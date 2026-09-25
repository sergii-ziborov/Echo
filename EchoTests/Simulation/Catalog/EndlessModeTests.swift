import XCTest
@testable import Echo

final class EndlessModeTests: XCTestCase {
    private let seeds: [UInt64] = [1, 0xEC40_D17E, 0x2545_F491_4F6C_DD1D, 77, 0xFFFF_FFFF_FFFF_FFF0]

    func testEveryDepthIsSolvableAndPassesTheGeometryAudit() {
        var levels: [LevelDefinition] = []
        for seed in seeds {
            for depth in 1...30 {
                let level = EndlessGenerator.level(EndlessKey(seed: seed, depth: depth))
                XCTAssertTrue(EndlessReach.isSolvable(level), "seed \(seed) depth \(depth)")
                XCTAssertEqual(level.id, EndlessKey(seed: seed, depth: depth).levelID)
                XCTAssertFalse(level.movers.contains { $0.position.distance(to: level.playerStart) < 200 }, "a rock spawns on the orb")
                levels.append(level)
            }
        }
        let issues = LevelGeometryAuditTests().audit(levels)
        XCTAssertTrue(issues.isEmpty, issues.prefix(12).joined(separator: "\n"))
    }

    func testTheSameSeedAndDepthAlwaysBuildTheSameArena() {
        let key = EndlessKey(seed: 0xEC40_D17E, depth: 9)
        XCTAssertEqual(EndlessGenerator.level(key), EndlessGenerator.level(key))
        XCTAssertNotEqual(EndlessGenerator.level(key).walls, EndlessGenerator.level(key.next).walls)
        XCTAssertNotEqual(
            EndlessGenerator.level(EndlessKey(seed: 1, depth: 3)).sparks.map(\.position),
            EndlessGenerator.level(EndlessKey(seed: 2, depth: 3)).sparks.map(\.position)
        )
    }

    func testPressureRampsAndLevelsOff() {
        let shallow = EndlessPressure(depth: 1)
        let deep = EndlessPressure(depth: 40)
        XCTAssertGreaterThan(shallow.echoInterval, deep.echoInterval)
        XCTAssertLessThan(shallow.rocks, deep.rocks)
        XCTAssertLessThanOrEqual(deep.rocks, 6)
        XCTAssertGreaterThanOrEqual(deep.echoInterval, 4.6)
        XCTAssertEqual(shallow.lasers, 0)
        XCTAssertEqual(Set(EndlessPressure(depth: 2).materials), [.basalt, .ice, .crystal, .alloy])
        XCTAssertEqual(Set(EndlessPressure(depth: 9).materials), Set(AsteroidMaterial.allCases))
    }

    func testRecordBanksDepthsAndEndsRuns() {
        var record = EndlessRecord()
        let run = EndlessKey(seed: 42, depth: 1)
        record.start(run)
        record.cleared(run)
        record.cleared(run.next)
        XCTAssertEqual(record.bestDepth, 2)
        XCTAssertEqual(record.depthsCleared, 2)
        XCTAssertEqual(record.current, EndlessKey(seed: 42, depth: 3))
        record.end(EndlessKey(seed: 7, depth: 1))
        XCTAssertNotNil(record.current, "Ending another run leaves this one alone")
        record.end(run)
        XCTAssertNil(record.current)
        XCTAssertEqual(record.runs, 1)
    }

    func testTheWatchRemoteBuildsTheSameEndlessArena() throws {
        let key = EndlessKey(seed: 0xEC40_D17E, depth: 12)
        let recipe = RemoteLevel(id: key.levelID, cycle: 0, aspect: 812.0 / 375.0, endless: key)
        let received = try XCTUnwrap(RemoteLevel(data: recipe.data))
        XCTAssertEqual(received.build(), recipe.build())
        XCTAssertEqual(received.build().id, key.levelID)
    }

    @MainActor
    func testProgressPersistsTheRecord() {
        let defaults = UserDefaults(suiteName: "EndlessModeTests")!
        defaults.removePersistentDomain(forName: "EndlessModeTests")
        let store = ProgressStore(defaults: defaults)
        let run = store.startEndlessRun(EndlessKey(seed: 9, depth: 1))
        let shards = store.shards
        let result = SessionResult(time: 30, moves: 50, stars: 2, sparks: 5, echoesFaced: 3)
        let awarded = store.recordEndlessClear(run, result: result)
        XCTAssertEqual(store.shards, shards + awarded)
        XCTAssertEqual(ProgressStore(defaults: defaults).endless.bestDepth, 1)
        store.resetProgress()
        XCTAssertEqual(ProgressStore(defaults: defaults).endless, EndlessRecord())
    }
}
