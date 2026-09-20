import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func asteroidFragments(at point: CGPoint, color: UIColor, count: Int, distance: CGFloat) {
        for index in 0..<max(1, count) {
            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2 + CGFloat(index % 3) * 0.16
            let radius = 2.2 + CGFloat(index % 3) * 1.35
            let fragment = SKShapeNode(path: Self.polygonPath(radius: radius, sides: index.isMultiple(of: 2) ? 4 : 5))
            fragment.position = CGPoint(

                x: point.x + cos(angle) * 5,
                y: point.y + sin(angle) * 5
            )
            fragment.fillColor = index.isMultiple(of: 4) ? .white : color
            fragment.strokeColor = color.withAlphaComponent(0.55)
            fragment.lineWidth = 0.8
            fragment.glowWidth = 0
            fragment.zPosition = 23
            addChild(fragment)

            let travel = distance * (0.72 + CGFloat(index % 4) * 0.11)
            fragment.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * travel, y: sin(angle) * travel, duration: 0.38),
                    .rotate(byAngle: index.isMultiple(of: 2) ? .pi : -.pi, duration: 0.38),
                    .scale(to: 0.18, duration: 0.38),
                    .fadeOut(withDuration: 0.38),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    func polygonWave(
        at point: CGPoint,
        sides: Int,
        color: UIColor,
        radius: CGFloat,
        scale: CGFloat,
        delay: TimeInterval = 0
    ) {
        let polygon = SKShapeNode(path: Self.polygonPath(radius: radius, sides: sides))
        polygon.position = point
        polygon.fillColor = color.withAlphaComponent(0.07)
        polygon.strokeColor = color
        polygon.lineWidth = 2.2
        polygon.glowWidth = 0
        polygon.zPosition = 22
        polygon.setScale(0.75)
        polygon.alpha = 0
        addChild(polygon)
        polygon.run(.sequence([
            .wait(forDuration: delay),
            .fadeIn(withDuration: 0.05),
            .group([
                .scale(to: scale, duration: 0.52),
                .fadeOut(withDuration: 0.52),
                .rotate(byAngle: .pi / 5, duration: 0.52),
            ]),
            .removeFromParent(),
        ]))
    }

    func speedStreaks(at point: CGPoint, color: UIColor) {
        let raw = session.sim.lastVelocity.normalized()
        let direction = raw.length > 0.1 ? raw : Vec2(x: 0, y: 1)
        let angle = CGFloat(atan2(direction.y, direction.x)) - .pi / 2
        let perpendicular = Vec2(x: -direction.y, y: direction.x)
        for index in 0..<11 {
            let lateral = Double(index - 5) * 6.5
            let streak = SKShapeNode(rectOf: CGSize(width: 2.2, height: CGFloat(16 + index % 4 * 5)), cornerRadius: 1)
            streak.position = CGPoint(
                x: point.x + CGFloat(perpendicular.x * lateral),
                y: point.y + CGFloat(perpendicular.y * lateral)
            )
            streak.zRotation = angle
            streak.fillColor = index.isMultiple(of: 4) ? .white : color
            streak.strokeColor = .clear
            streak.glowWidth = 0
            streak.zPosition = 22
            addChild(streak)
            streak.run(.sequence([
                .group([
                    .moveBy(x: CGFloat(-direction.x * 86), y: CGFloat(-direction.y * 86), duration: 0.32),
                    .fadeOut(withDuration: 0.32),
                    .scaleY(to: 0.35, duration: 0.32),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    func electricArcBurst(at point: CGPoint, color: UIColor, count: Int) {
        for index in 0..<max(1, count) {
            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2
                + sin(CGFloat(index + 7) * 2.17) * 0.20
            let bolt = lightningBoltNode(
                angle: angle,
                inner: 15,
                outer: 70,
                baseSeed: index + 71,
                color: color,
                delay: 0,
                persistent: false
            )
            bolt.position = point
            bolt.zPosition = 23
            bolt.alpha = 0
            addChild(bolt)
            bolt.run(.sequence([
                .fadeAlpha(to: 0.95, duration: 0.035 + Double(index % 2) * 0.02),
                .wait(forDuration: 0.06),
                .group([.fadeOut(withDuration: 0.24), .scale(to: 1.18, duration: 0.24)]),
                .removeFromParent(),
            ]))
        }
    }

    func lightningBoltNode(
        angle: CGFloat,
        inner: CGFloat,
        outer: CGFloat,
        baseSeed: Int,
        color: UIColor,
        delay: TimeInterval,
        persistent: Bool
    ) -> SKNode {
        let root = SKNode()
        let initialPath = Self.lightningPath(
            angle: angle,
            inner: inner,
            outer: outer,
            segments: 9,
            seed: baseSeed
        )
        let bloom = SKShapeNode(path: initialPath)
        bloom.name = "bloom"
        bloom.strokeColor = color.withAlphaComponent(0.46)
        bloom.lineWidth = 6.5
        bloom.lineCap = .round
        bloom.lineJoin = .round
        bloom.glowWidth = 0
        let core = SKShapeNode(path: initialPath)
        core.name = "core"
        core.strokeColor = UIColor.white.withAlphaComponent(0.96)
        core.lineWidth = 1.15
        core.lineCap = .round
        core.lineJoin = .round
        core.glowWidth = 2
        root.addChild(bloom)
        root.addChild(core)

        if persistent {
            var frame = 0
            let redraw = SKAction.run { [weak bloom, weak core] in
                frame += 1
                let path = Self.lightningPath(
                    angle: angle + sin(CGFloat(frame + baseSeed) * 1.17) * 0.08,
                    inner: inner,
                    outer: outer,
                    segments: 9,
                    seed: baseSeed + frame * 29
                )
                bloom?.path = path
                core?.path = path
            }
            root.alpha = 0.24
            root.run(.repeatForever(.sequence([
                .wait(forDuration: delay),
                redraw,
                .fadeAlpha(to: 1, duration: 0.018),
                .wait(forDuration: 0.072),
                .fadeAlpha(to: 0.24, duration: 0.065),
                .wait(forDuration: 0.045 + Double(baseSeed % 3) * 0.027),
            ])))
        }
        return root
    }

    func winterBurst(at point: CGPoint, color: UIColor) {
        let flash = SKSpriteNode(texture: GlowTextures.snowflakeParticle)
        flash.position = point
        flash.size = CGSize(width: 74, height: 74)
        flash.color = .white
        flash.colorBlendFactor = 0.18
        flash.blendMode = .add
        flash.zPosition = 24
        flash.setScale(0.24)
        flash.alpha = 0.95
        addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 1.65, duration: 0.38), .fadeAlpha(to: 0.44, duration: 0.38)]),
            .group([.scale(to: 2.05, duration: 0.40), .fadeOut(withDuration: 0.40)]),
            .removeFromParent(),
        ]))

        let snow = SKEmitterNode()
        snow.particleTexture = GlowTextures.snowflakeParticle
        snow.position = point
        snow.zPosition = 24
        snow.particleBirthRate = 95
        snow.numParticlesToEmit = 34
        snow.particleLifetime = 1.55
        snow.particleLifetimeRange = 0.40
        snow.emissionAngleRange = .pi * 2
        snow.particleSpeed = 72
        snow.particleSpeedRange = 34
        snow.particleScale = 0.11
        snow.particleScaleRange = 0.055
        snow.particleScaleSpeed = -0.045
        snow.particleRotationRange = .pi * 2
        snow.particleRotationSpeed = 0.75
        snow.particleAlpha = 0.92
        snow.particleAlphaSpeed = -0.48
        snow.particleBlendMode = .add
        addChild(snow)
        snow.run(.sequence([.wait(forDuration: 2.1), .removeFromParent()]))

        shockwave(at: point, color: color, start: 18, end: 154)
    }

}
