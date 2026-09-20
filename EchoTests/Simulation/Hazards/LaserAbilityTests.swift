import XCTest
@testable import Echo

extension WorldSimulationTests {
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

    func testPrismMakesFiringLaserSafe() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.playerStart = Vec2(x: 500, y: 120)
        level.lasers = [.horizontal(id: 0, y: 260, period: 10, chargeFor: 0, activeFor: 10)]
        var config = SimConfig()
        config.collisionSlop = 0
        let sim = WorldSimulation(level: level, config: config)

        XCTAssertTrue(sim.activate(.prism))
        advance(sim, seconds: 1.2, target: Vec2(x: 500, y: 500))

        XCTAssertEqual(sim.phase, .playing)
        XCTAssertTrue(sim.effects.isPrismatic)
    }

    func testAnchorSlowsTimelineButNotPlayerClock() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: level, config: config)
        advance(sim, seconds: 0.2, target: Vec2(x: 580, y: 120))
        let wallClock = sim.time
        let timeline = sim.playbackTime

        XCTAssertTrue(sim.activate(.anchor))
        advance(sim, seconds: 1.0, target: Vec2(x: 900, y: 120))

        XCTAssertGreaterThan(sim.time - wallClock, 0.9)
        XCTAssertEqual(sim.playbackTime - timeline, 0.42, accuracy: 0.06)
        XCTAssertGreaterThan(sim.playerPosition.x, 800)
    }

    func testBlinkJumpsInLastMovementDirection() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: level, config: config)
        advance(sim, seconds: 0.12, target: Vec2(x: 800, y: 120))
        let before = sim.playerPosition

        XCTAssertTrue(sim.activate(.blink))

        XCTAssertGreaterThan(sim.playerPosition.x - before.x, 150)
        XCTAssertGreaterThan(sim.effects.iFrames, 0.4)
        let events = sim.drainAppliedEvents()
        XCTAssertTrue(events.contains { event in
            if case .playerTeleported(_, _, .blink) = event { return true }
            return false
        })
    }

    func testShortBlinkStillEmitsTeleport() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        level.playerStart = Vec2(x: 880, y: 120)
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: level, config: config)
        advance(sim, seconds: 0.12, target: Vec2(x: 960, y: 120))
        let before = sim.playerPosition
        XCTAssertTrue(sim.activate(.blink))
        let jump = before.distance(to: sim.playerPosition)
        XCTAssertLessThan(jump * (375 / level.worldWidth), 72)
        XCTAssertTrue(sim.drainAppliedEvents().contains { event in
            if case .playerTeleported(_, _, .blink) = event { return true }
            return false
        })
    }

    func testWarpEmitsTeleportEvent() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        level.rifts = [RiftSpawn(id: 0, kind: .warp, position: Vec2(x: 500, y: 220), period: 10, openFor: 10)]
        let sim = WorldSimulation(level: level)
        var teleported = false
        for _ in 0..<60 {
            let events = sim.step(dt: 1.0 / 60.0, target: Vec2(x: 500, y: 240))
            if events.contains(where: { event in
                if case .playerTeleported(_, _, .warp) = event { return true }
                return false
            }) {
                teleported = true
                break
            }
        }
        XCTAssertTrue(teleported)
    }

    func testDeathSnapshotKeepsFiringLaser() throws {
        var level = LevelCatalog.prototype
        level.walls = []
        level.playerStart = Vec2(x: 500, y: 120)
        level.lasers = [
            .horizontal(id: 0, y: 260, period: 10, chargeFor: 0, activeFor: 10),
        ]
        var config = SimConfig()
        config.collisionSlop = 0
        let sim = WorldSimulation(level: level, config: config)
        advance(sim, seconds: 1.2, target: Vec2(x: 500, y: 500))
        XCTAssertEqual(sim.phase, .dead)
        let snap = try XCTUnwrap(sim.snapshots.last)
        XCTAssertEqual(snap.lasers.first?.phase, .firing)
        let frame = RenderFrame(
            snapshot: snap,
            gravityWells: sim.gravityWells,
            anchoredScale: sim.tuning.anchorTimeScale
        )
        XCTAssertEqual(frame.lasers.first?.phase, .firing)
        XCTAssertEqual(frame.player, snap.player)
    }

    func testRepulseShattersNearbyBreakableAsteroid() {
        var level = LevelCatalog.prototype
        level.walls = []
        level.maxEchoes = 0
        level.playerStart = Vec2(x: 500, y: 500)
        level.movers = [
            .bounce(id: 0, at: Vec2(x: 620, y: 500), velocity: .zero, radius: 34, material: .ice),
        ]
        var config = SimConfig()
        config.collisionSlop = 1_000
        let sim = WorldSimulation(level: level, config: config)

        XCTAssertTrue(sim.activate(.repulse))
        advance(sim, seconds: 0.2, target: Vec2(x: 560, y: 500))

        XCTAssertTrue(sim.movers.isEmpty)
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

}
