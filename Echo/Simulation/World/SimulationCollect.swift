import Foundation

extension WorldSimulation {
    /// Seconds to collect the next spark and keep the resonance chain going.
    static let normalResonanceWindow: TimeInterval = 3.25
    /// The candy training mode is more forgiving.
    static let candyResonanceWindow: TimeInterval = 5.0
    /// Freeze seconds a timed crystal pays when taken before its ring empties.
    static let crystalFreezeReward: TimeInterval = 1.5
    /// Seconds Pulse and Shift push the next echo back, before research.
    static let pulseEchoDelay: TimeInterval = 2.4
    static let shiftEchoDelay: TimeInterval = 3.6

    func tickLasers() -> [SimEvent] {
        var events: [SimEvent] = []
        for i in lasers.indices {
            lasers[i].updateGeometry(at: playbackTime)
            let previous = lasers[i].phase
            let next = lasers[i].phase(at: playbackTime, warningBonus: tuning.laserWarningBonus)
            if case .charging = next, case .idle = previous {
                events.append(.laserCharging(id: lasers[i].id))
            }
            if case .firing = next, previous != .firing {
                events.append(.laserFired(id: lasers[i].id))
            }
            lasers[i].phase = next
        }
        return events
    }

    func updateOrbits() {
        for i in sparks.indices where !sparks[i].collected {
            guard !sparks[i].magnetHeld, let orbit = sparks[i].orbit, orbit.period > 0 else { continue }
            let angle = orbit.phase + (playbackTime / orbit.period) * (.pi * 2)
            sparks[i].position = Vec2(
                x: orbit.center.x + cos(angle) * orbit.radius,
                y: orbit.center.y + sin(angle) * orbit.radius
            )
        }
    }

    func applyMagnet(dt: TimeInterval) {
        guard effects.isMagnet else { return }
        for i in sparks.indices where !sparks[i].collected {
            let delta = playerPosition - sparks[i].position
            let dist = delta.length
            if dist < config.magnetRadius * tuning.magnetRadiusMultiplier, dist > 1 {
                sparks[i].magnetHeld = true
                sparks[i].orbit = nil
                sparks[i].position = sparks[i].position + delta.normalized() * min(280 * dt, dist)
            }
        }
    }

    func tickTimers(dt: TimeInterval) -> [SimEvent] {
        var events: [SimEvent] = []
        for i in sparks.indices where !sparks[i].collected {
            guard let remaining = sparks[i].timerRemaining else { continue }
            let next = remaining - dt
            if next <= 0, !sparks[i].timedOut {
                sparks[i].timerRemaining = 0
                sparks[i].timedOut = true
                events.append(.sparkTimerExpired(id: sparks[i].id))
            } else if next > 0 {
                sparks[i].timerRemaining = next
            }
        }
        return events
    }

    func tickResonance(dt: TimeInterval) {
        guard resonanceRemaining > 0 else { return }
        resonanceRemaining = max(0, resonanceRemaining - dt)
        if resonanceRemaining <= 0 {
            resonanceChain = 0
        }
    }

    func collectSparks() -> [SimEvent] {
        var events: [SimEvent] = []
        for i in sparks.indices where !sparks[i].collected {
            if playerPosition.distance(to: sparks[i].position) < config.playerRadius + config.sparkRadius + tuning.pickupRadiusBonus {
                let securedCharge = sparks[i].timerDuration != nil && !sparks[i].timedOut
                sparks[i].collected = true
                let remaining = sparksRemaining
                events.append(.sparkCollected(id: sparks[i].id, remaining: remaining))
                resonanceChain = resonanceRemaining > 0 ? resonanceChain + 1 : 1
                resonanceRemaining = resonanceWindow
                bestResonance = max(bestResonance, resonanceChain)
                if resonanceChain >= 2 {
                    events.append(.resonance(chain: resonanceChain, window: resonanceWindow))
                }
                if securedCharge {
                    let reward = Self.crystalFreezeReward + tuning.freezeBonus * 0.25 + tuning.crystalRewardBonus
                    effects.freezeRemaining += reward
                    timedSparksSecured += 1
                    events.append(.timeCrystalSecured(id: sparks[i].id, freeze: reward))
                }
                if remaining == 0, !exitOpen {
                    exitOpen = true
                    events.append(.exitOpened)
                }
            }
        }
        return events
    }

