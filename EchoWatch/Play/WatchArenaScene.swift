import SpriteKit
import UIKit
import WatchKit

/// Draws a wrist run with the phone's comet, gems, ability tokens and
/// procedural rocks, trimmed for the watch GPU. The scene is built on its
/// first frame because watchOS has no SKView to announce it.
@MainActor
final class WatchArenaScene: SKScene {
    let run: WatchRun
    private var built = false
    private var scale: CGFloat = 1
    private var trails: TrailRenderer?
    private let trailLayer = SKNode()
    let player = SKNode()
    private var echoNodes: [SKNode] = []
    private var ghostNodes: [SKNode] = []
    private var sparkNodes: [Int: SKNode] = [:]
    private var bonusNodes: [Int: SKNode] = [:]
    var rockNodes: [Int: SKNode] = [:]
    var rockArt: [Int: RockArt] = [:]
    private var laserNodes: [Int: SKShapeNode] = [:]
    private var gateNodes: [Int: SKShapeNode] = [:]
    private let exitNode = SKNode()
    private var lastTime: TimeInterval = 0
    private let seed = UInt64.random(in: .min ... .max)
    private var backdrop: Backdrop?

    init(run: WatchRun, size: CGSize) {
        self.run = run
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = Self.color(run.level.theme.sky)
        run.onEvents = { [weak self] events in self?.react(to: events) }
        run.onRewind = { [weak self] in self?.trails?.beginBranch("player") }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    // watchOS does not mark SKScene as main-actor isolated, but SpriteKit
    // drives both callbacks from the main thread.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        nonisolated(unsafe) let scene = self
        MainActor.assumeIsolated {
            if scene.built, abs(oldSize.width - scene.size.width) > 1 { scene.rebuild() }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        nonisolated(unsafe) let scene = self
        MainActor.assumeIsolated { scene.advance(to: currentTime) }
    }

    private func advance(to currentTime: TimeInterval) {
        if !built { rebuild() }
        let dt = lastTime == 0 ? 0 : min(currentTime - lastTime, 1.0 / 20)
        lastTime = currentTime
        backdrop?.tick(now: currentTime)
        if run.phase != .paused {
            run.step(dt: dt)
        }
        sync(clock: run.sim.time)
    }

    func point(_ v: Vec2) -> CGPoint {
        CGPoint(x: v.x * Double(scale), y: v.y * Double(scale))
    }

    func world(_ p: CGPoint) -> Vec2 {
        Vec2(x: Double(p.x / scale), y: Double(p.y / scale))
    }

    // MARK: - Build

    func rebuild() {
        removeAllChildren()
        sparkNodes.removeAll()
        bonusNodes.removeAll()
        rockNodes.removeAll()
        laserNodes.removeAll()
        gateNodes.removeAll()
        echoNodes.removeAll()
        ghostNodes.removeAll()
        built = true
        scale = size.width / CGFloat(max(run.level.worldWidth, 1))
        physicsWorld.gravity = .zero

        let border = SKShapeNode(rect: CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2), cornerRadius: 26)
        border.strokeColor = Self.color(run.level.theme.wallStroke).withAlphaComponent(0.35)
        border.lineWidth = 1.5
        addChild(border)
        let theme = run.level.theme
        let sky = Backdrop(
            size: size,
            palette: Backdrop.Palette(sky: Self.color(theme.sky), glow: Self.color(theme.nebula), accent: Self.color(theme.wallStroke)),
            seed: UInt64(RemoteLevel.token(of: Data(run.level.id.utf8))),
            budget: .watch,
            motion: !WKAccessibilityIsReduceMotionEnabled()
        )
        sky.root.zPosition = -20
        addChild(sky.root)
        backdrop = sky
        let edge = SKNode()
        edge.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        addChild(edge)

        for wall in run.level.walls {
            let rect = CGRect(x: wall.minX * Double(scale), y: wall.minY * Double(scale), width: wall.width * Double(scale), height: wall.height * Double(scale))
            let node = SKShapeNode(rect: rect, cornerRadius: min(6, min(rect.width, rect.height) * 0.3))
            node.fillColor = Self.color(run.level.theme.wallFill).withAlphaComponent(0.85)
            node.strokeColor = Self.color(run.level.theme.wallStroke)
            node.lineWidth = 1.2
            node.zPosition = 2
            let body = SKNode()
            body.position = CGPoint(x: rect.midX, y: rect.midY)
            body.physicsBody = SKPhysicsBody(rectangleOf: rect.size)
            body.physicsBody?.isDynamic = false
            addChild(node)
            addChild(body)
        }

        for gate in run.level.gates {
            let rect = CGRect(x: gate.area.minX * Double(scale), y: gate.area.minY * Double(scale), width: gate.area.width * Double(scale), height: gate.area.height * Double(scale))
            let node = SKShapeNode(rect: rect, cornerRadius: 4)
            node.zPosition = 2.5
            addChild(node)
            gateNodes[gate.id] = node
        }

        buildExit()
        buildPickups()
        buildRocks()
        for laser in run.level.lasers {
            let beam = SKShapeNode()
            beam.lineCap = .round
            beam.zPosition = 9
            addChild(beam)
            laserNodes[laser.id] = beam
        }

        trailLayer.removeAllChildren()
        trailLayer.zPosition = 6
        addChild(trailLayer)
        let renderer = TrailRenderer(parent: trailLayer)
        renderer.budget = .watch
        trails = renderer

        player.removeAllChildren()
        player.addChild(Self.head(radius: actorRadius, core: VisualPalette.playerCore, rim: VisualPalette.playerRim, glow: VisualPalette.playerGlow))
        player.zPosition = 14
        addChild(player)
        sync(clock: run.sim.time)
    }

