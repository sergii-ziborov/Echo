import Foundation

extension ProgressStore {
    func addShards(_ amount: Int) {
        shards += max(0, amount)
        persist()
    }

    var points: Int { shards }

    func count(_ kind: BonusKind) -> Int {
        inventory[kind.rawValue] ?? 0
    }

    var inventoryCapacity: Int { Self.capacity(reserves: upgradeLevel(.reserves)) }

    var skillSlotCount: Int { Self.slots(rank: upgradeLevel(.slots)) }

    static func capacity(reserves rank: Int) -> Int { min(maxOwned, 3 + rank * 2) }

    static func slots(rank: Int) -> Int { min(6, 2 + rank) }

    static func discount(fabricator rank: Int) -> Double { min(0.25, Double(rank) * 0.05) }

    var equippedSkills: [BonusKind] {
        equippedSkillIDs.compactMap(BonusKind.init(rawValue:))
    }

    var unlockedSkillCount: Int {
        BonusKind.allCases.filter { $0.canBuy && isSkillUnlocked($0) }.count
    }

    func skillPrice(_ kind: BonusKind) -> Int {
        let discount = Self.discount(fabricator: upgradeLevel(.fabricator))
        return max(1, Int((Double(kind.price) * (1 - discount)).rounded()))
    }

    func canBuy(_ kind: BonusKind) -> Bool {
        kind.canBuy
            && isSkillUnlocked(kind)
            && shards >= skillPrice(kind)
            && count(kind) < inventoryCapacity
    }

    @discardableResult
    func buy(_ kind: BonusKind) -> Bool {
        guard canBuy(kind) else { return false }
        shards -= skillPrice(kind)
        inventory[kind.rawValue] = count(kind) + 1
        if !equippedSkillIDs.contains(kind.rawValue), equippedSkillIDs.count < skillSlotCount {
            equippedSkillIDs.append(kind.rawValue)
        }
        persist()
        return true
    }

    @discardableResult
    func consume(_ kind: BonusKind) -> Bool {
        let owned = count(kind)
        guard owned > 0 else { return false }
        if owned == 1 {
            inventory.removeValue(forKey: kind.rawValue)
        } else {
            inventory[kind.rawValue] = owned - 1
        }
        persist()
        return true
    }

    func refund(_ kind: BonusKind) {
        inventory[kind.rawValue] = min(Self.maxOwned, count(kind) + 1)
        persist()
    }

    func isSkillUnlocked(_ kind: BonusKind) -> Bool {
        if count(kind) > 0 { return true }
        return switch kind {
        case .shield, .freeze: true
        case .surge: upgradeLevel(.velocity) >= 1
        case .pulse: upgradeLevel(.chronoResearch) >= 1
        case .magnet: upgradeLevel(.magnetism) >= 1
        case .phase: upgradeLevel(.phaseResearch) >= 1
        case .chrono: upgradeLevel(.chronoResearch) >= 1
        case .anchor: upgradeLevel(.anchorResearch) >= 1
        case .repulse: upgradeLevel(.repulseResearch) >= 1
        case .prism: upgradeLevel(.prismResearch) >= 1
        case .blink: upgradeLevel(.blinkResearch) >= 1
        case .ward: false
        }
    }

    func skillUnlockHint(_ kind: BonusKind) -> String {
        let research: UpgradeKind? = switch kind {
        case .shield, .freeze, .ward: nil
        case .surge: .velocity
        case .pulse, .chrono: .chronoResearch
        case .magnet: .magnetism
        case .phase: .phaseResearch
        case .anchor: .anchorResearch
        case .repulse: .repulseResearch
        case .prism: .prismResearch
        case .blink: .blinkResearch
        }
        guard let research else { return Copy.text("lab.unlock.available") }
        return Copy.format("lab.unlock.research", "\(research.title) I")
    }

    @discardableResult
    func toggleEquipped(_ kind: BonusKind) -> Bool {
        if let index = equippedSkillIDs.firstIndex(of: kind.rawValue) {
            equippedSkillIDs.remove(at: index)
            persist()
            return true
        }
        guard kind.useFromBar, isSkillUnlocked(kind), equippedSkillIDs.count < skillSlotCount else {
            return false
        }
        equippedSkillIDs.append(kind.rawValue)
        persist()
        return true
    }

    func upgradeLevel(_ kind: UpgradeKind) -> Int {
        min(kind.maxLevel, max(0, upgrades[kind.rawValue] ?? 0))
    }

    func upgradeCost(_ kind: UpgradeKind) -> Int? {
        let level = upgradeLevel(kind)
        guard level < kind.maxLevel else { return nil }
        return kind.cost(after: level)
    }

