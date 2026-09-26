import Foundation

enum MoverKind: String, Equatable, Sendable {
    case asteroid
}

enum AsteroidMaterial: String, CaseIterable, Equatable, Sendable {
    case basalt
    case ice
    case crystal
    case alloy
    /// A molten body under a thin crust; cracks glow and it bursts into embers.
    case magma
    /// Plain stone outside, lined with crystal inside; it splits quickly.
    case geode
    /// A nickel-iron meteorite: the toughest shell that still breaks.
    case iron
    /// A dusty snowball trailing vapour; the first impact dooms it.
    case comet

    /// The material's display name; `rawValue` stays the internal key.
    var title: String { Copy.text("material.\(rawValue).name") }

    /// One line about the material for the Archive.
    var about: String { Copy.text("material.\(rawValue).about") }

    var shortLabel: String { Copy.text("material.\(rawValue).code") }

    /// Nil means the shell rebounds forever. Brittle shells start an internal
    /// collapse clock on their first wall impact and can also be broken early
    /// by repeated impacts. Cracks and debris convey damage without a timer UI.
    var wallHitsToShatter: Int? {
        switch self {
        case .basalt: 4
        case .ice: 2
        case .crystal: 3
        case .alloy: nil
        case .magma: 3
        case .geode: 2
        case .iron: 6
        case .comet: 1
        }
    }

    var fractureDuration: TimeInterval? {
        switch self {
        case .basalt: 9.0
        case .ice: 5.2
        case .crystal: 7.0
        case .alloy: nil
        case .magma: 6.0
        case .geode: 6.5
        case .iron: 12.0
        case .comet: 4.0
        }
    }

    var isBreakable: Bool { wallHitsToShatter != nil }

    /// Metal shells ring and throw sparks when they hit something.
    var isMetallic: Bool { self == .alloy || self == .iron }

    /// The materials a map may use. The first three acts keep the original
    /// four; DEBRIS brings molten and iron rocks, RIFT geodes and comets.
    static func palette(forLevel number: Int) -> [AsteroidMaterial] {
        switch number {
        case ..<22: [.basalt, .ice, .crystal, .alloy]
        case ..<43: [.basalt, .ice, .magma, .alloy, .crystal, .iron]
        default: [.basalt, .ice, .magma, .alloy, .crystal, .geode, .iron, .comet]
        }
    }
}

enum MoverPath: Equatable, Sendable {
    case stationary
    case bounce
    case patrol(from: Vec2, to: Vec2)
    case orbit(center: Vec2, radius: Double, period: TimeInterval, phase: Double)
}

struct MoverSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var kind: MoverKind = .asteroid
    var material: AsteroidMaterial = .basalt
    var position: Vec2
    var velocity: Vec2 = .zero
    var radius: Double = 42
    var path: MoverPath = .bounce

    static func stationary(
        id: Int,
        at position: Vec2,
        radius: Double = 130,
        material: AsteroidMaterial = .alloy
    ) -> MoverSpawn {
        MoverSpawn(id: id, material: material, position: position, velocity: .zero, radius: radius, path: .stationary)
    }

    static func bounce(
        id: Int,
        at position: Vec2,
        velocity: Vec2,
        radius: Double = 42,
        material: AsteroidMaterial = .basalt
    ) -> MoverSpawn {
        MoverSpawn(id: id, material: material, position: position, velocity: velocity, radius: radius, path: .bounce)
    }

    static func patrol(
        id: Int,
        from: Vec2,
        to: Vec2,
        radius: Double = 40,
        material: AsteroidMaterial = .alloy
    ) -> MoverSpawn {
        MoverSpawn(id: id, material: material, position: from, velocity: .zero, radius: radius, path: .patrol(from: from, to: to))
    }

    static func orbit(
        id: Int,
        center: Vec2,
        radius: Double,
        period: TimeInterval,
        phase: Double = 0,
        size: Double = 40,
        material: AsteroidMaterial = .crystal
    ) -> MoverSpawn {
        let start = Vec2(
            x: center.x + cos(phase) * radius,
            y: center.y + sin(phase) * radius
        )
        return MoverSpawn(
            id: id,
            material: material,
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
        case .stationary:
            copy.path = .stationary
        case .bounce:
            copy.path = .bounce
        case .patrol(let a, let b):
            copy.path = .patrol(from: Vec2(x: a.x, y: a.y * sy), to: Vec2(x: b.x, y: b.y * sy))
        case .orbit(let center, let radius, let period, let phase):
            let scaledCenter = Vec2(x: center.x, y: center.y * sy)
            copy.path = .orbit(
                center: scaledCenter,
                radius: radius,
                period: period,
                phase: phase
            )
            copy.position = Vec2(
                x: scaledCenter.x + cos(phase) * radius,
                y: scaledCenter.y + sin(phase) * radius
            )
        }
        return copy
    }
}

struct MoverState: Equatable, Sendable, Identifiable {
    var id: Int
    var kind: MoverKind
    var material: AsteroidMaterial
    var position: Vec2
    var velocity: Vec2
    var radius: Double
    var path: MoverPath
    var patrolT: Double = 0
    var patrolDir: Double = 1
    var hitsRemaining: Int?
    var fractureRemaining: TimeInterval?
    var impactCooldown: TimeInterval = 0

    var isFracturing: Bool { fractureRemaining != nil }

    var fractureProgress: Double {
        guard let maxHits = material.wallHitsToShatter else { return 0 }
        let hitProgress = 1 - Double(hitsRemaining ?? maxHits) / Double(maxHits)
        guard let duration = material.fractureDuration,
              let remaining = fractureRemaining else { return max(0, hitProgress) }
        let timeProgress = 1 - remaining / max(duration, 0.01)
        return min(1, max(hitProgress, timeProgress))
    }
}
