import SwiftUI

enum MechanicDemoScenario: Hashable {
    case echo, asteroid, rift, freeze, phase, collision, gate, laser
    case timeCrystal, resonance, blackHole
    case shield, surge, pulse, magnet, chrono, anchor, repulse, prism, blink

    init(bonus: BonusKind) {
        self = switch bonus {
        case .shield, .ward: .shield
        case .freeze: .freeze
        case .surge: .surge
        case .pulse: .pulse
        case .magnet: .magnet
        case .phase: .phase
        case .chrono: .chrono
        case .anchor: .anchor
        case .repulse: .repulse
        case .prism: .prism
        case .blink: .blink
        }
    }

    init(upgrade: UpgradeKind) {
        self = switch upgrade {
        case .velocity, .surgeMastery: .surge
        case .sparkSense: .resonance
        case .dashCapacitor, .dashImpulse: .blink
        case .slots, .reserves, .fabricator: .shield
        case .aegis, .shieldLattice: .shield
        case .fieldAmplifier: .anchor
        case .recharge, .chronoResearch, .rewind, .echoForecast: .chrono
        case .beamForecast: .laser
        case .cryostasis: .freeze
        case .crystalMemory: .timeCrystal
        case .magnetism: .magnet
        case .phaseResearch: .phase
        case .anchorResearch: .anchor
        case .repulseResearch: .repulse
        case .prismResearch: .prism
        case .blinkResearch: .blink
        }
    }

    init(hint: EncounterHint) {
        self = switch hint {
        case .echo: .echo
        case .asteroid: .asteroid
        case .rift, .realityShift: .rift
        case .freeze: .freeze
        case .phase: .phase
        case .collision: .collision
        case .gate: .gate
        case .laser: .laser
        case .timeCrystal: .timeCrystal
        case .resonance: .resonance
        case .blackHole: .blackHole
        case .surge: .surge
        case .pulse: .pulse
        case .magnet: .magnet
        case .chrono: .chrono
        case .anchor: .anchor
        case .repulse: .repulse
        case .prism: .prism
        case .blink: .blink
        }
    }

    var caption: String {
        switch self {
        case .echo: "YOUR OLD ROUTE REPEATS"
        case .asteroid: "WALL HIT → CRACK → BREAK"
        case .rift: "OPEN RING CHANGES THE RULES"
        case .freeze: "HAZARDS STOP · YOU MOVE"
        case .phase: "CROSS THROUGH DANGER"
        case .collision: "TWO ECHOES LEAVE A SCAR"
        case .gate: "WAIT · THEN CROSS"
        case .laser: "CHARGE → FIRE → MOVE"
        case .timeCrystal: "GOLD BONUS · GRAB FOR FREEZE"
        case .resonance: "FAST SPARKS BUILD A CHAIN"
        case .blackHole: "PULL OUTSIDE · DEATH INSIDE"
        case .shield: "ONE HIT BOUNCES AWAY"
        case .surge: "YOU MOVE FASTER"
        case .pulse: "NEXT ECHO ARRIVES LATER"
        case .magnet: "SPARKS FLY TO YOU"
        case .chrono: "PUSH THE TIMELINE BACK"
        case .anchor: "WORLD SLOWS · YOU DO NOT"
        case .repulse: "CLEAR SPACE AROUND YOU"
        case .prism: "LASERS BEND AROUND YOU"
        case .blink: "JUMP ACROSS ONE DANGER"
        }
    }

    var tint: Color {
        switch self {
        case .asteroid: .orange
        case .laser, .collision, .repulse: EchoTheme.magenta
        case .shield, .magnet: .green
        case .surge, .timeCrystal, .resonance: EchoTheme.gold
        case .phase, .rift, .chrono, .blink: EchoTheme.violet
        default: EchoTheme.cyan
        }
    }
}
