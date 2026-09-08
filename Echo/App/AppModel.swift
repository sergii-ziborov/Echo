import SwiftUI

enum Screen: Equatable {
    case splash
    case home
    case worlds
    case daily
    case tutorial(thenPlay: PlayRequest?)
    case playing(PlayRequest)
    case settings
}

struct PlayRequest: Equatable {
    var levelID: String
    var daily: Bool
}

@MainActor
@Observable
final class AppModel {
    var screen: Screen = .splash
    var progress = ProgressStore()
    let audio = SoundPlayer()

    var continueLevel: LevelDefinition {
        LevelCatalog.level(id: progress.lastLevelID) ?? LevelCatalog.prototype
    }

    func appear() {
        audio.enabled = progress.soundEnabled
    }

    func tapSplash() {
        audio.play(.tap)
        screen = .home
    }

    func playPrimary() {
        audio.play(.tap)
        let request = PlayRequest(levelID: continueLevel.id, daily: false)
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

    func openSettings() {
        audio.play(.tap)
        screen = .settings
    }

    func play(level: LevelDefinition, daily: Bool) {
        audio.play(.tap)
        guard progress.isUnlocked(level) || daily else { return }
        let request = PlayRequest(levelID: daily ? LevelCatalog.daily().id : level.id, daily: daily)
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
        screen = .home
    }

    func recordWin(levelID: String, result: SessionResult, daily: Bool) {
        progress.recordWin(levelID: daily ? "daily" : levelID, result: result, awardsShard: true)
        if daily {
            progress.markDailyComplete(LevelCatalog.dayKey(Date()))
        }
        audio.play(.win)
    }
}
