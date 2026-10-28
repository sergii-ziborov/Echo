import XCTest
@testable import Echo

@MainActor
final class TestPrivacyClient: AdPrivacyClient {
    var allowed = true
    var canRequestAds: Bool { allowed }
    var optionsRequired = true
    var requests = 0
    func updateConsent(mayPresent: @escaping @MainActor () -> Bool) async throws {
        requests += 1
        guard mayPresent() else { throw MonetizationError.unavailable }
    }
    func showOptions() async throws {}
}
@MainActor
final class TestAdProvider: AdProvider {
    var creative: AdCreative?
    var prepares = 0
    var presents = 0
    var onPrepare: (() -> Void)?
    var started: (() -> Void)?
    var completion: ((AdPresentationOutcome) -> Void)?
    func prepareInterstitial(context: AdRequestContext) async {
        prepares += 1; creative = context.creative; onPrepare?()
    }
    func discardPreparedAds() { creative = nil }
    func presentInterstitial(ticket: AdPresentationTicket, started: @escaping @MainActor () -> Void,
                             completion: @escaping @MainActor (AdPresentationOutcome) -> Void) {
        presents += 1; creative = nil
        self.started = started; self.completion = completion
    }
}
@MainActor
final class CoordinatorTests: XCTestCase {
    func setup() async -> (MonetizationCoordinator, TestAdProvider, TestPrivacyClient, AdContext) {
        let client = TestPurchaseClient(), provider = TestAdProvider(), privacy = TestPrivacyClient()
        let service = StoreKitPurchaseService(client: client, entitlements: EntitlementStore(cache: MemoryEvidenceCache()))
        await service.resolve()
        let name = "echo.coordinator.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        let budget = AdBudgetStore(defaults: defaults)
        let context = AdContext(runID: UUID(), resultID: UUID(), campaignNumber: 9, uniqueCampaignClears: 5)
        for _ in 0..<3 { budget.recordWin(AdContext(runID: UUID(), resultID: UUID(), campaignNumber: 9)) }
        for _ in 0..<960 { budget.addActiveSeconds(0.25) }
        let coordinator = MonetizationCoordinator(purchases: service, privacy: PrivacyCoordinator(client: privacy), budget: budget, provider: provider)
        return (coordinator, provider, privacy, context)
    }
    func prepare(_ coordinator: MonetizationCoordinator, _ provider: TestAdProvider, _ context: AdContext) async {
        let prepared = expectation(description: "prepared")
        provider.onPrepare = { prepared.fulfill() }
        coordinator.prepare(context: context, isCurrent: { true })
        await fulfillment(of: [prepared], timeout: 2)
    }
    func testOnePresentationAndContinuationDespiteRepeatedSDKCallbacks() async {
        let (coordinator, provider, _, context) = await setup()
        await prepare(coordinator, provider, context)
        var transitions = 0
        coordinator.next(context: context, isCurrent: { true }) { transitions += 1 }
        coordinator.next(context: context, isCurrent: { true }) { transitions += 1 }
        XCTAssertEqual(provider.presents, 1)
        provider.started?(); provider.started?()
        provider.completion?(.dismissed); provider.completion?(.dismissed)
        XCTAssertEqual(transitions, 1)
        XCTAssertEqual(coordinator.budget.value.started.count, 1)
        XCTAssertEqual(coordinator.budget.value.eligibleWins, 0)
        XCTAssertNil(coordinator.modal.owner)
    }
    func testNoFillAndNoConsentNeverWaitForAnAd() async {
        let (coordinator, provider, _, context) = await setup()
        var transitions = 0
        coordinator.next(context: context, isCurrent: { true }) { transitions += 1 }
        XCTAssertEqual(transitions, 1)
        XCTAssertEqual(provider.presents, 0)
        XCTAssertEqual(provider.prepares, 0)
    }
    func testPurchaseAfterPreloadInvalidatesAdBeforeNext() async throws {
        let (coordinator, provider, _, context) = await setup()
        await prepare(coordinator, provider, context)
        try coordinator.purchases.entitlements.grant(PurchaseEvidence(id: "paid", source: .purchase,
            environment: .sandbox, productID: MonetizationConfiguration.productID, verifiedAt: Date()), familySharingEnabled: false)
        var transitions = 0
        coordinator.next(context: context, isCurrent: { true }) { transitions += 1 }
        XCTAssertEqual(transitions, 1)
        XCTAssertEqual(provider.presents, 0)
    }
    func testLeavingResultAndBackgroundInvalidateLateCallbacks() async {
        let (coordinator, provider, _, context) = await setup()
        await prepare(coordinator, provider, context)
        var transitions = 0
        coordinator.next(context: context, isCurrent: { true }) { transitions += 1 }
        provider.started?()
        coordinator.leaveResult()
        provider.completion?(.failed)
        XCTAssertEqual(transitions, 0)
        XCTAssertNil(coordinator.modal.owner)
        coordinator.sceneChanged(active: false)
        XCTAssertEqual(coordinator.decision(context), .deny(.presentationState))
    }
    func testProtectedResultNeverRequestsConsentOrAds() async {
        let (coordinator, provider, privacy, original) = await setup()
        var protected = original; protected.hasMajorDiscovery = true
        coordinator.prepare(context: protected, isCurrent: { true })
        await Task.yield()
        XCTAssertEqual(provider.prepares, 0)
        XCTAssertEqual(privacy.requests, 0)
    }
    func testWatchProtectionIsStickyAndWinCallbackDoesNotDuplicateReward() {
        let model = CoverageFixtures.model(rich: false)
        var view = GameView(request: CoverageFixtures.playRequest(6))
        view.modelOverride = model
        let before = model.progress.shards
        let result = SessionResult(time: 20, moves: 8, stars: 3, sparks: 5, echoesFaced: 2)
        view.handle([.won(result), .won(result)])
        XCTAssertEqual(model.progress.shards, before + result.points)
        let session = view.session
        PhoneWatchLink.shared.attach(session: session, scene: view.scene, level: view.remoteLevel)
        PhoneWatchLink.shared.apply(.hello(level: 0), now: 100)
        PhoneWatchLink.shared.tick(now: 110)
        XCTAssertTrue(session.usedWatchRemote)
        XCTAssertFalse(PhoneWatchLink.shared.isSteering)
        PhoneWatchLink.shared.detach(session: session)
    }
    func testBackgroundDismissalDefersNavigationUntilForeground() async {
        let (coordinator, provider, _, context) = await setup()
        await prepare(coordinator, provider, context)
        var transitions = 0
        coordinator.next(context: context, isCurrent: { true }) { transitions += 1 }
        provider.started?()
        coordinator.sceneChanged(active: false)
        provider.completion?(.dismissed)
        XCTAssertEqual(transitions, 0)
        coordinator.sceneChanged(active: true)
        XCTAssertEqual(transitions, 1)
    }

