import SpriteKit
import UIKit

/// Asteroids break apart for real. The painted rock splits along the faults
/// that opened while it fractured, and every shard is a physics body that
/// keeps the rock's momentum, tumbles, ricochets off the walls and fades.
/// Debris is purely visual: the simulation never sees it.
extension GameScene {
    enum DebrisCategory {
        static let wall: UInt32 = 1 << 0
        static let shard: UInt32 = 1 << 1
    }

    func buildDebrisPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.speed = 1
        let bounds = SKNode()
        bounds.name = "debrisBounds"
        bounds.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size).insetBy(dx: 5, dy: 5))
        settle(bounds.physicsBody)
        addChild(bounds)
        for wall in session.level.walls {
            let rect = mapped(wall)
            guard rect.width > 1, rect.height > 1 else { continue }
            let node = SKNode()
            node.name = "debrisWall"
            node.position = CGPoint(x: rect.midX, y: rect.midY)
            node.physicsBody = SKPhysicsBody(rectangleOf: rect.size)
            settle(node.physicsBody)
            addChild(node)
        }
    }

    private func settle(_ body: SKPhysicsBody?) {
        body?.isDynamic = false
        body?.categoryBitMask = DebrisCategory.wall
        body?.collisionBitMask = 0
        body?.contactTestBitMask = 0
        body?.friction = 0.4
        body?.restitution = 0.5
    }

    // MARK: - Events

    func asteroidImpact(id: Int, material: AsteroidMaterial, at position: Vec2) {
        let worldRadius = session.sim.movers.first { $0.id == id }?.radius ?? 40
        let contact = rockContact(center: position, radius: worldRadius)
        let point = scenePoint(contact.point)
        let normal = CGVector(dx: contact.normal.x, dy: contact.normal.y)
        let radius = CGFloat(worldRadius) * worldScale
        let tint = Self.color(for: material)
        if let root = moverNodes[id] {
            root.removeAction(forKey: "impact")
            let squash = SKAction.sequence([
                .group([.scaleX(to: 1.12, duration: 0.05), .scaleY(to: 0.88, duration: 0.05)]),
                .group([.scaleX(to: 0.93, duration: 0.07), .scaleY(to: 1.07, duration: 0.07)]),
                .scale(to: 1, duration: 0.12),
            ])
            squash.timingMode = .easeOut
            root.run(squash, withKey: "impact")
        }
        if material.isMetallic {
            sparkBurst(at: point, color: Self.crackColor(for: material), count: 16, speed: radius * 7, heading: normal, spread: 1.1)
        }
        if material == .magma {
            sparkBurst(at: point, color: Self.secondaryColor(for: material), count: 8, speed: radius * 4, heading: normal, spread: 1.3)
        }
        if material.isBreakable, let art = rockArtCache[id] {
            // Start the splinters just off the surface so they never spawn inside the wall's body.
            let spawn = CGPoint(x: point.x + normal.dx * radius * 0.2, y: point.y + normal.dy * radius * 0.2)
            for _ in 0..<Int.random(in: 3...5) {
                chip(from: art, at: spawn, heading: normal, spread: 1.0, speed: radius * CGFloat.random(in: 3.5...7))
            }
        }
        rockDust(at: point, color: tint, radius: radius * 0.6, count: 8)
        shockwave(at: point, color: tint, start: max(4, radius * 0.3), end: radius * 1.5, lineWidth: 1.4)
    }

    func asteroidShatter(id: Int, material: AsteroidMaterial, at position: Vec2) {
        let point = scenePoint(position)
        let tint = Self.color(for: material)
        let accent = Self.crackColor(for: material)
        var radius = CGFloat(max(4, 40 * worldScale))
        var drift = CGVector.zero
        var turn: CGFloat = 0
        if let root = moverNodes.removeValue(forKey: id) {
            radius = CGFloat((root.userData?["diameter"] as? NSNumber)?.doubleValue ?? Double(radius * 2)) / 2
            drift = CGVector(
                dx: CGFloat((root.userData?["vx"] as? NSNumber)?.doubleValue ?? 0),
                dy: CGFloat((root.userData?["vy"] as? NSNumber)?.doubleValue ?? 0)
            )
            turn = root.childNode(withName: "rock")?.zRotation ?? 0
            root.removeFromParent()
        }
        if let art = rockArtCache[id] {
            shatter(art, at: point, rotation: turn, drift: drift)
            for _ in 0..<Int.random(in: 5...8) {
                chip(from: art, at: point, heading: nil, spread: .pi, speed: radius * CGFloat.random(in: 4...9))
            }
        }
        let flash = SKSpriteNode(texture: GlowTextures.blob)
        flash.position = point
        flash.size = CGSize(width: radius * 3.6, height: radius * 3.6)
        flash.color = accent
        flash.colorBlendFactor = 0.6
        flash.blendMode = .add
        flash.alpha = 0.95
        flash.zPosition = VisualLayer.events
        addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 1.35, duration: 0.24), .fadeOut(withDuration: 0.24)]),
            .removeFromParent(),
        ]))
        rockDust(at: point, color: tint, radius: radius, count: 22)
        sparkBurst(at: point, color: accent, count: material == .ice || material == .comet ? 10 : 18, speed: radius * 6, heading: nil, spread: .pi)
        switch material {
        case .ice: frostBurst(at: point, radius: radius)
        case .comet: frostBurst(at: point, radius: radius * 1.35)
        case .magma: emberBurst(at: point, radius: radius)
        case .geode: sparkBurst(at: point, color: Self.secondaryColor(for: material), count: 14, speed: radius * 3.5, heading: nil, spread: .pi)
        default: break
        }
        shockwave(at: point, color: accent.withAlphaComponent(0.8), start: radius * 0.9, end: radius * 3, lineWidth: 1.3)
        screenFlash(color: tint, alpha: 0.08)
    }

    /// Molten rock leaves embers that drift outward and cool for a moment.
    func emberBurst(at point: CGPoint, radius: CGFloat) {
        for _ in 0..<14 {
            let ember = SKSpriteNode(texture: GlowTextures.blob)
            let size = radius * CGFloat.random(in: 0.18...0.34)
            ember.size = CGSize(width: size, height: size)
            ember.color = UIColor(red: 1, green: CGFloat.random(in: 0.45...0.8), blue: 0.15, alpha: 1)
            ember.colorBlendFactor = 1
            ember.blendMode = .add
            ember.position = point
            ember.zPosition = VisualLayer.events - 0.5
            addChild(ember)
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let reach = radius * CGFloat.random(in: 1.2...2.8)
            let life = TimeInterval.random(in: 0.8...1.4)
            let drift = SKAction.moveBy(x: cos(angle) * reach, y: sin(angle) * reach, duration: life)
            drift.timingMode = .easeOut
            ember.run(.sequence([
                .group([drift, .fadeOut(withDuration: life), .scale(to: 0.3, duration: life)]),
                .removeFromParent(),
            ]))
        }
    }

    // MARK: - Debris

    func shatter(_ art: RockArt, at point: CGPoint, rotation: CGFloat, drift: CGVector) {
        let turn = CGAffineTransform(rotationAngle: rotation)
        for shard in art.shards {
            let offset = shard.centroid.applying(turn)
            let node = SKSpriteNode(texture: shard.texture, size: shard.size)
            node.anchorPoint = shard.anchor
            node.position = CGPoint(x: point.x + offset.x, y: point.y + offset.y)
            node.zRotation = rotation
            node.zPosition = VisualLayer.hazards + 0.4
            node.name = "rockShard"
            let body = debrisBody(hull: shard.hull, fallback: min(shard.size.width, shard.size.height) * 0.3)
            node.physicsBody = body
            addChild(node)
            let length = max(hypot(offset.x, offset.y), 0.001)
            let burst = art.shape.radius * CGFloat.random(in: 3.2...5.6)
            body.velocity = CGVector(
                dx: drift.dx * 0.7 + offset.x / length * burst,
                dy: drift.dy * 0.7 + offset.y / length * burst
            )
            body.angularVelocity = CGFloat.random(in: 2...7) * (Bool.random() ? 1 : -1)
            fadeDebris(node, after: TimeInterval.random(in: 0.7...1.05))
        }
    }

    /// A small splinter of the rock's own surface, thrown from `point`.
    func chip(from art: RockArt, at point: CGPoint, heading: CGVector?, spread: CGFloat, speed: CGFloat) {
        guard let source = art.shards.randomElement() else { return }
        let scale = CGFloat.random(in: 0.18...0.32)
        let node = SKSpriteNode(texture: source.texture, size: CGSize(width: source.size.width * scale, height: source.size.height * scale))
        node.anchorPoint = source.anchor
        node.position = point
        node.zRotation = CGFloat.random(in: 0..<(2 * .pi))
        node.zPosition = VisualLayer.hazards + 0.45
        node.name = "rockChip"
        let body = debrisBody(hull: source.hull.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }, fallback: max(1.2, min(node.size.width, node.size.height) * 0.3))
        node.physicsBody = body
        addChild(node)
        let base = heading.map { atan2($0.dy, $0.dx) } ?? CGFloat.random(in: 0..<(2 * .pi))
        let angle = base + CGFloat.random(in: -spread...spread)
        body.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
        body.angularVelocity = CGFloat.random(in: 4...12) * (Bool.random() ? 1 : -1)
        fadeDebris(node, after: TimeInterval.random(in: 0.35...0.6))
    }

    func debrisBody(hull: [CGPoint], fallback: CGFloat) -> SKPhysicsBody {
        var body: SKPhysicsBody?
        if hull.count >= 3, RockShape.area(hull) > 6 {
            let path = CGMutablePath()
            path.addLines(between: hull)
            path.closeSubpath()
            body = SKPhysicsBody(polygonFrom: path)
        }
        let debris = body ?? SKPhysicsBody(circleOfRadius: max(1, fallback))
        debris.categoryBitMask = DebrisCategory.shard
        debris.collisionBitMask = DebrisCategory.wall
        debris.contactTestBitMask = 0
        debris.fieldBitMask = 0
        debris.affectedByGravity = false
        debris.linearDamping = 1.5
        debris.angularDamping = 1.1
        debris.restitution = 0.45
        debris.friction = 0.3
        return debris
    }

    func fadeDebris(_ node: SKNode, after delay: TimeInterval) {
        node.run(.sequence([
            .wait(forDuration: delay),
            .group([.fadeOut(withDuration: 0.45), .scale(to: 0.55, duration: 0.45)]),
            .removeFromParent(),
        ]))
    }

    // MARK: - Particles

    func rockDust(at point: CGPoint, color: UIColor, radius: CGFloat, count: Int) {
        let dust = SKEmitterNode()
        dust.particleTexture = GlowTextures.blob
        dust.position = point
        dust.zPosition = VisualLayer.hazards + 0.3
        dust.particleBirthRate = 2_000
        dust.numParticlesToEmit = count
        dust.particleLifetime = 0.9
        dust.particleLifetimeRange = 0.35
        dust.emissionAngleRange = .pi * 2
        dust.particleSpeed = radius * 2.2
        dust.particleSpeedRange = radius * 1.6
        dust.particlePositionRange = CGVector(dx: radius * 0.8, dy: radius * 0.8)
        dust.particleScale = radius / 128 * 0.9
        dust.particleScaleRange = radius / 128 * 0.4
        dust.particleScaleSpeed = radius / 128 * 0.7
        dust.particleAlpha = 0.34
        dust.particleAlphaSpeed = -0.38
        dust.particleColor = color.blended(with: .white, amount: 0.35)
        dust.particleColorBlendFactor = 1
        dust.particleBlendMode = .add
        addChild(dust)
        dust.run(.sequence([.wait(forDuration: 1.4), .removeFromParent()]))
    }

    func sparkBurst(at point: CGPoint, color: UIColor, count: Int, speed: CGFloat, heading: CGVector?, spread: CGFloat) {
        let sparks = SKEmitterNode()
        sparks.particleTexture = GlowTextures.blob
        sparks.position = point
        sparks.zPosition = VisualLayer.events - 0.5
        sparks.particleBirthRate = 3_000
        sparks.numParticlesToEmit = count
        sparks.particleLifetime = 0.38
        sparks.particleLifetimeRange = 0.18
        sparks.emissionAngle = heading.map { atan2($0.dy, $0.dx) } ?? 0
        sparks.emissionAngleRange = spread * 2
        sparks.particleSpeed = speed
        sparks.particleSpeedRange = speed * 0.6
        sparks.particleScale = 0.055
        sparks.particleScaleRange = 0.025
        sparks.particleScaleSpeed = -0.1
        sparks.particleAlpha = 1
        sparks.particleAlphaSpeed = -2.2
        sparks.particleColor = color.blended(with: .white, amount: 0.3)
        sparks.particleColorBlendFactor = 1
        sparks.particleBlendMode = .add
        addChild(sparks)
        sparks.run(.sequence([.wait(forDuration: 0.8), .removeFromParent()]))
    }

    func frostBurst(at point: CGPoint, radius: CGFloat) {
        let frost = SKEmitterNode()
        frost.particleTexture = GlowTextures.snowflakeParticle
        frost.position = point
        frost.zPosition = VisualLayer.events - 0.4
        frost.particleBirthRate = 2_000
        frost.numParticlesToEmit = 14
        frost.particleLifetime = 0.9
        frost.particleLifetimeRange = 0.3
        frost.emissionAngleRange = .pi * 2
        frost.particleSpeed = radius * 3.2
        frost.particleSpeedRange = radius * 1.8
        frost.particleScale = 0.1
        frost.particleScaleRange = 0.05
        frost.particleScaleSpeed = -0.06
        frost.particleRotationRange = .pi * 2
        frost.particleRotationSpeed = 2
        frost.particleAlpha = 0.9
        frost.particleAlphaSpeed = -1
        frost.particleBlendMode = .add
        addChild(frost)
        frost.run(.sequence([.wait(forDuration: 1.3), .removeFromParent()]))
    }

    // MARK: - Contact

    /// The closest solid surface to a rock that just bounced, and the
    /// direction pointing from that surface back into open space.
    func rockContact(center: Vec2, radius: Double) -> (point: Vec2, normal: Vec2) {
        var best = (distance: Double.infinity, point: center, normal: Vec2(x: 0, y: 1))
        func consider(_ surface: Vec2) {
            let offset = center - surface
            let distance = offset.length
            guard distance > 0.0001, distance < best.distance else { return }
            best = (distance, surface, offset / distance)
        }
        for wall in session.level.walls { consider(wall.closestPoint(to: center)) }
        for gate in session.sim.gates where gate.solid { consider(gate.area.closestPoint(to: center)) }
        let inset = session.sim.config.edgeInset
        consider(Vec2(x: inset, y: center.y))
        consider(Vec2(x: session.level.worldWidth - inset, y: center.y))
        consider(Vec2(x: center.x, y: inset))
        consider(Vec2(x: center.x, y: session.level.worldHeight - inset))
        guard best.distance < radius * 1.6 else {
            return (center, best.normal)
        }
        return (best.point, best.normal)
    }
}
