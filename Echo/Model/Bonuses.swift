import Foundation

enum BonusKind: String, Equatable, Hashable, Sendable, CaseIterable {
    case shield
    case freeze
    case surge
    case pulse
    case magnet

    var title: String {
        switch self {
        case .shield: "Shield"
        case .freeze: "Freeze"
        case .surge: "Surge"
        case .pulse: "Pulse"
        case .magnet: "Magnet"
        }
    }

    var detail: String {
        switch self {
        case .shield: "Survive one echo"
        case .freeze: "Echoes pause"
        case .surge: "Burst of speed"
        case .pulse: "Delay the next copy"
        case .magnet: "Pull nearby sparks"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .shield: 0
        case .freeze: 3.2
        case .surge: 4.0
        case .pulse: 0
        case .magnet: 5.0
        }
    }

    var price: Int {
        switch self {
        case .surge: 60
        case .pulse: 50
        case .magnet: 65
        case .shield: 70
        case .freeze: 80
        }
    }

    var icon: String {
        switch self {
        case .shield: "shield.fill"
        case .freeze: "snowflake"
        case .surge: "bolt.fill"
        case .pulse: "waveform.circle.fill"
        case .magnet: "magnet"
        }
    }

    var assetName: String {
        switch self {
        case .shield: "BonusShield"
        case .freeze: "BonusFreeze"
        case .surge: "BonusSurge"
        case .pulse: "BonusPulse"
        case .magnet: "BonusMagnet"
        }
    }

    var tint: (r: Double, g: Double, b: Double) {
        switch self {
        case .shield: (0.40, 1.00, 0.65)
        case .freeze: (0.55, 0.82, 1.00)
        case .surge: (1.00, 0.82, 0.28)
        case .pulse: (0.85, 0.40, 1.00)
        case .magnet: (1.00, 0.45, 0.70)
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
    var dashCooldown: TimeInterval = 0
    var iFrames: TimeInterval = 0

    var isFrozen: Bool { freezeRemaining > 0 }
    var isSurging: Bool { surgeRemaining > 0 }
    var isMagnet: Bool { magnetRemaining > 0 }
    var canDash: Bool { dashCooldown <= 0 }
}
