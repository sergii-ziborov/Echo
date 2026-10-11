import SwiftUI
import UIKit
import XCTest
@testable import Echo

@MainActor
final class TutorialPracticeTests: XCTestCase {
    private func move(_ practice: TutorialPractice, to target: CGPoint) {
        practice.aim(at: target)
        for _ in 0..<160 {
            practice.tick(0.02)
            if hypot(practice.player.x - target.x, practice.player.y - target.y) < 0.015 { break }
        }
        practice.aim(at: nil)
    }

    func testPracticeWaitsForTouchAndStopsWhenReleased() {
        let practice = TutorialPractice()
        for _ in 0..<100 { practice.tick(0.02) }
        XCTAssertEqual(practice.player, TutorialPractice.start)
        XCTAssertEqual(practice.elapsed, 0)
        move(practice, to: TutorialPractice.sparks[0])
        let stopped = practice.player
        for _ in 0..<10 { practice.tick(0.02) }
        XCTAssertEqual(practice.player, stopped)
        XCTAssertTrue(practice.hasMoved)
        XCTAssertEqual(practice.collected, [0])
    }

    func testEchoReplaysTheEarlierRouteAndCollisionKeepsRecoveredSparks() throws {
        let practice = TutorialPractice()
        move(practice, to: TutorialPractice.sparks[0])
        let earlier = practice.trail[10]
        practice.aim(at: CGPoint(x: 0.9, y: 0.9))
        while practice.elapsed < earlier.time + TutorialPractice.delay { practice.tick(0.01) }
        let echo = try XCTUnwrap(practice.echo)
        XCTAssertLessThan(hypot(echo.x - earlier.point.x, echo.y - earlier.point.y), 0.01)
        XCTAssertGreaterThan(hypot(echo.x - practice.player.x, echo.y - practice.player.y), 0.1)
        XCTAssertTrue(practice.hasSeenEcho)
        practice.aim(at: nil)
        for _ in 0..<300 where practice.collisions == 0 { practice.tick(0.02) }
        XCTAssertEqual(practice.collisions, 1)
        XCTAssertEqual(practice.player, TutorialPractice.start)
        XCTAssertEqual(practice.collected, [0])
        XCTAssertNil(practice.target)
        XCTAssertFalse(practice.completed)
        for _ in 0..<200 { practice.tick(0.02) }
        XCTAssertEqual(practice.elapsed, 0, "A gentle reset waits for another touch")
        XCTAssertEqual(practice.collisions, 1)
    }

    func testExitRequiresEverySparkAndCompletedPracticeStaysStill() {
        let practice = TutorialPractice()
        move(practice, to: TutorialPractice.exit)
        XCTAssertFalse(practice.completed)
        XCTAssertFalse(practice.exitOpen)
        // A fresh route through all three sparks keeps ahead of its delayed echo.
        let ready = TutorialPractice()
        for spark in TutorialPractice.sparks { move(ready, to: spark) }
        XCTAssertTrue(ready.exitOpen)
        move(ready, to: TutorialPractice.exit)
        XCTAssertTrue(ready.completed)
        let final = ready.player
        ready.aim(at: TutorialPractice.start)
        ready.tick(0.05)
        XCTAssertNil(ready.target)
        XCTAssertEqual(ready.player, final)
    }

    func testSkippingPracticeIsRememberedAndDoesNotSpendCharges() throws {
        let model = CoverageFixtures.model(rich: false)
        model.progress.resetProgress()
        let charges = BonusKind.allCases.map { model.progress.count($0) }
        model.playPrimary()
        guard case .tutorial(let request) = model.screen else { return XCTFail("First route must offer practice") }
        let run = try XCTUnwrap(request)
        model.finishTutorial(then: run)
        XCTAssertTrue(model.progress.hasSeenTutorial)
        XCTAssertEqual(model.screen, .playing(run))
        XCTAssertEqual(charges, BonusKind.allCases.map { model.progress.count($0) })
        XCTAssertTrue(model.progress.pendingArchiveDiscoveries.isEmpty)
        XCTAssertTrue(ProgressStore(defaults: model.progress.defaults).hasSeenTutorial)
        model.goHome()
        model.playPrimary()
        XCTAssertEqual(model.screen, .playing(run))
    }

    func testPracticeAndResultFindsAcrossPhoneDuoAndPad() {
        let previous = LanguagePreference.shared.selection
        defer { LanguagePreference.shared.selection = previous; CoverageHost.teardown() }
        let result = SessionResult(time: 18, moves: 12, stars: 2, sparks: 6, echoesFaced: 1)
        let finds = ["region.trace", "wiki.story.philosophy"].compactMap(ArchiveDiscovery.item)
        let sizes = [("phone", CGSize(width: 390, height: 844)), ("duo-outer", CGSize(width: 466, height: 678)),
                     ("duo-inner", CGSize(width: 669, height: 951)), ("ipad-landscape", CGSize(width: 1376, height: 1032))]
        for language in [AppLanguage.english, .russian] {
            LanguagePreference.shared.selection = language
            for (name, size) in sizes {
                attach(CoverageHost.render(TutorialView(onDone: {}), size: size), name: "practice-\(language.rawValue)-\(name)")
                attach(CoverageHost.render(ResultsView(
                    levelName: LevelCatalog.prototype.title, result: result, controlSeal: .noShop, paradoxSeal: .noDash,
                    bestTime: 16, bestMoves: 10, cycleComplete: false, nextDifficulty: DifficultyProfile(cycle: 1),
                    awardedPoints: 90, onWatch: {}, onRetry: {}, onNext: {}, onMenu: {}, archiveFinds: finds, onArchive: {}
                ), size: size), name: "results-finds-\(language.rawValue)-\(name)")
            }
        }
    }

    private func attach(_ view: UIView, name: String) {
        let format = UIGraphicsImageRendererFormat(); format.scale = 2; format.opaque = true
        let image = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { _ in
            XCTAssertTrue(view.drawHierarchy(in: view.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
