import Foundation

enum UpgradeBranch: String, CaseIterable, Sendable {
    case traits
    case passives

    var title: String { Copy.text("branch.\(rawValue).title") }

    /// One line about the branch for the Archive.
    var summary: String { Copy.text("branch.\(rawValue).summary") }

    var tint: RGB {
        switch self {
        case .traits: RGB(0.35, 0.82, 1.0)
        case .passives: RGB(0.75, 0.42, 1.0)
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

    /// The old shop nodes. Bought ranks are refunded; the tree does not list them.
    var isShown: Bool {
        switch self {
        case .slots, .reserves, .fabricator, .recharge: false
        default: true
        }
    }

    static var shown: [UpgradeKind] { allCases.filter(\.isShown) }

    var branch: UpgradeBranch {
        switch self {
        case .velocity, .sparkSense, .dashCapacitor, .dashImpulse,
             .beamForecast, .echoForecast, .crystalMemory, .rewind: .traits
        case .aegis, .shieldLattice, .fieldAmplifier, .surgeMastery, .cryostasis,
             .magnetism, .phaseResearch, .chronoResearch, .anchorResearch,
             .repulseResearch, .prismResearch, .blinkResearch,
             .slots, .reserves, .fabricator, .recharge: .passives
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
        case .sparkSense: [(.velocity, 1)]
        case .dashCapacitor: [(.velocity, 1)]
        case .dashImpulse: [(.dashCapacitor, 2)]
        case .beamForecast: [(.velocity, 2)]
        case .echoForecast: [(.beamForecast, 1)]
        case .crystalMemory: [(.sparkSense, 1)]
        case .rewind: [(.echoForecast, 1)]
        case .aegis: [(.velocity, 1)]
        case .shieldLattice: [(.aegis, 2)]
        case .fieldAmplifier: [(.aegis, 1)]
        case .surgeMastery: [(.velocity, 2)]
        case .cryostasis: [(.fieldAmplifier, 1)]
        case .magnetism: [(.sparkSense, 1)]
        case .phaseResearch: [(.aegis, 1)]
        case .chronoResearch: [(.echoForecast, 1)]
        case .anchorResearch: [(.cryostasis, 1)]
        case .repulseResearch: [(.magnetism, 1)]
        case .prismResearch: [(.shieldLattice, 1)]
        case .blinkResearch: [(.dashImpulse, 1)]
        case .slots: [(.velocity, 1)]
        case .reserves: [(.slots, 1)]
        case .fabricator: [(.reserves, 2)]
        case .recharge: [(.velocity, 2)]
        }
    }

    func cost(after level: Int) -> Int {
        baseCost + max(0, level) * costStep
    }
}