    func collectBonuses() -> [SimEvent] {
        var events: [SimEvent] = []
        for i in bonuses.indices where !bonuses[i].collected {
            if playerPosition.distance(to: bonuses[i].position) < config.playerRadius + config.bonusRadius {
                bonuses[i].collected = true
                bonusesCollected += 1
                events.append(contentsOf: apply(bonuses[i].kind))
                events.append(.bonusCollected(kind: bonuses[i].kind))
            }
        }
        return events
    }

    @discardableResult
    func apply(_ kind: BonusKind) -> [SimEvent] {
        switch kind {
        case .shield:
            effects.shieldCharges += tuning.shieldChargesPerUse
        case .freeze:
            effects.freezeRemaining += (kind.duration + tuning.freezeBonus) * tuning.timedEffectMultiplier
        case .surge:
            effects.surgeRemaining += (kind.duration + tuning.surgeBonus) * tuning.timedEffectMultiplier
        case .pulse:
            pulseDelay += Self.pulseEchoDelay + tuning.pulseDelayBonus
        case .magnet:
            effects.magnetRemaining += kind.duration * tuning.timedEffectMultiplier
        case .phase:
            let duration = (kind.duration + tuning.phaseBonus) * tuning.timedEffectMultiplier
            effects.phaseRemaining += duration
            effects.iFrames = max(effects.iFrames, duration)
        case .chrono:
            pulseDelay += Self.shiftEchoDelay + tuning.chronoDelayBonus
        case .anchor:
            effects.anchorRemaining += (kind.duration + tuning.anchorBonus) * tuning.timedEffectMultiplier
        case .repulse:
            applyRepulse()
        case .prism:
            effects.prismRemaining += (kind.duration + tuning.prismBonus) * tuning.timedEffectMultiplier
        case .blink:
            return applyBlink()
        case .ward:
            effects.shieldCharges += tuning.shieldChargesPerUse
        }
        return []
    }

    func applyRepulse() {
        let radius = tuning.repulseRadius
        for index in movers.indices {
            let delta = movers[index].position - playerPosition
            guard delta.length <= radius + movers[index].radius else { continue }
            if case .stationary = movers[index].path { continue }
            let direction = delta.length > 1 ? delta.normalized() : Vec2(x: 1, y: 0)
            if movers[index].material.isBreakable {
                movers[index].hitsRemaining = 0
                movers[index].fractureRemaining = 0
            } else {
                movers[index].path = .bounce
                movers[index].velocity = direction * max(300, movers[index].velocity.length)
                let pushed = movers[index].position + direction * 34
                movers[index].position = clampToArena(pushed, radius: movers[index].radius)
            }
        }
        scars.removeAll { $0.position.distance(to: playerPosition) <= radius }
        pulseDelay += 0.7
        effects.iFrames = max(effects.iFrames, 0.25)
    }

    func blinkDirection() -> Vec2? {
        if lastAim.length > 0.1 { return lastAim }
        if lastVelocity.length > 1 { return lastVelocity.normalized() }
        return nil
    }

    func applyBlink() -> [SimEvent] {
        guard let direction = blinkDirection() else { return [] }
        let from = playerPosition
        let destination = playerPosition + direction * tuning.blinkDistance
        playerPosition = resolveWalls(clampToArena(destination, radius: config.playerRadius), radius: config.playerRadius)
        effects.iFrames = max(effects.iFrames, 0.45)
        return [.playerTeleported(from: from, to: playerPosition, reason: .blink)]
    }
}