    func testOwnedFullscreenCoverDoesNotCancelTheChosenNext() async {
        let (coordinator, provider, _, context) = await setup()
        await prepare(coordinator, provider, context)
        let model = AppModel(monetization: coordinator)
        var view = GameView(request: CoverageFixtures.playRequest(9)); view.modelOverride = model
        model.screen = .playing(view.request)
        var transitions = 0
        coordinator.next(context: context, isCurrent: { true }) { transitions += 1 }
        view.disappearedFromGame()
        provider.started?(); provider.completion?(.dismissed)
        XCTAssertEqual(transitions, 1)
        XCTAssertNil(coordinator.budget.value.pendingNextCampaignNumber)
    }
    func testStaleNextDoesNotNavigateOrShowAnAd() async {
        let (coordinator, provider, _, context) = await setup()
        var transitions = 0
        coordinator.next(context: context, isCurrent: { false }) { transitions += 1 }
        XCTAssertEqual(transitions, 0)
        XCTAssertEqual(provider.presents, 0)
    }
    func testReturningFromFullscreenDoesNotConsumeWardAgain() {
        let model = CoverageFixtures.model(rich: false)
        model.progress.inventory[BonusKind.ward.rawValue] = 2
        var view = GameView(request: CoverageFixtures.playRequest(9)); view.modelOverride = model
        model.screen = .playing(view.request)
        CoverageHost.render(view.environment(model))
        XCTAssertEqual(model.progress.inventory[BonusKind.ward.rawValue], 1)
        CoverageHost.render(view.environment(model))
        XCTAssertEqual(model.progress.inventory[BonusKind.ward.rawValue], 1)
        model.goHome(); CoverageHost.teardown()
    }

    func testRemoteRetryCannotStartAnArenaBehindAnAd() async {
        let (coordinator, provider, _, context) = await setup()
        await prepare(coordinator, provider, context)
        let model = AppModel(monetization: coordinator)
        var view = GameView(request: CoverageFixtures.playRequest(9)); view.modelOverride = model
        view.session.phase = .won(SessionResult(time: 20, moves: 8, stars: 3, sparks: 5, echoesFaced: 1))
        let runID = view.session.runID
        var transitions = 0
        coordinator.next(context: context, isCurrent: { true }) { transitions += 1 }
        view.restart()
        XCTAssertEqual(view.session.runID, runID)
        guard case .won = view.session.phase else { return XCTFail("Arena must stay stopped behind the ad") }
        provider.started?(); provider.completion?(.dismissed)
        XCTAssertEqual(transitions, 1)
    }

    func testWatchProtectedResultStillAdvancesWithoutAnAd() async {
        let (coordinator, provider, _, context) = await setup()
        await prepare(coordinator, provider, context)
        let model = AppModel(monetization: coordinator)
        model.progress.debugShowcase(cleared: 9)
        model.progress.hasSeenTutorial = true
        var view = GameView(request: CoverageFixtures.playRequest(9)); view.modelOverride = model
        model.screen = .playing(view.request)
        view.session.phase = .won(SessionResult(time: 20, moves: 8, stars: 3, sparks: 5, echoesFaced: 1))
        view.session.usedWatchRemote = true
        view.nextLevel()
        guard case .playing(let next) = model.screen else { return XCTFail("Protected result must continue normally") }
        XCTAssertEqual(next.levelID, LevelCatalog.level(number: 10)?.id)
        XCTAssertEqual(provider.presents, 0)
    }

}
