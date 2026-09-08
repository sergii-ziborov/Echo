import Foundation

struct Vec2: Equatable, Hashable, Sendable {
    var x: Double
    var y: Double

    static let zero = Vec2(x: 0, y: 0)

    var length: Double { hypot(x, y) }

    var lengthSquared: Double { x * x + y * y }

    func normalized() -> Vec2 {
        let len = length
        guard len > 0 else { return .zero }
        return Vec2(x: x / len, y: y / len)
    }

    func distance(to other: Vec2) -> Double {
        hypot(x - other.x, y - other.y)
    }

    func lerp(_ other: Vec2, _ t: Double) -> Vec2 {
        Vec2(x: x + (other.x - x) * t, y: y + (other.y - y) * t)
    }

    func clamped(minX: Double, minY: Double, maxX: Double, maxY: Double) -> Vec2 {
        Vec2(x: min(max(x, minX), maxX), y: min(max(y, minY), maxY))
    }

    static func + (lhs: Vec2, rhs: Vec2) -> Vec2 { Vec2(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func - (lhs: Vec2, rhs: Vec2) -> Vec2 { Vec2(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
    static func * (lhs: Vec2, rhs: Double) -> Vec2 { Vec2(x: lhs.x * rhs, y: lhs.y * rhs) }
    static func * (lhs: Double, rhs: Vec2) -> Vec2 { rhs * lhs }
    static func / (lhs: Vec2, rhs: Double) -> Vec2 { Vec2(x: lhs.x / rhs, y: lhs.y / rhs) }
}

struct AABB: Equatable, Sendable {
    var minX: Double
    var minY: Double
    var maxX: Double
    var maxY: Double

    var width: Double { maxX - minX }
    var height: Double { maxY - minY }
    var center: Vec2 { Vec2(x: (minX + maxX) / 2, y: (minY + maxY) / 2) }

    init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }

    init(x: Double, y: Double, width: Double, height: Double) {
        self.minX = x
        self.minY = y
        self.maxX = x + width
        self.maxY = y + height
    }

    func contains(_ point: Vec2) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }

    func closestPoint(to point: Vec2) -> Vec2 {
        Vec2(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }

    func intersectsCircle(center: Vec2, radius: Double) -> Bool {
        closestPoint(to: center).distance(to: center) < radius
    }
}

enum CircleMath {
    /// Push a circle out of an AABB. If the center is inside the box, eject along the shallowest edge.
    static func resolve(center: Vec2, radius: Double, box: AABB) -> Vec2 {
        if box.contains(center) {
            let left = center.x - box.minX
            let right = box.maxX - center.x
            let bottom = center.y - box.minY
            let top = box.maxY - center.y
            let smallest = min(left, right, bottom, top)
            if smallest == left { return Vec2(x: box.minX - radius, y: center.y) }
            if smallest == right { return Vec2(x: box.maxX + radius, y: center.y) }
            if smallest == bottom { return Vec2(x: center.x, y: box.minY - radius) }
            return Vec2(x: center.x, y: box.maxY + radius)
        }
        let closest = box.closestPoint(to: center)
        let delta = center - closest
        let dist = delta.length
        if dist == 0 {
            return Vec2(x: center.x, y: box.maxY + radius)
        }
        if dist < radius {
            return closest + delta.normalized() * radius
        }
        return center
    }
}
