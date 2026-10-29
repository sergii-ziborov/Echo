import XCTest
@testable import Echo

@MainActor
final class BaselineSnapshotTests: XCTestCase {
    func testFrozenBaselineSaveSurvivesMonetizationInitialization() throws {
        let file = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "BaselineProgress", withExtension: "json"))
        let fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        let values = try XCTUnwrap(fixture["values"] as? [String: [String: Any]])
        let suite = "echo.frozen-save.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for (key, entry) in values {
            if entry["kind"] as? String == "data" {
                defaults.set(try XCTUnwrap(Data(base64Encoded: try XCTUnwrap(entry["value"] as? String))), forKey: key)
            } else { defaults.set(entry["value"], forKey: key) }
        }
        let before = ProgressStore(defaults: defaults)
        XCTAssertEqual(before.starsByLevel.count, 77)
        XCTAssertFalse(before.inventory.isEmpty)
        XCTAssertFalse(before.upgrades.isEmpty)
        _ = AdBudgetStore(defaults: defaults)
        _ = ReleasePolicyStore(defaults: defaults)
        _ = EntitlementStore(cache: MemoryEvidenceCache())
        before.persist()
        let after = ProgressStore(defaults: defaults)
        XCTAssertEqual(after.starsByLevel, before.starsByLevel)
        XCTAssertEqual(after.shards, before.shards)
        XCTAssertEqual(after.upgrades, before.upgrades)
        XCTAssertEqual(after.inventory, before.inventory)
        XCTAssertEqual(after.equippedSkillIDs, before.equippedSkillIDs)
        XCTAssertEqual(after.difficultyCycle, before.difficultyCycle)
        XCTAssertEqual(after.completedDifficultyCycles, before.completedDifficultyCycles)
        XCTAssertEqual(after.lastLevelID, before.lastLevelID)
        XCTAssertEqual(after.wrist.cleared, before.wrist.cleared)
        XCTAssertEqual(after.announcedArchiveIDs, before.announcedArchiveIDs)
    }
    func testSDKVariantFlagMatchesGeneratedAppArtifact() {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "EchoAdSDKIncluded") as? Bool, MonetizationConfiguration.adsCompiledIn)
#if DEBUG
        XCTAssertTrue(MonetizationConfiguration.requiresTestAds)
#endif
    }

}
