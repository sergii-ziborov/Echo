import SpriteKit

@MainActor
final class TrailRenderer {
    @MainActor
    private final class Actor {
        var samples: [VisualTrailPoint] = []
        var lastPosition: CGPoint?
        let bloom = SKShapeNode()
        let colorBand = SKShapeNode()
        let core = SKShapeNode()

        init(color: UIColor, parent: SKNode) {
            for node in [bloom, colorBand, core] {
                node.fillColor = .clear
                node.strokeColor = .clear
                node.lineWidth = 0
                node.glowWidth = 0
                node.zPosition = VisualLayer.trails
                parent.addChild(node)
            }
            bloom.blendMode = .add
            bloom.fillColor = color.withAlphaComponent(0.05)
            colorBand.blendMode = .alpha
            colorBand.fillColor = color.withAlphaComponent(0.26)
            core.blendMode = .alpha
            core.fillColor = UIColor.white.withAlphaComponent(0.62)
        }

        func remove() {
            bloom.removeFromParent()
            colorBand.removeFromParent()
            core.removeFromParent()
        }
    }

    private weak var parent: SKNode?
    private var actors: [String: Actor] = [:]

    init(parent: SKNode) {
        self.parent = parent
    }

    func reset() {
        actors.values.forEach { $0.remove() }
        actors.removeAll()
    }

    func beginBranch(_ id: String) {
        guard let actor = actors[id], let last = actor.samples.last else { return }
        actor.samples.append(VisualTrailPoint(position: last.position, time: last.time, breakBefore: true))
        actor.lastPosition = nil
    }

    func sample(
        id: String,
        position: CGPoint,
        time: TimeInterval,
        color: UIColor,
        headWidth: CGFloat,
        moving: Bool,
        breakBefore: Bool = false
    ) {
        guard let parent else { return }
        let actor = actors[id] ?? {
            let created = Actor(color: color, parent: parent)
            actors[id] = created
            return created
        }()
        actor.bloom.fillColor = color.withAlphaComponent(0.05)
        actor.colorBand.fillColor = color.withAlphaComponent(0.26)

        if breakBefore {
            actor.samples.append(VisualTrailPoint(position: position, time: time, breakBefore: true))
            actor.lastPosition = position
            redraw(actor, now: time, headWidth: headWidth)
            return
        }

        let step = max(2.2, headWidth * VisualStyle.trailStepFactor)
        if let last = actor.lastPosition {
            let gap = hypot(position.x - last.x, position.y - last.y)
            if gap < 0.6 || !moving {
                redraw(actor, now: time, headWidth: headWidth)
                return
            }
            if gap > VisualStyle.teleportGap {
                actor.samples.append(VisualTrailPoint(position: position, time: time, breakBefore: true))
                actor.lastPosition = position
                redraw(actor, now: time, headWidth: headWidth)
                return
            }
            var remaining = gap
            let dx = (position.x - last.x) / gap
            let dy = (position.y - last.y) / gap
            var cursor = last
            while remaining > step {
                cursor = CGPoint(x: cursor.x + dx * step, y: cursor.y + dy * step)
                remaining -= step
                actor.samples.append(VisualTrailPoint(position: cursor, time: time))
            }
        }
        actor.samples.append(VisualTrailPoint(position: position, time: time))
        actor.lastPosition = position
        if actor.samples.count > VisualStyle.trailCapacity {
            actor.samples.removeFirst(actor.samples.count - VisualStyle.trailCapacity)
        }
        redraw(actor, now: time, headWidth: headWidth)
    }

    func prune(ids: Set<String>) {
        for key in actors.keys where !ids.contains(key) {
            actors.removeValue(forKey: key)?.remove()
        }
    }

    static func ribbon(
        samples: [VisualTrailPoint],
        now: TimeInterval,
        lifetime: TimeInterval,
        headWidth: CGFloat
    ) -> CGPath {
        let result = CGMutablePath()
        guard now.isFinite, lifetime > 0, headWidth > 0 else { return result }

        var strip: [VisualTrailPoint] = []
        strip.reserveCapacity(min(samples.count, VisualStyle.trailCapacity))

        func appendStrip(_ points: [VisualTrailPoint]) {
            guard points.count >= 2 else { return }
            var left: [CGPoint] = []
            var right: [CGPoint] = []
            left.reserveCapacity(points.count)
            right.reserveCapacity(points.count)

            for index in points.indices {
                let point = points[index]
                let previous = points[max(0, index - 1)].position
                let next = points[min(points.count - 1, index + 1)].position
                let incoming = unit(from: previous, to: point.position)
                let outgoing = unit(from: point.position, to: next)
                let directionIn = incoming ?? outgoing ?? CGVector(dx: 1, dy: 0)
                let directionOut = outgoing ?? incoming ?? CGVector(dx: 1, dy: 0)
                let nIn = CGVector(dx: -directionIn.dy, dy: directionIn.dx)
                let nOut = CGVector(dx: -directionOut.dy, dy: directionOut.dx)
                let sum = CGVector(dx: nIn.dx + nOut.dx, dy: nIn.dy + nOut.dy)
                let length = hypot(sum.dx, sum.dy)
                let normal = length > 0.001
                    ? CGVector(dx: sum.dx / length, dy: sum.dy / length)
                    : nOut
                let age = max(0, now - point.time)
                let u = min(1, age / lifetime)
                let half = headWidth * CGFloat(pow(1 - u, 1.3)) * 0.5
                let alignment = max(0.5, abs(normal.dx * nOut.dx + normal.dy * nOut.dy))
                let offset = min(half / alignment, half * 2)
                left.append(CGPoint(x: point.position.x + normal.dx * offset, y: point.position.y + normal.dy * offset))
                right.append(CGPoint(x: point.position.x - normal.dx * offset, y: point.position.y - normal.dy * offset))
            }

            guard let first = left.first else { return }
            result.move(to: first)
            for point in left.dropFirst() { result.addLine(to: point) }
            for point in right.reversed() { result.addLine(to: point) }
            result.closeSubpath()
        }

        for sample in samples {
            guard sample.time.isFinite,
                  sample.position.x.isFinite,
                  sample.position.y.isFinite,
                  sample.time <= now + 0.000_001 else {
                appendStrip(strip)
                strip.removeAll(keepingCapacity: true)
                continue
            }
            if now - sample.time > lifetime {
                appendStrip(strip)
                strip.removeAll(keepingCapacity: true)
                continue
            }
            if sample.breakBefore || (strip.last.map { sample.time < $0.time } ?? false) {
                appendStrip(strip)
                strip.removeAll(keepingCapacity: true)
            }
            if let last = strip.last,
               hypot(sample.position.x - last.position.x, sample.position.y - last.position.y) < 0.001 {
                continue
            }
            strip.append(sample)
        }
        appendStrip(strip)
        return result
    }

    private func redraw(_ actor: Actor, now: TimeInterval, headWidth: CGFloat) {
        let life = VisualStyle.trailLifetime
        actor.bloom.path = Self.ribbon(samples: actor.samples, now: now, lifetime: life, headWidth: headWidth * 1.35)
        actor.colorBand.path = Self.ribbon(samples: actor.samples, now: now, lifetime: life, headWidth: headWidth * 0.72)
        actor.core.path = Self.ribbon(samples: actor.samples, now: now, lifetime: life, headWidth: headWidth * 0.28)
    }

    private static func unit(from a: CGPoint, to b: CGPoint) -> CGVector? {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let length = hypot(dx, dy)
        guard length > 0.000_001 else { return nil }
        return CGVector(dx: dx / length, dy: dy / length)
    }
}
