import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            switch model.screen {
            case .splash:
                SplashView()
            case .home:
                HomeView()
            case .worlds:
                WorldsView()
            case .daily:
                DailyChallengeView()
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
            }
        }
        .animation(.easeInOut(duration: 0.28), value: screenKey)
        .onAppear { model.appear() }
    }

    private var screenKey: String {
        switch model.screen {
        case .splash: "splash"
        case .home: "home"
        case .worlds: "worlds"
        case .daily: "daily"
        case .tutorial: "tutorial"
        case .playing(let r): "play-\(r.levelID)"
        case .settings: "settings"
        case .shop: "shop"
        }
    }
}
