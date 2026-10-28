import Foundation

@MainActor
@Observable
final class StoreKitPurchaseService {
    enum Operation: Equatable { case idle, loadingProduct, purchasing, restoring }
    let entitlements: EntitlementStore
    let release: ReleasePolicyStore
    private let client: any PurchaseClient
    private(set) var product: PurchaseProduct?
    private(set) var operation = Operation.idle
    private(set) var messageKey: String?
    private(set) var environment = PurchaseEnvironment.unknown
    private(set) var productUnavailableThisSession = false
    private var acquisition: OriginalAcquisition?
    @ObservationIgnored private var listener: Task<Void, Never>?
    @ObservationIgnored private var resolving = false
    @ObservationIgnored private var started = false

    init(client: any PurchaseClient = StoreKitClient(), entitlements: EntitlementStore = EntitlementStore(),
         release: ReleasePolicyStore = ReleasePolicyStore()) {
        self.client = client
        self.entitlements = entitlements
        self.release = release
    }
    var effectivePolicy: ReleasePolicy {
        switch environment {
        case .sandbox, .xcode: .storeKitTesting
        default: release.current()
        }
    }
    var purchaseOffered: Bool {
        (MonetizationConfiguration.adsCompiledIn || environment == .sandbox || environment == .xcode)
            && effectivePolicy.phase != .preFree && entitlements.state.isConclusiveFree
    }
    var canPurchase: Bool {
        purchaseOffered && product != nil && operation == .idle && messageKey != "monetization.pending"
    }
    func start() {
        guard !started else { return }
        started = true
        // Lifetime listener is independent of any purchase sheet.
        let updates = client.updates()
        listener = Task { [weak self] in
            for await update in updates {
                guard let self else { return }
                await self.deliver(update)
            }
        }
        Task { [weak self] in
            guard let self else { return }
            await self.refreshPolicy()
        }
    }
    func resolve(refresh: Bool = false) async {
        guard !resolving else { return }
        resolving = true
        entitlements.unresolved()
        defer { resolving = false }
        do {
            let original = try await client.acquisition(refresh: refresh)
            let active = try await client.entitlements()
            environment = original.environment
            acquisition = original
            try entitlements.resolve(acquisition: original, purchases: active, policy: effectivePolicy)
        } catch { entitlements.unresolved() }
        MonetizationDiagnostics.shared.record(.entitlementResolution, entitlements.state.statusKey)
    }
    func loadProduct() async {
        guard purchaseOffered, operation == .idle else { return }
        operation = .loadingProduct
        defer { operation = .idle }
        do {
            product = try await client.product()
            if product == nil { productUnavailableThisSession = true; messageKey = "monetization.productUnavailable" }
        } catch {
            product = nil
            productUnavailableThisSession = true
            messageKey = "monetization.productUnavailable"
        }
    }
    func buy() async {
        guard canPurchase else { return }
        operation = .purchasing
        messageKey = nil
        defer { operation = .idle }
        do {
            switch try await client.purchase() {
            case .purchased(let evidence): await deliver(PurchaseUpdate(evidence: evidence, revoked: false))
            case .pending: messageKey = "monetization.pending"
            case .cancelled: break
            }
        } catch { messageKey = "monetization.purchaseError"; entitlements.unresolved() }
        MonetizationDiagnostics.shared.record(.purchaseResult, messageKey ?? "cancelled-or-completed")
    }
    func restore() async {
        guard operation == .idle else { return }
        operation = .restoring
        messageKey = nil
        defer { operation = .idle }
        do {
            // These authentication-capable operations only follow an explicit user action.
            try await client.sync()
            await resolve(refresh: true)
            if entitlements.state.isAdFree { messageKey = "monetization.thanks" }
            else if entitlements.state.isConclusiveFree { messageKey = "monetization.restoreNone" }
            else { messageKey = "monetization.restoreError" }
        } catch { messageKey = "monetization.restoreError"; entitlements.unresolved() }
        MonetizationDiagnostics.shared.record(.restoreResult, messageKey ?? "checking")
    }
    func refreshPolicy() async {
        await resolve()
        guard !entitlements.state.isAdFree else { return }
        await release.refresh()
        await resolve()
    }
    private func deliver(_ update: PurchaseUpdate) async {
        guard let evidence = update.evidence else { entitlements.unresolved(); return }
        do {
            if update.revoked {
                try entitlements.revoke(id: evidence.id, environment: evidence.environment)
                messageKey = nil
            } else {
                try entitlements.grant(evidence, familySharingEnabled: effectivePolicy.familySharingEnabled)
                guard entitlements.state.isAdFree else { return }
                messageKey = "monetization.thanks"
            }
            // Entitlement change invalidates ad readiness synchronously before finish.
            await client.finish(evidence)
            if update.revoked { await resolve() }
        } catch { entitlements.unresolved(); messageKey = "monetization.restoreError" }
    }
}
