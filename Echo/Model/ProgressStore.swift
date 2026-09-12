import Foundation

struct LevelProgress: Equatable, Sendable, Codable {
    var stars: Int = 0
    var bestTime: TimeInterval?
    var bestMoves: Int?
}

@MainActor
@Observable
final class ProgressStore {
    private let defaults: UserDefaults
    static let maxOwned = 9
    static let maxLives = 5
    static let startingLives = 3
    static let lifePrice = 100

    private let starsKey = "echo.progress.stars"
    private let shardsKey = "echo.progress.shards"
    private let inventoryKey = "echo.progress.inventory"
    private let livesKey = "echo.progress.lives"
    private let lastLevelKey = "echo.progress.lastLevel"
    private let tutorialKey = "echo.progress.tutorialSeen"
    private let dailyKey = "echo.progress.lastDaily"
    private let soundKey = "echo.settings.sound"
    private let hapticsKey = "echo.settings.haptics"
    private let replayKey = "echo.settings.autoReplay"
    private let hintsKey = "echo.progress.hints"
    private let upgradesKey = "echo.progress.upgrades.v1"
    private let equippedKey = "echo.progress.equipped.v1"
    private let difficultyKey = "echo.progress.difficultyCycle.v1"
    private let completedDifficultyKey = "echo.progress.completedDifficultyCycles.v1"

