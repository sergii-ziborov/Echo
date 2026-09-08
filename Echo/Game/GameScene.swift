import SpriteKit
import UIKit

@MainActor
final class GameScene: SKScene {
    unowned let session: GameSession
    var onEvents: (([SimEvent]) -> Void)?

    private var playerNode: SKNode!
    private var echoNodes: [SKNode] = []
    private var sparkNodes: [Int: SKNode] = [:]
    private var exitNode: SKShapeNode!
    private var threatLine: SKShapeNode!
    private var warningRing: SKShapeNode!
    private var lastTime: TimeInterval = 0
    private var trailAcc: TimeInterval = 0
    private let worldScale: CGFloat

    init(session: GameSession, size: CGSize) {
        self.session = session
        self.worldScale = size.width / CGFloat(session.level.worldSize)
        super.init(size: size)
        scaleMode = .aspectFit
        backgroundColor = UIColor(red: 0.03, green: 0.07, blue: 0.16, alpha: 1)
        anchorPoint = .zero
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func didMove(to view: SKView) {
        removeAllChildren()
        lastTime = 0
        buildArena()
        buildExit()
        buildSparks()
        buildPlayer()
        threatLine = SKShapeNode()
        threatLine.strokeColor = UIColor(red: 1, green: 0.4, blue: 0.55, alpha: 0.7)
        threatLine.lineWidth = 2
        threatLine.glowWidth = 4
        threatLine.zPosition = 8
        threatLine.lineCap = .round
        addChild(threatLine)
        warningRing = SKShapeNode(circleOfRadius: 28)
        warningRing.strokeColor = UIColor(red: 0.75, green: 0.4, blue: 1, alpha: 0.9)
        warningRing.lineWidth = 2
        warningRing.glowWidth = 8
        warningRing.fillColor = .clear
        warningRing.zPosition = 9
        warningRing.isHidden = true
        addChild(warningRing)
        syncNodes()
    }

    override func update(_ currentTime: TimeInterval) {
        if lastTime == 0 {
            lastTime = currentTime
            return
        }
        let dt = currentTime - lastTime
        lastTime = currentTime

        switch session.phase {
        case .paused, .dead, .won:
            return
        case .replaying:
            _ = session.advanceReplay(dt: dt)
            renderReplay()
            return
        case .playing:
            break
        }

        let events = session.sim.step(dt: dt, target: session.inputTarget)
        session.handle(events: events, autoReplay: session.autoReplay)
        if !events.isEmpty {
            onEvents?(events)
        }
        syncNodes()
        dropTrails(dt: dt)
        drawThreat()
        drawWarning()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        session.inputTarget = world(touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        session.inputTarget = world(touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        session.inputTarget = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        session.inputTarget = nil
    }

    func rebuild() {
        if let view {
            didMove(to: view)
        }
    }

    func burst(at position: Vec2, color: UIColor) {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 18
        emitter.particleLifetime = 0.45
        emitter.particlePositionRange = CGVector(dx: 8, dy: 8)
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 90
        emitter.particleSpeedRange = 40
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -2
        emitter.particleScale = 0.18
        emitter.particleScaleSpeed = -0.3
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        emitter.particleTexture = GlowTextures.orb(color: color, size: 32)
        emitter.position = scenePoint(position)
        emitter.zPosition = 20
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 0.6), .removeFromParent()]))
    }

    // MARK: - Build

    private func buildArena() {
        let w = size.width
        let grid = SKShapeNode()
        let path = CGMutablePath()
        let step = w / 10
        for i in 0...10 {
            let x = CGFloat(i) * step
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: w))
            path.move(to: CGPoint(x: 0, y: x))
            path.addLine(to: CGPoint(x: w, y: x))
        }
        grid.path = path
        grid.strokeColor = UIColor.white.withAlphaComponent(0.045)
        grid.lineWidth = 1
        grid.zPosition = 0
        addChild(grid)

        let border = SKShapeNode(rectOf: CGSize(width: w - 16, height: w - 16), cornerRadius: 18)
        border.position = CGPoint(x: w / 2, y: w / 2)
        border.strokeColor = UIColor(red: 0.25, green: 0.55, blue: 1, alpha: 0.28)
        border.lineWidth = 2
        border.glowWidth = 6
        border.fillColor = .clear
        border.zPosition = 1
        addChild(border)

        for wall in session.level.walls {
            let rect = CGRect(
                x: wall.minX * Double(worldScale),
                y: wall.minY * Double(worldScale),
                width: wall.width * Double(worldScale),
                height: wall.height * Double(worldScale)
            )
            let node = SKShapeNode(rect: rect, cornerRadius: 10)
            node.fillColor = UIColor(red: 0.08, green: 0.16, blue: 0.32, alpha: 0.95)
            node.strokeColor = UIColor(red: 0.35, green: 0.7, blue: 1, alpha: 0.35)
            node.lineWidth = 1.5
            node.glowWidth = 3
            node.zPosition = 2
            addChild(node)
        }
    }

    private func buildExit() {
        exitNode = SKShapeNode(circleOfRadius: CGFloat(session.sim.config.exitRadius) * worldScale)
        exitNode.position = scenePoint(session.level.exit)
        exitNode.lineWidth = 2
        exitNode.glowWidth = 8
        exitNode.fillColor = .clear
        exitNode.zPosition = 3
        addChild(exitNode)
        let inner = SKShapeNode(circleOfRadius: 10)
        inner.fillColor = UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 0.35)
        inner.strokeColor = .clear
        inner.glowWidth = 10
        inner.name = "exitCore"
        exitNode.addChild(inner)
        refreshExit()
    }

    private func buildSparks() {
        for spark in session.sim.sparks {
            let node = SKSpriteNode(texture: GlowTextures.orb(color: UIColor(red: 0.4, green: 0.85, blue: 1, alpha: 1), size: 64))
            node.size = CGSize(width: 36, height: 36)
            node.position = scenePoint(spark.position)
            node.zPosition = 5
            node.blendMode = .add
            node.name = "spark-\(spark.id)"
            let pulse = SKAction.sequence([
                .scale(to: 1.12, duration: 0.7),
                .scale(to: 0.88, duration: 0.7),
            ])
            node.run(.repeatForever(pulse))
            addChild(node)
            sparkNodes[spark.id] = node
        }
    }

    private func buildPlayer() {
        let root = SKNode()
        root.zPosition = 12
        let glow = SKSpriteNode(texture: GlowTextures.orb(color: UIColor(red: 0.45, green: 0.85, blue: 1, alpha: 1), size: 128))
        glow.size = CGSize(width: 70, height: 70)
        glow.blendMode = .add
        glow.name = "glow"
        let core = SKSpriteNode(texture: GlowTextures.hexCore(color: UIColor(red: 0.55, green: 0.92, blue: 1, alpha: 1), size: 96))
        core.size = CGSize(width: 38, height: 38)
        core.name = "core"
        root.addChild(glow)
        root.addChild(core)
        addChild(root)
        playerNode = root
    }

    private func echoNode() -> SKNode {
        let root = SKNode()
        root.zPosition = 10
        let glow = SKSpriteNode(texture: GlowTextures.orb(color: UIColor(red: 0.75, green: 0.35, blue: 1, alpha: 1), size: 128))
        glow.size = CGSize(width: 64, height: 64)
        glow.blendMode = .add
        glow.alpha = 0.85
        let body = SKShapeNode(circleOfRadius: 11)
        body.fillColor = UIColor(red: 0.55, green: 0.3, blue: 0.95, alpha: 0.55)
        body.strokeColor = UIColor(red: 0.85, green: 0.55, blue: 1, alpha: 0.9)
        body.lineWidth = 1.6
        body.glowWidth = 4
        body.name = "body"
        root.addChild(glow)
        root.addChild(body)
        return root
    }

    // MARK: - Sync

    private func syncNodes() {
        playerNode.position = scenePoint(session.sim.playerPosition)
        while echoNodes.count < session.sim.echoCount {
            let node = echoNode()
            addChild(node)
            echoNodes.append(node)
            node.setScale(0.2)
            node.run(.scale(to: 1, duration: 0.25))
        }
        for (i, echo) in session.sim.echoes.enumerated() {
            echoNodes[i].position = scenePoint(echo)
            if let threat = session.threat, threat.echoIndex == i, threat.willCollide {
                echoNodes[i].childNode(withName: "body")?.run(.sequence([
                    .scale(to: 1.15, duration: 0.08),
                    .scale(to: 1.0, duration: 0.08),
                ]))
            }
        }
        for spark in session.sim.sparks {
            sparkNodes[spark.id]?.isHidden = spark.collected
        }
        refreshExit()
    }

    private func renderReplay() {
        guard session.replaySnapshots.indices.contains(session.replayIndex) else { return }
        let snap = session.replaySnapshots[session.replayIndex]
        playerNode.position = scenePoint(snap.player)
        while echoNodes.count < snap.echoes.count {
            let node = echoNode()
            addChild(node)
            echoNodes.append(node)
        }
        for (i, echo) in snap.echoes.enumerated() {
            echoNodes[i].position = scenePoint(echo)
        }
        for (id, node) in sparkNodes {
            if snap.sparkCollected.indices.contains(id) {
                node.isHidden = snap.sparkCollected[id]
            }
        }
    }

    private func dropTrails(dt: TimeInterval) {
        trailAcc += dt
        guard trailAcc > 0.045 else { return }
        trailAcc = 0
        dropTrail(at: playerNode.position, color: UIColor(red: 0.45, green: 0.85, blue: 1, alpha: 0.45), hex: true)
        for echo in echoNodes {
            dropTrail(at: echo.position, color: UIColor(red: 0.7, green: 0.35, blue: 1, alpha: 0.35), hex: false)
        }
    }

    private func dropTrail(at point: CGPoint, color: UIColor, hex: Bool) {
        let node: SKShapeNode
        if hex {
            let path = CGMutablePath()
            let r: CGFloat = 8
            for i in 0..<6 {
                let a = CGFloat(i) * .pi / 3 - .pi / 2
                let p = CGPoint(x: cos(a) * r, y: sin(a) * r)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
            node = SKShapeNode(path: path)
        } else {
            node = SKShapeNode(circleOfRadius: 8)
        }
        node.position = point
        node.fillColor = color.withAlphaComponent(0.12)
        node.strokeColor = color
        node.lineWidth = 1
        node.glowWidth = 2
        node.zPosition = 6
        node.blendMode = .add
        addChild(node)
        node.run(.sequence([
            .group([.fadeOut(withDuration: 0.7), .scale(to: 0.4, duration: 0.7)]),
            .removeFromParent(),
        ]))
    }

    private func drawThreat() {
        guard session.phase == .playing,
              let threat = session.threat,
              threat.willCollide,
              session.sim.echoes.indices.contains(threat.echoIndex) else {
            threatLine.path = nil
            return
        }
        let path = CGMutablePath()
        let points = session.sim.predictedPath(forEcho: threat.echoIndex, duration: 0.7)
        guard let first = points.first else {
            threatLine.path = nil
            return
        }
        path.move(to: scenePoint(first))
        for p in points.dropFirst() {
            path.addLine(to: scenePoint(p))
        }
        threatLine.path = path
    }

    private func drawWarning() {
        guard session.warning, session.echoCount < session.maxEchoes else {
            warningRing.isHidden = true
            return
        }
        warningRing.isHidden = false
        warningRing.position = scenePoint(session.level.playerStart)
        let pulse = 1.0 + 0.12 * sin(CACurrentMediaTime() * 8)
        warningRing.setScale(pulse)
    }

    private func refreshExit() {
        if session.sim.exitOpen {
            exitNode.strokeColor = UIColor(red: 0.55, green: 0.9, blue: 1, alpha: 1)
            exitNode.glowWidth = 14
        } else {
            exitNode.strokeColor = UIColor.white.withAlphaComponent(0.18)
            exitNode.glowWidth = 2
        }
    }

    private func scenePoint(_ v: Vec2) -> CGPoint {
        CGPoint(x: v.x * Double(worldScale), y: v.y * Double(worldScale))
    }

    private func world(_ p: CGPoint) -> Vec2 {
        Vec2(x: Double(p.x / worldScale), y: Double(p.y / worldScale))
    }
}
