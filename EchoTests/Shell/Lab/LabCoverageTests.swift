import XCTest
@testable import Echo

@MainActor
final class LabCoverageTests: XCTestCase {
    func testLoadoutAndResearchBranches() {
        let model = CoverageFixtures.model()
        CoverageHost.render(ShopView(section: .loadout, flash: "TEMPORAL FABRICATOR READY").environment(model))
        for branch in UpgradeBranch.allCases {
            CoverageHost.render(ShopView(section: .research, researchBranch: branch).environment(model))
        }
        CoverageHost.render(ShopView(onBack: {}, hostTopInset: 48, section: .loadout).environment(model))
    }

    func testInspectorsForEveryUpgradeAndSkill() {
        let model = CoverageFixtures.model()
        for kind in UpgradeKind.allCases {
            CoverageHost.render(
                ShopView(section: .research, researchBranch: kind.branch, inspectedUpgrade: kind)
                    .environment(model)
            )
        }
        for kind in BonusKind.allCases {
            CoverageHost.render(ShopView(section: .loadout, inspectedSkill: kind).environment(model))
        }
        _ = ShopView.screenshotUpgrade
        XCTAssertFalse(UpgradeKind.allCases.isEmpty)
    }

    func testResearchIconsAndEmptyLab() {
        let empty = CoverageFixtures.model(rich: false)
        CoverageHost.render(ShopView(section: .loadout).environment(empty))
        CoverageHost.render(ShopView(section: .research, researchBranch: .temporal).environment(empty))
        for kind in UpgradeKind.allCases {
            CoverageHost.render(ResearchIconView(kind: kind, size: 28))
        }
    }

    func testTreeRowsFollowEverySameBranchRequirement() {
        for branch in UpgradeBranch.allCases {
            let kinds = UpgradeKind.allCases.filter { $0.branch == branch }
            let layout = ResearchTreeLayout(kinds: kinds)
            for kind in kinds {
                for requirement in kind.prerequisites where requirement.kind.branch == branch {
                    XCTAssertLessThan(layout.depths[requirement.kind]!, layout.depths[kind]!)
                }
            }
            for row in Set(layout.depths.values) {
                let rowKinds = kinds.filter { layout.depths[$0] == row }
                XCTAssertLessThanOrEqual(rowKinds.count, 3)
                let centers = rowKinds.map { layout.point(for: $0, width: 320).x }.sorted()
                for pair in zip(centers, centers.dropFirst()) {
                    XCTAssertGreaterThanOrEqual(pair.1 - pair.0, 77)
                }
            }
        }
    }
}
