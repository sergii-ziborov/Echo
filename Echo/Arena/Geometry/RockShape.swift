import CoreGraphics
import Foundation

/// A procedurally generated asteroid in its own local space: points, y up,
/// origin on the collision centre. One outline drives the painted texture, the
/// fault lines that crack open while the rock fractures, and the shards it
/// finally splits into, so the debris that flies apart is the rock the player
/// was dodging. The outline encloses the same area as the collision circle.
struct RockShape {
    var radius: CGFloat
    var outline: [CGPoint]
    /// Every fault runs from `origin` to the outline, in counter-clockwise order.
    var origin: CGPoint
    var faults: [[CGPoint]]
    /// Closed counter-clockwise polygons between neighbouring faults.
    var shards: [[CGPoint]]

    init(material: AsteroidMaterial, radius: CGFloat, seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        let style = Style(material)
        self.radius = radius
        outline = Self.outline(style: style, radius: radius, rng: &rng)
        origin = CGPoint(
            x: radius * CGFloat.random(in: -0.12...0.12, using: &rng),
            y: radius * CGFloat.random(in: -0.12...0.12, using: &rng)
        )
        let count = Int.random(in: style.faults, using: &rng)
        let turn = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
        var faults: [[CGPoint]] = []
        var hits: [(edge: Int, along: CGFloat)] = []
        for index in 0..<count {
            let slot = (CGFloat(index) + CGFloat.random(in: -0.26...0.26, using: &rng)) / CGFloat(count)
            let angle = turn + slot * 2 * .pi
            guard let hit = Self.cast(from: origin, angle: angle, outline: outline) else { continue }
            faults.append(Self.fault(from: origin, to: hit.point, rng: &rng))
            hits.append((hit.edge, hit.along))
        }
        self.faults = faults
        guard faults.count > 1 else {
            shards = [outline]
            return
        }
        var shards: [[CGPoint]] = []
        for index in faults.indices {
            let next = (index + 1) % faults.count
            var polygon = faults[index]
            polygon += Self.arc(of: outline, from: hits[index], to: hits[next])
            polygon += faults[next].dropFirst().reversed()
            shards.append(polygon)
        }
        self.shards = shards
    }

    struct Style {
        var corners: ClosedRange<Int>
        var lumps: CGFloat
        var bumps: CGFloat
        var jitter: CGFloat
        var smoothing: Int
        /// Grit added after smoothing so a rounded rock still has a rough edge.
        var grit: CGFloat
        var faults: ClosedRange<Int>

        init(_ material: AsteroidMaterial) {
            switch material {
            case .basalt:
                self = Style(corners: 11...15, lumps: 0.11, bumps: 0.06, jitter: 0.05, smoothing: 2, grit: 0.03, faults: 5...7)
            case .ice:
                self = Style(corners: 8...11, lumps: 0.08, bumps: 0.05, jitter: 0.07, smoothing: 0, grit: 0, faults: 4...6)
            case .crystal:
                self = Style(corners: 6...9, lumps: 0.08, bumps: 0.07, jitter: 0.09, smoothing: 0, grit: 0, faults: 5...7)
            case .alloy:
                self = Style(corners: 15...18, lumps: 0.05, bumps: 0.025, jitter: 0.02, smoothing: 2, grit: 0.006, faults: 5...6)
            }
        }

        init(corners: ClosedRange<Int>, lumps: CGFloat, bumps: CGFloat, jitter: CGFloat, smoothing: Int, grit: CGFloat, faults: ClosedRange<Int>) {
            self.corners = corners
            self.lumps = lumps
            self.bumps = bumps
            self.jitter = jitter
            self.smoothing = smoothing
            self.grit = grit
            self.faults = faults
        }
    }

    // MARK: - Outline

    static func outline(style: Style, radius: CGFloat, rng: inout SplitMix64) -> [CGPoint] {
        let count = Int.random(in: style.corners, using: &rng)
        let phases = (0..<3).map { _ in CGFloat.random(in: 0..<(2 * .pi), using: &rng) }
        let low = style.lumps * CGFloat.random(in: 0.45...1, using: &rng)
        let third = style.lumps * CGFloat.random(in: 0.2...0.8, using: &rng)
        let bump = style.bumps * CGFloat.random(in: 0.5...1, using: &rng)
        let bumpFrequency = CGFloat(Int.random(in: 4...7, using: &rng))
        var points: [CGPoint] = (0..<count).map { index in
            let angle = (CGFloat(index) + CGFloat.random(in: -0.3...0.3, using: &rng)) / CGFloat(count) * 2 * .pi
            let wave = low * cos(2 * angle + phases[0])
                + third * cos(3 * angle + phases[1])
                + bump * cos(bumpFrequency * angle + phases[2])
            let reach = 1 + wave + CGFloat.random(in: -style.jitter...style.jitter, using: &rng)
            return CGPoint(x: cos(angle) * reach, y: sin(angle) * reach)
        }
        for _ in 0..<style.smoothing {
            points = chaikin(points)
        }
        if style.grit > 0 {
            points = points.map { point in
                let scale = 1 + CGFloat.random(in: -style.grit...style.grit, using: &rng)
                return CGPoint(x: point.x * scale, y: point.y * scale)
            }
        }
        // Scale to the collision circle's area, then keep every point within a
        // readable band around it so no spike or dent lies about the hitbox.
        // The second pass restores the area the clamp shaved off.
        for _ in 0..<2 {
            let fit = radius / sqrt(max(area(points), 0.0001) / .pi)
            points = points.map { point in
                let scaled = CGPoint(x: point.x * fit, y: point.y * fit)
                let length = max(hypot(scaled.x, scaled.y), 0.0001)
                let clamped = min(max(length, radius * 0.84), radius * 1.16)
                return CGPoint(x: scaled.x / length * clamped, y: scaled.y / length * clamped)
            }
        }
        return points
    }

