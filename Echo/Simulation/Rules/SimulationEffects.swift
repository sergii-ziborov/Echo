import Foundation

struct PlayerTuning: Equatable, Sendable {
    var speedMultiplier: Double = 1
    var pickupRadiusBonus: Double = 0
    var dashCooldownMultiplier: Double = 1
    var dashDurationBonus: TimeInterval = 0
    var cooldownMultiplier: Double = 1
    var timedEffectMultiplier: Double = 1
    var surgeBonus: TimeInterval = 0
    var freezeBonus: TimeInterval = 0
    var magnetRadiusMultiplier: Double = 1
    var shieldGraceBonus: TimeInterval = 0
    var startsShielded = false
    var shieldChargesPerUse: Int = 1
    var laserWarningBonus: TimeInterval = 0
    var echoDelayBonus: TimeInterval = 0
    var crystalRewardBonus: TimeInterval = 0
    var rewindSeconds: TimeInterval = 3
    var rewindCharges: Int = 1
    var anchorTimeScale: Double = 0.42
    var anchorBonus: TimeInterval = 0
    var repulseRadius: Double = 175
    var prismBonus: TimeInterval = 0
    var blinkDistance: Double = 190
    var phaseBonus: TimeInterval = 0
    var chronoDelayBonus: TimeInterval = 0
    var pulseDelayBonus: TimeInterval = 0
}

struct BonusSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var kind: BonusKind
    var position: Vec2
}

struct SlowField: Equatable, Sendable, Identifiable {
    var id: Int
    var area: AABB
}

struct SparkOrbit: Equatable, Sendable {
    var center: Vec2
    var radius: Double
    var period: TimeInterval
    var phase: Double = 0
}

struct BonusState: Equatable, Sendable, Identifiable {
    var id: Int
    var kind: BonusKind
    var position: Vec2
    var collected: Bool
}

struct ActiveEffects: Equatable, Sendable {
    var shieldCharges: Int = 0
    var freezeRemaining: TimeInterval = 0
    var surgeRemaining: TimeInterval = 0
    var magnetRemaining: TimeInterval = 0
    var phaseRemaining: TimeInterval = 0
    var anchorRemaining: TimeInterval = 0
    var prismRemaining: TimeInterval = 0
    var dashCooldown: TimeInterval = 0
    var iFrames: TimeInterval = 0

    var isFrozen: Bool { freezeRemaining > 0 }
    var isSurging: Bool { surgeRemaining > 0 }
    var isMagnet: Bool { magnetRemaining > 0 }
    var isPhasing: Bool { phaseRemaining > 0 }
    var isAnchored: Bool { anchorRemaining > 0 }
    var isPrismatic: Bool { prismRemaining > 0 }
    var canDash: Bool { dashCooldown <= 0 }
}

enum RiftKind: String, Equatable, Sendable {
    case calm
    case collision
    case warp
    case candy
}

enum RealityMode: String, Equatable, Sendable {
    case normal
    case candy
    case mirror
}

struct RiftSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var kind: RiftKind
    var position: Vec2
    var radius: Double = 52
    var period: TimeInterval = 7
    var openFor: TimeInterval = 2.8
    var phase: TimeInterval = 0
}

struct RiftState: Equatable, Sendable, Identifiable {
    var id: Int
    var kind: RiftKind
    var position: Vec2
    var radius: Double
    var period: TimeInterval
    var openFor: TimeInterval
    var phase: TimeInterval
    var open: Bool = false
    var usedThisCycle: Bool = false

    func isOpen(at time: TimeInterval) -> Bool {
        guard period > 0 else { return false }
        let t = (time + phase).truncatingRemainder(dividingBy: period)
        return t >= 0 && t < openFor
    }
}

enum EncounterHint: String, Equatable, Sendable {
    case echo
    case asteroid
    case rift
    case freeze
    case phase
    case collision
    case gate
    case laser
    case timeCrystal
    case resonance
    case blackHole
    case realityShift
    case surge
    case pulse
    case magnet
    case chrono
    case anchor
    case repulse
    case prism
    case blink

    /// The ability this card introduces, if it is one of the skills.
    private var skill: BonusKind? {
        switch self {
        case .freeze: .freeze
        case .phase: .phase
        case .surge: .surge
        case .pulse: .pulse
        case .magnet: .magnet
        case .chrono: .chrono
        case .anchor: .anchor
        case .repulse: .repulse
        case .prism: .prism
        case .blink: .blink
        default: nil
        }
    }

    var title: String {
        skill?.title ?? Copy.text("hint.\(rawValue).title")
    }

    var detail: String {
        switch self {
        case .freeze, .phase: Copy.text("hint.\(rawValue).detail")
        case .resonance: Copy.format("hint.resonance.detail", Copy.seconds(WorldSimulation.normalResonanceWindow))
        default: skill?.detail ?? Copy.text("hint.\(rawValue).detail")
        }
    }

    var action: String {
        skill?.command ?? Copy.text("hint.\(rawValue).action")
    }
}

struct TimeGateSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var area: AABB
    var period: TimeInterval = 5.5
    var openFor: TimeInterval = 2.4
    var phase: TimeInterval = 0
}

struct TimeGateState: Equatable, Sendable, Identifiable {
    var id: Int
    var area: AABB
    var period: TimeInterval
    var openFor: TimeInterval
    var phase: TimeInterval
    var solid: Bool = true

    func isSolid(at time: TimeInterval) -> Bool {
        guard period > 0 else { return true }
        let t = (time + phase).truncatingRemainder(dividingBy: period)
        return t >= openFor
    }
}

struct CollisionScar: Equatable, Sendable, Identifiable {
    var id: Int
    var position: Vec2
    var radius: Double
    var remaining: TimeInterval
}
