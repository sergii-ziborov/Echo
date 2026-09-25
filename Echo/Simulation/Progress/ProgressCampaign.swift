import Foundation

extension ProgressStore {
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
            dailyKey, hintsKey, upgradesKey, equippedKey, difficultyKey, completedDifficultyKey, endlessKey,
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
        endless = EndlessRecord()
        sanitizeEquippedSkills()
        persist()
    }


#if DEBUG
    /// Screenshot aid: the first `count` maps cleared with a believable mix
    /// of seals and best times, and some research points to spend.
    func debugShowcase(cleared count: Int) {
        for (index, level) in LevelCatalog.playable.prefix(count).enumerated() {
            let stars = [3, 3, 2, 3, 1, 3, 2][index % 7]
            starsByLevel[progressKey(for: level.id)] = LevelProgress(
                stars: stars,
                bestTime: level.parTime * (0.8 + Double(index % 5) * 0.05),
                bestMoves: level.parMoves
            )
        }
        shards = max(shards, 640)
        persist()
    }
#endif
}
