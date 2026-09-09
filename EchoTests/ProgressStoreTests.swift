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

    func testWinAwardsPointsFromStars() {
        let store = makeStore()
        let result = SessionResult(time: 10, moves: 10, stars: 3, sparks: 6, echoesFaced: 1, bonuses: 2)
        store.recordWin(levelID: "test", result: result)
        XCTAssertEqual(store.points, result.points)
        XCTAssertEqual(result.points, 200)
        XCTAssertEqual(store.progress(for: "test").stars, 3)
    }

    func testInventoryCapsAtNine() {
        let store = makeStore()
        store.addShards(BonusKind.pulse.price * 12)
        for _ in 0..<ProgressStore.maxOwned {
            XCTAssertTrue(store.buy(.pulse))
        }
        XCTAssertFalse(store.buy(.pulse))
        XCTAssertEqual(store.count(.pulse), ProgressStore.maxOwned)
    }

    private func makeStore() -> ProgressStore {
        let name = "echo.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return ProgressStore(defaults: defaults)
    }
}
