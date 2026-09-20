import Foundation

struct SparkSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var position: Vec2
    var timer: TimeInterval? = nil
    var orbit: SparkOrbit? = nil
}

struct LevelDefinition: Equatable, Sendable, Identifiable {
    var id: String
    var number: Int
    var name: String
    var subtitle: String
    var worldSize: Double
    var worldHeight: Double
    var playerStart: Vec2
    var exit: Vec2
    var walls: [AABB]
    var sparks: [SparkSpawn]
    var bonuses: [BonusSpawn]
    var fields: [SlowField]
    var movers: [MoverSpawn]
    var rifts: [RiftSpawn]
    var gates: [TimeGateSpawn]
    var lasers: [LaserSpawn]
    var gravityWells: [GravityWellSpawn] = []
    var decorations: [ArenaDecoration]
    var theme: ArenaTheme
    var atmosphere: ArenaAtmosphere
    var echoInterval: TimeInterval
    var maxEchoes: Int
    var warningLead: TimeInterval
    var parTime: TimeInterval
    var parMoves: Int
    var playerSpeed: Double
    var locked: Bool

    var sparkCount: Int { sparks.count }
    var worldWidth: Double { worldSize }

    static let worldSize: Double = 1000

    /// Stretch the 1000×1000 layout to the screen aspect so the arena fills the phone.
    func fitted(aspect: Double) -> LevelDefinition {
        let a = min(max(aspect, 1.45), 2.25)
        let height = Self.worldSize * a
        let sy = height / Self.worldSize
        var copy = self
        copy.worldHeight = height
        copy.playerStart = Vec2(x: playerStart.x, y: playerStart.y * sy)
        copy.exit = Vec2(x: exit.x, y: exit.y * sy)
        copy.walls = walls.map {
            AABB(minX: $0.minX, minY: $0.minY * sy, maxX: $0.maxX, maxY: $0.maxY * sy)
        }
        copy.sparks = sparks.map {
            var orbit = $0.orbit
            if var ring = orbit {
                ring.center = Vec2(x: ring.center.x, y: ring.center.y * sy)
                orbit = ring
            }
            return SparkSpawn(
                id: $0.id,
                position: Vec2(x: $0.position.x, y: $0.position.y * sy),
                timer: $0.timer,
                orbit: orbit
            )
        }
        copy.bonuses = bonuses.map {
            BonusSpawn(id: $0.id, kind: $0.kind, position: Vec2(x: $0.position.x, y: $0.position.y * sy))
        }
        copy.fields = fields.map {
            SlowField(
                id: $0.id,
                area: AABB(minX: $0.area.minX, minY: $0.area.minY * sy, maxX: $0.area.maxX, maxY: $0.area.maxY * sy)
            )
        }
        copy.movers = movers.map { $0.scaled(sy: sy) }
        copy.rifts = rifts.map {
            RiftSpawn(
                id: $0.id,
                kind: $0.kind,
                position: Vec2(x: $0.position.x, y: $0.position.y * sy),
                radius: $0.radius,
                period: $0.period,
                openFor: $0.openFor,
                phase: $0.phase
            )
        }
        copy.gates = gates.map {
            TimeGateSpawn(
                id: $0.id,
                area: AABB(minX: $0.area.minX, minY: $0.area.minY * sy, maxX: $0.area.maxX, maxY: $0.area.maxY * sy),
                period: $0.period,
                openFor: $0.openFor,
                phase: $0.phase
            )
        }
        copy.lasers = lasers.map { $0.scaled(sy: sy) }
        copy.gravityWells = gravityWells.map { $0.scaled(sy: sy) }
        copy.decorations = decorations.map { $0.scaled(sy: sy) }
        return copy.sanitized()
    }

    /// Replays the same 77 maps as a harder timeline without invalidating the
    /// authored geometry or the player's records from earlier cycles.
    func difficultyAdjusted(for cycle: Int) -> LevelDefinition {
        guard cycle > 0 else { return self }
        let pressure = Double(cycle)
        let multiplier = DifficultyProfile(cycle: cycle).hazardMultiplier
        var copy = self
        copy.echoInterval = max(3.6, echoInterval * max(0.58, 1 - pressure * 0.055))
        copy.maxEchoes = min(9, maxEchoes + (cycle + 1) / 2)
        copy.warningLead = min(2.4, warningLead + pressure * 0.08)
        copy.parTime = max(12, parTime * max(0.70, 1 - pressure * 0.035))
        copy.movers = movers.map { mover in
            var next = mover
            next.velocity = mover.velocity * multiplier
            if case .orbit(let center, let radius, let period, let phase) = mover.path {
                next.path = .orbit(center: center, radius: radius, period: max(3.8, period / multiplier), phase: phase)
            }
            return next
        }
        copy.lasers = lasers.map { laser in
            var next = laser
            next.period = max(next.chargeFor + next.activeFor + 0.75, laser.period / multiplier)
            next.activeFor = min(2.2, laser.activeFor * (1 + pressure * 0.04))
            return next
        }
        copy.gravityWells = gravityWells.map { well in
            var next = well
            next.strength *= multiplier
            next.influenceRadius = min(290, well.influenceRadius * (1 + pressure * 0.025))
            return next
        }
        return copy
    }

