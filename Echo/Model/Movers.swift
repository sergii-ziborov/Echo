import Foundation

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

enum MoverKind: String, Equatable, Sendable {
    case asteroid
}

enum MoverPath: Equatable, Sendable {
    case bounce
    case patrol(from: Vec2, to: Vec2)
    case orbit(center: Vec2, radius: Double, period: TimeInterval, phase: Double)
}

struct MoverSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var kind: MoverKind = .asteroid
    var position: Vec2
    var velocity: Vec2 = .zero
    var radius: Double = 22
    var path: MoverPath = .bounce

    static func bounce(id: Int, at position: Vec2, velocity: Vec2, radius: Double = 22) -> MoverSpawn {
        MoverSpawn(id: id, position: position, velocity: velocity, radius: radius, path: .bounce)
    }

    static func patrol(id: Int, from: Vec2, to: Vec2, radius: Double = 20) -> MoverSpawn {
        MoverSpawn(id: id, position: from, velocity: .zero, radius: radius, path: .patrol(from: from, to: to))
    }

    static func orbit(id: Int, center: Vec2, radius: Double, period: TimeInterval, phase: Double = 0, size: Double = 20) -> MoverSpawn {
        let start = Vec2(
            x: center.x + cos(phase) * radius,
            y: center.y + sin(phase) * radius
        )
        return MoverSpawn(
            id: id,
            position: start,
            velocity: .zero,
            radius: size,
            path: .orbit(center: center, radius: radius, period: period, phase: phase)
        )
    }

    func scaled(sy: Double) -> MoverSpawn {
        var copy = self
        copy.position = Vec2(x: position.x, y: position.y * sy)
        copy.velocity = Vec2(x: velocity.x, y: velocity.y * sy)
        switch path {
        case .bounce:
            copy.path = .bounce
        case .patrol(let a, let b):
            copy.path = .patrol(from: Vec2(x: a.x, y: a.y * sy), to: Vec2(x: b.x, y: b.y * sy))
        case .orbit(let center, let radius, let period, let phase):
            copy.path = .orbit(
                center: Vec2(x: center.x, y: center.y * sy),
                radius: radius,
                period: period,
                phase: phase
            )
        }
        return copy
    }
}

struct MoverState: Equatable, Sendable, Identifiable {
    var id: Int
    var kind: MoverKind
    var position: Vec2
    var velocity: Vec2
    var radius: Double
    var path: MoverPath
    var patrolT: Double = 0
    var patrolDir: Double = 1
}
