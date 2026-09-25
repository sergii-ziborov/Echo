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
    /// Set for a Deep Time depth instead of a campaign or daily map.
    var endless: EndlessKey?
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
        PhoneWatchLink.shared.onProgress = { [weak self] incoming in
            self?.progress.mergeWrist(incoming)
        }
        PhoneWatchLink.shared.activate()
        audio.enabled = progress.soundEnabled
        audio.setMasterVolume(progress.soundVolume)
        audio.setHapticsEnabled(progress.hapticsEnabled)
        applyLaunchArgs(ProcessInfo.processInfo.arguments)
    }

    func applyLaunchArgs(_ args: [String]) {
        if args.contains("-shot-splash") {
            screen = .splash
        } else if args.contains("-shot-tutorial") {
            screen = .tutorial(thenPlay: nil)
        } else if args.contains("-shot-home") {
            progress.markTutorialSeen()
            screen = .home
        } else if args.contains("-shot-worlds") {
            progress.markTutorialSeen()
            screen = .worlds
        } else if args.contains("-shot-daily") {
            progress.markTutorialSeen()
            screen = .daily
        } else if args.contains("-shot-shop")
            || args.contains("-shot-research")
            || args.contains("-shot-research-loadout")
            || args.contains("-shot-research-time")
            || args.contains("-shot-research-detail")
            || args.contains("-shot-tech-surge")
            || args.contains("-shot-tech-magnet")
            || args.contains("-shot-tech-loadout")
            || args.contains("-shot-tech-temporal")
            || args.contains("-shot-ability") {
            progress.markTutorialSeen()
            screen = .shop
        } else if args.contains("-shot-wiki") || args.contains("-shot-wiki-research") {
            progress.markTutorialSeen()
            screen = .wiki
        } else if args.contains("-shot-settings") {
            progress.markTutorialSeen()
            screen = .settings
        } else if args.contains("-shot-vfx-freeze")
            || args.contains("-shot-vfx-surge")
            || args.contains("-shot-vfx-shield") {
            progress.markTutorialSeen()
            for hint in [
                EncounterHint.echo, .asteroid, .rift, .freeze, .phase, .collision, .gate,
                .laser, .timeCrystal, .resonance, .blackHole, .realityShift, .surge,
                .pulse, .magnet, .chrono, .anchor, .repulse, .prism, .blink,
            ] {
                _ = progress.markHint(hint.rawValue)
            }
            screen = .playing(PlayRequest(levelID: LevelCatalog.level(number: 21)?.id ?? LevelCatalog.prototype.id, daily: false))
        } else if args.contains("-shot-rift") || args.contains("-shot-gravity") || args.contains("-shot-candy") || args.contains("-shot-fracture") || args.contains("-shot-asteroid-core") {
            progress.markTutorialSeen()
            for hint in [EncounterHint.echo, .asteroid, .rift, .laser, .timeCrystal, .blackHole, .realityShift] {
                _ = progress.markHint(hint.rawValue)
            }
            let number = args.contains("-shot-asteroid-core")
                ? 40
                : (args.contains("-shot-fracture")
                    ? 33
                    : (args.contains("-shot-candy") ? 70 : (args.contains("-shot-gravity") ? 56 : 49)))
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
        } else if args.contains("-shot-endless") || args.contains("-shot-endless-deep") {
            progress.markTutorialSeen()
            for hint in [
                EncounterHint.echo, .asteroid, .rift, .freeze, .phase, .collision, .gate,
                .laser, .timeCrystal, .resonance, .blackHole, .realityShift, .surge,
                .pulse, .magnet, .chrono, .anchor, .repulse, .prism, .blink,
            ] {
                _ = progress.markHint(hint.rawValue)
            }
            let key = EndlessKey(seed: 0xEC40_D17E, depth: args.contains("-shot-endless-deep") ? 14 : 1)
            screen = .playing(PlayRequest(levelID: key.levelID, daily: false, endless: key))
        } else if args.contains("-shot-play") {
            progress.markTutorialSeen()
            _ = progress.markHint(EncounterHint.timeCrystal.rawValue)
            _ = progress.markHint(EncounterHint.asteroid.rawValue)
            screen = .playing(PlayRequest(levelID: LevelCatalog.level(number: 21)?.id ?? LevelCatalog.prototype.id, daily: false))
        }
    }

    func tapSplash() {
        audio.play(.confirm)
        screen = .home
    }

    func playPrimary() {
        audio.play(.confirm)
        let request = PlayRequest(levelID: continueLevel.id, daily: false, difficultyCycle: progress.difficultyCycle)
        if progress.hasSeenTutorial {
            screen = .playing(request)
        } else {
            screen = .tutorial(thenPlay: request)
        }
    }

    func openWorlds() {
        audio.play(.select)
        screen = .worlds
    }

    func openDaily() {
        audio.play(.select)
        screen = .daily
    }

    func openWiki() {
        audio.play(.select)
        screen = .wiki
    }

    func openSettings() {
        audio.play(.select)
        screen = .settings
    }

    func openShop() {
        audio.play(.select)
        screen = .shop
    }

    func play(level: LevelDefinition, daily: Bool) {
        guard progress.isUnlocked(level) || daily else { return }
        audio.play(.confirm)
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
        audio.play(request == nil ? .tap : .confirm)
        if let request {
            screen = .playing(request)
        } else {
            screen = .home
        }
    }

    func goHome() {
        screen = .home
    }

    /// Opens Deep Time: a fresh run, or the one waiting at its next depth.
    func playEndless(resume: Bool = false) {
        audio.play(.confirm)
        let key = resume ? (progress.endless.current ?? progress.startEndlessRun()) : progress.startEndlessRun()
        play(endless: key)
    }

    func play(endless key: EndlessKey) {
        let request = PlayRequest(levelID: key.levelID, daily: false, difficultyCycle: 0, endless: key)
        if progress.hasSeenTutorial {
            screen = .playing(request)
        } else {
            screen = .tutorial(thenPlay: request)
        }
    }

    func recordEndlessWin(_ key: EndlessKey, result: SessionResult) -> Int {
        let awarded = progress.recordEndlessClear(key, result: result)
        audio.play(.win)
        return awarded
    }

    func startNextCycle() {
        guard progress.advanceDifficultyIfComplete() else { return }
        play(level: LevelCatalog.prototype, daily: false)
    }

    func recordWin(levelID: String, result: SessionResult, daily: Bool, dayKey: String? = nil) -> Int {
        let awarded: Int
        if daily {
            let key = dayKey ?? LevelCatalog.dayKey(Date())
            let firstClear = progress.lastDailyKey != key
            awarded = firstClear ? result.points : 0
            progress.recordWin(levelID: levelID, result: result, awardsShard: firstClear)
            if firstClear {
                progress.markDailyComplete(key)
            }
        } else {
            awarded = result.points
            progress.recordWin(levelID: levelID, result: result, awardsShard: true)
        }
        audio.play(.win)
        return awarded
    }
}
