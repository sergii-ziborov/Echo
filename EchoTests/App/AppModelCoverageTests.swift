import XCTest
@testable import Echo

@MainActor
final class AppModelCoverageTests: XCTestCase {
    func testNavigationAndAwards() {
        let fresh = CoverageFixtures.model(rich: false)
        fresh.progress.hasSeenTutorial = false
        XCTAssertEqual(fresh.continueLevel.number, LevelCatalog.prototype.number)
        fresh.appear()
        fresh.tapSplash()
        fresh.playPrimary()
        XCTAssertEqual(fresh.screen, .tutorial(thenPlay: PlayRequest(
            levelID: LevelCatalog.prototype.id,
            daily: false
        )))
        fresh.finishTutorial(then: nil)
        XCTAssertEqual(fresh.screen, .home)
        fresh.playPrimary()
        if case .playing = fresh.screen {
            XCTAssertTrue(true)
        } else {
            XCTFail("expected playing after tutorial")
        }

        let rich = CoverageFixtures.model()
        rich.openWorlds()
        rich.openDaily()
        rich.openWiki()
        rich.openSettings()
        rich.openShop()
        rich.goHome()
        rich.play(level: LevelCatalog.prototype, daily: false)
        rich.play(level: LevelCatalog.prototype, daily: true)
        _ = rich.recordWin(
            levelID: LevelCatalog.prototype.id,
            result: SessionResult(time: 11, moves: 7, stars: 3, sparks: 6, echoesFaced: 1),
            daily: false
        )
        _ = rich.recordWin(
            levelID: LevelCatalog.daily().id,
            result: SessionResult(time: 11, moves: 7, stars: 3, sparks: 6, echoesFaced: 1),
            daily: true,
            dayKey: "coverage-repeat"
        )
        _ = rich.recordWin(
            levelID: LevelCatalog.daily().id,
            result: SessionResult(time: 11, moves: 7, stars: 3, sparks: 6, echoesFaced: 1),
            daily: true,
            dayKey: "coverage-repeat"
        )
        rich.startNextCycle()
        XCTAssertGreaterThanOrEqual(rich.progress.difficultyCycle, 1)

        let shots = [
            "-shot-splash", "-shot-tutorial", "-shot-home", "-shot-worlds", "-shot-daily",
            "-shot-shop", "-shot-research", "-shot-wiki", "-shot-settings",
            "-shot-vfx-freeze", "-shot-rift", "-shot-gravity", "-shot-candy",
            "-shot-fracture", "-shot-asteroid-core", "-shot-ricochet", "-shot-laser", "-shot-play",
        ]
        for flag in shots {
            let model = CoverageFixtures.model(rich: false)
            model.applyLaunchArgs([flag])
            _ = model.screen
        }
    }
}