    private(set) var starsByLevel: [String: LevelProgress]
    private(set) var shards: Int
    private(set) var inventory: [String: Int]
    private(set) var lives: Int
    private(set) var lastLevelID: String
    var hasSeenTutorial: Bool
    private(set) var lastDailyKey: String?
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var autoReplayEnabled: Bool
    private(set) var seenHints: Set<String>
    private(set) var upgrades: [String: Int]
    private(set) var equippedSkillIDs: [String]
    private(set) var difficultyCycle: Int
    private(set) var completedDifficultyCycles: Int

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: starsKey),
           let decoded = try? JSONDecoder().decode([String: LevelProgress].self, from: data) {
            starsByLevel = decoded
        } else {
            starsByLevel = [:]
        }
        shards = defaults.integer(forKey: shardsKey)
        if let data = defaults.data(forKey: inventoryKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            inventory = decoded
        } else {
            inventory = [:]
        }
        lives = defaults.object(forKey: livesKey) as? Int ?? Self.startingLives
        lastLevelID = defaults.string(forKey: lastLevelKey) ?? LevelCatalog.prototype.id
        hasSeenTutorial = defaults.bool(forKey: tutorialKey)
        lastDailyKey = defaults.string(forKey: dailyKey)
        soundEnabled = defaults.object(forKey: soundKey) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: hapticsKey) as? Bool ?? true
        autoReplayEnabled = defaults.object(forKey: replayKey) as? Bool ?? true
        if let data = defaults.data(forKey: hintsKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            seenHints = Set(decoded)
        } else {
            seenHints = []
        }
        if let data = defaults.data(forKey: upgradesKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            upgrades = decoded
        } else {
            upgrades = [:]
        }
        if let data = defaults.data(forKey: equippedKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            equippedSkillIDs = decoded
        } else {
            equippedSkillIDs = [BonusKind.shield.rawValue, BonusKind.freeze.rawValue]
        }
        difficultyCycle = max(0, defaults.integer(forKey: difficultyKey))
        completedDifficultyCycles = max(0, defaults.integer(forKey: completedDifficultyKey))
        sanitizeEquippedSkills()
    }

    var difficulty: DifficultyProfile { DifficultyProfile(cycle: difficultyCycle) }

    func continueLevel() -> LevelDefinition {
        if let next = LevelCatalog.playable.first(where: { isUnlocked($0) && progress(for: $0.id).stars == 0 }) {
            return next
        }
        return LevelCatalog.playable.last(where: { isUnlocked($0) }) ?? LevelCatalog.prototype
    }

    @discardableResult
    func markHint(_ key: String) -> Bool {
        guard !seenHints.contains(key) else { return false }
        seenHints.insert(key)
        persist()
        return true
    }

    var totalStars: Int {
        LevelCatalog.playable.reduce(0) { $0 + progress(for: $1.id).stars }
    }

    var lifetimeStars: Int { starsByLevel.values.reduce(0) { $0 + $1.stars } }

    func progress(for id: String, cycle: Int? = nil) -> LevelProgress {
        starsByLevel[progressKey(for: id, cycle: cycle)] ?? LevelProgress()
    }

    func isUnlocked(_ level: LevelDefinition) -> Bool {
        if level.number <= 4 { return true }
        let previous = level.number - 1
        guard let prior = LevelCatalog.level(number: previous) else { return false }
        return progress(for: prior.id).stars > 0
    }

    func recordWin(levelID: String, result: SessionResult, awardsShard: Bool = true) {
        var current = progress(for: levelID)
        current.stars = max(current.stars, result.stars)
        if let best = current.bestTime {
            current.bestTime = min(best, result.time)
        } else {
            current.bestTime = result.time
        }
        if let best = current.bestMoves {
            current.bestMoves = min(best, result.moves)
        } else {
            current.bestMoves = result.moves
        }
        starsByLevel[progressKey(for: levelID)] = current
        if !levelID.hasPrefix("daily") {
            lastLevelID = levelID
        }
        if awardsShard { shards += result.points }
        persist()
    }

    var isCurrentDifficultyComplete: Bool {
        !LevelCatalog.playable.isEmpty
            && LevelCatalog.playable.allSatisfy { progress(for: $0.id).stars > 0 }
    }

    /// Advances only after every authored epoch is clear. Each cycle receives a
    /// separate record namespace, so previous seals and best times stay visible in
    /// lifetime totals while the new route starts cleanly.
    @discardableResult
    func advanceDifficultyIfComplete() -> Bool {
        guard isCurrentDifficultyComplete else { return false }
        completedDifficultyCycles = max(completedDifficultyCycles, difficultyCycle + 1)
        difficultyCycle += 1
        lastLevelID = LevelCatalog.prototype.id
        shards += 777
        persist()
        return true
    }

    func resetProgress() {
        let progressKeys = [
            starsKey, shardsKey, inventoryKey, livesKey, lastLevelKey, tutorialKey,
            dailyKey, hintsKey, upgradesKey, equippedKey, difficultyKey, completedDifficultyKey,
        ]
        progressKeys.forEach { defaults.removeObject(forKey: $0) }
        starsByLevel = [:]
        shards = 0
        inventory = [:]
        lives = Self.startingLives
        lastLevelID = LevelCatalog.prototype.id
        hasSeenTutorial = false
        lastDailyKey = nil
        seenHints = []
        upgrades = [:]
        equippedSkillIDs = [BonusKind.shield.rawValue, BonusKind.freeze.rawValue]
        difficultyCycle = 0
        completedDifficultyCycles = 0
        sanitizeEquippedSkills()
        persist()
    }

    func addShards(_ amount: Int) {
        shards += max(0, amount)
        persist()
    }

    var points: Int { shards }

    func count(_ kind: BonusKind) -> Int {
        inventory[kind.rawValue] ?? 0
    }

    var inventoryCapacity: Int {
        min(Self.maxOwned, 3 + upgradeLevel(.reserves) * 2)
    }

    var skillSlotCount: Int {
        min(5, 2 + upgradeLevel(.slots))
    }

    var equippedSkills: [BonusKind] {
        equippedSkillIDs.compactMap(BonusKind.init(rawValue:))
    }

    var unlockedSkillCount: Int {
        BonusKind.allCases.filter { $0.canBuy && isSkillUnlocked($0) }.count
    }

    func canBuy(_ kind: BonusKind) -> Bool {
        kind.canBuy
            && isSkillUnlocked(kind)
            && shards >= kind.price
            && count(kind) < inventoryCapacity
    }

    @discardableResult
    func buy(_ kind: BonusKind) -> Bool {
        guard canBuy(kind) else { return false }
        shards -= kind.price
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
        case .ward: false
        }
    }

    func skillUnlockHint(_ kind: BonusKind) -> String {
        switch kind {
        case .shield, .freeze: "Available"
        case .surge: "Research Vector Drive I"
        case .pulse: "Research Chrono Theory"
        case .magnet: "Research Magnetic Field I"
        case .phase: "Research Phase Theory"
        case .chrono: "Research Chrono Theory"
        case .ward: "Arena-only"
        }
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
        return "Requires \(missing.kind.title) \(Self.roman(missing.level))"
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
        let rewindLevel = upgradeLevel(.rewind)
        let aegisLevel = upgradeLevel(.aegis)
        return PlayerTuning(
            speedMultiplier: 1 + Double(upgradeLevel(.velocity)) * 0.05,
            dashCooldownMultiplier: max(0.55, 1 - Double(upgradeLevel(.dashCapacitor)) * 0.12),
            cooldownMultiplier: max(0.55, 1 - Double(upgradeLevel(.recharge)) * 0.09),
            freezeBonus: Double(upgradeLevel(.cryostasis)) * 0.7,
            magnetRadiusMultiplier: 1 + Double(upgradeLevel(.magnetism)) * 0.18,
            shieldGraceBonus: Double(aegisLevel) * 0.22,
            startsShielded: aegisLevel >= 3,
            laserWarningBonus: Double(upgradeLevel(.beamForecast)) * 0.22,
            rewindSeconds: 3 + Double(rewindLevel) * 0.5,
            rewindCharges: rewindLevel >= 2 ? 2 : 1
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

    func markTutorialSeen() {
        hasSeenTutorial = true
        defaults.set(true, forKey: tutorialKey)
    }

    func markDailyComplete(_ key: String) {
        lastDailyKey = key
        defaults.set(key, forKey: dailyKey)
    }

    func persistSettings() {
        defaults.set(soundEnabled, forKey: soundKey)
        defaults.set(hapticsEnabled, forKey: hapticsKey)
        defaults.set(autoReplayEnabled, forKey: replayKey)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(starsByLevel) {
            defaults.set(data, forKey: starsKey)
        }
        defaults.set(shards, forKey: shardsKey)
        if let data = try? JSONEncoder().encode(inventory) {
            defaults.set(data, forKey: inventoryKey)
        }
        defaults.set(lastLevelID, forKey: lastLevelKey)
        defaults.set(lives, forKey: livesKey)
        if let data = try? JSONEncoder().encode(Array(seenHints)) {
            defaults.set(data, forKey: hintsKey)
        }
        if let data = try? JSONEncoder().encode(upgrades) {
            defaults.set(data, forKey: upgradesKey)
        }
        if let data = try? JSONEncoder().encode(equippedSkillIDs) {
            defaults.set(data, forKey: equippedKey)
        }
        defaults.set(difficultyCycle, forKey: difficultyKey)
        defaults.set(completedDifficultyCycles, forKey: completedDifficultyKey)
    }

    private func progressKey(for id: String, cycle: Int? = nil) -> String {
        guard !id.hasPrefix("daily") else { return id }
        let resolvedCycle = max(0, cycle ?? difficultyCycle)
        return resolvedCycle == 0 ? id : "\(id)::difficulty-\(resolvedCycle)"
    }

    private func sanitizeEquippedSkills() {
        var seen = Set<String>()
        equippedSkillIDs = equippedSkillIDs.filter { raw in
            guard let kind = BonusKind(rawValue: raw), kind.useFromBar, !seen.contains(raw) else { return false }
            seen.insert(raw)
            return true
        }
        if equippedSkillIDs.count > skillSlotCount {
            equippedSkillIDs = Array(equippedSkillIDs.prefix(skillSlotCount))
        }
    }

    private static func roman(_ value: Int) -> String {
        switch value {
        case 1: "I"
        case 2: "II"
        case 3: "III"
        case 4: "IV"
        case 5: "V"
        default: "\(value)"
        }
    }
}
