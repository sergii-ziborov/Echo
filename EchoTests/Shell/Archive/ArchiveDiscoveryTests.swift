import XCTest
import SwiftUI
import UIKit
@testable import Echo

@MainActor
final class ArchiveDiscoveryTests: XCTestCase {
    private func store() -> ProgressStore {
        let suite = "echo.archive.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return ProgressStore(defaults: defaults)
    }

    private var win: SessionResult { SessionResult(time: 10, moves: 10, stars: 1, sparks: 6, echoesFaced: 1, bonuses: 0) }

    func testFirstRouteRecoversOnlyItsRegionAndReadAcknowledgementSurvivesReload() throws {
        let progress = store()
        XCTAssertTrue(progress.pendingArchiveDiscoveries.isEmpty)
        progress.recordWin(levelID: LevelCatalog.prototype.id, result: win)
        XCTAssertEqual(progress.pendingArchiveDiscoveries.map(\.id), ["region.trace"])
        XCTAssertFalse(try XCTUnwrap(ArchiveDiscovery.item("wiki.story.break")).requirement.met(in: progress))
        progress.acknowledgeArchiveDiscoveries(progress.pendingArchiveDiscoveries)
        progress.recordWin(levelID: LevelCatalog.prototype.id, result: win)
        XCTAssertTrue(progress.pendingArchiveDiscoveries.isEmpty)
        XCTAssertTrue(ProgressStore(defaults: progress.defaults).pendingArchiveDiscoveries.isEmpty)
    }

    func testRegionRequiresEveryMapAndEndingStaysSealedUntilCampaignComplete() throws {
        let progress = store()
        for level in LevelCatalog.playable.prefix(6) { progress.recordWin(levelID: level.id, result: win) }
        XCTAssertFalse(try XCTUnwrap(ArchiveDiscovery.item("wiki.story.philosophy")).requirement.met(in: progress))
        progress.recordWin(levelID: LevelCatalog.level(number: 7)!.id, result: win)
        XCTAssertTrue(try XCTUnwrap(ArchiveDiscovery.item("wiki.story.philosophy")).requirement.met(in: progress))
        XCTAssertTrue(try XCTUnwrap(ArchiveDiscovery.item("wiki.story.science")).requirement.met(in: progress))
        XCTAssertFalse(try XCTUnwrap(ArchiveDiscovery.item("story.final")).requirement.met(in: progress))
        for level in LevelCatalog.playable { progress.recordWin(levelID: level.id, result: win) }
        XCTAssertTrue(try XCTUnwrap(ArchiveDiscovery.item("story.final")).requirement.met(in: progress))
        progress.acknowledgeArchiveDiscoveries(progress.pendingArchiveDiscoveries)
        XCTAssertTrue(progress.advanceDifficultyIfComplete())
        XCTAssertTrue(progress.pendingArchiveDiscoveries.isEmpty)
        XCTAssertTrue(try XCTUnwrap(ArchiveDiscovery.item("region.eternity")).requirement.met(in: progress))
    }

    func testEncounterNotesAreRecoveredBeforeAClearAndRemainPendingUntilAcknowledged() throws {
        let progress = store()
        XCTAssertFalse(try XCTUnwrap(ArchiveDiscovery.item("wiki.hazard.beams")).requirement.met(in: progress))
        progress.markHint("laser")
        XCTAssertEqual(progress.pendingArchiveDiscoveries.map(\.id), ["wiki.hazard.beams"])
        let reloaded = ProgressStore(defaults: progress.defaults)
        XCTAssertEqual(reloaded.pendingArchiveDiscoveries.map(\.id), ["wiki.hazard.beams"])
        reloaded.acknowledgeArchiveDiscoveries(reloaded.pendingArchiveDiscoveries)
        reloaded.markHint("laser")
        XCTAssertTrue(reloaded.pendingArchiveDiscoveries.isEmpty)
        XCTAssertFalse(try XCTUnwrap(ArchiveDiscovery.item("wiki.hazard.ghost")).requirement.met(in: reloaded))
        reloaded.markHint("archive.rewind")
        XCTAssertTrue(try XCTUnwrap(ArchiveDiscovery.item("wiki.hazard.ghost")).requirement.met(in: reloaded))
    }

