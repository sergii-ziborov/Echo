import XCTest
@testable import Echo

@MainActor
final class GameSessionCoverageTests: XCTestCase {
    func testEventsReplayBalletAndCooldowns() {
        let session = GameSession(level: LevelCatalog.prototype, daily: true)
        session.configure(tuning: PlayerTuning())
        session.abilityCooldowns[.shield] = 0.4
        session.abilityCooldowns[.freeze] = 2
        session.advanceCooldowns(dt: 0)
        session.advanceCooldowns(dt: 0.5)
        session.handle(events: [
            .resonance(chain: 3, window: 2),
            .timeCrystalSecured(id: 0, freeze: 1.2),
            .sparkTimerExpired(id: 0),
            .bonusCollected(kind: .pulse),
            .shieldBroke,
            .echoWillSpawn(index: 0, in: 1),
            .echoSpawned(index: 0),
            .exitOpened,
            .riftOpened(id: 0),
            .riftEntered(kind: .collision),
            .riftEntered(kind: .warp),
            .riftEntered(kind: .calm),
            .timeCollision(at: .zero),
            .died(.ghost),
        ], autoReplay: false)
        session.skipReplay()

        let start = session.sim.playerPosition
        session.restart()
        for _ in 0..<40 {
            _ = session.sim.step(dt: 1 / 60, target: Vec2(x: start.x + 80, y: start.y + 20))
        }
        session.handle(events: [.died(.laser)], autoReplay: true)
        _ = session.advanceReplay(dt: 0.08)
        if session.phase == .replaying {
            _ = session.advanceReplay(dt: 30)
        }
        session.skipReplay()

        let result = SessionResult(time: 3, moves: 6, stars: 2, sparks: 3, echoesFaced: 1)
        session.startBallet(result)
        _ = session.currentBalletFrame()
        _ = session.advanceBallet(dt: 0.2)
        _ = session.advanceBallet(dt: 8)
        session.handle(events: [.won(result)], autoReplay: true)
        session.applyDebugPreview(["-shot-fracture"])
        session.applyDebugPreview(["-shot-asteroid-core"])
        if let snap = session.sim.snapshots.first {
            session.replaySnapshots = Array(repeating: snap, count: 12)
            session.phase = .replaying
            session.deathCause = .laser
            session.replayClock = 0
            session.replayIndex = 0
            _ = session.advanceReplay(dt: 0.05)
            _ = session.advanceReplay(dt: 40)
        }
        session.deathCause = .asteroid
        session.skipReplay()
        XCTAssertNotNil(session.dailyKey)
    }
}
