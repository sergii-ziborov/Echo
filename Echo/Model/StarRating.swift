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
        case .beforeEcho(let n): "Before echo \(n)"
        case .noDash: "No dash"
        case .maxEchoes(let n): "≤\(n) echoes"
        case .noShop: "No arsenal"
        case .causeScar: "Cause a scar"
        case .avoidScar: "No scar"
        case .parTime: "Under par"
        case .useRift: "Enter a rift"
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

    var title: String {
        switch self {
        case .trace: "TRACE"
        case .drift: "DRIFT"
        case .fracture: "FRACTURE"
        case .debris: "DEBRIS"
        case .paradox: "PARADOX"
        case .singularity: "SINGULARITY"
        case .rift: "RIFT"
        case .gravity: "GRAVITY"
        case .mirage: "MIRAGE"
        case .confection: "CONFECTION"
        case .eternity: "ETERNITY"
        }
    }

    var blurb: String {
        switch self {
        case .trace: "Learn to fear your own path."
        case .drift: "Space starts to move."
        case .fracture: "Rifts, gates, scars."
        case .debris: "Outside hazards enter the timeline."
        case .paradox: "Every law at once."
        case .singularity: "The arena learns to fire back."
        case .rift: "Reality develops exits of its own."
        case .gravity: "Every route bends toward the dark."
        case .mirage: "The map lies before your echoes do."
        case .confection: "A beautiful timeline with dangerous rules."
        case .eternity: "Master every law, then survive it faster."
        }
    }

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
        switch max(0, cycle) {
        case 0: "AWAKENING"
        case 1: "FRACTURED"
        case 2: "PARADOX"
        case 3: "SINGULARITY"
        default: "ETERNAL +\(cycle - 3)"
        }
    }

    var shortTitle: String { "D\(number) · \(title)" }

    var detail: String {
        switch max(0, cycle) {
        case 0: "The original 77-epoch timeline."
        case 1: "Faster echoes and more aggressive hazards."
        case 2: "Short laser cycles and stronger gravity."
        case 3: "Maximum echo pressure and unstable rifts."
        default: "An endless escalation beyond the stable timeline."
        }
    }

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

    var headline: String {
        switch self {
        case .echo(let index, let delay):
            let seconds = Int(delay.rounded())
            return "You met echo \(index + 1)"
                + " — your path from \(seconds)s ago"
        case .asteroid:
            return "An asteroid cut your line"
        case .rift:
            return "You stepped into a collapsing rift"
        case .collision:
            return "A time collision left a scar"
        case .ghost:
            return "You met the timeline you discarded"
        case .laser:
            return "A temporal beam erased your route"
        case .blackHole:
            return "A gravity well swallowed your timeline"
        }
    }
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
