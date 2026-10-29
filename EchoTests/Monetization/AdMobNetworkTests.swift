import XCTest
@testable import Echo

/// Explicit network smoke test, separate from deterministic policy tests.
@MainActor
final class AdMobNetworkTests: XCTestCase {
    func testOfficialTestCreativeLoadsAfterPrivacyAndIsDiscarded() async throws {
#if ECHO_ADMOB && targetEnvironment(simulator)
        guard ProcessInfo.processInfo.environment["ECHO_RUN_AD_NETWORK_TESTS"] == "1" else {
            throw XCTSkip("Opt-in network test: use scripts/test_admob_network.py on an isolated simulator.")
        }
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
                       MonetizationConfiguration.testAppID)
        guard Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String
                == MonetizationConfiguration.testAppID else { return }
        let privacy = AdMobPrivacyClient()
        do { try await privacy.updateConsent(mayPresent: { true }) }
        catch { throw XCTSkip("BLOCKED: real UMP consent update failed; no ad request was made: \(error)") }
        guard privacy.canRequestAds else {
            throw XCTSkip("BLOCKED: UMP did not allow an ad request; consent was not bypassed.")
        }
        var configuration = MonetizationConfiguration()
        configuration.liveAppID = MonetizationConfiguration.testAppID
        let provider = AdMobProvider(configuration: configuration)
        defer { provider.discardPreparedAds() }
        let metadata = AdCreative(loadedAt: Date(), privacyGeneration: 1,
                                  entitlementGeneration: 1, policyVersion: 1)
        await provider.prepareInterstitial(context: AdRequestContext(creative: metadata, testing: true))
        guard let loaded = provider.creative else {
            throw XCTSkip("BLOCKED: the official Google test creative did not load; no mock readiness substituted.")
        }
        XCTAssertEqual(loaded.id, metadata.id)
        XCTAssertEqual(loaded.privacyGeneration, 1)
        provider.discardPreparedAds()
        XCTAssertNil(provider.creative)
        let ticket = AdPresentationTicket(id: UUID(), runID: UUID(), resultID: UUID(),
            navigationGeneration: 1, entitlementGeneration: 1, privacyGeneration: 1)
        var completions = 0
        provider.presentInterstitial(ticket: ticket, started: {
            XCTFail("A discarded creative must never present")
        }, completion: { outcome in
            if case .failed = outcome { completions += 1 }
            else { XCTFail("A discarded creative must fail immediately") }
        })
        XCTAssertEqual(completions, 1)
#else
        throw XCTSkip("Network smoke requires the explicit AdMob variant and an isolated simulator.")
#endif
    }
}
