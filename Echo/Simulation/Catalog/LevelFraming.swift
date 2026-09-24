import Foundation

/// What the phone interface covers once a level fills the screen: the HUD
/// across the top edge and the item bar along the bottom. All values are
/// world units of the fitted level.
struct InterfaceBands: Equatable, Sendable {
    /// Distance from the top edge a token centre must keep so the token and
    /// the caption drawn above it stay below the HUD.
    var top: Double
    /// Distance from the bottom edge a token centre must keep so the token
    /// stays above the item bar.
    var bottom: Double
    /// Room a token needs around its centre.
    var token: Double
}

extension LevelDefinition {
    /// Ability tokens are big enough that one parked under the HUD or the
    /// item bar loses its icon and caption. Move each covered token to the
    /// nearest visible spot that is clear of walls and of the things around
    /// it; tokens that are already visible stay where the map put them.
    func keepingBonusesInView(_ bands: InterfaceBands) -> LevelDefinition {
        let low = bands.bottom
        let high = worldHeight - bands.top
        guard high > low, bands.token > 0 else { return self }
        var positions = bonuses.map(\.position)
        for index in positions.indices {
            let point = positions[index]
            guard point.y < low || point.y > high else { continue }
            let others = positions.indices.filter { $0 != index }.map { positions[$0] }
            positions[index] = visibleSpot(near: point, low: low, high: high, token: bands.token, others: others)
        }
        var copy = self
        copy.bonuses = zip(bonuses, positions).map { BonusSpawn(id: $0.id, kind: $0.kind, position: $1) }
        return copy
    }

    /// The closest point to `point` inside the visible band where a token
    /// fits, scanning a grid over the band plus the token's own column.
    private func visibleSpot(near point: Vec2, low: Double, high: Double, token: Double, others: [Vec2]) -> Vec2 {
        let step = max(8, token / 4)
        let inset = token + 24
        var rows = Array(stride(from: low, through: high, by: step))
        rows.append(high)
        var columns = Array(stride(from: inset, through: worldWidth - inset, by: step))
        columns.append(min(max(point.x, inset), worldWidth - inset))

        var best: Vec2?
        var bestDistance = Double.infinity
        for y in rows {
            for x in columns {
                let candidate = Vec2(x: x, y: y)
                let distance = candidate.distance(to: point)
                guard distance < bestDistance, tokenFits(at: candidate, token: token, others: others) else { continue }
                best = candidate
                bestDistance = distance
            }
        }
        if let best { return best }
        let anchor = Vec2(x: point.x, y: min(max(point.y, low), high))
        return LayoutSafety.nudge(anchor, walls: walls, worldWidth: worldWidth, worldHeight: worldHeight, clearance: token)
    }

    private func tokenFits(at p: Vec2, token: Double, others: [Vec2]) -> Bool {
        guard LayoutSafety.isClear(p, walls: walls, clearance: token) else { return false }
        // Neighbours keep a gap wide enough for the caption drawn above the token.
        let spacing = token * 2
        let sparkSpacing = token * 1.8
        for spark in sparks {
            if let ring = spark.orbit {
                if abs(p.distance(to: ring.center) - ring.radius) < sparkSpacing { return false }
            } else if p.distance(to: spark.position) < sparkSpacing {
                return false
            }
        }
        if p.distance(to: exit) < spacing * 1.15 || p.distance(to: playerStart) < spacing { return false }
        if others.contains(where: { p.distance(to: $0) < spacing * 1.2 }) { return false }
        if rifts.contains(where: { p.distance(to: $0.position) < $0.radius + token }) { return false }
        if gravityWells.contains(where: { p.distance(to: $0.position) < $0.coreRadius + token }) { return false }
        if gates.contains(where: { $0.area.expanded(token).contains(p) }) { return false }
        for mover in movers {
            if case .stationary = mover.path, p.distance(to: mover.position) < mover.radius + token { return false }
        }
        for laser in lasers {
            guard case .fixed = laser.motion else { continue }
            if p.distance(toSegmentFrom: laser.start, to: laser.end) < token + laser.beamWidth / 2 { return false }
        }
        return true
    }
}
