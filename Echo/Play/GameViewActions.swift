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
                model.audio.haptic(.light)
                if let spark = session.sim.sparks.first(where: { $0.id == id }) {
                    model.audio.play(.collect, pan: audioPan(for: spark.position))
                    scene.burst(at: spark.position, color: UIColor(red: 0.5, green: 0.95, blue: 1, alpha: 1))
                } else {
                    model.audio.play(.collect)
                }
            case .resonance(let chain, _):
                model.audio.play(.resonance, volume: min(1.2, 0.74 + Float(chain) * 0.055))
                model.audio.haptic(chain >= 4 ? .rigid : .soft)
                scene.resonanceEffect(chain: chain, at: session.sim.playerPosition)
                if chain == 2 { offerHint(.resonance) }
            case .timeCrystalSecured:
                model.audio.play(.crystal)
                model.audio.haptic(.medium)
                scene.abilityEffect(kind: .freeze, at: session.sim.playerPosition)
            case .sparkTimerExpired(let id):
                model.audio.play(.timerExpired)
                model.audio.haptic(.soft)
                if let spark = session.sim.sparks.first(where: { $0.id == id }) {
                    scene.timerPop(at: spark.position)
                }
            case .bonusCollected(let kind):
                model.audio.playAbility(kind)
                model.audio.haptic(.medium)
                scene.abilityEffect(kind: kind, at: session.sim.playerPosition)
                offerAbilityHint(kind)
            case .shieldBroke:
                model.audio.play(.shieldBreak)
                model.audio.haptic(.rigid)
                scene.burst(at: session.sim.playerPosition, color: UIColor(red: 0.4, green: 1, blue: 0.65, alpha: 1))
            case .dashed:
                model.audio.play(.dash)
                model.audio.haptic(.light)
            case .laserCharging:
                model.audio.play(.laserCharge)
                model.audio.haptic(.soft)
            case .laserFired(let id):
                model.audio.play(.laserFire)
                model.audio.haptic(.rigid)
                scene.laserDischarge(id: id)
            case .asteroidImpacted(let id, let material, let position):
                model.audio.play(.asteroidImpact, volume: material == .alloy ? 1.15 : 0.88, pan: audioPan(for: position))
                model.audio.haptic(material == .alloy ? .rigid : .soft)
                scene.asteroidImpact(id: id, material: material, at: position)
            case .asteroidShattered(let id, let material, let position):
                model.audio.play(.asteroidShatter, pan: audioPan(for: position))
                model.audio.haptic(.medium)
                scene.asteroidShatter(id: id, material: material, at: position)
            case .echoWillSpawn:
                model.audio.play(.warn)
                model.audio.haptic(.medium)
            case .echoSpawned:
                model.audio.play(.spawn)
                model.audio.haptic(.rigid)
                scene.burst(
                    at: session.sim.echoes.last ?? session.level.playerStart,
                    color: UIColor(red: 0.75, green: 0.4, blue: 1, alpha: 1)
                )
                offerHint(.echo)
            case .exitOpened:
                model.audio.play(.exitOpen)
                model.audio.haptic(.soft)
            case .riftOpened:
                model.audio.play(.riftOpen)
                model.audio.haptic(.soft)
                offerHint(.rift)
            case .riftEntered(let kind):
                model.audio.play(kind == .calm ? .freeze : .riftEnter)
                if kind == .calm {
                    scene.abilityEffect(kind: .freeze, at: session.sim.playerPosition)
                } else if kind == .warp || kind == .candy {
                    scene.realityShift(kind: kind, at: session.sim.playerPosition)
                    offerHint(.realityShift)
                }
            case .playerTeleported:
                scene.notePlayerTeleport()
            case .timeCollision(let at):
                model.audio.play(.timeCollision, pan: audioPan(for: at))
                model.audio.haptic(.rigid)
                scene.burst(at: at, color: UIColor(red: 0.9, green: 0.4, blue: 1, alpha: 1))
                offerHint(.collision)
            case .died:
                model.audio.play(.death)
                model.audio.notify(.error)
            case .won(let result):
                awardedPoints = model.recordWin(
                    levelID: session.level.id,
                    result: result,
                    daily: request.daily,
                    dayKey: session.dailyKey
                )
                model.audio.notify(.success)
            }
        }
    }

    func restart(playSound: Bool = true) {
        if playSound { model.audio.play(.tap) }
        overlay = .none
        session.restart()
        scene.rebuild()
    }

    func paradoxRewind() {
        overlay = .none
        if session.paradoxRewind() {
            model.audio.play(.rewind)
            scene.rebuild()
        } else {
            model.audio.play(.denied)
            restart(playSound: false)
        }
    }

    func useItem(_ kind: BonusKind) {
        guard session.phase == .playing else { return }
        guard session.cooldownRemaining(for: kind) <= 0 else {
            session.banner = String(format: "Recharging %.1fs", session.cooldownRemaining(for: kind))
            model.audio.play(.denied)
            return
        }
        guard model.progress.consume(kind) else { return }
        if session.useBonus(kind) {
            model.audio.playAbility(kind)
            model.audio.haptic(.medium)
            scene.noteTrailEvents(session.sim.drainAppliedEvents())
            scene.abilityEffect(kind: kind, at: session.sim.playerPosition)
            offerAbilityHint(kind)
        } else {
            model.progress.refund(kind)
        }
    }

    func offerHint(_ value: EncounterHint) {
        guard hint == nil, model.progress.markHint(value.rawValue) else { return }
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
        model.audio.play(.tap)
        if request.daily {
            model.goHome()
            return
        }
        if session.level.number == LevelCatalog.playable.count {
            model.goHome()
            return
        }
        if let next = LevelCatalog.level(number: session.level.number + 1), model.progress.isUnlocked(next) {
            model.play(level: next, daily: false)
        } else {
            model.goHome()
        }
    }
}
