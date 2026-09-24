import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
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
            pendingPlayerTrailBreak = true
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
}
