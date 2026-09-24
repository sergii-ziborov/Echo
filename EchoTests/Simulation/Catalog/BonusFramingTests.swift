import UIKit
import XCTest
@testable import Echo

@MainActor
final class BonusFramingTests: XCTestCase {
    /// Screens the game ships on, in points.
    private let screens: [(name: String, size: CGSize)] = [
        ("iPhone 13 mini", CGSize(width: 375, height: 812)),
        ("iPhone SE", CGSize(width: 375, height: 667)),
        ("iPhone Pro Max", CGSize(width: 440, height: 956)),
        ("iPad Pro 13", CGSize(width: 1032, height: 1376)),
    ]

    func testTokensUnderTheHUDOrItemBarMoveIntoClearView() {
        var issues: [String] = []
        for screen in screens {
            for level in LevelCatalog.playable {
                let fitted = level.fitted(aspect: Double(screen.size.height / screen.size.width))
                let bands = GameView.interfaceBands(for: fitted, screen: screen.size)
                let kept = fitted.keepingBonusesInView(bands)
                let visible = bands.bottom - 0.5...fitted.worldHeight - bands.top + 0.5
                for (before, after) in zip(fitted.bonuses, kept.bonuses) {
                    let label = "\(screen.name) · map \(level.number) \(after.kind)"
                    if visible.contains(before.position.y) {
                        if after.position != before.position { issues.append("\(label) moved although it was visible") }
                        continue
                    }
                    let p = after.position
                    if !visible.contains(p.y) { issues.append("\(label) is still under the interface") }
                    if !LayoutSafety.isClear(p, walls: kept.walls, clearance: bands.token - 1) { issues.append("\(label) touches a wall") }
                    if kept.sparks.contains(where: { $0.orbit == nil && $0.position.distance(to: p) < bands.token * 1.8 - 1 }) {
                        issues.append("\(label) crowds a spark")
                    }
                    if p.distance(to: kept.exit) < bands.token * 2 { issues.append("\(label) crowds the exit") }
                }
            }
        }
        XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
    }

    func testMiniScreenKeepsTheLateActAbilityTokensOutOfTheHUD() throws {
        let level = try XCTUnwrap(LevelCatalog.level(number: 40))
        let size = CGSize(width: 375, height: 812)
        let fitted = level.fitted(aspect: Double(size.height / size.width))
        let kept = fitted.keepingBonusesInView(GameView.interfaceBands(for: fitted, screen: size))
        let scale = Double(size.width) / fitted.worldWidth

        XCTAssertEqual(kept.bonuses.count, fitted.bonuses.count)
        for bonus in kept.bonuses {
            let fromTop = Double(size.height) - bonus.position.y * scale
            // Measured on a 13 mini: the chips and the status row end at
            // 137 pt and the item bar starts at 754 pt.
            XCTAssertGreaterThan(fromTop - 22, 137, "\(bonus.kind) token under the HUD")
            XCTAssertLessThan(fromTop + 22, 754, "\(bonus.kind) token over the item bar")
        }
    }
}
