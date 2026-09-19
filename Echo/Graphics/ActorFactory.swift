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
            let locator = SKNode()
            locator.name = "playerLocator"
            locator.zPosition = 3
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -5, y: 4))
            path.addLine(to: CGPoint(x: 0, y: -4))
            path.addLine(to: CGPoint(x: 5, y: 4))
            let pointer = SKShapeNode(path: path)
            pointer.name = "pointer"
            pointer.strokeColor = VisualPalette.playerRim
            pointer.fillColor = .clear
            pointer.lineWidth = 1.8
            pointer.lineCap = .round
            pointer.lineJoin = .round
            pointer.glowWidth = 0
            locator.addChild(pointer)
            locator.position = CGPoint(x: 0, y: radius + 11)
            root.addChild(locator)
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
