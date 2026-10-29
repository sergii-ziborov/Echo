import XCTest
import CryptoKit
@testable import Echo

@MainActor
final class AdPolicyTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_790_000_000)
    func context(_ number: Int = 9) -> AdContext {
        AdContext(runID: UUID(), resultID: UUID(), campaignNumber: number, uniqueCampaignClears: 5)
    }
    func budget() -> AdBudget { AdBudget(eligibleWins: 3, activeSeconds: 240) }
    func creative() -> AdCreative {
        AdCreative(loadedAt: now, privacyGeneration: 1, entitlementGeneration: 1, policyVersion: 1)
    }
    func evaluate(_ context: AdContext, entitlement: EntitlementState = .freeVerified,
                  budget: AdBudget? = nil, creative: AdCreative? = nil, privacy: Bool = true) -> AdDecision {
        AdPolicy.evaluate(context: context, entitlement: entitlement, privacyAllowed: privacy, release: .storeKitTesting,
            budget: budget ?? self.budget(), creative: creative ?? self.creative(), now: now, privacyGeneration: 1, entitlementGeneration: 1)
    }
    func testEligibleTransitionAndEveryProtectedContext() {
        XCTAssertEqual(evaluate(context()), .allow)
        for number in 1...5 { XCTAssertEqual(evaluate(context(number)), .deny(.protectedLevel)) }
        let protected: [(WritableKeyPath<AdContext, Bool>, AdDecision.Reason)] = [
            (\.isEducational, .protectedContent), (\.hasMajorDiscovery, .protectedContent), (\.isChapterEnd, .protectedContent),
            (\.usedWatchRemote, .protectedMode), (\.isDaily, .protectedMode), (\.isEndless, .protectedMode),
            (\.hasModal, .presentationState), (\.isTestingRun, .protectedMode)]
        for (key, reason) in protected {
            var value = context(); value[keyPath: key] = true
            XCTAssertEqual(evaluate(value), .deny(reason))
        }
        for placement in [AdPlacement.death, .retry, .rewind, .menu] {
            var value = context(); value.placement = placement
            XCTAssertEqual(evaluate(value), .deny(.placement))
        }
        var background = context(); background.isForeground = false
        XCTAssertEqual(evaluate(background), .deny(.presentationState))
        var stale = context(); stale.nextIntentIsCurrent = false
        XCTAssertEqual(evaluate(stale), .deny(.presentationState))
        var offline = context(); offline.isOnline = false
        XCTAssertEqual(evaluate(offline), .deny(.offline))
    }
    func testCadenceRollingWindowAndClockRollback() {
        var value = budget(); value.eligibleWins = 2
        XCTAssertEqual(evaluate(context(), budget: value), .deny(.cadence))
        value = budget(); value.activeSeconds = 239.99
        XCTAssertEqual(evaluate(context(), budget: value), .deny(.cadence))
        value = budget(); value.started = [now.addingTimeInterval(-10), now.addingTimeInterval(-86_399)]
        XCTAssertEqual(evaluate(context(), budget: value), .deny(.dailyCap))
        value.started[1] = now.addingTimeInterval(-86_400)
        XCTAssertEqual(evaluate(context(), budget: value), .allow)
        value.wallHighWater = now.addingTimeInterval(1)
        XCTAssertEqual(evaluate(context(), budget: value), .deny(.clock))
    }
    func testUncertaintyConsentAndCreativeGenerationFailClosed() {
        for state in [EntitlementState.loading, .unresolved([])] {
            XCTAssertEqual(evaluate(context(), entitlement: state), .deny(.entitlementProtected))
        }
        XCTAssertEqual(evaluate(context(), privacy: false), .deny(.privacy))
        var ad = creative(); ad.privacyGeneration = 2
        XCTAssertEqual(evaluate(context(), creative: ad), .deny(.notReady))
        ad = creative(); ad.entitlementGeneration = 2
        XCTAssertEqual(evaluate(context(), creative: ad), .deny(.notReady))
        ad = creative(); ad.loadedAt = now.addingTimeInterval(-3000)
        XCTAssertEqual(evaluate(context(), creative: ad), .deny(.notReady))
        ad = creative(); ad.loadedAt = now.addingTimeInterval(1)
        XCTAssertEqual(evaluate(context(), creative: ad), .deny(.notReady))
    }
    func testReservationCrashRecoveryAndDuplicateWin() {
        let name = "echo.adBudget.tests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = AdBudgetStore(defaults: defaults, now: now), result = context()
        store.recordWin(result); store.recordWin(result)
        XCTAssertEqual(store.value.eligibleWins, 1)
        XCTAssertNotNil(store.reserve(result, now: now))
        XCTAssertNil(store.reserve(result, now: now))
        let recovered = AdBudgetStore(defaults: defaults, now: now)
        XCTAssertEqual(recovered.value.started.count, 1)
        XCTAssertNil(recovered.value.reservation)
        XCTAssertEqual(recovered.value.pendingNextCampaignNumber, 10)
        XCTAssertEqual(recovered.value.eligibleWins, 0)
        XCTAssertEqual(recovered.value.activeSeconds, 0)
        recovered.observeClock(now)
        XCTAssertNil(recovered.reserve(context(), now: now.addingTimeInterval(-1)))
        let ticket = recovered.reserve(context(), now: now)!
        recovered.started(ticket, now: now)
        let afterStarted = AdBudgetStore(defaults: defaults, now: now)
        XCTAssertEqual(afterStarted.value.started.count, 2)
        XCTAssertEqual(afterStarted.value.pendingNextCampaignNumber, 10)
        afterStarted.completeTransition()
        XCTAssertNil(AdBudgetStore(defaults: defaults, now: now).value.pendingNextCampaignNumber)
    }
    func testSignedPolicyCannotRaisePressureOrSurviveTamperingAndExpiry() throws {
        let key = Curve25519.Signing.PrivateKey()
        let policy = ReleasePolicy(version: 8, phase: .freeLive, issuedAt: now.addingTimeInterval(-1),
            expiresAt: now.addingTimeInterval(60), cutover: CutoverPolicy(id: "test", approved: true,
            legacyEligibilityEnd: now.addingTimeInterval(-100), rolloutUncertaintyEnd: now.addingTimeInterval(-10), paidBuilds: ["18"]),
            audienceReviewed: true, limits: AdLimits(minimumEligibleWins: 0, minimumActiveSeconds: 0, maxPer24Hours: 100, cacheMaxAge: 9999))
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(policy)
        let envelope = SignedReleasePolicy(payload: data.base64EncodedString(), signature: try key.signature(for: data).base64EncodedString())
        let verified = try envelope.verified(publicKey: key.publicKey.rawRepresentation, now: now)
        XCTAssertEqual(verified.limits.bounded, AdLimits())
        XCTAssertThrowsError(try envelope.verified(publicKey: key.publicKey.rawRepresentation, now: now.addingTimeInterval(61)))
        var modified = envelope; modified.payload = Data("{}".utf8).base64EncodedString()
        XCTAssertThrowsError(try modified.verified(publicKey: key.publicKey.rawRepresentation, now: now))
        XCTAssertFalse(ReleasePolicy().permitsAds(at: now))
    }
}
