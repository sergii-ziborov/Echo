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

    private let starsKey = "echo.progress.stars"
    private let shardsKey = "echo.progress.shards"
    private let inventoryKey = "echo.progress.inventory"
    private let lastLevelKey = "echo.progress.lastLevel"
    private let tutorialKey = "echo.progress.tutorialSeen"
    private let dailyKey = "echo.progress.lastDaily"
    private let soundKey = "echo.settings.sound"
    private let hapticsKey = "echo.settings.haptics"
    private let replayKey = "echo.settings.autoReplay"

    private(set) var starsByLevel: [String: LevelProgress]
    private(set) var shards: Int
    private(set) var inventory: [String: Int]
    private(set) var lastLevelID: String
    var hasSeenTutorial: Bool
    private(set) var lastDailyKey: String?
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var autoReplayEnabled: Bool

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
        lastLevelID = defaults.string(forKey: lastLevelKey) ?? LevelCatalog.prototype.id
        hasSeenTutorial = defaults.bool(forKey: tutorialKey)
        lastDailyKey = defaults.string(forKey: dailyKey)
        soundEnabled = defaults.object(forKey: soundKey) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: hapticsKey) as? Bool ?? true
        autoReplayEnabled = defaults.object(forKey: replayKey) as? Bool ?? true
    }

    var totalStars: Int {
        starsByLevel.values.reduce(0) { $0 + $1.stars }
    }

    func progress(for id: String) -> LevelProgress {
        starsByLevel[id] ?? LevelProgress()
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
        starsByLevel[levelID] = current
        lastLevelID = levelID
        if awardsShard { shards += result.points }
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

    func canBuy(_ kind: BonusKind) -> Bool {
        shards >= kind.price && count(kind) < Self.maxOwned
    }

    @discardableResult
    func buy(_ kind: BonusKind) -> Bool {
        guard canBuy(kind) else { return false }
        shards -= kind.price
        inventory[kind.rawValue] = count(kind) + 1
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
    }
}
