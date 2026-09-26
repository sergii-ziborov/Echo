import XCTest
@testable import Echo

final class WristLinkTests: XCTestCase {
    func testRemoteCommandsSurviveTheWire() throws {
        let commands: [RemoteCommand] = [.hello(level: 0xABCD_1234), .release, .dash, .pause, .rewind, .retry]
        for command in commands {
            XCTAssertEqual(RemoteCommand(data: command.data), command)
        }
        let stick = try XCTUnwrap(RemoteCommand(data: RemoteCommand.stick(Vec2(x: 0.5, y: -1.4)).data))
        guard case .stick(let vector) = stick else { return XCTFail("Expected a stick") }
        XCTAssertEqual(vector.x, 0.5, accuracy: 0.01)
        XCTAssertEqual(vector.y, -1, accuracy: 0.001, "Axes clamp to the stick's reach")
        XCTAssertEqual(RemoteCommand.stick(Vec2(x: 0.3, y: 0.3)).data.count, 3)

        XCTAssertNil(RemoteCommand(data: Data()))
        XCTAssertNil(RemoteCommand(data: Data([RemoteKind.stick.rawValue, 5])))
        XCTAssertNil(RemoteCommand(data: Data([99])))
        XCTAssertNil(RemoteCommand(data: Data([RemoteKind.frame.rawValue])))
    }

    func testStickSteersAFixedReachAheadAndRestsInTheDeadzone() {
        let player = Vec2(x: 300, y: 400)
        XCTAssertNil(RemoteSteering.target(stick: Vec2(x: 0.05, y: 0.05), player: player))
        let target = RemoteSteering.target(stick: Vec2(x: 0.5, y: 0), player: player)
        XCTAssertEqual(target?.x ?? 0, 300 + RemoteSteering.reach, accuracy: 0.001)
        XCTAssertEqual(target?.y ?? 0, 400, accuracy: 0.001)
    }

    func testOutboxSendsOnlyTheNewestStickAndNeverDropsCommands() {
        var outbox = RemoteOutbox(window: 2)
        outbox.post(.stick(Vec2(x: 1, y: 0)))
        XCTAssertEqual(outbox.next(now: 0), .stick(Vec2(x: 1, y: 0)))

        // A slow link: more positions and a dash arrive while replies are pending.
        outbox.post(.stick(Vec2(x: 0, y: 1)))
        outbox.post(.dash)
        outbox.post(.stick(Vec2(x: -1, y: 0)))
        XCTAssertEqual(outbox.next(now: 0.1), .dash, "Commands go ahead of the stick")
        outbox.post(.stick(Vec2(x: 0, y: -1)))
        XCTAssertNil(outbox.next(now: 0.2), "No more than two sticks wait for replies")
        XCTAssertEqual(outbox.waiting, 2)

        outbox.delivered()
        XCTAssertEqual(outbox.next(now: 0.3), .stick(Vec2(x: 0, y: -1)), "Stale positions are skipped")
        outbox.delivered()
        outbox.delivered()
        XCTAssertNil(outbox.next(now: 0.4))
        XCTAssertTrue(outbox.isIdle)

        outbox.post(.stick(Vec2(x: 1, y: 1)))
        outbox.post(.release)
        XCTAssertEqual(outbox.next(now: 0.5), .release, "Letting go cancels a stick that never left")
        outbox.post(.hello(level: 1))
        XCTAssertEqual(outbox.next(now: 0.6), .hello(level: 1))
        outbox.post(.stick(Vec2(x: 0, y: 1)))
        XCTAssertNil(outbox.next(now: 0.65), "The window is full for sticks")
        outbox.post(.release)
        XCTAssertEqual(outbox.next(now: 0.7), .release, "Letting go never waits behind the window")
        outbox.post(.pause)
        XCTAssertEqual(outbox.next(now: 0.75), .pause, "Neither does pause")
        XCTAssertNil(outbox.next(now: 0.8))
        XCTAssertEqual(outbox.waiting, 4)
        outbox.post(.hello(level: 2))
        XCTAssertNil(outbox.next(now: 0.5 + RemoteOutbox.replyTimeout + 0.01), "Only the oldest reply has timed out")
        XCTAssertEqual(outbox.next(now: 0.75 + RemoteOutbox.replyTimeout + 0.01), .hello(level: 2), "Lost replies free their slots")
    }

