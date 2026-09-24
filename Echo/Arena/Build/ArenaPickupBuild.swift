import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func buildExit() {
        let root = SKNode()
        root.zPosition = VisualLayer.pickups - 0.4
        root.position = scenePoint(session.level.exit)
        let r = CGFloat(session.sim.config.exitRadius) * worldScale
        let outer = SKShapeNode(circleOfRadius: r)
        outer.strokeColor = UIColor.white.withAlphaComponent(0.22)
        outer.lineWidth = 2
        outer.glowWidth = 0
        outer.fillColor = UIColor(white: 0.04, alpha: 0.55)
        outer.name = "outer"
        let spin = SKShapeNode(circleOfRadius: r * 0.72)
        spin.strokeColor = UIColor(red: 0.45, green: 0.85, blue: 1, alpha: 0.45)
        spin.lineWidth = 1.6
        spin.glowWidth = 0
        spin.fillColor = .clear
        spin.name = "spin"
        spin.run(.repeatForever(.rotate(byAngle: .pi, duration: 6)))
        let core = SKSpriteNode(texture: GlowTextures.blob)
        core.size = CGSize(width: r * 1.1, height: r * 1.1)
        core.blendMode = .add
        core.alpha = 0.35
        core.name = "core"
        core.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 1.1),
            .scale(to: 0.88, duration: 1.1),
        ])))
        root.addChild(outer)
        root.addChild(spin)
        root.addChild(core)
        addChild(root)
        exitNode = root
        refreshExit()
    }

    func buildSparks() {
        let scale = pickupScale
        for spark in session.sim.sparks {
            let root = SKNode()
            root.position = scenePoint(spark.position)
            root.zPosition = VisualLayer.pickups
            root.name = "spark-\(spark.id)"

            let timed = spark.timerDuration != nil
            let gold = VisualPalette.timedSpark
            let tint = timed ? gold : VisualPalette.spark

            let glow = SKSpriteNode(texture: GlowTextures.glowMask)
            glow.size = CGSize(width: 40 * scale, height: 40 * scale)
            glow.blendMode = .add
            glow.alpha = VisualStyle.glowAlpha + 0.08
            glow.color = tint
            glow.colorBlendFactor = 1
            glow.name = "glow"
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: VisualStyle.glowAlpha + 0.2, duration: 0.9),
                .fadeAlpha(to: VisualStyle.glowAlpha + 0.04, duration: 1.1),
            ])))

            let side = (timed ? 24 : 19) * scale
            let gem = SKSpriteNode(texture: timed ? SpriteTextures.timedGem : SpriteTextures.sparkGem)
            gem.size = CGSize(width: side, height: side)
            gem.name = "gem"
            let sway = SKAction.sequence([
                .group([.rotate(toAngle: 0.22, duration: 1.3), .moveBy(x: 0, y: 1.6 * scale, duration: 1.3)]),
                .group([.rotate(toAngle: -0.22, duration: 1.3), .moveBy(x: 0, y: -1.6 * scale, duration: 1.3)]),
            ])
            sway.timingMode = .easeInEaseOut
            gem.run(.repeatForever(sway))

            let glint = SKSpriteNode(texture: SpriteTextures.glint)
            glint.size = CGSize(width: side * 0.9, height: side * 0.9)
            glint.position = CGPoint(x: -side * 0.18, y: side * 0.22)
            glint.blendMode = .add
            glint.alpha = 0
            glint.zPosition = 1
            glint.run(.repeatForever(.sequence([
                .wait(forDuration: TimeInterval.random(in: 1.4...3.2)),
                .group([.fadeAlpha(to: 1, duration: 0.1), .scale(to: 1.15, duration: 0.1)]),
                .group([.fadeOut(withDuration: 0.35), .scale(to: 0.6, duration: 0.35)]),
            ])))

            root.addChild(glow)
            root.addChild(gem)
            root.addChild(glint)

            if timed {
                let arc = SKShapeNode()
                arc.strokeColor = gold
                arc.lineWidth = 2 * scale
                arc.glowWidth = 0
                arc.lineCap = .round
                arc.fillColor = .clear
                arc.zRotation = .pi / 2
                arc.name = "timer"
                root.addChild(arc)
                let reward = fieldCaption("BONUS", color: gold, y: 22 * scale)
                reward.name = "timerReward"
                reward.fontSize = 9 * scale
                let label = fieldCaption("", color: gold, y: -22 * scale)
                label.fontSize = 10 * scale
                label.name = "timerLabel"
                root.addChild(reward)
                root.addChild(label)
            }
            addChild(root)
            sparkNodes[spark.id] = root
        }
    }

    func buildFields() {
        for field in session.level.fields {
            let rect = mapped(field.area)
            let node = SKShapeNode(rect: rect, cornerRadius: 18)
            node.fillColor = UIColor(red: 0.35, green: 0.55, blue: 1, alpha: 0.14)
            node.strokeColor = UIColor(red: 0.45, green: 0.7, blue: 1, alpha: 0.45)
            node.lineWidth = 1.2
            node.glowWidth = 0
            node.zPosition = 2.4
            node.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.35, duration: 1.2),
                .fadeAlpha(to: 0.8, duration: 1.2),
            ])))
            addChild(node)
            if let texture = GlowTextures.slowField {
                let membrane = roundedMaterialPanel(texture: texture, rect: rect, zPosition: 2.42, name: "field")
                membrane.alpha = 0.24
                membrane.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.12, duration: 1.3),
                    .fadeAlpha(to: 0.29, duration: 1.3),
                ])))
                addChild(membrane)
            }
        }
    }

    func bonusAura(for kind: BonusKind, scale: CGFloat) -> SKNode {
        let root = SKNode()
        root.name = "abilityAura"
        root.zPosition = -2
        root.setScale(scale)
        let tint = Self.color(for: kind)

        switch kind {
        case .freeze:
            let field = SKShapeNode(circleOfRadius: 53)
            field.fillColor = tint.withAlphaComponent(0.055)
            field.strokeColor = tint.withAlphaComponent(0.24)
            field.lineWidth = 1
            field.glowWidth = 0
            root.addChild(field)
            for index in 0..<6 {
                let snow = SKSpriteNode(texture: GlowTextures.snowflakeParticle)
                snow.size = CGSize(width: 10 + CGFloat(index % 3) * 3, height: 10 + CGFloat(index % 3) * 3)
                snow.position = CGPoint(x: CGFloat(index - 3) * 13, y: CGFloat(index % 2) * 22 - 11)
                snow.alpha = 0.42 + CGFloat(index % 3) * 0.15
                root.addChild(snow)
                snow.run(.repeatForever(.sequence([
                    .group([.moveBy(x: 4, y: -9, duration: 0.9 + Double(index) * 0.05), .fadeAlpha(to: 0.18, duration: 0.9)]),
                    .group([.moveBy(x: -4, y: 9, duration: 0), .fadeAlpha(to: 0.72, duration: 0)]),
                ])))
            }

        case .surge:
            for index in 0..<3 {
                let path = CGMutablePath()
                let y = CGFloat(-10 + index * 7)
                path.move(to: CGPoint(x: -10, y: y))
                path.addLine(to: CGPoint(x: 0, y: y + 8))
                path.addLine(to: CGPoint(x: 10, y: y))
                let chevron = SKShapeNode(path: path)
                chevron.strokeColor = tint.withAlphaComponent(0.88)
                chevron.lineWidth = 2.1
                chevron.lineCap = .round
                chevron.lineJoin = .round
                chevron.glowWidth = 0
                chevron.position = CGPoint(x: 0, y: CGFloat(index) * 3)
                root.addChild(chevron)
                chevron.run(.repeatForever(.sequence([
                    .group([
                        .moveBy(x: 0, y: 8, duration: 0.42),
                        .fadeAlpha(to: 0.18, duration: 0.42),
                    ]),
                    .group([
                        .moveBy(x: 0, y: -8, duration: 0),
                        .fadeAlpha(to: 0.92, duration: 0),
                    ]),
                ])))
            }

        case .shield, .ward:
            let bloom = SKSpriteNode(texture: GlowTextures.blob)
            bloom.size = CGSize(width: 54, height: 54)
            bloom.blendMode = .add
            bloom.color = tint
            bloom.colorBlendFactor = 0.8
            bloom.alpha = 0.28
            bloom.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.42, duration: 0.7),
                .fadeAlpha(to: 0.22, duration: 0.7),
            ])))
            root.addChild(bloom)

        case .pulse:
            let hand = SKShapeNode(rectOf: CGSize(width: 1.8, height: 15), cornerRadius: 0.9)
            hand.fillColor = tint
            hand.strokeColor = .clear
            hand.glowWidth = 0
            hand.position = CGPoint(x: 0, y: 7)
            let pivot = SKNode()
            pivot.addChild(hand)
            pivot.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 2.2)))
            root.addChild(pivot)

        case .magnet:
            root.addChild(magneticFieldAura(tint: tint, radius: 52, particleCount: 4))

        case .phase, .blink:
            for index in 0..<4 {
                let ghost = SKShapeNode(circleOfRadius: CGFloat(10 + index * 7))
                ghost.strokeColor = tint.withAlphaComponent(0.65 - CGFloat(index) * 0.10)
                ghost.lineWidth = 1.5
                ghost.glowWidth = 0
                ghost.position = CGPoint(x: CGFloat(index - 2) * 7, y: 0)
                root.addChild(ghost)
            }
            root.run(.repeatForever(.sequence([.moveBy(x: 8, y: 0, duration: 0.55), .moveBy(x: -8, y: 0, duration: 0.55)])))

        case .chrono, .anchor:
            let clock = SKShapeNode(path: Self.segmentedCirclePath(radius: 43, segments: 12, coverage: 0.32))
            clock.strokeColor = tint.withAlphaComponent(0.75)
            clock.lineWidth = 2
            clock.glowWidth = 0
            root.addChild(clock)
            clock.run(.repeatForever(.rotate(byAngle: kind == .anchor ? -.pi / 2 : .pi * 2, duration: kind == .anchor ? 4.2 : 7)))

        case .repulse:
            let crown = SKShapeNode(path: Self.segmentedCirclePath(radius: 47, segments: 16, coverage: 0.34))
            crown.strokeColor = tint.withAlphaComponent(0.85)
            crown.lineWidth = 2.4
            crown.glowWidth = 0
            root.addChild(crown)
            crown.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.55), .scale(to: 0.92, duration: 0.55)])))

        case .prism:
            let triangle = SKShapeNode(path: Self.polygonPath(radius: 48, sides: 3))
            triangle.strokeColor = tint.withAlphaComponent(0.90)
            triangle.fillColor = tint.withAlphaComponent(0.045)
            triangle.lineWidth = 2
            triangle.glowWidth = 0
            root.addChild(triangle)
            let hex = SKShapeNode(path: Self.polygonPath(radius: 36, sides: 6))
            hex.strokeColor = UIColor.white.withAlphaComponent(0.62)
            hex.lineWidth = 1.2
            root.addChild(hex)
            root.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 10)))
        }
        return root
    }
}
