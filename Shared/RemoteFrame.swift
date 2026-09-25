import Foundation

/// Which arena a phone run is playing, precise enough for the watch to build
/// the identical level from its own copy of the catalog. Walls, pickups and
/// hazards then never cross the link; only the moving parts do.
struct RemoteLevel: Codable, Equatable, Sendable {
    var id: String
    /// Set for the Daily Rift, whose layout depends on the day.
    var daily: Date?
    var cycle: Int
    var aspect: Double
    /// What the phone HUD covers, so ability tokens move exactly as they do there.
    var bands: InterfaceBands?
    /// Set for Deep Time, whose arenas come from the run's seed and depth.
    var endless: EndlessKey?

    /// The run's level before tokens are moved out from under the HUD.
    func fitted() -> LevelDefinition {
        let raw: LevelDefinition
        if let endless {
            raw = EndlessGenerator.level(endless)
        } else {
            raw = daily.map { LevelCatalog.daily(on: $0) } ?? LevelCatalog.level(id: id) ?? LevelCatalog.prototype
        }
        return raw.difficultyAdjusted(for: cycle).fitted(aspect: aspect)
    }

    func build() -> LevelDefinition {
        let level = fitted()
        return bands.map(level.keepingBonusesInView) ?? level
    }

    var data: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var bytes = ByteWriter(.level).data
        bytes.append((try? encoder.encode(self)) ?? Data())
        return bytes
    }

    init(id: String, daily: Date? = nil, cycle: Int, aspect: Double, bands: InterfaceBands? = nil, endless: EndlessKey? = nil) {
        self.id = id
        self.daily = daily
        self.cycle = cycle
        self.aspect = aspect
        self.bands = bands
        self.endless = endless
    }

    init?(data: Data) {
        guard data.first == RemoteKind.level.rawValue,
              let level = try? JSONDecoder().decode(RemoteLevel.self, from: data.dropFirst()) else { return nil }
        self = level
    }

    /// Names a level message on both devices (FNV-1a, stable unlike `Hasher`).
    static func token(of data: Data) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for byte in data {
            hash = (hash ^ UInt32(byte)) &* 16_777_619
        }
        return hash == 0 ? 1 : hash
    }
}

/// The moving parts of a phone run, around a hundred bytes per frame.
struct RemoteFrame: Equatable, Sendable {
    enum State: UInt8, Sendable {
        case ready, playing, paused, dead, won
    }

    struct Body: Equatable, Sendable {
        var id: Int
        var position: Vec2
    }

    struct Beam: Equatable, Sendable {
        var id: Int
        var start: Vec2
        var end: Vec2
        var phase: LaserPhase
    }

    /// The level token the frame belongs to, so a late frame from an earlier
    /// run is never drawn over the next arena.
    var level: UInt32
    /// Phone wall-clock time of sending, for measuring the link.
    var sentAt: Double
    var state: State
    var cause: DeathCause?
    var rewindsLeft: Int
    var time: Double
    var nextEcho: Double?
    var exitOpen: Bool
    var phasing: Bool
    var surging: Bool
    var frozen: Bool
    var player: Vec2
    var velocity: Vec2
    var echoes: [Vec2]
    var ghosts: [Vec2]
    var rocks: [Body]
    var collected: UInt64
    var timedOut: UInt64
    /// Sparks that move along an orbit; the rest stay where the level put them.
    var orbiting: [Body]
    var bonusesTaken: UInt64
    var solidGates: UInt64
    var beams: [Beam]

    init(sim: WorldSimulation, level: UInt32, state: State, cause: DeathCause?, sentAt: Double) {
        self.level = level
        self.sentAt = sentAt
        self.state = state
        self.cause = cause
        rewindsLeft = sim.rewindCharges
        time = sim.time
        nextEcho = sim.nextEchoIn
        exitOpen = sim.exitOpen
        phasing = sim.effects.isPhasing
        surging = sim.effects.isSurging
        frozen = sim.effects.isFrozen
        player = sim.playerPosition
        velocity = sim.lastVelocity
        echoes = sim.echoes
        ghosts = sim.ghosts.compactMap { $0.position(at: sim.time) }
        rocks = sim.movers.map { Body(id: $0.id, position: $0.position) }
        collected = Self.mask(sim.sparks.filter(\.collected).map(\.id))
        timedOut = Self.mask(sim.sparks.filter(\.timedOut).map(\.id))
        orbiting = sim.sparks.filter { $0.orbit != nil && !$0.collected }.map { Body(id: $0.id, position: $0.position) }
        bonusesTaken = Self.mask(sim.bonuses.filter(\.collected).map(\.id))
        solidGates = Self.mask(sim.gates.filter(\.solid).map(\.id))
        beams = sim.lasers.map { Beam(id: $0.id, start: $0.start, end: $0.end, phase: $0.phase) }
    }

