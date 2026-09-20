import QuartzCore
import SpriteKit
import UIKit

@MainActor
final class GameScene: SKScene {
    unowned let session: GameSession
    var onEvents: (([SimEvent]) -> Void)?

    var playerNode: SKNode!
    var echoNodes: [SKNode] = []
    var sparkNodes: [Int: SKNode] = [:]
    var bonusNodes: [Int: SKNode] = [:]
    var exitNode: SKNode!
    var lastTapAt: TimeInterval = 0
    var threatLine: SKShapeNode!
    var spawnBeacon: SKNode!
    var ambienceNode: SKNode!
    var decorationNode: SKNode!
    var moverNodes: [Int: SKNode] = [:]
    var gravityWellNodes: [Int: SKNode] = [:]
    var riftNodes: [Int: SKNode] = [:]
    var gateNodes: [Int: SKNode] = [:]
    var gateFrames: [Int: [SKSpriteNode]] = [:]
    var gateSolidStates: [Int: Bool] = [:]
    var laserNodes: [Int: SKNode] = [:]
    var scarNodes: [Int: SKNode] = [:]
    var ghostNodes: [SKNode] = []
    var frostOverlay: SKSpriteNode!
    var realityBackdrop: SKSpriteNode!
    var lastTime: TimeInterval = 0
    var trailAcc: TimeInterval = 0
    var trailBudget = 0
    var trailLayer: SKNode!
    var trails: TrailRenderer!
    var magnetLinks: SKShapeNode!
    var lastPlayerScene = CGPoint.zero
    var lastSampledSimTime: TimeInterval = 0
    var dyingMoverIDs = Set<Int>()
    var wasExitOpen = false
    var displayed: RenderFrame!
    var pendingPlayerTrailBreak = false

    init(session: GameSession, size: CGSize) {
        self.session = session
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = session.level.theme.sky.uiColor
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
        moverNodes.removeAll()
        gravityWellNodes.removeAll()
        riftNodes.removeAll()
        gateNodes.removeAll()
        gateFrames.removeAll()
        gateSolidStates.removeAll()
        laserNodes.removeAll()
        scarNodes.removeAll()
        ghostNodes.removeAll()
        lastTime = 0
        backgroundColor = session.level.theme.sky.uiColor
        trailAcc = 0
        trailBudget = 0
        lastPlayerScene = .zero
        lastSampledSimTime = 0
        dyingMoverIDs.removeAll()
        wasExitOpen = false
        pendingPlayerTrailBreak = false
        displayed = RenderFrame(simulation: session.sim)
        trailLayer = SKNode()
        trailLayer.name = "trails"
        trailLayer.zPosition = VisualLayer.trails
        addChild(trailLayer)
        trails = TrailRenderer(parent: trailLayer)
        magnetLinks = SKShapeNode()
        magnetLinks.name = "magnetLinks"
        magnetLinks.strokeColor = UIColor(red: 1, green: 0.50, blue: 0.72, alpha: 0.55)
        magnetLinks.lineWidth = 1.1
        magnetLinks.glowWidth = 0
        magnetLinks.lineCap = .round
        magnetLinks.zPosition = VisualLayer.pickups - 0.2
        addChild(magnetLinks)
        realityBackdrop = SKSpriteNode(
            texture: GlowTextures.candyTimeline,
            size: CGSize(width: size.width * 1.08, height: size.height * 1.08)
        )
        realityBackdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        realityBackdrop.zPosition = 0.25
        realityBackdrop.alpha = 0
        realityBackdrop.color = UIColor(red: 0.75, green: 0.45, blue: 1, alpha: 1)
        realityBackdrop.colorBlendFactor = 0.04
        realityBackdrop.run(.repeatForever(.sequence([
            .group([
                .moveBy(x: 3, y: 5, duration: 3.8),
                .scaleY(to: 1.025, duration: 3.8),
                .rotate(toAngle: 0.008, duration: 3.8, shortestUnitArc: true),
            ]),
            .group([
                .moveBy(x: -6, y: -10, duration: 4.6),
                .scaleY(to: 0.985, duration: 4.6),
                .rotate(toAngle: -0.008, duration: 4.6, shortestUnitArc: true),
            ]),
            .group([
                .moveBy(x: 3, y: 5, duration: 3.8),
                .scaleY(to: 1, duration: 3.8),
                .rotate(toAngle: 0, duration: 3.8, shortestUnitArc: true),
            ]),
        ])))
        addChild(realityBackdrop)
        ambienceNode = SKNode()
        ambienceNode.zPosition = 1.5
        addChild(ambienceNode)
        decorationNode = SKNode()
        decorationNode.zPosition = 1.72
        addChild(decorationNode)
        buildArena()
        buildAmbient()
        buildDecorations()
        buildExit()
        buildSparks()
        buildBonuses()
        buildFields()
        buildMovers()
        buildGravityWells()
        buildRifts()
        buildGates()
        buildLasers()
        buildSpawnBeacon()
        frostOverlay = SKSpriteNode(texture: GlowTextures.frostVignette, color: .clear, size: size)
        frostOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        frostOverlay.zPosition = 20
        frostOverlay.blendMode = .alpha
        frostOverlay.alpha = 0
        frostOverlay.isUserInteractionEnabled = false
        addChild(frostOverlay)
        buildPlayer()
        threatLine = SKShapeNode()
        threatLine.strokeColor = UIColor(red: 1, green: 0.45, blue: 0.6, alpha: 0.85)
        threatLine.lineWidth = 1.6
        threatLine.glowWidth = 0
        threatLine.lineCap = .round
        threatLine.zPosition = 8
        addChild(threatLine)
        apply(frame: RenderFrame(simulation: session.sim), mode: .live)
        updateSparkTimers()
        drawSpawnBeacon()
    }

