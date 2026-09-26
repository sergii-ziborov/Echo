import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
#if DEBUG
    static var testLaunchArguments: [String] = []
#endif

    var shotArguments: [String] {
#if DEBUG
        if !Self.testLaunchArguments.isEmpty { return Self.testLaunchArguments }
#endif
        return ProcessInfo.processInfo.arguments
    }

#if DEBUG
    /// The map the pause and results screenshots name, in the app's language.
    static var shotLevelTitle: String { LevelCatalog.level(number: 27)?.title ?? "" }
#endif

    var body: some View {
        ZStack {
#if DEBUG
            if shotArguments.contains("-shot-pause") {
                ScreenBackground()
                PauseView(levelName: Self.shotLevelTitle, rewindCharges: 2, onResume: {}, onRestart: {}, onShop: {}, onSettings: {}, onMenu: {})
            } else if shotArguments.contains("-shot-death") {
                ScreenBackground()
                DeathView(cause: .asteroid, rewindCharges: 2, onRewind: {}, onRestart: {}, onMenu: {})
            } else if shotArguments.contains("-shot-results") {
                ScreenBackground()
                ResultsView(
                    levelName: Self.shotLevelTitle,
                    result: SessionResult(time: 43.28, moves: 18, stars: 2, sparks: 6, echoesFaced: 4, timeCrystals: 2, resonance: 3, scars: 1, closest: 0.14, control: true, paradox: false),
                    controlSeal: .maxEchoes(4),
                    paradoxSeal: .parTime,
                    bestTime: 41.62,
                    bestMoves: 15,
                    cycleComplete: false,
                    nextDifficulty: DifficultyProfile(cycle: 1),
                    awardedPoints: 180,
                    onWatch: {},
                    onRetry: {},
                    onNext: {},
                    onMenu: {}
                )
            } else {
                screenContent
            }
#else
            screenContent
#endif
        }
        .animation(.easeInOut(duration: 0.28), value: screenKey)
        .onAppear { model.appear() }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch model.screen {
        case .splash:
            SplashView()
        case .home:
            HomeView()
        case .worlds:
            WorldsView()
        case .daily:
            DailyChallengeView()
        case .wiki:
            WikiView()
        case .tutorial(let thenPlay):
            TutorialView {
                model.finishTutorial(then: thenPlay)
            }
        case .playing(let request):
            GameView(request: request)
                .id(request.levelID + (request.daily ? "-daily" : ""))
        case .settings:
            SettingsView()
        case .shop:
            ShopView()
        case .records:
            RecordsView()
        }
    }

    private var screenKey: String {
        switch model.screen {
        case .splash: "splash"
        case .home: "home"
        case .worlds: "worlds"
        case .daily: "daily"
        case .wiki: "wiki"
        case .tutorial: "tutorial"
        case .playing(let r): "play-\(r.levelID)"
        case .settings: "settings"
        case .shop: "shop"
        case .records: "records"
        }
    }
}