    var actorRadius: CGFloat {
        CGFloat(run.sim.config.playerRadius) * scale * VisualStyle.actorBodyScale
    }

    private func buildExit() {
        exitNode.removeAllChildren()
        let radius = CGFloat(run.sim.config.exitRadius) * scale
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.name = "ring"
        ring.lineWidth = 1.5
        exitNode.addChild(ring)
        let spin = SKShapeNode(path: Self.dashedCircle(radius: radius * 0.72))
        spin.name = "spin"
        spin.strokeColor = UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 0.8)
        spin.lineWidth = 1.2
        spin.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 5)))
        exitNode.addChild(spin)
        exitNode.position = point(run.level.exit)
        exitNode.zPosition = 5
        addChild(exitNode)
    }

    private func buildPickups() {
        let gem = max(12, 22 * scale * 1.6)
        for spark in run.sim.sparks {
            let root = SKNode()
            let timed = spark.timerDuration != nil
            let glow = SKSpriteNode(texture: SpriteTextures.puff)
            glow.size = CGSize(width: gem * 2.1, height: gem * 2.1)
            glow.color = timed ? VisualPalette.timedSpark : VisualPalette.spark
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.35
            let sprite = SKSpriteNode(texture: timed ? SpriteTextures.timedGem : SpriteTextures.sparkGem)
            sprite.name = "gem"
            sprite.size = CGSize(width: gem, height: gem)
            sprite.run(.repeatForever(.sequence([.rotate(toAngle: 0.25, duration: 1.2), .rotate(toAngle: -0.25, duration: 1.2)])))
            root.addChild(glow)
            root.addChild(sprite)
            root.zPosition = 7
            addChild(root)
            sparkNodes[spark.id] = root
        }
        for bonus in run.sim.bonuses {
            let root = SKNode()
            let token = max(20, 44 * scale * 1.35)
            let halo = SKSpriteNode(texture: SpriteTextures.puff)
            halo.size = CGSize(width: token * 1.9, height: token * 1.9)
            halo.color = SpriteTextures.tint(bonus.kind)
            halo.colorBlendFactor = 1
            halo.blendMode = .add
            halo.alpha = 0.4
            let sprite = SKSpriteNode(texture: SpriteTextures.token(bonus.kind))
            sprite.size = CGSize(width: token, height: token)
            sprite.run(.repeatForever(.sequence([
                .wait(forDuration: 2.8),
                .scaleX(to: 0.08, duration: 0.14),
                .scaleX(to: 1, duration: 0.16),
            ])))
            root.addChild(halo)
            root.addChild(sprite)
            root.position = point(bonus.position)
            root.zPosition = 7
            addChild(root)
            bonusNodes[bonus.id] = root
        }
    }

    private func buildRocks() {
        for mover in run.sim.movers { buildRock(mover) }
    }

    private func buildRock(_ mover: MoverState) {
        let radius = CGFloat(mover.radius) * scale
        let art = rockArt[mover.id] ?? RockPainter.art(
            material: mover.material,
            radius: radius,
            seed: seed ^ (UInt64(truncatingIfNeeded: mover.id) &* 0x9E37_79B9_7F4A_7C15),
            still: mover.path == .stationary,
            scale: 2
        )
        rockArt[mover.id] = art
        let root = SKNode()
        let body = SKSpriteNode(texture: art.texture, size: art.canvas)
        body.name = "rock"
        body.zRotation = art.phase
        if art.spin > 0 {
            body.run(.repeatForever(.rotate(byAngle: .pi * 2 * art.spinDirection, duration: art.spin)))
        }
        root.addChild(body)
        root.zPosition = 10
        addChild(root)
        rockNodes[mover.id] = root
    }

    // MARK: - Sync

    private func sync(clock: TimeInterval) {
        let sim = run.sim
        player.position = point(sim.playerPosition)
        player.alpha = sim.effects.isPhasing ? 0.7 : 1

        while echoNodes.count < sim.echoes.count {
            let node = Self.head(radius: actorRadius * 0.92, core: VisualPalette.echoCore, rim: VisualPalette.echoRim, glow: VisualPalette.echoRim)
            node.zPosition = 13
            node.setScale(0.2)
            node.run(.scale(to: 1, duration: 0.2))
            addChild(node)
            echoNodes.append(node)
        }
        while echoNodes.count > sim.echoes.count { echoNodes.removeLast().removeFromParent() }
        for (index, echo) in sim.echoes.enumerated() { echoNodes[index].position = point(echo) }

        let ghosts = sim.ghosts.compactMap { $0.position(at: clock) }
        while ghostNodes.count < ghosts.count {
            let node = Self.head(radius: actorRadius * 0.92, core: VisualPalette.ghostCore, rim: VisualPalette.ghostRim, glow: VisualPalette.ghostRim)
            node.zPosition = 13
            addChild(node)
            ghostNodes.append(node)
        }
        while ghostNodes.count > ghosts.count { ghostNodes.removeLast().removeFromParent() }
        for (index, ghost) in ghosts.enumerated() { ghostNodes[index].position = point(ghost) }

        for spark in sim.sparks {
            guard let node = sparkNodes[spark.id] else { continue }
            node.isHidden = spark.collected
            node.position = point(spark.position)
            if spark.timedOut, let gem = node.childNode(withName: "gem") as? SKSpriteNode, gem.texture !== SpriteTextures.sparkGem {
                gem.texture = SpriteTextures.sparkGem
            }
        }
        for bonus in sim.bonuses { bonusNodes[bonus.id]?.isHidden = bonus.collected }

        let live = Set(sim.movers.map(\.id))
        for (id, node) in rockNodes where !live.contains(id) {
            node.removeFromParent()
            rockNodes.removeValue(forKey: id)
        }
        for mover in sim.movers {
            if rockNodes[mover.id] == nil { buildRock(mover) }
            rockNodes[mover.id]?.position = point(mover.position)
        }

        for laser in sim.lasers {
            guard let beam = laserNodes[laser.id] else { continue }
            let path = CGMutablePath()
            path.move(to: point(laser.start))
            path.addLine(to: point(laser.end))
            beam.path = path
            switch laser.phase {
            case .idle:
                beam.strokeColor = UIColor(red: 1, green: 0.3, blue: 0.5, alpha: 0.12)
                beam.lineWidth = 1
            case .charging(let progress):
                beam.strokeColor = UIColor(red: 1, green: 0.35, blue: 0.55, alpha: 0.25 + CGFloat(progress) * 0.5)
                beam.lineWidth = 1 + CGFloat(progress) * 1.5
            case .firing:
                beam.strokeColor = UIColor(red: 1, green: 0.55, blue: 0.7, alpha: 1)
                beam.lineWidth = max(2, CGFloat(laser.beamWidth) * scale)
            }
        }
        for gate in sim.gates {
            guard let node = gateNodes[gate.id] else { continue }
            node.fillColor = gate.solid ? UIColor(red: 1, green: 0.32, blue: 0.42, alpha: 0.55) : UIColor(red: 0.4, green: 0.9, blue: 1, alpha: 0.08)
            node.strokeColor = gate.solid ? UIColor(red: 1, green: 0.45, blue: 0.5, alpha: 1) : UIColor(red: 0.45, green: 0.9, blue: 1, alpha: 0.5)
        }

        if let ring = exitNode.childNode(withName: "ring") as? SKShapeNode {
            ring.strokeColor = sim.exitOpen ? UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 1) : UIColor.white.withAlphaComponent(0.2)
            ring.fillColor = sim.exitOpen ? UIColor(red: 0.35, green: 0.78, blue: 1, alpha: 0.18) : UIColor(white: 0.04, alpha: 0.5)
        }
        exitNode.childNode(withName: "spin")?.isHidden = !sim.exitOpen

        guard let trails else { return }
        let diameter = actorRadius * 2
        let surging = sim.effects.isSurging
        trails.sample(
            id: "player",
            position: player.position,
            time: clock,
            color: surging ? UIColor(red: 1, green: 0.86, blue: 0.4, alpha: 1) : VisualPalette.playerGlow,
            headWidth: diameter * (surging ? VisualStyle.cometSurgeWidth : VisualStyle.cometPlayerWidth),
            moving: true
        )
        var ids: Set<String> = ["player"]
        for (index, node) in echoNodes.enumerated() {
            ids.insert("echo-\(index)")
            trails.sample(id: "echo-\(index)", position: node.position, time: clock, color: VisualPalette.echoRim, headWidth: diameter * 0.92 * VisualStyle.cometEchoWidth, moving: true)
        }
        trails.prune(ids: ids)
    }
}