    override func update(_ currentTime: TimeInterval) {
        if lastTime == 0 {
            lastTime = currentTime
            return
        }
        let dt = currentTime - lastTime
        lastTime = currentTime

        syncPauseClock()
        switch session.phase {
        case .paused:
            stopMotionEmitters()
            return
        case .dead, .won:
            stopMotionEmitters()
            endIdlePulse()
            return
        case .replaying:
            endIdlePulse()
            stopMotionEmitters()
            _ = session.advanceReplay(dt: dt)
            if let frame = currentReplayFrame() {
                apply(frame: frame, mode: .replay)
                sampleTrails(clock: frame.time)
            }
            return
        case .ballet:
            endIdlePulse()
            stopMotionEmitters()
            _ = session.advanceBallet(dt: dt)
            let frame = currentBalletFrame()
            apply(frame: frame, mode: .ballet)
            sampleTrails(clock: frame.time)
            return
        case .playing:
            break
        }

        session.advanceCooldowns(dt: dt)
        let events = session.sim.step(dt: dt, target: session.inputTarget)
        noteTrailEvents(events)
        session.handle(events: events, autoReplay: session.autoReplay)
        if events.contains(where: { event in
            if case .shieldBroke = event { return true }
            return false
        }) {
            shieldBreakEffect(at: scenePoint(session.sim.playerPosition))
        }
        if !events.isEmpty { onEvents?(events) }
        let live = session.hasStarted
        ambienceNode.speed = live ? 1 : 0
        exitNode.speed = live ? 1 : 0
        spawnBeacon.speed = live ? 1 : 0
        let frozen = session.sim.effects.isFrozen
        let anchored = session.sim.effects.isAnchored
        decorationNode.speed = live ? (frozen ? 0.18 : anchored ? CGFloat(session.sim.timelineScale) : 1) : 0.32
        let spinning: CGFloat = live ? CGFloat(session.sim.timelineScale) : 0
        sparkNodes.values.forEach { $0.speed = spinning }
        bonusNodes.values.forEach { $0.speed = spinning }
        moverNodes.values.forEach { $0.speed = spinning }
        echoNodes.forEach { $0.speed = 1 }
        riftNodes.values.forEach { $0.speed = spinning }
        laserNodes.values.forEach { $0.speed = spinning }
        apply(frame: RenderFrame(simulation: session.sim), mode: .live)
        drawSpawnBeacon()
        if live {
            drawThreat()
            updateSparkTimers()
            pulsePlayer()
            sampleTrails(clock: session.sim.time)
            syncMagnetLinks()
        }
    }

    func notePlayerTeleport() {
        pendingPlayerTrailBreak = true
    }

    func noteTrailEvents(_ events: [SimEvent]) {
        if events.contains(where: { event in
            if case .playerTeleported = event { return true }
            return false
        }) {
            pendingPlayerTrailBreak = true
        }
    }

    func currentReplayFrame() -> RenderFrame? {
        guard session.replaySnapshots.indices.contains(session.replayIndex) else { return nil }
        return RenderFrame(
            snapshot: session.replaySnapshots[session.replayIndex],
            gravityWells: session.sim.gravityWells,
            anchoredScale: session.sim.tuning.anchorTimeScale
        )
    }

    func currentBalletFrame() -> RenderFrame {
        if let frame = session.currentBalletFrame() {
            return frame
        }
        var frame = RenderFrame(simulation: session.sim)
        let t = session.balletPlaybackTime
        if let player = session.sim.recorder.position(at: t) {
            frame.player = player
        }
        frame.echoes = (0..<(session.sim.result?.echoesFaced ?? session.sim.echoCount)).map { index in
            let delay = Double(index + 1) * session.level.echoInterval
            return session.sim.recorder.position(at: max(0, t - delay)) ?? session.level.playerStart
        }
        frame.time = t
        return frame
    }

    func syncPauseClock() {
        let halt: Bool
        switch session.phase {
        case .playing: halt = false
        case .ballet: halt = false
        default: halt = true
        }
        for child in children {
            child.isPaused = halt
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let now = CACurrentMediaTime()
        if now - lastTapAt < 0.28, session.sim.tryDash() {
            abilityEffect(kind: .surge, at: session.sim.playerPosition)
            onEvents?([.dashed])
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
}

