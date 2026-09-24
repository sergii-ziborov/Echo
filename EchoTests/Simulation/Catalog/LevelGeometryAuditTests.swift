import XCTest
@testable import Echo

final class LevelGeometryAuditTests: XCTestCase {
    func testEveryAuthoredMapPassesGeometryAudit() {
        let issues = audit(LevelCatalog.playable)
        XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
    }

    func testEveryWristMapPassesGeometryAuditOnTheWatchFace() {
        let fitted = WristCatalog.maps.map { WristCatalog.fitted($0, aspect: 1.07) }
        let issues = audit(WristCatalog.maps + fitted)
        XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
    }

    func audit(_ levels: [LevelDefinition]) -> [String] {
        var issues: [String] = []

        for level in levels {
            let prefix = "Map \(level.number) · \(level.name):"

            checkUnique(level.sparks.map(\.id), label: "spark", prefix: prefix, issues: &issues)
            checkUnique(level.bonuses.map(\.id), label: "bonus", prefix: prefix, issues: &issues)
            checkUnique(level.fields.map(\.id), label: "field", prefix: prefix, issues: &issues)
            checkUnique(level.movers.map(\.id), label: "mover", prefix: prefix, issues: &issues)
            checkUnique(level.rifts.map(\.id), label: "rift", prefix: prefix, issues: &issues)
            checkUnique(level.gates.map(\.id), label: "gate", prefix: prefix, issues: &issues)
            checkUnique(level.lasers.map(\.id), label: "laser", prefix: prefix, issues: &issues)
            checkUnique(level.gravityWells.map(\.id), label: "gravity well", prefix: prefix, issues: &issues)
            checkUnique(level.decorations.map(\.id), label: "decoration", prefix: prefix, issues: &issues)

            for (index, wall) in level.walls.enumerated() {
                checkBox(wall, label: "wall \(index)", level: level, prefix: prefix, issues: &issues)
            }
            for field in level.fields {
                checkBox(field.area, label: "field \(field.id)", level: level, prefix: prefix, issues: &issues)
            }
            for gate in level.gates {
                checkBox(gate.area, label: "gate \(gate.id)", level: level, prefix: prefix, issues: &issues)
            }

            checkPoint(level.playerStart, radius: 24, label: "player start", level: level, prefix: prefix, issues: &issues)
            checkPoint(level.exit, radius: 44, label: "exit", level: level, prefix: prefix, issues: &issues)
            checkWallClear(level.playerStart, radius: 24, label: "player start", level: level, prefix: prefix, issues: &issues)
            checkWallClear(level.exit, radius: 44, label: "exit", level: level, prefix: prefix, issues: &issues)

            for spark in level.sparks {
                checkPoint(spark.position, radius: 22, label: "spark \(spark.id)", level: level, prefix: prefix, issues: &issues)
                checkWallClear(spark.position, radius: 22, label: "spark \(spark.id)", level: level, prefix: prefix, issues: &issues)
                if let orbit = spark.orbit {
                    for sample in orbitSamples(center: orbit.center, orbitRadius: orbit.radius, count: 32) {
                        checkPoint(sample, radius: 22, label: "spark \(spark.id) orbit", level: level, prefix: prefix, issues: &issues)
                        checkWallClear(sample, radius: 22, label: "spark \(spark.id) orbit", level: level, prefix: prefix, issues: &issues)
                    }
                }
            }

            for bonus in level.bonuses {
                checkPoint(bonus.position, radius: 26, label: "bonus \(bonus.id)", level: level, prefix: prefix, issues: &issues)
                checkWallClear(bonus.position, radius: 26, label: "bonus \(bonus.id)", level: level, prefix: prefix, issues: &issues)
            }

            for rift in level.rifts {
                checkPoint(rift.position, radius: rift.radius, label: "rift \(rift.id)", level: level, prefix: prefix, issues: &issues)
                checkWallClear(rift.position, radius: rift.radius, label: "rift \(rift.id)", level: level, prefix: prefix, issues: &issues)
            }

            for well in level.gravityWells {
                checkPoint(well.position, radius: well.coreRadius, label: "gravity well \(well.id)", level: level, prefix: prefix, issues: &issues)
                checkWallClear(well.position, radius: well.coreRadius, label: "gravity well \(well.id)", level: level, prefix: prefix, issues: &issues)
                for spark in level.sparks where spark.position.distance(to: well.position) < 22 + well.coreRadius + 4 {
                    issues.append("\(prefix) spark \(spark.id) intersects gravity well \(well.id)")
                }
                if level.exit.distance(to: well.position) < 44 + well.coreRadius + 4 {
                    issues.append("\(prefix) exit intersects gravity well \(well.id)")
                }
            }

            if level.number >= 37 {
                for rift in level.rifts {
                    for mover in level.movers where mover.position.distance(to: rift.position) < mover.radius + rift.radius + 4 {
                        issues.append("\(prefix) rift \(rift.id) overlaps mover \(mover.id)")
                    }
                    for well in level.gravityWells where well.position.distance(to: rift.position) < well.coreRadius + rift.radius + 4 {
                        issues.append("\(prefix) rift \(rift.id) overlaps gravity well \(well.id)")
                    }
                }
            }

            for mover in level.movers {
                for sample in moverSamples(mover) {
                    checkPoint(sample, radius: mover.radius, label: "mover \(mover.id) route", level: level, prefix: prefix, issues: &issues)
                    checkWallClear(sample, radius: mover.radius, label: "mover \(mover.id) route", level: level, prefix: prefix, issues: &issues)
                }
            }

            for laser in level.lasers {
                guard laser.period > laser.activeFor,
                      laser.chargeFor >= 0,
                      laser.activeFor > 0,
                      laser.beamWidth > 0 else {
                    issues.append("\(prefix) laser \(laser.id) has invalid timing or width")
                    continue
                }
                for point in laserSamples(laser) {
                    checkPoint(point, radius: laser.beamWidth / 2, label: "laser \(laser.id) endpoint", level: level, prefix: prefix, issues: &issues)
                }
            }

            for decoration in level.decorations {
                checkPoint(decoration.position, radius: 0, label: "decoration \(decoration.id)", level: level, prefix: prefix, issues: &issues)
                if case .lane(let end, _) = decoration.kind {
                    checkPoint(end, radius: 0, label: "decoration \(decoration.id) lane end", level: level, prefix: prefix, issues: &issues)
                }
            }

            let routeTargets = level.sparks.map(\.position) + [level.exit]
            if let unreachable = unreachableTargets(in: level, targets: routeTargets), !unreachable.isEmpty {
                issues.append("\(prefix) objectives \(unreachable) are cut off by static walls")
            }
        }

        return issues
    }

