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
    private var decorationNode: SKNode!
    private var moverNodes: [Int: SKNode] = [:]
    private var gravityWellNodes: [Int: SKNode] = [:]
    private var riftNodes: [Int: SKNode] = [:]
    private var gateNodes: [Int: SKNode] = [:]
    private var laserNodes: [Int: SKNode] = [:]
    private var scarNodes: [Int: SKNode] = [:]
    private var ghostNodes: [SKNode] = []
    private var frostOverlay: SKSpriteNode!
    private var realityBackdrop: SKSpriteNode!
    private var lastTime: TimeInterval = 0
    private var trailAcc: TimeInterval = 0
    private var trailBudget = 0

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
        laserNodes.removeAll()
        scarNodes.removeAll()
        ghostNodes.removeAll()
        lastTime = 0
        backgroundColor = session.level.theme.sky.uiColor
        trailAcc = 0
        trailBudget = 0
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
        frostOverlay.blendMode = .screen
        frostOverlay.alpha = 0
        frostOverlay.isUserInteractionEnabled = false
        addChild(frostOverlay)
        buildPlayer()
        threatLine = SKShapeNode()
        threatLine.strokeColor = UIColor(red: 1, green: 0.45, blue: 0.6, alpha: 0.85)
        threatLine.lineWidth = 2
        threatLine.glowWidth = 3
        threatLine.lineCap = .round
        threatLine.zPosition = 8
        addChild(threatLine)
        syncNodes()
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

        switch session.phase {
        case .paused, .dead, .won:
            return
        case .replaying:
            _ = session.advanceReplay(dt: dt)
            renderReplay()
            return
        case .ballet:
            _ = session.advanceBallet(dt: dt)
            renderBallet()
            dropTrails(dt: dt)
            return
        case .playing:
            break
        }

        session.advanceCooldowns(dt: dt)
        let events = session.sim.step(dt: dt, target: session.inputTarget)
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
        echoNodes.forEach { $0.speed = spinning }
        riftNodes.values.forEach { $0.speed = spinning }
        laserNodes.values.forEach { $0.speed = spinning }
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

    func abilityEffect(kind: BonusKind, at position: Vec2) {
        let point = scenePoint(position)
        let color = GlowTextures.color(for: kind)

        switch kind {
        case .freeze:
            winterBurst(at: point, color: color)
            shockwave(at: point, color: UIColor.white.withAlphaComponent(0.90), start: 10, end: 142)
            screenFlash(color: color, alpha: 0.15)
        case .shield, .ward:
            shieldFormEffect(at: point, color: color)
        case .surge:
            burst(at: position, color: color)
            speedStreaks(at: point, color: color)
            electricArcBurst(
                at: point,
                color: UIColor(red: 0.35, green: 0.80, blue: 1, alpha: 1),
                count: 9
            )
        case .pulse:
            timelineWaves(at: point, color: color, count: 3)
        case .magnet:
            shockwave(at: point, color: color, start: 20, end: 105)
            orbitalArcs(at: point, color: color)
        case .phase:
            timelineWaves(at: point, color: color, count: 2)
            phaseAfterimages(at: point, color: color)
        case .chrono:
            timelineWaves(at: point, color: color, count: 4)
            polygonWave(at: point, sides: 8, color: color, radius: 20, scale: 3.8)
        case .anchor:
            timelineWaves(at: point, color: color, count: 5)
            polygonWave(at: point, sides: 12, color: color, radius: 20, scale: 4.2)
            screenFlash(color: color, alpha: 0.08)
        case .repulse:
            shockwave(at: point, color: color, start: 18, end: 168)
            radialShards(at: point, color: color, count: 18)
            screenFlash(color: color, alpha: 0.07)
        case .prism:
            polygonWave(at: point, sides: 3, color: color, radius: 28, scale: 3.6)
            polygonWave(at: point, sides: 6, color: .white, radius: 20, scale: 2.8, delay: 0.08)
            orbitalArcs(at: point, color: color)
        case .blink:
            phaseAfterimages(at: point, color: color)
            timelineWaves(at: point, color: color, count: 2)
        }
    }

    func resonanceEffect(chain: Int, at position: Vec2) {
        let point = scenePoint(position)
        let tint = chain >= 4
            ? UIColor(red: 1, green: 0.42, blue: 0.78, alpha: 1)
            : UIColor(red: 1, green: 0.82, blue: 0.3, alpha: 1)
        shockwave(at: point, color: tint, start: 14, end: CGFloat(64 + min(chain, 6) * 9))

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "×\(chain)  RESONANCE"
        label.fontSize = CGFloat(12 + min(chain, 5))
        label.fontColor = tint
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: point.x, y: point.y + 42)
        label.zPosition = 25
        label.setScale(0.72)
        addChild(label)
        label.run(.sequence([
            .group([.scale(to: 1, duration: 0.16), .moveBy(x: 0, y: 12, duration: 0.16)]),
            .wait(forDuration: 0.42),
            .group([.fadeOut(withDuration: 0.26), .moveBy(x: 0, y: 14, duration: 0.26)]),
            .removeFromParent(),
        ]))
    }

    func laserDischarge(id: Int) {
        guard let laser = session.sim.lasers.first(where: { $0.id == id }) else { return }
        let color = UIColor(red: 1, green: 0.28, blue: 0.48, alpha: 1)
        shockwave(at: scenePoint(laser.start), color: color, start: 9, end: 48)
        shockwave(at: scenePoint(laser.end), color: color, start: 9, end: 48)
        screenFlash(color: color, alpha: 0.075)
        if let root = laserNodes[id] {
            for name in ["start", "end"] {
                root.childNode(withName: name)?.run(.sequence([
                    .scale(to: 1.32, duration: 0.07),
                    .scale(to: 1.16, duration: 0.16),
                ]))
            }
        }
    }

    func asteroidImpact(id: Int, material: AsteroidMaterial, at position: Vec2) {
        let point = scenePoint(position)
        let tint = Self.color(for: material)
        if let root = moverNodes[id] {
            root.removeAction(forKey: "impact")
            root.run(.sequence([
                .scale(to: 1.11, duration: 0.055),
                .scale(to: 0.96, duration: 0.075),
                .scale(to: 1, duration: 0.12),
            ]), withKey: "impact")
        }
        asteroidFragments(at: point, color: tint, count: material == .alloy ? 4 : 6, distance: 28)
        shockwave(at: point, color: tint, start: 7, end: 34)
    }

    func asteroidShatter(id: Int, material: AsteroidMaterial, at position: Vec2) {
        let point = scenePoint(position)
        let tint = Self.color(for: material)
        if let root = moverNodes.removeValue(forKey: id) {
            root.removeAllActions()
            root.speed = 1
            root.run(.sequence([
                .group([
                    .scale(to: 1.28, duration: 0.12),
                    .fadeAlpha(to: 0.2, duration: 0.12),
                ]),
                .group([
                    .scale(to: 0.18, duration: 0.24),
                    .fadeOut(withDuration: 0.24),
                ]),
                .removeFromParent(),
            ]))
        }
        asteroidFragments(at: point, color: tint, count: 16, distance: 72)
        shockwave(at: point, color: tint, start: 10, end: 78)
    }

    func realityShift(kind: RiftKind, at position: Vec2) {
        let point = scenePoint(position)
        let tint = kind == .candy
            ? UIColor(red: 1, green: 0.38, blue: 0.78, alpha: 1)
            : UIColor(red: 0.36, green: 0.82, blue: 1, alpha: 1)
        screenFlash(color: tint, alpha: 0.20)
        timelineWaves(at: point, color: tint, count: 4)
        radialShards(at: point, color: tint, count: 18)
        realityBackdrop.run(.sequence([
            .fadeAlpha(to: kind == .candy ? 0.64 : 0.22, duration: 0.20),
            .wait(forDuration: 0.12),
        ]))
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
        let theme = session.level.theme
        grid.path = path
        grid.strokeColor = theme.wallStroke.uiColor.withAlphaComponent(0.10)
        grid.lineWidth = 1
        grid.zPosition = 0
        addChild(grid)

        let border = SKShapeNode(rectOf: CGSize(width: w - 10, height: h - 10), cornerRadius: 8)
        border.position = CGPoint(x: w / 2, y: h / 2)
        border.strokeColor = theme.wallStroke.uiColor.withAlphaComponent(0.40)
        border.lineWidth = 2
        border.glowWidth = 8
        border.fillColor = .clear
        border.zPosition = 1
        addChild(border)

        if !session.level.walls.isEmpty {
            let fillPath = CGMutablePath()
            for wall in session.level.walls {
                fillPath.addRect(mapped(wall))
            }
            let fill = SKShapeNode(path: fillPath)
            fill.fillColor = theme.wallFill.uiColor.withAlphaComponent(0.97)
            fill.strokeColor = .clear
            fill.zPosition = 2
            addChild(fill)

            // Stroke only the union's exposed boundary. Drawing each rectangle separately
            // leaves bright seams wherever two wall pieces meet.
            let boundaryPath = wallBoundaryPath(session.level.walls)
            let glow = SKShapeNode(path: boundaryPath)
            glow.fillColor = .clear
            glow.strokeColor = theme.wallStroke.uiColor.withAlphaComponent(0.30)
            glow.lineWidth = 5
            glow.glowWidth = 9
            glow.lineCap = .round
            glow.lineJoin = .round
            glow.zPosition = 2.05
            addChild(glow)

            let edge = SKShapeNode(path: boundaryPath)
            edge.fillColor = .clear
            edge.strokeColor = theme.wallStroke.uiColor.withAlphaComponent(0.74)
            edge.lineWidth = 1.5
            edge.lineCap = .round
            edge.lineJoin = .round
            edge.zPosition = 2.1
            addChild(edge)
        }
    }

    private func buildAmbient() {
        let theme = session.level.theme
        let tint = theme.nebula.uiColor
        let nebulaCount: Int
        let moteCount: Int
        let rockCount: Int
        switch session.level.atmosphere {
        case .clear:
            nebulaCount = 0
            moteCount = 6
            rockCount = 0
        case .drift:
            nebulaCount = 1
            moteCount = 11
            rockCount = 3
        case .nebula:
            nebulaCount = 4
            moteCount = 17
            rockCount = 5
        }

        for _ in 0..<nebulaCount {
            let nebula = SKSpriteNode(texture: GlowTextures.blob)
            let s = CGFloat.random(in: 160...280)
            nebula.size = CGSize(width: s, height: s)
            nebula.alpha = CGFloat.random(in: 0.07...0.15)
            nebula.blendMode = .add
            nebula.color = tint
            nebula.colorBlendFactor = 0.85
            nebula.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            nebula.zPosition = 0.4
            nebula.run(.repeatForever(.sequence([
                .moveBy(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -30...40), duration: TimeInterval.random(in: 10...16)),
                .moveBy(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -40...30), duration: TimeInterval.random(in: 10...16)),
            ])))
            ambienceNode.addChild(nebula)
        }
        for _ in 0..<moteCount {
            let mote = SKSpriteNode(texture: GlowTextures.blob)
            let s = CGFloat.random(in: 8...24)
            mote.size = CGSize(width: s, height: s)
            mote.alpha = CGFloat.random(in: 0.10...0.28)
            mote.blendMode = .add
            mote.color = tint
            mote.colorBlendFactor = 0.55
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
        }
        for _ in 0..<rockCount {
            let rock = SKSpriteNode(texture: GlowTextures.asteroid)
            let s = CGFloat.random(in: 18...34)
            rock.size = CGSize(width: s, height: s)
            rock.color = tint
            rock.colorBlendFactor = 0.12
            rock.alpha = 0.22
            rock.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            rock.zPosition = 1.2
            rock.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: TimeInterval.random(in: 14...28))))
            rock.run(.repeatForever(.sequence([
                .moveBy(x: CGFloat.random(in: -80...80), y: CGFloat.random(in: 40...120), duration: TimeInterval.random(in: 9...16)),
                .moveBy(x: CGFloat.random(in: -80...80), y: CGFloat.random(in: -60...40), duration: TimeInterval.random(in: 9...16)),
            ])))
            ambienceNode.addChild(rock)
        }
    }

    private func buildDecorations() {
        for decoration in session.level.decorations {
            let tint = decorationColor(decoration.tone)
            switch decoration.kind {
            case .anchor(let radius):
                let root = SKNode()
                root.position = scenePoint(decoration.position)
                root.zRotation = CGFloat(decoration.rotation)
                let r = max(12, CGFloat(radius) * worldScale)

                let bloom = SKSpriteNode(texture: GlowTextures.blob)
                bloom.size = CGSize(width: r * 2.8, height: r * 2.8)
                bloom.blendMode = .add
                bloom.color = tint
                bloom.colorBlendFactor = 0.82
                bloom.alpha = 0.10

                let plate = SKShapeNode(path: Self.polygonPath(radius: r, sides: 6))
                plate.fillColor = tint.withAlphaComponent(0.045)
                plate.strokeColor = tint.withAlphaComponent(0.34)
                plate.lineWidth = 1.2
                plate.glowWidth = 3

                let dial = SKShapeNode(path: Self.segmentedCirclePath(radius: r * 0.66, segments: 6, coverage: 0.56))
                dial.fillColor = .clear
                dial.strokeColor = tint.withAlphaComponent(0.46)
                dial.lineWidth = 2
                dial.glowWidth = 2
                dial.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 15)))

                let core = SKShapeNode(circleOfRadius: max(2.5, r * 0.10))
                core.fillColor = tint.withAlphaComponent(0.72)
                core.strokeColor = .clear
                core.glowWidth = 4

                root.addChild(bloom)
                root.addChild(plate)
                root.addChild(dial)
                root.addChild(core)
                decorationNode.addChild(root)

            case .reactor(let radius, let spokes):
                let root = SKNode()
                root.position = scenePoint(decoration.position)
                root.zRotation = CGFloat(decoration.rotation)
                let r = max(24, CGFloat(radius) * worldScale)

                let bloom = SKSpriteNode(texture: GlowTextures.blob)
                bloom.size = CGSize(width: r * 2.35, height: r * 2.35)
                bloom.blendMode = .add
                bloom.color = tint
                bloom.colorBlendFactor = 0.86
                bloom.alpha = 0.055

                let spokePath = CGMutablePath()
                for index in 0..<max(4, spokes) {
                    let angle = CGFloat(index) / CGFloat(max(4, spokes)) * .pi * 2
                    spokePath.move(to: CGPoint(x: cos(angle) * r * 0.44, y: sin(angle) * r * 0.44))
                    spokePath.addLine(to: CGPoint(x: cos(angle) * r * 0.93, y: sin(angle) * r * 0.93))
                }
                let spokeNode = SKShapeNode(path: spokePath)
                spokeNode.strokeColor = tint.withAlphaComponent(0.16)
                spokeNode.lineWidth = 1
                spokeNode.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 36)))

                for (index, factor) in [CGFloat(1), 0.73, 0.45].enumerated() {
                    let ring = SKShapeNode(path: Self.segmentedCirclePath(
                        radius: r * factor,
                        segments: max(6, spokes - index * 2),
                        coverage: index == 1 ? 0.58 : 0.72
                    ))
                    ring.fillColor = .clear
                    ring.strokeColor = tint.withAlphaComponent(index == 2 ? 0.36 : 0.23)
                    ring.lineWidth = index == 2 ? 1.7 : 1.1
                    ring.glowWidth = index == 2 ? 3 : 1
                    let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                    ring.run(.repeatForever(.rotate(byAngle: direction * .pi * 2, duration: 22 + Double(index) * 7)))
                    root.addChild(ring)
                }

                root.addChild(bloom)
                root.addChild(spokeNode)
                decorationNode.addChild(root)

            case .lane(let end, let chevrons):
                let startPoint = scenePoint(decoration.position)
                let endPoint = scenePoint(end)
                let dx = endPoint.x - startPoint.x
                let dy = endPoint.y - startPoint.y
                let length = max(1, hypot(dx, dy))
                let direction = CGPoint(x: dx / length, y: dy / length)
                let normal = CGPoint(x: -direction.y, y: direction.x)

                let linePath = CGMutablePath()
                linePath.move(to: startPoint)
                linePath.addLine(to: endPoint)
                let line = SKShapeNode(path: linePath)
                line.strokeColor = tint.withAlphaComponent(0.13)
                line.lineWidth = 1.2
                line.glowWidth = 3

                let arrowPath = CGMutablePath()
                for index in 1...max(1, chevrons) {
                    let t = CGFloat(index) / CGFloat(max(1, chevrons) + 1)
                    let center = CGPoint(x: startPoint.x + dx * t, y: startPoint.y + dy * t)
                    let tip = CGPoint(x: center.x + direction.x * 7, y: center.y + direction.y * 7)
                    let tail = CGPoint(x: center.x - direction.x * 6, y: center.y - direction.y * 6)
                    arrowPath.move(to: CGPoint(x: tail.x + normal.x * 5, y: tail.y + normal.y * 5))
                    arrowPath.addLine(to: tip)
                    arrowPath.addLine(to: CGPoint(x: tail.x - normal.x * 5, y: tail.y - normal.y * 5))
                }
                let arrows = SKShapeNode(path: arrowPath)
                arrows.strokeColor = tint.withAlphaComponent(0.30)
                arrows.lineWidth = 1.4
                arrows.lineCap = .round
                arrows.lineJoin = .round
                arrows.glowWidth = 2
                arrows.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.48, duration: 1.1),
                    .fadeAlpha(to: 1, duration: 1.1),
                ])))

                decorationNode.addChild(line)
                decorationNode.addChild(arrows)

            case .hazardRing(let radius, let segments):
                let root = SKNode()
                root.position = scenePoint(decoration.position)
                root.zRotation = CGFloat(decoration.rotation)
                let r = max(16, CGFloat(radius) * worldScale)

                let outer = SKShapeNode(path: Self.segmentedCirclePath(radius: r, segments: max(6, segments), coverage: 0.54))
                outer.fillColor = .clear
                outer.strokeColor = tint.withAlphaComponent(0.34)
                outer.lineWidth = 2
                outer.glowWidth = 3
                outer.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 19)))

                let inner = SKShapeNode(path: Self.segmentedCirclePath(radius: r * 0.78, segments: max(4, segments / 2), coverage: 0.30))
                inner.fillColor = .clear
                inner.strokeColor = tint.withAlphaComponent(0.15)
                inner.lineWidth = 1
                inner.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 27)))

                root.addChild(outer)
                root.addChild(inner)
                decorationNode.addChild(root)
            }
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

            let reward = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            reward.fontSize = 9
            reward.fontColor = UIColor(red: 0.65, green: 0.9, blue: 1, alpha: 0.9)
            reward.verticalAlignmentMode = .center
            reward.position = CGPoint(x: 0, y: 41)
            reward.name = "timerReward"

            root.addChild(glow)
            root.addChild(gem)
            root.addChild(ring)
            root.addChild(label)
            root.addChild(reward)
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
            let aura = bonusAura(for: bonus.kind)
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
            root.addChild(aura)
            root.addChild(glow)
            root.addChild(gem)
            addChild(root)
            bonusNodes[bonus.id] = root
        }
    }

    private func bonusAura(for kind: BonusKind) -> SKNode {
        let root = SKNode()
        root.name = "abilityAura"
        root.zPosition = -2
        let tint = Self.color(for: kind)

        func addPulse(radius: CGFloat, delay: TimeInterval, scale: CGFloat = 1.55) {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.strokeColor = tint.withAlphaComponent(0.72)
            ring.fillColor = tint.withAlphaComponent(0.025)
            ring.lineWidth = 1.5
            ring.glowWidth = 5
            ring.alpha = 0
            root.addChild(ring)
            ring.run(.repeatForever(.sequence([
                .wait(forDuration: delay),
                .group([.fadeAlpha(to: 0.75, duration: 0.16), .scale(to: 1.04, duration: 0.16)]),
                .group([.fadeOut(withDuration: 1.0), .scale(to: scale, duration: 1.0)]),
                .scale(to: 1, duration: 0),
                .wait(forDuration: max(0, 1.45 - delay)),
            ])))
        }

        switch kind {
        case .freeze:
            let field = SKShapeNode(circleOfRadius: 53)
            field.fillColor = tint.withAlphaComponent(0.055)
            field.strokeColor = tint.withAlphaComponent(0.24)
            field.lineWidth = 1
            field.glowWidth = 7
            root.addChild(field)
            for index in 0..<6 {
                let snow = SKSpriteNode(texture: GlowTextures.snowflakeParticle)
                snow.size = CGSize(width: 10 + CGFloat(index % 3) * 3, height: 10 + CGFloat(index % 3) * 3)
                snow.position = CGPoint(x: CGFloat(index - 3) * 13, y: CGFloat(index % 2) * 22 - 11)
                snow.alpha = 0.42 + CGFloat(index % 3) * 0.15
                root.addChild(snow)
                snow.run(.repeatForever(.sequence([
                    .group([.moveBy(x: 4, y: -9, duration: 0.9 + Double(index) * 0.05), .fadeAlpha(to: 0.18, duration: 0.9)]),
                    .group([.moveBy(x: -4, y: 9, duration: 0), .fadeAlpha(to: 0.72, duration: 0)]),
                ])))
            }
            addPulse(radius: 32, delay: 0)

        case .surge:
            let electricity = UIColor(red: 0.34, green: 0.80, blue: 1, alpha: 1)
            for index in 0..<7 {
                let angle = CGFloat(index) / 7 * .pi * 2 + sin(CGFloat(index) * 2.31) * 0.34
                root.addChild(lightningBoltNode(
                    angle: angle,
                    inner: 17,
                    outer: 49 + CGFloat(index % 3) * 5,
                    baseSeed: index + 11,
                    color: electricity,
                    delay: Double(index) * 0.031,
                    persistent: true
                ))
            }

        case .shield, .ward:
            root.addChild(shieldBubbleNode(color: tint, radius: 45, layers: 1, animated: true))

        case .pulse:
            addPulse(radius: 24, delay: 0, scale: 2.15)
            addPulse(radius: 24, delay: 0.62, scale: 2.15)
            addPulse(radius: 24, delay: 1.24, scale: 2.15)

        case .magnet:
            root.addChild(magneticFieldAura(tint: tint, radius: 52, particleCount: 4))

        case .phase, .blink:
            for index in 0..<4 {
                let ghost = SKShapeNode(circleOfRadius: CGFloat(10 + index * 7))
                ghost.strokeColor = tint.withAlphaComponent(0.65 - CGFloat(index) * 0.10)
                ghost.lineWidth = 1.5
                ghost.glowWidth = 4
                ghost.position = CGPoint(x: CGFloat(index - 2) * 7, y: 0)
                root.addChild(ghost)
            }
            root.run(.repeatForever(.sequence([.moveBy(x: 8, y: 0, duration: 0.55), .moveBy(x: -8, y: 0, duration: 0.55)])))

        case .chrono, .anchor:
            addPulse(radius: 27, delay: 0, scale: kind == .anchor ? 1.85 : 2.15)
            let clock = SKShapeNode(path: Self.segmentedCirclePath(radius: 43, segments: 12, coverage: 0.32))
            clock.strokeColor = tint.withAlphaComponent(0.75)
            clock.lineWidth = 2
            clock.glowWidth = 4
            root.addChild(clock)
            clock.run(.repeatForever(.rotate(byAngle: kind == .anchor ? -.pi / 2 : .pi * 2, duration: kind == .anchor ? 4.2 : 7)))

        case .repulse:
            let crown = SKShapeNode(path: Self.segmentedCirclePath(radius: 47, segments: 16, coverage: 0.34))
            crown.strokeColor = tint.withAlphaComponent(0.85)
            crown.lineWidth = 2.4
            crown.glowWidth = 6
            root.addChild(crown)
            crown.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.55), .scale(to: 0.92, duration: 0.55)])))
            addPulse(radius: 30, delay: 0.3, scale: 1.9)

        case .prism:
            let triangle = SKShapeNode(path: Self.polygonPath(radius: 48, sides: 3))
            triangle.strokeColor = tint.withAlphaComponent(0.90)
            triangle.fillColor = tint.withAlphaComponent(0.045)
            triangle.lineWidth = 2
            triangle.glowWidth = 7
            root.addChild(triangle)
            let hex = SKShapeNode(path: Self.polygonPath(radius: 36, sides: 6))
            hex.strokeColor = UIColor.white.withAlphaComponent(0.62)
            hex.lineWidth = 1.2
            root.addChild(hex)
            root.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 10)))
        }
        return root
    }

    private func buildMovers() {
        for mover in session.sim.movers {
            addMoverNode(for: mover)
        }
    }

    private func addMoverNode(for mover: MoverState) {
        guard moverNodes[mover.id] == nil else { return }
        let root = SKNode()
        root.zPosition = 10
        root.position = scenePoint(mover.position)
        root.name = "asteroid-\(mover.id)"

        let diameter = max(58, CGFloat(mover.radius) * worldScale * 2.75)
        let tint = Self.color(for: mover.material)
        let secondary = Self.secondaryColor(for: mover.material)

        let glow = SKSpriteNode(texture: GlowTextures.blob)
        let glowSize = diameter * 1.48
        glow.size = CGSize(width: glowSize, height: glowSize)
        glow.blendMode = .add
        glow.color = tint
        glow.colorBlendFactor = 0.86
        glow.alpha = mover.material == .alloy ? 0.20 : 0.33
        glow.name = "glow"
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: mover.material == .crystal ? 0.48 : 0.38, duration: 0.75),
            .fadeAlpha(to: mover.material == .alloy ? 0.17 : 0.27, duration: 0.92),
        ])))

        let shell = SKShapeNode(
            path: Self.segmentedCirclePath(
                radius: diameter * 0.48,
                segments: mover.material == .alloy ? 8 : 5,
                coverage: mover.material == .ice ? 0.48 : 0.68
            )
        )
        shell.name = "shell"
        shell.fillColor = .clear
        shell.strokeColor = secondary.withAlphaComponent(0.82)
        shell.lineWidth = mover.material == .alloy ? 2.2 : 1.4
        shell.glowWidth = mover.material == .crystal ? 5 : 2
        shell.run(.repeatForever(.rotate(
            byAngle: mover.material == .alloy ? -.pi * 2 : .pi * 2,
            duration: mover.material == .ice ? 4.2 : 7.5
        )))

        let rock = SKSpriteNode(texture: GlowTextures.asteroid)
        rock.size = CGSize(width: diameter, height: diameter)
        rock.color = tint
        rock.colorBlendFactor = mover.material == .basalt ? 0.30 : 0.52
        rock.name = "rock"
        let spinDuration: TimeInterval = switch mover.material {
        case .basalt: 8.8
        case .ice: 6.2
        case .crystal: 5.0
        case .alloy: 10.5
        }
        rock.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: spinDuration)))

        let surface = SKShapeNode(
            path: Self.asteroidMaterialPath(
                material: mover.material,
                radius: diameter * 0.34,
                seed: mover.id + session.level.number * 11
            )
        )
        surface.name = "surface"
        surface.fillColor = .clear
        surface.strokeColor = secondary.withAlphaComponent(0.72)
        surface.lineWidth = mover.material == .alloy ? 1.8 : 1.35
        surface.glowWidth = mover.material == .crystal ? 4 : 1
        surface.run(.repeatForever(.rotate(
            byAngle: mover.material == .ice ? -.pi * 2 : .pi * 2,
            duration: mover.material == .crystal ? 7.2 : 12.0
        )))

        let cracks = SKShapeNode(
            path: Self.asteroidCrackPath(
                radius: diameter * 0.38,
                seed: mover.id + session.level.number * 17
            )
        )
        cracks.name = "cracks"
        cracks.fillColor = .clear
        cracks.strokeColor = UIColor.white.withAlphaComponent(0.96)
        cracks.lineWidth = 1.7
        cracks.glowWidth = 3
        cracks.alpha = 0

        let chips = SKNode()
        chips.name = "chips"
        chips.alpha = 0
        for index in 0..<6 {
            let angle = CGFloat(index) / 6 * .pi * 2 + CGFloat(mover.id) * 0.21
            let chip = SKShapeNode(path: Self.polygonPath(radius: 2.5 + CGFloat(index % 2), sides: 4))
            chip.position = CGPoint(x: cos(angle) * diameter * 0.43, y: sin(angle) * diameter * 0.43)
            chip.fillColor = index.isMultiple(of: 2) ? tint : secondary
            chip.strokeColor = .clear
            chip.glowWidth = 2
            chips.addChild(chip)
        }
        chips.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 6.4)))

        let timerRoot = SKNode()
        timerRoot.name = "fractureTimer"
        timerRoot.position = CGPoint(x: 0, y: diameter * 0.66)
        timerRoot.alpha = 0
        let timerPlate = SKShapeNode(rectOf: CGSize(width: 72, height: 23), cornerRadius: 11.5)
        timerPlate.fillColor = UIColor(red: 0.025, green: 0.045, blue: 0.10, alpha: 0.88)
        timerPlate.strokeColor = tint.withAlphaComponent(0.65)
        timerPlate.lineWidth = 1
        let timerArc = SKShapeNode()
        timerArc.name = "fractureArc"
        timerArc.strokeColor = tint
        timerArc.lineWidth = 2.2
        timerArc.lineCap = .round
        timerArc.glowWidth = 3
        timerArc.position = CGPoint(x: -24, y: 0)
        let timerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        timerLabel.name = "fractureLabel"
        timerLabel.fontSize = 9
        timerLabel.fontColor = .white
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.verticalAlignmentMode = .center
        timerLabel.position = CGPoint(x: -13, y: 0)
        timerRoot.addChild(timerPlate)
        timerRoot.addChild(timerArc)
        timerRoot.addChild(timerLabel)

        root.addChild(glow)
        root.addChild(shell)
        root.addChild(rock)
        root.addChild(surface)
        root.addChild(cracks)
        root.addChild(chips)
        root.addChild(timerRoot)
        addChild(root)
        moverNodes[mover.id] = root
    }

    private func buildGravityWells() {
        for well in session.sim.gravityWells {
            let root = SKNode()
            root.zPosition = 9.4
            root.position = scenePoint(well.position)

            let influence = SKShapeNode(circleOfRadius: CGFloat(well.influenceRadius) * worldScale)
            influence.name = "influence"
            influence.fillColor = UIColor(red: 0.35, green: 0.20, blue: 0.65, alpha: 0.045)
            influence.strokeColor = UIColor(red: 0.45, green: 0.70, blue: 1, alpha: 0.20)
            influence.lineWidth = 1.2
            influence.glowWidth = 4
            influence.run(.repeatForever(.sequence([
                .scale(to: 0.92, duration: 1.4),
                .scale(to: 1.04, duration: 1.4),
            ])))

            let lensing = SKNode()
            lensing.name = "lensing"
            for index in 0..<3 {
                let radius = CGFloat(well.coreRadius) * worldScale * (1.05 + CGFloat(index) * 0.30)
                let arc = SKShapeNode(
                    path: Self.segmentedCirclePath(
                        radius: radius,
                        segments: 3 + index,
                        coverage: 0.42
                    )
                )
                arc.strokeColor = index == 1
                    ? UIColor(red: 1, green: 0.78, blue: 0.35, alpha: 0.86)
                    : UIColor(red: 0.42, green: 0.82, blue: 1, alpha: 0.72)
                arc.lineWidth = 1.5 + CGFloat(index) * 0.35
                arc.glowWidth = 5
                arc.xScale = 1.25
                arc.yScale = 0.58 + CGFloat(index) * 0.08
                arc.zRotation = CGFloat(index) * 0.72
                arc.run(.repeatForever(.rotate(
                    byAngle: index.isMultiple(of: 2) ? .pi * 2 : -.pi * 2,
                    duration: 3.8 + Double(index) * 1.2
                )))
                lensing.addChild(arc)
            }

            let orbiters = SKNode()
            orbiters.name = "orbiters"
            for index in 0..<6 {
                let angle = CGFloat(index) / 6 * .pi * 2
                let mote = SKSpriteNode(texture: GlowTextures.blob)
                mote.size = CGSize(width: 5 + CGFloat(index % 2) * 2, height: 5 + CGFloat(index % 2) * 2)
                mote.position = CGPoint(
                    x: cos(angle) * CGFloat(well.coreRadius) * worldScale * 1.55,
                    y: sin(angle) * CGFloat(well.coreRadius) * worldScale * 0.82
                )
                mote.color = index.isMultiple(of: 3)
                    ? UIColor(red: 1, green: 0.75, blue: 0.3, alpha: 1)
                    : UIColor(red: 0.45, green: 0.85, blue: 1, alpha: 1)
                mote.colorBlendFactor = 0.8
                mote.blendMode = .add
                orbiters.addChild(mote)
            }
            orbiters.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 4.8)))

            let sprite = SKSpriteNode(texture: GlowTextures.blackHole)
            sprite.name = "core"
            let diameter = max(92, CGFloat(well.coreRadius) * worldScale * 3.4)
            sprite.size = CGSize(width: diameter, height: diameter)
            sprite.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 8.5)))

            root.addChild(influence)
            root.addChild(lensing)
            root.addChild(orbiters)
            root.addChild(sprite)
            addChild(root)
            gravityWellNodes[well.id] = root
        }
    }

    private func buildRifts() {
        for rift in session.sim.rifts {
            let root = SKNode()
            root.zPosition = 8
            root.position = scenePoint(rift.position)
            let color: UIColor = switch rift.kind {
            case .calm: UIColor(red: 0.55, green: 0.82, blue: 1, alpha: 1)
            case .collision: UIColor(red: 1, green: 0.30, blue: 0.48, alpha: 1)
            case .warp: UIColor(red: 0.45, green: 0.48, blue: 1, alpha: 1)
            case .candy: UIColor(red: 1, green: 0.40, blue: 0.78, alpha: 1)
            }
            let glow = SKSpriteNode(texture: GlowTextures.blob)
            let s = CGFloat(rift.radius) * worldScale * 2.4
            glow.size = CGSize(width: s, height: s)
            glow.blendMode = .add
            glow.color = color
            glow.colorBlendFactor = 0.8
            glow.alpha = 0.7
            glow.run(.repeatForever(.sequence([
                .scale(to: 1.12, duration: 0.7),
                .scale(to: 0.88, duration: 0.7),
            ])))
            let ring = SKShapeNode(circleOfRadius: CGFloat(rift.radius) * worldScale)
            ring.strokeColor = color
            ring.lineWidth = 2
            ring.glowWidth = 6
            ring.fillColor = color.withAlphaComponent(0.08)
            ring.run(.repeatForever(.rotate(byAngle: .pi, duration: 5)))
            root.addChild(glow)

            let orbit = SKNode()
            orbit.name = "riftOrbit"
            for index in 0..<8 {
                let angle = CGFloat(index) / 8 * .pi * 2
                let shard = SKShapeNode(rectOf: CGSize(width: 2.2, height: 8 + CGFloat(index % 3) * 2), cornerRadius: 1)
                shard.position = CGPoint(
                    x: cos(angle) * s * 0.72,
                    y: sin(angle) * s * 0.48
                )
                shard.zRotation = angle - .pi / 2
                shard.fillColor = index.isMultiple(of: 3) ? .white : color
                shard.strokeColor = .clear
                shard.glowWidth = 4
                orbit.addChild(shard)
            }
            orbit.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: rift.kind == .candy ? 3.8 : 5.4)))
            root.addChild(orbit)

            if rift.kind == .warp || rift.kind == .candy {
                let tear = SKSpriteNode(texture: GlowTextures.dimensionalRift)
                tear.name = "tear"
                let tearWidth = max(105, s * 2.15)
                tear.size = CGSize(width: tearWidth, height: tearWidth * 1.42)
                tear.color = color
                tear.colorBlendFactor = rift.kind == .candy ? 0.28 : 0.08
                tear.blendMode = .add
                tear.run(.repeatForever(.sequence([
                    .group([
                        .rotate(toAngle: 0.08, duration: 0.62, shortestUnitArc: true),
                        .scaleX(to: 0.94, duration: 0.62),
                    ]),
                    .group([
                        .rotate(toAngle: -0.08, duration: 0.74, shortestUnitArc: true),
                        .scaleX(to: 1.06, duration: 0.74),
                    ]),
                ])))
                root.addChild(tear)
            }
            root.addChild(ring)
            addChild(root)
            riftNodes[rift.id] = root
        }
    }

    private func buildGates() {
        let theme = session.level.theme
        for gate in session.sim.gates {
            let rect = mapped(gate.area)
            let node = SKShapeNode(rect: rect, cornerRadius: 10)
            node.fillColor = theme.wallStroke.uiColor.withAlphaComponent(0.35)
            node.strokeColor = theme.wallStroke.uiColor
            node.lineWidth = 1.5
            node.glowWidth = 5
            node.zPosition = 2.6
            addChild(node)
            gateNodes[gate.id] = node
        }
    }

    private func buildLasers() {
        for laser in session.sim.lasers {
            let path = beamPath(for: laser)

            let root = SKNode()
            root.zPosition = 8.6

            let aura = SKShapeNode(path: path)
            aura.name = "aura"
            aura.strokeColor = UIColor(red: 1, green: 0.16, blue: 0.42, alpha: 1)
            aura.lineWidth = max(6, CGFloat(laser.beamWidth) * worldScale * 2.1)
            aura.lineCap = .round
            aura.glowWidth = 18
            aura.alpha = 0

            let warning = SKShapeNode(path: path)
            warning.name = "warning"
            warning.strokeColor = UIColor(red: 1, green: 0.32, blue: 0.46, alpha: 1)
            warning.lineWidth = max(2, CGFloat(laser.beamWidth) * worldScale * 0.65)
            warning.lineCap = .round
            warning.glowWidth = 4

            let core = SKShapeNode(path: path)
            core.name = "core"
            core.strokeColor = .white
            core.lineWidth = max(2, CGFloat(laser.beamWidth) * worldScale)
            core.lineCap = .round
            core.glowWidth = 12
            core.alpha = 0

            root.addChild(aura)
            root.addChild(warning)
            root.addChild(core)
            root.addChild(laserEmitter(at: scenePoint(laser.start), name: "start"))
            root.addChild(laserEmitter(at: scenePoint(laser.end), name: "end"))
            for index in 0..<4 {
                let pulse = SKSpriteNode(texture: GlowTextures.blob)
                pulse.name = "pulse-\(index)"
                pulse.size = CGSize(width: 18, height: 18)
                pulse.blendMode = .add
                pulse.color = UIColor(red: 1, green: 0.22, blue: 0.48, alpha: 1)
                pulse.colorBlendFactor = 0.72
                pulse.alpha = 0
                root.addChild(pulse)
            }
            addChild(root)
            laserNodes[laser.id] = root
        }
        syncLasers()
    }

    private func laserEmitter(at point: CGPoint, name: String) -> SKNode {
        let root = SKNode()
        root.name = name
        root.position = point
        let glow = SKSpriteNode(texture: GlowTextures.blob)
        glow.name = "glow"
        glow.size = CGSize(width: 42, height: 42)
        glow.blendMode = .add
        glow.color = UIColor(red: 1, green: 0.18, blue: 0.46, alpha: 1)
        glow.colorBlendFactor = 0.72
        glow.alpha = 0.44
        let housing = SKSpriteNode(texture: GlowTextures.laserEmitter)
        housing.name = "housing"
        housing.size = CGSize(width: 43, height: 43)
        let lens = SKSpriteNode(texture: GlowTextures.blob)
        lens.size = CGSize(width: 12, height: 12)
        lens.blendMode = .add
        lens.color = UIColor(red: 1, green: 0.32, blue: 0.68, alpha: 1)
        lens.colorBlendFactor = 0.65
        lens.name = "lens"
        lens.run(.repeatForever(.sequence([
            .scale(to: 1.22, duration: 0.42),
            .scale(to: 0.82, duration: 0.42),
        ])))
        root.addChild(glow)
        root.addChild(housing)
        root.addChild(lens)
        return root
    }

    private func syncGates() {
        for gate in session.sim.gates {
            guard let node = gateNodes[gate.id] else { continue }
            node.alpha = gate.solid ? 0.95 : 0.12
        }
    }

    private func syncLasers() {
        for laser in session.sim.lasers {
            guard let root = laserNodes[laser.id],
                  let aura = root.childNode(withName: "aura") as? SKShapeNode,
                  let warning = root.childNode(withName: "warning") as? SKShapeNode,
                  let core = root.childNode(withName: "core") as? SKShapeNode else { continue }
            let emitters = [root.childNode(withName: "start"), root.childNode(withName: "end")]
            let path = beamPath(for: laser)
            aura.path = path
            warning.path = path
            core.path = path
            let start = scenePoint(laser.start)
            let end = scenePoint(laser.end)
            emitters[0]?.position = start
            emitters[1]?.position = end
            let angle = atan2(end.y - start.y, end.x - start.x)
            emitters[0]?.zRotation = angle
            emitters[1]?.zRotation = angle + .pi

            if session.sim.effects.isPrismatic {
                aura.strokeColor = UIColor(red: 0.40, green: 1.00, blue: 0.84, alpha: 1)
                aura.alpha = 0.18
                warning.strokeColor = UIColor(red: 0.72, green: 0.48, blue: 1.00, alpha: 1)
                warning.alpha = 0.62
                core.strokeColor = UIColor(red: 0.55, green: 0.94, blue: 1.00, alpha: 1)
                core.alpha = laser.phase == .firing ? 0.58 : 0.18
                emitters.forEach { $0?.setScale(0.98) }
                for index in 0..<4 {
                    guard let pulse = root.childNode(withName: "pulse-\(index)") else { continue }
                    let phase = (session.sim.playbackTime * 0.8 + Double(index) / 4)
                        .truncatingRemainder(dividingBy: 1)
                    pulse.position = scenePoint(laser.start.lerp(laser.end, phase))
                    pulse.alpha = 0.38
                }
                continue
            }

            if session.sim.effects.isFrozen {
                aura.strokeColor = UIColor(red: 0.42, green: 0.80, blue: 1, alpha: 1)
                aura.alpha = 0.08
                warning.strokeColor = UIColor(red: 0.55, green: 0.86, blue: 1, alpha: 1)
                warning.alpha = 0.34
                core.strokeColor = UIColor(red: 0.72, green: 0.94, blue: 1, alpha: 1)
                core.alpha = 0.10
                emitters.forEach { $0?.setScale(0.92) }
                for index in 0..<4 { root.childNode(withName: "pulse-\(index)")?.alpha = 0 }
                continue
            }

            aura.strokeColor = UIColor(red: 1, green: 0.16, blue: 0.42, alpha: 1)
            warning.strokeColor = UIColor(red: 1, green: 0.32, blue: 0.46, alpha: 1)
            core.strokeColor = .white
            switch laser.phase {
            case .idle:
                aura.alpha = 0
                warning.alpha = 0.12
                core.alpha = 0
                emitters.forEach { $0?.setScale(0.82) }
            case .charging(let progress):
                aura.alpha = 0.03 + CGFloat(progress) * 0.13
                warning.alpha = 0.22 + CGFloat(progress) * 0.58
                core.alpha = 0.04 + CGFloat(progress) * 0.14
                let scale = 0.9 + CGFloat(progress) * 0.22
                emitters.forEach { $0?.setScale(scale) }
            case .firing:
                aura.alpha = 0.42
                warning.alpha = 1
                core.alpha = 0.92
                emitters.forEach { $0?.setScale(1.16) }
            }

            for index in 0..<4 {
                guard let pulse = root.childNode(withName: "pulse-\(index)") else { continue }
                if case .firing = laser.phase {
                    let t = (session.sim.playbackTime * 1.45 + Double(index) / 4)
                        .truncatingRemainder(dividingBy: 1)
                    pulse.position = scenePoint(laser.start.lerp(laser.end, t))
                    pulse.alpha = 0.78
                    pulse.setScale(index.isMultiple(of: 2) ? 0.8 : 1.08)
                } else {
                    pulse.alpha = 0
                }
            }
        }
    }

    private func syncScars() {
        let live = Set(session.sim.scars.map(\.id))
        for (id, node) in scarNodes where !live.contains(id) {
            node.removeFromParent()
            scarNodes.removeValue(forKey: id)
        }
        for scar in session.sim.scars {
            let node: SKNode
            if let existing = scarNodes[scar.id] {
                node = existing
            } else {
                let root = SKNode()
                root.zPosition = 9
                let glow = SKSpriteNode(texture: GlowTextures.blob)
                let s = CGFloat(scar.radius) * worldScale * 2.6
                glow.size = CGSize(width: s, height: s)
                glow.blendMode = .add
                glow.color = UIColor(red: 0.95, green: 0.4, blue: 1, alpha: 1)
                glow.colorBlendFactor = 0.85
                glow.alpha = 0.8
                let ring = SKShapeNode(circleOfRadius: CGFloat(scar.radius) * worldScale)
                ring.strokeColor = UIColor(red: 1, green: 0.45, blue: 0.85, alpha: 1)
                ring.lineWidth = 2
                ring.glowWidth = 6
                ring.fillColor = UIColor(red: 0.7, green: 0.2, blue: 0.6, alpha: 0.18)
                root.addChild(glow)
                root.addChild(ring)
                addChild(root)
                scarNodes[scar.id] = root
                node = root
            }
            node.position = scenePoint(scar.position)
            node.alpha = CGFloat(min(1, scar.remaining / 0.8))
        }
    }

    private func syncFrostCrown() {
        let existing = playerNode.childNode(withName: "frost")
        if session.sim.effects.isFrozen {
            if existing == nil {
                let frost = SKNode()
                frost.name = "frost"
                frost.zPosition = 2
                let snowflake = SKSpriteNode(texture: GlowTextures.snowflakeParticle)
                snowflake.size = CGSize(width: 47, height: 47)
                snowflake.alpha = 0.78
                snowflake.blendMode = .add
                snowflake.run(.repeatForever(.sequence([
                    .group([.scale(to: 1.10, duration: 0.65), .fadeAlpha(to: 0.92, duration: 0.65)]),
                    .group([.scale(to: 0.94, duration: 0.70), .fadeAlpha(to: 0.64, duration: 0.70)]),
                ])))
                frost.addChild(snowflake)

                let mist = SKEmitterNode()
                mist.particleTexture = GlowTextures.snowflakeParticle
                mist.particleBirthRate = 9
                mist.particleLifetime = 1.5
                mist.particleLifetimeRange = 0.45
                mist.particlePositionRange = CGVector(dx: 48, dy: 48)
                mist.emissionAngleRange = .pi * 2
                mist.particleSpeed = 9
                mist.particleSpeedRange = 6
                mist.particleScale = 0.065
                mist.particleScaleRange = 0.028
                mist.particleScaleSpeed = -0.025
                mist.particleAlpha = 0.62
                mist.particleAlphaSpeed = -0.38
                mist.particleBlendMode = .add
                frost.addChild(mist)
                playerNode.addChild(frost)
            }
        } else {
            existing?.removeFromParent()
        }
    }

    private func syncWinterEffect() {
        let existing = childNode(withName: "winterStorm")
        if session.sim.effects.isFrozen {
            guard existing == nil else { return }
            frostOverlay.removeAllActions()
            frostOverlay.run(.fadeAlpha(to: 0.64, duration: 0.22))

            let storm = SKNode()
            storm.name = "winterStorm"
            storm.zPosition = 19

            let snow = SKEmitterNode()
            snow.particleTexture = GlowTextures.snowflakeParticle
            snow.position = CGPoint(x: size.width / 2, y: size.height + 24)
            snow.particlePositionRange = CGVector(dx: size.width * 1.12, dy: 70)
            snow.particleBirthRate = 12
            snow.particleLifetime = 7.2
            snow.particleLifetimeRange = 2.0
            snow.emissionAngle = -.pi / 2
            snow.emissionAngleRange = 0.28
            snow.particleSpeed = 34
            snow.particleSpeedRange = 16
            snow.xAcceleration = 5
            snow.particleScale = 0.085
            snow.particleScaleRange = 0.05
            snow.particleScaleSpeed = -0.004
            snow.particleRotationRange = .pi * 2
            snow.particleRotationSpeed = 0.35
            snow.particleAlpha = 0.72
            snow.particleAlphaRange = 0.22
            snow.particleAlphaSpeed = -0.055
            snow.particleBlendMode = .add
            storm.addChild(snow)

            for index in 0..<3 {
                let fog = SKSpriteNode(texture: GlowTextures.blob)
                fog.size = CGSize(width: 270 + CGFloat(index) * 85, height: 120 + CGFloat(index) * 34)
                fog.position = CGPoint(
                    x: size.width * (0.18 + CGFloat(index) * 0.31),
                    y: size.height * (0.24 + CGFloat(index % 2) * 0.34)
                )
                fog.color = UIColor(red: 0.45, green: 0.80, blue: 1, alpha: 1)
                fog.colorBlendFactor = 0.82
                fog.alpha = 0.045
                fog.blendMode = .add
                fog.run(.repeatForever(.sequence([
                    .group([.moveBy(x: 24, y: 5, duration: 3.4 + Double(index)), .fadeAlpha(to: 0.085, duration: 3.4 + Double(index))]),
                    .group([.moveBy(x: -24, y: -5, duration: 4.1 + Double(index)), .fadeAlpha(to: 0.035, duration: 4.1 + Double(index))]),
                ])))
                storm.addChild(fog)
            }
            storm.alpha = 0
            addChild(storm)
            storm.run(.fadeIn(withDuration: 0.25))
        } else if let existing {
            existing.name = nil
            existing.run(.sequence([.fadeOut(withDuration: 0.28), .removeFromParent()]))
            frostOverlay.removeAllActions()
            frostOverlay.run(.fadeOut(withDuration: 0.32))
        }
    }

    private func syncShieldBubble() {
        let charges = session.sim.effects.shieldCharges
        let existing = playerNode.childNode(withName: "shieldBubble")
        let renderedCharges = existing?.userData?["charges"] as? Int
        if charges > 0 {
            guard existing == nil || renderedCharges != charges else { return }
            existing?.removeFromParent()
            let bubble = shieldBubbleNode(
                color: UIColor(red: 0.35, green: 1.0, blue: 0.70, alpha: 1),
                radius: 33,
                layers: min(2, charges),
                animated: true
            )
            bubble.name = "shieldBubble"
            bubble.zPosition = 1
            bubble.userData = NSMutableDictionary(dictionary: ["charges": charges])
            bubble.setScale(0.35)
            playerNode.addChild(bubble)
            let form = SKAction.scale(to: 1, duration: 0.34)
            form.timingMode = .easeOut
            bubble.run(form)
        } else {
            existing?.removeFromParent()
        }
    }

    private func syncSurgeCrown() {
        let existing = playerNode.childNode(withName: "energyCrown")
        if session.sim.effects.isSurging {
            guard existing == nil else { return }
            let crown = SKNode()
            crown.name = "energyCrown"
            crown.zPosition = 3
            let electricity = UIColor(red: 0.45, green: 0.82, blue: 1, alpha: 1)
            for index in 0..<7 {
                let angle = CGFloat(index) / 7 * .pi * 2 + sin(CGFloat(index + 3) * 1.73) * 0.37
                crown.addChild(lightningBoltNode(
                    angle: angle,
                    inner: 10,
                    outer: 42 + CGFloat(index % 3) * 5,
                    baseSeed: index + 37,
                    color: electricity,
                    delay: Double(index) * 0.027,
                    persistent: true
                ))
            }
            playerNode.addChild(crown)
        } else {
            existing?.removeFromParent()
        }
    }

    private func syncMagnetCrown() {
        let existing = playerNode.childNode(withName: "magnetCrown")
        if session.sim.effects.isMagnet {
            guard existing == nil else { return }
            let crown = magneticFieldAura(
                tint: UIColor(red: 1, green: 0.45, blue: 0.70, alpha: 1),
                radius: 47,
                particleCount: 5
            )
            crown.name = "magnetCrown"
            crown.zPosition = 2
            playerNode.addChild(crown)
        } else {
            existing?.removeFromParent()
        }
    }

    private func syncAnchorCrown() {
        let existing = playerNode.childNode(withName: "anchorCrown")
        if session.sim.effects.isAnchored {
            guard existing == nil else { return }
            let crown = SKShapeNode(path: Self.segmentedCirclePath(radius: 31, segments: 12, coverage: 0.26))
            crown.name = "anchorCrown"
            crown.strokeColor = UIColor(red: 0.30, green: 0.88, blue: 1, alpha: 0.86)
            crown.lineWidth = 2
            crown.glowWidth = 5
            crown.zPosition = 3
            crown.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 5.5)))
            playerNode.addChild(crown)
        } else {
            existing?.removeFromParent()
        }
    }

    private func syncPrismCrown() {
        let existing = playerNode.childNode(withName: "prismCrown")
        if session.sim.effects.isPrismatic {
            guard existing == nil else { return }
            let crown = SKNode()
            crown.name = "prismCrown"
            crown.zPosition = 4
            let triangle = SKShapeNode(path: Self.polygonPath(radius: 34, sides: 3))
            triangle.strokeColor = UIColor(red: 0.60, green: 1.00, blue: 0.92, alpha: 0.94)
            triangle.lineWidth = 2.3
            triangle.glowWidth = 7
            triangle.fillColor = UIColor(red: 0.35, green: 0.88, blue: 1, alpha: 0.045)
            crown.addChild(triangle)
            let hex = SKShapeNode(path: Self.polygonPath(radius: 27, sides: 6))
            hex.strokeColor = UIColor.white.withAlphaComponent(0.74)
            hex.lineWidth = 1.1
            crown.addChild(hex)
            crown.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 7)))
            playerNode.addChild(crown)
        } else {
            existing?.removeFromParent()
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
        while echoNodes.count > session.sim.echoCount {
            echoNodes.removeLast().removeFromParent()
        }
        for (i, echo) in session.sim.echoes.enumerated() {
            echoNodes[i].position = scenePoint(echo)
        }
        syncGhosts()
        for spark in session.sim.sparks {
            sparkNodes[spark.id]?.isHidden = spark.collected
            sparkNodes[spark.id]?.position = scenePoint(spark.position)
        }
        for bonus in session.sim.bonuses {
            bonusNodes[bonus.id]?.isHidden = bonus.collected
        }
        syncMovers(session.sim.movers, frozen: session.sim.effects.isFrozen)
        for well in session.sim.gravityWells {
            gravityWellNodes[well.id]?.position = scenePoint(well.position)
            gravityWellNodes[well.id]?.alpha = session.sim.effects.isFrozen ? 0.52 : session.sim.effects.isAnchored ? 0.76 : 1
            gravityWellNodes[well.id]?.speed = CGFloat(session.sim.timelineScale)
        }
        for rift in session.sim.rifts {
            guard let node = riftNodes[rift.id] else { continue }
            node.position = scenePoint(rift.position)
            node.alpha = rift.open ? 1 : 0.22
            node.setScale(rift.open ? 1 : 0.72)
        }
        syncRealityBackdrop()
        for echo in echoNodes {
            echo.alpha = session.sim.effects.isFrozen ? 0.4 : session.sim.effects.isAnchored ? 0.70 : 1
        }
        syncGates()
        syncLasers()
        syncScars()
        syncWinterEffect()
        syncFrostCrown()
        syncSurgeCrown()
        syncMagnetCrown()
        syncShieldBubble()
        syncAnchorCrown()
        syncPrismCrown()
        exitNode.position = scenePoint(session.level.exit)
        refreshExit()
        if let halo = playerNode.childNode(withName: "halo") as? SKSpriteNode {
            if session.sim.effects.isPrismatic {
                halo.color = UIColor(red: 0.60, green: 1.00, blue: 0.92, alpha: 1)
                halo.colorBlendFactor = 0.72
            } else if session.sim.effects.isPhasing {
                halo.color = UIColor.white
                halo.colorBlendFactor = 0.7
            } else if session.sim.effects.shieldCharges > 0 {
                halo.color = UIColor(red: 0.45, green: 1, blue: 0.7, alpha: 1)
                halo.colorBlendFactor = 0.55
            } else if session.sim.effects.isSurging {
                halo.color = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
                halo.colorBlendFactor = 0.5
            } else if session.sim.effects.isAnchored {
                halo.color = UIColor(red: 0.30, green: 0.88, blue: 1, alpha: 1)
                halo.colorBlendFactor = 0.58
            } else if session.sim.effects.isFrozen {
                halo.color = UIColor(red: 0.55, green: 0.8, blue: 1, alpha: 1)
                halo.colorBlendFactor = 0.45
            } else {
                halo.colorBlendFactor = 0
            }
        }
    }

    private func syncMovers(_ states: [MoverState], frozen: Bool) {
        let liveIDs = Set(states.map(\.id))
        for id in Array(moverNodes.keys) where !liveIDs.contains(id) {
            moverNodes.removeValue(forKey: id)?.removeFromParent()
        }

        for mover in states {
            if moverNodes[mover.id] == nil {
                addMoverNode(for: mover)
            }
            guard let root = moverNodes[mover.id] else { continue }
            root.position = scenePoint(mover.position)
            root.alpha = frozen ? 0.88 : 1

            let iceShell = root.childNode(withName: "freezeShell")
            if frozen, iceShell == nil {
                let rockSize = (root.childNode(withName: "rock") as? SKSpriteNode)?.size.width ?? 64
                let shell = SKShapeNode(circleOfRadius: rockSize * 0.46)
                shell.name = "freezeShell"
                shell.zPosition = 5
                shell.fillColor = UIColor(red: 0.48, green: 0.83, blue: 1, alpha: 0.12)
                shell.strokeColor = UIColor(red: 0.76, green: 0.95, blue: 1, alpha: 0.82)
                shell.lineWidth = 1.4
                shell.glowWidth = 5
                for index in 0..<5 {
                    let crystal = SKSpriteNode(texture: GlowTextures.snowflakeParticle)
                    crystal.size = CGSize(width: 8, height: 8)
                    let angle = CGFloat(index) / 5 * .pi * 2 + 0.3
                    crystal.position = CGPoint(x: cos(angle) * rockSize * 0.39, y: sin(angle) * rockSize * 0.39)
                    crystal.alpha = 0.78
                    shell.addChild(crystal)
                }
                shell.setScale(0.72)
                root.addChild(shell)
                let freezeIn = SKAction.scale(to: 1, duration: 0.24)
                freezeIn.timingMode = .easeOut
                shell.run(freezeIn)
            } else if !frozen {
                iceShell?.removeFromParent()
            }

            let progress = CGFloat(mover.fractureProgress)
            let tint = Self.color(for: mover.material)
            if let rock = root.childNode(withName: "rock") as? SKSpriteNode {
                let scale = 1 - progress * 0.075
                rock.xScale = scale
                rock.yScale = scale
                rock.colorBlendFactor = mover.material == .basalt
                    ? 0.30 + progress * 0.22
                    : 0.52 + progress * 0.18
            }
            if let cracks = root.childNode(withName: "cracks") as? SKShapeNode {
                cracks.alpha = max(0, min(1, progress * 1.35))
                cracks.strokeColor = progress > 0.68
                    ? UIColor.white
                    : tint.withAlphaComponent(0.96)
            }
            root.childNode(withName: "chips")?.alpha = max(0, min(0.92, (progress - 0.28) * 1.7))

            guard let timer = root.childNode(withName: "fractureTimer") else { continue }
            let diameter = (root.childNode(withName: "rock") as? SKSpriteNode)?.size.height ?? 68
            let vertical = root.position.y > size.height - 76 ? -diameter * 0.67 : diameter * 0.67
            let horizontal: CGFloat
            if root.position.x < 42 {
                horizontal = 42 - root.position.x
            } else if root.position.x > size.width - 42 {
                horizontal = size.width - 42 - root.position.x
            } else {
                horizontal = 0
            }
            timer.position = CGPoint(x: horizontal, y: vertical)
            if let remaining = mover.fractureRemaining,
               let duration = mover.material.fractureDuration {
                timer.alpha = frozen ? 0.62 : 1
                let fraction = max(0, min(1, remaining / max(duration, 0.01)))
                let arc = timer.childNode(withName: "fractureArc") as? SKShapeNode
                arc?.path = Self.arc(radius: 7.2, fraction: fraction)
                arc?.strokeColor = fraction < 0.28
                    ? UIColor(red: 1, green: 0.35, blue: 0.45, alpha: 1)
                    : tint
                let label = timer.childNode(withName: "fractureLabel") as? SKLabelNode
                label?.text = "\(mover.material.shortLabel)  \(String(format: "%.1f", remaining))"
                if fraction < 0.28 {
                    timer.setScale(1 + 0.045 * abs(sin(CACurrentMediaTime() * 10)))
                } else {
                    timer.setScale(1)
                }
            } else {
                timer.alpha = 0
                timer.setScale(1)
            }
        }
    }

    private func syncRealityBackdrop() {
        switch session.sim.reality {
        case .normal:
            realityBackdrop.alpha = max(0, realityBackdrop.alpha - 0.045)
            realityBackdrop.xScale = 1
            backgroundColor = session.level.theme.sky.uiColor
        case .candy:
            realityBackdrop.alpha = min(0.64, realityBackdrop.alpha + 0.05)
            realityBackdrop.xScale = 1
            backgroundColor = UIColor(red: 0.055, green: 0.025, blue: 0.13, alpha: 1)
        case .mirror:
            realityBackdrop.alpha = min(0.20, realityBackdrop.alpha + 0.04)
            realityBackdrop.xScale = -1
            backgroundColor = UIColor(red: 0.02, green: 0.04, blue: 0.13, alpha: 1)
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
        while echoNodes.count > snap.echoes.count {
            echoNodes.removeLast().removeFromParent()
        }
        for (i, echo) in snap.echoes.enumerated() {
            echoNodes[i].position = scenePoint(echo)
        }
        syncMovers(snap.movers, frozen: snap.effects.isFrozen)
    }

    private func renderBallet() {
        let t = session.balletPlaybackTime
        let recorder = session.sim.recorder
        if let p = recorder.position(at: t) {
            playerNode.position = scenePoint(p)
        }
        let echoes = session.sim.result?.echoesFaced ?? session.sim.echoCount
        while echoNodes.count < echoes {
            let node = echoNode()
            addChild(node)
            echoNodes.append(node)
        }
        for i in 0..<echoes {
            let delay = Double(i + 1) * session.level.echoInterval
            if t >= delay, let p = recorder.position(at: t - delay) {
                echoNodes[i].isHidden = false
                echoNodes[i].position = scenePoint(p)
            } else if let p = recorder.position(at: 0) {
                echoNodes[i].isHidden = false
                echoNodes[i].position = scenePoint(p)
                echoNodes[i].alpha = 0.35
            }
        }
    }

    private func syncGhosts() {
        let live = session.sim.ghosts
        while ghostNodes.count < live.count {
            let node = echoNode()
            node.alpha = 0.7
            if let halo = node.childNode(withName: "halo") as? SKSpriteNode {
                halo.color = UIColor(red: 1, green: 0.35, blue: 0.45, alpha: 1)
                halo.colorBlendFactor = 0.8
            }
            addChild(node)
            ghostNodes.append(node)
        }
        while ghostNodes.count > live.count {
            ghostNodes.removeLast().removeFromParent()
        }
        for (i, ghost) in live.enumerated() {
            if let p = ghost.position(at: session.sim.time) {
                ghostNodes[i].isHidden = false
                ghostNodes[i].position = scenePoint(p)
                ghostNodes[i].alpha = 0.45 + 0.35 * abs(sin(CACurrentMediaTime() * 8))
            } else {
                ghostNodes[i].isHidden = true
            }
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
        let near = max(8, min(90, threat.distance))
        threatLine.lineWidth = CGFloat(3.8 - near / 40)
        threatLine.alpha = CGFloat(max(0.35, 1.1 - near / 70))
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
            let reward = root.childNode(withName: "timerReward") as? SKLabelNode
            if let duration = spark.timerDuration, let remaining = spark.timerRemaining, !spark.collected {
                let frac = max(0, min(1, remaining / duration))
                ring?.path = Self.arc(radius: 30, fraction: frac)
                ring?.strokeColor = spark.timedOut
                    ? UIColor(red: 1, green: 0.35, blue: 0.45, alpha: 0.55)
                    : UIColor(red: 1, green: 0.82, blue: 0.35, alpha: 0.95)
                if spark.timedOut {
                    label?.text = "CHARGE LOST"
                    label?.fontSize = 9
                    label?.fontColor = UIColor(red: 1, green: 0.48, blue: 0.55, alpha: 0.9)
                    reward?.text = ""
                } else {
                    label?.fontSize = 11
                    label?.fontColor = UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
                    label?.text = session.sim.effects.isFrozen
                        ? String(format: "PAUSED · %.0f", ceil(remaining))
                        : String(format: "%.0fs", ceil(remaining))
                    reward?.text = "+ FREEZE"
                }
            } else {
                ring?.path = Self.arc(radius: 30, fraction: 1)
                ring?.strokeColor = UIColor(red: 0.45, green: 0.9, blue: 1, alpha: 0.35)
                label?.text = ""
                reward?.text = ""
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

    private func radialShards(at point: CGPoint, color: UIColor, count: Int) {
        for index in 0..<max(1, count) {
            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2
            let shard = SKShapeNode(rectOf: CGSize(width: 3, height: 17), cornerRadius: 1.5)
            shard.position = CGPoint(x: point.x + cos(angle) * 12, y: point.y + sin(angle) * 12)
            shard.zRotation = angle - .pi / 2
            shard.fillColor = index.isMultiple(of: 3) ? .white : color
            shard.strokeColor = .clear
            shard.glowWidth = 5
            shard.zPosition = 23
            addChild(shard)
            let distance: CGFloat = 58 + CGFloat(index % 3) * 10
            shard.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.42),
                    .scaleY(to: 0.15, duration: 0.42),
                    .fadeOut(withDuration: 0.42),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func asteroidFragments(at point: CGPoint, color: UIColor, count: Int, distance: CGFloat) {
        for index in 0..<max(1, count) {
            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2 + CGFloat(index % 3) * 0.16
            let radius = 2.2 + CGFloat(index % 3) * 1.35
            let fragment = SKShapeNode(path: Self.polygonPath(radius: radius, sides: index.isMultiple(of: 2) ? 4 : 5))
            fragment.position = CGPoint(
                x: point.x + cos(angle) * 5,
                y: point.y + sin(angle) * 5
            )
            fragment.fillColor = index.isMultiple(of: 4) ? .white : color
            fragment.strokeColor = color.withAlphaComponent(0.55)
            fragment.lineWidth = 0.8
            fragment.glowWidth = 3
            fragment.zPosition = 23
            addChild(fragment)

            let travel = distance * (0.72 + CGFloat(index % 4) * 0.11)
            fragment.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * travel, y: sin(angle) * travel, duration: 0.38),
                    .rotate(byAngle: index.isMultiple(of: 2) ? .pi : -.pi, duration: 0.38),
                    .scale(to: 0.18, duration: 0.38),
                    .fadeOut(withDuration: 0.38),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func polygonWave(
        at point: CGPoint,
        sides: Int,
        color: UIColor,
        radius: CGFloat,
        scale: CGFloat,
        delay: TimeInterval = 0
    ) {
        let polygon = SKShapeNode(path: Self.polygonPath(radius: radius, sides: sides))
        polygon.position = point
        polygon.fillColor = color.withAlphaComponent(0.07)
        polygon.strokeColor = color
        polygon.lineWidth = 2.2
        polygon.glowWidth = 8
        polygon.zPosition = 22
        polygon.setScale(0.75)
        polygon.alpha = 0
        addChild(polygon)
        polygon.run(.sequence([
            .wait(forDuration: delay),
            .fadeIn(withDuration: 0.05),
            .group([
                .scale(to: scale, duration: 0.52),
                .fadeOut(withDuration: 0.52),
                .rotate(byAngle: .pi / 5, duration: 0.52),
            ]),
            .removeFromParent(),
        ]))
    }

    private func speedStreaks(at point: CGPoint, color: UIColor) {
        let raw = session.sim.lastVelocity.normalized()
        let direction = raw.length > 0.1 ? raw : Vec2(x: 0, y: 1)
        let angle = CGFloat(atan2(direction.y, direction.x)) - .pi / 2
        let perpendicular = Vec2(x: -direction.y, y: direction.x)
        for index in 0..<11 {
            let lateral = Double(index - 5) * 6.5
            let streak = SKShapeNode(rectOf: CGSize(width: 2.2, height: CGFloat(16 + index % 4 * 5)), cornerRadius: 1)
            streak.position = CGPoint(
                x: point.x + CGFloat(perpendicular.x * lateral),
                y: point.y + CGFloat(perpendicular.y * lateral)
            )
            streak.zRotation = angle
            streak.fillColor = index.isMultiple(of: 4) ? .white : color
            streak.strokeColor = .clear
            streak.glowWidth = 4
            streak.zPosition = 22
            addChild(streak)
            streak.run(.sequence([
                .group([
                    .moveBy(x: CGFloat(-direction.x * 86), y: CGFloat(-direction.y * 86), duration: 0.32),
                    .fadeOut(withDuration: 0.32),
                    .scaleY(to: 0.35, duration: 0.32),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func electricArcBurst(at point: CGPoint, color: UIColor, count: Int) {
        for index in 0..<max(1, count) {
            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2
                + sin(CGFloat(index + 7) * 2.17) * 0.20
            let bolt = lightningBoltNode(
                angle: angle,
                inner: 15,
                outer: 70,
                baseSeed: index + 71,
                color: color,
                delay: 0,
                persistent: false
            )
            bolt.position = point
            bolt.zPosition = 23
            bolt.alpha = 0
            addChild(bolt)
            bolt.run(.sequence([
                .fadeAlpha(to: 0.95, duration: 0.035 + Double(index % 2) * 0.02),
                .wait(forDuration: 0.06),
                .group([.fadeOut(withDuration: 0.24), .scale(to: 1.18, duration: 0.24)]),
                .removeFromParent(),
            ]))
        }
    }

    private func lightningBoltNode(
        angle: CGFloat,
        inner: CGFloat,
        outer: CGFloat,
        baseSeed: Int,
        color: UIColor,
        delay: TimeInterval,
        persistent: Bool
    ) -> SKNode {
        let root = SKNode()
        let initialPath = Self.lightningPath(
            angle: angle,
            inner: inner,
            outer: outer,
            segments: 9,
            seed: baseSeed
        )
        let bloom = SKShapeNode(path: initialPath)
        bloom.name = "bloom"
        bloom.strokeColor = color.withAlphaComponent(0.46)
        bloom.lineWidth = 6.5
        bloom.lineCap = .round
        bloom.lineJoin = .round
        bloom.glowWidth = 9
        let core = SKShapeNode(path: initialPath)
        core.name = "core"
        core.strokeColor = UIColor.white.withAlphaComponent(0.96)
        core.lineWidth = 1.15
        core.lineCap = .round
        core.lineJoin = .round
        core.glowWidth = 2
        root.addChild(bloom)
        root.addChild(core)

        if persistent {
            var frame = 0
            let redraw = SKAction.run { [weak bloom, weak core] in
                frame += 1
                let path = Self.lightningPath(
                    angle: angle + sin(CGFloat(frame + baseSeed) * 1.17) * 0.08,
                    inner: inner,
                    outer: outer,
                    segments: 9,
                    seed: baseSeed + frame * 29
                )
                bloom?.path = path
                core?.path = path
            }
            root.alpha = 0.24
            root.run(.repeatForever(.sequence([
                .wait(forDuration: delay),
                redraw,
                .fadeAlpha(to: 1, duration: 0.018),
                .wait(forDuration: 0.072),
                .fadeAlpha(to: 0.24, duration: 0.065),
                .wait(forDuration: 0.045 + Double(baseSeed % 3) * 0.027),
            ])))
        }
        return root
    }

    private func winterBurst(at point: CGPoint, color: UIColor) {
        let flash = SKSpriteNode(texture: GlowTextures.snowflakeParticle)
        flash.position = point
        flash.size = CGSize(width: 74, height: 74)
        flash.color = .white
        flash.colorBlendFactor = 0.18
        flash.blendMode = .add
        flash.zPosition = 24
        flash.setScale(0.24)
        flash.alpha = 0.95
        addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 1.65, duration: 0.38), .fadeAlpha(to: 0.44, duration: 0.38)]),
            .group([.scale(to: 2.05, duration: 0.40), .fadeOut(withDuration: 0.40)]),
            .removeFromParent(),
        ]))

        let snow = SKEmitterNode()
        snow.particleTexture = GlowTextures.snowflakeParticle
        snow.position = point
        snow.zPosition = 24
        snow.particleBirthRate = 95
        snow.numParticlesToEmit = 34
        snow.particleLifetime = 1.55
        snow.particleLifetimeRange = 0.40
        snow.emissionAngleRange = .pi * 2
        snow.particleSpeed = 72
        snow.particleSpeedRange = 34
        snow.particleScale = 0.11
        snow.particleScaleRange = 0.055
        snow.particleScaleSpeed = -0.045
        snow.particleRotationRange = .pi * 2
        snow.particleRotationSpeed = 0.75
        snow.particleAlpha = 0.92
        snow.particleAlphaSpeed = -0.48
        snow.particleBlendMode = .add
        addChild(snow)
        snow.run(.sequence([.wait(forDuration: 2.1), .removeFromParent()]))

        shockwave(at: point, color: color, start: 18, end: 154)
    }

    private func shieldBubbleNode(
        color: UIColor,
        radius: CGFloat,
        layers: Int,
        animated: Bool
    ) -> SKNode {
        let root = SKNode()
        for layer in 0..<max(1, layers) {
            let layerRadius = radius + CGFloat(layer) * 7
            let surface = SKSpriteNode(texture: GlowTextures.shieldBubble)
            surface.size = CGSize(width: layerRadius * 2.42, height: layerRadius * 2.42)
            surface.blendMode = .add
            surface.alpha = layer == 0 ? 0.92 : 0.42
            surface.zRotation = CGFloat(layer) * 0.32
            root.addChild(surface)

            let shell = SKShapeNode(circleOfRadius: layerRadius)
            shell.fillColor = color.withAlphaComponent(layer == 0 ? 0.085 : 0.018)
            shell.strokeColor = (layer == 0 ? color : .white).withAlphaComponent(layer == 0 ? 0.28 : 0.20)
            shell.lineWidth = layer == 0 ? 1.2 : 0.8
            shell.glowWidth = layer == 0 ? 4 : 2
            root.addChild(shell)

            let highlightPath = CGMutablePath()
            highlightPath.addArc(
                center: .zero,
                radius: layerRadius - 2,
                startAngle: .pi * 0.18,
                endAngle: .pi * 0.68,
                clockwise: false
            )
            let highlight = SKShapeNode(path: highlightPath)
            highlight.strokeColor = UIColor.white.withAlphaComponent(layer == 0 ? 0.68 : 0.30)
            highlight.lineWidth = layer == 0 ? 1.8 : 1.0
            highlight.lineCap = .round
            highlight.glowWidth = 3
            root.addChild(highlight)
        }

        let lens = SKShapeNode(ellipseOf: CGSize(width: radius * 1.25, height: radius * 0.34))
        lens.position = CGPoint(x: -radius * 0.17, y: radius * 0.38)
        lens.zRotation = -0.32
        lens.fillColor = UIColor.white.withAlphaComponent(0.055)
        lens.strokeColor = UIColor.white.withAlphaComponent(0.16)
        lens.lineWidth = 0.8
        root.addChild(lens)

        for index in 0..<4 {
            let angle = CGFloat(index) / 4 * .pi * 2 + 0.42
            let mote = SKShapeNode(circleOfRadius: index.isMultiple(of: 2) ? 1.8 : 1.2)
            mote.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            mote.fillColor = index.isMultiple(of: 2) ? .white : color
            mote.strokeColor = .clear
            mote.glowWidth = 4
            root.addChild(mote)
            if animated {
                mote.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.18, duration: 0.45 + Double(index) * 0.08),
                    .fadeAlpha(to: 0.95, duration: 0.38 + Double(index) * 0.06),
                ])))
            }
        }

        if animated {
            lens.run(.repeatForever(.sequence([
                .group([.scale(to: 1.04, duration: 0.78), .fadeAlpha(to: 0.72, duration: 0.78)]),
                .group([.scale(to: 0.97, duration: 0.82), .fadeAlpha(to: 1, duration: 0.82)]),
            ])))
        }
        return root
    }

    private func shieldFormEffect(at point: CGPoint, color: UIColor) {
        let bubble = shieldBubbleNode(color: color, radius: 34, layers: 1, animated: false)
        bubble.position = point
        bubble.zPosition = 24
        bubble.setScale(0.28)
        bubble.alpha = 0
        addChild(bubble)
        bubble.run(.sequence([
            .group([.scale(to: 1.16, duration: 0.25), .fadeIn(withDuration: 0.12)]),
            .group([.scale(to: 1.32, duration: 0.42), .fadeOut(withDuration: 0.42)]),
            .removeFromParent(),
        ]))
        shockwave(at: point, color: color, start: 23, end: 82)
    }

    private func shieldBreakEffect(at point: CGPoint) {
        let color = UIColor(red: 0.38, green: 1.0, blue: 0.72, alpha: 1)
        let broken = shieldBubbleNode(color: color, radius: 34, layers: 1, animated: false)
        broken.position = point
        broken.zPosition = 25

        let cracks = CGMutablePath()
        let impact = CGPoint(x: -33, y: 3)
        for index in 0..<5 {
            let angle = -0.65 + CGFloat(index) * 0.31
            let joint = CGPoint(x: -14, y: 3 + sin(angle) * 10)
            let end = CGPoint(x: 5 + CGFloat(index % 2) * 8, y: 3 + sin(angle) * 25)
            cracks.move(to: impact)
            cracks.addLine(to: joint)
            cracks.addLine(to: end)
            if index.isMultiple(of: 2) {
                cracks.move(to: joint)
                cracks.addLine(to: CGPoint(x: joint.x + 5, y: joint.y + 9))
            }
        }
        let crackNode = SKShapeNode(path: cracks)
        crackNode.strokeColor = .white
        crackNode.lineWidth = 1.45
        crackNode.lineCap = .round
        crackNode.lineJoin = .round
        crackNode.glowWidth = 5
        broken.addChild(crackNode)
        addChild(broken)
        broken.run(.sequence([
            .wait(forDuration: 0.08),
            .group([.scale(to: 1.28, duration: 0.34), .fadeOut(withDuration: 0.34)]),
            .removeFromParent(),
        ]))
        shockwave(at: point, color: color, start: 30, end: 112)
        screenFlash(color: color, alpha: 0.07)
    }

    private func magneticFieldAura(tint: UIColor, radius: CGFloat, particleCount: Int) -> SKNode {
        let root = SKNode()
        let cyan = UIColor(red: 0.30, green: 0.90, blue: 1, alpha: 1)

        for index in 0..<4 {
            let scale = 0.58 + CGFloat(index) * 0.14
            let path = Self.magneticFieldPath(
                horizontal: radius * scale,
                vertical: radius * (0.52 + CGFloat(index) * 0.10),
                poleGap: 15 + CGFloat(index) * 1.5
            )
            let field = SKShapeNode(path: path)
            field.strokeColor = (index.isMultiple(of: 2) ? tint : cyan)
                .withAlphaComponent(0.34 + CGFloat(index) * 0.08)
            field.lineWidth = index == 3 ? 1.45 : 1.05
            field.lineCap = .round
            field.glowWidth = index == 3 ? 4 : 2
            root.addChild(field)
            field.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.48, duration: 0.75 + Double(index) * 0.12),
                .fadeAlpha(to: 0.92, duration: 0.82 + Double(index) * 0.09),
            ])))
        }

        for index in 0..<max(1, particleCount) {
            let path = Self.magneticFieldPath(
                horizontal: radius * (0.64 + CGFloat(index % 3) * 0.13),
                vertical: radius * (0.56 + CGFloat(index % 3) * 0.09),
                poleGap: 16
            )
            let mote = SKShapeNode(circleOfRadius: index.isMultiple(of: 2) ? 1.8 : 1.25)
            mote.fillColor = index.isMultiple(of: 2) ? cyan : .white
            mote.strokeColor = .clear
            mote.glowWidth = 4
            mote.alpha = 0
            root.addChild(mote)
            let travel = 1.55 + Double(index % 3) * 0.24
            mote.run(.repeatForever(.sequence([
                .wait(forDuration: Double(index) * 0.24),
                .fadeAlpha(to: 0.92, duration: 0.12),
                .follow(path, asOffset: false, orientToPath: false, duration: travel),
                .fadeOut(withDuration: 0.14),
                .wait(forDuration: 0.28),
            ])))
        }

        let north = SKShapeNode(circleOfRadius: 3.2)
        north.position = CGPoint(x: 0, y: 16)
        north.fillColor = cyan
        north.strokeColor = .white.withAlphaComponent(0.65)
        north.glowWidth = 4
        root.addChild(north)

        let south = SKShapeNode(circleOfRadius: 3.2)
        south.position = CGPoint(x: 0, y: -16)
        south.fillColor = tint
        south.strokeColor = .white.withAlphaComponent(0.65)
        south.glowWidth = 4
        root.addChild(south)

        root.run(.repeatForever(.sequence([
            .scale(to: 1.035, duration: 0.85),
            .scale(to: 0.975, duration: 0.85),
        ])))
        return root
    }

    private func timelineWaves(at point: CGPoint, color: UIColor, count: Int) {
        for index in 0..<max(1, count) {
            let ring = SKShapeNode(circleOfRadius: 17 + CGFloat(index) * 4)
            ring.position = point
            ring.fillColor = .clear
            ring.strokeColor = index.isMultiple(of: 2) ? color : .white
            ring.lineWidth = 2
            ring.glowWidth = 7
            ring.zPosition = 22
            ring.alpha = 0
            addChild(ring)
            ring.run(.sequence([
                .wait(forDuration: Double(index) * 0.09),
                .fadeIn(withDuration: 0.04),
                .group([
                    .scale(to: 3.6 + CGFloat(index) * 0.28, duration: 0.5),
                    .fadeOut(withDuration: 0.5),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func orbitalArcs(at point: CGPoint, color: UIColor) {
        for index in 0..<3 {
            let path = CGMutablePath()
            let radius = CGFloat(27 + index * 11)
            path.addArc(center: .zero, radius: radius, startAngle: CGFloat(index) * 0.7, endAngle: CGFloat(index) * 0.7 + .pi * 1.25, clockwise: false)
            let arc = SKShapeNode(path: path)
            arc.position = point
            arc.strokeColor = index == 1 ? .white : color
            arc.lineWidth = 2.4
            arc.lineCap = .round
            arc.glowWidth = 6
            arc.zPosition = 22
            addChild(arc)
            arc.run(.sequence([
                .group([
                    .rotate(byAngle: index.isMultiple(of: 2) ? .pi : -.pi, duration: 0.62),
                    .scale(to: 1.75, duration: 0.62),
                    .fadeOut(withDuration: 0.62),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func phaseAfterimages(at point: CGPoint, color: UIColor) {
        for index in 0..<4 {
            let image = SKSpriteNode(texture: GlowTextures.player)
            image.position = point
            image.size = CGSize(width: 42, height: 42)
            image.color = color
            image.colorBlendFactor = 0.65
            image.blendMode = .add
            image.alpha = 0.42
            image.zPosition = 21
            addChild(image)
            let angle = CGFloat(index) / 4 * .pi * 2
            image.run(.sequence([
                .wait(forDuration: Double(index) * 0.035),
                .group([
                    .moveBy(x: cos(angle) * 48, y: sin(angle) * 48, duration: 0.42),
                    .fadeOut(withDuration: 0.42),
                    .scale(to: 0.55, duration: 0.42),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func screenFlash(color: UIColor, alpha: CGFloat) {
        let flash = SKSpriteNode(color: color, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.alpha = 0
        flash.blendMode = .add
        flash.zPosition = 30
        flash.isUserInteractionEnabled = false
        addChild(flash)
        flash.run(.sequence([
            .fadeAlpha(to: alpha, duration: 0.04),
            .fadeOut(withDuration: 0.20),
            .removeFromParent(),
        ]))
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

    private static func asteroidShape(radius: CGFloat, seed: Int) -> SKShapeNode {
        let path = CGMutablePath()
        let count = 8
        for i in 0..<count {
            let jitter = 0.72 + 0.28 * sin(Double(seed * 13 + i * 19))
            let angle = (Double(i) / Double(count)) * .pi * 2
            let p = CGPoint(x: cos(angle) * Double(radius) * jitter, y: sin(angle) * Double(radius) * jitter)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.lineJoin = .round
        return node
    }

    private static func asteroidMaterialPath(
        material: AsteroidMaterial,
        radius: CGFloat,
        seed: Int
    ) -> CGPath {
        let path = CGMutablePath()
        let offset = CGFloat(seed % 17) * 0.11
        switch material {
        case .basalt:
            for index in 0..<4 {
                let angle = offset + CGFloat(index) * 1.71
                let distance = radius * (0.22 + CGFloat(index % 2) * 0.18)
                let craterRadius = radius * (0.12 + CGFloat(index % 3) * 0.035)
                path.addEllipse(in: CGRect(
                    x: cos(angle) * distance - craterRadius,
                    y: sin(angle) * distance - craterRadius,
                    width: craterRadius * 2,
                    height: craterRadius * 2
                ))
            }
        case .ice:
            path.addPath(polygonPath(radius: radius * 0.76, sides: 6))
            for index in 0..<6 {
                let angle = offset + CGFloat(index) / 6 * .pi * 2
                path.move(to: CGPoint(x: cos(angle) * radius * 0.12, y: sin(angle) * radius * 0.12))
                path.addLine(to: CGPoint(x: cos(angle) * radius * 0.82, y: sin(angle) * radius * 0.82))
            }
        case .crystal:
            path.addPath(polygonPath(radius: radius * 0.86, sides: 5))
            for index in 0..<5 {
                let angle = -.pi / 2 + CGFloat(index) / 5 * .pi * 2
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: cos(angle) * radius * 0.86, y: sin(angle) * radius * 0.86))
            }
            path.addEllipse(in: CGRect(x: -radius * 0.19, y: -radius * 0.19, width: radius * 0.38, height: radius * 0.38))
        case .alloy:
            path.addEllipse(in: CGRect(x: -radius * 0.78, y: -radius * 0.78, width: radius * 1.56, height: radius * 1.56))
            path.addEllipse(in: CGRect(x: -radius * 0.31, y: -radius * 0.31, width: radius * 0.62, height: radius * 0.62))
            for index in 0..<8 {
                let angle = offset + CGFloat(index) / 8 * .pi * 2
                path.move(to: CGPoint(x: cos(angle) * radius * 0.38, y: sin(angle) * radius * 0.38))
                path.addLine(to: CGPoint(x: cos(angle) * radius * 0.76, y: sin(angle) * radius * 0.76))
            }
        }
        return path
    }

    private static func asteroidCrackPath(radius: CGFloat, seed: Int) -> CGPath {
        let path = CGMutablePath()
        let offset = CGFloat(seed % 23) * 0.09
        for index in 0..<4 {
            let angle = offset + CGFloat(index) / 4 * .pi * 2
            let inner = CGPoint(x: cos(angle + 0.25) * radius * 0.08, y: sin(angle + 0.25) * radius * 0.08)
            let middle = CGPoint(x: cos(angle - 0.12) * radius * 0.48, y: sin(angle - 0.12) * radius * 0.48)
            let outer = CGPoint(x: cos(angle + 0.08) * radius * 0.92, y: sin(angle + 0.08) * radius * 0.92)
            path.move(to: inner)
            path.addLine(to: middle)
            path.addLine(to: outer)
            path.move(to: middle)
            path.addLine(to: CGPoint(
                x: middle.x + cos(angle + 0.72) * radius * 0.24,
                y: middle.y + sin(angle + 0.72) * radius * 0.24
            ))
        }
        return path
    }

    private static func polygonPath(radius: CGFloat, sides: Int) -> CGPath {
        let path = CGMutablePath()
        let count = max(3, sides)
        for index in 0..<count {
            let angle = CGFloat(index) / CGFloat(count) * .pi * 2 - .pi / 2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private static func lightningPath(
        angle: CGFloat,
        inner: CGFloat,
        outer: CGFloat,
        segments: Int,
        seed: Int
    ) -> CGPath {
        let path = CGMutablePath()
        let count = max(5, segments)
        let direction = CGVector(dx: cos(angle), dy: sin(angle))
        let perpendicular = CGVector(dx: -direction.dy, dy: direction.dx)
        var points: [CGPoint] = []

        for index in 0...count {
            let progress = CGFloat(index) / CGFloat(count)
            let radius = inner + (outer - inner) * progress
            let envelope = sin(progress * .pi)
            let waveA = sin(CGFloat(seed * 19 + index * 43) * 0.73)
            let waveB = cos(CGFloat(seed * 31 + index * 17) * 1.11)
            let lateral = (waveA * 0.72 + waveB * 0.28) * (outer - inner) * 0.18 * envelope
            let point = CGPoint(
                x: direction.dx * radius + perpendicular.dx * lateral,
                y: direction.dy * radius + perpendicular.dy * lateral
            )
            points.append(point)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }

        let branchLength = (outer - inner) * 0.24
        for branchIndex in 0..<2 {
            let sourceIndex = min(count - 1, max(2, (count * (branchIndex + 2)) / 4))
            let source = points[sourceIndex]
            let side: CGFloat = (seed + branchIndex).isMultiple(of: 2) ? 1 : -1
            let branchAngle = angle + side * (0.52 + CGFloat(branchIndex) * 0.12)
            let branchDirection = CGVector(dx: cos(branchAngle), dy: sin(branchAngle))
            let branchPerpendicular = CGVector(dx: -branchDirection.dy, dy: branchDirection.dx)
            path.move(to: source)
            for step in 1...2 {
                let amount = CGFloat(step) / 2
                let branchJitter = sin(CGFloat(seed * 13 + branchIndex * 23 + step * 37)) * branchLength * 0.10
                path.addLine(to: CGPoint(
                    x: source.x + branchDirection.dx * branchLength * amount + branchPerpendicular.dx * branchJitter,
                    y: source.y + branchDirection.dy * branchLength * amount + branchPerpendicular.dy * branchJitter
                ))
            }
        }
        return path
    }

    private static func magneticFieldPath(
        horizontal: CGFloat,
        vertical: CGFloat,
        poleGap: CGFloat
    ) -> CGPath {
        let path = CGMutablePath()
        let north = CGPoint(x: 0, y: poleGap)
        let south = CGPoint(x: 0, y: -poleGap)
        path.move(to: north)
        path.addCurve(
            to: south,
            control1: CGPoint(x: horizontal, y: vertical),
            control2: CGPoint(x: horizontal, y: -vertical)
        )
        path.addCurve(
            to: north,
            control1: CGPoint(x: -horizontal, y: -vertical),
            control2: CGPoint(x: -horizontal, y: vertical)
        )
        path.closeSubpath()
        return path
    }

    private static func segmentedCirclePath(
        radius: CGFloat,
        segments: Int,
        coverage: CGFloat
    ) -> CGPath {
        let path = CGMutablePath()
        let count = max(2, segments)
        let slice = CGFloat.pi * 2 / CGFloat(count)
        let visible = slice * min(max(coverage, 0.1), 0.92)
        for index in 0..<count {
            let start = CGFloat(index) * slice
            path.addArc(
                center: .zero,
                radius: radius,
                startAngle: start,
                endAngle: start + visible,
                clockwise: false
            )
        }
        return path
    }

    private static func arc(radius: CGFloat, fraction: Double) -> CGPath {
        let path = CGMutablePath()
        let end = CGFloat(fraction) * .pi * 2
        path.addArc(center: .zero, radius: radius, startAngle: 0, endAngle: end, clockwise: false)
        return path
    }

    private static func color(for material: AsteroidMaterial) -> UIColor {
        switch material {
        case .basalt:
            UIColor(red: 0.50, green: 0.40, blue: 0.34, alpha: 1)
        case .ice:
            UIColor(red: 0.48, green: 0.91, blue: 1.00, alpha: 1)
        case .crystal:
            UIColor(red: 0.82, green: 0.42, blue: 1.00, alpha: 1)
        case .alloy:
            UIColor(red: 0.72, green: 0.82, blue: 0.92, alpha: 1)
        }
    }

    private static func secondaryColor(for material: AsteroidMaterial) -> UIColor {
        switch material {
        case .basalt:
            UIColor(red: 1.00, green: 0.62, blue: 0.29, alpha: 1)
        case .ice:
            UIColor.white
        case .crystal:
            UIColor(red: 0.42, green: 0.92, blue: 1.00, alpha: 1)
        case .alloy:
            UIColor(red: 1.00, green: 0.78, blue: 0.32, alpha: 1)
        }
    }

    private static func color(for kind: BonusKind) -> UIColor {
        GlowTextures.color(for: kind)
    }

    private func decorationColor(_ tone: ArenaDecorationTone) -> UIColor {
        switch tone {
        case .theme:
            session.level.theme.wallStroke.uiColor
        case .cyan:
            UIColor(red: 0.42, green: 0.88, blue: 1, alpha: 1)
        case .violet:
            UIColor(red: 0.78, green: 0.42, blue: 1, alpha: 1)
        case .gold:
            UIColor(red: 1, green: 0.76, blue: 0.26, alpha: 1)
        case .danger:
            UIColor(red: 1, green: 0.29, blue: 0.43, alpha: 1)
        }
    }

    private var worldScale: CGFloat {
        size.width / CGFloat(max(session.level.worldWidth, 1))
    }

    private func beamPath(for laser: LaserState) -> CGPath {
        let path = CGMutablePath()
        path.move(to: scenePoint(laser.start))
        path.addLine(to: scenePoint(laser.end))
        return path
    }

    private func mapped(_ wall: AABB) -> CGRect {
        CGRect(
            x: wall.minX * Double(worldScale),
            y: wall.minY * Double(worldScale),
            width: wall.width * Double(worldScale),
            height: wall.height * Double(worldScale)
        )
    }

    private func wallBoundaryPath(_ walls: [AABB]) -> CGPath {
        let xs = Array(Set(walls.flatMap { [$0.minX, $0.maxX] })).sorted()
        let ys = Array(Set(walls.flatMap { [$0.minY, $0.maxY] })).sorted()
        let path = CGMutablePath()
        guard xs.count > 1, ys.count > 1 else { return path }

        func occupied(_ x: Int, _ y: Int) -> Bool {
            guard x >= 0, y >= 0, x < xs.count - 1, y < ys.count - 1 else { return false }
            let point = Vec2(x: (xs[x] + xs[x + 1]) / 2, y: (ys[y] + ys[y + 1]) / 2)
            return walls.contains { $0.contains(point) }
        }

        func segment(_ a: Vec2, _ b: Vec2) {
            path.move(to: scenePoint(a))
            path.addLine(to: scenePoint(b))
        }

        // Merge adjacent collinear edges before stroking. Without this pass every
        // rectangle-grid cell contributes a round-capped line, creating bright dots
        // and hairline overlaps at otherwise seamless wall joints.
        for x in 0..<xs.count {
            var runStart: Int?
            var runSide = 0
            for y in 0..<ys.count {
                let side: Int
                if y < ys.count - 1 {
                    let left = occupied(x - 1, y)
                    let right = occupied(x, y)
                    side = left == right ? 0 : (left ? -1 : 1)
                } else {
                    side = 0
                }

                if let start = runStart, side != runSide {
                    segment(Vec2(x: xs[x], y: ys[start]), Vec2(x: xs[x], y: ys[y]))
                    runStart = nil
                }
                if side != 0, runStart == nil {
                    runStart = y
                    runSide = side
                }
            }
        }

        for y in 0..<ys.count {
            var runStart: Int?
            var runSide = 0
            for x in 0..<xs.count {
                let side: Int
                if x < xs.count - 1 {
                    let below = occupied(x, y - 1)
                    let above = occupied(x, y)
                    side = below == above ? 0 : (below ? -1 : 1)
                } else {
                    side = 0
                }

                if let start = runStart, side != runSide {
                    segment(Vec2(x: xs[start], y: ys[y]), Vec2(x: xs[x], y: ys[y]))
                    runStart = nil
                }
                if side != 0, runStart == nil {
                    runStart = x
                    runSide = side
                }
            }
        }
        return path
    }

    private func scenePoint(_ v: Vec2) -> CGPoint {
        CGPoint(x: v.x * Double(worldScale), y: v.y * Double(worldScale))
    }

    private func world(_ p: CGPoint) -> Vec2 {
        Vec2(x: Double(p.x / worldScale), y: Double(p.y / worldScale))
    }
}

private extension RGB {
    var uiColor: UIColor { UIColor(red: r, green: g, blue: b, alpha: 1) }
}
