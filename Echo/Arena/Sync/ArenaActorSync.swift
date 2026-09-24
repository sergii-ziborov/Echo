import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func buildPlayer() {
        if VisualStyle.useLegacyRenderer {
            let root = SKNode()
            root.zPosition = VisualLayer.actors
            let body = SKSpriteNode(texture: GlowTextures.player)
            body.size = CGSize(width: actorRadius * 2, height: actorRadius * 2)
            body.name = "body"
            root.addChild(body)
            addChild(root)
            playerNode = root
            return
        }
        let root = ActorFactory.make(kind: .player, radius: actorRadius)
        addChild(root)
        playerNode = root
    }

    func buildSpawnBeacon() {
        let root = SKNode()
        root.zPosition = 9
        root.position = scenePoint(session.level.playerStart)

        let glow = SKSpriteNode(texture: GlowTextures.spawnRing)
        glow.size = CGSize(width: 72, height: 72)
        glow.blendMode = .add
        glow.alpha = 0.18
        glow.name = "glow"
        glow.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 7.5)))

        let ring = SKShapeNode(circleOfRadius: 26)
        ring.strokeColor = UIColor(red: 0.8, green: 0.4, blue: 1, alpha: 0.95)
        ring.lineWidth = 2.0
        ring.glowWidth = 0
        ring.fillColor = UIColor(red: 0.45, green: 0.2, blue: 0.7, alpha: 0.12)
        ring.name = "ring"

        let arc = SKShapeNode()
        arc.strokeColor = UIColor(red: 0.55, green: 0.85, blue: 1, alpha: 1)
        arc.lineWidth = 2.4
        arc.glowWidth = 0
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

    func echoNode() -> SKNode {
        if VisualStyle.useLegacyRenderer {
            let root = SKNode()
            root.zPosition = VisualLayer.actors - 1
            let body = SKSpriteNode(texture: GlowTextures.echo)
            body.size = CGSize(width: actorRadius * 1.75, height: actorRadius * 1.75)
            body.name = "body"
            root.addChild(body)
            return root
        }
        let root = ActorFactory.make(kind: .echo, radius: actorRadius * 0.92)
        root.zPosition = VisualLayer.actors - 1
        return root
    }

    // MARK: - Sync

    func apply(frame: RenderFrame, mode: RenderMode) {
        displayed = frame
        playerNode.position = scenePoint(frame.player)
        while echoNodes.count < frame.echoes.count {
            let node = echoNode()
            let index = echoNodes.count
            if frame.echoes.indices.contains(index) {
                node.position = scenePoint(frame.echoes[index])
            }
            addChild(node)
            echoNodes.append(node)
            node.userData = ["spawnedAt": frame.playbackTime]
            if mode == .live {
                node.setScale(0.2)
                node.run(.scale(to: 1, duration: 0.22))
                shockwave(at: node.position, color: UIColor(red: 0.8, green: 0.4, blue: 1, alpha: 1), start: 10, end: 64)
            }
        }
        while echoNodes.count > frame.echoes.count {
            echoNodes.removeLast().removeFromParent()
        }
        for (i, echo) in frame.echoes.enumerated() {
            echoNodes[i].position = scenePoint(echo)
            echoNodes[i].isHidden = false
            echoNodes[i].alpha = frame.effects.isFrozen ? 0.78 : frame.effects.isAnchored ? 0.88 : 1
            syncEchoPose(echoNodes[i], index: i)
        }
        syncPlayerPose()
        syncGhosts()
        for spark in frame.sparks {
            sparkNodes[spark.id]?.isHidden = spark.collected
            sparkNodes[spark.id]?.position = scenePoint(spark.position)
        }
        syncBonuses(frame.bonuses, mode: mode)
        syncMovers(frame.movers, frozen: frame.effects.isFrozen)
        for well in frame.gravityWells {
            gravityWellNodes[well.id]?.position = scenePoint(well.position)
            gravityWellNodes[well.id]?.alpha = frame.effects.isFrozen ? 0.52 : frame.effects.isAnchored ? 0.76 : 1
            gravityWellNodes[well.id]?.speed = CGFloat(frame.timelineScale)
        }
        for rift in frame.rifts {
            guard let node = riftNodes[rift.id] else { continue }
            node.position = scenePoint(rift.position)
            node.alpha = rift.open ? 1 : 0.22
            node.setScale(rift.open ? 1 : 0.72)
        }
        syncRealityBackdrop()
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
        syncStatusShell()
        exitNode.position = scenePoint(session.level.exit)
        refreshExit()
        if let halo = playerNode.childNode(withName: "halo") as? SKSpriteNode {
            let tint: UIColor
            if frame.effects.shieldCharges > 0 {
                tint = VisualPalette.shield
            } else if frame.effects.isSurging {
                tint = UIColor(red: 1, green: 0.86, blue: 0.40, alpha: 1)
            } else if frame.effects.isPhasing {
                tint = .white
            } else {
                tint = cometStyle.glow
            }
            halo.color = tint
            halo.colorBlendFactor = 1
            halo.alpha = VisualStyle.glowAlpha
            let span = actorRadius * 2 * VisualStyle.glowRadiusMul
            halo.size = CGSize(width: span, height: span)
        }
        if mode != .live {
            updateSparkTimers()
        }
    }
}
