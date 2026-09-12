import XCTest
@testable import Echo

@MainActor
final class ProgressStoreTests: XCTestCase {
    func testBuySpendsPointsAndStocksInventory() {
        let store = makeStore()
        store.addShards(80)
        XCTAssertTrue(store.buy(.freeze))
        XCTAssertEqual(store.points, 80 - BonusKind.freeze.price)
        XCTAssertEqual(store.count(.freeze), 1)
        XCTAssertTrue(store.consume(.freeze))
        XCTAssertEqual(store.count(.freeze), 0)
        XCTAssertFalse(store.consume(.freeze))
    }

    func testCannotBuyWithoutPoints() {
        let store = makeStore()
        XCTAssertFalse(store.buy(.shield))
        XCTAssertEqual(store.count(.shield), 0)
        XCTAssertEqual(store.points, 0)
    }

    func testContinuePicksNextUnbeatenLevel() {
        let store = makeStore()
        XCTAssertEqual(store.continueLevel().number, 1)
        let win = SessionResult(time: 10, moves: 10, stars: 1, sparks: 6, echoesFaced: 1, bonuses: 0)
        store.recordWin(levelID: LevelCatalog.prototype.id, result: win)
        XCTAssertEqual(store.continueLevel().number, 2)
        store.recordWin(levelID: "daily-2026-09-09", result: win)
        XCTAssertEqual(store.continueLevel().number, 2)
    }

    func testWinAwardsPointsFromStars() {
        let store = makeStore()
        let result = SessionResult(time: 10, moves: 10, stars: 3, sparks: 6, echoesFaced: 1, bonuses: 2)
        store.recordWin(levelID: "test", result: result)
        XCTAssertEqual(store.points, result.points)
        XCTAssertEqual(result.points, 200)
        XCTAssertEqual(store.progress(for: "test").stars, 3)
    }

    func testDailyFirstClearAwardsPointsOnce() {
        let store = makeStore()
        let result = SessionResult(time: 10, moves: 10, stars: 2, sparks: 6, echoesFaced: 1, bonuses: 0)
        store.recordWin(levelID: "daily-2026-09-09", result: result, awardsShard: true)
        XCTAssertEqual(store.points, result.points)
        store.recordWin(levelID: "daily-2026-09-09", result: result, awardsShard: false)
        XCTAssertEqual(store.points, result.points)
        XCTAssertEqual(store.progress(for: "daily-2026-09-09").stars, 2)
    }

    func testDailyProgressDoesNotReplaceContinueLevel() {
        let store = makeStore()
        let win = SessionResult(time: 10, moves: 10, stars: 1, sparks: 6, echoesFaced: 1, bonuses: 0)
        store.recordWin(levelID: LevelCatalog.prototype.id, result: win)
        store.recordWin(levelID: "daily-2026-09-09", result: win)
        XCTAssertEqual(store.continueLevel().number, 2)
        XCTAssertNotEqual(store.lastLevelID, "daily-2026-09-09")
    }

    func testInventoryUsesResearchableCapacity() {
        let store = makeStore()
        store.addShards(BonusKind.freeze.price * 12)
        for _ in 0..<store.inventoryCapacity {
            XCTAssertTrue(store.buy(.freeze))
        }
        XCTAssertFalse(store.buy(.freeze))
        XCTAssertEqual(store.count(.freeze), 3)
    }

    func testResearchUnlocksSlotsCapacityAndSkillTypes() {
        let store = makeStore()
        store.addShards(2_000)
        XCTAssertFalse(store.isSkillUnlocked(.surge))
        XCTAssertEqual(store.skillSlotCount, 2)
        XCTAssertEqual(store.inventoryCapacity, 3)

        XCTAssertTrue(store.buyUpgrade(.velocity))
        XCTAssertTrue(store.isSkillUnlocked(.surge))
        XCTAssertGreaterThan(store.playerTuning.speedMultiplier, 1)
        XCTAssertTrue(store.buyUpgrade(.slots))
        XCTAssertEqual(store.skillSlotCount, 3)
        XCTAssertTrue(store.buyUpgrade(.reserves))
        XCTAssertEqual(store.inventoryCapacity, 5)
        XCTAssertTrue(store.buy(.surge))
        XCTAssertTrue(store.equippedSkills.contains(.surge))
    }

