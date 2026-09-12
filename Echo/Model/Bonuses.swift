import Foundation

enum BonusKind: String, Equatable, Hashable, Sendable, CaseIterable {
    case shield
    case freeze
    case surge
    case pulse
    case magnet
    case phase
    case chrono
    case ward

    var title: String {
        switch self {
        case .shield: "Shield"
        case .freeze: "Freeze"
        case .surge: "Surge"
        case .pulse: "Pulse"
        case .magnet: "Magnet"
        case .phase: "Phase"
        case .chrono: "Shift"
        case .ward: "Ward"
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
        case .ward: "Starting shield — easy-mode, not used from the bar"
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
        case .ward: 0
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
        case .ward: 75
        }
    }

    /// Shop stock you tap in a run. Surge, Pulse, Magnet stay arena-only. Ward is easy-mode leftover stock.
    var canBuy: Bool {
        switch self {
        case .ward: false
        default: true
        }
    }

    var useFromBar: Bool {
        switch self {
        case .ward: false
        default: true
        }
    }

    var cooldown: TimeInterval {
        switch self {
        case .shield: 7
        case .freeze: 11
        case .surge: 9
        case .pulse: 8
        case .magnet: 10
        case .phase: 12
        case .chrono: 13
        case .ward: 0
        }
    }

    var icon: String {
        switch self {
        case .shield: "shield.fill"
        case .freeze: "snowflake"
        case .surge: "bolt.fill"
        case .pulse: "waveform.circle.fill"
        case .magnet: "magnet.fill"
        case .phase: "sparkles"
        case .chrono: "clock.arrow.circlepath"
        case .ward: "lock.shield.fill"
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
        case .ward: "BonusShield"
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
        case .ward: (0.55, 0.90, 0.70)
        }
    }
}

enum UpgradeBranch: String, CaseIterable, Sendable {
    case motion
    case loadout
    case temporal

    var title: String {
        switch self {
        case .motion: "MOTION"
        case .loadout: "LOADOUT"
        case .temporal: "TIME"
        }
    }

    var tint: RGB {
        switch self {
        case .motion: RGB(0.35, 0.82, 1.0)
        case .loadout: RGB(0.75, 0.42, 1.0)
        case .temporal: RGB(1.0, 0.78, 0.32)
        }
    }
}

enum UpgradeKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case velocity
    case dashCapacitor
    case slots
    case reserves
    case aegis
    case recharge
    case beamForecast
    case cryostasis
    case magnetism
    case phaseResearch
    case chronoResearch
    case rewind

    var id: String { rawValue }

    var branch: UpgradeBranch {
        switch self {
        case .velocity, .dashCapacitor, .magnetism: .motion
        case .slots, .reserves, .aegis, .phaseResearch: .loadout
        case .recharge, .beamForecast, .cryostasis, .chronoResearch, .rewind: .temporal
        }
    }

    var title: String {
        switch self {
        case .velocity: "Vector Drive"
        case .dashCapacitor: "Dash Capacitor"
        case .slots: "Slot Matrix"
        case .reserves: "Deep Reserves"
        case .aegis: "Aegis Protocol"
        case .recharge: "Fast Cycle"
        case .beamForecast: "Beam Forecast"
        case .cryostasis: "Cryostasis"
        case .magnetism: "Magnetic Field"
        case .phaseResearch: "Phase Theory"
        case .chronoResearch: "Chrono Theory"
        case .rewind: "Long Rewind"
        }
    }

    var detail: String {
        switch self {
        case .velocity: "Move 5% faster per rank; unlocks Surge."
        case .dashCapacitor: "Reduce double-tap dash cooldown by 12% per rank."
        case .slots: "Add one equipped skill slot per rank."
        case .reserves: "Carry two more charges of every skill."
        case .aegis: "Extend shield recovery; final rank starts each run shielded."
        case .recharge: "Reduce skill cooldowns by 9% per rank."
        case .beamForecast: "Laser emitters telegraph their shot 0.22s earlier per rank."
        case .cryostasis: "Freeze lasts 0.7 seconds longer per rank."
        case .magnetism: "Unlock Magnet and widen its pull radius."
        case .phaseResearch: "Unlock Phase for the loadout."
        case .chronoResearch: "Unlock Shift and temporal Pulse."
        case .rewind: "Extend rewind; rank two adds another charge."
        }
    }

    var icon: String {
        switch self {
        case .velocity: "speedometer"
        case .dashCapacitor: "bolt.circle.fill"
        case .slots: "square.grid.2x2"
        case .reserves: "shippingbox.fill"
        case .aegis: "shield.fill"
        case .recharge: "gauge.with.dots.needle.67percent"
        case .beamForecast: "scope"
        case .cryostasis: "snowflake"
        case .magnetism: "magnet.fill"
        case .phaseResearch: "sparkles"
        case .chronoResearch: "clock.badge.checkmark"
        case .rewind: "clock.arrow.circlepath"
        }
    }

    var maxLevel: Int {
        switch self {
        case .velocity: 5
        case .dashCapacitor: 4
        case .slots: 3
        case .reserves: 3
        case .aegis: 3
        case .recharge: 4
        case .beamForecast: 4
        case .cryostasis: 4
        case .magnetism: 3
        case .phaseResearch, .chronoResearch: 1
        case .rewind: 3
        }
    }

    var baseCost: Int {
        switch self {
        case .velocity: 100
        case .dashCapacitor: 135
        case .slots: 180
        case .reserves: 130
        case .aegis: 190
        case .recharge: 140
        case .beamForecast: 165
        case .cryostasis: 150
        case .magnetism: 170
        case .phaseResearch: 260
        case .chronoResearch: 340
        case .rewind: 220
        }
    }

    var costStep: Int {
        switch self {
        case .velocity: 70
        case .dashCapacitor: 90
        case .slots: 140
        case .reserves: 90
        case .aegis: 125
        case .recharge: 90
        case .beamForecast: 105
        case .cryostasis: 100
        case .magnetism: 110
        case .phaseResearch, .chronoResearch: 0
        case .rewind: 140
        }
    }

    var prerequisites: [(kind: UpgradeKind, level: Int)] {
        switch self {
        case .velocity: []
        case .dashCapacitor: [(.velocity, 1)]
        case .slots: [(.velocity, 1)]
        case .reserves: [(.slots, 1)]
        case .aegis: [(.reserves, 1)]
        case .recharge: [(.velocity, 2)]
        case .beamForecast: [(.recharge, 1)]
        case .cryostasis: [(.recharge, 1)]
        case .magnetism: [(.velocity, 2), (.dashCapacitor, 1)]
        case .phaseResearch: [(.slots, 2), (.aegis, 1)]
        case .chronoResearch: [(.phaseResearch, 1), (.beamForecast, 2)]
        case .rewind: [(.chronoResearch, 1)]
        }
    }

    func cost(after level: Int) -> Int {
        baseCost + max(0, level) * costStep
    }
}

struct PlayerTuning: Equatable, Sendable {
    var speedMultiplier: Double = 1
    var dashCooldownMultiplier: Double = 1
    var cooldownMultiplier: Double = 1
    var freezeBonus: TimeInterval = 0
    var magnetRadiusMultiplier: Double = 1
    var shieldGraceBonus: TimeInterval = 0
    var startsShielded = false
    var laserWarningBonus: TimeInterval = 0
    var rewindSeconds: TimeInterval = 3
    var rewindCharges: Int = 1
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

    var title: String {
        switch self {
        case .echo: "Your first echo"
        case .asteroid: "Asteroids"
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
