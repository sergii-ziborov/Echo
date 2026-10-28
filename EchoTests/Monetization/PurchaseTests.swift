import XCTest
@testable import Echo

@MainActor
final class MemoryEvidenceCache: PurchaseEvidenceCaching {
    var evidence: [PurchaseEvidence] = []
    var fail = false
    var failRead = false
    func load() throws -> [PurchaseEvidence] {
        if failRead { throw MonetizationError.persistence }
        return evidence
    }
    func save(_ evidence: [PurchaseEvidence]) throws {
        if fail { throw MonetizationError.persistence }
        self.evidence = evidence
    }
}

@MainActor
final class PurchaseTests: XCTestCase {
    let date = Date(timeIntervalSince1970: 1_790_000_000)
    func acquisition(_ environment: PurchaseEnvironment = .production, offset: Double = -100) -> OriginalAcquisition {
        OriginalAcquisition(evidenceID: "original", bundleID: MonetizationConfiguration.bundleID, environment: environment,
            originalBuild: "18", originalPurchaseDate: date.addingTimeInterval(offset))
    }
    func policy() -> ReleasePolicy {
        ReleasePolicy(version: 2, phase: .freeQuiet, issuedAt: date.addingTimeInterval(-1000), expiresAt: date.addingTimeInterval(1000),
            cutover: CutoverPolicy(id: "fixture-only", approved: true, legacyEligibilityEnd: date, rolloutUncertaintyEnd: date.addingTimeInterval(60), paidBuilds: ["18"]))
    }
    func evidence(_ source: EvidenceSource = .purchase) -> PurchaseEvidence {
        PurchaseEvidence(id: "iap", source: source, environment: .production, productID: MonetizationConfiguration.productID, verifiedAt: date)
    }
    func testLegacyWithoutCutoverIsUnresolvedAndOldTestDateIsNotLegacy() {
        XCTAssertEqual(LegacyEligibility.assess(acquisition(), policy: ReleasePolicy()), .unresolved)
        XCTAssertEqual(LegacyEligibility.assess(acquisition(.sandbox), policy: policy()), .notEligible)
        XCTAssertEqual(LegacyEligibility.assess(acquisition(.xcode), policy: policy()), .notEligible)
        XCTAssertEqual(LegacyEligibility.assess(acquisition(offset: 1), policy: policy()), .unresolved)
        XCTAssertEqual(LegacyEligibility.assess(acquisition(offset: 61), policy: policy()), .notEligible)
    }
    func testLegacySurvivesIAPRefundAndNarrowerPolicy() throws {
        let store = EntitlementStore(cache: MemoryEvidenceCache())
        try store.resolve(acquisition: acquisition(), purchases: [], policy: policy())
        try store.grant(evidence(), familySharingEnabled: false)
        try store.revoke(id: "iap", environment: .production)
        try store.resolve(acquisition: acquisition(), purchases: [], policy: ReleasePolicy())
        guard case .adFreeLegacy = store.state else { return XCTFail("Legacy must remain") }
    }
    func testEmptyEnumerationAndFailureDoNotRevokeVerifiedPurchase() throws {
        let store = EntitlementStore(cache: MemoryEvidenceCache())
        try store.grant(evidence(), familySharingEnabled: false)
        try store.resolve(acquisition: acquisition(offset: 70), purchases: [], policy: policy())
        XCTAssertFalse(store.state.isConclusiveFree)
        store.unresolved()
        XCTAssertEqual(store.evidence.count, 1)
    }
    func testResetKeepsEvidenceAndAllExistingSaveFieldsRoundTrip() throws {
        let name = "monetization.migration.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let progress = ProgressStore(defaults: defaults)
        progress.debugShowcase(cleared: 77)
        progress.debugLabShowcase()
        let stars = progress.starsByLevel, inventory = progress.inventory, upgrades = progress.upgrades
        let restored = ProgressStore(defaults: defaults)
        XCTAssertEqual(stars, restored.starsByLevel)
        XCTAssertEqual(inventory, restored.inventory)
        XCTAssertEqual(upgrades, restored.upgrades)
        let store = EntitlementStore(cache: MemoryEvidenceCache())
        try store.grant(evidence(), familySharingEnabled: false)
        defaults.set("retained", forKey: "echo.monetization.test")
        restored.resetProgress()
        XCTAssertTrue(store.state.isAdFree)
        XCTAssertEqual(defaults.string(forKey: "echo.monetization.test"), "retained")
    }
    func testCacheFailureNeverGrantsAndFamilyRequiresExplicitConfiguration() throws {
        let store = EntitlementStore(cache: MemoryEvidenceCache())
        try store.grant(evidence(.family), familySharingEnabled: false)
        XCTAssertFalse(store.state.isAdFree)
        let failed = MemoryEvidenceCache(); failed.fail = true
        XCTAssertThrowsError(try EntitlementStore(cache: failed).grant(evidence(), familySharingEnabled: false))
    }
    func testChangedAcquisitionAndConflictingBuildStayUnresolved() throws {
        let store = EntitlementStore(cache: MemoryEvidenceCache())
        try store.resolve(acquisition: acquisition(), purchases: [], policy: policy())
        var changed = acquisition(offset: 100); changed.evidenceID = "different-acquisition"
        try store.resolve(acquisition: changed, purchases: [], policy: policy())
        XCTAssertFalse(store.state.isConclusiveFree)
        guard case .unresolved = store.state else { return XCTFail("Changed context must be rechecked") }
        var conflict = acquisition(); conflict.originalBuild = "unexpected-build"
        XCTAssertEqual(LegacyEligibility.assess(conflict, policy: policy()), .unresolved)
    }

    func testUnreadableCacheCannotBecomeFreeOrOverwriteOldEvidence() throws {
        let cache = MemoryEvidenceCache()
        cache.evidence = [evidence()]
        cache.failRead = true
        let store = EntitlementStore(cache: cache)
        XCTAssertThrowsError(try store.resolve(acquisition: acquisition(offset: 70), purchases: [], policy: policy()))
        XCTAssertThrowsError(try store.grant(evidence(.family), familySharingEnabled: true))
        XCTAssertFalse(store.state.isConclusiveFree)
        XCTAssertEqual(cache.evidence, [evidence()])
        cache.failRead = false
        try store.resolve(acquisition: acquisition(offset: 70), purchases: [evidence()], policy: policy())
        XCTAssertTrue(store.state.isAdFree)
    }

}
