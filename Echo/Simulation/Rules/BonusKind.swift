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

    var fieldLabel: String {
        switch self {
        case .surge: "SPEED"
        case .pulse: "DELAY"
        case .chrono: "SHIFT"
        case .anchor: "SLOW"
        case .repulse: "BLAST"
        default: title.uppercased()
        }
    }

    var detail: String {
        switch self {
        case .shield: "Block the next collision."
        case .freeze: "Stop every hazard; you keep moving."
        case .surge: "Move much faster for a few seconds."
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
        case .surge: "hare.fill"
        case .pulse: "clock.badge.plus"
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
