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

    func testLegacyTextureHelpersStillBuild() {
        _ = GlowTextures.asteroid
        _ = GlowTextures.candyTimeline
        _ = GlowTextures.asteroid(for: .basalt, variation: 0)
        _ = GlowTextures.wall(for: .void, levelNumber: 1)
        _ = GlowTextures.bonus(.ward)
        _ = GlowTextures.orb(color: .cyan, size: 32)
        _ = GlowTextures.abilityGlyph(systemName: "shield.fill", color: .green, size: 28)
        _ = GlowTextures.abilityGlyph(systemName: "missing", color: .white, size: 20)
    }

    func testEveryAbilityHasItsOwnGeneratedGem() {
        XCTAssertEqual(BonusKind.allCases.count, 12)
        for left in BonusKind.allCases {
            for right in BonusKind.allCases where left != right {
                XCTAssertFalse(GlowTextures.bonus(left) === GlowTextures.bonus(right),
                               "\(left) and \(right) reuse the same in-game texture")
            }
        }
    }
}
