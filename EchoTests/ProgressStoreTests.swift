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
        XCTAssertEqual(UpgradeKind.allCases.count, 24)
        XCTAssertEqual(UpgradeKind.allCases.filter { $0.branch == .motion }.count, 8)
        XCTAssertEqual(UpgradeKind.allCases.filter { $0.branch == .loadout }.count, 8)
        XCTAssertEqual(UpgradeKind.allCases.filter { $0.branch == .temporal }.count, 8)
        XCTAssertEqual(UpgradeKind.allCases.reduce(0) { $0 + $1.maxLevel }, 117)

        XCTAssertTrue(store.buyUpgrade(.velocity))
        XCTAssertTrue(store.buyUpgrade(.velocity))
        XCTAssertTrue(store.buyUpgrade(.dashCapacitor))
        XCTAssertTrue(store.buyUpgrade(.slots))
        XCTAssertTrue(store.buyUpgrade(.reserves))
        XCTAssertTrue(store.buyUpgrade(.aegis))
        XCTAssertTrue(store.buyUpgrade(.aegis))
        XCTAssertTrue(store.buyUpgrade(.aegis))
        XCTAssertTrue(store.buyUpgrade(.aegis))
        XCTAssertTrue(store.buyUpgrade(.aegis))
        XCTAssertTrue(store.buyUpgrade(.recharge))
        XCTAssertTrue(store.buyUpgrade(.beamForecast))
        XCTAssertTrue(store.buyUpgrade(.beamForecast))

        let tuning = store.playerTuning
        XCTAssertLessThan(tuning.dashCooldownMultiplier, 1)
        XCTAssertGreaterThan(tuning.shieldGraceBonus, 0.6)
        XCTAssertTrue(tuning.startsShielded)
        XCTAssertGreaterThan(tuning.laserWarningBonus, 0.2)
    }

    func testAdvancedResearchNodesChangeTheirPromisedSystems() {
        let store = makeStore()
        store.addShards(20_000)

        func raise(_ kind: UpgradeKind, to target: Int) {
            while store.upgradeLevel(kind) < target {
                XCTAssertTrue(store.buyUpgrade(kind), "Could not raise \(kind.title)")
            }
        }

        raise(.velocity, to: 4)
        raise(.sparkSense, to: 2)
        raise(.surgeMastery, to: 1)
        raise(.dashCapacitor, to: 3)
        raise(.dashImpulse, to: 1)
        raise(.slots, to: 2)
        raise(.reserves, to: 2)
        raise(.fabricator, to: 1)
        raise(.aegis, to: 3)
        raise(.shieldLattice, to: 1)
        raise(.recharge, to: 2)
        raise(.beamForecast, to: 2)
        raise(.cryostasis, to: 2)
        raise(.echoForecast, to: 1)
        raise(.crystalMemory, to: 1)
        raise(.phaseResearch, to: 2)
        raise(.fieldAmplifier, to: 1)

        let tuning = store.playerTuning
        XCTAssertGreaterThan(tuning.pickupRadiusBonus, 0)
        XCTAssertGreaterThan(tuning.surgeBonus, 0)
        XCTAssertGreaterThan(tuning.dashDurationBonus, 0)
        XCTAssertGreaterThan(tuning.timedEffectMultiplier, 1)
        XCTAssertGreaterThan(tuning.echoDelayBonus, 0)
        XCTAssertGreaterThan(tuning.crystalRewardBonus, 0)
        XCTAssertLessThan(store.skillPrice(.freeze), BonusKind.freeze.price)
    }

    func testDeepResearchUnlocksFourDistinctLateGameAbilities() {
        let store = makeStore()
        store.addShards(50_000)

        func raise(_ kind: UpgradeKind, to target: Int) {
            while store.upgradeLevel(kind) < target {
                XCTAssertTrue(store.buyUpgrade(kind), "Could not raise \(kind.title)")
            }
        }

        raise(.velocity, to: 2)
        raise(.dashCapacitor, to: 3)
        raise(.slots, to: 2)
        raise(.reserves, to: 1)
        raise(.aegis, to: 2)
        raise(.recharge, to: 3)
        raise(.beamForecast, to: 2)
        raise(.cryostasis, to: 2)
        raise(.magnetism, to: 2)
        raise(.repulseResearch, to: 1)
        raise(.blinkResearch, to: 1)
        raise(.prismResearch, to: 1)
        raise(.anchorResearch, to: 1)

        XCTAssertTrue(store.isSkillUnlocked(.anchor))
        XCTAssertTrue(store.isSkillUnlocked(.repulse))
        XCTAssertTrue(store.isSkillUnlocked(.prism))
        XCTAssertTrue(store.isSkillUnlocked(.blink))
        XCTAssertLessThan(store.playerTuning.anchorTimeScale, 0.44)
        XCTAssertGreaterThan(store.playerTuning.repulseRadius, 160)
        XCTAssertGreaterThan(store.playerTuning.blinkDistance, 165)
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
        store.soundVolume = 0.37
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
        XCTAssertEqual(store.soundVolume, 0.37, accuracy: 0.001)
    }

    func testSoundVolumePersistsAndClampsWhenReloaded() {
        let name = "echo.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)

        let store = ProgressStore(defaults: defaults)
        store.soundVolume = 0.61
        store.persistSettings()
        XCTAssertEqual(ProgressStore(defaults: defaults).soundVolume, 0.61, accuracy: 0.001)

        defaults.set(4.0, forKey: "echo.settings.soundVolume")
        XCTAssertEqual(ProgressStore(defaults: defaults).soundVolume, 1, accuracy: 0.001)
    }

    private func makeStore() -> ProgressStore {
        let name = "echo.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return ProgressStore(defaults: defaults)
    }
}
