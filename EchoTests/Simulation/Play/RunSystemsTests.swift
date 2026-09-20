import XCTest
@testable import Echo

extension WorldSimulationTests {
    func testDashCapacitorAndAegisTuningApplyToRun() {
        let sim = WorldSimulation(level: LevelCatalog.prototype)
        sim.configure(tuning: PlayerTuning(
            dashCooldownMultiplier: 0.5,
            shieldGraceBonus: 0.44,
            startsShielded: true
        ))
        XCTAssertEqual(sim.effects.shieldCharges, 1)
        advance(sim, seconds: 0.4, target: Vec2(x: 500, y: 240))
        XCTAssertTrue(sim.tryDash())
        XCTAssertEqual(sim.effects.dashCooldown, sim.config.dashCooldown * 0.5, accuracy: 0.001)
    }

    func testFastSparkRouteBuildsAndExpiresResonance() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        level.playerSpeed = 600
        level.exit = Vec2(x: 900, y: 900)
        level.sparks = [
            SparkSpawn(id: 0, position: Vec2(x: 500, y: 230)),
            SparkSpawn(id: 1, position: Vec2(x: 500, y: 350)),
        ]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 0.35, target: level.sparks[0].position)
        advance(sim, seconds: 0.35, target: level.sparks[1].position)
        XCTAssertEqual(sim.resonanceChain, 2)
        XCTAssertEqual(sim.bestResonance, 2)
        XCTAssertGreaterThan(sim.resonanceRemaining, 2.5)

        advance(sim, seconds: 3.4, target: Vec2(x: 700, y: 350))
        XCTAssertEqual(sim.resonanceChain, 0)
        XCTAssertEqual(sim.bestResonance, 2)
    }

    func testClockStaysFrozenUntilFirstMove() {
        let sim = WorldSimulation(level: LevelCatalog.prototype)
        advance(sim, seconds: 9, target: sim.level.playerStart)
        XCTAssertFalse(sim.hasStarted)
        XCTAssertEqual(sim.echoCount, 0)
        XCTAssertEqual(sim.time, 0, accuracy: 0.001)
        XCTAssertEqual(sim.phase, .playing)
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
        XCTAssertGreaterThanOrEqual(daily.sparkCount, 1)
        let again = LevelCatalog.daily(on: day, calendar: calendar)
        XCTAssertEqual(daily.sparks.map(\.position), again.sparks.map(\.position))
        XCTAssertEqual(daily.id, "daily-2026-09-09")
        XCTAssertFalse(daily.walls.isEmpty)
    }

    func testDailySeedIsCalendarStable() {
        let calendar = Calendar(identifier: .gregorian)
        var a = DateComponents()
        a.year = 2026
        a.month = 1
        a.day = 1
        var b = DateComponents()
        b.year = 2026
        b.month = 1
        b.day = 2
        let first = calendar.date(from: a)!
        let second = calendar.date(from: b)!
        let d1 = LevelCatalog.daily(on: first, calendar: calendar)
        let d2 = LevelCatalog.daily(on: second, calendar: calendar)
        XCTAssertEqual(d1.id, "daily-2026-01-01")
        XCTAssertEqual(d2.id, "daily-2026-01-02")
        XCTAssertEqual(LevelCatalog.daily(on: first, calendar: calendar).sparks.map(\.position), d1.sparks.map(\.position))
    }

    func testRewindRestoresStateAndLeavesGhost() {
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: LevelCatalog.prototype, config: config)
        advance(sim, seconds: 1.6, target: Vec2(x: 500, y: 360))
        let markedTime = sim.time
        let markedPos = sim.playerPosition
        advance(sim, seconds: 1.8, target: Vec2(x: 760, y: 360))
        XCTAssertGreaterThan(sim.time, markedTime + 1)
        XCTAssertTrue(sim.rewind(seconds: 1.8))
        XCTAssertEqual(sim.time, markedTime, accuracy: 0.08)
        XCTAssertEqual(sim.playerPosition.distance(to: markedPos), 0, accuracy: 24)
        XCTAssertEqual(sim.ghosts.count, 1)
        XCTAssertEqual(sim.rewindCharges, 0)
        XCTAssertEqual(sim.phase, .playing)
        XCTAssertFalse(sim.rewind())
    }

    func testSealsAreIndependentOfTimeMovesStars() {
        var result = SessionResult(time: 80, moves: 200, stars: 1, sparks: 6, echoesFaced: 1, bonuses: 0, dashed: true, usedItem: false)
        let seals = LevelCatalog.seals(for: 1)
        XCTAssertEqual(seals.control, .beforeEcho(3))
        XCTAssertEqual(seals.paradox, .noDash)
        XCTAssertTrue(seals.control.met(by: result, parTime: 22))
        XCTAssertFalse(seals.paradox.met(by: result, parTime: 22))
        result.dashed = false
        XCTAssertTrue(seals.paradox.met(by: result, parTime: 22))
    }

    func testActsCoverSeventySevenLevels() {
        XCTAssertEqual(Act.allCases.count, 11)
        let covered = Act.allCases.flatMap { Array($0.range) }
        XCTAssertEqual(covered, Array(1...77))
        XCTAssertEqual(Act.containing(level: 1), .trace)
        XCTAssertEqual(Act.containing(level: 8), .drift)
        XCTAssertEqual(Act.containing(level: 43), .rift)
        XCTAssertEqual(Act.containing(level: 64), .confection)
        XCTAssertEqual(Act.containing(level: 77), .eternity)
    }

    func testEchoForecastDelaysSpawnAndIndicatorTogether() {
        var level = LevelCatalog.prototype
        level.echoInterval = 8
        level.maxEchoes = 2
        level.playerStart = Vec2(x: 200, y: 200)
        level.exit = Vec2(x: 800, y: 800)
        let sim = WorldSimulation(level: level)
        var tuning = PlayerTuning()
        tuning.echoDelayBonus = 2.25
        sim.configure(tuning: tuning)

        advance(sim, seconds: 8.0, target: Vec2(x: 260, y: 200))
        XCTAssertEqual(sim.echoCount, 0)
        XCTAssertEqual(sim.nextEchoIn ?? -1, 2.25, accuracy: 0.08)

        advance(sim, seconds: 2.3, target: Vec2(x: 320, y: 200))
        XCTAssertEqual(sim.echoCount, 1)
        XCTAssertLessThan(sim.nextEchoIn ?? 9, 8.1)
    }

    func testLongRewindKeepsUpgradedHistory() {
        var level = LevelCatalog.prototype
        level.maxEchoes = 0
        level.playerStart = Vec2(x: 180, y: 180)
        var config = SimConfig()
        config.snapshotHz = 60
        config.snapshotWindow = 3
        let sim = WorldSimulation(level: level, config: config)
        var tuning = PlayerTuning()
        tuning.rewindSeconds = 5.25
        sim.configure(tuning: tuning)

        advance(sim, seconds: 8.0, target: Vec2(x: 820, y: 180))
        let before = sim.time
        XCTAssertTrue(sim.rewind(seconds: 5.25))
        XCTAssertEqual(sim.time, before - 5.25, accuracy: 0.12)
    }

    func testMagnetPullsOrbitalSparkOffItsRing() throws {
        var level = LevelCatalog.prototype
        level.walls = []
        level.movers = []
        level.lasers = []
        level.gravityWells = []
        level.rifts = []
        level.gates = []
        level.fields = []
        level.bonuses = []
        level.maxEchoes = 0
        level.playerStart = Vec2(x: 160, y: 200)
        level.exit = Vec2(x: 900, y: 900)
        level.sparks = [
            SparkSpawn(
                id: 0,
                position: Vec2(x: 280, y: 200),
                orbit: SparkOrbit(center: Vec2(x: 200, y: 200), radius: 80, period: 90)
            ),
        ]
        let sim = WorldSimulation(level: level)
        XCTAssertTrue(sim.activate(.magnet))
        XCTAssertTrue(sim.effects.isMagnet)
        advance(sim, seconds: 0.5, target: Vec2(x: 220, y: 200))
        let spark = try XCTUnwrap(sim.sparks.first)
        XCTAssertTrue(spark.magnetHeld || spark.collected)
        if !spark.collected {
            XCTAssertNil(spark.orbit)
            XCTAssertLessThan(spark.position.distance(to: sim.playerPosition), 70)
        }
    }

    func testBlinkFollowsAimInsteadOfExit() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.playerStart = Vec2(x: 200, y: 200)
        level.exit = Vec2(x: 880, y: 880)
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 0.35, target: Vec2(x: 200, y: 780))
        XCTAssertTrue(sim.activate(.blink))
        XCTAssertGreaterThan(sim.playerPosition.y, 280)
        XCTAssertLessThan(sim.playerPosition.x, 280)
    }

    func testPulseDoesNothingWhenNoFutureEchoRemains() {
        var level = LevelCatalog.prototype
        level.maxEchoes = 0
        let sim = WorldSimulation(level: level)
        XCTAssertFalse(sim.activate(.pulse))
        XCTAssertFalse(sim.activate(.chrono))
    }

    func testLateCoreMapsHaveTheirOwnSeals() {
        XCTAssertEqual(LevelCatalog.seals(for: 40).control, .maxEchoes(3))
        XCTAssertEqual(LevelCatalog.seals(for: 47).control, .useRift)
        XCTAssertEqual(LevelCatalog.seals(for: 61).control, .noDash)
        XCTAssertEqual(LevelCatalog.seals(for: 68).control, .useRift)
    }

    func testCollisionCooldownUsesRealDt() {
        var level = LevelCatalog.prototype
        level.echoInterval = 0.4
        level.maxEchoes = 2
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: level, config: config)
        advance(sim, seconds: 1.0, target: Vec2(x: 500, y: 220))
        advance(sim, seconds: 1.2, target: sim.level.playerStart)
        XCTAssertGreaterThanOrEqual(sim.echoCount, 2)
        let before = sim.scarsCreated
        _ = sim.step(dt: 1.0 / 30.0, target: sim.level.playerStart)
        if sim.scarsCreated == before + 1 {
            _ = sim.step(dt: 3.3, target: sim.level.playerStart)
            let scars = sim.scarsCreated
            _ = sim.step(dt: 1.0 / 30.0, target: sim.level.playerStart)
            XCTAssertGreaterThanOrEqual(sim.scarsCreated, scars)
        }
    }

    func asteroidImpactSimulation(material: AsteroidMaterial) -> WorldSimulation {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        level.playerStart = Vec2(x: 500, y: 500)
        level.exit = Vec2(x: 900, y: 900)
        level.sparks = [SparkSpawn(id: 0, position: Vec2(x: 900, y: 100))]
        level.movers = [
            MoverSpawn.bounce(
                id: 0,
                at: Vec2(x: 62.5, y: 180),
                velocity: Vec2(x: -140, y: 0),
                radius: 34,
                material: material
            ),
        ]
        var config = SimConfig()
        config.collisionSlop = 1_000
        return WorldSimulation(level: level, config: config)
    }
}
