import XCTest
@testable import Echo

@MainActor
final class AtlasCoverageTests: XCTestCase {
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
