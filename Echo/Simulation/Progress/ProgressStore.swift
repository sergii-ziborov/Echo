import Foundation

@MainActor
@Observable
final class ProgressStore {
    let defaults: UserDefaults
    static let maxOwned = 15
    static let maxLives = 5
    static let startingLives = 3
    static let lifePrice = 100

    let starsKey = "echo.progress.stars"
    let shardsKey = "echo.progress.shards"
    let inventoryKey = "echo.progress.inventory"
    let livesKey = "echo.progress.lives"
    let lastLevelKey = "echo.progress.lastLevel"
    let tutorialKey = "echo.progress.tutorialSeen"
    let dailyKey = "echo.progress.lastDaily"
    let soundKey = "echo.settings.sound"
    let soundVolumeKey = "echo.settings.soundVolume"
    let hapticsKey = "echo.settings.haptics"
    let replayKey = "echo.settings.autoReplay"
    let hintsKey = "echo.progress.hints"
    let upgradesKey = "echo.progress.upgrades.v1"
    let equippedKey = "echo.progress.equipped.v1"
    let difficultyKey = "echo.progress.difficultyCycle.v1"
    let completedDifficultyKey = "echo.progress.completedDifficultyCycles.v1"
    let wristKey = "echo.progress.wrist.v1"
    let wristTrailKey = "echo.settings.wristTrail.v1"

    var starsByLevel: [String: LevelProgress]
    var shards: Int
    var inventory: [String: Int]
    var lives: Int
    var lastLevelID: String
    var hasSeenTutorial: Bool
    var lastDailyKey: String?
    var soundEnabled: Bool
    var soundVolume: Double
    var hapticsEnabled: Bool
    var autoReplayEnabled: Bool
    var seenHints: Set<String>
    var upgrades: [String: Int]
    var equippedSkillIDs: [String]
    var difficultyCycle: Int
    var completedDifficultyCycles: Int
    /// Clears earned on Apple Watch; they unlock relics in the iPhone game.
    var wrist: WristProgress
    var wristTrailEnabled: Bool

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
        if let savedVolume = defaults.object(forKey: soundVolumeKey) as? NSNumber {
            soundVolume = min(1, max(0, savedVolume.doubleValue))
        } else {
            soundVolume = 0.82
        }
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
        if let data = defaults.data(forKey: wristKey),
           let decoded = try? JSONDecoder().decode(WristProgress.self, from: data) {
            wrist = decoded
        } else {
            wrist = WristProgress()
        }
        wristTrailEnabled = defaults.object(forKey: wristTrailKey) as? Bool ?? true
        sanitizeEquippedSkills()
    }

    var difficulty: DifficultyProfile { DifficultyProfile(cycle: difficultyCycle) }


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
        defaults.set(soundVolume, forKey: soundVolumeKey)
        defaults.set(hapticsEnabled, forKey: hapticsKey)
        defaults.set(autoReplayEnabled, forKey: replayKey)
    }

    func persist() {
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
        if let data = try? JSONEncoder().encode(wrist) {
            defaults.set(data, forKey: wristKey)
        }
        defaults.set(wristTrailEnabled, forKey: wristTrailKey)
    }

    func progressKey(for id: String, cycle: Int? = nil) -> String {
        guard !id.hasPrefix("daily") else { return id }
        let resolvedCycle = max(0, cycle ?? difficultyCycle)
        return resolvedCycle == 0 ? id : "\(id)::difficulty-\(resolvedCycle)"
    }

    func sanitizeEquippedSkills() {
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

    static func roman(_ value: Int) -> String {
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
