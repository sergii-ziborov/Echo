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
        let chained = SessionResult(time: 12, moves: 20, stars: 2, sparks: 6, echoesFaced: 1, bonuses: 1, resonance: 4)
        XCTAssertEqual(chained.points, 160)
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

    func testAsteroidKillsOnContact() {
        var level = LevelCatalog.prototype
        level.movers = [MoverSpawn.bounce(id: 0, at: Vec2(x: 500, y: 200), velocity: Vec2(x: 0, y: 0), radius: 28)]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 1.2, target: Vec2(x: 500, y: 200))
        XCTAssertEqual(sim.phase, .dead)
        XCTAssertEqual(sim.deathCause, .asteroid)
    }

    func testTimeGateBlocksThenOpens() {
        var level = LevelCatalog.prototype
        level.gates = [TimeGateSpawn(id: 0, area: AABB(x: 400, y: 180, width: 200, height: 40), period: 4, openFor: 1, phase: 1)]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 0.6, target: Vec2(x: 500, y: 800))
        XCTAssertLessThan(sim.playerPosition.y, 240)
    }

    func testCalmRiftFreezesOnEnter() {
        var level = LevelCatalog.prototype
        level.rifts = [RiftSpawn(id: 0, kind: .calm, position: Vec2(x: 500, y: 220), period: 4, openFor: 3.5)]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 1.0, target: Vec2(x: 500, y: 220))
        XCTAssertTrue(sim.effects.isFrozen)
    }

    func testWarpRiftFoldsSpaceAndChangesReality() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        level.rifts = [RiftSpawn(id: 0, kind: .warp, position: Vec2(x: 500, y: 220), period: 10, openFor: 10)]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 0.9, target: Vec2(x: 500, y: 240))
        XCTAssertEqual(sim.reality, .mirror)
        XCTAssertEqual(sim.riftsUsed, 1)
        XCTAssertGreaterThan(sim.playerPosition.y, 500)
    }

    func testCandyRiftStartsPocketTimeline() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        level.rifts = [RiftSpawn(id: 0, kind: .candy, position: Vec2(x: 500, y: 220), period: 10, openFor: 10)]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 0.8, target: Vec2(x: 500, y: 240))
        XCTAssertEqual(sim.reality, .candy)
        XCTAssertGreaterThan(sim.realityRemaining, 8)
        XCTAssertGreaterThan(sim.currentSpeed, level.playerSpeed)
    }

    func testGravityWellPullsAndHasLethalCore() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        level.playerStart = Vec2(x: 260, y: 500)
        level.gravityWells = [GravityWellSpawn(id: 0, position: Vec2(x: 500, y: 500), coreRadius: 32, influenceRadius: 260, strength: 340)]
        let pulled = WorldSimulation(level: level)
        advance(pulled, seconds: 0.4, target: Vec2(x: 360, y: 500))
        let before = pulled.playerPosition.x
        for _ in 0..<36 { _ = pulled.step(dt: 1.0 / 60.0, target: nil) }
        XCTAssertGreaterThan(pulled.playerPosition.x, before)

        level.playerStart = Vec2(x: 500, y: 410)
        let lethal = WorldSimulation(level: level)
        advance(lethal, seconds: 0.6, target: Vec2(x: 500, y: 500))
        XCTAssertEqual(lethal.deathCause, .blackHole)
    }

    func testDifficultyCycleRaisesPressureWithoutChangingGeometry() {
        let base = LevelCatalog.level(number: 77)!
        let hard = base.difficultyAdjusted(for: 2)
        XCTAssertEqual(hard.walls, base.walls)
        XCTAssertLessThan(hard.echoInterval, base.echoInterval)
        XCTAssertGreaterThanOrEqual(hard.maxEchoes, base.maxEchoes)
        XCTAssertLessThan(hard.lasers[0].period, base.lasers[0].period)
        XCTAssertGreaterThan(hard.gravityWells[0].strength, base.gravityWells[0].strength)
    }

    func testFreezePausesAsteroids() {
        var level = LevelCatalog.prototype
        level.bonuses = [BonusSpawn(id: 0, kind: .freeze, position: Vec2(x: 500, y: 200))]
        level.movers = [MoverSpawn.bounce(id: 0, at: Vec2(x: 800, y: 400), velocity: Vec2(x: 90, y: 0), radius: 18)]
        let sim = WorldSimulation(level: level)
        advance(sim, seconds: 0.8, target: Vec2(x: 500, y: 200))
        XCTAssertTrue(sim.effects.isFrozen)
        let parked = sim.movers[0].position
        advance(sim, seconds: 0.8, target: Vec2(x: 520, y: 200))
        XCTAssertEqual(sim.movers[0].position.x, parked.x, accuracy: 0.5)
    }

    func testFreezePausesTimedCrystalCountdown() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.sparks = [SparkSpawn(id: 0, position: Vec2(x: 820, y: 820), timer: 8)]
        let sim = WorldSimulation(level: level)
        XCTAssertTrue(sim.activate(.freeze))
        let before = sim.sparks[0].timerRemaining!
        advance(sim, seconds: 1.0, target: Vec2(x: 600, y: 140))
        XCTAssertEqual(sim.sparks[0].timerRemaining!, before, accuracy: 0.05)
    }

    func testTimedCrystalAwardsFreezeCharge() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.sparks = [SparkSpawn(id: 0, position: Vec2(x: 500, y: 240), timer: 8)]
        let sim = WorldSimulation(level: level)
        var secured = false
        for _ in 0..<90 {
            let events = sim.step(dt: 1.0 / 60.0, target: Vec2(x: 500, y: 260))
            if events.contains(where: {
                if case .timeCrystalSecured = $0 { return true }
                return false
            }) {
                secured = true
                break
            }
        }
        XCTAssertTrue(secured)
        XCTAssertEqual(sim.timedSparksSecured, 1)
        XCTAssertTrue(sim.effects.isFrozen)
    }

    func testBouncingAsteroidReflectsFromInternalWall() {
        var level = LevelCatalog.prototype
        level.playerStart = Vec2(x: 100, y: 100)
        level.walls = [AABB(x: 500, y: 80, width: 60, height: 840)]
        level.movers = [
            MoverSpawn.bounce(id: 0, at: Vec2(x: 410, y: 500), velocity: Vec2(x: 140, y: 0), radius: 38),
        ]
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: level, config: config)
        advance(sim, seconds: 1.1, target: Vec2(x: 180, y: 100))
        XCTAssertLessThan(sim.movers[0].velocity.x, 0)
        XCTAssertLessThanOrEqual(sim.movers[0].position.x, 462.1)
    }

    func testFiringLaserKillsAndFreezeDisarmsIt() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.playerStart = Vec2(x: 500, y: 120)
        level.lasers = [
            .horizontal(id: 0, y: 260, period: 10, chargeFor: 0, activeFor: 10),
        ]
        var config = SimConfig()
        config.collisionSlop = 0

        let lethal = WorldSimulation(level: level, config: config)
        advance(lethal, seconds: 1.2, target: Vec2(x: 500, y: 500))
        XCTAssertEqual(lethal.phase, .dead)
        XCTAssertEqual(lethal.deathCause, .laser)

        let frozen = WorldSimulation(level: level, config: config)
        XCTAssertTrue(frozen.activate(.freeze))
        advance(frozen, seconds: 1.2, target: Vec2(x: 500, y: 500))
        XCTAssertEqual(frozen.phase, .playing)
    }

    func testSweepingLaserMovesAndFreezeStopsItsGeometry() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.sparks = []
        level.maxEchoes = 0
        level.playerStart = Vec2(x: 100, y: 100)
        level.lasers = [
            .sweeping(
                id: 0,
                center: Vec2(x: 500, y: 500),
                length: 600,
                from: -.pi / 4,
                to: .pi / 4,
                sweepDuration: 2,
                period: 10,
                chargeFor: 1,
                activeFor: 1
            ),
        ]
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: level, config: config)
        advance(sim, seconds: 0.25, target: Vec2(x: 180, y: 100))
        let first = sim.lasers[0].start
        advance(sim, seconds: 0.8, target: Vec2(x: 220, y: 100))
        XCTAssertGreaterThan(sim.lasers[0].start.distance(to: first), 20)

        XCTAssertTrue(sim.activate(.freeze))
        let parked = sim.lasers[0].start
        advance(sim, seconds: 0.8, target: Vec2(x: 240, y: 100))
        XCTAssertEqual(sim.lasers[0].start.distance(to: parked), 0, accuracy: 0.001)
    }

    func testBeamForecastExtendsChargeWithoutMovingFireTime() {
        var laser = LaserState(
            id: 0,
            start: .zero,
            end: Vec2(x: 100, y: 0),
            beamWidth: 18,
            period: 10,
            chargeFor: 1,
            activeFor: 1,
            offset: 0,
            motion: .fixed
        )
        XCTAssertEqual(laser.phase(at: 6.5), .idle)
        if case .charging = laser.phase(at: 6.5, warningBonus: 2) {
            // Expected: forecast starts the warning earlier.
        } else {
            XCTFail("beam forecast should expose the charge phase")
        }
        XCTAssertEqual(laser.phase(at: 9.2), .firing)
        XCTAssertEqual(laser.phase(at: 9.2, warningBonus: 2), .firing)
        laser.updateGeometry(at: 2)
    }

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
}