    func prerequisitesMet(for kind: UpgradeKind) -> Bool {
        kind.prerequisites.allSatisfy { upgradeLevel($0.kind) >= $0.level }
    }

    func upgradeRequirement(_ kind: UpgradeKind) -> String? {
        guard let missing = kind.prerequisites.first(where: { upgradeLevel($0.kind) < $0.level }) else {
            return nil
        }
        return Copy.format("lab.requires", "\(missing.kind.title) \(Self.roman(missing.level))")
    }

    func canUpgrade(_ kind: UpgradeKind) -> Bool {
        guard prerequisitesMet(for: kind), let cost = upgradeCost(kind) else { return false }
        return shards >= cost
    }

    @discardableResult
    func buyUpgrade(_ kind: UpgradeKind) -> Bool {
        guard canUpgrade(kind), let cost = upgradeCost(kind) else { return false }
        shards -= cost
        upgrades[kind.rawValue] = upgradeLevel(kind) + 1
        sanitizeEquippedSkills()
        persist()
        return true
    }

    var playerTuning: PlayerTuning {
        Self.tuning(wrist: wrist) { upgradeLevel($0) }
    }

    /// Run tuning for a set of research ranks. The Lab previews one rank with it,
    /// so what a node promises is what the run applies.
    static func tuning(wrist: WristProgress = WristProgress(), rank: (UpgradeKind) -> Int) -> PlayerTuning {
        let rewindLevel = rank(.rewind)
        let aegisLevel = rank(.aegis)
        return PlayerTuning(
            speedMultiplier: 1 + Double(rank(.velocity)) * 0.04,
            pickupRadiusBonus: Double(rank(.sparkSense)) * 3.5,
            dashCooldownMultiplier: max(0.42, 1 - Double(rank(.dashCapacitor)) * 0.09),
            dashDurationBonus: Double(rank(.dashImpulse)) * 0.09,
            cooldownMultiplier: max(0.46, 1 - Double(rank(.recharge)) * 0.08),
            timedEffectMultiplier: 1 + Double(rank(.fieldAmplifier)) * 0.04,
            surgeBonus: Double(rank(.surgeMastery)) * 0.45,
            freezeBonus: Double(rank(.cryostasis)) * 0.55,
            magnetRadiusMultiplier: 1 + Double(rank(.magnetism)) * 0.14,
            shieldGraceBonus: Double(aegisLevel) * 0.18 + Double(rank(.shieldLattice)) * 0.12,
            startsShielded: aegisLevel >= 5,
            shieldChargesPerUse: rank(.shieldLattice) >= 5 ? 2 : 1,
            laserWarningBonus: Double(rank(.beamForecast)) * 0.18,
            echoDelayBonus: Double(rank(.echoForecast)) * 0.45
                + (wrist.isUnlocked(.mainspring) ? WristProgress.echoDelayRelicBonus : 0),
            crystalRewardBonus: Double(rank(.crystalMemory)) * 0.30,
            rewindSeconds: 3 + Double(rewindLevel) * 0.45,
            rewindCharges: (rewindLevel >= 5 ? 3 : rewindLevel >= 2 ? 2 : 1) + (wrist.isUnlocked(.crownCharge) ? 1 : 0),
            anchorTimeScale: max(0.24, 0.44 - Double(rank(.anchorResearch)) * 0.05),
            anchorBonus: Double(rank(.anchorResearch)) * 0.35,
            repulseRadius: 160 + Double(rank(.repulseResearch)) * 24,
            prismBonus: Double(rank(.prismResearch)) * 0.5,
            blinkDistance: 165 + Double(rank(.blinkResearch)) * 28,
            phaseBonus: Double(max(0, rank(.phaseResearch) - 1)) * 0.45,
            chronoDelayBonus: Double(max(0, rank(.chronoResearch) - 1)) * 0.65,
            pulseDelayBonus: Double(max(0, rank(.chronoResearch) - 1)) * 0.40
        )
    }

    var canBuyLife: Bool {
        shards >= Self.lifePrice && lives < Self.maxLives
    }

    @discardableResult
    func addLife(_ amount: Int = 1) -> Int {
        let before = lives
        lives = min(Self.maxLives, lives + max(0, amount))
        persist()
        return lives - before
    }

    @discardableResult
    func spendLife() -> Bool {
        guard lives > 0 else { return false }
        lives -= 1
        persist()
        return true
    }

    @discardableResult
    func buyLife() -> Bool {
        guard canBuyLife else { return false }
        shards -= Self.lifePrice
        lives += 1
        persist()
        return true
    }

}
