import XCTest
import SwiftUI
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
                    if layout.depths[kind]! - layout.depths[requirement.kind]! > 1 {
                        let path = layout.path(from: requirement.kind, to: kind, width: 320)
                        let destination = layout.point(for: kind, width: 320)
                        if destination.x >= 160 {
                            XCTAssertEqual(path.boundingRect.maxX, 300, accuracy: 0.5)
                        } else {
                            XCTAssertEqual(path.boundingRect.minX, 20, accuracy: 0.5)
                        }
                    }
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

    func testDuoOuterAndInnerDisplayLayouts() {
        // Duo screenshots use 1398 × 2034 and 2007 × 2853 pixels at 3×.
        let outer = CGSize(width: 466, height: 678)
        let inner = CGSize(width: 669, height: 951)
        XCTAssertFalse(LabLayout.usesSidePanels(width: outer.width))
        XCTAssertTrue(LabLayout.usesSidePanels(width: inner.width))

        let model = CoverageFixtures.model(rich: false)
        model.progress.debugLabShowcase()
        for size in [outer, inner] {
            let loadout = CoverageHost.render(ShopView(section: .loadout).environment(model), size: size)
            XCTAssertEqual(loadout.bounds.size, size)
            attachScreenshot(loadout, name: size == outer ? "duo-outer-loadout" : "duo-inner-loadout")
            let research = CoverageHost.render(ShopView(section: .research).environment(model), size: size)
            XCTAssertEqual(research.bounds.size, size)
            attachScreenshot(research, name: size == outer ? "duo-outer-research" : "duo-inner-research")
        }
    }

    private func attachScreenshot(_ view: UIView, name: String) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
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
