import SpriteKit
import UIKit

/// Wrist-run effects: pickup rings, dashes and rocks breaking into shards.
extension WatchArenaScene {
    // MARK: - Effects

    func react(to events: [SimEvent]) {
        for event in events {
            switch event {
            case .sparkCollected(let id, _):
                if let spark = run.sim.sparks.first(where: { $0.id == id }) { ring(at: point(spark.position), color: VisualPalette.spark) }
            case .bonusCollected(let kind):
                ring(at: player.position, color: SpriteTextures.tint(kind))
            case .asteroidShattered(let id, _, _):
                shatter(id)
            case .echoSpawned:
                ring(at: point(run.level.playerStart), color: VisualPalette.echoRim)
            case .dashed:
                ring(at: player.position, color: UIColor(red: 1, green: 0.86, blue: 0.4, alpha: 1))
            default:
                break
            }
        }
    }

    private func ring(at position: CGPoint, color: UIColor) {
        let ring = SKShapeNode(circleOfRadius: max(6, actorRadius * 0.8))
        ring.position = position
        ring.strokeColor = color
        ring.lineWidth = 1.4
        ring.zPosition = 20
        addChild(ring)
        ring.run(.sequence([.group([.scale(to: 2.6, duration: 0.35), .fadeOut(withDuration: 0.35)]), .removeFromParent()]))
    }

    /// The painted rock splits along its faults; every shard keeps flying on
    /// its own physics body and fades.
    private func shatter(_ id: Int) {
        guard let root = rockNodes.removeValue(forKey: id), let art = rockArt[id] else { return }
        let turn = root.childNode(withName: "rock")?.zRotation ?? 0
        let origin = root.position
        root.removeFromParent()
        for shard in art.shards {
            let offset = shard.centroid.applying(CGAffineTransform(rotationAngle: turn))
            let node = SKSpriteNode(texture: shard.texture, size: shard.size)
            node.anchorPoint = shard.anchor
            node.position = CGPoint(x: origin.x + offset.x, y: origin.y + offset.y)
            node.zRotation = turn
            node.zPosition = 10.5
            let body = SKPhysicsBody(circleOfRadius: max(1, min(shard.size.width, shard.size.height) * 0.3))
            body.affectedByGravity = false
            body.linearDamping = 1.6
            body.restitution = 0.4
            node.physicsBody = body
            addChild(node)
            let length = max(hypot(offset.x, offset.y), 0.001)
            let burst = art.shape.radius * CGFloat.random(in: 3.2...5.2)
            body.velocity = CGVector(dx: offset.x / length * burst, dy: offset.y / length * burst)
            body.angularVelocity = CGFloat.random(in: -6...6)
            node.run(.sequence([.wait(forDuration: 0.7), .group([.fadeOut(withDuration: 0.4), .scale(to: 0.5, duration: 0.4)]), .removeFromParent()]))
        }
        ring(at: origin, color: UIColor(red: 1, green: 0.8, blue: 0.5, alpha: 1))
    }

    // MARK: - Helpers

    static func head(radius: CGFloat, core: UIColor, rim: UIColor, glow: UIColor) -> SKNode {
        let root = SKNode()
        let halo = SKSpriteNode(texture: SpriteTextures.puff)
        halo.size = CGSize(width: radius * 4.2, height: radius * 4.2)
        halo.color = glow
        halo.colorBlendFactor = 1
        halo.blendMode = .add
        halo.alpha = 0.32
        let body = SKShapeNode(circleOfRadius: radius)
        body.fillTexture = SpriteTextures.nucleus
        body.fillColor = core
        body.strokeColor = rim
        body.lineWidth = max(1, radius * 0.1)
        root.addChild(halo)
        root.addChild(body)
        return root
    }

    static func dashedCircle(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<10 {
            let start = CGFloat(index) / 10 * .pi * 2
            path.addArc(center: .zero, radius: radius, startAngle: start, endAngle: start + .pi / 10, clockwise: false)
        }
        return path
    }

    static func color(_ rgb: RGB) -> UIColor {
        UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
    }
}
