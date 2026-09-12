import Foundation

enum BonusKind: String, Equatable, Hashable, Sendable, CaseIterable, Identifiable {
    case shield
    case freeze
    case surge
    case pulse
    case magnet
    case phase
    case chrono
    case anchor
    case repulse
    case prism
    case blink
    case ward

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shield: "Shield"
        case .freeze: "Freeze"
        case .surge: "Surge"
        case .pulse: "Pulse"
        case .magnet: "Magnet"
        case .phase: "Phase"
        case .chrono: "Shift"
        case .anchor: "Anchor"
        case .repulse: "Repulse"
        case .prism: "Prism"
        case .blink: "Blink"
        case .ward: "Ward"
        }
    }

    var detail: String {
        switch self {
        case .shield: "Block the next collision."
        case .freeze: "Stop every hazard; you keep moving."
        case .surge: "Move much faster and trail lightning."
        case .pulse: "Delay the next echo with a time wave."
        case .magnet: "Pull every nearby spark toward you."
        case .phase: "Pass safely through echoes and debris."
        case .chrono: "Push the next echo far into the future."
        case .anchor: "Slow the whole timeline; you stay fast."
        case .repulse: "Blast rocks and scars away from you."
        case .prism: "Bend lasers around you for a moment."
        case .blink: "Jump forward through a dangerous line."
        case .ward: "Starting shield — easy-mode, not used from the bar"
        }
    }

    var command: String {
        switch self {
        case .shield: "TAP BEFORE IMPACT"
        case .freeze: "TAP · HAZARDS STOP"
        case .surge: "TAP · ESCAPE FAST"
        case .pulse: "TAP BEFORE ECHO SPAWNS"
        case .magnet: "TAP NEAR MANY SPARKS"
        case .phase: "TAP · CROSS THROUGH DANGER"
        case .chrono: "TAP · BUY MORE TIME"
        case .anchor: "TAP · OUTRUN THE WORLD"
        case .repulse: "TAP WHEN SURROUNDED"
        case .prism: "TAP BEFORE THE BEAM FIRES"
        case .blink: "FACE A DIRECTION · TAP"
        case .ward: "AUTOMATIC AT START"
        }
    }

    var bestUse: String {
        switch self {
        case .shield: "When one unavoidable hit is close."
        case .freeze: "When several moving hazards overlap."
        case .surge: "On long routes or while escaping an echo."
        case .pulse: "When the echo countdown is almost empty."
        case .magnet: "Inside a dense cluster of sparks."
        case .phase: "To cut through a trapped corridor."
        case .chrono: "Before a difficult final route."
        case .anchor: "When timing windows are too tight."
        case .repulse: "Among brittle rocks or lethal scars."
        case .prism: "While crossing a charged laser."
        case .blink: "To skip one wall, beam, or collision line."
        case .ward: "At the beginning of assisted runs."
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
        case .anchor: 5.0
        case .repulse: 0
        case .prism: 4.5
        case .blink: 0
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
        case .anchor: 115
        case .repulse: 105
        case .prism: 120
        case .blink: 110
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
        case .anchor: 14
        case .repulse: 12
        case .prism: 13
        case .blink: 10
        case .ward: 0
        }
    }

    var icon: String {
        switch self {
        case .shield: "shield.fill"
        case .freeze: "snowflake"
        case .surge: "bolt.fill"
        case .pulse: "waveform.circle.fill"
        case .magnet: "dot.radiowaves.left.and.right"
        case .phase: "sparkles"
        case .chrono: "clock.arrow.circlepath"
        case .anchor: "hourglass.bottomhalf.filled"
        case .repulse: "burst.fill"
        case .prism: "triangle.fill"
        case .blink: "arrow.forward.to.line.compact"
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
        case .anchor: "BonusFreeze"
        case .repulse: "BonusPulse"
        case .prism: "BonusShield"
        case .blink: "BonusSurge"
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
        case .anchor: (0.30, 0.88, 1.00)
        case .repulse: (1.00, 0.38, 0.62)
        case .prism: (0.60, 1.00, 0.92)
        case .blink: (0.52, 0.62, 1.00)
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
    case sparkSense
    case dashCapacitor
    case surgeMastery
    case dashImpulse
    case slots
    case reserves
    case fabricator
    case aegis
    case shieldLattice
    case fieldAmplifier
    case recharge
    case beamForecast
    case cryostasis
    case echoForecast
    case crystalMemory
    case magnetism
    case phaseResearch
    case chronoResearch
    case rewind
    case anchorResearch
    case repulseResearch
    case prismResearch
    case blinkResearch

    var id: String { rawValue }

    var branch: UpgradeBranch {
        switch self {
        case .velocity, .sparkSense, .dashCapacitor, .surgeMastery, .dashImpulse,
             .magnetism, .repulseResearch, .blinkResearch: .motion
        case .slots, .reserves, .fabricator, .aegis, .shieldLattice,
             .fieldAmplifier, .phaseResearch, .prismResearch: .loadout
        case .recharge, .beamForecast, .cryostasis, .echoForecast, .crystalMemory,
             .chronoResearch, .rewind, .anchorResearch: .temporal
        }
    }

    var title: String {
        switch self {
        case .velocity: "Vector Drive"
        case .sparkSense: "Spark Sense"
        case .dashCapacitor: "Dash Capacitor"
        case .surgeMastery: "Storm Runner"
        case .dashImpulse: "Kinetic Impulse"
        case .slots: "Slot Matrix"
        case .reserves: "Deep Reserves"
        case .fabricator: "Nano Fabricator"
        case .aegis: "Aegis Protocol"
        case .shieldLattice: "Shield Lattice"
        case .fieldAmplifier: "Field Amplifier"
        case .recharge: "Fast Cycle"
        case .beamForecast: "Beam Forecast"
        case .cryostasis: "Cryostasis"
        case .echoForecast: "Echo Forecast"
        case .crystalMemory: "Crystal Memory"
        case .magnetism: "Magnetic Field"
        case .phaseResearch: "Phase Theory"
        case .chronoResearch: "Chrono Theory"
        case .rewind: "Long Rewind"
        case .anchorResearch: "World Anchor"
        case .repulseResearch: "Repulse Core"
        case .prismResearch: "Prism Shell"
        case .blinkResearch: "Blink Drive"
        }
    }

    var detail: String {
        switch self {
        case .velocity: "Your orb moves 4% faster per rank. Rank 1 also unlocks Surge for the Skills tab."
        case .sparkSense: "Nearby sparks jump into your orb automatically. Every rank expands the collection ring."
        case .dashCapacitor: "Your double-tap dash becomes ready 9% sooner per rank. Dash distance does not change."
        case .surgeMastery: "Every Surge charge keeps its speed and lightning trail active 0.45s longer per rank."
        case .dashImpulse: "Each double-tap dash travels farther and keeps its safe crossing window open longer."
        case .slots: "Adds one ability slot. A new, larger activation button appears during a run."
        case .reserves: "Adds two charges to every owned ability, so you can activate it more often per run."
        case .fabricator: "Future ability charges cost 5% fewer research points per rank. Earlier purchases are unchanged."
        case .aegis: "After a shield hit, you stay protected longer. At rank 5 every new run starts shielded."
        case .shieldLattice: "Extends safety after impact. Rank 5 lets Shield absorb two separate hits."
        case .fieldAmplifier: "Freeze, Surge, Magnet, Phase, Anchor and Prism last 4% longer per rank."
        case .recharge: "All equipped abilities recover 8% faster per rank after you activate them."
        case .beamForecast: "Laser warning lines appear 0.18s earlier per rank, giving you more time to move."
        case .cryostasis: "Freeze holds asteroids, echoes and moving hazards still for 0.55s longer per rank."
        case .echoForecast: "Each recorded echo starts 0.45s later per rank, leaving more space behind you."
        case .crystalMemory: "Timed crystals release 0.30s more emergency Freeze energy per rank when collected."
        case .magnetism: "Unlocks Magnet. Further ranks widen the field that pulls sparks toward your orb."
        case .phaseResearch: "Unlocks Phase. Higher ranks keep you intangible longer while crossing hazards."
        case .chronoResearch: "Unlocks Shift and Pulse. Further ranks push dangerous timeline events farther away."
        case .rewind: "Rewinds more of your route. Ranks 2 and 5 add another rewind charge for each run."
        case .anchorResearch: "Unlocks Anchor. Each rank slows the world more while your orb keeps full speed."
        case .repulseResearch: "Unlocks Repulse. Each rank makes its blast clear a wider circle around your orb."
        case .prismResearch: "Unlocks Prism. Higher ranks bend lasers away from you for longer."
        case .blinkResearch: "Unlocks Blink. Each rank teleports your orb farther across one danger zone."
        }
    }

    var useCase: String {
        switch self {
        case .velocity: "Best for races, collapsing lanes and crystals with short timers."
        case .sparkSense: "Best when sparks sit near walls, lasers or moving asteroids."
        case .dashCapacitor: "Best on maps that demand several emergency dodges in a row."
        case .surgeMastery: "Best for long open routes and escaping a pursuing echo."
        case .dashImpulse: "Best for crossing gates, walls and wide hazard lanes in one move."
        case .slots: "Use it when you own more abilities than you can bring into a run."
        case .reserves: "Best for long levels where one or two activations are not enough."
        case .fabricator: "Buy early if you plan to collect and upgrade many abilities."
        case .aegis: "Best for learning dense maps without losing a run to one mistake."
        case .shieldLattice: "Best against chain collisions and hazards that strike twice quickly."
        case .fieldAmplifier: "Best for loadouts built around timed area effects."
        case .recharge: "Best when your strongest ability is often still cooling down."
        case .beamForecast: "Best on laser-heavy maps and narrow corridors."
        case .cryostasis: "Best for safely collecting crystals inside crowded rooms."
        case .echoForecast: "Best when your own previous route blocks the next objective."
        case .crystalMemory: "Best when the timer is nearly empty and the map is already crowded."
        case .magnetism: "Best for collecting risky sparks without touching their exact position."
        case .phaseResearch: "Best for direct shortcuts through asteroids, gates and echo trails."
        case .chronoResearch: "Best for delaying the next wave while you finish an objective."
        case .rewind: "Best for undoing a wrong turn or returning to a missed crystal."
        case .anchorResearch: "Best when several moving hazards converge at the same time."
        case .repulseResearch: "Best when enemies and breakable asteroids surround you."
        case .prismResearch: "Best for crossing overlapping laser beams without waiting."
        case .blinkResearch: "Best for instant escapes across a wall or fatal collision line."
        }
    }

    var icon: String {
        switch self {
        case .velocity: "speedometer"
        case .sparkSense: "dot.radiowaves.left.and.right"
        case .dashCapacitor: "bolt.circle.fill"
        case .surgeMastery: "bolt.horizontal.circle.fill"
        case .dashImpulse: "arrow.right.circle.fill"
        case .slots: "square.grid.2x2"
        case .reserves: "shippingbox.fill"
        case .fabricator: "atom"
        case .aegis: "shield.fill"
        case .shieldLattice: "shield.lefthalf.filled"
        case .fieldAmplifier: "wave.3.up.circle.fill"
        case .recharge: "gauge.with.dots.needle.67percent"
        case .beamForecast: "scope"
        case .cryostasis: "snowflake"
        case .echoForecast: "eye.trianglebadge.exclamationmark.fill"
        case .crystalMemory: "diamond.circle.fill"
        case .magnetism: "dot.radiowaves.left.and.right"
        case .phaseResearch: "sparkles"
        case .chronoResearch: "clock.badge.checkmark"
        case .rewind: "clock.arrow.circlepath"
        case .anchorResearch: "hourglass.bottomhalf.filled"
        case .repulseResearch: "burst.fill"
        case .prismResearch: "triangle.fill"
        case .blinkResearch: "arrow.forward.to.line.compact"
        }
    }

    var maxLevel: Int {
        switch self {
        case .velocity: 7
        case .sparkSense: 5
        case .dashCapacitor: 6
        case .surgeMastery, .dashImpulse: 5
        case .slots: 4
        case .reserves: 6
        case .fabricator: 5
        case .aegis: 5
        case .shieldLattice, .fieldAmplifier: 5
        case .recharge: 6
        case .beamForecast: 6
        case .cryostasis: 6
        case .echoForecast, .crystalMemory: 5
        case .magnetism: 5
        case .phaseResearch, .chronoResearch: 3
        case .rewind: 5
        case .anchorResearch, .repulseResearch, .blinkResearch: 4
        case .prismResearch: 3
        }
    }

    var baseCost: Int {
        switch self {
        case .velocity: 100
        case .sparkSense: 125
        case .dashCapacitor: 135
        case .surgeMastery: 260
        case .dashImpulse: 285
        case .slots: 180
        case .reserves: 130
        case .fabricator: 210
        case .aegis: 190
        case .shieldLattice: 300
        case .fieldAmplifier: 325
        case .recharge: 140
        case .beamForecast: 165
        case .cryostasis: 150
        case .echoForecast: 280
        case .crystalMemory: 245
        case .magnetism: 170
        case .phaseResearch: 260
        case .chronoResearch: 340
        case .rewind: 220
        case .anchorResearch: 390
        case .repulseResearch: 350
        case .prismResearch: 430
        case .blinkResearch: 470
        }
    }

    var costStep: Int {
        switch self {
        case .velocity: 70
        case .sparkSense: 80
        case .dashCapacitor: 90
        case .surgeMastery: 135
        case .dashImpulse: 145
        case .slots: 140
        case .reserves: 90
        case .fabricator: 125
        case .aegis: 125
        case .shieldLattice: 155
        case .fieldAmplifier: 165
        case .recharge: 90
        case .beamForecast: 105
        case .cryostasis: 100
        case .echoForecast: 145
        case .crystalMemory: 125
        case .magnetism: 110
        case .phaseResearch, .chronoResearch: 155
        case .rewind: 140
        case .anchorResearch: 190
        case .repulseResearch: 175
        case .prismResearch: 220
        case .blinkResearch: 240
        }
    }

    var prerequisites: [(kind: UpgradeKind, level: Int)] {
        switch self {
        case .velocity: []
        case .sparkSense: [(.velocity, 2)]
        case .dashCapacitor: [(.velocity, 1)]
        case .surgeMastery: [(.velocity, 4), (.sparkSense, 2)]
        case .dashImpulse: [(.dashCapacitor, 3)]
        case .slots: [(.velocity, 1)]
        case .reserves: [(.slots, 1)]
        case .fabricator: [(.reserves, 2)]
        case .aegis: [(.reserves, 1)]
        case .shieldLattice: [(.aegis, 3)]
        case .fieldAmplifier: [(.phaseResearch, 2), (.recharge, 2)]
        case .recharge: [(.velocity, 2)]
        case .beamForecast: [(.recharge, 1)]
        case .cryostasis: [(.recharge, 1)]
        case .echoForecast: [(.beamForecast, 2)]
        case .crystalMemory: [(.cryostasis, 2)]
        case .magnetism: [(.velocity, 2), (.dashCapacitor, 1)]
        case .phaseResearch: [(.slots, 2), (.aegis, 1)]
        case .chronoResearch: [(.phaseResearch, 1), (.beamForecast, 2)]
        case .rewind: [(.chronoResearch, 1)]
        case .repulseResearch: [(.magnetism, 2)]
        case .blinkResearch: [(.dashCapacitor, 3), (.repulseResearch, 1)]
        case .prismResearch: [(.aegis, 2), (.beamForecast, 2)]
        case .anchorResearch: [(.cryostasis, 2), (.recharge, 3)]
        }
    }

    func cost(after level: Int) -> Int {
        baseCost + max(0, level) * costStep
    }
}

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
            "Ice, crystal, and basalt crack after wall hits. The small ring shows time until they break; metal alloy never breaks."
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
