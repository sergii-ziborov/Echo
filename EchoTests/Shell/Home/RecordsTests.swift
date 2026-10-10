import XCTest
import UIKit
@testable import Echo

/// The ratings are plain sums of what the player can see on the screen.
@MainActor
final class RecordsTests: XCTestCase {
    func testBothLeaderboardArtworksShipInTheApp() {
        for board in RecordsView.Board.allCases {
            let artwork = UIImage(named: board.artwork)
            XCTAssertNotNil(artwork, "Missing artwork for \(board.rawValue)")
            XCTAssertEqual(artwork?.size, CGSize(width: 1024, height: 1024))
        }
    }

    func testPhoneRatingCountsSealsDepthAndPasses() {
        let model = CoverageFixtures.model(rich: false)
        XCTAssertEqual(Ratings.total(Ratings.phone(model.progress)), 0)

        _ = model.recordWin(
            levelID: LevelCatalog.prototype.id,
            result: SessionResult(time: 12, moves: 8, stars: 3, sparks: 6, echoesFaced: 1),
            daily: false
        )
        let lines = Ratings.phone(model.progress)
        XCTAssertEqual(lines.first { $0.id == "records.line.seals" }?.count, 3)
        XCTAssertEqual(Ratings.total(lines), 3 * Ratings.sealPoints)
    }

    func testWatchRatingCountsRoomsAndSecondsUnderPar() {
        var wrist = WristProgress()
        XCTAssertEqual(Ratings.total(Ratings.watch(wrist)), 0)

        let first = WristCatalog.maps[0]
        let second = WristCatalog.maps[1]
        wrist.record(clear: first.id, time: first.parTime - 4.6)
        wrist.record(clear: second.id, time: second.parTime + 3)
        XCTAssertEqual(Ratings.secondsUnderPar(wrist), 4, "Only whole seconds under par count, and a slow clear adds nothing")
        XCTAssertEqual(Ratings.total(Ratings.watch(wrist)), 2 * Ratings.roomPoints + 4 * Ratings.parSecondPoints)

        wrist.record(clear: second.id, time: second.parTime - 1)
        XCTAssertEqual(Ratings.secondsUnderPar(wrist), 5, "A better time only raises the rating")
    }

    func testAchievementsFollowTheSavedRecords() {
        XCTAssertLessThanOrEqual(Achievement.allCases.reduce(0) { $0 + $1.points }, 1000, "Game Center allows 1000 points per game")
        XCTAssertEqual(Set(Achievement.allCases.map(\.rawValue)).count, Achievement.allCases.count)

        let fresh = CoverageFixtures.model(rich: false).progress
        XCTAssertTrue(Achievement.allCases.allSatisfy { $0.percent(fresh) == 0 })

        let model = CoverageFixtures.model(rich: false)
        model.progress.debugShowcase(cleared: Act.trace.range.upperBound)
        XCTAssertEqual(Achievement.firstLight.percent(model.progress), 100)
        XCTAssertEqual(Achievement.lighthouse.percent(model.progress), 100)
        XCTAssertLessThan(Achievement.lastDawn.percent(model.progress), 100)

        for room in WristCatalog.maps.prefix(12) {
            model.progress.wrist.record(clear: room.id, time: room.parTime - 1)
        }
        XCTAssertEqual(Achievement.calibrated.percent(model.progress), 100)
        XCTAssertEqual(Achievement.regulated.percent(model.progress), 0)
        XCTAssertEqual(Achievement.aheadOfTime.percent(model.progress), 100)
        XCTAssertEqual(Achievement.certified.percent(model.progress), 33)
    }

    func testRatingsScreensRender() {
        let model = CoverageFixtures.model()
        model.progress.wrist.record(clear: WristCatalog.maps[0].id, time: 10)
        CoverageHost.render(RecordsView(board: .phone).environment(model))
        CoverageHost.render(RecordsView(board: .watch).environment(model))
        CoverageHost.render(RecordsView(board: .watch).environment(CoverageFixtures.model(rich: false)))
        CoverageHost.render(RecordsCard().environment(model))
    }
}
