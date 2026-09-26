import Foundation

/// Remote play between the watch and a phone run travels as a few bytes of
/// binary with `sendMessageData`. Each side keeps only a couple of messages
/// waiting for replies and always sends the newest state, so a slow Bluetooth
/// link skips stale stick positions and arena frames instead of queueing
/// seconds of lag behind them.
enum RemoteKind: UInt8, Sendable {
    case hello = 1, stick, release, dash, pause, rewind, retry
    case level = 20, frame
}

/// A command from the watch remote.
enum RemoteCommand: Equatable, Sendable {
    /// The remote is open; `level` is the token of the arena it has built, 0 for none.
    case hello(level: UInt32)
    case stick(Vec2)
    case release
    case dash
    case pause
    /// Turn the Crown back after a crash: the phone's Paradox Rewind.
    case rewind
    case retry

    var data: Data {
        switch self {
        case .hello(let level):
            var writer = ByteWriter(.hello)
            writer.u32(level)
            return writer.data
        case .stick(let vector):
            var writer = ByteWriter(.stick)
            writer.axis(vector.x)
            writer.axis(vector.y)
            return writer.data
        case .release: return ByteWriter(.release).data
        case .dash: return ByteWriter(.dash).data
        case .pause: return ByteWriter(.pause).data
        case .rewind: return ByteWriter(.rewind).data
        case .retry: return ByteWriter(.retry).data
        }
    }

    init?(data: Data) {
        var reader = ByteReader(data)
        do {
            switch try reader.kind() {
            case .hello: self = .hello(level: try reader.u32())
            case .stick: self = .stick(Vec2(x: try reader.axis(), y: try reader.axis()))
            case .release: self = .release
            case .dash: self = .dash
            case .pause: self = .pause
            case .rewind: self = .rewind
            case .retry: self = .retry
            case .level, .frame: return nil
            }
        } catch {
            return nil
        }
    }
}

/// What the watch sends next. Letting go, dash, pause, rewind and retry go
/// out at once, ahead of everything, because waiting behind stick positions
/// is what made the orb coast on after the finger lifted. After them come
/// hellos, then only the newest stick position, with no more than `window`
/// messages waiting for their replies so stale positions never queue up.
struct RemoteOutbox: Sendable {
    /// A reply that never comes (a dropped link) frees its slot after this long.
    static let replyTimeout: TimeInterval = 1

    let window: Int
    private var inFlight: [TimeInterval] = []
    private var urgent: [RemoteCommand] = []
    private var queue: [RemoteCommand] = []
    private var stick: Vec2?
    private var stickDirty = false

    init(window: Int = 3) {
        self.window = max(1, window)
    }

    var isIdle: Bool { urgent.isEmpty && queue.isEmpty && !stickDirty }
    var waiting: Int { inFlight.count }

    mutating func post(_ command: RemoteCommand) {
        switch command {
        case .stick(let vector):
            stick = vector
            stickDirty = true
        case .release:
            stick = nil
            stickDirty = false
            urgent.append(.release)
        case .hello:
            queue.removeAll { if case .hello = $0 { true } else { false } }
            queue.append(command)
        default:
            urgent.append(command)
        }
    }

    /// The message to send now, if there is one and it may go; marks it in flight.
    mutating func next(now: TimeInterval) -> RemoteCommand? {
        inFlight.removeAll { now - $0 >= Self.replyTimeout }
        let command: RemoteCommand
        if !urgent.isEmpty {
            command = urgent.removeFirst()
        } else if inFlight.count >= window {
            return nil
        } else if !queue.isEmpty {
            command = queue.removeFirst()
        } else if stickDirty, let stick {
            stickDirty = false
            command = .stick(stick)
        } else {
            return nil
        }
        inFlight.append(now)
        return command
    }

    /// A reply (or an error) arrived, so the oldest slot is free again.
    mutating func delivered() {
        if !inFlight.isEmpty { inFlight.removeFirst() }
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

/// Little-endian packing for remote-play messages. World coordinates are
/// stored in eighths of a unit, which keeps a whole arena inside an Int16.
struct ByteWriter {
    private(set) var data = Data()

    init(_ kind: RemoteKind) {
        data.append(kind.rawValue)
    }

    mutating func u8(_ value: UInt8) { data.append(value) }
    mutating func u16(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
    mutating func u32(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
    mutating func u64(_ value: UInt64) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
    mutating func f32(_ value: Double) { u32(Float(value).bitPattern) }
    mutating func f64(_ value: Double) { u64(value.bitPattern) }

    /// A stick axis in -1…1 as a signed byte.
    mutating func axis(_ value: Double) {
        let clamped = max(-1, min(1, value.isFinite ? value : 0))
        u8(UInt8(bitPattern: Int8((clamped * 127).rounded())))
    }

    mutating func coordinate(_ value: Double) {
        let scaled = max(-32767, min(32767, ((value.isFinite ? value : 0) * 8).rounded()))
        u16(UInt16(bitPattern: Int16(scaled)))
    }

    mutating func point(_ point: Vec2) {
        coordinate(point.x)
        coordinate(point.y)
    }

    mutating func count(_ value: Int) { u8(UInt8(clamping: value)) }
}

struct ByteReader {
    struct Truncated: Error {}

    private let bytes: [UInt8]
    private var index = 0

    init(_ data: Data) {
        bytes = [UInt8](data)
    }

    mutating func kind() throws -> RemoteKind {
        guard let kind = RemoteKind(rawValue: try u8()) else { throw Truncated() }
        return kind
    }

    mutating func u8() throws -> UInt8 {
        guard index < bytes.count else { throw Truncated() }
        defer { index += 1 }
        return bytes[index]
    }

    mutating func u16() throws -> UInt16 { UInt16(try unsigned(2)) }
    mutating func u32() throws -> UInt32 { UInt32(try unsigned(4)) }
    mutating func u64() throws -> UInt64 { try unsigned(8) }
    mutating func f32() throws -> Double { Double(Float(bitPattern: try u32())) }
    mutating func f64() throws -> Double { Double(bitPattern: try u64()) }
    mutating func axis() throws -> Double { Double(Int8(bitPattern: try u8())) / 127 }
    mutating func coordinate() throws -> Double { Double(Int16(bitPattern: try u16())) / 8 }
    mutating func point() throws -> Vec2 { Vec2(x: try coordinate(), y: try coordinate()) }

    private mutating func unsigned(_ width: Int) throws -> UInt64 {
        guard index + width <= bytes.count else { throw Truncated() }
        var value: UInt64 = 0
        for offset in 0..<width {
            value |= UInt64(bytes[index + offset]) << (8 * UInt64(offset))
        }
        index += width
        return value
    }
}
