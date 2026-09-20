import SpriteKit
import SwiftUI
import UIKit

extension GameView {
    var resultKey: String {
        session.level.id
    }

    func handle(_ events: [SimEvent]) {
        for event in events {
            switch event {
            case .sparkCollected(let id, _):
                activeModel.audio.haptic(.light)
                if let spark = session.sim.sparks.first(where: { $0.id == id }) {
                    activeModel.audio.play(.collect, pan: audioPan(for: spark.position))
                    scene.burst(at: spark.position, color: UIColor(red: 0.5, green: 0.95, blue: 1, alpha: 1))
                } else {
                    activeModel.audio.play(.collect)
                }
            case .resonance(let chain, _):
                activeModel.audio.play(.resonance, volume: min(1.2, 0.74 + Float(chain) * 0.055))
                activeModel.audio.haptic(chain >= 4 ? .rigid : .soft)
                scene.resonanceEffect(chain: chain, at: session.sim.playerPosition)
                if chain == 2 { offerHint(.resonance) }
            case .timeCrystalSecured:
                activeModel.audio.play(.crystal)
                activeModel.audio.haptic(.medium)
                scene.abilityEffect(kind: .freeze, at: session.sim.playerPosition)
            case .sparkTimerExpired(let id):
                activeModel.audio.play(.timerExpired)
                activeModel.audio.haptic(.soft)
                if let spark = session.sim.sparks.first(where: { $0.id == id }) {
                    scene.timerPop(at: spark.position)
                }
            case .bonusCollected(let kind):
                activeModel.audio.playAbility(kind)
                activeModel.audio.haptic(.medium)
                scene.abilityEffect(kind: kind, at: session.sim.playerPosition)
                offerAbilityHint(kind)
            case .shieldBroke:
                activeModel.audio.play(.shieldBreak)
                activeModel.audio.haptic(.rigid)
                scene.burst(at: session.sim.playerPosition, color: UIColor(red: 0.4, green: 1, blue: 0.65, alpha: 1))
            case .dashed:
                activeModel.audio.play(.dash)
                activeModel.audio.haptic(.light)
            case .laserCharging:
                activeModel.audio.play(.laserCharge)
                activeModel.audio.haptic(.soft)
            case .laserFired(let id):
                activeModel.audio.play(.laserFire)
                activeModel.audio.haptic(.rigid)
                scene.laserDischarge(id: id)
            case .asteroidImpacted(let id, let material, let position):
                activeModel.audio.play(.asteroidImpact, volume: material == .alloy ? 1.15 : 0.88, pan: audioPan(for: position))
                activeModel.audio.haptic(material == .alloy ? .rigid : .soft)
                scene.asteroidImpact(id: id, material: material, at: position)
            case .asteroidShattered(let id, let material, let position):
                activeModel.audio.play(.asteroidShatter, pan: audioPan(for: position))
                activeModel.audio.haptic(.medium)
                scene.asteroidShatter(id: id, material: material, at: position)
            case .echoWillSpawn:
                activeModel.audio.play(.warn)
                activeModel.audio.haptic(.medium)
            case .echoSpawned:
                activeModel.audio.play(.spawn)
                activeModel.audio.haptic(.rigid)
                scene.burst(
                    at: session.sim.echoes.last ?? session.level.playerStart,
                    color: UIColor(red: 0.75, green: 0.4, blue: 1, alpha: 1)
                )
                offerHint(.echo)
            case .exitOpened:
                activeModel.audio.play(.exitOpen)
                activeModel.audio.haptic(.soft)
            case .riftOpened:
                activeModel.audio.play(.riftOpen)
                activeModel.audio.haptic(.soft)
                offerHint(.rift)
            case .riftEntered(let kind):
                activeModel.audio.play(kind == .calm ? .freeze : .riftEnter)
                if kind == .calm {
                    scene.abilityEffect(kind: .freeze, at: session.sim.playerPosition)
                } else if kind == .warp || kind == .candy {
                    scene.realityShift(kind: kind, at: session.sim.playerPosition)
                    offerHint(.realityShift)
                }
            case .playerTeleported:
                scene.notePlayerTeleport()
            case .timeCollision(let at):
                activeModel.audio.play(.timeCollision, pan: audioPan(for: at))
                activeModel.audio.haptic(.rigid)
                scene.burst(at: at, color: UIColor(red: 0.9, green: 0.4, blue: 1, alpha: 1))
                offerHint(.collision)
            case .died:
                activeModel.audio.play(.death)
                activeModel.audio.notify(.error)
            case .won(let result):
                awardedPoints = activeModel.recordWin(
                    levelID: session.level.id,
                    result: result,
                    daily: request.daily,
                    dayKey: session.dailyKey
                )
                activeModel.audio.notify(.success)
            }
        }
    }

    func restart(playSound: Bool = true) {
        if playSound { activeModel.audio.play(.tap) }
        overlay = .none
        session.restart()
        scene.rebuild()
    }

    func paradoxRewind() {
        overlay = .none
        if session.paradoxRewind() {
            activeModel.audio.play(.rewind)
            scene.rebuild()
        } else {
            activeModel.audio.play(.denied)
            restart(playSound: false)
        }
    }

    func useItem(_ kind: BonusKind) {
        guard session.phase == .playing else { return }
        guard session.cooldownRemaining(for: kind) <= 0 else {
            session.banner = String(format: "Recharging %.1fs", session.cooldownRemaining(for: kind))
            activeModel.audio.play(.denied)
            return
        }
        guard activeModel.progress.consume(kind) else { return }
        if session.useBonus(kind) {
            activeModel.audio.playAbility(kind)
            activeModel.audio.haptic(.medium)
            scene.noteTrailEvents(session.sim.drainAppliedEvents())
            scene.abilityEffect(kind: kind, at: session.sim.playerPosition)
            offerAbilityHint(kind)
        } else {
            activeModel.progress.refund(kind)
        }
    }

    func offerHint(_ value: EncounterHint) {
        guard hint == nil, activeModel.progress.markHint(value.rawValue) else { return }
        hint = value
        if session.phase == .playing {
            session.togglePause()
        }
    }

    func offerAbilityHint(_ kind: BonusKind) {
        let value: EncounterHint? = switch kind {
        case .shield, .ward: nil
        case .freeze: .freeze
        case .surge: .surge
        case .pulse: .pulse
        case .magnet: .magnet
        case .phase: .phase
        case .chrono: .chrono
        case .anchor: .anchor
        case .repulse: .repulse
        case .prism: .prism
        case .blink: .blink
        }
        if let value { offerHint(value) }
    }

    func audioPan(for position: Vec2) -> Float {
        let normalized = position.x / max(1, session.level.worldWidth)
        return Float((normalized * 2 - 1) * 0.62)
    }

    func dismissHint() {
        hint = nil
        if session.phase == .paused {
            session.togglePause()
        }
    }

    func nextLevel() {
        activeModel.audio.play(.tap)
        if request.daily {
            activeModel.goHome()
            return
        }
        if session.level.number == LevelCatalog.playable.count {
            activeModel.goHome()
            return
        }
        if let next = LevelCatalog.level(number: session.level.number + 1), activeModel.progress.isUnlocked(next) {
            activeModel.play(level: next, daily: false)
        } else {
            activeModel.goHome()
        }
    }
}
