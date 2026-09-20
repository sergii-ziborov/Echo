import XCTest
@testable import Echo

final class WorldSimulationTests: XCTestCase {
    func testEchoSpawnsOnIntervalAndLags() {
        let sim = WorldSimulation(level: LevelCatalog.prototype)
        let start = sim.playerPosition
        advance(sim, seconds: 8.05, target: Vec2(x: 780, y: start.y))
        XCTAssertEqual(sim.echoCount, 1)
        XCTAssertEqual(sim.echoes[0].distance(to: start), 0, accuracy: 40)
        XCTAssertGreaterThan(sim.playerPosition.distance(to: start), 100)
    }

    func testWarningFiresBeforeSpawn() {
        let sim = WorldSimulation(level: LevelCatalog.prototype)
        var sawWarning = false
        var warningIndex: Int?
        for _ in 0..<500 {
            let events = sim.step(dt: 1.0 / 60.0, target: Vec2(x: 700, y: 400))
            for event in events {
                if case .echoWillSpawn(let index, let remaining) = event {
                    sawWarning = true
                    warningIndex = index
                    XCTAssertLessThanOrEqual(remaining, sim.level.warningLead + 0.05)
                    XCTAssertEqual(sim.echoCount, 0)
                }
            }
            if sawWarning { break }
        }
        XCTAssertTrue(sawWarning)
        XCTAssertEqual(warningIndex, 0)
    }

