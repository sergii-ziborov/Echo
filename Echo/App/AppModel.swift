import SwiftUI

enum Screen: Equatable {
    case splash
    case home
    case worlds
    case daily
    case wiki
    case tutorial(thenPlay: PlayRequest?)
    case playing(PlayRequest)
    case settings
    case shop
}

struct PlayRequest: Equatable {
    var levelID: String
    var daily: Bool
    var difficultyCycle: Int = 0
}

@MainActor
@Observable
final class AppModel {
    var screen: Screen = .splash
    var progress = ProgressStore()
    let audio = SoundPlayer()

    var continueLevel: LevelDefinition {
        progress.continueLevel()
    }

    func appear() {
        audio.enabled = progress.soundEnabled
        applyLaunchArgs()
    }

    private func applyLaunchArgs() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-shot-splash") {
            screen = .splash
        } else if args.contains("-shot-home") {
            progress.markTutorialSeen()
            screen = .home
        } else if args.contains("-shot-worlds") {
            progress.markTutorialSeen()
            screen = .worlds
        } else if args.contains("-shot-shop") {
            progress.markTutorialSeen()
            screen = .shop
        } else if args.contains("-shot-wiki") {
            progress.markTutorialSeen()
            screen = .wiki
        } else if args.contains("-shot-settings") {
            progress.markTutorialSeen()
            screen = .settings
        } else if args.contains("-shot-rift") || args.contains("-shot-gravity") || args.contains("-shot-candy") {
            progress.markTutorialSeen()
            for hint in [EncounterHint.echo, .asteroid, .rift, .laser, .timeCrystal, .blackHole, .realityShift] {
                _ = progress.markHint(hint.rawValue)
            }
            let number = args.contains("-shot-candy") ? 70 : (args.contains("-shot-gravity") ? 56 : 49)
            screen = .playing(PlayRequest(levelID: LevelCatalog.level(number: number)?.id ?? LevelCatalog.prototype.id, daily: false))
        } else if args.contains("-shot-ricochet") {
            progress.markTutorialSeen()
            _ = progress.markHint(EncounterHint.asteroid.rawValue)
            _ = progress.markHint(EncounterHint.timeCrystal.rawValue)
            screen = .playing(PlayRequest(levelID: LevelCatalog.level(number: 33)?.id ?? LevelCatalog.prototype.id, daily: false))
        } else if args.contains("-shot-laser") {
            progress.markTutorialSeen()
            _ = progress.markHint(EncounterHint.asteroid.rawValue)
            _ = progress.markHint(EncounterHint.gate.rawValue)
            _ = progress.markHint(EncounterHint.laser.rawValue)
            _ = progress.markHint(EncounterHint.timeCrystal.rawValue)
            _ = progress.markHint(EncounterHint.rift.rawValue)
            _ = progress.markHint(EncounterHint.collision.rawValue)
            screen = .playing(PlayRequest(levelID: LevelCatalog.level(number: 36)?.id ?? LevelCatalog.prototype.id, daily: false))
        } else if args.contains("-shot-play") {
            progress.markTutorialSeen()
            _ = progress.markHint(EncounterHint.timeCrystal.rawValue)
            _ = progress.markHint(EncounterHint.asteroid.rawValue)
            screen = .playing(PlayRequest(levelID: LevelCatalog.level(number: 21)?.id ?? LevelCatalog.prototype.id, daily: false))
        }
    }

    func tapSplash() {
        audio.play(.tap)
        screen = .home
    }

    func playPrimary() {
        audio.play(.tap)
        let request = PlayRequest(levelID: continueLevel.id, daily: false, difficultyCycle: progress.difficultyCycle)
        if progress.hasSeenTutorial {
            screen = .playing(request)
        } else {
            screen = .tutorial(thenPlay: request)
        }
    }

    func openWorlds() {
        audio.play(.tap)
        screen = .worlds
    }

    func openDaily() {
        audio.play(.tap)
        screen = .daily
    }

    func openWiki() {
        audio.play(.tap)
        screen = .wiki
    }

    func openSettings() {
        audio.play(.tap)
        screen = .settings
    }

    func openShop() {
        audio.play(.tap)
        screen = .shop
    }

    func play(level: LevelDefinition, daily: Bool) {
        audio.play(.tap)
        guard progress.isUnlocked(level) || daily else { return }
        let request = PlayRequest(
            levelID: daily ? LevelCatalog.daily().id : level.id,
            daily: daily,
            difficultyCycle: daily ? 0 : progress.difficultyCycle
        )
        if progress.hasSeenTutorial {
            screen = .playing(request)
        } else {
            screen = .tutorial(thenPlay: request)
        }
    }

    func finishTutorial(then request: PlayRequest?) {
        progress.markTutorialSeen()
        audio.play(.tap)
        if let request {
            screen = .playing(request)
        } else {
            screen = .home
        }
    }

    func goHome() {
        _ = progress.advanceDifficultyIfComplete()
        screen = .home
    }

    func recordWin(levelID: String, result: SessionResult, daily: Bool) {
        if daily {
            let key = LevelCatalog.dayKey(Date())
            let firstClear = progress.lastDailyKey != key
            progress.recordWin(levelID: levelID, result: result, awardsShard: firstClear)
            if firstClear {
                progress.markDailyComplete(key)
            }
        } else {
            progress.recordWin(levelID: levelID, result: result, awardsShard: true)
        }
        audio.play(.win)
    }
}
