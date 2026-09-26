import XCTest
@testable import Echo

final class WristProgressTests: XCTestCase {
    func testThirtySixWristRoomsOpenOneAfterAnother() {
        XCTAssertEqual(WristCatalog.maps.count, 36)
        XCTAssertEqual(WristCatalog.maps.map(\.number), Array(1...36), "Rooms are listed in play order")
        XCTAssertEqual(WristCatalog.maps.map(\.id), (1...36).map { "wrist-\($0)" }, "Room IDs are save data")
        var progress = WristProgress()
        XCTAssertTrue(progress.isPlayable(WristCatalog.maps[0]))
        XCTAssertFalse(progress.isPlayable(WristCatalog.maps[1]))
        progress.record(clear: WristCatalog.maps[0].id, time: 12)
        XCTAssertTrue(progress.isPlayable(WristCatalog.maps[1]))
        XCTAssertEqual(WristCatalog.act(of: WristCatalog.maps[11]), 0)
        XCTAssertEqual(WristCatalog.act(of: WristCatalog.maps[12]), 1)
        XCTAssertEqual(WristCatalog.act(of: WristCatalog.maps[35]), 2)
    }

    /// Every spark, bonus and the exit can be reached past the walls, on the
    /// authored square and on the faces the rooms are stretched to.
    func testEveryWristRoomCanBeCleared() {
        for level in WristCatalog.maps {
            for aspect in [1.0, 1.07, 1.25] {
                let face = WristCatalog.fitted(level, aspect: aspect)
                XCTAssertTrue(EndlessReach.isSolvable(face), "Room \(level.number) \(level.name) at \(aspect) has an objective cut off")
            }
            XCTAssertGreaterThanOrEqual(level.sparks.count, 3, "Room \(level.number) needs a route, not a dash")
            for laser in level.lasers {
                XCTAssertGreaterThanOrEqual(laser.period - laser.activeFor - laser.chargeFor, 2, "Room \(level.number) beam \(laser.id) leaves too little quiet time")
            }
        }
    }

    func testMergeKeepsTheFasterTimeAndReportsOnlyNewClears() {
        var phone = WristProgress()
        phone.record(clear: "wrist-1", time: 20)
        var watch = WristProgress()
        watch.record(clear: "wrist-1", time: 14)
        watch.record(clear: "wrist-2", time: 30)
        XCTAssertEqual(phone.merge(watch), ["wrist-2"])
        XCTAssertEqual(phone.bestTimes["wrist-1"], 14)
        XCTAssertEqual(phone.merge(watch), [])
    }

    func testRelicsUnlockAtFourEightAndTwelveClears() {
        var progress = WristProgress()
        for level in WristCatalog.maps.prefix(3) { progress.record(clear: level.id, time: 10) }
        XCTAssertTrue(progress.relics.isEmpty)
        progress.record(clear: WristCatalog.maps[3].id, time: 10)
        XCTAssertEqual(progress.relics, [.tourbillonTail])
        for level in WristCatalog.maps { progress.record(clear: level.id, time: 10) }
        XCTAssertEqual(progress.relics, WristRelic.allCases)
    }

    @MainActor
    func testPhonePaysShardsOnceAndAppliesRelicPerks() {
        let name = "echo.wrist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = ProgressStore(defaults: defaults)
        let before = store.playerTuning

        var watch = WristProgress()
        for level in WristCatalog.maps { watch.record(clear: level.id, time: level.parTime) }
        XCTAssertEqual(store.mergeWrist(watch), WristCatalog.maps.count * WristProgress.shardsPerMap)
        XCTAssertEqual(store.mergeWrist(watch), 0, "A clear pays only once")
        XCTAssertEqual(store.playerTuning.rewindCharges, before.rewindCharges + 1)
        XCTAssertEqual(store.playerTuning.echoDelayBonus, before.echoDelayBonus + WristProgress.echoDelayRelicBonus, accuracy: 0.0001)
        XCTAssertTrue(store.usesTourbillonTail)
        store.setWristTrail(false)
        XCTAssertFalse(ProgressStore(defaults: defaults).usesTourbillonTail, "The switch survives a relaunch")
        XCTAssertEqual(ProgressStore(defaults: defaults).wrist.cleared.count, WristCatalog.maps.count)
    }
}
