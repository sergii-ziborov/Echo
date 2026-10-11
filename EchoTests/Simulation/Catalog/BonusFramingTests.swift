import UIKit
import SwiftUI
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

@MainActor
final class ArenaFramingTests: XCTestCase {
    func testEveryRouteFitsBetweenPanelsIncludingOrbitingSparksAndRemoteRecipes() throws {
        let screens: [CGSize] = [.init(width: 375, height: 667), .init(width: 390, height: 844), .init(width: 440, height: 956),
            .init(width: 466, height: 678), .init(width: 669, height: 951), .init(width: 1032, height: 1376),
            .init(width: 1376, height: 1032), .init(width: 520, height: 740)]
        for screen in screens {
            for raw in LevelCatalog.playable {
                let recipe = RemoteLevel(id: raw.id, cycle: 0, aspect: Double(GameView.playfieldSize(in: screen).height / screen.width))
                let level = recipe.build()
                let arena = GameView.arenaRect(for: level, screen: screen)
                XCTAssertGreaterThanOrEqual(arena.minY, 151 - 0.01)
                XCTAssertLessThanOrEqual(arena.maxY, screen.height - 132 + 0.01)
                XCTAssertLessThanOrEqual(arena.maxX, screen.width + 0.01)
                XCTAssertGreaterThan(arena.width, 200)
                XCTAssertEqual(arena.width / level.worldWidth, arena.height / level.worldHeight, accuracy: 0.0001)
                XCTAssertEqual(try XCTUnwrap(RemoteLevel(data: recipe.data)).build(), level)
                var points = level.sparks.map(\.position) + level.bonuses.map(\.position) + [level.exit, level.playerStart]
                for spark in level.sparks {
                    if let orbit = spark.orbit {
                        for a in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 8) {
                            points.append(Vec2(x: orbit.center.x + cos(a) * orbit.radius, y: orbit.center.y + sin(a) * orbit.radius))
                        }
                    }
                }
                for point in points {
                    let x = arena.minX + point.x / level.worldWidth * arena.width
                    let y = arena.maxY - point.y / level.worldHeight * arena.height
                    XCTAssertTrue(arena.insetBy(dx: -0.01, dy: -0.01).contains(CGPoint(x: x, y: y)), "Map \(raw.number), \(screen): \(point)")
                }
            }
        }
    }
    func testLiveArenaWithActiveHUDOnPhoneDuoAndPad() {
        let previous = LanguagePreference.shared.selection
        defer { CoverageHost.teardown(); LanguagePreference.shared.selection = previous }
        LanguagePreference.shared.selection = .russian
        let model = CoverageFixtures.model(rich: false)
        let sizes: [(String, CGSize)] = [("phone", .init(width: 390, height: 844)), ("duo-outer", .init(width: 466, height: 678)),
            ("duo-inner", .init(width: 669, height: 951)), ("ipad-landscape", .init(width: 1376, height: 1032))]
        for (name, size) in sizes {
            for number in [21, 40] {
                var game = GameView(request: CoverageFixtures.playRequest(number), viewport: size)
                game.session.banner = Copy.text("play.dragToMove")
                game.session.effects.shieldCharges = 1
                let view = CoverageHost.render(game.environment(model), size: size)
                RunLoop.current.run(until: Date().addingTimeInterval(0.4))
                let format = UIGraphicsImageRendererFormat(); format.scale = 2; format.opaque = true
                let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                    XCTAssertTrue(view.drawHierarchy(in: view.bounds, afterScreenUpdates: true))
                }
                let attachment = XCTAttachment(image: image)
                attachment.name = "arena-ru-\(name)-map\(number)"; attachment.lifetime = .keepAlways; add(attachment)
            }
        }
    }

}

@MainActor
final class AppStoreSceneCaptures: XCTestCase {
    func testCurrentGameAndCollectionAtAppleScreenshotSizes() {
        let previous = LanguagePreference.shared.selection
        defer { LanguagePreference.shared.selection = previous; CoverageHost.teardown() }
        let screens: [(String, CGSize, CGFloat)] = [("phone69", .init(width: 440, height: 956), 3),
            ("phone65", .init(width: 428, height: 926), 3), ("ipad", .init(width: 1032, height: 1376), 2)]
        let key = EndlessKey(seed: 0xEC40_D17E, depth: 14)
        let expedition = PlayRequest(levelID: key.levelID, daily: false, endless: key)
        let finds = ["wiki.story.break", "wiki.story.philosophy", "wiki.story.science"].compactMap(ArchiveDiscovery.item)
        for language in [AppLanguage.english, .russian] {
            LanguagePreference.shared.selection = language
            for (name, size, scale) in screens {
                let maps: [(String, PlayRequest)] = name == "ipad"
                    ? [("01-gameplay", CoverageFixtures.playRequest(21)), ("03-deep-time", expedition)]
                    : [("01-gameplay", CoverageFixtures.playRequest(21)), ("02-lasers", CoverageFixtures.playRequest(36)), ("04-deep-time", expedition)]
                for (file, request) in maps {
                    let model = CoverageFixtures.model(rich: false)
                    model.progress.debugLabShowcase()
                    var game = GameView(request: request, viewport: size)
                    game.modelOverride = model
                    let view = CoverageHost.render(game.environment(model), size: size)
                    game.useItem(.shield)
                    attach(view, scale: scale, name: "store-\(language.rawValue)-\(name)-\(file)")
                }
                if name != "ipad" {
                    attach(CoverageHost.render(ZStack {
                        ScreenBackground()
                        ArchiveRecoveryView(finds: finds, onRead: { _ in }, onContinue: {})
                    }, size: size), scale: scale, name: "store-\(language.rawValue)-\(name)-05-archive")
                }
            }
        }
    }

    private func attach(_ view: UIView, scale: CGFloat, name: String) {
        RunLoop.current.run(until: Date().addingTimeInterval(0.65))
        let format = UIGraphicsImageRendererFormat(); format.scale = scale; format.opaque = true
        let image = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { _ in
            XCTAssertTrue(view.drawHierarchy(in: view.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
