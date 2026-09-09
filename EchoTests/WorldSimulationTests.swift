import XCTest
@testable import Echo

final class PathRecorderTests: XCTestCase {
    func testInterpolatesBetweenSamples() {
        var recorder = PathRecorder()
        recorder.record(time: 0, position: Vec2(x: 0, y: 0))
        recorder.record(time: 1, position: Vec2(x: 10, y: 0))
        let mid = recorder.position(at: 0.5)
        XCTAssertEqual(mid?.x ?? -1, 5, accuracy: 0.001)
        XCTAssertEqual(mid?.y ?? -1, 0, accuracy: 0.001)
    }

    func testClampsOutsideRange() {
        var recorder = PathRecorder()
        recorder.record(time: 1, position: Vec2(x: 4, y: 4))
        recorder.record(time: 2, position: Vec2(x: 8, y: 4))
        XCTAssertEqual(recorder.position(at: 0)?.x, 4)
        XCTAssertEqual(recorder.position(at: 9)?.x, 8)
    }
}

final class StarRatingTests: XCTestCase {
    func testParGivesThreeStars() {
        XCTAssertEqual(StarRating.stars(time: 20, moves: 30, parTime: 22, parMoves: 38), 3)
    }

    func testPointsScaleWithStarsAndBonuses() {
        XCTAssertEqual(StarRating.points(stars: 3, bonuses: 2), 200)
        XCTAssertEqual(StarRating.points(stars: 1, bonuses: 0), 60)
        let result = SessionResult(time: 12, moves: 20, stars: 2, sparks: 6, echoesFaced: 1, bonuses: 1)
        XCTAssertEqual(result.points, 130)
    }

    func testSlowRunGivesOneStar() {
        XCTAssertEqual(StarRating.stars(time: 80, moves: 200, parTime: 22, parMoves: 38), 1)
    }

    func testNearParGivesTwoStars() {
        XCTAssertEqual(StarRating.stars(time: 28, moves: 60, parTime: 22, parMoves: 38), 2)
    }
}

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

    func testCatalogHasTwelvePlayableMaps() {
        XCTAssertEqual(LevelCatalog.playable.count, 12)
        XCTAssertEqual(Set(LevelCatalog.playable.map(\.number)).count, 12)
    }

    func testDailyKeepsACenterSpark() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 9
        let day = calendar.date(from: components)!
        let daily = LevelCatalog.daily(on: day, calendar: calendar)
        XCTAssertTrue(daily.sparks.contains { $0.position.distance(to: Vec2(x: 500, y: 500)) < 1 })
        XCTAssertEqual(daily.sparkCount, 6)
        let again = LevelCatalog.daily(on: day, calendar: calendar)
        XCTAssertEqual(daily.sparks.map(\.position), again.sparks.map(\.position))
    }
}

private func advance(_ sim: WorldSimulation, seconds: TimeInterval, target: Vec2) {
    let steps = Int((seconds * 60).rounded(.up))
    for _ in 0..<steps {
        if sim.phase != .playing { return }
        sim.step(dt: 1.0 / 60.0, target: target)
    }
}
