import Foundation

/// Endless arenas. Each depth of a run is a fresh random map drawn from the
/// run's seed and a little harder than the one before. A draft is thrown away
/// unless every spark, bonus and the exit can be reached from the start and
/// no hazard spawns on top of the orb; the same seed and depth always give
/// the same map, so a phone and a watch build it identically.
enum EndlessGenerator {
    static func level(_ key: EndlessKey) -> LevelDefinition {
        let depth = max(1, key.depth)
        for attempt in 0..<32 {
            var rng = SplitMix64(seed: key.seed &+ UInt64(depth) &* 0x9E37_79B9_7F4A_7C15 &+ UInt64(attempt) &* 0xD1B5_4A32_D192_ED03)
            if let level = draft(key, depth: depth, rng: &rng) { return level }
        }
        return fallback(key, depth: depth)
    }

    private static func draft(_ key: EndlessKey, depth: Int, rng: inout SplitMix64) -> LevelDefinition? {
        let pressure = EndlessPressure(depth: depth)
        let walls = EndlessLayouts.walls(depth: depth, rng: &rng)
        func clear(_ point: Vec2, _ clearance: Double) -> Bool {
            LayoutSafety.isClear(point, walls: walls, clearance: clearance)
        }

        let start = Vec2(x: Double.random(in: 160...840, using: &rng), y: 110)
        // High enough to feel like the far end, low enough to clear the phone HUD.
        let exit = Vec2(x: Double.random(in: 160...840, using: &rng), y: 830)
        guard clear(start, 40), clear(exit, 58) else { return nil }

        var taken = [start, exit]
        func spot(clearance: Double, spacing: Double, away: [(Vec2, Double)], rows: ClosedRange<Double> = 150...820) -> Vec2? {
            for _ in 0..<200 {
                let point = Vec2(x: Double.random(in: 90...910, using: &rng), y: Double.random(in: rows, using: &rng))
                guard clear(point, clearance),
                      taken.allSatisfy({ $0.distance(to: point) >= spacing }),
                      away.allSatisfy({ point.distance(to: $0.0) >= $0.1 }) else { continue }
                return point
            }
            return nil
        }

        var sparks: [SparkSpawn] = []
        for index in 0..<pressure.sparks {
            guard let point = spot(clearance: 40, spacing: 130, away: [(start, 170)]) else { return nil }
            taken.append(point)
            let timer: TimeInterval? = index < pressure.timedSparks ? TimeInterval(18 + Int.random(in: 0...8, using: &rng)) : nil
            sparks.append(SparkSpawn(id: index, position: point, timer: timer, orbit: nil))
        }

        var bonuses: [BonusSpawn] = []
        for index in 0..<pressure.bonuses {
            guard let point = spot(clearance: 44, spacing: 120, away: [(start, 150)]) else { break }
            taken.append(point)
            let kinds = pressure.bonusKinds
            bonuses.append(BonusSpawn(id: index, kind: kinds[Int.random(in: 0..<kinds.count, using: &rng)], position: point))
        }

        var movers: [MoverSpawn] = []
        for index in 0..<pressure.rocks {
            let material = pressure.materials[Int.random(in: 0..<pressure.materials.count, using: &rng)]
            let radius = Double.random(in: 26...36, using: &rng)
            let body = ArenaMetrics.readableRockRadius(radius) + 6
            let roll = Int.random(in: 0..<100, using: &rng)
            if roll < 22, let from = spot(clearance: body, spacing: 0, away: [(start, 280), (exit, 160)], rows: 260...800) {
                let length = Double.random(in: 220...400, using: &rng)
                let along = Bool.random(using: &rng) ? Vec2(x: from.x < 500 ? 1 : -1, y: 0) : Vec2(x: 0, y: from.y < 520 ? 1 : -1)
                let to = from + along * length
                if pathIsClear(from: from, to: to, clearance: body, walls: walls), to.distance(to: start) > 260 {
                    movers.append(.patrol(id: index, from: from, to: to, radius: radius, material: material))
                    continue
                }
            }
            if roll < 38, depth >= 3, let center = spot(clearance: 30, spacing: 0, away: [(start, 440), (exit, 300)], rows: 330...700) {
                let ring = Double.random(in: 120...180, using: &rng)
                let inside = (body + ring...(1000 - body - ring)).contains(center.x) && (body + ring...(1000 - body - ring)).contains(center.y)
                let clearRing = inside && (0..<48).allSatisfy { step in
                    let angle = Double(step) / 48 * 2 * .pi
                    return clear(center + Vec2(x: cos(angle), y: sin(angle)) * ring, body)
                }
                if clearRing {
                    movers.append(.orbit(id: index, center: center, radius: ring, period: Double.random(in: 7...10, using: &rng), phase: Double.random(in: 0..<(2 * .pi), using: &rng), size: radius, material: material))
                    continue
                }
            }
            guard let at = spot(clearance: body, spacing: 0, away: [(start, 280), (exit, 150)], rows: 250...820) else { continue }
            let angle = Double.random(in: 0..<(2 * .pi), using: &rng)
            movers.append(.bounce(id: index, at: at, velocity: Vec2(x: cos(angle), y: sin(angle)) * pressure.rockSpeed, radius: radius, material: material))
        }

        var lasers: [LaserSpawn] = []
        for _ in 0..<pressure.lasers {
            let period = Double.random(in: 7...9.2, using: &rng)
            let phase = Double.random(in: 0...period, using: &rng)
            if Bool.random(using: &rng) {
                let y = Double.random(in: 300...700, using: &rng)
                lasers.append(.horizontal(id: lasers.count, y: y, period: period, chargeFor: 1.6, activeFor: 1.25, phase: phase))
            } else {
                let x = Double.random(in: 180...820, using: &rng)
                guard abs(x - start.x) > 90, abs(x - exit.x) > 90 else { continue }
                lasers.append(.vertical(id: lasers.count, x: x, period: period, chargeFor: 1.6, activeFor: 1.25, phase: phase))
            }
        }
        let pivot = Vec2(x: 500, y: 500)
        if depth >= 14, Int.random(in: 0..<10, using: &rng) < 3, clear(pivot, 40) {
            lasers.append(.sweeping(id: lasers.count, center: pivot, length: 820, from: 0, to: .pi, sweepDuration: 5.4, beamWidth: 15, period: 9.4, chargeFor: 1.8, activeFor: 1.2))
        }

        var wells: [GravityWellSpawn] = []
        if depth >= 12, Bool.random(using: &rng), let point = spot(clearance: 80, spacing: 150, away: [(start, 260), (exit, 220)], rows: 320...700) {
            taken.append(point)
            wells.append(GravityWellSpawn(id: 0, position: point, coreRadius: 34, influenceRadius: Double.random(in: 160...200, using: &rng), strength: Double.random(in: 200...260, using: &rng)))
        }

        var rifts: [RiftSpawn] = []
        let hazards = movers.map { ($0.position, ArenaMetrics.readableRockRadius($0.radius) + 60) }
            + wells.map { ($0.position, $0.coreRadius + 60) }
        if depth >= 7, Int.random(in: 0..<10, using: &rng) < 4, let point = spot(clearance: 60, spacing: 150, away: [(start, 200), (exit, 170)] + hazards, rows: 300...740) {
            taken.append(point)
            let kinds: [RiftKind] = depth >= 16 ? [.calm, .warp, .candy] : [.calm, .warp]
            rifts.append(RiftSpawn(id: 0, kind: kinds[Int.random(in: 0..<kinds.count, using: &rng)], position: point, radius: 48, period: 7.2, openFor: 3.0, phase: Double.random(in: 0...3, using: &rng)))
        }

        var fields: [SlowField] = []
        if depth >= 5, Int.random(in: 0..<10, using: &rng) < 3 {
            let x = Double.random(in: 150...680, using: &rng)
            let y = Double.random(in: 300...560, using: &rng)
            fields.append(SlowField(id: 0, area: AABB(x: x, y: y, width: 170, height: 170)))
        }

        var level = LevelCatalog.make(
            number: 1000 + depth,
            name: "Depth \(depth)",
            subtitle: "Deep Time · run \(key.code)",
            playerStart: start,
            exit: exit,
            walls: walls,
            sparks: sparks,
            echoInterval: pressure.echoInterval,
            maxEchoes: pressure.maxEchoes,
            parTime: 26 + Double(sparks.count) * 5 + Double(depth),
            parMoves: 60 + sparks.count * 9,
            playerSpeed: pressure.playerSpeed,
            bonuses: bonuses,
            fields: fields,
            movers: movers,
            rifts: rifts,
            lasers: lasers,
            gravityWells: wells,
            theme: ArenaTheme(rawValue: (depth - 1) % ArenaTheme.allCases.count),
            atmosphere: ArenaAtmosphere.allCases[Int.random(in: 0..<ArenaAtmosphere.allCases.count, using: &rng)]
        )
        level.id = key.levelID
        level = level.withReadableAsteroids().inRegion()
        return EndlessReach.isSolvable(level) ? level : nil
    }

