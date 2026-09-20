import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func shieldBubbleNode(
        color: UIColor,
        radius: CGFloat,
        layers: Int,
        animated: Bool
    ) -> SKNode {
        let root = SKNode()
        for layer in 0..<max(1, layers) {
            let layerRadius = radius + CGFloat(layer) * 7
            let surface = SKSpriteNode(texture: GlowTextures.shieldBubble)
            surface.size = CGSize(width: layerRadius * 2.22, height: layerRadius * 2.22)
            surface.blendMode = .alpha
            surface.alpha = layer == 0 ? 0.64 : 0.35
            surface.zRotation = CGFloat(layer) * 0.32
            root.addChild(surface)

            let shell = SKShapeNode(circleOfRadius: layerRadius)
            shell.fillColor = .clear
            shell.strokeColor = (layer == 0 ? color : .white).withAlphaComponent(layer == 0 ? 0.36 : 0.20)
            shell.lineWidth = layer == 0 ? 1.2 : 0.8
            shell.glowWidth = 0
            root.addChild(shell)

            let highlightPath = CGMutablePath()
            highlightPath.addArc(
                center: .zero,
                radius: layerRadius - 2,
                startAngle: .pi * 0.18,
                endAngle: .pi * 0.68,
                clockwise: false
            )
            let highlight = SKShapeNode(path: highlightPath)
            highlight.strokeColor = UIColor.white.withAlphaComponent(layer == 0 ? 0.68 : 0.30)
            highlight.lineWidth = layer == 0 ? 1.8 : 1.0
            highlight.lineCap = .round
            highlight.glowWidth = 0
            root.addChild(highlight)
            if animated {
                surface.run(.repeatForever(.sequence([
                    .fadeAlpha(to: layer == 0 ? 0.78 : 0.45, duration: 0.9),
                    .fadeAlpha(to: layer == 0 ? 0.58 : 0.32, duration: 1.1),
                ])))
            }
        }

        let lens = SKShapeNode(ellipseOf: CGSize(width: radius * 1.25, height: radius * 0.34))
        lens.position = CGPoint(x: -radius * 0.17, y: radius * 0.38)
        lens.zRotation = -0.32
        lens.fillColor = UIColor.white.withAlphaComponent(0.055)
        lens.strokeColor = UIColor.white.withAlphaComponent(0.16)
        lens.lineWidth = 0.8
        root.addChild(lens)

        for index in 0..<4 {
            let angle = CGFloat(index) / 4 * .pi * 2 + 0.42
            let mote = SKShapeNode(circleOfRadius: index.isMultiple(of: 2) ? 1.8 : 1.2)
            mote.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            mote.fillColor = index.isMultiple(of: 2) ? .white : color
            mote.strokeColor = .clear
            mote.glowWidth = 0
            root.addChild(mote)
            if animated {
                mote.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.18, duration: 0.45 + Double(index) * 0.08),
                    .fadeAlpha(to: 0.95, duration: 0.38 + Double(index) * 0.06),
                ])))
            }
        }

        if animated {
            lens.run(.repeatForever(.sequence([
                .group([.scale(to: 1.04, duration: 0.78), .fadeAlpha(to: 0.72, duration: 0.78)]),
                .group([.scale(to: 0.97, duration: 0.82), .fadeAlpha(to: 1, duration: 0.82)]),
            ])))
        }
        return root
    }

    func shieldFormEffect(at point: CGPoint, color: UIColor) {
        guard let playerNode else { return }
        let glow = SKSpriteNode(texture: GlowTextures.blob)
        glow.size = CGSize(width: 30, height: 30)
        glow.blendMode = .add
        glow.color = color
        glow.colorBlendFactor = 0.92
        glow.alpha = 0.9
        glow.zPosition = 2
        playerNode.addChild(glow)
        glow.run(.sequence([
            .group([.scale(to: 2.6, duration: 0.34), .fadeOut(withDuration: 0.34)]),
            .removeFromParent(),
        ]))
        shockwave(at: point, color: color, start: 16, end: 64)
    }

    func shieldBreakEffect(at point: CGPoint) {
        let color = UIColor(red: 0.38, green: 1.0, blue: 0.72, alpha: 1)
        let glow = SKSpriteNode(texture: GlowTextures.blob)
        glow.position = point
        glow.size = CGSize(width: 42, height: 42)
        glow.blendMode = .add
        glow.color = color
        glow.colorBlendFactor = 0.95
        glow.alpha = 0.95
        glow.zPosition = 25
        addChild(glow)
        glow.run(.sequence([
            .group([.scale(to: 2.4, duration: 0.28), .fadeOut(withDuration: 0.28)]),
            .removeFromParent(),
        ]))
        burst(at: session.sim.playerPosition, color: color)
        screenFlash(color: color, alpha: 0.05)
    }

    func magneticFieldAura(tint: UIColor, radius: CGFloat, particleCount: Int) -> SKNode {
        let root = SKNode()
        let cyan = UIColor(red: 0.30, green: 0.90, blue: 1, alpha: 1)

        for index in 0..<4 {
            let scale = 0.58 + CGFloat(index) * 0.14
            let path = Self.magneticFieldPath(
                horizontal: radius * scale,
                vertical: radius * (0.52 + CGFloat(index) * 0.10),
                poleGap: 15 + CGFloat(index) * 1.5
            )
            let field = SKShapeNode(path: path)
            field.strokeColor = (index.isMultiple(of: 2) ? tint : cyan)
                .withAlphaComponent(0.34 + CGFloat(index) * 0.08)
            field.lineWidth = index == 3 ? 1.45 : 1.05
            field.lineCap = .round
            field.glowWidth = 0
            root.addChild(field)
            field.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.48, duration: 0.75 + Double(index) * 0.12),
                .fadeAlpha(to: 0.92, duration: 0.82 + Double(index) * 0.09),
            ])))
        }

        for index in 0..<max(1, particleCount) {
            let path = Self.magneticFieldPath(
                horizontal: radius * (0.64 + CGFloat(index % 3) * 0.13),
                vertical: radius * (0.56 + CGFloat(index % 3) * 0.09),
                poleGap: 16
            )
            let mote = SKShapeNode(circleOfRadius: index.isMultiple(of: 2) ? 1.8 : 1.25)
            mote.fillColor = index.isMultiple(of: 2) ? cyan : .white
            mote.strokeColor = .clear
            mote.glowWidth = 0
            mote.alpha = 0
            root.addChild(mote)
            let travel = 1.55 + Double(index % 3) * 0.24
            mote.run(.repeatForever(.sequence([
                .wait(forDuration: Double(index) * 0.24),
                .fadeAlpha(to: 0.92, duration: 0.12),
                .follow(path, asOffset: false, orientToPath: false, duration: travel),
                .fadeOut(withDuration: 0.14),
                .wait(forDuration: 0.28),
            ])))
        }

        let north = SKShapeNode(circleOfRadius: 3.2)
        north.position = CGPoint(x: 0, y: 16)
        north.fillColor = cyan
        north.strokeColor = .white.withAlphaComponent(0.65)
        north.glowWidth = 0
        root.addChild(north)

        let south = SKShapeNode(circleOfRadius: 3.2)
        south.position = CGPoint(x: 0, y: -16)
        south.fillColor = tint
        south.strokeColor = .white.withAlphaComponent(0.65)
        south.glowWidth = 0
        root.addChild(south)

        root.run(.repeatForever(.sequence([
            .scale(to: 1.035, duration: 0.85),
            .scale(to: 0.975, duration: 0.85),
        ])))
        return root
    }

    func timelineWaves(at point: CGPoint, color: UIColor, count: Int) {
        for index in 0..<max(1, count) {
            let ring = SKShapeNode(circleOfRadius: 17 + CGFloat(index) * 4)
            ring.position = point
            ring.fillColor = .clear
            ring.strokeColor = index.isMultiple(of: 2) ? color : .white
            ring.lineWidth = 2
            ring.glowWidth = 0
            ring.zPosition = 22
            ring.alpha = 0
            addChild(ring)
            ring.run(.sequence([
                .wait(forDuration: Double(index) * 0.09),
                .fadeIn(withDuration: 0.04),
                .group([
                    .scale(to: 3.6 + CGFloat(index) * 0.28, duration: 0.5),
                    .fadeOut(withDuration: 0.5),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    func orbitalArcs(at point: CGPoint, color: UIColor) {
        for index in 0..<3 {
            let path = CGMutablePath()
            let radius = CGFloat(27 + index * 11)
            path.addArc(center: .zero, radius: radius, startAngle: CGFloat(index) * 0.7, endAngle: CGFloat(index) * 0.7 + .pi * 1.25, clockwise: false)
            let arc = SKShapeNode(path: path)
            arc.position = point
            arc.strokeColor = index == 1 ? .white : color
            arc.lineWidth = 2.4
            arc.lineCap = .round
            arc.glowWidth = 0
            arc.zPosition = 22
            addChild(arc)
            arc.run(.sequence([
                .group([
                    .rotate(byAngle: index.isMultiple(of: 2) ? .pi : -.pi, duration: 0.62),
                    .scale(to: 1.75, duration: 0.62),
                    .fadeOut(withDuration: 0.62),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    func phaseAfterimages(at point: CGPoint, color: UIColor) {
        for index in 0..<4 {
            let image = SKSpriteNode(texture: GlowTextures.player)
            image.position = point
            image.size = CGSize(width: 42, height: 42)
            image.color = color
            image.colorBlendFactor = 0.65
            image.blendMode = .add
            image.alpha = 0.42
            image.zPosition = 21
            addChild(image)
            let angle = CGFloat(index) / 4 * .pi * 2
            image.run(.sequence([
                .wait(forDuration: Double(index) * 0.035),
                .group([
                    .moveBy(x: cos(angle) * 48, y: sin(angle) * 48, duration: 0.42),
                    .fadeOut(withDuration: 0.42),
                    .scale(to: 0.55, duration: 0.42),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    func screenFlash(color: UIColor, alpha: CGFloat) {
        let flash = SKSpriteNode(color: color, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.alpha = 0
        flash.blendMode = .add
        flash.zPosition = 30
        flash.isUserInteractionEnabled = false
        addChild(flash)
        flash.run(.sequence([
            .fadeAlpha(to: alpha, duration: 0.04),
            .fadeOut(withDuration: 0.20),
            .removeFromParent(),
        ]))
    }

    func shockwave(at point: CGPoint, color: UIColor, start: CGFloat = 12, end: CGFloat = 86) {
        let ring = SKShapeNode(circleOfRadius: start)
        ring.position = point
        ring.strokeColor = color
        ring.lineWidth = 3
        ring.glowWidth = 0
        ring.fillColor = .clear
        ring.zPosition = 21
        addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: end / start, duration: 0.45),
                .fadeOut(withDuration: 0.45),
            ]),
            .removeFromParent(),
        ]))
    }

}
