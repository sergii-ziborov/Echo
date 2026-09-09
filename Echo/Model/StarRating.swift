import Foundation

enum StarRating {
    static func stars(time: TimeInterval, moves: Int, parTime: TimeInterval, parMoves: Int) -> Int {
        if time <= parTime && moves <= parMoves { return 3 }
        if time <= parTime * 1.35 || moves <= Int(Double(parMoves) * 1.35) { return 2 }
        return 1
    }

    static func points(stars: Int, bonuses: Int) -> Int {
        max(0, stars) * 50 + max(0, bonuses) * 20 + 10
    }
}

struct SessionResult: Equatable, Sendable {
    var time: TimeInterval
    var moves: Int
    var stars: Int
    var sparks: Int
    var echoesFaced: Int
    var bonuses: Int = 0
    var dashed: Bool = false
    var usedItem: Bool = false
    var scars: Int = 0
    var riftsUsed: Int = 0
    var closest: Double = .infinity
    var control: Bool = false
    var paradox: Bool = false

    var points: Int {
        StarRating.points(stars: stars, bonuses: bonuses)
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

    var title: String {
        switch self {
        case .trace: "TRACE"
        case .drift: "DRIFT"
        case .fracture: "FRACTURE"
        case .debris: "DEBRIS"
        case .paradox: "PARADOX"
        }
    }

    var blurb: String {
        switch self {
        case .trace: "Learn to fear your own path."
        case .drift: "Space starts to move."
        case .fracture: "Rifts, gates, scars."
        case .debris: "Outside hazards enter the timeline."
        case .paradox: "Every law at once."
        }
    }

    var range: ClosedRange<Int> {
        let start = (rawValue - 1) * 6 + 1
        return start...(start + 5)
    }

    static func containing(level number: Int) -> Act {
        Act(rawValue: min(5, max(1, (number - 1) / 6 + 1))) ?? .trace
    }
}

enum DeathCause: Equatable, Sendable {
    case echo(index: Int, delay: TimeInterval)
    case asteroid
    case rift
    case collision
    case ghost

    var echoIndex: Int? {
        switch self {
        case .echo(let index, _): index
        case .asteroid, .rift, .collision, .ghost: nil
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
    var rifts: [RiftState]
    var gates: [TimeGateState]
    var scars: [CollisionScar]
    var effects: ActiveEffects
    var exitOpen: Bool
    var moves: Int
    var bonusesCollected: Int
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
}
