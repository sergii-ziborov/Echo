import Foundation

enum StarRating {
    static func stars(time: TimeInterval, moves: Int, parTime: TimeInterval, parMoves: Int) -> Int {
        if time <= parTime && moves <= parMoves { return 3 }
        if time <= parTime * 1.35 || moves <= Int(Double(parMoves) * 1.35) { return 2 }
        return 1
    }

    static func points(stars: Int, bonuses: Int, timeCrystals: Int = 0, resonance: Int = 0) -> Int {
        max(0, stars) * 50
            + max(0, bonuses) * 20
            + max(0, timeCrystals) * 15
            + max(0, resonance - 1) * 10
            + 10
    }
}

struct SessionResult: Equatable, Sendable {
    var time: TimeInterval
    var moves: Int
    var stars: Int
    var sparks: Int
    var echoesFaced: Int
    var bonuses: Int = 0
    var timeCrystals: Int = 0
    var resonance: Int = 0
    var dashed: Bool = false
    var usedItem: Bool = false
    var scars: Int = 0
    var riftsUsed: Int = 0
    var closest: Double = .infinity
    var control: Bool = false
    var paradox: Bool = false

    var points: Int {
        StarRating.points(stars: stars, bonuses: bonuses, timeCrystals: timeCrystals, resonance: resonance)
    }
}

enum SealKind: Equatable, Sendable {
    case beforeEcho(Int)
    case noDash
    case maxEchoes(Int)
    case noShop
    case causeScar
    case avoidScar
    case parTime
    case useRift

    var label: String {
        switch self {
        case .beforeEcho(let n): Copy.format("seal.beforeEcho", n)
        case .noDash: Copy.text("seal.noDash")
        case .maxEchoes(let n): Copy.format("seal.maxEchoes", n)
        case .noShop: Copy.text("seal.noShop")
        case .causeScar: Copy.text("seal.causeScar")
        case .avoidScar: Copy.text("seal.avoidScar")
        case .parTime: Copy.text("seal.parTime")
        case .useRift: Copy.text("seal.useRift")
        }
    }

    func met(by result: SessionResult, parTime: TimeInterval) -> Bool {
        switch self {
        case .beforeEcho(let n): result.echoesFaced < n
        case .noDash: !result.dashed
        case .maxEchoes(let n): result.echoesFaced <= n
        case .noShop: !result.usedItem
        case .causeScar: result.scars >= 1
        case .avoidScar: result.scars == 0
        case .parTime: result.time <= parTime
        case .useRift: result.riftsUsed >= 1
        }
    }
}

enum Act: Int, CaseIterable, Sendable {
    case trace = 1
    case drift
    case fracture
    case debris
    case paradox
    case singularity
    case rift
    case gravity
    case mirage
    case confection
    case eternity

    /// The act's chapter heading, such as TRACE.
    var title: String { Copy.text("region.\(key).act") }

    /// One line about the region for the Atlas.
    var blurb: String { Copy.text("region.\(key).blurb") }

    var range: ClosedRange<Int> {
        let start = (rawValue - 1) * 7 + 1
        return start...(start + 6)
    }

    static func containing(level number: Int) -> Act {
        Act(rawValue: min(allCases.count, max(1, (number - 1) / 7 + 1))) ?? .trace
    }
}

struct DifficultyProfile: Equatable, Sendable {
    var cycle: Int

    var number: Int { max(0, cycle) + 1 }

    var title: String {
        max(0, cycle) <= 3 ? Copy.text("difficulty.\(max(0, cycle)).title") : Copy.format("difficulty.eternal", cycle - 3)
    }

    var shortTitle: String { Copy.format("difficulty.short", number, title) }

    var detail: String { Copy.text("difficulty.\(min(4, max(0, cycle))).detail") }

    var hazardMultiplier: Double { 1 + Double(max(0, cycle)) * 0.12 }
}

enum DeathCause: Equatable, Sendable {
    case echo(index: Int, delay: TimeInterval)
    case asteroid
    case rift
    case collision
    case ghost
    case laser
    case blackHole

    var echoIndex: Int? {
        switch self {
        case .echo(let index, _): index
        case .asteroid, .rift, .collision, .ghost, .laser, .blackHole: nil
        }
    }

    /// Stable key of the cause's texts; `.blackHole` reads as a field well.
    var key: String {
        switch self {
        case .echo: "echo"
        case .asteroid: "asteroid"
        case .rift: "rift"
        case .collision: "collision"
        case .ghost: "ghost"
        case .laser: "laser"
        case .blackHole: "blackHole"
        }
    }

    var headline: String {
        switch self {
        case .echo(let index, let delay):
            Copy.format("death.cause.echo", index + 1, Int(delay.rounded()))
        default:
            Copy.text("death.cause.\(key)")
        }
    }

    /// What to do differently next time.
    var tip: String { Copy.text("death.tip.\(key)") }
}

struct EchoThreat: Equatable, Sendable {
    var echoIndex: Int
    var distance: Double
    var eta: TimeInterval
    var willCollide: Bool
}

struct ParadoxGhost: Equatable, Sendable {
    var samples: [PathSample]
    var bornAt: TimeInterval

    func position(at time: TimeInterval) -> Vec2? {
        guard let first = samples.first, let last = samples.last else { return nil }
        let local = time - bornAt
        if local < 0 { return first.position }
        if local >= last.time { return nil }
        var rec = PathRecorder()
        for sample in samples { rec.record(time: sample.time, position: sample.position) }
        return rec.position(at: local)
    }

    func isAlive(at time: TimeInterval) -> Bool {
        guard let last = samples.last else { return false }
        let local = time - bornAt
        return local >= 0 && local < last.time
    }
}

struct WorldSnapshot: Equatable, Sendable {
    var time: TimeInterval
    var playbackTime: TimeInterval
    var player: Vec2
    var lastVelocity: Vec2
    var lastAim: Vec2
    var echoes: [Vec2]
    var sparks: [SparkState]
    var bonuses: [BonusState]
    var movers: [MoverState]
    var lasers: [LaserState]
    var rifts: [RiftState]
    var gates: [TimeGateState]
    var scars: [CollisionScar]
    var effects: ActiveEffects
    var exitOpen: Bool
    var moves: Int
    var bonusesCollected: Int
    var timedSparksSecured: Int
    var resonanceChain: Int
    var bestResonance: Int
    var resonanceRemaining: TimeInterval
    var hasStarted: Bool
    var recorder: PathRecorder
    var pulseDelay: TimeInterval
    var warnedFor: Int
    var distanceAcc: Double
    var ghosts: [ParadoxGhost]
    var dashed: Bool
    var usedItem: Bool
    var scarsCreated: Int
    var riftsUsed: Int
    var closestApproach: Double
    var reality: RealityMode
    var realityRemaining: TimeInterval
    var riftTravelCooldown: TimeInterval
}
