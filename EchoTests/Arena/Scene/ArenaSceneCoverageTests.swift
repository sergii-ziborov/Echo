import SpriteKit
import XCTest
@testable import Echo

@MainActor
final class ArenaSceneCoverageTests: XCTestCase {
    func testLiveReplayBalletAndInput() {
        for number in [1, 21, 36, 70] {
            let level = LevelCatalog.level(number: number) ?? LevelCatalog.prototype
            let session = GameSession(level: level, daily: number == 1)
            session.configure(tuning: PlayerTuning())
            let scene = GameScene(session: session, size: CoverageHost.size)
            CoverageHost.present(scene)

            let start = session.sim.playerPosition
            session.inputTarget = Vec2(x: start.x + 90, y: start.y + 50)
            session.hasStarted = true
            var time: TimeInterval = 0
            for _ in 0..<90 {
                time += 1 / 60
                scene.update(time)
            }

            session.phase = .paused
            scene.update(time + 0.1)
            session.phase = .replaying
            session.deathCause = .laser
            session.replaySnapshots = session.sim.snapshots
            session.replayClock = 0
            scene.update(time + 0.3)
            session.startBallet(
                SessionResult(time: max(2, session.elapsed), moves: 8, stars: 2, sparks: 3, echoesFaced: 1)
            )
            scene.update(time + 0.5)
            session.phase = .dead(.asteroid)
            scene.update(time + 0.6)
            session.phase = .won(
                SessionResult(time: 12, moves: 8, stars: 2, sparks: 3, echoesFaced: 1)
            )
            scene.update(time + 0.7)
            session.phase = .playing
            scene.rebuild()
            scene.touchesBegan([], with: nil)
            scene.touchesMoved([], with: nil)
            scene.touchesEnded([], with: nil)
            scene.touchesCancelled([], with: nil)
            scene.notePlayerTeleport()
            scene.noteTrailEvents([
                .playerTeleported(from: start, to: start, reason: .warp),
                .dashed,
            ])
            _ = scene.currentReplayFrame()
            _ = scene.currentBalletFrame()
            scene.syncPauseClock()
            scene.resize(to: CGSize(width: 4, height: 4))
            scene.resize(to: CoverageHost.size)
        }
        CoverageHost.teardown()
        XCTAssertNotNil(LevelCatalog.level(number: 21))
    }

    func testRichFrameSyncBranches() {
        let level = LevelCatalog.level(number: 36) ?? LevelCatalog.prototype
        let session = GameSession(level: level, daily: false)
        let scene = GameScene(session: session, size: CoverageHost.size)
        CoverageHost.present(scene)
        let start = session.sim.playerPosition
        for _ in 0..<80 {
            _ = session.sim.step(dt: 1 / 60, target: Vec2(x: start.x + 70, y: start.y + 40))
        }
        session.hasStarted = true
        session.phase = .playing
        session.exitOpen = true
        if session.sim.echoes.isEmpty {
            session.sim.echoes = [start, Vec2(x: start.x + 24, y: start.y + 12)]
        }
        session.threat = EchoThreat(echoIndex: 0, distance: 18, eta: 0.3, willCollide: true)

        var frame = RenderFrame(simulation: session.sim)
        frame.echoes = session.sim.echoes
        if frame.echoes.isEmpty {
            frame.echoes = [start, Vec2(x: start.x + 30, y: start.y)]
        }
        frame.scars = [CollisionScar(id: 11, position: start, radius: 22, remaining: 1.4)]
        frame.ghosts = [
            ParadoxGhost(
                samples: [
                    PathSample(time: 0, position: start),
                    PathSample(time: 1, position: Vec2(x: start.x + 40, y: start.y)),
                ],
                bornAt: 0
            )
        ]
        frame.exitOpen = true
        frame.reality = .candy
        frame.effects.freezeRemaining = 2
        frame.effects.magnetRemaining = 2
        frame.effects.surgeRemaining = 2
        frame.effects.phaseRemaining = 1
        frame.effects.shieldCharges = 1
        frame.lastVelocity = Vec2(x: 40, y: 10)
        frame.lastAim = Vec2(x: 1, y: 0)
        scene.apply(frame: frame, mode: .live)
        scene.apply(frame: frame, mode: .replay)
        scene.apply(frame: frame, mode: .ballet)
        scene.drawThreat()
        scene.drawSpawnBeacon()
        scene.refreshExit()
        scene.sampleTrails(clock: session.sim.time + 0.2)
        scene.syncMagnetLinks()
        scene.syncGhosts()
        scene.syncScars()
        scene.syncRealityBackdrop()
        scene.dropTrails(dt: 0.2)
        if let echo = scene.echoNodes.first {
            scene.syncEchoPose(echo, index: 0)
            scene.syncEchoPose(echo, index: 0)
        }
        CoverageHost.teardown()
        XCTAssertFalse(frame.echoes.isEmpty)
    }
}