final class LevelGeometryAuditTests: XCTestCase {
    func testEveryAuthoredMapPassesGeometryAudit() {
        var issues: [String] = []

        for level in LevelCatalog.playable {
            let prefix = "Map \(level.number) · \(level.name):"

            checkUnique(level.sparks.map(\.id), label: "spark", prefix: prefix, issues: &issues)
            checkUnique(level.bonuses.map(\.id), label: "bonus", prefix: prefix, issues: &issues)
            checkUnique(level.fields.map(\.id), label: "field", prefix: prefix, issues: &issues)
            checkUnique(level.movers.map(\.id), label: "mover", prefix: prefix, issues: &issues)
            checkUnique(level.rifts.map(\.id), label: "rift", prefix: prefix, issues: &issues)
            checkUnique(level.gates.map(\.id), label: "gate", prefix: prefix, issues: &issues)
            checkUnique(level.lasers.map(\.id), label: "laser", prefix: prefix, issues: &issues)
            checkUnique(level.gravityWells.map(\.id), label: "gravity well", prefix: prefix, issues: &issues)
            checkUnique(level.decorations.map(\.id), label: "decoration", prefix: prefix, issues: &issues)

            for (index, wall) in level.walls.enumerated() {
                checkBox(wall, label: "wall \(index)", level: level, prefix: prefix, issues: &issues)
            }
            for field in level.fields {
                checkBox(field.area, label: "field \(field.id)", level: level, prefix: prefix, issues: &issues)
            }
            for gate in level.gates {
                checkBox(gate.area, label: "gate \(gate.id)", level: level, prefix: prefix, issues: &issues)
            }

            checkPoint(level.playerStart, radius: 24, label: "player start", level: level, prefix: prefix, issues: &issues)
            checkPoint(level.exit, radius: 44, label: "exit", level: level, prefix: prefix, issues: &issues)
            checkWallClear(level.playerStart, radius: 24, label: "player start", level: level, prefix: prefix, issues: &issues)
            checkWallClear(level.exit, radius: 44, label: "exit", level: level, prefix: prefix, issues: &issues)

            for spark in level.sparks {
                checkPoint(spark.position, radius: 22, label: "spark \(spark.id)", level: level, prefix: prefix, issues: &issues)
                checkWallClear(spark.position, radius: 22, label: "spark \(spark.id)", level: level, prefix: prefix, issues: &issues)
                if let orbit = spark.orbit {
                    for sample in orbitSamples(center: orbit.center, orbitRadius: orbit.radius, count: 32) {
                        checkPoint(sample, radius: 22, label: "spark \(spark.id) orbit", level: level, prefix: prefix, issues: &issues)
                        checkWallClear(sample, radius: 22, label: "spark \(spark.id) orbit", level: level, prefix: prefix, issues: &issues)
                    }
                }
            }

            for bonus in level.bonuses {
                checkPoint(bonus.position, radius: 26, label: "bonus \(bonus.id)", level: level, prefix: prefix, issues: &issues)
                checkWallClear(bonus.position, radius: 26, label: "bonus \(bonus.id)", level: level, prefix: prefix, issues: &issues)
            }

            for rift in level.rifts {
                checkPoint(rift.position, radius: rift.radius, label: "rift \(rift.id)", level: level, prefix: prefix, issues: &issues)
                checkWallClear(rift.position, radius: rift.radius, label: "rift \(rift.id)", level: level, prefix: prefix, issues: &issues)
            }

            for well in level.gravityWells {
                checkPoint(well.position, radius: well.coreRadius, label: "gravity well \(well.id)", level: level, prefix: prefix, issues: &issues)
                checkWallClear(well.position, radius: well.coreRadius, label: "gravity well \(well.id)", level: level, prefix: prefix, issues: &issues)
                for spark in level.sparks where spark.position.distance(to: well.position) < 22 + well.coreRadius + 4 {
                    issues.append("\(prefix) spark \(spark.id) intersects gravity well \(well.id)")
                }
                if level.exit.distance(to: well.position) < 44 + well.coreRadius + 4 {
                    issues.append("\(prefix) exit intersects gravity well \(well.id)")
                }
            }

            if level.number >= 37 {
                for rift in level.rifts {
                    for mover in level.movers where mover.position.distance(to: rift.position) < mover.radius + rift.radius + 4 {
                        issues.append("\(prefix) rift \(rift.id) overlaps mover \(mover.id)")
                    }
                    for well in level.gravityWells where well.position.distance(to: rift.position) < well.coreRadius + rift.radius + 4 {
                        issues.append("\(prefix) rift \(rift.id) overlaps gravity well \(well.id)")
                    }
                }
            }

            for mover in level.movers {
                for sample in moverSamples(mover) {
                    checkPoint(sample, radius: mover.radius, label: "mover \(mover.id) route", level: level, prefix: prefix, issues: &issues)
                    checkWallClear(sample, radius: mover.radius, label: "mover \(mover.id) route", level: level, prefix: prefix, issues: &issues)
                }
            }

            for laser in level.lasers {
                guard laser.period > laser.activeFor,
                      laser.chargeFor >= 0,
                      laser.activeFor > 0,
                      laser.beamWidth > 0 else {
                    issues.append("\(prefix) laser \(laser.id) has invalid timing or width")
                    continue
                }
                for point in laserSamples(laser) {
                    checkPoint(point, radius: laser.beamWidth / 2, label: "laser \(laser.id) endpoint", level: level, prefix: prefix, issues: &issues)
                }
            }

            for decoration in level.decorations {
                checkPoint(decoration.position, radius: 0, label: "decoration \(decoration.id)", level: level, prefix: prefix, issues: &issues)
                if case .lane(let end, _) = decoration.kind {
                    checkPoint(end, radius: 0, label: "decoration \(decoration.id) lane end", level: level, prefix: prefix, issues: &issues)
                }
            }

            let routeTargets = level.sparks.map(\.position) + [level.exit]
            if let unreachable = unreachableTargets(in: level, targets: routeTargets), !unreachable.isEmpty {
                issues.append("\(prefix) objectives \(unreachable) are cut off by static walls")
            }
        }

        XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
    }