    /// A body of this clearance can travel the straight line from `from` to `to`.
    private static func pathIsClear(from: Vec2, to: Vec2, clearance: Double, walls: [AABB]) -> Bool {
        guard (clearance...(1000 - clearance)).contains(to.x), (200...840).contains(to.y) else { return false }
        let steps = max(2, Int(from.distance(to: to) / 20))
        return (0...steps).allSatisfy { step in
            LayoutSafety.isClear(from.lerp(to, Double(step) / Double(steps)), walls: walls, clearance: clearance)
        }
    }

    /// A plain, always-solvable arena for the rare seed that never drafts well.
    private static func fallback(_ key: EndlessKey, depth: Int) -> LevelDefinition {
        let pressure = EndlessPressure(depth: depth)
        let points = [Vec2(x: 200, y: 260), Vec2(x: 800, y: 260), Vec2(x: 500, y: 540), Vec2(x: 200, y: 760), Vec2(x: 800, y: 760)]
        var level = LevelCatalog.make(
            number: 1000 + depth,
            name: "Depth \(depth)",
            subtitle: "Deep Time · run \(key.code)",
            playerStart: Vec2(x: 500, y: 110),
            exit: Vec2(x: 500, y: 830),
            walls: [
                AABB(x: 200, y: 400, width: 150, height: 50),
                AABB(x: 650, y: 400, width: 150, height: 50),
                AABB(x: 430, y: 640, width: 140, height: 50),
            ],
            sparks: points.enumerated().map { SparkSpawn(id: $0.offset, position: $0.element, timer: nil, orbit: nil) },
            echoInterval: pressure.echoInterval,
            maxEchoes: pressure.maxEchoes,
            parTime: 50,
            parMoves: 90,
            playerSpeed: pressure.playerSpeed,
            movers: [.bounce(id: 0, at: Vec2(x: 500, y: 330), velocity: Vec2(x: pressure.rockSpeed, y: pressure.rockSpeed * 0.6), radius: 30, material: .basalt)],
            theme: ArenaTheme(rawValue: (depth - 1) % ArenaTheme.allCases.count)
        )
        level.id = key.levelID
        return level.withReadableAsteroids().inRegion()
    }
}
