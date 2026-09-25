import SwiftUI
import XCTest
@testable import Echo

@MainActor
final class GameViewCoverageTests: XCTestCase {
    func testPlayingPausedOverlaysAndHints() {
        let model = CoverageFixtures.model()
        let request = CoverageFixtures.playRequest(21)
        var playing = GameView(request: request)
        playing.session.hasStarted = true
        playing.session.banner = "SURGE"
        CoverageHost.render(playing.environment(model))

        var paused = GameView(request: request)
        paused.session.phase = .paused
        CoverageHost.render(paused.environment(model))

        var shop = GameView(request: request, overlay: .shop)
        shop.session.phase = .paused
        CoverageHost.render(shop.environment(model))

        var settings = GameView(request: request, overlay: .settings)
        settings.session.phase = .paused
        CoverageHost.render(settings.environment(model))

        CoverageHost.render(GameView(request: request, hint: .echo).environment(model))
        CoverageHost.render(GameView(request: CoverageFixtures.playRequest(1, daily: true)).environment(model))
    }

    func testEndlessDepthCrashesAndClears() {
        let model = CoverageFixtures.model()
        let key = EndlessKey(seed: 0xEC40_D17E, depth: 7)
        let request = PlayRequest(levelID: key.levelID, daily: false, endless: key)
        let result = SessionResult(time: 20, moves: 12, stars: 2, sparks: 6, echoesFaced: 2)

        var dead = GameView(request: request)
        XCTAssertEqual(dead.session.level.id, key.levelID)
        dead.session.phase = .dead(.laser)
        dead.session.deathCause = .laser
        CoverageHost.render(dead.environment(model))

        var won = GameView(request: request)
        won.session.phase = .won(result)
        CoverageHost.render(won.environment(model))

        won.modelOverride = model
        won.nextLevel()
        XCTAssertEqual(model.screen, .playing(PlayRequest(levelID: key.next.levelID, daily: false, endless: key.next)))

        dead.modelOverride = model
        model.progress.endless.current = key
        dead.newEndlessRun()
        guard case .playing(let fresh) = model.screen, let run = fresh.endless else {
            return XCTFail("A new run should start")
        }
        XCTAssertEqual(run.depth, 1)
        XCTAssertNotEqual(run.seed, key.seed)
    }

    func testDeadWonReplayBallet() {
        let model = CoverageFixtures.model()
        let request = CoverageFixtures.playRequest(1)
        let result = SessionResult(
            time: 20, moves: 12, stars: 3, sparks: 6, echoesFaced: 2,
            control: true, paradox: false
        )

        var dead = GameView(request: request)
        dead.session.phase = .dead(.asteroid)
        dead.session.deathCause = .asteroid
        CoverageHost.render(dead.environment(model))

        var won = GameView(request: request)
        won.session.phase = .won(result)
        CoverageHost.render(won.environment(model))

        var last = GameView(request: CoverageFixtures.playRequest(77))
        last.session.phase = .won(result)
        CoverageHost.render(last.environment(model))

        var replay = GameView(request: request)
        replay.session.phase = .replaying
        replay.session.deathCause = .laser
        replay.session.replaySnapshots = replay.session.sim.snapshots
        CoverageHost.render(replay.environment(model))

        var ballet = GameView(request: request)
        ballet.session.startBallet(result)
        CoverageHost.render(ballet.environment(model))
    }

    func testEventDispatchAndSessionHelpers() {
        let model = CoverageFixtures.model()
        let request = CoverageFixtures.playRequest(36)
        var view = GameView(request: request)
        CoverageHost.render(view.environment(model))

        let position = view.session.sim.playerPosition
        let events: [SimEvent] = [
            .sparkCollected(id: 0, remaining: 5),
            .resonance(chain: 2, window: 3),
            .resonance(chain: 4, window: 3),
            .timeCrystalSecured(id: 1, freeze: 1.5),
            .sparkTimerExpired(id: 1),
            .bonusCollected(kind: .freeze),
            .bonusCollected(kind: .blink),
            .bonusCollected(kind: .ward),
            .shieldBroke,
            .dashed,
            .laserCharging(id: 0),
            .laserFired(id: 0),
            .asteroidImpacted(id: 0, material: .basalt, at: position),
            .asteroidShattered(id: 0, material: .ice, at: position),
            .echoWillSpawn(index: 0, in: 2),
            .echoSpawned(index: 0),
            .exitOpened,
            .riftOpened(id: 0),
            .riftEntered(kind: .calm),
            .riftEntered(kind: .warp),
            .riftEntered(kind: .candy),
            .playerTeleported(from: position, to: position, reason: .blink),
            .timeCollision(at: position),
            .died(.ghost),
            .won(SessionResult(time: 16, moves: 9, stars: 2, sparks: 6, echoesFaced: 1)),
        ]
        view.modelOverride = model
        view.scene.onEvents?(events)
        view.handle(events)
        view.useItem(.shield)
        view.session.abilityCooldowns[.freeze] = 1.2
        view.useItem(.freeze)
        view.offerHint(.gate)
        view.offerAbilityHint(.surge)
        view.offerAbilityHint(.ward)
        view.dismissHint()
        view.restart()
        view.paradoxRewind()
        view.nextLevel()
        _ = view.resultKey

        var daily = GameView(request: CoverageFixtures.playRequest(1, daily: true))
        daily.modelOverride = model
        daily.nextLevel()

        var last = GameView(request: CoverageFixtures.playRequest(77))
        last.modelOverride = model
        last.nextLevel()

        var fresh = GameView(request: request)
        fresh.modelOverride = CoverageFixtures.model(rich: false)
        fresh.offerHint(.echo)
        fresh.dismissHint()
        fresh.useItem(.blink)
        XCTAssertEqual(view.request.daily, false)
        CoverageHost.teardown()
    }
}