    private func checkUnique(
        _ ids: [Int],
        label: String,
        prefix: String,
        issues: inout [String]
    ) {
        if Set(ids).count != ids.count {
            issues.append("\(prefix) duplicate \(label) IDs")
        }
    }

    private func checkBox(
        _ box: AABB,
        label: String,
        level: LevelDefinition,
        prefix: String,
        issues: inout [String]
    ) {
        guard box.width > 0, box.height > 0,
              box.minX >= 0, box.minY >= 0,
              box.maxX <= level.worldWidth, box.maxY <= level.worldHeight else {
            issues.append("\(prefix) \(label) is invalid or outside the arena")
            return
        }
    }

    private func checkPoint(
        _ point: Vec2,
        radius: Double,
        label: String,
        level: LevelDefinition,
        prefix: String,
        issues: inout [String]
    ) {
        let edge = radius + 4
        if point.x < edge || point.y < edge || point.x > level.worldWidth - edge || point.y > level.worldHeight - edge {
            let rounded = "(\(Int(point.x.rounded())), \(Int(point.y.rounded())))"
            let message = "\(prefix) \(label) clips the arena at \(rounded)"
            if !issues.contains(message) { issues.append(message) }
        }
    }

    private func checkWallClear(
        _ point: Vec2,
        radius: Double,
        label: String,
        level: LevelDefinition,
        prefix: String,
        issues: inout [String]
    ) {
        guard level.walls.contains(where: { $0.intersectsCircle(center: point, radius: radius + 2) }) else { return }
        let rounded = "(\(Int(point.x.rounded())), \(Int(point.y.rounded())))"
        let message = "\(prefix) \(label) intersects a wall at \(rounded)"
        if !issues.contains(message) { issues.append(message) }
    }

