import SpriteKit
import UIKit

/// Region landmarks. Each one says at a glance which part of space the
/// Signal has reached, sits in the same place on every map of its region,
/// and grows a little as the Road crosses the region.
extension Backdrop {
    private var short: CGFloat { min(size.width, size.height) }
    /// From 0.85× on a region's first map to 1.15× on its last.
    private var approach: CGFloat { 0.85 + 0.3 * progress }

    func buildLandmark() {
        let layer = SKNode()
        layer.zPosition = -2
        root.addChild(layer)
        switch landmark {
        case .giant(let base, let accent, let rings):
            let radius = short * 0.27 * approach * budget.planetScale
            layer.addChild(bandedWorld(radius: radius, at: CGPoint(x: radius * 0.1, y: size.height * 0.16 + radius * 0.4), base: tone(base), accent: tone(accent), rings: rings))
        case .sun(let core, let corona, let fraction):
            let giant = fraction > 0.4
            let radius = short * CGFloat(fraction) * approach * (giant ? 1 : budget.planetScale)
            let spot = giant
                ? CGPoint(x: size.width - radius * 0.35, y: radius * 0.25)
                : CGPoint(x: size.width - radius * 1.6, y: size.height - radius * 2.6)
            landmarkOnLeft = false
            layer.addChild(sunNode(radius: radius, at: spot, core: tone(core), corona: tone(corona), alpha: giant ? 0.42 : 0.7))
        case .crackedMoon(let base, let glow):
            let radius = short * 0.2 * approach * budget.planetScale
            layer.addChild(crackedMoon(radius: radius, at: CGPoint(x: radius * 0.9, y: size.height - radius * 2.4), base: tone(base), glow: tone(glow)))
        case .brokenWorld(let base, let glow):
            let radius = short * 0.26 * approach * budget.planetScale
            landmarkOnLeft = false
            layer.addChild(brokenWorld(radius: radius, at: CGPoint(x: size.width - radius * 0.15, y: size.height * 0.3), base: tone(base), glow: tone(glow)))
        case .pulsar(let color):
            layer.addChild(pulsar(at: CGPoint(x: size.width * 0.28, y: size.height * 0.68), color: tone(color)))
        case .tear(let color):
            layer.addChild(tear(color: tone(color)))
        case .blackHole(let disc):
            let radius = short * 0.1 * approach * budget.planetScale
            landmarkOnLeft = false
            layer.addChild(blackHole(radius: radius, at: CGPoint(x: size.width * 0.7, y: size.height * 0.66), disc: tone(disc)))
        case .twinGiants(let base, let accent):
            let radius = short * 0.2 * approach * budget.planetScale
            let bands = Self.bandTexture(size: CGSize(width: radius * 4, height: radius * 2), base: tone(base), accent: tone(accent), scale: budget.textureScale, rng: &rng)
            let left = bandedWorld(radius: radius, at: CGPoint(x: radius * 0.2, y: size.height * 0.58), base: tone(base), accent: tone(accent), rings: false, bands: bands)
            let right = bandedWorld(radius: radius, at: CGPoint(x: size.width - radius * 0.2, y: size.height * 0.58), base: tone(base), accent: tone(accent), rings: false, bands: bands)
            right.xScale = -1
            layer.addChild(left)
            layer.addChild(right)
        case .candyWorld(let base, let accent):
            let radius = short * 0.24 * approach * budget.planetScale
            layer.addChild(candyWorld(radius: radius, at: CGPoint(x: radius * 0.3, y: size.height * 0.2), base: tone(base), accent: tone(accent)))
        case .dawn(let core, let corona):
            layer.addChild(dawn(core: tone(core), corona: tone(corona)))
        }
    }

    private func tone(_ rgb: RGB) -> UIColor {
        UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
    }

    // MARK: - Worlds