    func testFramesCarryTheMovingPartsInAFewDozenBytes() throws {
        let level = try XCTUnwrap(LevelCatalog.level(number: 40)).fitted(aspect: 2.16)
        let sim = WorldSimulation(level: level)
        for _ in 0..<90 { _ = sim.step(dt: 1.0 / 60, target: Vec2(x: 500, y: 900)) }
        let frame = RemoteFrame(sim: sim, level: 0xC0FF_EE00, state: .playing, cause: nil, sentAt: 1_000)
        let data = frame.data
        XCTAssertLessThan(data.count, 200)

        let decoded = try XCTUnwrap(RemoteFrame(data: data))
        XCTAssertEqual(decoded.data, data, "Decoding and encoding again is lossless")
        XCTAssertEqual(decoded.rocks.map(\.id), sim.movers.map(\.id))
        XCTAssertEqual(decoded.player.x, sim.playerPosition.x, accuracy: 0.125)
        XCTAssertEqual(decoded.player.y, sim.playerPosition.y, accuracy: 0.125)
        XCTAssertEqual(decoded.beams.count, sim.lasers.count)
        XCTAssertEqual(decoded.time, sim.time, accuracy: 0.001)
        XCTAssertEqual(decoded.level, 0xC0FF_EE00)
        XCTAssertNil(RemoteFrame(data: data.prefix(20)))

        var dead = frame
        dead.state = .dead
        dead.cause = .laser
        XCTAssertEqual(RemoteFrame(data: dead.data)?.cause, .laser)
    }

    func testTheWatchBuildsTheSameArenaAsThePhone() throws {
        let aspect = 812.0 / 375.0
        let bands = InterfaceBands(top: 430, bottom: 235, token: 80)
        for recipe in [
            RemoteLevel(id: try XCTUnwrap(LevelCatalog.level(number: 40)).id, cycle: 1, aspect: aspect, bands: bands),
            RemoteLevel(id: "daily", daily: Date(timeIntervalSince1970: 1_790_000_000), cycle: 0, aspect: aspect, bands: bands),
            RemoteLevel(id: "missing", cycle: 0, aspect: 1.9),
        ] {
            let data = recipe.data
            let received = try XCTUnwrap(RemoteLevel(data: data))
            XCTAssertEqual(received, recipe)
            // What GameView plays: fitted, then tokens moved out from under the HUD.
            let phone = recipe.bands.map { recipe.fitted().keepingBonusesInView($0) } ?? recipe.fitted()
            XCTAssertEqual(received.build(), phone)
            XCTAssertEqual(RemoteLevel.token(of: received.data), RemoteLevel.token(of: data))
        }
        let a = RemoteLevel(id: "a", cycle: 0, aspect: 2).data
        let b = RemoteLevel(id: "a", cycle: 1, aspect: 2).data
        XCTAssertNotEqual(RemoteLevel.token(of: a), RemoteLevel.token(of: b))
        XCTAssertNil(RemoteLevel(data: Data([RemoteKind.level.rawValue, 1, 2])))
    }

    func testProgressRoundTrip() {
        var progress = WristProgress()
        progress.record(clear: "wrist-3", time: 18.5)
        XCTAssertEqual(WristLink.progress(in: WristLink.progressPayload(progress)), progress)
        XCTAssertNil(WristLink.progress(in: [:]))
    }

    @MainActor
    func testWatchCommandsDriveTheRunOnThePhone() throws {
        let level = LevelCatalog.prototype
        let session = GameSession(level: level, daily: false)
        let scene = GameScene(session: session, size: CoverageHost.size)
        let link = PhoneWatchLink.shared
        var rewinds = 0
        var retries = 0
        link.attach(
            session: session,
            scene: scene,
            level: RemoteLevel(id: level.id, cycle: 0, aspect: 2),
            actions: PhoneWatchLink.RunActions(rewind: { rewinds += 1 }, retry: { retries += 1 })
        )
        defer { link.detach(session: session) }

        link.apply(.stick(Vec2(x: 0, y: 1)), now: 100)
        let target = try XCTUnwrap(session.inputTarget)
        XCTAssertGreaterThan(target.y, session.sim.playerPosition.y)
        XCTAssertTrue(link.isSteering)

        // The target follows the orb every frame, not only when a message lands.
        session.sim.playerPosition = Vec2(x: 420, y: 300)
        link.tick(now: 100.5)
        XCTAssertEqual(session.inputTarget?.x ?? 0, 420, accuracy: 0.001)
        XCTAssertEqual(session.inputTarget?.y ?? 0, 300 + RemoteSteering.reach, accuracy: 0.001)

        // A stick that goes quiet (the watch left or the link dropped) lets go.
        link.tick(now: 100 + PhoneWatchLink.stickTimeout + 0.1)
        XCTAssertNil(session.inputTarget)

        link.apply(.stick(Vec2(x: 1, y: 0)), now: 102)
        link.apply(.release, now: 102.1)
        XCTAssertNil(session.inputTarget)

        link.apply(.pause, now: 103)
        XCTAssertEqual(session.phase, .paused)
        link.apply(.pause, now: 103.1)
        XCTAssertEqual(session.phase, .playing)

        link.apply(.rewind, now: 104)
        link.apply(.retry, now: 104)
        XCTAssertEqual(rewinds, 0, "Rewind only answers a crash")
        XCTAssertEqual(retries, 0)
        session.phase = .dead(.asteroid)
        link.apply(.rewind, now: 105)
        link.apply(.retry, now: 105)
        XCTAssertEqual(rewinds, 1)
        XCTAssertEqual(retries, 1)
    }
}
