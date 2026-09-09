import Foundation

enum BonusKind: String, Equatable, Hashable, Sendable, CaseIterable {
    case shield
    case freeze
    case surge
    case pulse
    case magnet
    case phase
    case chrono

    var title: String {
        switch self {
        case .shield: "Shield"
        case .freeze: "Freeze"
        case .surge: "Surge"
        case .pulse: "Pulse"
        case .magnet: "Magnet"
        case .phase: "Phase"
        case .chrono: "Chrono"
        }
    }

    var detail: String {
        switch self {
        case .shield: "Survive one echo or rock"
        case .freeze: "Echoes and rocks pause"
        case .surge: "Burst of speed"
        case .pulse: "Delay the next copy — arena only"
        case .magnet: "Pull nearby sparks — arena only"
        case .phase: "Walk through copies for a moment"
        case .chrono: "Push the next echo further out"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .shield: 0
        case .freeze: 3.2
        case .surge: 4.0
        case .pulse: 0
        case .magnet: 5.0
        case .phase: 2.4
        case .chrono: 0
        }
    }

    var price: Int {
        switch self {
        case .surge: 60
        case .pulse: 50
        case .magnet: 65
        case .shield: 70
        case .freeze: 80
        case .phase: 90
        case .chrono: 85
        }
    }

    /// Shop stock you can save and fire later. Arena pickups still apply instantly.
    var canBuy: Bool {
        switch self {
        case .pulse, .magnet: false
        default: true
        }
    }

    var icon: String {
        switch self {
        case .shield: "shield.fill"
        case .freeze: "snowflake"
        case .surge: "bolt.fill"
        case .pulse: "waveform.circle.fill"
        case .magnet: "magnet"
        case .phase: "sparkles"
        case .chrono: "clock.arrow.circlepath"
        }
    }

    var assetName: String {
        switch self {
        case .shield: "BonusShield"
        case .freeze: "BonusFreeze"
        case .surge: "BonusSurge"
        case .pulse: "BonusPulse"
        case .magnet: "BonusMagnet"
        case .phase: "BonusShield"
        case .chrono: "BonusFreeze"
        }
    }

    var tint: (r: Double, g: Double, b: Double) {
        switch self {
        case .shield: (0.40, 1.00, 0.65)
        case .freeze: (0.55, 0.82, 1.00)
        case .surge: (1.00, 0.82, 0.28)
        case .pulse: (0.85, 0.40, 1.00)
        case .magnet: (1.00, 0.45, 0.70)
        case .phase: (0.85, 0.95, 1.00)
        case .chrono: (0.70, 0.55, 1.00)
        }
    }
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
    var dashCooldown: TimeInterval = 0
    var iFrames: TimeInterval = 0

    var isFrozen: Bool { freezeRemaining > 0 }
    var isSurging: Bool { surgeRemaining > 0 }
    var isMagnet: Bool { magnetRemaining > 0 }
    var isPhasing: Bool { phaseRemaining > 0 }
    var canDash: Bool { dashCooldown <= 0 }
}

enum RiftKind: String, Equatable, Sendable {
    case calm
    case collision
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

    var title: String {
        switch self {
        case .echo: "Your first echo"
        case .asteroid: "Asteroids"
        case .rift: "Time rifts"
        case .freeze: "Freeze"
        case .phase: "Phase"
        case .collision: "Time collision"
        }
    }

    var detail: String {
        switch self {
        case .echo:
            "A copy of your path just appeared. It will replay what you already did. Do not meet it."
        case .asteroid:
            "Rocks move on their own. A shield eats one hit. Freeze stops them with the echoes."
        case .rift:
            "Rifts open and close. A calm tear pauses time. A collapsing one is a collision — stay out."
        case .freeze:
            "Echoes, rocks, and rifts hold still. Move while the past cannot."
        case .phase:
            "You pass through copies for a moment. Spend it on a bad line, not a pretty one."
        case .collision:
            "Two pasts occupied the same beat. That crack will show up in later worlds as a real hazard."
        }
    }
}