    /// Bands scrolling inside a round mask, under a fixed terminator, read as
    /// a giant slowly turning.
    func bandedWorld(radius: CGFloat, at spot: CGPoint, base: UIColor, accent: UIColor, rings: Bool, bands: SKTexture? = nil) -> SKNode {
        let world = SKNode()
        world.position = spot
        world.alpha = budget.planetAlpha
        let crop = SKCropNode()
        let mask = SKShapeNode(circleOfRadius: radius)
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        let tile = CGSize(width: radius * 4, height: radius * 2)
        let texture = bands ?? Self.bandTexture(size: tile, base: base, accent: accent, scale: budget.textureScale, rng: &rng)
        let strip = SKNode()
        for index in 0..<2 {
            let sprite = SKSpriteNode(texture: texture, size: tile)
            sprite.anchorPoint = CGPoint(x: 0, y: 0.5)
            sprite.position = CGPoint(x: -radius + CGFloat(index) * tile.width, y: 0)
            strip.addChild(sprite)
        }
        crop.addChild(strip)
        world.addChild(crop)
        if motion {
            strip.run(.repeatForever(.sequence([
                .moveBy(x: -tile.width, y: 0, duration: 130),
                .moveBy(x: tile.width, y: 0, duration: 0),
            ])))
        }
        shade(world, radius: radius)
        if rings {
            let ring = SKShapeNode(ellipseOf: CGSize(width: radius * 3.3, height: radius * 0.7))
            ring.strokeColor = accent.withAlphaComponent(0.34)
            ring.lineWidth = max(1.5, radius * 0.05)
            ring.zRotation = -0.3
            world.addChild(ring)
        }
        return world
    }

    /// Night side and a lit rim, turned toward the middle of the arena.
    private func shade(_ world: SKNode, radius: CGFloat) {
        let facing = atan2(size.height / 2 - world.position.y, size.width / 2 - world.position.x)
        let night = SKSpriteNode(texture: Self.terminatorTexture(sky: palette.sky, scale: budget.textureScale), size: CGSize(width: radius * 2.02, height: radius * 2.02))
        night.zRotation = facing
        world.addChild(night)
        let rim = SKSpriteNode(texture: Self.rimTexture, size: CGSize(width: radius * 2.5, height: radius * 2.5))
        rim.color = palette.glow
        rim.colorBlendFactor = 1
        rim.blendMode = .add
        rim.alpha = 0.55
        rim.zRotation = facing
        world.addChild(rim)
    }

