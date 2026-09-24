import XCTest
@testable import Echo

final class WristLinkTests: XCTestCase {
    func testRemoteCommandsSurviveTheWire() {
        let commands: [RemoteCommand] = [.hello, .stick(Vec2(x: 0.5, y: -0.25)), .release, .dash, .pause]
        for command in commands {
            XCTAssertEqual(RemoteCommand(command.message), command)
        }
        XCTAssertNil(RemoteCommand(["op": "remote.stick", "x": Double.nan, "y": 0.0]))
        XCTAssertNil(RemoteCommand(["op": "something-else"]))
    }

    func testStickSteersAFixedReachAheadAndRestsInTheDeadzone() {
        let player = Vec2(x: 300, y: 400)
        XCTAssertNil(RemoteSteering.target(stick: Vec2(x: 0.05, y: 0.05), player: player))
        let target = RemoteSteering.target(stick: Vec2(x: 0.5, y: 0), player: player)
        XCTAssertEqual(target?.x ?? 0, 300 + RemoteSteering.reach, accuracy: 0.001)
        XCTAssertEqual(target?.y ?? 0, 400, accuracy: 0.001)
    }

    func testProgressAndRadarRoundTrip() throws {
        var progress = WristProgress()
        progress.record(clear: "wrist-3", time: 18.5)
        XCTAssertEqual(WristLink.progress(in: WristLink.progressPayload(progress)), progress)

        let sim = WorldSimulation(level: LevelCatalog.prototype)
        let frame = RadarFrame(simulation: sim, state: .ready)
        let decoded = try XCTUnwrap(RadarFrame(payload: frame.payload))
        XCTAssertEqual(decoded, frame)
        XCTAssertEqual(decoded.total, LevelCatalog.prototype.sparks.count)
        for point in [decoded.player] + decoded.sparks.map({ Array($0.prefix(2)) }) {
            XCTAssertTrue((0...1).contains(point[0]))
            XCTAssertTrue((0...decoded.aspect).contains(point[1]))
        }
    }

    @MainActor
    func testWatchCommandsDriveTheRunOnThePhone() throws {
        let level = LevelCatalog.prototype
        let session = GameSession(level: level, daily: false)
        let scene = GameScene(session: session, size: CoverageHost.size)
        let link = PhoneWatchLink.shared
        link.attach(session: session, scene: scene)
        defer { link.detach(session: session) }

        link.apply(.stick(Vec2(x: 0, y: 1)))
        let target = try XCTUnwrap(session.inputTarget)
        XCTAssertGreaterThan(target.y, session.sim.playerPosition.y)
        XCTAssertTrue(link.isSteering)

        link.apply(.release)
        XCTAssertNil(session.inputTarget)

        link.apply(.pause)
        XCTAssertEqual(session.phase, .paused)
        link.apply(.pause)
        XCTAssertEqual(session.phase, .playing)
    }
}
