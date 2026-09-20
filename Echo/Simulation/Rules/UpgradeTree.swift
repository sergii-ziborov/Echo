import Foundation

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
        case .surgeMastery: "Every Surge charge keeps the speed boost active 0.45s longer per rank."
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
        case .surgeMastery: "hare.circle.fill"
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
