import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func syncGates() {
        for gate in displayed.gates {
            guard let node = gateNodes[gate.id] else { continue }
            let changed = gateSolidStates[gate.id] != gate.solid
            gateSolidStates[gate.id] = gate.solid
            node.alpha = gate.solid ? 0.95 : 0.12
            let texture = gate.solid ? GlowTextures.closedGate : GlowTextures.openGate
            for frame in gateFrames[gate.id] ?? [] {
                if let texture { frame.texture = texture }
                frame.alpha = gate.solid ? 0.92 : 0.72
                if changed {
                    frame.run(.sequence([
                        .scale(to: 1.24, duration: 0.08),
                        .scale(to: 1, duration: 0.24),
                    ]), withKey: "gateTransition")
                }
            }
        }
    }

    func syncLasers() {
        for laser in displayed.lasers {
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

            if displayed.effects.isPrismatic {
                aura.strokeColor = UIColor(red: 0.40, green: 1.00, blue: 0.84, alpha: 1)
                aura.alpha = 0.18
                warning.strokeColor = UIColor(red: 0.72, green: 0.48, blue: 1.00, alpha: 1)
                warning.alpha = 0.62
                core.strokeColor = UIColor(red: 0.55, green: 0.94, blue: 1.00, alpha: 1)
                core.alpha = laser.phase == .firing ? 0.58 : 0.18
                emitters.forEach { $0?.setScale(0.98) }
                for index in 0..<4 {
                    guard let pulse = root.childNode(withName: "pulse-\(index)") else { continue }
                    let phase = (displayed.playbackTime * 0.8 + Double(index) / 4)
                        .truncatingRemainder(dividingBy: 1)
                    pulse.position = scenePoint(laser.start.lerp(laser.end, phase))
                    pulse.alpha = 0.38
                }
                continue
            }

            if displayed.effects.isFrozen {
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
                    let t = (displayed.playbackTime * 1.45 + Double(index) / 4)
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

    func syncScars() {
        let live = Set(displayed.scars.map(\.id))
        for (id, node) in scarNodes where !live.contains(id) {
            node.removeFromParent()
            scarNodes.removeValue(forKey: id)
        }
        for scar in displayed.scars {
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
                ring.glowWidth = 0
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

    func syncFrostCrown() {
        playerNode.childNode(withName: "frost")?.removeFromParent()
    }

    func syncWinterEffect() {
        let existing = childNode(withName: "winterStorm")
        if displayed.effects.isFrozen {
            guard existing == nil else { return }
            frostOverlay.removeAllActions()
            frostOverlay.run(.fadeAlpha(to: 0.22, duration: 0.22))

            let storm = SKNode()
            storm.name = "winterStorm"
            storm.zPosition = 19

            let snow = SKEmitterNode()
            snow.particleTexture = GlowTextures.snowflakeParticle
            snow.position = CGPoint(x: size.width / 2, y: size.height + 24)
            snow.particlePositionRange = CGVector(dx: size.width * 1.12, dy: 70)
            snow.particleBirthRate = 5
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

    func syncShieldBubble() {
        playerNode.childNode(withName: "shieldBubble")?.removeFromParent()
    }

    func syncSurgeCrown() {
        playerNode.childNode(withName: "energyCrown")?.removeFromParent()
    }

    func syncMagnetCrown() {
        playerNode.childNode(withName: "magnetCrown")?.removeFromParent()
    }

    func syncAnchorCrown() {
        playerNode.childNode(withName: "anchorCrown")?.removeFromParent()
    }

    func syncPrismCrown() {
        playerNode.childNode(withName: "prismCrown")?.removeFromParent()
    }

    func syncStatusShell() {
        guard let shell = playerNode.childNode(withName: "statusShell") as? SKShapeNode else { return }
        let shielded = displayed.effects.shieldCharges > 0
        let prism = displayed.effects.isPrismatic
        if shielded || prism {
            shell.strokeColor = shielded && prism
                ? UIColor(red: 0.58, green: 1.00, blue: 0.84, alpha: 0.95)
                : (prism ? UIColor(red: 0.60, green: 1.00, blue: 0.92, alpha: 0.88) : VisualPalette.shield)
            shell.lineWidth = 1.55
            shell.alpha = 1
            if prism {
                shell.path = Self.polygonPath(radius: actorRadius + 6, sides: 3)
            } else {
                shell.path = CGPath(ellipseIn: CGRect(x: -actorRadius - 5, y: -actorRadius - 5, width: (actorRadius + 5) * 2, height: (actorRadius + 5) * 2), transform: nil)
            }
        } else {
            shell.strokeColor = .clear
        }
        playerNode.childNode(withName: "body")?.alpha = displayed.effects.isPhasing ? 0.74 : 1
    }
}
