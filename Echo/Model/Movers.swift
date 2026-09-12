import Foundation

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

enum MoverKind: String, Equatable, Sendable {
    case asteroid
}

enum AsteroidMaterial: String, CaseIterable, Equatable, Sendable {
    case basalt
    case ice
    case crystal
    case alloy

    var title: String {
        switch self {
        case .basalt: "Basalt"
        case .ice: "Cryo ice"
        case .crystal: "Chrono crystal"
        case .alloy: "Void alloy"
        }
    }

    var shortLabel: String {
        switch self {
        case .basalt: "BAS"
        case .ice: "ICE"
        case .crystal: "CHR"
        case .alloy: "ALLOY"
        }
    }

    /// Nil means the shell rebounds forever. Brittle shells start a visible
    /// collapse clock on their first wall impact and can also be broken early
    /// by repeated impacts.
    var wallHitsToShatter: Int? {
        switch self {
        case .basalt: 4
        case .ice: 2
        case .crystal: 3
        case .alloy: nil
        }
    }

    var fractureDuration: TimeInterval? {
        switch self {
        case .basalt: 9.0
        case .ice: 5.2
        case .crystal: 7.0
        case .alloy: nil
        }
    }

    var isBreakable: Bool { wallHitsToShatter != nil }
}

enum MoverPath: Equatable, Sendable {
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

struct GravityWellSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var position: Vec2
    var coreRadius: Double = 42
    var influenceRadius: Double = 210
    var strength: Double = 270

    func scaled(sy: Double) -> GravityWellSpawn {
        var copy = self
        copy.position = Vec2(x: position.x, y: position.y * sy)
        return copy
    }
}

struct GravityWellState: Equatable, Sendable, Identifiable {
    var id: Int
    var position: Vec2
    var coreRadius: Double
    var influenceRadius: Double
    var strength: Double
}

enum LaserPhase: Equatable, Sendable {
    case idle
    case charging(Double)
    case firing
}

enum LaserMotion: Equatable, Sendable {
    case fixed
    /// Rotates around `center`, easing back and forth between both angles.
    case sweep(
        center: Vec2,
        length: Double,
        startAngle: Double,
        endAngle: Double,
        duration: TimeInterval,
        phase: TimeInterval
    )
}

struct LaserSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var start: Vec2
    var end: Vec2
    var beamWidth: Double = 18
    var period: TimeInterval = 6
    var chargeFor: TimeInterval = 1.2
    var activeFor: TimeInterval = 1.4
    var phase: TimeInterval = 0
    var motion: LaserMotion = .fixed

    static func horizontal(
        id: Int,
        y: Double,
        fromX: Double = 90,
        toX: Double = 910,
        beamWidth: Double = 18,
        period: TimeInterval = 6,
        chargeFor: TimeInterval = 1.2,
        activeFor: TimeInterval = 1.4,
        phase: TimeInterval = 0
    ) -> LaserSpawn {
        LaserSpawn(
            id: id,
            start: Vec2(x: fromX, y: y),
            end: Vec2(x: toX, y: y),
            beamWidth: beamWidth,
            period: period,
            chargeFor: chargeFor,
            activeFor: activeFor,
            phase: phase
        )
    }

    static func vertical(
        id: Int,
        x: Double,
        fromY: Double = 90,
        toY: Double = 910,
        beamWidth: Double = 18,
        period: TimeInterval = 6,
        chargeFor: TimeInterval = 1.2,
        activeFor: TimeInterval = 1.4,
        phase: TimeInterval = 0
    ) -> LaserSpawn {
        LaserSpawn(
            id: id,
            start: Vec2(x: x, y: fromY),
            end: Vec2(x: x, y: toY),
            beamWidth: beamWidth,
            period: period,
            chargeFor: chargeFor,
            activeFor: activeFor,
            phase: phase
        )
    }

    static func sweeping(
        id: Int,
        center: Vec2,
        length: Double,
        from startAngle: Double,
        to endAngle: Double,
        sweepDuration: TimeInterval,
        beamWidth: Double = 18,
        period: TimeInterval = 6,
        chargeFor: TimeInterval = 1.2,
        activeFor: TimeInterval = 1.4,
        phase: TimeInterval = 0,
        motionPhase: TimeInterval = 0
    ) -> LaserSpawn {
        let direction = Vec2(x: cos(startAngle), y: sin(startAngle))
        let half = direction * (length / 2)
        return LaserSpawn(
            id: id,
            start: center - half,
            end: center + half,
            beamWidth: beamWidth,
            period: period,
            chargeFor: chargeFor,
            activeFor: activeFor,
            phase: phase,
            motion: .sweep(
                center: center,
                length: length,
                startAngle: startAngle,
                endAngle: endAngle,
                duration: sweepDuration,
                phase: motionPhase
            )
        )
    }

    func scaled(sy: Double) -> LaserSpawn {
        var copy = self
        copy.start = Vec2(x: start.x, y: start.y * sy)
        copy.end = Vec2(x: end.x, y: end.y * sy)
        if case .sweep(let center, let length, let startAngle, let endAngle, let duration, let phase) = motion {
            copy.motion = .sweep(
                center: Vec2(x: center.x, y: center.y * sy),
                length: length,
                startAngle: startAngle,
                endAngle: endAngle,
                duration: duration,
                phase: phase
            )
        }
        return copy
    }
}

struct LaserState: Equatable, Sendable, Identifiable {
    var id: Int
    var start: Vec2
    var end: Vec2
    var beamWidth: Double
    var period: TimeInterval
    var chargeFor: TimeInterval
    var activeFor: TimeInterval
    var offset: TimeInterval
    var motion: LaserMotion
    var phase: LaserPhase = .idle

    func phase(at time: TimeInterval, warningBonus: TimeInterval = 0) -> LaserPhase {
        guard period > 0 else { return .idle }
        let raw = (time + offset).truncatingRemainder(dividingBy: period)
        let t = raw < 0 ? raw + period : raw
        let effectiveCharge = min(max(0, period - activeFor), max(0, chargeFor + warningBonus))
        let idleFor = max(0, period - effectiveCharge - activeFor)
        if t < idleFor { return .idle }
        if t < idleFor + effectiveCharge {
            let progress = (t - idleFor) / max(effectiveCharge, 0.001)
            return .charging(min(max(progress, 0), 1))
        }
        return t < idleFor + effectiveCharge + activeFor ? .firing : .idle
    }

    mutating func updateGeometry(at time: TimeInterval) {
        guard case .sweep(
            let center,
            let length,
            let startAngle,
            let endAngle,
            let duration,
            let motionPhase
        ) = motion else { return }

        let leg = max(0.1, duration)
        let cycle = leg * 2
        let raw = (time + motionPhase).truncatingRemainder(dividingBy: cycle)
        let local = raw < 0 ? raw + cycle : raw
        let linear = local <= leg ? local / leg : 2 - local / leg
        let eased = 0.5 - cos(linear * .pi) * 0.5
        let angle = startAngle + (endAngle - startAngle) * eased
        let half = Vec2(x: cos(angle), y: sin(angle)) * (length / 2)
        start = center - half
        end = center + half
    }
}
