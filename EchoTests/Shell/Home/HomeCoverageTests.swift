import XCTest
@testable import Echo

@MainActor
final class HomeCoverageTests: XCTestCase {
    func testRootScreensRender() {
        let model = CoverageFixtures.model()
        model.appear()
        model.tapSplash()
        model.openWorlds()
        model.openDaily()
        model.openWiki()
        model.openSettings()
        model.openShop()
        model.openRecords()
        model.goHome()
        model.playPrimary()
        model.finishTutorial(then: nil)
        model.play(level: LevelCatalog.prototype, daily: false)
        model.play(level: LevelCatalog.prototype, daily: true)
        _ = model.recordWin(
            levelID: LevelCatalog.prototype.id,
            result: SessionResult(time: 12, moves: 8, stars: 2, sparks: 6, echoesFaced: 1),
            daily: false
        )
        _ = model.recordWin(
            levelID: LevelCatalog.daily().id,
            result: SessionResult(time: 12, moves: 8, stars: 2, sparks: 6, echoesFaced: 1),
            daily: true,
            dayKey: "coverage-day"
        )
        model.startNextCycle()

        for screen in [
            Screen.splash, .home, .worlds, .daily, .wiki, .settings, .shop, .records,
            .tutorial(thenPlay: nil),
            .tutorial(thenPlay: CoverageFixtures.playRequest(1)),
            .playing(CoverageFixtures.playRequest(1)),
            .playing(CoverageFixtures.playRequest(21, daily: true)),
        ] {
            CoverageHost.render(CoverageFixtures.rooted(screen, model: model))
        }
        XCTAssertEqual(model.continueLevel.number, LevelCatalog.prototype.number)
    }

    func testHomeAndSplashVariants() {
        let rich = CoverageFixtures.model()
        CoverageHost.render(HomeView().environment(rich))
        CoverageHost.render(SplashView().environment(rich))

        let fresh = CoverageFixtures.model(rich: false)
        fresh.progress.hasSeenTutorial = false
        CoverageHost.render(HomeView().environment(fresh))
        CoverageHost.render(SplashView().environment(fresh))

        for flag in ["-shot-pause", "-shot-death", "-shot-results"] {
            RootView.testLaunchArguments = [flag]
            CoverageHost.render(RootView().environment(rich))
        }
        RootView.testLaunchArguments = []
    }

    func testHomeUsesTabletDashboardAtIPadSizes() {
        let model = CoverageFixtures.model()
        for size in [
            CGSize(width: 1032, height: 1376),
            CGSize(width: 1376, height: 1032),
            CGSize(width: 834, height: 1194),
        ] {
            let view = CoverageHost.render(HomeView().environment(model), size: size)
            XCTAssertEqual(view.bounds.size, size)
        }
        for size in [CGSize(width: 744, height: 1133), CGSize(width: 650, height: 900)] {
            XCTAssertEqual(CoverageHost.render(HomeView().environment(model), size: size).bounds.size, size)
        }
    }
}
