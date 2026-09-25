import Foundation

/// Where the orb can actually go, judged the way the map audit judges the
/// handmade campaign: a flood fill over a 20-unit grid of points that keep
/// clear of every wall, from the grid point nearest the start. A target
/// counts as reached when the clear point nearest to it was visited, so a
/// gap only counts if the orb fits through it with room to spare.
struct EndlessReach {
    static let step = 20.0
    static let inset = 30.0
    static let clearance = 26.0

    private let columns: Int
    private let rows: Int
    private let open: [Bool]
    private let visited: [Bool]

    init(level: LevelDefinition) {
        let columns = Int((level.worldWidth - Self.inset * 2) / Self.step) + 1
        let rows = Int((level.worldHeight - Self.inset * 2) / Self.step) + 1
        self.columns = max(0, columns)
        self.rows = max(0, rows)
        let count = self.columns * self.rows
        var open = [Bool](repeating: false, count: count)
        for index in 0..<count {
            open[index] = LayoutSafety.isClear(Self.point(index, columns: self.columns), walls: level.walls, clearance: Self.clearance)
        }
        self.open = open
        var visited = [Bool](repeating: false, count: count)
        if let start = Self.nearestOpen(to: level.playerStart, open: open, columns: self.columns) {
            var queue = [start]
            visited[start] = true
            var head = 0
            while head < queue.count {
                let current = queue[head]
                head += 1
                let x = current % self.columns
                let y = current / self.columns
                for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                    let nx = x + dx
                    let ny = y + dy
                    guard nx >= 0, ny >= 0, nx < self.columns, ny < self.rows else { continue }
                    let next = ny * self.columns + nx
                    if open[next], !visited[next] {
                        visited[next] = true
                        queue.append(next)
                    }
                }
            }
        }
        self.visited = visited
    }

    func reaches(_ target: Vec2) -> Bool {
        guard let cell = Self.nearestOpen(to: target, open: open, columns: columns) else { return false }
        return visited[cell]
    }

    /// Every spark, bonus and the exit can be reached from the start.
    static func isSolvable(_ level: LevelDefinition) -> Bool {
        let reach = EndlessReach(level: level)
        return reach.reaches(level.exit)
            && level.sparks.allSatisfy { reach.reaches($0.orbit?.center ?? $0.position) }
            && level.bonuses.allSatisfy { reach.reaches($0.position) }
    }

    private static func point(_ index: Int, columns: Int) -> Vec2 {
        Vec2(x: inset + Double(index % columns) * step, y: inset + Double(index / columns) * step)
    }

    private static func nearestOpen(to target: Vec2, open: [Bool], columns: Int) -> Int? {
        guard columns > 0 else { return nil }
        var best: Int?
        var bestDistance = Double.infinity
        for index in open.indices where open[index] {
            let distance = point(index, columns: columns).distance(to: target)
            if distance < bestDistance {
                best = index
                bestDistance = distance
            }
        }
        return best
    }
}
