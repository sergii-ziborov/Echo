import SpriteKit
import XCTest
@testable import Echo

@MainActor
final class ArenaFXCoverageTests: XCTestCase {
    func testCombatAndBurstCatalog() {
        let level = LevelCatalog.level(number: 36) ?? LevelCatalog.prototype
        let session = GameSession(level: level, daily: false)
        let scene = GameScene(session: session, size: CoverageHost.size)
        CoverageHost.present(scene)
        let origin = session.sim.playerPosition
        let point = CGPoint(x: 180, y: 240)

        for kind in BonusKind.allCases {
            scene.abilityEffect(kind: kind, at: origin)
        }
        scene.burst(at: origin, color: .cyan)
        scene.timerPop(at: origin)
        scene.resonanceEffect(chain: 2, at: origin)
        scene.resonanceEffect(chain: 5, at: origin)
        scene.laserDischarge(id: session.sim.lasers.first?.id ?? 0)
        for material in AsteroidMaterial.allCases {
            scene.asteroidImpact(id: session.sim.movers.first?.id ?? 0, material: material, at: origin)
            scene.asteroidShatter(id: 9_001 + material.hashValue, material: material, at: origin)
        }
        if let mover = session.sim.movers.first {
            scene.asteroidShatter(id: mover.id, material: mover.material, at: mover.position)
        }
        for kind in [RiftKind.calm, .warp, .candy, .collision] {
            scene.realityShift(kind: kind, at: origin)
        }

        scene.asteroidFragments(at: point, color: .orange, count: 6, distance: 40)
        scene.polygonWave(at: point, sides: 5, color: .white, radius: 18, scale: 2.4)
        scene.speedStreaks(at: point, color: .yellow)
        scene.electricArcBurst(at: point, color: .cyan, count: 5)
        _ = scene.lightningBoltNode(
            angle: 0.4,
            inner: 12,
            outer: 64,
            baseSeed: 3,
            color: .white,
            delay: 0,
            persistent: true
        )
        scene.winterBurst(at: point, color: .cyan)
        _ = scene.shieldBubbleNode(color: .green, radius: 28, layers: 2, animated: true)
        scene.shieldFormEffect(at: point, color: .green)
        scene.shieldBreakEffect(at: point)
        _ = scene.magneticFieldAura(tint: .magenta, radius: 36, particleCount: 8)
        scene.timelineWaves(at: point, color: .purple, count: 3)
        scene.orbitalArcs(at: point, color: .cyan)
        scene.phaseAfterimages(at: point, color: .white)
        scene.screenFlash(color: .red, alpha: 0.2)
        scene.shockwave(at: point, color: .white)
        scene.dropTrail(at: point, color: .cyan, size: 8)
        scene.dropTrails(dt: 1 / 30)
        scene.beginIdlePulse()
        scene.spawnIdlePing()
        scene.endIdlePulse()
        _ = scene.echoNode()
        _ = scene.world(point)
        _ = scene.wallTextureComponentPaths(session.level.walls)
        scene.syncWinterEffect()
        _ = session.sim.activate(.freeze)
        scene.syncWinterEffect()
        _ = session.sim.activate(.magnet)
        scene.syncMagnetLinks()
        scene.syncMagnetCrown()
        scene.syncScars()
        scene.syncGhosts()
        scene.syncRealityBackdrop()
        scene.refreshExit()
        scene.drawThreat()
        session.hasStarted = true
        session.inputTarget = nil
        scene.update(1.2)
        scene.update(2.4)
        scene.pulsePlayer()
        CoverageHost.teardown()
        XCTAssertFalse(BonusKind.allCases.isEmpty)
    }
}
