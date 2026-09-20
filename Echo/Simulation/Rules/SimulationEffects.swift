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

    var title: String {
        switch self {
        case .echo: "Violet orb = your echo"
        case .asteroid: "Moving rock = asteroid"
        case .rift: "Time rifts"
        case .freeze: "Freeze"
        case .phase: "Phase"
        case .collision: "Time collision"
        case .gate: "Time gates"
        case .laser: "Temporal lasers"
        case .timeCrystal: "Timed crystals"
        case .resonance: "Resonance route"
        case .blackHole: "Gravity wells"
        case .realityShift: "Reality breach"
        case .surge: "Surge"
        case .pulse: "Pulse"
        case .magnet: "Magnet"
        case .chrono: "Shift"
        case .anchor: "Anchor"
        case .repulse: "Repulse"
        case .prism: "Prism"
        case .blink: "Blink"
        }
    }

    var detail: String {
        switch self {
        case .echo:
            "It repeats the route you just drew. Change direction so the violet orb never touches you."
        case .asteroid:
            "Ice, crystal, and basalt crack after wall hits. Watch the cracks open and chips flake off; metal alloy never breaks."
        case .rift:
            "Rifts open and close. A calm tear pauses time. A collapsing one is a collision — stay out."
        case .freeze:
            "Echoes, rocks, rifts, gates, lasers, and crystal countdowns hold still. Move while the past cannot."
        case .phase:
            "You pass through copies for a moment. Spend it on a bad line, not a pretty one."
        case .collision:
            "Two pasts occupied the same beat. The scar they leave is lethal for a few seconds."
        case .gate:
            "These bars vanish and return on a clock. Freeze holds them too."
        case .laser:
            "Emitters charge before the line flares lethal. Some beams sweep across the arena. Freeze suspends and disarms them."
        case .timeCrystal:
            "Take the crystal before its ring empties to gain bonus Freeze time and points. Freeze pauses this countdown too."
        case .resonance:
            "Collect another spark within 3.25 seconds to extend the chain. Longer routes earn bonus research points."
        case .blackHole:
            "The bright lens is only a warning. Gravity pulls inside the outer ring; the dark core ends the run. Freeze suspends its pull."
        case .realityShift:
            "Warp tears fold the arena. Candy tears open a temporary pocket timeline with faster movement and a wider resonance window."
        case .surge: BonusKind.surge.detail
        case .pulse: BonusKind.pulse.detail
        case .magnet: BonusKind.magnet.detail
        case .chrono: BonusKind.chrono.detail
        case .anchor: BonusKind.anchor.detail
        case .repulse: BonusKind.repulse.detail
        case .prism: BonusKind.prism.detail
        case .blink: BonusKind.blink.detail
        }
    }

    var action: String {
        switch self {
        case .echo: "YOUR OLD PATH CHASES YOU"
        case .asteroid: "WALL HITS CRACK SOME ROCKS"
        case .rift: "ENTER ONLY WHILE THE RING IS OPEN"
        case .freeze: BonusKind.freeze.command
        case .phase: BonusKind.phase.command
        case .collision: "LEAVE THE PURPLE SCAR"
        case .gate: "CROSS WHILE THE BAR IS GONE"
        case .laser: "MOVE AFTER CHARGE · BEFORE FIRE"
        case .timeCrystal: "TAKE IT BEFORE THE RING EMPTIES"
        case .resonance: "CHAIN SPARKS BEFORE TIME RUNS OUT"
        case .blackHole: "ESCAPE THE OUTER RING"
        case .realityShift: "A TEAR CHANGES THE ARENA RULES"
        case .surge: BonusKind.surge.command
        case .pulse: BonusKind.pulse.command
        case .magnet: BonusKind.magnet.command
        case .chrono: BonusKind.chrono.command
        case .anchor: BonusKind.anchor.command
        case .repulse: BonusKind.repulse.command
        case .prism: BonusKind.prism.command
        case .blink: BonusKind.blink.command
        }
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