    static func mask(_ ids: [Int]) -> UInt64 {
        ids.reduce(0) { $1 >= 0 && $1 < 64 ? $0 | (1 << UInt64($1)) : $0 }
    }

    static func contains(_ mask: UInt64, _ id: Int) -> Bool {
        id >= 0 && id < 64 && mask & (1 << UInt64(id)) != 0
    }

    var data: Data {
        var writer = ByteWriter(.frame)
        writer.u32(level)
        writer.f64(sentAt)
        writer.u8(state.rawValue)
        writer.u8(Self.code(for: cause))
        writer.u8(UInt8(clamping: rewindsLeft))
        writer.u8((exitOpen ? 1 : 0) | (phasing ? 2 : 0) | (surging ? 4 : 0) | (frozen ? 8 : 0))
        writer.f32(time)
        writer.u16(nextEcho.map { UInt16(clamping: Int(($0 * 10).rounded())) } ?? .max)
        writer.point(player)
        writer.point(velocity)
        writer.count(echoes.count)
        echoes.prefix(255).forEach { writer.point($0) }
        writer.count(ghosts.count)
        ghosts.prefix(255).forEach { writer.point($0) }
        for bodies in [rocks, orbiting] {
            writer.count(bodies.count)
            for body in bodies.prefix(255) {
                writer.u8(UInt8(clamping: body.id))
                writer.point(body.position)
            }
        }
        writer.u64(collected)
        writer.u64(timedOut)
        writer.u64(bonusesTaken)
        writer.u64(solidGates)
        writer.count(beams.count)
        for beam in beams.prefix(255) {
            writer.u8(UInt8(clamping: beam.id))
            writer.u8(Self.code(for: beam.phase))
            writer.point(beam.start)
            writer.point(beam.end)
        }
        return writer.data
    }

    init?(data: Data) {
        var reader = ByteReader(data)
        do {
            guard try reader.kind() == .frame else { return nil }
            level = try reader.u32()
            sentAt = try reader.f64()
            guard let state = State(rawValue: try reader.u8()) else { return nil }
            self.state = state
            cause = Self.cause(for: try reader.u8())
            rewindsLeft = Int(try reader.u8())
            let flags = try reader.u8()
            exitOpen = flags & 1 != 0
            phasing = flags & 2 != 0
            surging = flags & 4 != 0
            frozen = flags & 8 != 0
            time = try reader.f32()
            let echo = try reader.u16()
            nextEcho = echo == .max ? nil : Double(echo) / 10
            player = try reader.point()
            velocity = try reader.point()
            echoes = try (0..<Int(try reader.u8())).map { _ in try reader.point() }
            ghosts = try (0..<Int(try reader.u8())).map { _ in try reader.point() }
            rocks = try Self.bodies(&reader)
            orbiting = try Self.bodies(&reader)
            collected = try reader.u64()
            timedOut = try reader.u64()
            bonusesTaken = try reader.u64()
            solidGates = try reader.u64()
            beams = try (0..<Int(try reader.u8())).map { _ in
                Beam(id: Int(try reader.u8()), phase: Self.phase(for: try reader.u8()), start: try reader.point(), end: try reader.point())
            }
        } catch {
            return nil
        }
    }

    private static func bodies(_ reader: inout ByteReader) throws -> [Body] {
        try (0..<Int(try reader.u8())).map { _ in Body(id: Int(try reader.u8()), position: try reader.point()) }
    }

    private static func code(for phase: LaserPhase) -> UInt8 {
        switch phase {
        case .idle: 0
        case .charging(let progress): UInt8(1 + (max(0, min(1, progress)) * 99).rounded())
        case .firing: 255
        }
    }

    private static func phase(for code: UInt8) -> LaserPhase {
        switch code {
        case 0: .idle
        case 255: .firing
        default: .charging(Double(code - 1) / 99)
        }
    }

    private static let causes: [DeathCause] = [.echo(index: 0, delay: 0), .asteroid, .laser, .rift, .collision, .ghost, .blackHole]

    private static func code(for cause: DeathCause?) -> UInt8 {
        guard let cause else { return 0 }
        if cause.echoIndex != nil { return 1 }
        return UInt8((causes.firstIndex(of: cause) ?? 0) + 1)
    }

    private static func cause(for code: UInt8) -> DeathCause? {
        code == 0 ? nil : causes[min(Int(code) - 1, causes.count - 1)]
    }
}

private extension RemoteFrame.Beam {
    init(id: Int, phase: LaserPhase, start: Vec2, end: Vec2) {
        self.init(id: id, start: start, end: end, phase: phase)
    }
}
