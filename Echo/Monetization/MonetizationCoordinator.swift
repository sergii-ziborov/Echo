import Foundation

@MainActor
@Observable
final class MonetizationCoordinator {
    let purchases: StoreKitPurchaseService
    let privacy: PrivacyCoordinator
    let modal = MonetizationModalGate()
    let budget: AdBudgetStore
    private let provider: any AdProvider
    private let configuration: MonetizationConfiguration
    private(set) var isForeground = true
    private(set) var navigationGeneration: UInt64 = 0
    private(set) var lastAdDiagnostic: String?
    private(set) var lastAdStartedAt: Date?
    private var current: AdPresentationTicket?
    private var complete: (() -> Void)?
    private var preparedResult: UUID?
    private var prepareTask: Task<Void, Never>?
    private var began = false
    private var deferredNavigation: (UInt64, () -> Void)?
    private(set) var readinessGeneration: UInt64 = 0
    var onPresentationChange: ((Bool) -> Void)?

    init(purchases: StoreKitPurchaseService = StoreKitPurchaseService(), privacy: PrivacyCoordinator = PrivacyCoordinator(),
         budget: AdBudgetStore = AdBudgetStore(), provider: any AdProvider = DisabledAdProvider(),
         configuration: MonetizationConfiguration = .init()) {
        self.purchases = purchases; self.privacy = privacy; self.budget = budget
        self.provider = provider; self.configuration = configuration
        purchases.entitlements.onChange = { [weak self] in self?.invalidate() }
        purchases.release.onChange = { [weak self] in self?.invalidate() }
        privacy.onChange = { [weak self] in self?.provider.discardPreparedAds() }
    }
    func start() { purchases.start() }
    func sceneChanged(active: Bool) {
        isForeground = active
        if !active {
            invalidate()
            if current != nil, !began { finish(.failed) }
        } else {
            if let (generation, action) = deferredNavigation {
                deferredNavigation = nil
                if generation == navigationGeneration { budget.completeTransition(); action() }
            }
            Task { [weak self] in await self?.purchases.refreshPolicy() }
        }
    }
    func leaveResult() {
        navigationGeneration &+= 1
        preparedResult = nil
        invalidate()
        // No callback is allowed to navigate out of a later screen.
        complete = nil
        deferredNavigation = nil
        budget.completeTransition()
    }
    func invalidate() {
        prepareTask?.cancel()
        provider.discardPreparedAds()
        readinessGeneration &+= 1
    }
    private var deploymentAllowed: Bool {
        if purchases.environment == .sandbox || purchases.environment == .xcode { return true }
        return MonetizationConfiguration.adsCompiledIn && configuration.hasLiveIdentifiers
    }
    func prepare(context: AdContext, isCurrent: @escaping @MainActor () -> Bool) {
        guard deploymentAllowed, purchases.entitlements.state.isConclusiveFree,
              purchases.effectivePolicy.permitsAds(at: Date()), context.isEligibleWin,
              context.uniqueCampaignClears >= 5, isForeground, modal.owner == nil,
              preparedResult != context.resultID else { return }
        preparedResult = context.resultID
        prepareTask = Task { [weak self] in
            guard let self else { return }
            await self.purchases.loadProduct()
            guard !Task.isCancelled, !self.purchases.productUnavailableThisSession,
                  isCurrent(), self.modal.acquire(.privacy) else { return }
            await self.privacy.prepare(mayPresent: { !Task.isCancelled && isCurrent() && self.isForeground })
            self.modal.release(.privacy)
            guard !Task.isCancelled, isCurrent(), self.decision(context, preparing: true) == .allow else { return }
            let creative = AdCreative(loadedAt: Date(), privacyGeneration: self.privacy.generation,
                entitlementGeneration: self.purchases.entitlements.generation, policyVersion: self.purchases.effectivePolicy.version)
            await self.provider.prepareInterstitial(context: AdRequestContext(creative: creative,
                testing: self.purchases.environment != .production || MonetizationConfiguration.requiresTestAds))
            if Task.isCancelled || !isCurrent() { self.provider.discardPreparedAds() }
            self.readinessGeneration &+= 1
        }
    }
    func next(context: AdContext, isCurrent: @escaping @MainActor () -> Bool, continuation: @escaping @MainActor () -> Void) {
        guard current == nil else { return }
        guard isCurrent() else {
            MonetizationDiagnostics.shared.record(.nextTransition, "cancelled-stale", placement: context.placement)
            return
        }
        budget.observeClock(Date())
        MonetizationDiagnostics.shared.record(.adOpportunity, String(describing: decision(context)), placement: context.placement)
        guard isCurrent(), decision(context) == .allow,
              modal.acquire(.ad), let reservation = budget.reserve(context, now: Date()) else {
            modal.release(.ad)
            provider.discardPreparedAds()
            MonetizationDiagnostics.shared.record(.nextTransition, "continued-without-ad", placement: context.placement)
            continuation()
            return
        }
        // A second check closes the purchase/privacy/watch race immediately before present.
        var checked = context
        checked.hasModal = false // This operation itself owns the modal lock.
        let snapshot = budget.value
        var withoutOwnReservation = snapshot
        withoutOwnReservation.reservation = nil
        guard isCurrent(), evaluate(checked, budget: withoutOwnReservation) == .allow else {
            budget.cancel(reservation); budget.completeTransition(); modal.release(.ad)
            if isCurrent() { continuation() }
            return
        }
        let ticket = AdPresentationTicket(id: reservation.id, runID: context.runID, resultID: context.resultID,
            navigationGeneration: navigationGeneration, entitlementGeneration: purchases.entitlements.generation,
            privacyGeneration: privacy.generation)
        current = ticket; complete = continuation; began = false
        onPresentationChange?(true)
        provider.presentInterstitial(ticket: ticket, started: { [weak self] in
            guard let self, self.current == ticket, !self.began else { return }
            self.began = true
            self.lastAdDiagnostic = self.provider.diagnosticID
            self.lastAdStartedAt = Date()
            self.budget.started(reservation, now: Date())
            MonetizationDiagnostics.shared.record(.adStarted, "started", placement: context.placement)
        }, completion: { [weak self] outcome in
            guard let self, self.current == ticket else { return }
            if !self.began { self.budget.cancel(reservation) }
            self.finish(outcome)
        })
    }
    func showPrivacyOptions() async {
        guard modal.acquire(.privacy) else { return }
        defer { modal.release(.privacy) }
        await privacy.showOptions()
    }
    func decision(_ context: AdContext, preparing: Bool = false) -> AdDecision {
        _ = readinessGeneration
        guard deploymentAllowed, !purchases.productUnavailableThisSession else { return .deny(.releaseNotEnabled) }
        var checked = context
        checked.hasModal = checked.hasModal || modal.owner != nil || purchases.operation != .idle
        return evaluate(checked, budget: budget.value, preparing: preparing)
    }
    private func evaluate(_ context: AdContext, budget: AdBudget, preparing: Bool = false) -> AdDecision {
        var context = context
        context.isForeground = context.isForeground && isForeground
        return AdPolicy.evaluate(context: context, entitlement: purchases.entitlements.state,
            privacyAllowed: privacy.canRequestAds, release: purchases.effectivePolicy, budget: budget,
            creative: provider.creative, now: Date(), privacyGeneration: privacy.generation,
            entitlementGeneration: purchases.entitlements.generation, preparing: preparing)
    }
    private func finish(_ outcome: AdPresentationOutcome) {
        guard let ticket = current else { return }
        current = nil
        MonetizationDiagnostics.shared.record(.adClosed, String(describing: outcome), placement: .campaignResultToNext)
        let action = ticket.navigationGeneration == navigationGeneration ? complete : nil
        complete = nil
        modal.release(.ad)
        provider.discardPreparedAds()
        onPresentationChange?(false)
        if let action {
            if isForeground {
                MonetizationDiagnostics.shared.record(.nextTransition, "completed", placement: .campaignResultToNext)
                budget.completeTransition()
                action()
            }
            else { deferredNavigation = (navigationGeneration, action) }
        }
    }
}
