import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func syncMovers(_ states: [MoverState], frozen: Bool) {
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
                let rockSize = CGFloat((root.userData?["diameter"] as? NSNumber)?.doubleValue ?? 64)
                let shell = SKShapeNode(circleOfRadius: rockSize * 0.62)
                shell.name = "freezeShell"
                shell.zPosition = 5
                shell.fillColor = UIColor(red: 0.48, green: 0.83, blue: 1, alpha: 0.12)
                shell.strokeColor = UIColor(red: 0.76, green: 0.95, blue: 1, alpha: 0.82)
                shell.lineWidth = 1.4
                shell.glowWidth = 0
                for index in 0..<5 {
                    let crystal = SKSpriteNode(texture: GlowTextures.snowflakeParticle)
                    crystal.size = CGSize(width: 8, height: 8)
                    let angle = CGFloat(index) / 5 * .pi * 2 + 0.3
                    crystal.position = CGPoint(x: cos(angle) * rockSize * 0.55, y: sin(angle) * rockSize * 0.55)
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
            root.userData?["vx"] = NSNumber(value: mover.velocity.x * Double(worldScale))
            root.userData?["vy"] = NSNumber(value: mover.velocity.y * Double(worldScale))
            if let glow = root.childNode(withName: "glow") {
                glow.setScale(1 + progress * 0.18)
                glow.alpha = frozen ? 0.14 : (0.17 + progress * 0.14)
            }
            if let rock = root.childNode(withName: "rock") {
                syncFaults(rock, progress: progress, frozen: frozen)
            }
            syncMotionEmitter(
                root,
                headingX: mover.velocity.x,
                headingY: mover.velocity.y,
                speed: mover.velocity.length,
                dashing: false
            )
        }
    }

    /// Faults open one after another as a brittle rock fractures; the last
    /// stretch before it splits makes the whole body shiver.
    func syncFaults(_ rock: SKNode, progress: CGFloat, frozen: Bool) {
        for crack in rock.children where crack.name == "fault" {
            let threshold = CGFloat((crack.userData?["threshold"] as? NSNumber)?.doubleValue ?? 1)
            crack.alpha = max(0, min(1, (progress - threshold * 0.82) * 6))
        }
        let diameter = CGFloat((rock.parent?.userData?["diameter"] as? NSNumber)?.doubleValue ?? 40)
        let tremor = frozen ? 0 : max(0, progress - 0.72) * diameter * 0.17
        let beat = CGFloat(displayed?.time ?? 0)
        rock.position = CGPoint(x: sin(beat * 53) * tremor, y: cos(beat * 47) * tremor)
    }

    func syncRealityBackdrop() {
        switch displayed.reality {
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

    func syncGhosts() {
        let live = displayed.ghosts
        while ghostNodes.count < live.count {
            let node = ActorFactory.make(kind: .ghost, radius: actorRadius * 0.92)
            node.zPosition = VisualLayer.actors - 0.5
            addChild(node)
            ghostNodes.append(node)
        }
        while ghostNodes.count > live.count {
            ghostNodes.removeLast().removeFromParent()
        }
        for (i, ghost) in live.enumerated() {
            if let p = ghost.position(at: displayed.time) {
                ghostNodes[i].isHidden = false
                ghostNodes[i].position = scenePoint(p)
                ghostNodes[i].alpha = 0.78 + 0.08 * abs(sin(displayed.time * 6))
            } else {
                ghostNodes[i].isHidden = true
            }
        }
    }

    func sampleTrails(clock: TimeInterval) {
        guard !VisualStyle.useLegacyRenderer, let trails else { return }
        if clock + 0.04 < lastSampledSimTime {
            trails.beginBranch("player")
        }
        lastSampledSimTime = clock
        let gap = hypot(playerNode.position.x - lastPlayerScene.x, playerNode.position.y - lastPlayerScene.y)
        let jumped = gap > VisualStyle.teleportGap && lastPlayerScene != .zero
        let breakBefore = pendingPlayerTrailBreak || jumped
        pendingPlayerTrailBreak = false
        let surging = displayed?.effects.isSurging ?? session.sim.effects.isSurging
        let diameter = actorRadius * 2
        trails.sample(
            id: "player",
            position: playerNode.position,
            time: clock,
            color: surging ? UIColor(red: 1, green: 0.86, blue: 0.40, alpha: 1) : cometStyle.glow,
            headWidth: diameter * (surging ? VisualStyle.cometSurgeWidth : VisualStyle.cometPlayerWidth),
            moving: gap >= 0.6,
            breakBefore: breakBefore && lastPlayerScene != .zero
        )
        lastPlayerScene = playerNode.position
        var live: Set<String> = ["player"]
        for (index, node) in echoNodes.enumerated() where !node.isHidden {
            let id = "echo-\(index)"
            live.insert(id)
            trails.sample(
                id: id,
                position: node.position,
                time: clock,
                color: VisualPalette.echoRim,
                headWidth: diameter * 0.92 * VisualStyle.cometEchoWidth,
                moving: true
            )
        }
        for (index, node) in ghostNodes.enumerated() where !node.isHidden {
            let id = "ghost-\(index)"
            live.insert(id)
            trails.sample(
                id: id,
                position: node.position,
                time: clock,
                color: VisualPalette.ghostRim,
                headWidth: diameter * 0.92 * VisualStyle.cometGhostWidth,
                moving: true
            )
        }
        trails.prune(ids: live)
    }

    func syncMagnetLinks() {
        guard displayed.effects.isMagnet else {
            magnetLinks.path = nil
            return
        }
        let path = CGMutablePath()
        for spark in displayed.sparks where spark.magnetHeld && !spark.collected {
            path.move(to: playerNode.position)
            path.addLine(to: scenePoint(spark.position))
        }
        magnetLinks.path = path
    }

    func dropTrails(dt: TimeInterval) {
        trailAcc += dt
        guard trailAcc > 0.028 else { return }
        trailAcc = 0
        let playerSpeed = session.sim.lastVelocity.length
        if playerSpeed > 18 {
            dropTrail(
                at: playerNode.position,
                color: UIColor(red: 0.45, green: 0.9, blue: 1, alpha: 1),
                size: session.sim.effects.isSurging ? 22 : 16
            )
        }
        for echo in echoNodes {
            dropTrail(at: echo.position, color: UIColor(red: 0.78, green: 0.38, blue: 1, alpha: 1), size: 14)
        }
    }

    func makeMotionEmitter(color: UIColor, emphasis: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = GlowTextures.blob
        emitter.particleBirthRate = 0
        emitter.particleLifetime = 0.3
        emitter.particleLifetimeRange = 0.1
        emitter.particleAlpha = 0.42
        emitter.particleAlphaRange = 0.10
        emitter.particleAlphaSpeed = -1.6
        emitter.particleScale = 0.034 * emphasis
        emitter.particleScaleRange = 0.012
        emitter.particleScaleSpeed = -0.08
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .alpha
        emitter.emissionAngleRange = 0.38
        emitter.particleSpeed = 96
        emitter.particleSpeedRange = 38
        emitter.particlePositionRange = CGVector(dx: 3, dy: 3)
        emitter.targetNode = self
        emitter.zPosition = -1
        emitter.name = "motionTrail"
        let data = NSMutableDictionary()
        data["emphasis"] = emphasis
        emitter.userData = data
        return emitter
    }

    func syncMotionEmitter(_ node: SKNode, headingX: Double, headingY: Double, speed: Double, dashing: Bool) {
        if let vapor = node.childNode(withName: "vapor") as? SKEmitterNode {
            vapor.particleBirthRate = session.sim.effects.isFrozen ? 0 : 34
        }
        guard let emitter = node.childNode(withName: "motionTrail") as? SKEmitterNode else { return }
        let emphasis = CGFloat((emitter.userData?["emphasis"] as? NSNumber)?.doubleValue ?? 1)
        guard !session.sim.effects.isFrozen,
              speed > 12,
              headingX * headingX + headingY * headingY > 0.01 else {
            emitter.particleBirthRate = 0
            return
        }
        emitter.emissionAngle = CGFloat(atan2(headingY, headingX)) + .pi
        emitter.particleBirthRate = (dashing ? 96 : 52) * emphasis
        emitter.particleLifetime = dashing ? 0.42 : 0.3
        emitter.particleSpeed = dashing ? 150 : 92
        emitter.particleScale = (dashing ? 0.07 : 0.052) * emphasis
    }

    func stopMotionEmitters() {
        (playerNode?.childNode(withName: "motionTrail") as? SKEmitterNode)?.particleBirthRate = 0
        for node in echoNodes + ghostNodes + Array(moverNodes.values) {
            (node.childNode(withName: "motionTrail") as? SKEmitterNode)?.particleBirthRate = 0
        }
    }
}
