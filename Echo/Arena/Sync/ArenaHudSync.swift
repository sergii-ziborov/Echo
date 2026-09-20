import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func asteroidDust(at point: CGPoint, color: UIColor, count: Int) {
        for index in 0..<max(1, count) {
            let mote = SKSpriteNode(texture: GlowTextures.blob)
            let size = CGFloat(7 + index % 4 * 3)
            mote.size = CGSize(width: size, height: size)
            mote.position = point
            mote.blendMode = .add
            mote.color = index.isMultiple(of: 3) ? .white : color
            mote.colorBlendFactor = 0.9
            mote.alpha = 0.72
            mote.zPosition = 22
            addChild(mote)
            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2 + CGFloat(index) * 0.13
            let travel = CGFloat(18 + index % 5 * 8)
            mote.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * travel, y: sin(angle) * travel, duration: 0.36),
                    .fadeOut(withDuration: 0.36),
                    .scale(to: 0.2, duration: 0.36),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    func fieldCaption(_ text: String, color: UIColor, y: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 9
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: y)
        label.zPosition = 4
        return label
    }

    func dropTrail(at point: CGPoint, color: UIColor, size: CGFloat) {
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

    func drawThreat() {
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

    func drawSpawnBeacon() {
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

    func updateSparkTimers() {
        for spark in displayed.sparks {
            guard let root = sparkNodes[spark.id] else { continue }
            let label = root.childNode(withName: "timerLabel") as? SKLabelNode
            let reward = root.childNode(withName: "timerReward") as? SKLabelNode
            let arc = root.childNode(withName: "timer") as? SKShapeNode
            if let duration = spark.timerDuration, !spark.collected {
                if spark.timedOut {
                    label?.text = ""
                    reward?.text = ""
                    arc?.path = nil
                    if let gem = root.childNode(withName: "gem") as? SKShapeNode {
                        gem.fillColor = VisualPalette.spark
                    }
                } else if let remaining = spark.timerRemaining {
                    let frac = max(0, min(1, remaining / duration))
                    arc?.path = Self.arc(radius: 13, fraction: frac)
                    arc?.strokeColor = VisualPalette.timedSpark
                    label?.fontSize = 10
                    label?.fontColor = VisualPalette.timedSpark
                    label?.text = displayed.effects.isFrozen
                        ? String(format: "HOLD  %.0f", ceil(remaining))
                        : String(format: "%.0fs", ceil(remaining))
                    reward?.text = "BONUS"
                }
            } else {
                label?.text = ""
                reward?.text = ""
                arc?.path = nil
            }
        }
    }

    func pulsePlayer() {
        if let sheen = playerNode.childNode(withName: "sheen") {
            sheen.alpha = displayed.lastVelocity.length > 1 ? 0.62 : 0.48
        }
        let idle = session.phase == .playing && session.inputTarget == nil
        if idle {
            beginIdlePulse()
        } else {
            endIdlePulse()
        }
    }

    func beginIdlePulse() {
        guard playerNode.action(forKey: "idlePulse") == nil else { return }
        if let aura = playerNode.childNode(withName: "idleAura") {
            aura.removeAllActions()
            aura.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.30, duration: 0.52),
                .fadeAlpha(to: 0.07, duration: 0.78),
            ])), withKey: "breathe")
        }
        let ping = SKAction.run { [weak self] in
            self?.spawnIdlePing()
        }
        playerNode.run(.repeatForever(.sequence([
            ping,
            .wait(forDuration: 1.15),
        ])), withKey: "idlePulse")
    }

    func spawnIdlePing() {
        let ring = SKShapeNode(circleOfRadius: actorRadius + 1)
        ring.name = "idlePing"
        ring.fillColor = .clear
        ring.strokeColor = VisualPalette.playerRim.withAlphaComponent(0.85)
        ring.lineWidth = 1.45
        ring.glowWidth = 0
        ring.zPosition = 3.4
        ring.alpha = 0.70
        playerNode.addChild(ring)
        let expand = SKAction.group([
            .fadeOut(withDuration: 0.74),
            .scale(to: 1.85, duration: 0.74),
        ])
        expand.timingMode = .easeOut
        ring.run(.sequence([expand, .removeFromParent()]))
    }

    func endIdlePulse() {
        playerNode.removeAction(forKey: "idlePulse")
        if let aura = playerNode.childNode(withName: "idleAura") {
            aura.removeAllActions()
            aura.run(.fadeOut(withDuration: 0.12))
        }
        playerNode.children.filter { $0.name == "idlePing" }.forEach { $0.removeFromParent() }
    }

    func syncPlayerPose() {
        if session.sim.phase == .dead, let body = playerNode.childNode(withName: "body") as? SKShapeNode {
            body.fillColor = UIColor(red: 1, green: 0.42, blue: 0.46, alpha: 1)
        }
        let heading = displayed.lastAim.length > 0.1 ? displayed.lastAim : displayed.lastVelocity
        syncMotionEmitter(
            playerNode,
            headingX: heading.x,
            headingY: heading.y,
            speed: displayed.lastVelocity.length,
            dashing: displayed.effects.isSurging
        )
    }

    func syncEchoPose(_ node: SKNode, index: Int) {
        guard displayed.echoes.indices.contains(index) else { return }
        let current = displayed.echoes[index]
        let previous: Vec2
        if let x = node.userData?["lastEchoX"] as? NSNumber,
           let y = node.userData?["lastEchoY"] as? NSNumber {
            previous = Vec2(x: x.doubleValue, y: y.doubleValue)
        } else {
            previous = current
        }
        node.userData = node.userData ?? NSMutableDictionary()
        node.userData?["lastEchoX"] = current.x
        node.userData?["lastEchoY"] = current.y
        let delta = current - previous
        let moving = current.distance(to: previous) > 1.2
        syncMotionEmitter(
            node,
            headingX: delta.x,
            headingY: delta.y,
            speed: moving ? current.distance(to: previous) * 40 : 0,
            dashing: false
        )
    }

    func refreshExit() {
        let outer = exitNode.childNode(withName: "outer") as? SKShapeNode
        let spin = exitNode.childNode(withName: "spin") as? SKShapeNode
        let core = exitNode.childNode(withName: "core") as? SKSpriteNode
        if displayed.exitOpen && !wasExitOpen {
            outer?.run(.sequence([
                .scale(to: 1.42, duration: 0.18),
                .scale(to: 1, duration: 0.38),
            ]), withKey: "opening")
            shockwave(at: exitNode.position, color: UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 1),
                      start: 14, end: 88)
        }
        wasExitOpen = displayed.exitOpen
        if displayed.exitOpen {
            outer?.strokeColor = UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 1)
            outer?.fillColor = UIColor(red: 0.35, green: 0.78, blue: 1, alpha: 0.16)
            outer?.glowWidth = 0
            spin?.strokeColor = UIColor(red: 0.7, green: 0.95, blue: 1, alpha: 0.85)
            spin?.glowWidth = 0
            core?.alpha = 0.55
            core?.color = UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 1)
            core?.colorBlendFactor = 0.55
            spin?.isHidden = false
        } else {
            outer?.strokeColor = UIColor.white.withAlphaComponent(0.22)
            outer?.fillColor = UIColor(white: 0.04, alpha: 0.55)
            outer?.glowWidth = 0
            spin?.isHidden = true
            core?.alpha = 0.08
            core?.colorBlendFactor = 0
        }
    }

    func radialShards(at point: CGPoint, color: UIColor, count: Int) {
        for index in 0..<max(1, count) {
            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2
            let shard = SKShapeNode(rectOf: CGSize(width: 3, height: 17), cornerRadius: 1.5)
            shard.position = CGPoint(x: point.x + cos(angle) * 12, y: point.y + sin(angle) * 12)
            shard.zRotation = angle - .pi / 2
            shard.fillColor = index.isMultiple(of: 3) ? .white : color
            shard.strokeColor = .clear
            shard.glowWidth = 0
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

}
