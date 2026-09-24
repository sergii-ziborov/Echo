import SpriteKit
import UIKit

/// The watch's close-up of a phone run. The arena around the orb is drawn at
/// nearly the phone's scale and follows the orb, and whatever lies past the
/// edge of the face shows up as a marker on the rim, so rocks and echoes
/// closing in, the next spark and the exit announce themselves from the side
/// they are on. The level is built from the watch's own catalog; only the
/// moving parts arrive from the phone.
@MainActor
final class RemoteScopeScene: SKScene {
    /// World units across the face.
    static let window: Double = 560

    let level: LevelDefinition
    /// The newest frame from the phone and when it arrived.
    var source: @MainActor () -> (frame: RemoteFrame, stamp: TimeInterval)? = { nil }

    /// A never-stepped simulation of the same level, for starting positions and sizes.
    let layout: WorldSimulation
    private(set) var scale: CGFloat = 1
    let lens = SKCameraNode()
    let markers = SKNode()
    var markerPool: [SKShapeNode] = []
    let exitMarker = SKShapeNode()
    private var built = false
    private var hasFrame = false
    private var trails: TrailRenderer?
    private let trailLayer = SKNode()
    private let player = SKNode()
    private var echoNodes: [SKNode] = []
    private var ghostNodes: [SKNode] = []
    private var sparkNodes: [Int: SKNode] = [:]
    private var bonusNodes: [Int: SKNode] = [:]
    private var rockNodes: [Int: SKNode] = [:]
    private var laserNodes: [Int: SKShapeNode] = [:]
    private var gateNodes: [Int: SKShapeNode] = [:]
    private let exitRing = SKShapeNode()
    private let exitSpin = SKShapeNode()
    private var lastTime: TimeInterval = 0
    private let seed = UInt64.random(in: .min ... .max)

