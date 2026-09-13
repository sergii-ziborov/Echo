import SpriteKit
import UIKit
import XCTest
@testable import Echo

@MainActor
final class VisualAssetTests: XCTestCase {
    func testEveryGeneratedAtlasIsBundled() {
        for name in [
            "AsteroidMaterialAtlas", "AsteroidVariantAtlasA", "AsteroidVariantAtlasB",
            "WallMaterialAtlas", "WallVariantAtlasA", "WallVariantAtlasB",
            "ObstacleTileAtlas",
        ] {
            XCTAssertNotNil(UIImage(named: name)?.cgImage, "Missing asset: \(name)")
        }
    }

    func testRockMaterialsSelectDistinctVisualVariants() {
        let expectedCounts: [(AsteroidMaterial, Int)] = [
            (.basalt, 5), (.ice, 2), (.crystal, 2), (.alloy, 3),
        ]
        for (material, count) in expectedCounts {
            let variants = (0..<count).map { GlowTextures.asteroid(for: material, variation: $0) }
            for left in variants.indices {
                for right in variants.indices where right > left {
                    XCTAssertFalse(variants[left] === variants[right], "Repeated \(material) skin")
                }
            }
        }
    }

    func testEveryRockAppearanceOccursInTheLevelCatalog() {
        let expectedCounts: [(AsteroidMaterial, Int)] = [
            (.basalt, 5), (.ice, 2), (.crystal, 2), (.alloy, 3),
        ]
        for (material, count) in expectedCounts {
            let appearances = Set(LevelCatalog.playable.flatMap { level in
                level.movers.filter { $0.material == material }.map { mover in
                    AsteroidMaterial.appearanceSeed(levelNumber: level.number, rockID: mover.id) % count
                }
            })
            XCTAssertEqual(appearances.count, count, "Some \(material) art never appears")
        }
    }

    func testThemeFinishesCycleAcrossMaps() throws {
        for theme in ArenaTheme.allCases {
            let firstLevel = theme.rawValue + 1
            let first = try XCTUnwrap(GlowTextures.wall(for: theme, levelNumber: firstLevel))
            let second = try XCTUnwrap(GlowTextures.wall(for: theme, levelNumber: firstLevel + 6))
            let third = try XCTUnwrap(GlowTextures.wall(for: theme, levelNumber: firstLevel + 12))
            XCTAssertFalse(first === second, "First and second \(theme) finishes match")
            XCTAssertFalse(second === third, "Second and third \(theme) finishes match")
        }
    }

    func testAllWallFinishesAppearInPlayableMaps() {
        let finishes = Set(LevelCatalog.playable.compactMap { level in
            GlowTextures.wall(for: level.theme, levelNumber: level.number).map(ObjectIdentifier.init)
        })
        XCTAssertEqual(finishes.count, 12)
    }

    func testObstacleStatesHaveDedicatedSprites() {
        XCTAssertNotNil(GlowTextures.closedGate)
        XCTAssertNotNil(GlowTextures.openGate)
        XCTAssertNotNil(GlowTextures.slowField)
        XCTAssertNotNil(GlowTextures.hazardEmitter)
        XCTAssertFalse(GlowTextures.closedGate === GlowTextures.openGate)
        XCTAssertTrue(LevelCatalog.playable.contains { !$0.gates.isEmpty })
        XCTAssertTrue(LevelCatalog.playable.contains { !$0.fields.isEmpty })
        XCTAssertTrue(LevelCatalog.playable.contains { !$0.lasers.isEmpty })
    }
}
