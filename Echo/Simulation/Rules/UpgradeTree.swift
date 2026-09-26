import Foundation

enum UpgradeBranch: String, CaseIterable, Sendable {
    case motion
    case loadout
    case temporal

    var title: String { Copy.text("branch.\(rawValue).title") }

    /// One line about the branch for the Archive.
    var summary: String { Copy.text("branch.\(rawValue).summary") }

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

    /// The research node's name; `rawValue` stays the save key.
    var title: String { Copy.text("upgrade.\(rawValue).name") }

    /// What the node changes. The current and next values come from the
    /// same formulas the run uses, shown in the Lab.
    var detail: String { Copy.text("upgrade.\(rawValue).effect") }

    var useCase: String { Copy.text("upgrade.\(rawValue).best") }

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
