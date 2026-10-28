import SwiftUI
import Vision
import XCTest
@testable import Echo

@MainActor
final class LoreAndRussianLayoutTests: XCTestCase {
    func testEveryRegionHasDistinctInterpretationAndTraceableSources() {
        let previous = LanguagePreference.shared.selection
        defer { LanguagePreference.shared.selection = previous }
        for language in [AppLanguage.english, .russian] {
            LanguagePreference.shared.selection = language
            for act in Act.allCases {
                XCTAssertGreaterThan(act.philosophyNote.count, 100)
                XCTAssertNotEqual(act.philosophyNote, act.scienceNote)
                let references = LoreReference.references(for: act)
                XCTAssertGreaterThanOrEqual(references.count, 2)
                XCTAssertEqual(Set(references.map(\.id)).count, references.count)
                XCTAssertTrue(references.allSatisfy { $0.url.scheme == "https" && $0.url.host != nil })
            }
            // Stable saved map identities remain independent of the rewritten text.
            XCTAssertEqual(Set(LevelCatalog.playable.map(\.id)), Set((1...77).map { "awakening-\($0)" }))
        }
    }

    func testAwakeningStaysAWholeWordWithLargeBalancesOnNarrowPhone() throws {
        let previous = LanguagePreference.shared.selection
        defer { LanguagePreference.shared.selection = previous; CoverageHost.teardown() }
        LanguagePreference.shared.selection = .russian
        let model = CoverageFixtures.model()
        model.progress.difficultyCycle = 0
        model.progress.addShards(9_000_000)
        for width in [320.0, 375.0, 393.0] {
            let view = CoverageHost.render(
                HomeTopBar(reduceMotion: true).environment(model)
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background(EchoTheme.navyDeep),
                size: CGSize(width: width, height: 180))
            let image = UIGraphicsImageRenderer(bounds: view.bounds, format: {
                let format = UIGraphicsImageRendererFormat(); format.scale = 3; return format
            }()).image { _ in view.drawHierarchy(in: view.bounds, afterScreenUpdates: true) }
            let attachment = XCTAttachment(image: image)
            attachment.name = "russian-header-large-balance-\(Int(width))"
            attachment.lifetime = .keepAlways; add(attachment)
            let request = VNRecognizeTextRequest()
            request.recognitionLanguages = ["ru-RU", "en-US"]
            request.recognitionLevel = .accurate
            try VNImageRequestHandler(cgImage: try XCTUnwrap(image.cgImage)).perform([request])
            let words = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
            XCTAssertTrue(words.contains { $0.uppercased().contains("ПРОБУЖДЕНИЕ") }, "Split or missing recovery title at \(width): \(words)")
        }
    }

    func testRussianNextRankLabelDoesNotSplitItsLastLetter() async throws {
        let previous = LanguagePreference.shared.selection
        defer { LanguagePreference.shared.selection = previous; CoverageHost.teardown() }
        LanguagePreference.shared.selection = .russian
        let model = CoverageFixtures.model(rich: false)
        model.progress.debugLabShowcase()
        let view = CoverageHost.render(
            ShopView(section: .research, researchBranch: .motion).environment(model),
            size: CGSize(width: 320, height: 852))
        try await Task.sleep(for: .milliseconds(450))
        let format = UIGraphicsImageRendererFormat(); format.scale = 3
        let image = UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "russian-next-rank-narrow-phone"
        attachment.lifetime = .keepAlways; add(attachment)
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["ru-RU"]
        request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: try XCTUnwrap(image.cgImage)).perform([request])
        let words = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
        for word in ["СЛЕДУЮЩИЙ", "КОНДЕНСАТОР", "КИНЕТИЧЕСКИЙ"] {
            XCTAssertTrue(words.contains { $0.uppercased().contains(word) }, "Split word \(word): \(words)")
        }
    }
}
