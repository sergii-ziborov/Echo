import XCTest
@testable import Echo

@MainActor
final class SessionCoverageTests: XCTestCase {
    func testSettingsLegalAndReset() {
        let model = CoverageFixtures.model()
        CoverageHost.render(SettingsView().environment(model))
        CoverageHost.render(SettingsView(showingResetConfirmation: true).environment(model))
        for document in LegalDocument.allCases {
            CoverageHost.render(SettingsView(legalDocument: document).environment(model))
            CoverageHost.render(LegalPageView(document: document, onBack: {}))
            XCTAssertFalse(document.paragraphs.isEmpty)
        }
        _ = LegalDocument.shortVersion
        _ = LegalDocument.buildNumber
    }

    func testTutorialDailyAndPause() {
        let model = CoverageFixtures.model()
        for step in 0..<4 {
            CoverageHost.render(TutorialView(stepIndex: step, onDone: {}).environment(model))
        }
        CoverageHost.render(DailyChallengeView().environment(model))
        CoverageHost.render(
            PauseView(
                levelName: "Trace",
                rewindCharges: 2,
                onResume: {},
                onRestart: {},
                onShop: {},
                onSettings: {},
                onMenu: {}
            )
        )
        CoverageHost.render(
            PauseView(
                levelName: "Trace",
                rewindCharges: 0,
                onResume: {},
                onRestart: {},
                onShop: {},
                onSettings: {},
                onMenu: {},
                place: "The Lighthouse · Lamp Deck",
                log: LevelLore.entry(for: 1)?.log
            )
        )
        let level = LevelCatalog.playable[21]
        if let arrival = ArrivalCard.Arrival.first(for: PlayRequest(levelID: level.id, daily: false), level: level, seen: []) {
            CoverageHost.render(ArrivalCard(arrival: arrival, onEnter: {}))
        }
    }
}