    func testExistingSavesDoNotShowHistoricalNotificationsAndResetStartsTheCollectionAgain() {
        let progress = store()
        progress.markHint("asteroid")
        progress.recordWin(levelID: LevelCatalog.prototype.id, result: win)
        progress.defaults.removeObject(forKey: progress.archiveAnnouncementsKey)
        let upgraded = ProgressStore(defaults: progress.defaults)
        XCTAssertTrue(upgraded.pendingArchiveDiscoveries.isEmpty)
        XCTAssertTrue(ArchiveDiscovery.availableIDs(in: upgraded).contains("wiki.hazard.materials"))
        upgraded.resetProgress()
        XCTAssertFalse(ArchiveDiscovery.availableIDs(in: upgraded).contains("wiki.hazard.materials"))
        upgraded.recordWin(levelID: LevelCatalog.prototype.id, result: win)
        XCTAssertEqual(upgraded.pendingArchiveDiscoveries.map(\.id), ["region.trace"])
    }

    func testCatalogHasUniqueStableIDsAndUsefulRequirementsInBothLanguages() {
        let preference = LanguagePreference.shared
        let previous = preference.selection
        defer { preference.selection = previous }
        let catalog = ArchiveDiscovery.catalog
        XCTAssertEqual(Set(catalog.map(\.id)).count, catalog.count)
        for language in [AppLanguage.english, .russian] {
            preference.selection = language
            for item in catalog {
                XCTAssertTrue(Copy.has(item.titleKey), item.id)
                XCTAssertFalse(item.excerpt.isEmpty, item.id)
                XCTAssertFalse(item.excerpt.hasSuffix(".body"), item.id)
                XCTAssertFalse(item.excerpt.hasSuffix(".arrival"), item.id)
                XCTAssertFalse(item.excerpt.hasSuffix(".text"), item.id)
                XCTAssertFalse(item.requirement.instruction.isEmpty, item.id)
                XCTAssertFalse(item.requirement.recoveryReason.isEmpty, item.id)
            }
        }
    }

    func testReadingAFindOpensTheRightArchiveSectionAndPreservesProgress() throws {
        let model = CoverageFixtures.model(rich: false)
        model.progress.markHint("laser")
        let find = try XCTUnwrap(ArchiveDiscovery.item("wiki.hazard.beams"))
        model.readDiscovery(find)
        XCTAssertEqual(model.screen, .wiki)
        XCTAssertEqual(model.archiveFocus?.id, find.id)
        XCTAssertEqual(model.archiveFocus?.section, .threats)
        XCTAssertTrue(model.progress.pendingArchiveDiscoveries.isEmpty)
    }

    func testRecoveryAndLanguageSettingsAcrossPhoneDuoAndPad() {
        let previous = LanguagePreference.shared.selection
        defer {
            CoverageHost.teardown()
            LanguagePreference.shared.selection = previous
        }
        let model = CoverageFixtures.model(rich: false)
        let finds = ["wiki.story.break", "wiki.story.philosophy", "wiki.story.science"].compactMap(ArchiveDiscovery.item)
        let sizes = [
            ("phone", CGSize(width: 390, height: 844)),
            ("duo-outer", CGSize(width: 466, height: 678)),
            ("duo-inner", CGSize(width: 669, height: 951)),
            ("ipad", CGSize(width: 1032, height: 1376)),
        ]
        for language in [AppLanguage.english, .russian] {
            LanguagePreference.shared.selection = language
            for (name, size) in sizes {
                attach(CoverageHost.render(
                    ZStack {
                        ScreenBackground()
                        ArchiveRecoveryView(finds: finds, onRead: { _ in }, onContinue: {})
                    }, size: size
                ), name: "archive-\(language.rawValue)-\(name)")
                attach(CoverageHost.render(SettingsView().environment(model), size: size), name: "language-\(language.rawValue)-\(name)")
            }
        }
    }

    private func attach(_ view: UIView, name: String) {
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { _ in
            XCTAssertTrue(view.drawHierarchy(in: view.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

}