    private func sunNode(radius: CGFloat, at spot: CGPoint, core: UIColor, corona: UIColor, alpha: CGFloat) -> SKNode {
        let sun = SKNode()
        sun.position = spot
        let halo = SKSpriteNode(texture: Self.softDisc, size: CGSize(width: radius * 3.4, height: radius * 3.4))
        halo.color = corona
        halo.colorBlendFactor = 1
        halo.blendMode = .add
        halo.alpha = 0.22
        sun.addChild(halo)
        let disc = SKSpriteNode(texture: Self.sunTexture(core: core, corona: corona, scale: budget.textureScale, rng: &rng), size: CGSize(width: radius * 2, height: radius * 2))
        disc.alpha = alpha
        sun.addChild(disc)
        guard motion else { return sun }
        disc.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 260)))
        halo.run(.repeatForever(.sequence([.fadeAlpha(to: 0.32, duration: 4), .fadeAlpha(to: 0.18, duration: 5)])))
        return sun
    }

    private func crackedMoon(radius: CGFloat, at spot: CGPoint, base: UIColor, glow: UIColor) -> SKNode {
        let moon = SKNode()
        moon.position = spot
        moon.alpha = min(0.7, budget.planetAlpha + 0.1)
        var cracks = CGMutablePath() as CGPath
        let surface = Self.moonTexture(base: base, glow: glow, scale: budget.textureScale, cracks: &cracks, rng: &rng)
        moon.addChild(SKSpriteNode(texture: surface, size: CGSize(width: radius * 2, height: radius * 2)))
        shade(moon, radius: radius)
        let light = SKSpriteNode(texture: Self.crackGlowTexture(cracks, glow: glow, scale: budget.textureScale), size: CGSize(width: radius * 2, height: radius * 2))
        light.blendMode = .add
        light.alpha = 0.5
        moon.addChild(light)
        if motion {
            light.run(.repeatForever(.sequence([.fadeAlpha(to: 0.85, duration: 3), .fadeAlpha(to: 0.35, duration: 3.5)])))
        }
        return moon
    }

    /// One banded world with a glowing break across it, trailing its rubble.
    private func brokenWorld(radius: CGFloat, at spot: CGPoint, base: UIColor, glow: UIColor) -> SKNode {
        let world = bandedWorld(radius: radius, at: spot, base: base, accent: glow.blended(with: base, amount: 0.6), rings: false)
        let rift = SKSpriteNode(texture: Self.faultTexture(glow: glow, scale: budget.textureScale, rng: &rng), size: CGSize(width: radius * 2, height: radius * 2))
        rift.blendMode = .add
        rift.alpha = 0.9
        world.addChild(rift)
        let tilt = SKNode()
        tilt.yScale = 0.28
        tilt.zRotation = 0.25
        let rubble = SKSpriteNode(texture: Self.rubbleTexture(tint: base.blended(with: .white, amount: 0.25), scale: budget.textureScale, rng: &rng), size: CGSize(width: radius * 3.8, height: radius * 3.8))
        tilt.addChild(rubble)
        world.addChild(tilt)
        if motion { rubble.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 120))) }
        return world
    }

    /// A dead star turning like a lighthouse lamp.
    private func pulsar(at spot: CGPoint, color: UIColor) -> SKNode {
        let star = SKNode()
        star.position = spot
        let glow = SKSpriteNode(texture: Self.softDisc, size: CGSize(width: short * 0.24, height: short * 0.24))
        glow.color = color
        glow.colorBlendFactor = 1
        glow.blendMode = .add
        glow.alpha = 0.3
        star.addChild(glow)
        let core = SKSpriteNode(texture: Self.softDisc, size: CGSize(width: short * 0.05, height: short * 0.05))
        core.blendMode = .add
        star.addChild(core)
        let shell = SKShapeNode(circleOfRadius: short * 0.15)
        shell.strokeColor = color.withAlphaComponent(0.14)
        shell.lineWidth = 2
        star.addChild(shell)
        let beams = SKNode()
        for angle in [0, CGFloat.pi] {
            let beam = SKSpriteNode(texture: Self.streakTexture, size: CGSize(width: short * 0.9, height: max(2, short * 0.012)))
            beam.anchorPoint = CGPoint(x: 1, y: 0.5)
            beam.zRotation = angle
            beam.color = color.blended(with: .white, amount: 0.4)
            beam.colorBlendFactor = 1
            beam.blendMode = .add
            beam.alpha = 0.14
            beams.addChild(beam)
        }
        star.addChild(beams)
        if motion {
            beams.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 12)))
            glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.4, duration: 0.6), .fadeAlpha(to: 0.24, duration: 0.6)])))
        }
        return star
    }

    /// Torn nebula clouds with a bright tear running through them.
    private func tear(color: UIColor) -> SKNode {
        let region = SKNode()
        landmarkOnLeft = true
        let violet = UIColor(red: 0.55, green: 0.3, blue: 1, alpha: 1)
        for index in 0..<5 {
            let cloud = SKSpriteNode(texture: Self.softDisc)
            let side = short * CGFloat.random(in: 0.4...0.75, using: &rng)
            cloud.size = CGSize(width: side, height: side * 0.7)
            cloud.color = index.isMultiple(of: 2) ? color : violet
            cloud.colorBlendFactor = 1
            cloud.blendMode = .add
            cloud.alpha = CGFloat.random(in: 0.1...0.18, using: &rng)
            cloud.position = CGPoint(x: size.width * CGFloat.random(in: 0.05...0.6, using: &rng), y: size.height * CGFloat.random(in: 0.55...0.9, using: &rng))
            cloud.zRotation = CGFloat.random(in: -0.6...0.6, using: &rng)
            region.addChild(cloud)
            if motion {
                cloud.run(.repeatForever(.sequence([
                    .moveBy(x: CGFloat.random(in: -18...18, using: &rng), y: CGFloat.random(in: -12...12, using: &rng), duration: 14),
                    .moveBy(x: CGFloat.random(in: -18...18, using: &rng), y: CGFloat.random(in: -12...12, using: &rng), duration: 14),
                ])))
            }
        }
        let length = short * 0.95 * approach
        let crack = SKSpriteNode(texture: Self.tearTexture(glow: color, scale: budget.textureScale, rng: &rng), size: CGSize(width: length, height: length * 0.18))
        crack.position = CGPoint(x: size.width * 0.34, y: size.height * 0.74)
        crack.zRotation = -0.55
        crack.blendMode = .add
        crack.alpha = 0.42
        region.addChild(crack)
        if motion {
            crack.run(.repeatForever(.sequence([.fadeAlpha(to: 0.6, duration: 3.2), .fadeAlpha(to: 0.3, duration: 3.6)])))
        }
        return region
    }

    /// The shadow sits in front of the far side of the disc and behind the near side.
    private func blackHole(radius: CGFloat, at spot: CGPoint, disc: UIColor) -> SKNode {
        let hole = SKNode()
        hole.position = spot
        hole.alpha = min(0.85, budget.planetAlpha + 0.3)
        let lens = SKSpriteNode(texture: Self.softDisc, size: CGSize(width: radius * 7, height: radius * 7))
        lens.color = disc
        lens.colorBlendFactor = 1
        lens.blendMode = .add
        lens.alpha = 0.12
        hole.addChild(lens)
        let texture = Self.accretionTexture(tint: disc, scale: budget.textureScale, rng: &rng)
        let spin = SKAction.repeatForever(.rotate(byAngle: -.pi * 2, duration: 30))
        func discLayer(front: Bool) -> SKNode {
            let tilt = SKNode()
            tilt.yScale = 0.3
            tilt.zRotation = -0.22
            let ring = SKSpriteNode(texture: texture, size: CGSize(width: radius * 5.4, height: radius * 5.4))
            ring.blendMode = .add
            if motion { ring.run(spin) }
            guard front else {
                tilt.addChild(ring)
                return tilt
            }
            let crop = SKCropNode()
            let mask = SKSpriteNode(color: .white, size: CGSize(width: radius * 6, height: radius * 3))
            mask.position = CGPoint(x: 0, y: -radius * 1.5)
            crop.maskNode = mask
            crop.addChild(ring)
            tilt.addChild(crop)
            return tilt
        }
        hole.addChild(discLayer(front: false))
        let shadow = SKShapeNode(circleOfRadius: radius)
        shadow.fillColor = UIColor(white: 0, alpha: 1)
        shadow.strokeColor = disc.blended(with: .white, amount: 0.5).withAlphaComponent(0.85)
        shadow.lineWidth = max(1, radius * 0.08)
        shadow.glowWidth = 0
        hole.addChild(shadow)
        hole.addChild(discLayer(front: true))
        return hole
    }

    private func candyWorld(radius: CGFloat, at spot: CGPoint, base: UIColor, accent: UIColor) -> SKNode {
        let world = bandedWorld(radius: radius, at: spot, base: base, accent: accent, rings: false)
        let moon = SKShapeNode(circleOfRadius: radius * 0.14)
        moon.fillColor = accent.blended(with: .white, amount: 0.5)
        moon.strokeColor = .clear
        moon.position = CGPoint(x: radius * 1.6, y: 0)
        world.addChild(moon)
        if motion {
            let orbit = CGPath(ellipseIn: CGRect(x: -radius * 1.6, y: -radius * 0.5, width: radius * 3.2, height: radius * 1), transform: nil)
            moon.run(.repeatForever(.follow(orbit, asOffset: false, orientToPath: false, duration: 22)))
        }
        return world
    }

    /// The last dawn: a star rising over the bottom edge, its rays fanning up.
    private func dawn(core: UIColor, corona: UIColor) -> SKNode {
        let radius = short * 0.9 * approach
        let spot = CGPoint(x: size.width * 0.5, y: -radius * 0.72)
        let sun = sunNode(radius: radius, at: spot, core: core, corona: corona, alpha: 0.45)
        let rays = SKNode()
        for index in 0..<7 {
            let ray = SKSpriteNode(texture: Self.sweepTexture, size: CGSize(width: radius * 0.16, height: radius * 3.2))
            ray.anchorPoint = CGPoint(x: 0.5, y: 0)
            ray.zRotation = CGFloat(index - 3) * 0.28
            ray.color = corona
            ray.colorBlendFactor = 1
            ray.blendMode = .add
            ray.alpha = 0.06
            rays.addChild(ray)
        }
        sun.addChild(rays)
        if motion {
            rays.run(.repeatForever(.sequence([
                .rotate(byAngle: 0.12, duration: 40),
                .rotate(byAngle: -0.12, duration: 40),
            ])))
        }
        return sun
    }
}
