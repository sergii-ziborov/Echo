import Foundation

extension UpgradeKind {
    /// What this research gives at `rank`, read from the tuning the run
    /// applies, so a node never promises a number the arena does not use.
    @MainActor
    func effect(atRank rank: Int) -> String {
        let tuning = ProgressStore.tuning { $0 == self ? rank : 0 }
        let config = SimConfig()
        let key = "lab.effect.\(rawValue)"
        func base() -> String { Copy.text("\(key).base") }

        switch self {
        case .velocity:
            return rank == 0 ? base() : Copy.format(key, Copy.percent(tuning.speedMultiplier - 1))
        case .sparkSense:
            return rank == 0 ? base() : Copy.format(key, Copy.number(tuning.pickupRadiusBonus))
        case .dashCapacitor:
            return Copy.format(key, Copy.number(config.dashCooldown * tuning.dashCooldownMultiplier))
        case .surgeMastery:
            return Self.duration(.surge, BonusKind.surge.duration + tuning.surgeBonus)
        case .dashImpulse:
            return Copy.format(key, Copy.number(config.dashDuration + tuning.dashDurationBonus))
        case .slots:
            return Copy.format(key, ProgressStore.slots(rank: rank))
        case .reserves:
            return Copy.format(key, ProgressStore.capacity(reserves: rank))
        case .fabricator:
            return rank == 0 ? base() : Copy.format(key, Copy.percent(ProgressStore.discount(fabricator: rank)))
        case .aegis:
            if rank == 0 { return base() }
            let grace = Copy.number(tuning.shieldGraceBonus)
            return Copy.format(tuning.startsShielded ? "\(key).final" : "lab.effect.grace", grace)
        case .shieldLattice:
            if rank == 0 { return base() }
            let grace = Copy.number(tuning.shieldGraceBonus)
            return Copy.format(tuning.shieldChargesPerUse > 1 ? "\(key).final" : "lab.effect.grace", grace)
        case .fieldAmplifier:
            return rank == 0 ? base() : Copy.format(key, Copy.percent(tuning.timedEffectMultiplier - 1))
        case .recharge:
            return rank == 0 ? base() : Copy.format(key, Copy.percent(1 - tuning.cooldownMultiplier))
        case .beamForecast:
            return rank == 0 ? base() : Copy.format(key, Copy.number(tuning.laserWarningBonus))
        case .cryostasis:
            return Self.duration(.freeze, BonusKind.freeze.duration + tuning.freezeBonus)
        case .echoForecast:
            return rank == 0 ? base() : Copy.format(key, Copy.number(tuning.echoDelayBonus))
        case .crystalMemory:
            return Copy.format(key, Copy.number(WorldSimulation.crystalFreezeReward + tuning.crystalRewardBonus))
        case .magnetism:
            if rank == 0 { return Self.locked(.magnet) }
            return Copy.format(key, BonusKind.magnet.title, Copy.percent(tuning.magnetRadiusMultiplier - 1))
        case .phaseResearch:
            if rank == 0 { return Self.locked(.phase) }
            return Self.duration(.phase, BonusKind.phase.duration + tuning.phaseBonus)
        case .chronoResearch:
            if rank == 0 { return Copy.format("\(key).base", BonusKind.chrono.title, BonusKind.pulse.title) }
            return Copy.format(
                key,
                BonusKind.chrono.title, Copy.number(WorldSimulation.shiftEchoDelay + tuning.chronoDelayBonus),
                BonusKind.pulse.title, Copy.number(WorldSimulation.pulseEchoDelay + tuning.pulseDelayBonus)
            )
        case .rewind:
            return Copy.format(key, Copy.number(tuning.rewindSeconds), Copy.format("lab.charges", tuning.rewindCharges))
        case .anchorResearch:
            if rank == 0 { return Self.locked(.anchor) }
            return Copy.format(
                key,
                BonusKind.anchor.title,
                Copy.percent(tuning.anchorTimeScale),
                Copy.number(BonusKind.anchor.duration + tuning.anchorBonus)
            )
        case .repulseResearch:
            if rank == 0 { return Self.locked(.repulse) }
            return Copy.format(key, BonusKind.repulse.title, Copy.number(tuning.repulseRadius))
        case .prismResearch:
            if rank == 0 { return Self.locked(.prism) }
            return Self.duration(.prism, BonusKind.prism.duration + tuning.prismBonus)
        case .blinkResearch:
            if rank == 0 { return Self.locked(.blink) }
            return Copy.format(key, BonusKind.blink.title, Copy.number(tuning.blinkDistance))
        }
    }

    private static func duration(_ skill: BonusKind, _ seconds: TimeInterval) -> String {
        Copy.format("lab.effect.duration", skill.title, Copy.number(seconds))
    }

    private static func locked(_ skill: BonusKind) -> String {
        Copy.format("lab.effect.locked", skill.title)
    }
}
