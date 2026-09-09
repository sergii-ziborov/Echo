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

    func testInventoryCapsAtNine() {
        let store = makeStore()
        store.addShards(BonusKind.freeze.price * 12)
        for _ in 0..<ProgressStore.maxOwned {
            XCTAssertTrue(store.buy(.freeze))
        }
        XCTAssertFalse(store.buy(.freeze))
        XCTAssertEqual(store.count(.freeze), ProgressStore.maxOwned)
    }

    private func makeStore() -> ProgressStore {
        let name = "echo.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return ProgressStore(defaults: defaults)
    }
}