    init(level: LevelDefinition, size: CGSize) {
        self.level = level
        layout = WorldSimulation(level: level)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = WatchArenaScene.color(level.theme.sky)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    // watchOS does not mark SKScene as main-actor isolated, but SpriteKit
    // drives both callbacks from the main thread.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        nonisolated(unsafe) let scene = self
        MainActor.assumeIsolated {
            if scene.built, abs(oldSize.width - scene.size.width) > 1 { scene.build() }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        nonisolated(unsafe) let scene = self
        MainActor.assumeIsolated { scene.advance(to: currentTime) }
    }

    func point(_ v: Vec2) -> CGPoint {
        CGPoint(x: v.x * Double(scale), y: v.y * Double(scale))
    }

    private func advance(to currentTime: TimeInterval) {
        if !built { build() }
        let dt = lastTime == 0 ? 1.0 / 60 : min(currentTime - lastTime, 0.1)
        lastTime = currentTime
        guard let (frame, stamp) = source() else { return }
        sync(frame, age: max(0, ProcessInfo.processInfo.systemUptime - stamp), dt: dt, clock: currentTime)
    }

    // MARK: - Build

    private func build() {
        built = true
        hasFrame = false
        removeAllChildren()
        sparkNodes.removeAll()
        bonusNodes.removeAll()
        rockNodes.removeAll()
        laserNodes.removeAll()
        gateNodes.removeAll()
        echoNodes.removeAll()
        ghostNodes.removeAll()
        scale = size.width / CGFloat(Self.window)
        let theme = level.theme

        lens.removeAllChildren()
        addChild(lens)
        camera = lens
        markers.removeAllChildren()
        markers.zPosition = 50
        lens.addChild(markers)
        buildMarkers()

        let arena = CGRect(x: 0, y: 0, width: level.worldWidth * Double(scale), height: level.worldHeight * Double(scale))
        let border = SKShapeNode(rect: arena, cornerRadius: 12)
        border.strokeColor = WatchArenaScene.color(theme.wallStroke).withAlphaComponent(0.45)
        border.lineWidth = 1.5
        addChild(border)

        for field in level.fields {
            let node = SKShapeNode(rect: rect(field.area), cornerRadius: 6)
            node.fillColor = UIColor(red: 0.4, green: 0.7, blue: 1, alpha: 0.08)
            node.strokeColor = UIColor(red: 0.4, green: 0.7, blue: 1, alpha: 0.25)
            addChild(node)
        }
        for wall in level.walls {
            let box = rect(wall)
            let node = SKShapeNode(rect: box, cornerRadius: min(6, min(box.width, box.height) * 0.3))
            node.fillColor = WatchArenaScene.color(theme.wallFill).withAlphaComponent(0.9)
            node.strokeColor = WatchArenaScene.color(theme.wallStroke)
            node.lineWidth = 1.2
            node.zPosition = 2
            addChild(node)
        }
        for gate in level.gates {
            let node = SKShapeNode(rect: rect(gate.area), cornerRadius: 4)
            node.zPosition = 2.5
            addChild(node)
            gateNodes[gate.id] = node
        }
        for rift in layout.rifts {
            let ring = SKShapeNode(path: WatchArenaScene.dashedCircle(radius: CGFloat(rift.radius) * scale))
            ring.strokeColor = UIColor(red: 0.8, green: 0.45, blue: 1, alpha: 0.8)
            ring.lineWidth = 1.5
            ring.position = point(rift.position)
            ring.zPosition = 3
            ring.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 6)))
            addChild(ring)
        }
        for well in layout.gravityWells {
            let core = SKShapeNode(circleOfRadius: CGFloat(well.coreRadius) * scale)
            core.fillColor = UIColor(white: 0.02, alpha: 0.95)
            core.strokeColor = UIColor(red: 0.95, green: 0.6, blue: 0.3, alpha: 0.9)
            core.lineWidth = 1.5
            core.position = point(well.position)
            core.zPosition = 3
            addChild(core)
        }

        buildExit()
        buildPickups()
        for mover in layout.movers { buildRock(mover) }
        for laser in layout.lasers {
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
        player.addChild(WatchArenaScene.head(radius: actorRadius, core: VisualPalette.playerCore, rim: VisualPalette.playerRim, glow: VisualPalette.playerGlow))
        player.zPosition = 14
        player.position = point(level.playerStart)
        addChild(player)
        lens.position = player.position
    }

    var actorRadius: CGFloat {
        max(4, CGFloat(layout.config.playerRadius) * scale * VisualStyle.actorBodyScale)
    }

    private func rect(_ box: AABB) -> CGRect {
        CGRect(x: box.minX * Double(scale), y: box.minY * Double(scale), width: box.width * Double(scale), height: box.height * Double(scale))
    }

    private func buildExit() {
        let radius = CGFloat(layout.config.exitRadius) * scale
        exitRing.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        exitRing.lineWidth = 1.5
        exitRing.position = point(level.exit)
        exitRing.zPosition = 5
        addChild(exitRing)
        exitSpin.path = WatchArenaScene.dashedCircle(radius: radius * 0.72)
        exitSpin.strokeColor = UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 0.8)
        exitSpin.lineWidth = 1.2
        exitSpin.removeAllActions()
        exitSpin.removeFromParent()
        exitSpin.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 5)))
        exitRing.addChild(exitSpin)
    }

    private func buildPickups() {
        let gem = max(11, 22 * scale * 1.5)
        for spark in layout.sparks {
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
            root.addChild(glow)
            root.addChild(sprite)
            root.position = point(spark.position)
            root.zPosition = 7
            addChild(root)
            sparkNodes[spark.id] = root
        }
        let token = max(18, 44 * scale * 1.2)
        for bonus in layout.bonuses {
            let root = SKNode()
            let halo = SKSpriteNode(texture: SpriteTextures.puff)
            halo.size = CGSize(width: token * 1.9, height: token * 1.9)
            halo.color = SpriteTextures.tint(bonus.kind)
            halo.colorBlendFactor = 1
            halo.blendMode = .add
            halo.alpha = 0.4
            let sprite = SKSpriteNode(texture: SpriteTextures.token(bonus.kind))
            sprite.size = CGSize(width: token, height: token)
            root.addChild(halo)
            root.addChild(sprite)
            root.position = point(bonus.position)
            root.zPosition = 7
            addChild(root)
            bonusNodes[bonus.id] = root
        }
    }

    private func buildRock(_ mover: MoverState) {
        let art = RockPainter.art(
            material: mover.material,
            radius: CGFloat(mover.radius) * scale,
            seed: seed ^ (UInt64(truncatingIfNeeded: mover.id) &* 0x9E37_79B9_7F4A_7C15),
            still: mover.path == .stationary,
            scale: 2
        )
        let root = SKNode()
        let body = SKSpriteNode(texture: art.texture, size: art.canvas)
        body.zRotation = art.phase
        if art.spin > 0 {
            body.run(.repeatForever(.rotate(byAngle: .pi * 2 * art.spinDirection, duration: art.spin)))
        }
        root.addChild(body)
        root.position = point(mover.position)
        root.zPosition = 10
        addChild(root)
        rockNodes[mover.id] = root
    }

    // MARK: - Sync

    private func sync(_ frame: RemoteFrame, age: TimeInterval, dt: TimeInterval, clock: TimeInterval) {
        let ease = hasFrame ? CGFloat(min(1, dt * 16)) : 1
        hasFrame = true
        let lead = frame.state == .playing ? min(age, 0.15) : 0
        player.position = mix(player.position, point(frame.player + frame.velocity * lead), ease)
        player.alpha = frame.phasing ? 0.7 : 1

        place(&echoNodes, at: frame.echoes, ease: ease, core: VisualPalette.echoCore, rim: VisualPalette.echoRim)
        place(&ghostNodes, at: frame.ghosts, ease: ease, core: VisualPalette.ghostCore, rim: VisualPalette.ghostRim)

        let live = Dictionary(frame.rocks.map { ($0.id, $0.position) }, uniquingKeysWith: { first, _ in first })
        for (id, node) in rockNodes {
            guard let position = live[id] else {
                node.removeFromParent()
                rockNodes.removeValue(forKey: id)
                continue
            }
            node.position = mix(node.position, point(position), ease)
            node.alpha = frame.frozen ? 0.6 : 1
        }

        let orbiting = Dictionary(frame.orbiting.map { ($0.id, $0.position) }, uniquingKeysWith: { first, _ in first })
        for (id, node) in sparkNodes {
            node.isHidden = RemoteFrame.contains(frame.collected, id)
            if let position = orbiting[id] { node.position = mix(node.position, point(position), ease) }
            if RemoteFrame.contains(frame.timedOut, id), let gem = node.childNode(withName: "gem") as? SKSpriteNode, gem.texture !== SpriteTextures.sparkGem {
                gem.texture = SpriteTextures.sparkGem
            }
        }
        for (id, node) in bonusNodes { node.isHidden = RemoteFrame.contains(frame.bonusesTaken, id) }
        for (id, node) in gateNodes {
            let solid = RemoteFrame.contains(frame.solidGates, id)
            node.fillColor = solid ? UIColor(red: 1, green: 0.32, blue: 0.42, alpha: 0.55) : UIColor(red: 0.4, green: 0.9, blue: 1, alpha: 0.08)
            node.strokeColor = solid ? UIColor(red: 1, green: 0.45, blue: 0.5, alpha: 1) : UIColor(red: 0.45, green: 0.9, blue: 1, alpha: 0.5)
        }
        for beam in frame.beams { style(beam) }

        exitRing.strokeColor = frame.exitOpen ? UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 1) : UIColor.white.withAlphaComponent(0.25)
        exitRing.fillColor = frame.exitOpen ? UIColor(red: 0.35, green: 0.78, blue: 1, alpha: 0.18) : UIColor(white: 0.04, alpha: 0.5)
        exitSpin.isHidden = !frame.exitOpen

        follow(ease: ease)
        drawTrails(frame, clock: clock)
        updateMarkers(frame)
    }

    private func place(_ nodes: inout [SKNode], at positions: [Vec2], ease: CGFloat, core: UIColor, rim: UIColor) {
        while nodes.count < positions.count {
            let node = WatchArenaScene.head(radius: actorRadius * 0.92, core: core, rim: rim, glow: rim)
            node.zPosition = 13
            node.position = point(positions[nodes.count])
            node.setScale(0.2)
            node.run(.scale(to: 1, duration: 0.2))
            addChild(node)
            nodes.append(node)
        }
        while nodes.count > positions.count { nodes.removeLast().removeFromParent() }
        for (node, position) in zip(nodes, positions) { node.position = mix(node.position, point(position), ease) }
    }

    private func style(_ beam: RemoteFrame.Beam) {
        guard let node = laserNodes[beam.id] else { return }
        let path = CGMutablePath()
        path.move(to: point(beam.start))
        path.addLine(to: point(beam.end))
        node.path = path
        switch beam.phase {
        case .idle:
            node.strokeColor = UIColor(red: 1, green: 0.3, blue: 0.5, alpha: 0.14)
            node.lineWidth = 1
        case .charging(let progress):
            node.strokeColor = UIColor(red: 1, green: 0.35, blue: 0.55, alpha: 0.25 + CGFloat(progress) * 0.55)
            node.lineWidth = 1 + CGFloat(progress) * 1.5
        case .firing:
            node.strokeColor = UIColor(red: 1, green: 0.55, blue: 0.7, alpha: 1)
            node.lineWidth = max(2.5, 18 * scale)
        }
    }

    /// Keep the orb centred, but never show much beyond the arena's walls.
    private func follow(ease: CGFloat) {
        let width = CGFloat(level.worldWidth) * scale
        let height = CGFloat(level.worldHeight) * scale
        func clamp(_ value: CGFloat, span: CGFloat, view: CGFloat) -> CGFloat {
            let margin: CGFloat = 10
            guard span + margin * 2 > view else { return span / 2 }
            return min(max(value, view / 2 - margin), span - view / 2 + margin)
        }
        let goal = CGPoint(
            x: clamp(player.position.x, span: width, view: size.width),
            y: clamp(player.position.y, span: height, view: size.height)
        )
        lens.position = mix(lens.position, goal, min(1, ease * 0.8))
    }

    private func drawTrails(_ frame: RemoteFrame, clock: TimeInterval) {
        guard let trails else { return }
        let diameter = actorRadius * 2
        trails.sample(
            id: "player",
            position: player.position,
            time: clock,
            color: frame.surging ? UIColor(red: 1, green: 0.86, blue: 0.4, alpha: 1) : VisualPalette.playerGlow,
            headWidth: diameter * (frame.surging ? VisualStyle.cometSurgeWidth : VisualStyle.cometPlayerWidth),
            moving: true
        )
        var ids: Set<String> = ["player"]
        for (index, node) in echoNodes.enumerated() {
            ids.insert("echo-\(index)")
            trails.sample(id: "echo-\(index)", position: node.position, time: clock, color: VisualPalette.echoRim, headWidth: diameter * 0.92 * VisualStyle.cometEchoWidth, moving: true)
        }
        trails.prune(ids: ids)
    }

    func mix(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
