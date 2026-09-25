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

    /// Stretch the square layout to the screen aspect so the arena fills the
    /// display. Phones use the tall default range; the watch is nearly square.
    func fitted(aspect: Double, range: ClosedRange<Double> = 1.45...2.25) -> LevelDefinition {
        let a = min(max(aspect, range.lowerBound), range.upperBound)
        let height = worldSize * a
        let sy = height / max(worldHeight, 1)
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
        let palette = AsteroidMaterial.palette(forLevel: number)
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

    /// Moving rocks were authored small enough to vanish next to the orb. Grow
    /// every moving body before fitting and sanitizing, so the collision circle,
    /// the drawn silhouette and the wall nudges all use the same radius. Fixed
    /// cores keep their authored size; a larger ricochet spawn is pushed clear
    /// of the wall it would now overlap.
    func withReadableAsteroids() -> LevelDefinition {
        var copy = self
        copy.movers = movers.map { mover in
            guard mover.path != .stationary else { return mover }
            // The full growth first; if the bigger rock would spawn on a rift
            // or a black hole, the earlier, smaller growth that fits.
            var next = mover
            for grown in [ArenaMetrics.readableRockRadius(mover.radius), ArenaMetrics.formerRockRadius(mover.radius)] {
                next = mover
                // A patrol or orbit grows only as far as its route stays off the walls.
                next.radius = min(grown, max(mover.radius, routeAllowance(for: mover)))
                if case .bounce = mover.path {
                    next.position = LayoutSafety.clearSpot(
                        near: mover.position,
                        walls: walls,
                        worldWidth: worldWidth,
                        worldHeight: worldHeight,
                        clearance: next.radius + 4
                    )
                }
                if hazardRoom(at: next.position) >= next.radius { break }
            }
            return next
        }
        return copy
    }

    /// How large a body at `point` can be before it touches a rift or a black hole.
    func hazardRoom(at point: Vec2) -> Double {
        let rifts = rifts.map { point.distance(to: $0.position) - $0.radius - 5 }
        let wells = gravityWells.map { point.distance(to: $0.position) - $0.coreRadius - 5 }
        return (rifts + wells).min() ?? .infinity
    }

    /// The largest body that can follow a fixed route without touching a wall
    /// or the arena edge, and that starts clear of rifts and black holes.
    func routeAllowance(for mover: MoverSpawn) -> Double {
        var limit = hazardRoom(at: mover.position)
        let samples: [Vec2]
        switch mover.path {
        case .patrol(let start, let end):
            samples = (0...24).map { start.lerp(end, Double($0) / 24) }
        case .orbit(let center, let radius, _, _):
            samples = (0..<48).map { index in
                let angle = Double(index) / 48 * .pi * 2
                return center + Vec2(x: cos(angle), y: sin(angle)) * radius
            }
        case .bounce, .stationary:
            return limit
        }
        for point in samples {
            limit = min(limit, point.x - 5, point.y - 5, worldWidth - 5 - point.x, worldHeight - 5 - point.y)
            for wall in walls {
                limit = min(limit, point.distance(to: wall.closestPoint(to: point)) - 3)
            }
        }
        return limit
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

    /// `nudge` resolves one wall at a time, so a gap narrower than the body can
    /// pin the point between two walls. Then search outward for the nearest
    /// spot that really has the requested clearance.
    static func clearSpot(
        near point: Vec2,
        walls: [AABB],
        worldWidth: Double,
        worldHeight: Double,
        clearance: Double
    ) -> Vec2 {
        let nudged = nudge(point, walls: walls, worldWidth: worldWidth, worldHeight: worldHeight, clearance: clearance)
        // A resolved point sits exactly on the clearance boundary; allow that.
        if isClear(nudged, walls: walls, clearance: clearance - 2) { return nudged }
        let inset = clearance + 24
        for ring in 1...32 {
            let distance = Double(ring) * 8
            for step in 0..<24 {
                let angle = Double(step) / 24 * .pi * 2
                let candidate = Vec2(x: point.x + cos(angle) * distance, y: point.y + sin(angle) * distance)
                guard candidate.x >= inset, candidate.y >= inset,
                      candidate.x <= worldWidth - inset, candidate.y <= worldHeight - inset,
                      isClear(candidate, walls: walls, clearance: clearance) else { continue }
                return candidate
            }
        }
        return nudged
    }
}

