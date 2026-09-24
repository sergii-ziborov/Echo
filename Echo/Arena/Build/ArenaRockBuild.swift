import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func buildMovers() {
        for mover in session.sim.movers {
            addMoverNode(for: mover)
        }
    }

    /// Every rock is painted from a seed drawn once per scene build, so a
    /// restart shows new asteroids while a rewind or replay brings back the
    /// exact rock that was on screen.
    func rockArt(for mover: MoverState, radius: CGFloat) -> RockArt {
        if let art = rockArtCache[mover.id], abs(art.shape.radius - radius) < 0.5 {
            return art
        }
        let still: Bool = {
            if case .stationary = mover.path { return true }
            return false
        }()
        let art = RockPainter.art(
            material: mover.material,
            radius: radius,
            seed: rockSeed ^ (UInt64(truncatingIfNeeded: mover.id) &* 0x9E37_79B9_7F4A_7C15),
            still: still,
            scale: view?.contentScaleFactor ?? 3
        )
        rockArtCache[mover.id] = art
        return art
    }

    func addMoverNode(for mover: MoverState) {
        guard moverNodes[mover.id] == nil else { return }
        let radius = max(4, CGFloat(mover.radius) * worldScale)
        let diameter = radius * 2
        let art = rockArt(for: mover, radius: radius)
        let tint = Self.color(for: mover.material)
        let root = SKNode()
        root.zPosition = VisualLayer.hazards
        root.position = scenePoint(mover.position)
        root.name = "asteroid-\(mover.id)"
        root.userData = ["diameter": NSNumber(value: Double(diameter))]

        let glow = SKSpriteNode(texture: GlowTextures.blob)
        glow.size = CGSize(width: diameter * 1.95, height: diameter * 1.95)
        glow.blendMode = .add
        glow.color = Self.secondaryColor(for: mover.material)
        glow.colorBlendFactor = 0.55
        glow.alpha = mover.material == .crystal ? 0.24 : 0.17
        glow.name = "glow"
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: glow.alpha + 0.08, duration: 0.9),
            .fadeAlpha(to: glow.alpha, duration: 1.0),
        ])))

        let body = SKNode()
        body.name = "rock"
        let surface = SKSpriteNode(texture: art.texture, size: art.canvas)
        surface.name = "surface"
        body.addChild(surface)
        let seam = Self.crackColor(for: mover.material)
        for (index, fault) in art.shape.faults.enumerated() where mover.material.isBreakable {
            let path = CGMutablePath()
            path.addLines(between: fault)
            let crack = SKShapeNode(path: path)
            crack.name = "fault"
            crack.strokeColor = seam
            crack.lineWidth = max(1, radius * 0.055)
            crack.lineCap = .round
            crack.lineJoin = .round
            crack.glowWidth = 0
            crack.alpha = 0
            crack.zPosition = 1
            crack.userData = ["threshold": NSNumber(value: Double(index + 1) / Double(art.shape.faults.count + 1))]
            let bloom = SKShapeNode(path: path)
            bloom.strokeColor = seam.withAlphaComponent(0.32)
            bloom.lineWidth = crack.lineWidth * 3.2
            bloom.lineCap = .round
            bloom.lineJoin = .round
            bloom.glowWidth = 0
            bloom.blendMode = .add
            bloom.zPosition = -0.1
            crack.addChild(bloom)
            body.addChild(crack)
        }
        body.zRotation = art.phase
        if art.spin > 0 {
            body.run(.repeatForever(.rotate(byAngle: .pi * 2 * art.spinDirection, duration: art.spin)))
        }

        root.addChild(glow)
        root.addChild(body)
        root.addChild(makeMotionEmitter(color: tint, emphasis: min(3.2, max(1.6, radius / 8))))
        addChild(root)
        moverNodes[mover.id] = root
    }

    static func crackColor(for material: AsteroidMaterial) -> UIColor {
        switch material {
        case .basalt: UIColor(red: 1, green: 0.58, blue: 0.22, alpha: 1)
        case .ice: UIColor(red: 0.86, green: 0.98, blue: 1, alpha: 1)
        case .crystal: UIColor(red: 0.50, green: 0.97, blue: 1, alpha: 1)
        case .alloy: UIColor(red: 1, green: 0.80, blue: 0.36, alpha: 1)
        }
    }
}