    static func chaikin(_ points: [CGPoint]) -> [CGPoint] {
        points.indices.flatMap { index -> [CGPoint] in
            let a = points[index]
            let b = points[(index + 1) % points.count]
            return [
                CGPoint(x: a.x * 0.75 + b.x * 0.25, y: a.y * 0.75 + b.y * 0.25),
                CGPoint(x: a.x * 0.25 + b.x * 0.75, y: a.y * 0.25 + b.y * 0.75),
            ]
        }
    }

    // MARK: - Faults and shards

    static func cast(from origin: CGPoint, angle: CGFloat, outline: [CGPoint]) -> (point: CGPoint, edge: Int, along: CGFloat)? {
        let direction = CGVector(dx: cos(angle), dy: sin(angle))
        var best: (point: CGPoint, edge: Int, along: CGFloat, distance: CGFloat)?
        for edge in outline.indices {
            let a = outline[edge]
            let b = outline[(edge + 1) % outline.count]
            let side = CGVector(dx: b.x - a.x, dy: b.y - a.y)
            let denominator = direction.dx * side.dy - direction.dy * side.dx
            guard abs(denominator) > 0.000_001 else { continue }
            let offset = CGVector(dx: a.x - origin.x, dy: a.y - origin.y)
            let distance = (offset.dx * side.dy - offset.dy * side.dx) / denominator
            let along = (offset.dx * direction.dy - offset.dy * direction.dx) / denominator
            guard distance > 0, along >= 0, along <= 1 else { continue }
            if best == nil || distance < best!.distance {
                let point = CGPoint(x: a.x + side.dx * along, y: a.y + side.dy * along)
                best = (point, edge, along, distance)
            }
        }
        return best.map { ($0.point, $0.edge, $0.along) }
    }

    /// A jagged seam. Kinks stay small near the origin so neighbouring faults
    /// cannot cross and every shard stays a simple polygon.
    static func fault(from origin: CGPoint, to hit: CGPoint, rng: inout SplitMix64) -> [CGPoint] {
        let dx = hit.x - origin.x
        let dy = hit.y - origin.y
        let length = hypot(dx, dy)
        guard length > 0.0001 else { return [origin, hit] }
        let normal = CGVector(dx: -dy / length, dy: dx / length)
        var points = [origin]
        for step in [0.3, 0.62, 0.84] as [CGFloat] {
            let kink = CGFloat.random(in: -1...1, using: &rng) * 0.11 * step * length
            points.append(CGPoint(
                x: origin.x + dx * step + normal.dx * kink,
                y: origin.y + dy * step + normal.dy * kink
            ))
        }
        points.append(hit)
        return points
    }

    static func arc(
        of outline: [CGPoint],
        from start: (edge: Int, along: CGFloat),
        to end: (edge: Int, along: CGFloat)
    ) -> [CGPoint] {
        guard start.edge != end.edge || end.along < start.along else { return [] }
        var points: [CGPoint] = []
        var vertex = (start.edge + 1) % outline.count
        while true {
            points.append(outline[vertex])
            if vertex == end.edge { break }
            vertex = (vertex + 1) % outline.count
        }
        return points
    }

    // MARK: - Polygon helpers

    static func area(_ polygon: [CGPoint]) -> CGFloat {
        guard polygon.count > 2 else { return 0 }
        var sum: CGFloat = 0
        for index in polygon.indices {
            let a = polygon[index]
            let b = polygon[(index + 1) % polygon.count]
            sum += a.x * b.y - b.x * a.y
        }
        return sum / 2
    }

    static func centroid(_ polygon: [CGPoint]) -> CGPoint {
        let signed = area(polygon)
        guard abs(signed) > 0.0001 else {
            let count = CGFloat(max(polygon.count, 1))
            return CGPoint(
                x: polygon.reduce(0) { $0 + $1.x } / count,
                y: polygon.reduce(0) { $0 + $1.y } / count
            )
        }
        var x: CGFloat = 0
        var y: CGFloat = 0
        for index in polygon.indices {
            let a = polygon[index]
            let b = polygon[(index + 1) % polygon.count]
            let cross = a.x * b.y - b.x * a.y
            x += (a.x + b.x) * cross
            y += (a.y + b.y) * cross
        }
        return CGPoint(x: x / (6 * signed), y: y / (6 * signed))
    }

    /// Counter-clockwise convex hull, thinned to at most `limit` corners so it
    /// fits a physics polygon.
    static func hull(_ points: [CGPoint], limit: Int = 8) -> [CGPoint] {
        let sorted = points.sorted { $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x }
        guard sorted.count > 2 else { return sorted }
        func turn(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        }
        var lower: [CGPoint] = []
        for point in sorted {
            while lower.count >= 2, turn(lower[lower.count - 2], lower[lower.count - 1], point) <= 0 {
                lower.removeLast()
            }
            lower.append(point)
        }
        var upper: [CGPoint] = []
        for point in sorted.reversed() {
            while upper.count >= 2, turn(upper[upper.count - 2], upper[upper.count - 1], point) <= 0 {
                upper.removeLast()
            }
            upper.append(point)
        }
        let hull = Array(lower.dropLast() + upper.dropLast())
        guard hull.count > limit else { return hull }
        return (0..<limit).map { hull[$0 * hull.count / limit] }
    }
}
