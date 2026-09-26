import SpriteKit
import UIKit

/// A beam drawn so it reads on a 40 mm face. At rest: two dim emitters and a
/// dashed guide along the line it will fire on. While it charges, a fuse runs
/// from one emitter to the other, so the time left can be read at a glance.
/// Firing: a bright core in a soft glow, with the emitters flared.
@MainActor
final class WatchLaserNode {
    let root = SKNode()
    private let guide = SKShapeNode()
    private let aura = SKShapeNode()
    private let core = SKShapeNode()
    private let fuse = SKShapeNode(circleOfRadius: 2.4)
    private let emitters = [SKShapeNode(circleOfRadius: 3.4), SKShapeNode(circleOfRadius: 3.4)]
    private var line: (CGPoint, CGPoint)?

    private static let pink = UIColor(red: 1, green: 0.32, blue: 0.52, alpha: 1)
    private static let hot = UIColor(red: 1, green: 0.88, blue: 0.94, alpha: 1)

    init() {
        root.zPosition = 9
        guide.lineWidth = 1
        aura.lineCap = .round
        aura.blendMode = .add
        aura.zPosition = 1
        core.lineCap = .round
        core.zPosition = 2
        fuse.fillColor = Self.hot
        fuse.strokeColor = .clear
        fuse.blendMode = .add
        fuse.zPosition = 3
        for emitter in emitters {
            emitter.lineWidth = 1.2
            emitter.zPosition = 4
        }
        for node in [guide, aura, core, fuse] + emitters { root.addChild(node) }
    }

    /// `width` is the lethal band in points; `clock` drives the charge flicker.
    func update(start: CGPoint, end: CGPoint, phase: LaserPhase, width: CGFloat, clock: TimeInterval) {
        if line.map({ $0.0 != start || $0.1 != end }) ?? true {
            line = (start, end)
            let path = CGMutablePath()
            path.move(to: start)
            path.addLine(to: end)
            guide.path = path.copy(dashingWithPhase: 0, lengths: [3, 4])
            aura.path = path
            core.path = path
            emitters[0].position = start
            emitters[1].position = end
        }
        switch phase {
        case .idle:
            guide.strokeColor = Self.pink.withAlphaComponent(0.22)
            aura.isHidden = true
            core.isHidden = true
            fuse.isHidden = true
            setEmitters(fill: Self.pink.withAlphaComponent(0.22), stroke: Self.pink.withAlphaComponent(0.5), scale: 1)
        case .charging(let progress):
            let p = CGFloat(min(1, max(0, progress)))
            let flicker = 0.78 + 0.22 * CGFloat(sin(clock * 20))
            guide.strokeColor = Self.pink.withAlphaComponent(0.35 + 0.4 * p)
            aura.isHidden = false
            aura.strokeColor = Self.pink.withAlphaComponent((0.08 + 0.3 * p) * flicker)
            aura.lineWidth = width * (0.8 + 1.0 * p)
            core.isHidden = false
            core.strokeColor = Self.pink.withAlphaComponent(0.2 + 0.45 * p)
            core.lineWidth = max(1, width * 0.3)
            fuse.isHidden = false
            fuse.position = CGPoint(x: start.x + (end.x - start.x) * p, y: start.y + (end.y - start.y) * p)
            setEmitters(fill: Self.pink.withAlphaComponent(0.45 + 0.55 * p), stroke: Self.hot.withAlphaComponent(0.5 + 0.5 * p), scale: 1 + 0.4 * p * flicker)
        case .firing:
            guide.strokeColor = .clear
            aura.isHidden = false
            aura.strokeColor = Self.pink.withAlphaComponent(0.55)
            aura.lineWidth = width * 2.3
            core.isHidden = false
            core.strokeColor = Self.hot
            core.lineWidth = width
            fuse.isHidden = true
            setEmitters(fill: Self.hot, stroke: Self.pink, scale: 1.5)
        }
    }

    private func setEmitters(fill: UIColor, stroke: UIColor, scale: CGFloat) {
        for emitter in emitters {
            emitter.fillColor = fill
            emitter.strokeColor = stroke
            emitter.setScale(scale)
        }
    }
}
