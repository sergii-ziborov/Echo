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
        realityBackdrop = SKSpriteNode(texture: GlowTextures.candyTimeline, size: size)
        realityBackdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        realityBackdrop.zPosition = 0.25
        realityBackdrop.alpha = 0
        realityBackdrop.color = UIColor(red: 0.75, green: 0.45, blue: 1, alpha: 1)
        realityBackdrop.colorBlendFactor = 0.04
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
        frostOverlay = SKSpriteNode(color: UIColor(red: 0.55, green: 0.82, blue: 1, alpha: 0.22), size: size)
        frostOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        frostOverlay.zPosition = 20
        frostOverlay.blendMode = .add
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
        if !events.isEmpty { onEvents?(events) }
        let live = session.hasStarted
        ambienceNode.speed = live ? 1 : 0
        exitNode.speed = live ? 1 : 0
        spawnBeacon.speed = live ? 1 : 0
        let frozen = session.sim.effects.isFrozen
        decorationNode.speed = live ? (frozen ? 0.18 : 1) : 0.32
        let spinning: CGFloat = (live && !frozen) ? 1 : 0
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
            shockwave(at: point, color: color, start: 16, end: 124)
            shockwave(at: point, color: .white, start: 10, end: 76)
            radialShards(at: point, color: color, count: 12)
            screenFlash(color: color, alpha: 0.10)
        case .shield, .ward:
            polygonWave(at: point, sides: 6, color: color, radius: 25, scale: 3.1)
            polygonWave(at: point, sides: 6, color: .white, radius: 18, scale: 2.5, delay: 0.08)
        case .surge:
            burst(at: position, color: color)
            speedStreaks(at: point, color: color)
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

    private func buildMovers() {
        for mover in session.sim.movers {
            let root = SKNode()
            root.zPosition = 10
            root.position = scenePoint(mover.position)
            let diameter = max(50, CGFloat(mover.radius) * worldScale * 2.7)
            let glow = SKSpriteNode(texture: GlowTextures.blob)
            let glowSize = diameter * 1.45
            glow.size = CGSize(width: glowSize, height: glowSize)
            glow.blendMode = .add
            glow.color = session.level.theme.wallStroke.uiColor
            glow.colorBlendFactor = 0.72
            glow.alpha = 0.32
            glow.name = "glow"
            let rock = SKSpriteNode(texture: GlowTextures.asteroid)
            rock.size = CGSize(width: diameter, height: diameter)
            rock.color = session.level.theme.wallStroke.uiColor
            rock.colorBlendFactor = 0.10
            rock.name = "rock"
            rock.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: TimeInterval.random(in: 5...9))))
            root.addChild(glow)
            root.addChild(rock)
            addChild(root)
            moverNodes[mover.id] = root
        }
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

            let sprite = SKSpriteNode(texture: GlowTextures.blackHole)
            sprite.name = "core"
            let diameter = max(92, CGFloat(well.coreRadius) * worldScale * 3.4)
            sprite.size = CGSize(width: diameter, height: diameter)
            sprite.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 8.5)))

            root.addChild(influence)
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
            if rift.kind == .warp || rift.kind == .candy {
                let tear = SKSpriteNode(texture: GlowTextures.dimensionalRift)
                tear.name = "tear"
                let tearWidth = max(105, s * 2.15)
                tear.size = CGSize(width: tearWidth, height: tearWidth * 1.42)
                tear.color = color
                tear.colorBlendFactor = rift.kind == .candy ? 0.28 : 0.08
                tear.blendMode = .add
                tear.run(.repeatForever(.sequence([
                    .rotate(toAngle: 0.08, duration: 0.7, shortestUnitArc: true),
                    .rotate(toAngle: -0.08, duration: 0.7, shortestUnitArc: true),
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
                for i in 0..<6 {
                    let shard = SKShapeNode(rectOf: CGSize(width: 3, height: 16), cornerRadius: 1)
                    shard.fillColor = UIColor(red: 0.75, green: 0.92, blue: 1, alpha: 0.9)
                    shard.strokeColor = .clear
                    let angle = CGFloat(i) / 6 * .pi * 2
                    shard.position = CGPoint(x: cos(angle) * 18, y: sin(angle) * 18)
                    shard.zRotation = angle
                    frost.addChild(shard)
                }
                playerNode.addChild(frost)
            }
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
        for mover in session.sim.movers {
            moverNodes[mover.id]?.position = scenePoint(mover.position)
            moverNodes[mover.id]?.alpha = session.sim.effects.isFrozen ? 0.58 : 1
        }
        for well in session.sim.gravityWells {
            gravityWellNodes[well.id]?.position = scenePoint(well.position)
            gravityWellNodes[well.id]?.alpha = session.sim.effects.isFrozen ? 0.52 : 1
            gravityWellNodes[well.id]?.speed = session.sim.effects.isFrozen ? 0 : 1
        }
        for rift in session.sim.rifts {
            guard let node = riftNodes[rift.id] else { continue }
            node.position = scenePoint(rift.position)
            node.alpha = rift.open ? 1 : 0.22
            node.setScale(rift.open ? 1 : 0.72)
        }
        frostOverlay?.alpha = session.sim.effects.isFrozen ? 1 : 0
        syncRealityBackdrop()
        for echo in echoNodes {
            echo.alpha = session.sim.effects.isFrozen ? 0.4 : 1
        }
        syncGates()
        syncLasers()
        syncScars()
        syncFrostCrown()
        exitNode.position = scenePoint(session.level.exit)
        refreshExit()
        if let halo = playerNode.childNode(withName: "halo") as? SKSpriteNode {
            if session.sim.effects.isPhasing {
                halo.color = UIColor.white
                halo.colorBlendFactor = 0.7
            } else if session.sim.effects.shieldCharges > 0 {
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
