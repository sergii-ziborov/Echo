import SpriteKit

enum ActorKind {
    case player
    case echo
    case ghost
}

@MainActor
enum ActorFactory {
    static func make(kind: ActorKind, radius: CGFloat) -> SKNode {
        let root = SKNode()
        root.zPosition = VisualLayer.actors
        let coreTint: UIColor
        let rimTint: UIColor
        let glowTint: UIColor
        switch kind {
        case .player:
            coreTint = VisualPalette.playerCore
            rimTint = VisualPalette.playerRim
            glowTint = VisualPalette.playerGlow
        case .echo:
            coreTint = VisualPalette.echoCore
            rimTint = VisualPalette.echoRim
            glowTint = VisualPalette.echoRim
        case .ghost:
            coreTint = VisualPalette.ghostCore
            rimTint = VisualPalette.ghostRim
            glowTint = VisualPalette.ghostRim
        }

        let glow = SKSpriteNode(texture: GlowTextures.glowMask)
        glow.name = "halo"
        glow.size = CGSize(width: radius * 2 * VisualStyle.glowRadiusMul, height: radius * 2 * VisualStyle.glowRadiusMul)
        glow.color = glowTint
        glow.colorBlendFactor = 1
        glow.alpha = VisualStyle.glowAlpha
        glow.blendMode = .add
        glow.zPosition = 0

        let body = SKShapeNode(circleOfRadius: radius)
        body.name = "body"
        body.fillColor = coreTint
        body.strokeColor = rimTint
        body.lineWidth = max(1.0, radius * 0.09)
        body.glowWidth = 0
        body.blendMode = .alpha
        body.zPosition = 1

        let sheen = SKShapeNode(circleOfRadius: radius * 0.22)
        sheen.name = "sheen"
        sheen.fillColor = UIColor.white.withAlphaComponent(0.55)
        sheen.strokeColor = .clear
        sheen.glowWidth = 0
        sheen.position = CGPoint(x: -radius * 0.22, y: radius * 0.24)
        sheen.zPosition = 2
        sheen.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.38, duration: 0.9),
            .fadeAlpha(to: 0.62, duration: 0.9),
        ])))

        root.addChild(glow)
        root.addChild(body)
        root.addChild(sheen)

        if kind == .player {
            let idleAura = SKSpriteNode(texture: GlowTextures.glowMask)
            idleAura.name = "idleAura"
            idleAura.size = CGSize(width: radius * 2.55, height: radius * 2.55)
            idleAura.color = glowTint
            idleAura.colorBlendFactor = 1
            idleAura.alpha = 0
            idleAura.blendMode = .add
            idleAura.zPosition = 0.4
            root.addChild(idleAura)
        }

        let shell = SKShapeNode(circleOfRadius: radius + 5)
        shell.name = "statusShell"
        shell.fillColor = .clear
        shell.strokeColor = .clear
        shell.lineWidth = 1.5
        shell.glowWidth = 0
        shell.zPosition = VisualLayer.shells - VisualLayer.actors
        root.addChild(shell)
        return root
    }
}
