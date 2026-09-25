import Foundation

/// Wall kits for endless arenas, laid out in the square 1000-unit space the
/// campaign is authored in (y grows upward). Most kits are mirrored left to
/// right like the handmade maps, and all keep to the middle band so the start
/// along the bottom and the exit along the top stay open.
enum EndlessLayouts {
    static let band: ClosedRange<Double> = 230...780

    static func walls(depth: Int, rng: inout SplitMix64) -> [AABB] {
        var walls: [AABB]
        switch Int.random(in: 0..<6, using: &rng) {
        case 0: walls = pillars(rng: &rng)
        case 1: walls = zigzag(rng: &rng)
        case 2: walls = brokenRing(rng: &rng)
        case 3: walls = scatter(rng: &rng)
        case 4: walls = lanes(rng: &rng)
        default: walls = chambers(rng: &rng)
        }
        // Later depths add a few loose blocks to break up the long lines.
        let crates = min(3, depth / 5)
        for _ in 0..<crates {
            let side = Double.random(in: 38...56, using: &rng)
            let x = Double.random(in: 140...(860 - side), using: &rng)
            let y = Double.random(in: band.lowerBound...(band.upperBound - side), using: &rng)
            walls.append(AABB(x: x, y: y, width: side, height: side))
        }
        return walls
    }

    private static func mirrored(_ box: AABB) -> [AABB] {
        let twin = AABB(minX: 1000 - box.maxX, minY: box.minY, maxX: 1000 - box.minX, maxY: box.maxY)
        return abs(twin.minX - box.minX) < 1 ? [box] : [box, twin]
    }

    /// Pairs of blocks either side of a clear centre line.
    private static func pillars(rng: inout SplitMix64) -> [AABB] {
        let rows = Int.random(in: 2...3, using: &rng)
        var walls: [AABB] = []
        for row in 0..<rows {
            let y = band.lowerBound + (band.upperBound - band.lowerBound - 60) * Double(row) / Double(max(1, rows - 1)) + Double.random(in: -20...20, using: &rng)
            let width = Double.random(in: 70...150, using: &rng)
            let height = Double.random(in: 42...64, using: &rng)
            let x = Double.random(in: 150...(390 - width), using: &rng)
            walls += mirrored(AABB(x: x, y: y, width: width, height: height))
        }
        if Bool.random(using: &rng) {
            walls.append(AABB(x: 455, y: 480, width: 90, height: 44))
        }
        return walls
    }

    /// Bars reaching in from alternate sides, so the route snakes upward.
    private static func zigzag(rng: inout SplitMix64) -> [AABB] {
        let bars = Int.random(in: 2...3, using: &rng)
        var fromLeft = Bool.random(using: &rng)
        var walls: [AABB] = []
        for bar in 0..<bars {
            let y = band.lowerBound + 40 + (band.upperBound - band.lowerBound - 120) * Double(bar) / Double(max(1, bars - 1))
            let reach = Double.random(in: 560...680, using: &rng)
            walls.append(fromLeft
                ? AABB(x: 70, y: y, width: reach - 70, height: 46)
                : AABB(x: 1000 - reach, y: y, width: reach - 70, height: 46))
            fromLeft.toggle()
        }
        return walls
    }

    /// Four corner brackets around the middle, open at the sides and poles.
    private static func brokenRing(rng: inout SplitMix64) -> [AABB] {
        let reach = Double.random(in: 210...270, using: &rng)
        let arm = Double.random(in: 110...150, using: &rng)
        let thick = 44.0
        var walls: [AABB] = []
        for (sx, sy) in [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)] {
            let cornerX = 500 + sx * reach
            let cornerY = 505 + sy * reach * 0.9
            let horizontal = AABB(
                minX: min(cornerX, cornerX - sx * arm), minY: cornerY - thick / 2,
                maxX: max(cornerX, cornerX - sx * arm), maxY: cornerY + thick / 2
            )
            let vertical = AABB(
                minX: cornerX - thick / 2, minY: min(cornerY, cornerY - sy * arm),
                maxX: cornerX + thick / 2, maxY: max(cornerY, cornerY - sy * arm)
            )
            walls += [horizontal, vertical]
        }
        return walls
    }

    /// A handful of blocks on the left half, mirrored to the right.
    private static func scatter(rng: inout SplitMix64) -> [AABB] {
        var walls: [AABB] = []
        for _ in 0..<Int.random(in: 3...4, using: &rng) {
            let width = Double.random(in: 50...170, using: &rng)
            let height = Double.random(in: 44...120, using: &rng)
            let x = Double.random(in: 100...(430 - width), using: &rng)
            let y = Double.random(in: band.lowerBound...(band.upperBound - height), using: &rng)
            walls += mirrored(AABB(x: x, y: y, width: width, height: height))
        }
        return walls
    }

    /// Two long uprights with doorways at different heights.
    private static func lanes(rng: inout SplitMix64) -> [AABB] {
        var walls: [AABB] = []
        for x in [Double.random(in: 290...350, using: &rng), Double.random(in: 650...710, using: &rng)] {
            let door = Double.random(in: (band.lowerBound + 40)...(band.upperBound - 220), using: &rng)
            let height = Double.random(in: 170...220, using: &rng)
            if door > band.lowerBound + 20 {
                walls.append(AABB(minX: x - 22, minY: band.lowerBound, maxX: x + 22, maxY: door))
            }
            if door + height < band.upperBound - 20 {
                walls.append(AABB(minX: x - 22, minY: door + height, maxX: x + 22, maxY: band.upperBound))
            }
        }
        return walls
    }

    /// A cross through the middle with a gap in every arm.
    private static func chambers(rng: inout SplitMix64) -> [AABB] {
        let gap = Double.random(in: 130...170, using: &rng)
        let thick = 44.0
        let middle = 500.0
        let span = Double.random(in: 300...380, using: &rng)
        return [
            AABB(minX: middle - span, minY: middle - thick / 2, maxX: middle - gap / 2, maxY: middle + thick / 2),
            AABB(minX: middle + gap / 2, minY: middle - thick / 2, maxX: middle + span, maxY: middle + thick / 2),
            AABB(minX: middle - thick / 2, minY: middle - span * 0.7, maxX: middle + thick / 2, maxY: middle - gap / 2),
            AABB(minX: middle - thick / 2, minY: middle + gap / 2, maxX: middle + thick / 2, maxY: middle + span * 0.7),
        ]
    }
}
