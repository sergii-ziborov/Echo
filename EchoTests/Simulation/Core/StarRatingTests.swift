import XCTest
@testable import Echo

final class StarRatingTests: XCTestCase {
    func testParGivesThreeStars() {
        XCTAssertEqual(StarRating.stars(time: 20, moves: 30, parTime: 22, parMoves: 38), 3)
    }

    func testPointsScaleWithStarsAndBonuses() {
        XCTAssertEqual(StarRating.points(stars: 3, bonuses: 2), 200)
        XCTAssertEqual(StarRating.points(stars: 1, bonuses: 0), 60)
        let result = SessionResult(time: 12, moves: 20, stars: 2, sparks: 6, echoesFaced: 1, bonuses: 1)
        XCTAssertEqual(result.points, 130)
        let chained = SessionResult(time: 12, moves: 20, stars: 2, sparks: 6, echoesFaced: 1, bonuses: 1, resonance: 4)
        XCTAssertEqual(chained.points, 160)
    }

    func testSlowRunGivesOneStar() {
        XCTAssertEqual(StarRating.stars(time: 80, moves: 200, parTime: 22, parMoves: 38), 1)
    }

    func testNearParGivesTwoStars() {
        XCTAssertEqual(StarRating.stars(time: 28, moves: 60, parTime: 22, parMoves: 38), 2)
    }
}
