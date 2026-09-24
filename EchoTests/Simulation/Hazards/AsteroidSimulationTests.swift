import XCTest
@testable import Echo

extension WorldSimulationTests {
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

    func testFixedAsteroidCoreStaysStillWhileSatellitesOrbit() throws {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        level.playerStart = Vec2(x: 100, y: 100)
        level.exit = Vec2(x: 900, y: 900)
        level.sparks = [SparkSpawn(id: 0, position: Vec2(x: 900, y: 100))]
        level.movers = [
            .stationary(id: 0, at: Vec2(x: 500, y: 500), radius: 130),
            .orbit(id: 1, center: Vec2(x: 500, y: 500), radius: 210, period: 8, size: ArenaMetrics.satelliteRadius),
        ]
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: level, config: config)
        let satelliteStart = try XCTUnwrap(sim.movers.first { $0.id == 1 }).position

        advance(sim, seconds: 0.8, target: Vec2(x: 220, y: 100))

        let core = try XCTUnwrap(sim.movers.first { $0.id == 0 })
        let satellite = try XCTUnwrap(sim.movers.first { $0.id == 1 })
        XCTAssertEqual(core.position, Vec2(x: 500, y: 500))
        XCTAssertEqual(core.velocity, .zero)
        XCTAssertEqual(satellite.radius, ArenaMetrics.satelliteRadius)
        XCTAssertGreaterThan(satellite.position.distance(to: satelliteStart), 10)
        XCTAssertEqual(satellite.position.distance(to: core.position), 210, accuracy: 0.001)
    }

    func testExpandedMapsUseDistinctAsteroidMotionPatterns() throws {
        for number in [40, 47, 61, 68] {
            let level = try XCTUnwrap(LevelCatalog.level(number: number))
            XCTAssertEqual(level.movers.count, 4, "Map \(number)")
            XCTAssertEqual(level.movers.first?.material, .alloy, "Map \(number)")
            guard case .stationary = level.movers[0].path else {
                return XCTFail("Map \(number) needs a fixed core")
            }
            for satellite in level.movers.dropFirst() {
                guard case .orbit(let center, let radius, _, _) = satellite.path else {
                    return XCTFail("Map \(number) needs orbiting satellites")
                }
                XCTAssertEqual(center, level.movers[0].position)
                XCTAssertEqual(radius, 210)
                XCTAssertEqual(satellite.radius, ArenaMetrics.readableRockRadius(ArenaMetrics.satelliteRadius))
                XCTAssertGreaterThan(radius, level.movers[0].radius + satellite.radius + 24)
            }
        }
        let firstCoreMap = try XCTUnwrap(LevelCatalog.level(number: 40))
        let laterCoreMap = try XCTUnwrap(LevelCatalog.level(number: 68))
        guard case .orbit(_, _, let firstPeriod, _) = firstCoreMap.movers[1].path,
              case .orbit(_, _, let laterPeriod, _) = laterCoreMap.movers[1].path else {
            return XCTFail("Core satellites need orbit timings")
        }
        XCTAssertLessThan(laterPeriod, firstPeriod)
        let orbitMap = try XCTUnwrap(LevelCatalog.level(number: 38))
        let patrolMap = try XCTUnwrap(LevelCatalog.level(number: 39))
        XCTAssertGreaterThanOrEqual(orbitMap.movers.filter {
            if case .orbit = $0.path { return true }
            return false
        }.count, 2)
        XCTAssertGreaterThanOrEqual(patrolMap.movers.filter {
            if case .patrol = $0.path { return true }
            return false
        }.count, 2)
    }

    func testOrbitingAsteroidStartsOnItsFittedCircularRoute() throws {
        let level = try XCTUnwrap(LevelCatalog.level(number: 40))
        let fitted = level.fitted(aspect: 2.1)
        let core = try XCTUnwrap(fitted.movers.first { $0.id == 0 })
        for satellite in fitted.movers.dropFirst() {
            XCTAssertEqual(satellite.position.distance(to: core.position), 210, accuracy: 0.001)
        }
    }

    func testRepulseCannotDislodgeFixedAsteroidCore() throws {
        var level = LevelCatalog.prototype
        level.walls = []
        level.playerStart = Vec2(x: 500, y: 330)
        level.movers = [.stationary(id: 0, at: Vec2(x: 500, y: 500), radius: 130)]
        let sim = WorldSimulation(level: level)

        XCTAssertTrue(sim.activate(.repulse))

        let core = try XCTUnwrap(sim.movers.first)
        XCTAssertEqual(core.position, Vec2(x: 500, y: 500))
        XCTAssertEqual(core.path, .stationary)
    }

    func testBrittleAsteroidStartsFractureClockOnWallImpact() {
        let sim = asteroidImpactSimulation(material: .ice)
        var sawImpact = false
        for _ in 0..<30 {
            let events = sim.step(dt: 1.0 / 60.0, target: Vec2(x: 560, y: 500))
            sawImpact = sawImpact || events.contains {
                if case .asteroidImpacted(_, .ice, _) = $0 { return true }
                return false
            }
        }

        XCTAssertTrue(sawImpact)
        XCTAssertEqual(sim.movers.first?.material, .ice)
        XCTAssertEqual(sim.movers.first?.hitsRemaining, 1)
        XCTAssertNotNil(sim.movers.first?.fractureRemaining)
        XCTAssertGreaterThan(sim.movers.first?.fractureProgress ?? 0, 0)
    }

    func testFractureClockShattersBrittleAsteroid() {
        let sim = asteroidImpactSimulation(material: .ice)
        var shattered = false
        for _ in 0..<390 {
            let events = sim.step(dt: 1.0 / 60.0, target: Vec2(x: 560, y: 500))
            shattered = shattered || events.contains {
                if case .asteroidShattered(_, .ice, _) = $0 { return true }
                return false
            }
            if shattered { break }
        }

        XCTAssertTrue(shattered)
        XCTAssertTrue(sim.movers.isEmpty)
    }

    func testFreezePausesAsteroidFractureClock() {
        let sim = asteroidImpactSimulation(material: .crystal)
        advance(sim, seconds: 0.45, target: Vec2(x: 560, y: 500))
        let before = sim.movers[0].fractureRemaining
        XCTAssertNotNil(before)
        XCTAssertTrue(sim.activate(.freeze))
        advance(sim, seconds: 1.0, target: Vec2(x: 580, y: 500))
        XCTAssertEqual(sim.movers[0].fractureRemaining ?? -1, before ?? -2, accuracy: 0.02)
    }

    func testVoidAlloyNeverArmsFractureClock() {
        let sim = asteroidImpactSimulation(material: .alloy)
        advance(sim, seconds: 0.45, target: Vec2(x: 560, y: 500))
        XCTAssertEqual(sim.movers.first?.material, .alloy)
        XCTAssertNil(sim.movers.first?.hitsRemaining)
        XCTAssertNil(sim.movers.first?.fractureRemaining)
    }

    func testCampaignUsesEveryAsteroidMaterial() {
        let materials = Set(LevelCatalog.playable.flatMap { $0.movers.map(\.material) })
        XCTAssertEqual(materials, Set(AsteroidMaterial.allCases))
        XCTAssertTrue(LevelCatalog.playable.flatMap(\.movers).contains { $0.material == .alloy })
        XCTAssertTrue(LevelCatalog.playable.flatMap(\.movers).contains { $0.material.isBreakable })
    }

}
