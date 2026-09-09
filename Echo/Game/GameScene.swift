import QuartzCore
import SpriteKit
import UIKit

@MainActor
final class GameScene: SKScene {
    unowned let session: GameSession
    var onEvents: (([SimEvent]) -> Void)?

    private var playerNode: SKNode!
    private var echoNodes: [SKNode] = []
    private var sparkNodes: [Int: SKNode] = [:]
    private var bonusNodes: [Int: SKNode] = [:]
    private var exitNode: SKNode!
    private var lastTapAt: TimeInterval = 0
    private var threatLine: SKShapeNode!
    private var spawnBeacon: SKNode!
    private var ambienceNode: SKNode!
    private var lastTime: TimeInterval = 0
    private var trailAcc: TimeInterval = 0
    private var trailBudget = 0

    init(session: GameSession, size: CGSize) {
        self.session = session
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.015, green: 0.04, blue: 0.11, alpha: 1)
        anchorPoint = .zero
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func resize(to newSize: CGSize) {
        guard newSize.width > 8, newSize.height > 8 else { return }
        let changed = abs(newSize.width - size.width) > 1 || abs(newSize.height - size.height) > 1
        size = newSize
        scaleMode = .resizeFill
        if changed, view != nil { rebuild() }
    }

    override func didMove(to view: SKView) {
        removeAllChildren()
        echoNodes.removeAll()
        sparkNodes.removeAll()
        bonusNodes.removeAll()
        lastTime = 0
        trailAcc = 0
        trailBudget = 0
        ambienceNode = SKNode()
        ambienceNode.zPosition = 1.5
        addChild(ambienceNode)
        buildArena()
        buildAmbient()
        buildExit()
        buildSparks()
        buildBonuses()
        buildFields()
        buildSpawnBeacon()
        buildPlayer()
        threatLine = SKShapeNode()
        threatLine.strokeColor = UIColor(red: 1, green: 0.45, blue: 0.6, alpha: 0.85)
        threatLine.lineWidth = 2
        threatLine.glowWidth = 3
        threatLine.lineCap = .round
        threatLine.zPosition = 8
        addChild(threatLine)
        syncNodes()
        drawSpawnBeacon()
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
        if !events.isEmpty { onEvents?(events) }
        let live = session.hasStarted
        ambienceNode.speed = live ? 1 : 0
        exitNode.speed = live ? 1 : 0
        spawnBeacon.speed = live ? 1 : 0
        sparkNodes.values.forEach { $0.speed = live ? 1 : 0 }
        bonusNodes.values.forEach { $0.speed = live ? 1 : 0 }
        syncNodes()
        drawSpawnBeacon()
        if live {
            dropTrails(dt: dt)
            drawThreat()
            updateSparkTimers()
            pulsePlayer()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let now = CACurrentMediaTime()
        if now - lastTapAt < 0.28, session.sim.tryDash() {
            burst(at: session.sim.playerPosition, color: UIColor(red: 1, green: 0.85, blue: 0.35, alpha: 1))
        }
        lastTapAt = now
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
        if let view { didMove(to: view) }
    }

    func burst(at position: Vec2, color: UIColor) {
        shockwave(at: scenePoint(position), color: color)
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 140
        emitter.numParticlesToEmit = 36
        emitter.particleLifetime = 0.55
        emitter.particleLifetimeRange = 0.2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 140
        emitter.particleSpeedRange = 70
        emitter.particleAlpha = 1
        emitter.particleAlphaSpeed = -1.8
        emitter.particleScale = 0.35
        emitter.particleScaleSpeed = -0.4
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        emitter.particleTexture = GlowTextures.blob
        emitter.position = scenePoint(position)
        emitter.zPosition = 22
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 0.8), .removeFromParent()]))
    }

    func timerPop(at position: Vec2) {
        shockwave(at: scenePoint(position), color: UIColor(red: 1, green: 0.75, blue: 0.3, alpha: 1), start: 18, end: 70)
    }

    // MARK: - Build

    private func buildArena() {
        let w = size.width
        let h = size.height
        let grid = SKShapeNode()
        let path = CGMutablePath()
        let cols = 8
        let rows = max(8, Int((h / w) * 8))
        let dx = w / CGFloat(cols)
        let dy = h / CGFloat(rows)
        for i in 0...cols {
            let x = CGFloat(i) * dx
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: h))
        }
        for i in 0...rows {
            let y = CGFloat(i) * dy
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: w, y: y))
        }
        grid.path = path
        grid.strokeColor = UIColor.white.withAlphaComponent(0.055)
        grid.lineWidth = 1
        grid.zPosition = 0
        addChild(grid)

        let border = SKShapeNode(rectOf: CGSize(width: w - 10, height: h - 10), cornerRadius: 8)
        border.position = CGPoint(x: w / 2, y: h / 2)
        border.strokeColor = UIColor(red: 0.3, green: 0.65, blue: 1, alpha: 0.35)
        border.lineWidth = 2
        border.glowWidth = 8
        border.fillColor = .clear
        border.zPosition = 1
        addChild(border)

        for wall in session.level.walls {
            let rect = mapped(wall)
            let node = SKShapeNode(rect: rect, cornerRadius: 14)
            node.fillColor = UIColor(red: 0.07, green: 0.14, blue: 0.3, alpha: 0.96)
            node.strokeColor = UIColor(red: 0.4, green: 0.75, blue: 1, alpha: 0.55)
            node.lineWidth = 2
            node.glowWidth = 6
            node.zPosition = 2
            addChild(node)
            let inner = SKShapeNode(rect: rect.insetBy(dx: 5, dy: 5), cornerRadius: 10)
            inner.fillColor = .clear
            inner.strokeColor = UIColor(red: 0.55, green: 0.85, blue: 1, alpha: 0.18)
            inner.lineWidth = 1
            inner.zPosition = 2.1
            addChild(inner)
        }
    }

    private func buildAmbient() {
        for i in 0..<18 {
            let mote = SKSpriteNode(texture: GlowTextures.blob)
            let s = CGFloat.random(in: 10...28)
            mote.size = CGSize(width: s, height: s)
            mote.alpha = CGFloat.random(in: 0.08...0.22)
            mote.blendMode = .add
            mote.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            mote.zPosition = 1.5
            let drift = SKAction.moveBy(
                x: CGFloat.random(in: -40...40),
                y: CGFloat.random(in: 30...90),
                duration: TimeInterval.random(in: 6...12)
            )
            let fade = SKAction.sequence([
                .fadeAlpha(to: mote.alpha + 0.08, duration: 2.4),
                .fadeAlpha(to: mote.alpha, duration: 2.4),
            ])
            mote.run(.repeatForever(.group([drift, fade])))
            mote.run(.repeatForever(.sequence([
                .wait(forDuration: TimeInterval.random(in: 4...9)),
                .move(to: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ), duration: 0),
            ])))
            ambienceNode.addChild(mote)
            _ = i
        }
    }

    private func buildExit() {
        let root = SKNode()
        root.zPosition = 3
        root.position = scenePoint(session.level.exit)
        let r = CGFloat(session.sim.config.exitRadius) * worldScale
        let outer = SKShapeNode(circleOfRadius: r)
        outer.strokeColor = UIColor.white.withAlphaComponent(0.2)
        outer.lineWidth = 2
        outer.glowWidth = 4
        outer.fillColor = UIColor(red: 0.2, green: 0.55, blue: 1, alpha: 0.08)
        outer.name = "outer"
        let spin = SKShapeNode(circleOfRadius: r * 0.72)
        spin.strokeColor = UIColor(red: 0.45, green: 0.85, blue: 1, alpha: 0.45)
        spin.lineWidth = 2
        spin.glowWidth = 6
        spin.fillColor = .clear
        spin.name = "spin"
        spin.run(.repeatForever(.rotate(byAngle: .pi, duration: 6)))
        let core = SKSpriteNode(texture: GlowTextures.blob)
        core.size = CGSize(width: r * 1.1, height: r * 1.1)
        core.blendMode = .add
        core.alpha = 0.35
        core.name = "core"
        core.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 1.1),
            .scale(to: 0.88, duration: 1.1),
        ])))
        root.addChild(outer)
        root.addChild(spin)
        root.addChild(core)
        addChild(root)
        exitNode = root
        refreshExit()
    }

    private func buildSparks() {
        for spark in session.sim.sparks {
            let root = SKNode()
            root.position = scenePoint(spark.position)
            root.zPosition = 5
            root.name = "spark-\(spark.id)"

            let glow = SKSpriteNode(texture: GlowTextures.blob)
            glow.size = CGSize(width: 48, height: 48)
            glow.blendMode = .add
            glow.alpha = 0.45
            glow.name = "glow"

            let gem = SKSpriteNode(texture: GlowTextures.spark)
            gem.size = CGSize(width: 42, height: 42)
            gem.name = "gem"
            gem.run(.repeatForever(.rotate(byAngle: .pi, duration: 7)))
            gem.run(.repeatForever(.sequence([
                .scale(to: 1.12, duration: 0.55),
                .scale(to: 0.9, duration: 0.55),
            ])))

            let ring = SKShapeNode(circleOfRadius: 30)
            ring.strokeColor = UIColor(red: 0.45, green: 0.9, blue: 1, alpha: 0.7)
            ring.lineWidth = 3
            ring.glowWidth = 5
            ring.fillColor = .clear
            ring.name = "timer"
            ring.zRotation = -.pi / 2

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.fontSize = 13
            label.fontColor = UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: -42)
            label.name = "timerLabel"

            root.addChild(glow)
            root.addChild(gem)
            root.addChild(ring)
            root.addChild(label)
            addChild(root)
            sparkNodes[spark.id] = root
        }
    }

    private func buildFields() {
        for field in session.level.fields {
            let rect = mapped(field.area)
            let node = SKShapeNode(rect: rect, cornerRadius: 18)
            node.fillColor = UIColor(red: 0.35, green: 0.55, blue: 1, alpha: 0.14)
            node.strokeColor = UIColor(red: 0.45, green: 0.7, blue: 1, alpha: 0.45)
            node.lineWidth = 1.5
            node.glowWidth = 4
            node.zPosition = 2.4
            node.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.35, duration: 1.2),
                .fadeAlpha(to: 0.8, duration: 1.2),
            ])))
            addChild(node)
        }
    }

    private func buildBonuses() {
        for bonus in session.sim.bonuses {
            let root = SKNode()
            root.position = scenePoint(bonus.position)
            root.zPosition = 7
            let glow = SKSpriteNode(texture: GlowTextures.blob)
            glow.size = CGSize(width: 32, height: 32)
            glow.blendMode = .add
            glow.color = Self.color(for: bonus.kind)
            glow.colorBlendFactor = 0.7
            glow.alpha = 0.4
            let gem = SKSpriteNode(texture: GlowTextures.bonus(bonus.kind))
            gem.size = CGSize(width: 36, height: 36)
            gem.run(.repeatForever(.sequence([
                .scale(to: 1.12, duration: 0.55),
                .scale(to: 0.92, duration: 0.55),
            ])))
            root.addChild(glow)
            root.addChild(gem)
            addChild(root)
            bonusNodes[bonus.id] = root
        }
    }

    private func buildPlayer() {
        let root = SKNode()
        root.zPosition = 14
        let halo = SKSpriteNode(texture: GlowTextures.blob)
        halo.size = CGSize(width: 34, height: 34)
        halo.blendMode = .add
        halo.alpha = 0.32
        halo.name = "halo"
        let body = SKSpriteNode(texture: GlowTextures.player)
        body.size = CGSize(width: 48, height: 48)
        body.name = "body"
        body.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 14)))
        root.addChild(halo)
        root.addChild(body)
        addChild(root)
        playerNode = root
    }

    private func buildSpawnBeacon() {
        let root = SKNode()
        root.zPosition = 9
        root.position = scenePoint(session.level.playerStart)

        let glow = SKSpriteNode(texture: GlowTextures.spawnRing)
        glow.size = CGSize(width: 72, height: 72)
        glow.blendMode = .add
        glow.alpha = 0.55
        glow.name = "glow"
        glow.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 7.5)))

        let ring = SKShapeNode(circleOfRadius: 26)
        ring.strokeColor = UIColor(red: 0.8, green: 0.4, blue: 1, alpha: 0.95)
        ring.lineWidth = 2.4
        ring.glowWidth = 5
        ring.fillColor = UIColor(red: 0.45, green: 0.2, blue: 0.7, alpha: 0.12)
        ring.name = "ring"

        let arc = SKShapeNode()
        arc.strokeColor = UIColor(red: 0.55, green: 0.85, blue: 1, alpha: 1)
        arc.lineWidth = 3.4
        arc.glowWidth = 4
        arc.lineCap = .round
        arc.fillColor = .clear
        arc.zRotation = .pi / 2
        arc.name = "arc"

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = 15
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "label"

        root.addChild(glow)
        root.addChild(ring)
        root.addChild(arc)
        root.addChild(label)
        addChild(root)
        spawnBeacon = root
    }

    private func echoNode() -> SKNode {
        let root = SKNode()
        root.zPosition = 11
        let halo = SKSpriteNode(texture: GlowTextures.blob)
        halo.size = CGSize(width: 28, height: 28)
        halo.blendMode = .add
        halo.color = UIColor(red: 0.85, green: 0.4, blue: 1, alpha: 1)
        halo.colorBlendFactor = 0.45
        halo.alpha = 0.28
        halo.name = "halo"
        let body = SKSpriteNode(texture: GlowTextures.echo)
        body.size = CGSize(width: 42, height: 42)
        body.name = "body"
        body.alpha = 0.92
        body.run(.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.7),
            .scale(to: 0.94, duration: 0.7),
        ])))
        root.addChild(halo)
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
            node.setScale(0.15)
            node.run(.scale(to: 1, duration: 0.28))
            shockwave(at: node.position, color: UIColor(red: 0.8, green: 0.4, blue: 1, alpha: 1), start: 10, end: 90)
        }
        for (i, echo) in session.sim.echoes.enumerated() {
            echoNodes[i].position = scenePoint(echo)
        }
        for spark in session.sim.sparks {
            sparkNodes[spark.id]?.isHidden = spark.collected
            sparkNodes[spark.id]?.position = scenePoint(spark.position)
        }
        for bonus in session.sim.bonuses {
            bonusNodes[bonus.id]?.isHidden = bonus.collected
        }
        exitNode.position = scenePoint(session.level.exit)
        refreshExit()
        if let halo = playerNode.childNode(withName: "halo") as? SKSpriteNode {
            if session.sim.effects.shieldCharges > 0 {
                halo.color = UIColor(red: 0.45, green: 1, blue: 0.7, alpha: 1)
                halo.colorBlendFactor = 0.55
            } else if session.sim.effects.isSurging {
                halo.color = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
                halo.colorBlendFactor = 0.5
            } else if session.sim.effects.isFrozen {
                halo.color = UIColor(red: 0.55, green: 0.8, blue: 1, alpha: 1)
                halo.colorBlendFactor = 0.45
            } else {
                halo.colorBlendFactor = 0
            }
        }
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
    }

    private func dropTrails(dt: TimeInterval) {
        trailAcc += dt
        guard trailAcc > 0.03 else { return }
        trailAcc = 0
        dropTrail(at: playerNode.position, color: UIColor(red: 0.45, green: 0.9, blue: 1, alpha: 1), size: 16)
        for echo in echoNodes {
            dropTrail(at: echo.position, color: UIColor(red: 0.78, green: 0.38, blue: 1, alpha: 1), size: 14)
        }
    }

    private func dropTrail(at point: CGPoint, color: UIColor, size: CGFloat) {
        trailBudget += 1
        if trailBudget > 80 {
            // Keep the scene from accumulating hundreds of trail sprites.
            enumerateChildNodes(withName: "trail") { node, stop in
                node.removeFromParent()
                stop.pointee = true
            }
            trailBudget = 40
        }
        let node = SKSpriteNode(texture: GlowTextures.blob)
        node.size = CGSize(width: size, height: size)
        node.position = point
        node.blendMode = .add
        node.color = color
        node.colorBlendFactor = 0.65
        node.alpha = 0.7
        node.zPosition = 6
        node.name = "trail"
        addChild(node)
        node.run(.sequence([
            .group([
                .fadeOut(withDuration: 0.85),
                .scale(to: 0.15, duration: 0.85),
            ]),
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
        let points = session.sim.predictedPath(forEcho: threat.echoIndex, duration: 0.7)
        guard let first = points.first else {
            threatLine.path = nil
            return
        }
        let path = CGMutablePath()
        path.move(to: scenePoint(first))
        for p in points.dropFirst() { path.addLine(to: scenePoint(p)) }
        threatLine.path = path
    }

    private func drawSpawnBeacon() {
        spawnBeacon.position = scenePoint(session.level.playerStart)
        let glow = spawnBeacon.childNode(withName: "glow") as? SKSpriteNode
        let ring = spawnBeacon.childNode(withName: "ring") as? SKShapeNode
        let arc = spawnBeacon.childNode(withName: "arc") as? SKShapeNode
        let label = spawnBeacon.childNode(withName: "label") as? SKLabelNode

        if !session.hasStarted {
            spawnBeacon.alpha = 0.7
            spawnBeacon.setScale(1)
            glow?.alpha = 0.35
            label?.text = ""
            arc?.path = nil
            ring?.strokeColor = UIColor(red: 0.8, green: 0.4, blue: 1, alpha: 0.7)
            return
        }

        spawnBeacon.alpha = 1
        if let remaining = session.nextEchoIn {
            let interval = max(session.level.echoInterval, 0.01)
            let frac = max(0, min(1, 1 - remaining / interval))
            label?.text = String(format: "%.0f", remaining)
            arc?.path = Self.arc(radius: 26, fraction: frac)
            if session.warning {
                let pulse = 1.0 + 0.12 * sin(CACurrentMediaTime() * 10)
                spawnBeacon.setScale(pulse)
                glow?.alpha = 0.9
                ring?.strokeColor = UIColor(red: 0.95, green: 0.45, blue: 1, alpha: 1)
                arc?.strokeColor = UIColor(red: 1, green: 0.55, blue: 0.95, alpha: 1)
            } else {
                spawnBeacon.setScale(1)
                glow?.alpha = 0.55
                ring?.strokeColor = UIColor(red: 0.8, green: 0.4, blue: 1, alpha: 0.95)
                arc?.strokeColor = UIColor(red: 0.55, green: 0.85, blue: 1, alpha: 1)
            }
        } else {
            label?.text = ""
            arc?.path = Self.arc(radius: 26, fraction: 1)
            arc?.strokeColor = UIColor(red: 0.8, green: 0.4, blue: 1, alpha: 0.35)
            spawnBeacon.setScale(1)
            glow?.alpha = 0.25
        }
    }

    private func updateSparkTimers() {
        for spark in session.sim.sparks {
            guard let root = sparkNodes[spark.id] else { continue }
            let ring = root.childNode(withName: "timer") as? SKShapeNode
            let label = root.childNode(withName: "timerLabel") as? SKLabelNode
            if let duration = spark.timerDuration, let remaining = spark.timerRemaining, !spark.collected {
                let frac = max(0, min(1, remaining / duration))
                ring?.path = Self.arc(radius: 30, fraction: frac)
                ring?.strokeColor = spark.timedOut
                    ? UIColor(red: 1, green: 0.78, blue: 0.3, alpha: 0.55)
                    : UIColor(red: 1, green: 0.82, blue: 0.35, alpha: 0.95)
                if spark.timedOut {
                    label?.text = ""
                } else {
                    label?.text = String(format: "%.0f", remaining)
                }
            } else {
                ring?.path = Self.arc(radius: 30, fraction: 1)
                ring?.strokeColor = UIColor(red: 0.45, green: 0.9, blue: 1, alpha: 0.35)
                label?.text = ""
            }
        }
    }

    private func pulsePlayer() {
        guard let halo = playerNode.childNode(withName: "halo") else { return }
        let moving = session.sim.lastVelocity.length > 1
        halo.run(.scale(to: moving ? 1.08 : 1.0, duration: 0.12))
    }

    private func refreshExit() {
        let outer = exitNode.childNode(withName: "outer") as? SKShapeNode
        let spin = exitNode.childNode(withName: "spin") as? SKShapeNode
        let core = exitNode.childNode(withName: "core") as? SKSpriteNode
        if session.sim.exitOpen {
            outer?.strokeColor = UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 1)
            outer?.glowWidth = 16
            spin?.strokeColor = UIColor(red: 0.7, green: 0.95, blue: 1, alpha: 1)
            core?.alpha = 0.85
        } else {
            outer?.strokeColor = UIColor.white.withAlphaComponent(0.18)
            outer?.glowWidth = 3
            spin?.strokeColor = UIColor.white.withAlphaComponent(0.2)
            core?.alpha = 0.28
        }
    }

    private func shockwave(at point: CGPoint, color: UIColor, start: CGFloat = 12, end: CGFloat = 86) {
        let ring = SKShapeNode(circleOfRadius: start)
        ring.position = point
        ring.strokeColor = color
        ring.lineWidth = 3
        ring.glowWidth = 10
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

    private static func arc(radius: CGFloat, fraction: Double) -> CGPath {
        let path = CGMutablePath()
        let end = CGFloat(fraction) * .pi * 2
        path.addArc(center: .zero, radius: radius, startAngle: 0, endAngle: end, clockwise: false)
        return path
    }

    private static func color(for kind: BonusKind) -> UIColor {
        switch kind {
        case .shield: UIColor(red: 0.4, green: 1, blue: 0.65, alpha: 1)
        case .freeze: UIColor(red: 0.55, green: 0.82, blue: 1, alpha: 1)
        case .surge: UIColor(red: 1, green: 0.82, blue: 0.28, alpha: 1)
        case .pulse: UIColor(red: 0.85, green: 0.4, blue: 1, alpha: 1)
        case .magnet: UIColor(red: 1, green: 0.45, blue: 0.7, alpha: 1)
        }
    }

    private var worldScale: CGFloat {
        size.width / CGFloat(max(session.level.worldWidth, 1))
    }

    private func mapped(_ wall: AABB) -> CGRect {
        CGRect(
            x: wall.minX * Double(worldScale),
            y: wall.minY * Double(worldScale),
            width: wall.width * Double(worldScale),
            height: wall.height * Double(worldScale)
        )
    }

    private func scenePoint(_ v: Vec2) -> CGPoint {
        CGPoint(x: v.x * Double(worldScale), y: v.y * Double(worldScale))
    }

    private func world(_ p: CGPoint) -> Vec2 {
        Vec2(x: Double(p.x / worldScale), y: Double(p.y / worldScale))
    }
}
