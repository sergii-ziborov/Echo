import Foundation

enum PurchaseEnvironment: String, Codable, Sendable { case production, sandbox, xcode, unknown }
enum EvidenceSource: String, Codable, Sendable { case legacy, purchase, family }

struct PurchaseEvidence: Codable, Equatable, Sendable {
    var id: String
    var source: EvidenceSource
    var environment: PurchaseEnvironment
    var productID: String?
    var policyID: String?
    var verifiedAt: Date
}

struct OriginalAcquisition: Equatable, Sendable {
    var evidenceID: String
    var bundleID: String
    var environment: PurchaseEnvironment
    /// AppTransaction.originalAppVersion is an acquisition build, not a marketing version.
    var originalBuild: String
    var originalPurchaseDate: Date
}

enum EntitlementState: Equatable {
    case loading
    case adFreeLegacy(PurchaseEvidence)
    case adFreePurchase(PurchaseEvidence)
    case adFreeFamily(PurchaseEvidence)
    case freeVerified
    case unresolved([PurchaseEvidence])

    var isConclusiveFree: Bool { self == .freeVerified }
    var isAdFree: Bool {
        switch self {
        case .adFreeLegacy, .adFreePurchase, .adFreeFamily: true
        default: false
        }
    }
    var statusKey: String {
        switch self {
        case .adFreeLegacy: "monetization.legacy"
        case .adFreePurchase, .adFreeFamily: "monetization.adFree"
        case .freeVerified: "monetization.free"
        default: "monetization.checking"
        }
    }
}

@MainActor
@Observable
final class EntitlementStore {
    private(set) var state: EntitlementState = .loading
    private(set) var generation: UInt64 = 0
    private(set) var evidence: [PurchaseEvidence]
    let cache: any PurchaseEvidenceCaching
    var onChange: (() -> Void)?
    private var currentAcquisition: OriginalAcquisition?
    private var cacheReadFailed = false

    init(cache: any PurchaseEvidenceCaching = KeychainEvidenceCache()) {
        self.cache = cache
        do { evidence = try cache.load() }
        catch { evidence = []; cacheReadFailed = true }
        if cacheReadFailed || !evidence.isEmpty { state = .unresolved(evidence) }
    }

    func unresolved() { set(.unresolved(evidence)) }

    func resolve(acquisition: OriginalAcquisition, purchases: [PurchaseEvidence], policy: ReleasePolicy) throws {
        try recoverCacheIfNeeded()
        guard acquisition.bundleID == MonetizationConfiguration.bundleID,
              acquisition.environment != .unknown else { unresolved(); return }
        currentAcquisition = acquisition
        let environment = acquisition.environment
        // Never transfer a test grant to production, or reuse an unverified account context.
        let prior = evidence.filter { $0.environment == environment }
        var current = purchases.filter {
            $0.environment == environment && $0.productID == MonetizationConfiguration.productID
                && ($0.source == .purchase || ($0.source == .family && policy.familySharingEnabled))
        }
        if let legacy = prior.first(where: { $0.source == .legacy }) {
            guard legacy.id == acquisition.evidenceID else { unresolved(); return }
            current.append(legacy) // A later, narrower cutover cannot revoke a granted legacy right.
        } else if LegacyEligibility.assess(acquisition, policy: policy) == .eligible {
            current.append(PurchaseEvidence(id: acquisition.evidenceID, source: .legacy,
                environment: environment, policyID: policy.cutover?.id, verifiedAt: Date()))
        }
        // A successful but empty enumeration does not prove a cached right was refunded.
        let missingPrior = prior.filter { old in !current.contains(where: { $0.id == old.id }) }
        if !missingPrior.isEmpty {
            unresolved()
            return
        }
        let allEnvironments = evidence.filter { $0.environment != environment } + current
        try cache.save(allEnvironments)
        evidence = allEnvironments
        if let legacy = current.first(where: { $0.source == .legacy }) { set(.adFreeLegacy(legacy)) }
        else if let purchase = current.first(where: { $0.source == .purchase }) { set(.adFreePurchase(purchase)) }
        else if let family = current.first(where: { $0.source == .family }) { set(.adFreeFamily(family)) }
        else if LegacyEligibility.assess(acquisition, policy: policy) == .notEligible { set(.freeVerified) }
        else { unresolved() }
    }

    func grant(_ item: PurchaseEvidence, familySharingEnabled: Bool) throws {
        try recoverCacheIfNeeded()
        guard item.productID == MonetizationConfiguration.productID, !item.id.isEmpty, item.environment != .unknown,
              item.source == .purchase || (item.source == .family && familySharingEnabled) else {
            unresolved(); return
        }
        var items = evidence.filter { !($0.environment == item.environment && $0.id == item.id) }
        items.append(item)
        try cache.save(items) // Delivery must be durable before StoreKit.finish().
        evidence = items
        if let legacy = items.first(where: { $0.source == .legacy && $0.environment == item.environment && $0.id == currentAcquisition?.evidenceID }) { set(.adFreeLegacy(legacy)) }
        else { set(item.source == .family ? .adFreeFamily(item) : .adFreePurchase(item)) }
    }

    func revoke(id: String, environment: PurchaseEnvironment) throws {
        try recoverCacheIfNeeded()
        let items = evidence.filter { !($0.id == id && $0.environment == environment && $0.source != .legacy) }
        try cache.save(items)
        evidence = items
        if let legacy = items.first(where: { $0.source == .legacy && $0.environment == environment && $0.id == currentAcquisition?.evidenceID }) {
            set(.adFreeLegacy(legacy))
        } else { unresolved() }
    }

    private func recoverCacheIfNeeded() throws {
        guard cacheReadFailed else { return }
        // An inaccessible/corrupt cache is not an empty purchase history. Never overwrite it
        // or classify the owner as free until its previous evidence can be read again.
        evidence = try cache.load()
        cacheReadFailed = false
    }

    private func set(_ value: EntitlementState) {
        guard state != value else { return }
        state = value
        generation &+= 1
        onChange?()
    }
}
