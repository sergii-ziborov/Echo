import XCTest
@testable import Echo

@MainActor
final class AtlasCoverageTests: XCTestCase {
    func testAtlasFitsIPadPortraitLandscapeAndNarrowWindow() {
        let portrait = CGSize(width: 1032, height: 1376)
        let landscape = CGSize(width: 1376, height: 1032)
        let smallerPad = CGSize(width: 834, height: 1194)
        let narrow = CGSize(width: 650, height: 900)

        XCTAssertTrue(AtlasLayout.usesTwoColumns(width: portrait.width))
        XCTAssertTrue(AtlasLayout.usesTwoColumns(width: landscape.width))
        XCTAssertFalse(AtlasLayout.usesTwoColumns(width: smallerPad.width))
        XCTAssertEqual(AtlasLayout.contentWidth(for: smallerPad.width), 800)
        XCTAssertFalse(AtlasLayout.usesTwoColumns(width: narrow.width))

        for size in [portrait, landscape] {
            let contentWidth = AtlasLayout.contentWidth(for: size.width)
            let inspectorWidth = min(360, contentWidth * 0.37)
            let routeWidth = contentWidth - inspectorWidth - 18
            let map = CGSize(width: routeWidth - 26, height: AtlasLayout.routeHeight(for: size.height))
            XCTAssertGreaterThan(map.width, 480)
            for act in Act.allCases {
                let stops = AtlasRouteLayout.points(for: act, in: map)
                XCTAssertEqual(stops.count, 7)
                XCTAssertTrue(stops.allSatisfy {
                    $0.x > 50 && $0.x < map.width - 50 && $0.y > 50 && $0.y < map.height - 50
                })
            }
        }

        let model = CoverageFixtures.model()
        for size in [portrait, landscape, smallerPad, narrow] {
            let view = CoverageHost.render(WorldsView(act: .debris, levelNumber: 28).environment(model), size: size)
            XCTAssertEqual(view.bounds.size, size)
        }
    }

    func testEveryActAndLockedAtlas() {
        let rich = CoverageFixtures.model()
        for act in Act.allCases {
            let level = LevelCatalog.level(number: act.range.lowerBound) ?? LevelCatalog.prototype
            CoverageHost.render(
                WorldsView(act: act, levelNumber: level.number, appeared: true)
                    .environment(rich)
            )
        }

        let locked = CoverageFixtures.model(rich: false)
        CoverageHost.render(WorldsView(act: .eternity, levelNumber: 77, appeared: false).environment(locked))
        CoverageHost.render(CoverageFixtures.rooted(.worlds, model: locked))
    }
}
