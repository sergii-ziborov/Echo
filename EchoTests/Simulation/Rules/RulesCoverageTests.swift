import XCTest
@testable import Echo

@MainActor
final class RulesCoverageTests: XCTestCase {
    func testBonusUpgradeAndHintCopy() {
        for kind in BonusKind.allCases {
            _ = kind.id
            _ = kind.title
            _ = kind.fieldLabel
            _ = kind.detail
            _ = kind.command
            _ = kind.bestUse
            _ = kind.duration
            _ = kind.price
            _ = kind.canBuy
            _ = kind.useFromBar
            _ = kind.cooldown
            _ = kind.icon
            _ = kind.tint
        }
        for kind in UpgradeKind.allCases {
            _ = kind.id
            _ = kind.branch
            _ = kind.title
            _ = kind.detail
            _ = kind.useCase
            _ = kind.icon
            _ = kind.maxLevel
            _ = kind.baseCost
            _ = kind.costStep
            _ = kind.prerequisites
            _ = kind.cost(after: 0)
            _ = kind.cost(after: 3)
        }
        for branch in UpgradeBranch.allCases {
            _ = branch.title
            _ = branch.tint
        }
        for hint in EncounterHint.allCases {
            _ = hint.title
            _ = hint.detail
            _ = hint.action
        }
        XCTAssertFalse(BonusKind.ward.useFromBar)
    }

    func testThemeMaterialsAndAtmosphere() {
        for theme in ArenaTheme.allCases {
            _ = theme.sky
            _ = theme.wallFill
            _ = theme.wallStroke
            _ = theme.nebula
        }
        for number in 0...12 {
            _ = ArenaTheme.forLevel(number)
            _ = ArenaAtmosphere.forLevel(number)
        }
        for material in AsteroidMaterial.allCases {
            _ = material.title
            _ = material.shortLabel
            _ = material.wallHitsToShatter
            _ = material.fractureDuration
            _ = material.isBreakable
        }
        let decoration = ArenaDecoration(
            id: 1,
            kind: .lane(to: Vec2(x: 10, y: 20), chevrons: 3),
            position: Vec2(x: 4, y: 8),
            tone: .cyan
        )
        _ = decoration.scaled(sy: 1.2)
        _ = ArenaDecoration(id: 2, kind: .anchor(radius: 12), position: .zero, tone: .gold).scaled(sy: 0.5)
        _ = ArenaMetrics.satelliteRadius
        _ = GravityWellSpawn(id: 1, position: Vec2(x: 8, y: 12)).scaled(sy: 2)
        XCTAssertEqual(ArenaTheme.forLevel(1), .void)
    }
}
