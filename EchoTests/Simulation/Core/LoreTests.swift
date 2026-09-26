import XCTest
@testable import Echo

/// The story has to hold for every map: each one names its place on the
/// Fold Road, and a region never changes its look halfway through.
@MainActor
final class LoreTests: XCTestCase {
    func testEveryCampaignMapHasItsOwnNameAndLog() throws {
        XCTAssertEqual(LevelLore.count, LevelCatalog.playable.count)
        let entries = try LevelCatalog.playable.map { level in
            try XCTUnwrap(LevelLore.entry(for: level.number), "Map \(level.number) has no lore")
        }
        for (level, entry) in zip(LevelCatalog.playable, entries) {
            XCTAssertFalse(entry.title.isEmpty, "Map \(level.number) has no name")
            XCTAssertFalse(entry.log.isEmpty, "Map \(level.number) has no log")
            XCTAssertEqual(level.title, entry.title)
            XCTAssertFalse(level.tip.isEmpty, "Map \(level.number) has no tip")
        }
        XCTAssertEqual(Set(entries.map(\.log)).count, entries.count, "Two maps share a log")
        XCTAssertNil(LevelLore.entry(for: 0))
        XCTAssertNil(LevelLore.entry(for: LevelLore.count + 1))
    }

    func testEachRegionKeepsOneLook() {
        for act in Act.allCases {
            let maps = LevelCatalog.playable.filter { act.range.contains($0.number) }
            XCTAssertEqual(maps.count, 7)
            for map in maps {
                XCTAssertEqual(map.region, act)
                XCTAssertEqual(map.theme, act.theme, "Map \(map.number) leaves the colours of \(act.region)")
                XCTAssertEqual(map.atmosphere, act.atmosphere, "Map \(map.number) leaves the air of \(act.region)")
            }
            XCTAssertFalse(act.intro.isEmpty)
            XCTAssertFalse(act.blurb.isEmpty)
        }
        XCTAssertEqual(Set(Act.allCases.map(\.region)).count, Act.allCases.count)
    }

    func testEveryRegionHasItsOwnLandmark() {
        let landmarks = Act.allCases.map(\.landmark)
        for left in landmarks.indices {
            for right in landmarks.indices where right > left {
                XCTAssertNotEqual(landmarks[left], landmarks[right], "Two regions share a sky")
            }
        }
    }

    func testLandmarkDrawsNearerAcrossARegion() throws {
        let first = try XCTUnwrap(LevelCatalog.level(number: 8))
        let last = try XCTUnwrap(LevelCatalog.level(number: 14))
        XCTAssertEqual(first.regionProgress, 0)
        XCTAssertEqual(last.regionProgress, 1)
    }

    func testDeepTimeBorrowsEveryRegion() {
        let levels = (1...Act.allCases.count).map { EndlessGenerator.level(EndlessKey(seed: 7, depth: $0)) }
        XCTAssertEqual(Set(levels.map(\.region)).count, Act.allCases.count)
        XCTAssertTrue(levels.allSatisfy { $0.theme == $0.region.theme })
    }

    func testDailyRiftKeepsTheLookOfItsStop() {
        let daily = LevelCatalog.daily()
        XCTAssertEqual(daily.theme, Act.containing(level: daily.number).theme)
        XCTAssertNotNil(LevelLore.entry(for: daily.number))
    }

    func testArrivalShowsOncePerRegion() throws {
        let level = try XCTUnwrap(LevelCatalog.level(number: 15))
        let request = PlayRequest(levelID: level.id, daily: false)
        let arrival = try XCTUnwrap(ArrivalCard.Arrival.first(for: request, level: level, seen: []))
        XCTAssertEqual(arrival.key, "region.\(Act.fracture.rawValue)")
        XCTAssertEqual(arrival.title, Act.fracture.region.uppercased())
        XCTAssertNil(ArrivalCard.Arrival.first(for: request, level: level, seen: [arrival.key]))
        XCTAssertNil(ArrivalCard.Arrival.first(for: PlayRequest(levelID: "daily", daily: true), level: level, seen: []))

        let dive = PlayRequest(levelID: "endless", daily: false, endless: EndlessKey(seed: 3, depth: 1))
        XCTAssertEqual(ArrivalCard.Arrival.first(for: dive, level: level, seen: [])?.key, "region.deep")
        XCTAssertEqual(Set(ArrivalCard.Arrival.allKeys).count, Act.allCases.count + 1)
    }

    func testStoryRecordsOpenAsRegionsAreCleared() {
        XCTAssertTrue(WikiSection.allCases.contains(.story))
        let name = "echo.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        let store = ProgressStore(defaults: defaults)

        let open = StoryRecord.allCases.filter { $0.isRecovered(in: store) }
        XCTAssertEqual(open, [.lighthouse], "A new save only holds the Lighthouse record")
        XCTAssertTrue(StoryRecord.allCases.filter(\.isEnding).allSatisfy { $0.region == nil })

        store.debugShowcase(cleared: Act.drift.range.upperBound)
        XCTAssertTrue(StoryRecord.gardens.isRecovered(in: store))
        XCTAssertFalse(StoryRecord.final.isRecovered(in: store))

        store.debugShowcase(cleared: LevelCatalog.playable.count)
        XCTAssertTrue(StoryRecord.allCases.allSatisfy { $0.isRecovered(in: store) })
    }
}
