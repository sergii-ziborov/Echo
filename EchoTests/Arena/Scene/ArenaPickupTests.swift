import SpriteKit
import XCTest
@testable import Echo

@MainActor
final class ArenaPickupTests: XCTestCase {
    func testCollectedPickupHidesAtOnceAndARewindBringsItBack() throws {
        let level = try XCTUnwrap(LevelCatalog.level(number: 21))
        let session = GameSession(level: level, daily: false)
        let scene = GameScene(session: session, size: CoverageHost.size)
        CoverageHost.present(scene)
        var frame = RenderFrame(simulation: session.sim)
        let bonus = try XCTUnwrap(frame.bonuses.first)
        let node = try XCTUnwrap(scene.bonusNodes[bonus.id])
        XCTAssertFalse(node.isHidden)

        // Freeze stops pickup animations, so collection must not rely on them.
        node.speed = 0
        frame.bonuses[0].collected = true
        scene.apply(frame: frame, mode: .live)
        XCTAssertTrue(node.isHidden)

        frame.bonuses[0].collected = false
        scene.apply(frame: frame, mode: .live)
        XCTAssertFalse(node.isHidden)
        CoverageHost.teardown()
    }

    func testTimedCrystalTurnsIntoAPlainSparkWhenItsBonusExpires() throws {
        let level = try XCTUnwrap(LevelCatalog.level(number: 21))
        let session = GameSession(level: level, daily: false)
        let scene = GameScene(session: session, size: CoverageHost.size)
        CoverageHost.present(scene)
        let index = try XCTUnwrap(scene.displayed.sparks.firstIndex { $0.timerDuration != nil })
        let root = try XCTUnwrap(scene.sparkNodes[scene.displayed.sparks[index].id])
        let gem = try XCTUnwrap(root.childNode(withName: "gem") as? SKSpriteNode)
        XCTAssertTrue(gem.texture === SpriteTextures.timedGem)

        scene.displayed.sparks[index].timedOut = true
        scene.updateSparkTimers()
        XCTAssertTrue(gem.texture === SpriteTextures.sparkGem)
        CoverageHost.teardown()
    }

    func testEveryAbilityTokenIsDrawn() {
        for kind in BonusKind.allCases {
            let image = SpriteTextures.token(kind).cgImage()
            XCTAssertGreaterThan(image.width, 100, "\(kind)")
        }
    }
}