    func testResearchPrerequisitesAndCooldownTuning() {
        let store = makeStore()
        store.addShards(2_000)
        XCTAssertFalse(store.buyUpgrade(.recharge))
        XCTAssertTrue(store.buyUpgrade(.velocity))
        XCTAssertTrue(store.buyUpgrade(.velocity))
        XCTAssertTrue(store.buyUpgrade(.recharge))
        XCTAssertLessThan(store.playerTuning.cooldownMultiplier, 1)
        XCTAssertTrue(store.prerequisitesMet(for: .cryostasis))
    }

    func testExpandedResearchTreeHasFunctionalBranchUpgrades() {
        let store = makeStore()
        store.addShards(10_000)
        XCTAssertEqual(UpgradeKind.allCases.count, 12)
        XCTAssertEqual(UpgradeKind.allCases.filter { $0.branch == .motion }.count, 3)
        XCTAssertEqual(UpgradeKind.allCases.filter { $0.branch == .loadout }.count, 4)
        XCTAssertEqual(UpgradeKind.allCases.filter { $0.branch == .temporal }.count, 5)

        XCTAssertTrue(store.buyUpgrade(.velocity))
        XCTAssertTrue(store.buyUpgrade(.velocity))
        XCTAssertTrue(store.buyUpgrade(.dashCapacitor))
        XCTAssertTrue(store.buyUpgrade(.slots))
        XCTAssertTrue(store.buyUpgrade(.reserves))
        XCTAssertTrue(store.buyUpgrade(.aegis))
        XCTAssertTrue(store.buyUpgrade(.aegis))
        XCTAssertTrue(store.buyUpgrade(.aegis))
        XCTAssertTrue(store.buyUpgrade(.recharge))
        XCTAssertTrue(store.buyUpgrade(.beamForecast))

        let tuning = store.playerTuning
        XCTAssertLessThan(tuning.dashCooldownMultiplier, 1)
        XCTAssertGreaterThan(tuning.shieldGraceBonus, 0.6)
        XCTAssertTrue(tuning.startsShielded)
        XCTAssertGreaterThan(tuning.laserWarningBonus, 0.2)
    }

    func testClearingAllEpochsRaisesDifficultyAndKeepsOldRecords() {
        let store = makeStore()
        let win = SessionResult(time: 10, moves: 10, stars: 1, sparks: 8, echoesFaced: 1)
        for level in LevelCatalog.playable {
            store.recordWin(levelID: level.id, result: win, awardsShard: false)
        }
        XCTAssertTrue(store.isCurrentDifficultyComplete)
        XCTAssertTrue(store.advanceDifficultyIfComplete())
        XCTAssertEqual(store.difficultyCycle, 1)
        XCTAssertEqual(store.completedDifficultyCycles, 1)
        XCTAssertEqual(store.progress(for: LevelCatalog.prototype.id).stars, 0)
        XCTAssertEqual(store.progress(for: LevelCatalog.prototype.id, cycle: 0).stars, 1)
        XCTAssertEqual(store.continueLevel().number, 1)
        XCTAssertEqual(store.points, 777)
    }

    func testResetClearsProgressButKeepsPreferences() {
        let store = makeStore()
        store.soundEnabled = false
        store.persistSettings()
        store.addShards(500)
        store.markTutorialSeen()
        store.recordWin(
            levelID: LevelCatalog.prototype.id,
            result: SessionResult(time: 10, moves: 10, stars: 3, sparks: 6, echoesFaced: 1)
        )
        store.resetProgress()
        XCTAssertEqual(store.totalStars, 0)
        XCTAssertEqual(store.points, 0)
        XCTAssertEqual(store.lives, ProgressStore.startingLives)
        XCTAssertFalse(store.hasSeenTutorial)
        XCTAssertFalse(store.soundEnabled)
    }

    private func makeStore() -> ProgressStore {
        let name = "echo.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return ProgressStore(defaults: defaults)
    }
}
