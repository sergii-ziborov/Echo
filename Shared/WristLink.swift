import Foundation

/// What the phone and the watch say to each other over WatchConnectivity.
/// Payloads are plain property-list dictionaries so both sides can send them
/// with `sendMessage`, `transferUserInfo` or the application context.
enum WristLink {
    static let opKey = "op"
    static let progressKey = "wrist.progress"
    static let radarKey = "radar"

    enum Op: String, Sendable {
        /// The watch remote is open; repeated as a keep-alive.
        case hello = "remote.hello"
        case stick = "remote.stick"
        case release = "remote.release"
        case dash = "remote.dash"
        case pause = "remote.pause"
        case radar = "remote.radar"
    }

    static func message(_ op: Op, _ extra: [String: Any] = [:]) -> [String: Any] {
        var message = extra
        message[opKey] = op.rawValue
        return message
    }

    static func progressPayload(_ progress: WristProgress) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(progress) else { return [:] }
        return [progressKey: data]
    }

    static func progress(in payload: [String: Any]) -> WristProgress? {
        guard let data = payload[progressKey] as? Data else { return nil }
        return try? JSONDecoder().decode(WristProgress.self, from: data)
    }
}

/// A remote-control command decoded from a watch message.
enum RemoteCommand: Equatable, Sendable {
    case hello
    case stick(Vec2)
    case release
    case dash
    case pause

    init?(_ message: [String: Any]) {
        guard let raw = message[WristLink.opKey] as? String, let op = WristLink.Op(rawValue: raw) else { return nil }
        switch op {
        case .hello: self = .hello
        case .release: self = .release
        case .dash: self = .dash
        case .pause: self = .pause
        case .radar: return nil
        case .stick:
            guard let x = message["x"] as? Double, let y = message["y"] as? Double, x.isFinite, y.isFinite else { return nil }
            self = .stick(Vec2(x: x, y: y))
        }
    }

    var message: [String: Any] {
        switch self {
        case .hello: WristLink.message(.hello)
        case .stick(let vector): WristLink.message(.stick, ["x": vector.x, "y": vector.y])
        case .release: WristLink.message(.release)
        case .dash: WristLink.message(.dash)
        case .pause: WristLink.message(.pause)
        }
    }
}

/// Turns a thumbstick vector from the watch into a target ahead of the orb.
enum RemoteSteering {
    /// Below this magnitude the stick is resting and the orb stops.
    static let deadzone = 0.16
    /// How far ahead of the orb the target sits, in world units.
    static let reach = 220.0

    static func target(stick: Vec2, player: Vec2) -> Vec2? {
        let magnitude = stick.length
        guard magnitude.isFinite, magnitude > deadzone else { return nil }
        return player + stick / magnitude * reach
    }
}

/// A compact snapshot of the phone's arena, normalised to 0…1 across the
/// arena width, so the watch can draw a live radar while it steers.
struct RadarFrame: Codable, Equatable, Sendable {
    enum State: String, Codable, Sendable {
        case ready, playing, paused, dead, won
    }

    var aspect: Double
    var player: [Double]
    var echoes: [[Double]]
    var sparks: [[Double]]
    var exit: [Double]
    var rocks: [[Double]]
    var walls: [[Double]]
    var collected: Int
    var total: Int
    var echoCount: Int
    var maxEchoes: Int
    var nextEcho: Double?
    var state: State
    var levelName: String

    init(simulation sim: WorldSimulation, state: State) {
        let width = max(sim.level.worldWidth, 1)
        func point(_ vector: Vec2) -> [Double] { [vector.x / width, vector.y / width] }
        aspect = sim.level.worldHeight / width
        player = point(sim.playerPosition)
        echoes = sim.echoes.map(point)
        sparks = sim.sparks.filter { !$0.collected }.map { point($0.position) + [$0.timerDuration != nil && !$0.timedOut ? 1 : 0] }
        exit = point(sim.level.exit) + [sim.exitOpen ? 1 : 0]
        rocks = sim.movers.map { point($0.position) + [$0.radius / width] }
        walls = sim.level.walls.map { [$0.minX / width, $0.minY / width, $0.width / width, $0.height / width] }
        collected = sim.sparks.filter(\.collected).count
        total = sim.sparks.count
        echoCount = sim.echoes.count
        maxEchoes = sim.level.maxEchoes
        nextEcho = sim.nextEchoIn
        self.state = state
        levelName = sim.level.name
    }

    var payload: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return WristLink.message(.radar, [WristLink.radarKey: data])
    }

    init?(payload: [String: Any]) {
        guard payload[WristLink.opKey] as? String == WristLink.Op.radar.rawValue,
              let data = payload[WristLink.radarKey] as? Data,
              let frame = try? JSONDecoder().decode(RadarFrame.self, from: data) else { return nil }
        self = frame
    }
}