    func testMaxFourEchoes() {
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: LevelCatalog.prototype, config: config)
        advance(sim, seconds: 33, target: Vec2(x: 200, y: 800))
        XCTAssertEqual(sim.echoCount, 4)
        XCTAssertNil(sim.nextEchoIn)
    }

    func testStandingStillDiesWhenEchoArrives() {
        let sim = WorldSimulation(level: LevelCatalog.prototype)
        // Leave spawn so the first frames aren't a self-collision, then return and wait.
        advance(sim, seconds: 1.2, target: Vec2(x: 500, y: 260))
        advance(sim, seconds: 1.2, target: sim.level.playerStart)
        XCTAssertEqual(sim.phase, .playing)
        advance(sim, seconds: 8, target: sim.level.playerStart)
        XCTAssertEqual(sim.phase, .dead)
        if case .echo(let index, let delay) = sim.deathCause {
            XCTAssertEqual(index, 0)
            XCTAssertEqual(delay, 8, accuracy: 0.01)
        } else {
            XCTFail("expected echo death, got \(String(describing: sim.deathCause))")
        }
    }

    func testWallsBlockWithoutKilling() {
        var level = LevelCatalog.prototype
        level.walls = [AABB(x: 450, y: 200, width: 100, height: 80)]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 3, target: Vec2(x: 500, y: 800))
        XCTAssertEqual(sim.phase, .playing)
        XCTAssertLessThan(sim.playerPosition.y, 220)
    }

    func testExitStaysClosedUntilAllSparksAreCollected() {
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: LevelCatalog.prototype, config: config)
        XCTAssertFalse(sim.exitOpen)
        for spark in sim.level.sparks {
            if sim.sparksRemaining <= 1 { break }
            advance(sim, seconds: 5, target: spark.position)
        }
        XCTAssertEqual(sim.sparksRemaining, 1)
        XCTAssertFalse(sim.exitOpen)
        if let last = sim.sparks.first(where: { !$0.collected }) {
            advance(sim, seconds: 5, target: last.position)
        }
        XCTAssertTrue(sim.exitOpen)
        advance(sim, seconds: 4, target: sim.level.exit)
        XCTAssertEqual(sim.phase, .won)
        XCTAssertEqual(sim.result?.sparks, 6)
    }

    func testPrototypeForcesInteriorRouting() {
        let level = LevelCatalog.prototype
        let outerBand: (Vec2) -> Bool = { p in
            p.x < 110 || p.x > 890 || p.y < 110 || p.y > 890
        }
        let interior = level.sparks.filter { !outerBand($0.position) }
        XCTAssertFalse(interior.isEmpty, "at least one spark must sit off the outer ring")
        XCTAssertTrue(level.sparks.contains { $0.position.distance(to: level.exit) < 1 })
        XCTAssertEqual(level.exit, Vec2(x: 500, y: 500))
        XCTAssertEqual(level.maxEchoes, 4)
        XCTAssertEqual(level.sparkCount, 6)
    }

    func testSparksAreNotEmbeddedInWalls() {
        for level in LevelCatalog.playable {
            for spark in level.sparks {
                XCTAssertTrue(
                    LayoutSafety.isClear(spark.position, walls: level.walls, clearance: 28),
                    "spark \(spark.id) in \(level.name) sits inside a wall at \(spark.position)"
                )
            }
            XCTAssertTrue(
                LayoutSafety.isClear(level.exit, walls: level.walls, clearance: 28),
                "exit in \(level.name) sits inside a wall"
            )
        }
    }

    func testShieldPickup() {
        var level = LevelCatalog.prototype
        level.bonuses = [BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 500, y: 200))]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 1.0, target: Vec2(x: 500, y: 200))
        XCTAssertEqual(sim.effects.shieldCharges, 1)
        XCTAssertEqual(sim.bonusesCollected, 1)
        XCTAssertEqual(sim.phase, .playing)
    }

    func testFreezePausesEchoPlayback() {
        var level = LevelCatalog.prototype
        level.bonuses = [BonusSpawn(id: 0, kind: .freeze, position: Vec2(x: 700, y: 140))]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 1.0, target: Vec2(x: 700, y: 140))
        XCTAssertTrue(sim.effects.isFrozen)
        let playback = sim.playbackTime
        advance(sim, seconds: 1.0, target: Vec2(x: 800, y: 140))
        XCTAssertEqual(sim.playbackTime, playback, accuracy: 0.05)
    }

    func testDashEntersCooldown() {
        let sim = WorldSimulation(level: LevelCatalog.prototype)
        advance(sim, seconds: 0.4, target: Vec2(x: 500, y: 220))
        XCTAssertTrue(sim.hasStarted)
        XCTAssertTrue(sim.tryDash())
        XCTAssertTrue(sim.effects.isSurging)
        XCTAssertFalse(sim.tryDash())
    }

    func testActivateAppliesShopBonus() {
        let sim = WorldSimulation(level: LevelCatalog.prototype)
        XCTAssertTrue(sim.activate(.freeze))
        XCTAssertTrue(sim.effects.isFrozen)
        XCTAssertTrue(sim.activate(.shield))
        XCTAssertEqual(sim.effects.shieldCharges, 1)
        XCTAssertTrue(sim.activate(.surge))
        XCTAssertTrue(sim.effects.isSurging)
    }

    func testCatalogHasSeventySevenPlayableMaps() {
        XCTAssertEqual(LevelCatalog.playable.count, 77)
        XCTAssertEqual(Set(LevelCatalog.playable.map(\.number)).count, 77)
        XCTAssertEqual(Set(LevelCatalog.playable.map(\.name)).count, 77)
        XCTAssertEqual(Set(LevelCatalog.playable.map(\.theme)).count, ArenaTheme.allCases.count)
        XCTAssertEqual(Set(LevelCatalog.playable.map(\.atmosphere)).count, ArenaAtmosphere.allCases.count)
        XCTAssertTrue(
            LevelCatalog.playable.allSatisfy { $0.decorations.count >= 3 },
            "every authored map should have its own environmental landmarks"
        )
    }

    func testSignatureMapsHaveDesignedSetpieces() throws {
        let ricochet = try XCTUnwrap(LevelCatalog.level(number: 33))
        XCTAssertGreaterThanOrEqual(ricochet.walls.count, 10)
        XCTAssertGreaterThanOrEqual(ricochet.decorations.count, 7)
        XCTAssertTrue(ricochet.decorations.contains {
            if case .lane = $0.kind { return true }
            return false
        })
        for mover in ricochet.movers {
            XCTAssertTrue(
                LayoutSafety.isClear(mover.position, walls: ricochet.walls, clearance: mover.radius),
                "Ricochet mover \(mover.id) starts inside a wall"
            )
        }

        let horizon = try XCTUnwrap(LevelCatalog.level(number: 36))
        XCTAssertGreaterThanOrEqual(horizon.lasers.count, 4)
        XCTAssertGreaterThanOrEqual(horizon.decorations.count, 7)
        XCTAssertGreaterThanOrEqual(horizon.sparks.filter { $0.orbit != nil }.count, 3)
        XCTAssertTrue(horizon.decorations.contains {
            if case .reactor = $0.kind { return true }
            return false
        })
        XCTAssertTrue(horizon.lasers.contains {
            if case .sweep = $0.motion { return true }
            return false
        })
    }
}