    /// Gives every debris field a deterministic material language without
    /// changing authored routes. The palette rotates between maps so players
    /// cannot assume that every moving body will eventually disappear.
    func assigningAsteroidMaterials() -> LevelDefinition {
        let palette: [AsteroidMaterial] = [.basalt, .ice, .crystal, .alloy]
        var copy = self
        copy.movers = movers.map { mover in
            var next = mover
            if case .stationary = mover.path {
                next.material = .alloy
                return next
            }
            let index = abs(number * 5 + mover.id * 3) % palette.count
            next.material = palette[index]
            return next
        }
        return copy
    }

    /// Push sparks, the exit, and the start out of walls so pickups are always reachable.
    func sanitized(clearance: Double = 34) -> LevelDefinition {
        var copy = self
        copy.playerStart = LayoutSafety.nudge(playerStart, walls: walls, worldWidth: worldWidth, worldHeight: worldHeight, clearance: clearance)
        copy.exit = LayoutSafety.nudge(exit, walls: walls, worldWidth: worldWidth, worldHeight: worldHeight, clearance: clearance + 14)
        copy.sparks = sparks.map { spark in
            var next = spark
            if var ring = spark.orbit {
                ring.center = LayoutSafety.nudge(
                    ring.center,
                    walls: walls,
                    worldWidth: worldWidth,
                    worldHeight: worldHeight,
                    clearance: clearance + ring.radius
                )
                next.orbit = ring
                next.position = ring.center
            } else {
                next.position = LayoutSafety.nudge(
                    spark.position,
                    walls: walls,
                    worldWidth: worldWidth,
                    worldHeight: worldHeight,
                    clearance: clearance
                )
            }
            return next
        }
        copy.bonuses = bonuses.map { bonus in
            var next = bonus
            next.position = LayoutSafety.nudge(
                bonus.position,
                walls: walls,
                worldWidth: worldWidth,
                worldHeight: worldHeight,
                clearance: clearance
            )
            return next
        }
        copy.movers = movers.map { mover in
            var next = mover
            if case .bounce = mover.path {
                next.position = LayoutSafety.nudge(
                    mover.position,
                    walls: walls,
                    worldWidth: worldWidth,
                    worldHeight: worldHeight,
                    clearance: mover.radius + 4
                )
            }
            return next
        }
        copy.rifts = rifts.map { rift in
            var next = rift
            next.position = LayoutSafety.nudge(
                rift.position,
                walls: walls,
                worldWidth: worldWidth,
                worldHeight: worldHeight,
                clearance: rift.radius + 4
            )
            return next
        }
        copy.gravityWells = gravityWells.map { well in
            var next = well
            next.position = LayoutSafety.nudge(
                well.position,
                walls: walls,
                worldWidth: worldWidth,
                worldHeight: worldHeight,
                clearance: well.coreRadius + 4
            )
            return next
        }
        return copy
    }
}

enum LayoutSafety {
    static func nudge(
        _ point: Vec2,
        walls: [AABB],
        worldWidth: Double,
        worldHeight: Double,
        clearance: Double
    ) -> Vec2 {
        var p = point.clamped(
            minX: clearance + 24,
            minY: clearance + 24,
            maxX: worldWidth - clearance - 24,
            maxY: worldHeight - clearance - 24
        )
        for _ in 0..<8 {
            var moved = false
            for wall in walls {
                let box = wall.expanded(clearance)
                if box.intersectsCircle(center: p, radius: 1) {
                    p = CircleMath.resolve(center: p, radius: clearance, box: wall)
                    p = p.clamped(
                        minX: clearance + 24,
                        minY: clearance + 24,
                        maxX: worldWidth - clearance - 24,
                        maxY: worldHeight - clearance - 24
                    )
                    moved = true
                }
            }
            if !moved { break }
        }
        return p
    }

    static func isClear(
        _ point: Vec2,
        walls: [AABB],
        clearance: Double
    ) -> Bool {
        walls.allSatisfy { !$0.expanded(clearance).intersectsCircle(center: point, radius: 1) }
    }
}