    func checkUnique(
        _ ids: [Int],
        label: String,
        prefix: String,
        issues: inout [String]
    ) {
        if Set(ids).count != ids.count {
            issues.append("\(prefix) duplicate \(label) IDs")
        }
    }

    func checkBox(
        _ box: AABB,
        label: String,
        level: LevelDefinition,
        prefix: String,
        issues: inout [String]
    ) {
        guard box.width > 0, box.height > 0,
              box.minX >= 0, box.minY >= 0,
              box.maxX <= level.worldWidth, box.maxY <= level.worldHeight else {
            issues.append("\(prefix) \(label) is invalid or outside the arena")
            return
        }
    }

    func checkPoint(
        _ point: Vec2,
        radius: Double,
        label: String,
        level: LevelDefinition,
        prefix: String,
        issues: inout [String]
    ) {
        let edge = radius + 4
        if point.x < edge || point.y < edge || point.x > level.worldWidth - edge || point.y > level.worldHeight - edge {
            let rounded = "(\(Int(point.x.rounded())), \(Int(point.y.rounded())))"
            let message = "\(prefix) \(label) clips the arena at \(rounded)"
            if !issues.contains(message) { issues.append(message) }
        }
    }

    func checkWallClear(
        _ point: Vec2,
        radius: Double,
        label: String,
        level: LevelDefinition,
        prefix: String,
        issues: inout [String]
    ) {
        guard level.walls.contains(where: { $0.intersectsCircle(center: point, radius: radius + 2) }) else { return }
        let rounded = "(\(Int(point.x.rounded())), \(Int(point.y.rounded())))"
        let message = "\(prefix) \(label) intersects a wall at \(rounded)"
        if !issues.contains(message) { issues.append(message) }
    }

    func orbitSamples(center: Vec2, orbitRadius: Double, count: Int) -> [Vec2] {
        (0..<count).map { index in
            let angle = Double(index) / Double(count) * .pi * 2
            return center + Vec2(x: cos(angle), y: sin(angle)) * orbitRadius
        }
    }

    func moverSamples(_ mover: MoverSpawn) -> [Vec2] {
        switch mover.path {
        case .stationary:
            return [mover.position]
        case .bounce:
            return [mover.position]
        case .patrol(let start, let end):
            return (0...24).map { start.lerp(end, Double($0) / 24) }
        case .orbit(let center, let radius, _, _):
            return orbitSamples(center: center, orbitRadius: radius, count: 48)
        }
    }

    func laserSamples(_ laser: LaserSpawn) -> [Vec2] {
        switch laser.motion {
        case .fixed:
            return [laser.start, laser.end]
        case .sweep(let center, let length, let startAngle, let endAngle, _, _):
            return (0...24).flatMap { index -> [Vec2] in
                let angle = startAngle + (endAngle - startAngle) * Double(index) / 24
                let half = Vec2(x: cos(angle), y: sin(angle)) * (length / 2)
                return [center - half, center + half]
            }
        }
    }

    func unreachableTargets(in level: LevelDefinition, targets: [Vec2]) -> [Int]? {
        let step = 20.0
        let inset = 30.0
        let columns = Int((level.worldWidth - inset * 2) / step) + 1
        let rows = Int((level.worldHeight - inset * 2) / step) + 1
        guard columns > 0, rows > 0 else { return nil }

        func point(_ index: Int) -> Vec2 {
            Vec2(x: inset + Double(index % columns) * step, y: inset + Double(index / columns) * step)
        }
        func clear(_ index: Int) -> Bool {
            LayoutSafety.isClear(point(index), walls: level.walls, clearance: 26)
        }
        func nearestClear(to target: Vec2) -> Int? {
            (0..<(columns * rows))
                .filter(clear)
                .min { point($0).distance(to: target) < point($1).distance(to: target) }
        }

        guard let start = nearestClear(to: level.playerStart) else { return Array(targets.indices) }
        var visited: Set<Int> = [start]
        var queue = [start]
        var head = 0
        let moves = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        while head < queue.count {
            let current = queue[head]
            head += 1
            let x = current % columns
            let y = current / columns
            for move in moves {
                let nx = x + move.0
                let ny = y + move.1
                guard nx >= 0, nx < columns, ny >= 0, ny < rows else { continue }
                let next = ny * columns + nx
                guard !visited.contains(next), clear(next) else { continue }
                visited.insert(next)
                queue.append(next)
            }
        }

        return targets.indices.filter { index in
            guard let targetCell = nearestClear(to: targets[index]) else { return true }
            return !visited.contains(targetCell)
        }
    }
}
