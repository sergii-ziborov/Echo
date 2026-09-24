import QuartzCore
import SpriteKit
import UIKit

/// Ability pickups on the map: a floating jewel token that flips like a coin
/// and catches a sweeping shine, a rotating pickup ring, orbiting glints, a
/// themed aura that hints at what the ability does, and a caption pill. The
/// pickup leans toward an approaching orb and is sucked into it when taken.
extension GameScene {
    func buildBonuses() {
        for bonus in session.sim.bonuses {
            let node = bonusNode(for: bonus.kind, scale: pickupScale)
            node.position = scenePoint(bonus.position)
            node.zPosition = VisualLayer.pickups
            node.userData = ["collected": false]
            addChild(node)
            bonusNodes[bonus.id] = node
        }
    }

    func bonusNode(for kind: BonusKind, scale: CGFloat) -> SKNode {
        let tint = Self.color(for: kind)
        let token = 44 * scale
        let root = SKNode()

        let halo = SKSpriteNode(texture: SpriteTextures.puff)
        halo.name = "halo"
        halo.size = CGSize(width: token * 2.1, height: token * 2.1)
        halo.color = tint
        halo.colorBlendFactor = 1
        halo.blendMode = .add
        halo.alpha = 0.3
        halo.zPosition = -3
        root.addChild(halo)

        let pad = SKShapeNode(path: Self.segmentedCirclePath(radius: token * 0.72, segments: 18, coverage: 0.52))
        pad.name = "pad"
        pad.strokeColor = tint.withAlphaComponent(0.42)
        pad.lineWidth = 1.2 * scale
        pad.lineCap = .round
        pad.glowWidth = 0
        pad.zPosition = -2.5
        pad.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 14)))
        root.addChild(pad)

        let aura = bonusAura(for: kind, scale: scale)
        aura.alpha = 0.8
        root.addChild(aura)

        let body = SKNode()
        body.name = "body"
        root.addChild(body)

        let float = SKNode()
        float.name = "float"
        let bob = SKAction.sequence([
            .moveBy(x: 0, y: 2.2 * scale, duration: 1.1),
            .moveBy(x: 0, y: -2.2 * scale, duration: 1.1),
        ])
        bob.timingMode = .easeInEaseOut
        float.run(.repeatForever(bob))
        body.addChild(float)

        let gem = SKSpriteNode(texture: SpriteTextures.token(kind))
        gem.name = "token"
        gem.size = CGSize(width: token, height: token)
        let flip = SKAction.sequence([
            .wait(forDuration: TimeInterval.random(in: 2.5...5)),
            .scaleX(to: 0.06, duration: 0.14),
            .scaleX(to: 1, duration: 0.16),
            .wait(forDuration: 2.6),
        ])
        gem.run(.repeatForever(flip))
        float.addChild(gem)

        let crop = SKCropNode()
        let mask = SKShapeNode(path: BitmapCanvas.hexagon(center: .zero, radius: token * 0.42, corner: token * 0.07))
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        let shine = SKSpriteNode(texture: SpriteTextures.shine)
        shine.size = CGSize(width: token * 0.34, height: token * 1.2)
        shine.zRotation = -0.45
        shine.alpha = 0.8
        shine.blendMode = .add
        shine.position = CGPoint(x: -token, y: 0)
        shine.run(.repeatForever(.sequence([
            .wait(forDuration: TimeInterval.random(in: 1.6...3.2)),
            .moveTo(x: token, duration: 0.55),
            .moveTo(x: -token, duration: 0),
        ])))
        crop.addChild(shine)
        crop.zPosition = 0.5
        float.addChild(crop)

        let orbit = SKNode()
        orbit.name = "orbit"
        for index in 0..<3 {
            let glint = SKSpriteNode(texture: SpriteTextures.glint)
            let angle = CGFloat(index) / 3 * .pi * 2
            glint.position = CGPoint(x: cos(angle) * token * 0.66, y: sin(angle) * token * 0.66)
            glint.size = CGSize(width: 9 * scale, height: 9 * scale)
            glint.color = tint.blended(with: .white, amount: 0.45)
            glint.colorBlendFactor = 1
            glint.blendMode = .add
            glint.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.25, duration: 0.5 + Double(index) * 0.13),
                .fadeAlpha(to: 1, duration: 0.45),
            ])))
            orbit.addChild(glint)
        }
        orbit.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 3.2)))
        orbit.zPosition = 1
        body.addChild(orbit)

        let caption = captionPill(kind.fieldLabel, tint: tint, scale: scale)
        caption.position = CGPoint(x: 0, y: token * 0.86)
        caption.zPosition = 2
        root.addChild(caption)

        let ping = SKAction.run { [weak root] in
            guard let root else { return }
            let ring = SKShapeNode(circleOfRadius: token * 0.5)
            ring.strokeColor = tint.withAlphaComponent(0.7)
            ring.lineWidth = 1.4 * scale
            ring.glowWidth = 0
            ring.zPosition = -1
            root.addChild(ring)
            let grow = SKAction.group([.scale(to: 1.9, duration: 0.9), .fadeOut(withDuration: 0.9)])
            grow.timingMode = .easeOut
            ring.run(.sequence([grow, .removeFromParent()]))
        }
        root.run(.repeatForever(.sequence([.wait(forDuration: TimeInterval.random(in: 1.9...2.4)), ping])))
        return root
    }

    func captionPill(_ text: String, tint: UIColor, scale: CGFloat) -> SKNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 8.5 * scale
        label.fontColor = tint.blended(with: .white, amount: 0.35)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        let width = label.frame.width + 12 * scale
        let pill = SKShapeNode(rectOf: CGSize(width: width, height: 13 * scale), cornerRadius: 6.5 * scale)
        pill.fillColor = UIColor(red: 0.03, green: 0.04, blue: 0.08, alpha: 0.78)
        pill.strokeColor = tint.withAlphaComponent(0.55)
        pill.lineWidth = 1
        pill.glowWidth = 0
        pill.addChild(label)
        return pill
    }

    // MARK: - Live sync

    /// Leans each pickup toward an approaching orb, plays the collection once,
    /// and restores pickups that a rewind brings back.
    func syncBonuses(_ states: [BonusState], mode: RenderMode) {
        let player = playerNode.position
        let reach = CGFloat(session.sim.config.playerRadius + session.sim.config.bonusRadius) * worldScale
        for bonus in states {
            guard let root = bonusNodes[bonus.id] else { continue }
            let taken = (root.userData?["collected"] as? Bool) ?? false
            if bonus.collected {
                guard !taken else { continue }
                root.userData?["collected"] = true
                if mode == .live {
                    collectBonus(root, kind: bonus.kind, toward: player)
                } else {
                    root.isHidden = true
                }
                continue
            }
            if taken {
                root.userData?["collected"] = false
                root.isHidden = false
            }
            let distance = hypot(player.x - root.position.x, player.y - root.position.y)
            let near = max(0, min(1, 1 - (distance - reach) / (reach * 3)))
            root.childNode(withName: "body")?.setScale(1 + near * 0.16)
            root.childNode(withName: "halo")?.alpha = 0.3 + near * 0.4
            root.childNode(withName: "body")?.childNode(withName: "orbit")?.speed = 1 + near * 2.5
        }
    }

    /// The pickup itself hides at once: pickups share the timeline's speed, so
    /// a Freeze taken here would otherwise stall its own collection. A detached
    /// copy of the token flies into the orb instead.
    func collectBonus(_ root: SKNode, kind: BonusKind, toward player: CGPoint) {
        let tint = Self.color(for: kind)
        let origin = root.position
        root.isHidden = true
        let flyer = SKSpriteNode(texture: SpriteTextures.token(kind))
        flyer.size = CGSize(width: 44 * pickupScale, height: 44 * pickupScale)
        flyer.position = origin
        flyer.zPosition = VisualLayer.events - 0.2
        addChild(flyer)
        let pull = SKAction.group([
            .move(to: player, duration: 0.18),
            .scale(to: 0.25, duration: 0.18),
            .fadeAlpha(to: 0.2, duration: 0.18),
        ])
        pull.timingMode = .easeIn
        flyer.run(.sequence([pull, .removeFromParent()]))

        shockwave(at: origin, color: tint, start: 14 * pickupScale, end: 58 * pickupScale, lineWidth: 1.6)
        let burst = SKEmitterNode()
        burst.particleTexture = SpriteTextures.glint
        burst.position = origin
        burst.zPosition = VisualLayer.events - 0.3
        burst.particleBirthRate = 2_000
        burst.numParticlesToEmit = 14
        burst.particleLifetime = 0.55
        burst.particleLifetimeRange = 0.2
        burst.emissionAngleRange = .pi * 2
        burst.particleSpeed = 110 * pickupScale
        burst.particleSpeedRange = 50 * pickupScale
        burst.particleScale = 0.18 * pickupScale
        burst.particleScaleRange = 0.08
        burst.particleScaleSpeed = -0.25
        burst.particleAlphaSpeed = -1.8
        burst.particleColor = tint.blended(with: .white, amount: 0.3)
        burst.particleColorBlendFactor = 1
        burst.particleBlendMode = .add
        addChild(burst)
        burst.run(.sequence([.wait(forDuration: 0.9), .removeFromParent()]))

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "+\(kind.title.uppercased())"
        label.fontSize = 12 * pickupScale
        label.fontColor = tint.blended(with: .white, amount: 0.25)
        label.position = CGPoint(x: player.x, y: player.y + actorRadius + 8)
        label.zPosition = VisualLayer.events
        label.setScale(0.6)
        addChild(label)
        label.run(.sequence([
            .group([.scale(to: 1, duration: 0.14), .moveBy(x: 0, y: 10, duration: 0.14)]),
            .group([.moveBy(x: 0, y: 22, duration: 0.7), .fadeOut(withDuration: 0.7)]),
            .removeFromParent(),
        ]))
    }
}
