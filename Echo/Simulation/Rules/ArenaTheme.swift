import Foundation

enum ArenaMetrics {
    static let satelliteRadius: Double = 34
    /// The orb's own collision circle is 24, so a moving rock smaller than this
    /// reads as a speck beside it on a phone.
    static let minimumRockRadius: Double = 33
    /// Authored radii are grown by this much: first a fifth for readability,
    /// then another tenth so rocks hold their own beside the enlarged orb.
    static let rockGrowth: Double = 1.32

    static func readableRockRadius(_ authored: Double) -> Double {
        max(minimumRockRadius, (authored * rockGrowth).rounded())
    }

    /// The growth before the latest tenth, kept for the few rocks whose spawn
    /// has no room for the full size next to a rift or a black hole.
    static func formerRockRadius(_ authored: Double) -> Double {
        max(30, (authored * 1.2).rounded())
    }
}

enum ArenaAtmosphere: String, Equatable, Sendable, CaseIterable {
    case clear
    case drift
    case nebula

    static func forLevel(_ number: Int) -> ArenaAtmosphere {
        switch max(1, number) % 4 {
        case 0: .nebula
        case 2: .drift
        default: .clear
        }
    }
}

enum ArenaDecorationTone: String, Equatable, Sendable {
    case theme
    case cyan
    case violet
    case gold
    case danger
}

enum ArenaDecorationKind: Equatable, Sendable {
    /// A low, architectural floor plate used as a visual landmark.
    case anchor(radius: Double)
    /// Concentric rings and spokes that make a destination feel like a machine.
    case reactor(radius: Double, spokes: Int)
    /// A directional floor trace. It is intentionally non-solid and never blocks the player.
    case lane(to: Vec2, chevrons: Int)
    /// Broken warning arcs around a dangerous or high-traffic point.
    case hazardRing(radius: Double, segments: Int)
}

struct ArenaDecoration: Equatable, Sendable, Identifiable {
    var id: Int
    var kind: ArenaDecorationKind
    var position: Vec2
    var tone: ArenaDecorationTone = .theme
    var rotation: Double = 0

    func scaled(sy: Double) -> ArenaDecoration {
        var copy = self
        copy.position = Vec2(x: position.x, y: position.y * sy)
        if case .lane(let end, let chevrons) = kind {
            copy.kind = .lane(to: Vec2(x: end.x, y: end.y * sy), chevrons: chevrons)
        }
        return copy
    }
}

enum ArenaTheme: Int, Equatable, Sendable, CaseIterable {
    case void
    case ember
    case moss
    case ion
    case ice
    case dust

    static func forLevel(_ number: Int) -> ArenaTheme {
        ArenaTheme(rawValue: (max(1, number) - 1) % allCases.count) ?? .void
    }

    var sky: RGB {
        switch self {
        case .void: RGB(0.015, 0.04, 0.11)
        case .ember: RGB(0.08, 0.02, 0.03)
        case .moss: RGB(0.02, 0.07, 0.06)
        case .ion: RGB(0.05, 0.02, 0.10)
        case .ice: RGB(0.03, 0.06, 0.12)
        case .dust: RGB(0.07, 0.05, 0.02)
        }
    }

    var wallFill: RGB {
        switch self {
        case .void: RGB(0.07, 0.14, 0.30)
        case .ember: RGB(0.28, 0.08, 0.07)
        case .moss: RGB(0.05, 0.20, 0.16)
        case .ion: RGB(0.16, 0.06, 0.28)
        case .ice: RGB(0.08, 0.16, 0.28)
        case .dust: RGB(0.24, 0.16, 0.07)
        }
    }

    var wallStroke: RGB {
        switch self {
        case .void: RGB(0.40, 0.75, 1.00)
        case .ember: RGB(1.00, 0.45, 0.28)
        case .moss: RGB(0.35, 0.95, 0.70)
        case .ion: RGB(0.85, 0.45, 1.00)
        case .ice: RGB(0.55, 0.85, 1.00)
        case .dust: RGB(1.00, 0.78, 0.35)
        }
    }

    var nebula: RGB { wallStroke }
}

struct RGB: Equatable, Sendable {
    var r: Double
    var g: Double
    var b: Double
    init(_ r: Double, _ g: Double, _ b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }
}
