import Foundation

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