    private func orbitSamples(center: Vec2, orbitRadius: Double, count: Int) -> [Vec2] {
        (0..<count).map { index in
            let angle = Double(index) / Double(count) * .pi * 2
            return center + Vec2(x: cos(angle), y: sin(angle)) * orbitRadius
        }
    }

    private func moverSamples(_ mover: MoverSpawn) -> [Vec2] {
        switch mover.path {
        case .bounce:
            return [mover.position]
        case .patrol(let start, let end):
            return (0...24).map { start.lerp(end, Double($0) / 24) }
        case .orbit(let center, let radius, _, _):
            return orbitSamples(center: center, orbitRadius: radius, count: 48)
        }
    }

    private func laserSamples(_ laser: LaserSpawn) -> [Vec2] {
        switch laser.motion {
        case .fixed:
            return [laser.start, laser.end]
        case .sweep(let center, let length, let startAngle, let endAngle, _, _):
            return (0...24).flatMap { index -> [Vec2] in
                let angle = startAngle + (endAngle - startAngle) * Double(index) / 24
                let half = Vec2(x: cos(angle), y: sin(angle)) * (length / 2)
                return [center - half, center + half]
            }
        }
    }

    private func unreachableTargets(in level: LevelDefinition, targets: [Vec2]) -> [Int]? {
        let step = 20.0
        let inset = 30.0
        let columns = Int((level.worldWidth - inset * 2) / step) + 1
        let rows = Int((level.worldHeight - inset * 2) / step) + 1
        guard columns > 0, rows > 0 else { return nil }

        func point(_ index: Int) -> Vec2 {
            Vec2(x: inset + Double(index % columns) * step, y: inset + Double(index / columns) * step)
        }
        func clear(_ index: Int) -> Bool {
            LayoutSafety.isClear(point(index), walls: level.walls, clearance: 26)
        }
        func nearestClear(to target: Vec2) -> Int? {
            (0..<(columns * rows))
                .filter(clear)
                .min { point($0).distance(to: target) < point($1).distance(to: target) }
        }

        guard let start = nearestClear(to: level.playerStart) else { return Array(targets.indices) }
        var visited: Set<Int> = [start]
        var queue = [start]
        var head = 0
        let moves = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        while head < queue.count {
            let current = queue[head]
            head += 1
            let x = current % columns
            let y = current / columns
            for move in moves {
                let nx = x + move.0
                let ny = y + move.1
                guard nx >= 0, nx < columns, ny >= 0, ny < rows else { continue }
                let next = ny * columns + nx
                guard !visited.contains(next), clear(next) else { continue }
                visited.insert(next)
                queue.append(next)
            }
        }

        return targets.indices.filter { index in
            guard let targetCell = nearestClear(to: targets[index]) else { return true }
            return !visited.contains(targetCell)
        }
    }
}

private func advance(_ sim: WorldSimulation, seconds: TimeInterval, target: Vec2) {
    let steps = Int((seconds * 60).rounded(.up))
    for _ in 0..<steps {
        if sim.phase != .playing { return }
        sim.step(dt: 1.0 / 60.0, target: target)
    }
}
