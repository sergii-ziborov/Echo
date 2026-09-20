import SwiftUI
import XCTest
@testable import Echo

@MainActor
final class DemoCoverageTests: XCTestCase {
    func testEveryMechanicDemo() {
        let scenarios = MechanicDemoScenario.allCases
        XCTAssertFalse(scenarios.isEmpty)
        for scenario in scenarios {
            CoverageHost.render(MechanicDemoView(scenario: scenario, height: 162))
            CoverageHost.renderCanvas(MechanicDemoView(scenario: scenario, height: 162))
            _ = scenario.caption
            _ = scenario.tint
        }
        for kind in BonusKind.allCases {
            CoverageHost.renderCanvas(MechanicDemoView(scenario: MechanicDemoScenario(bonus: kind)))
        }
        for kind in UpgradeKind.allCases {
            CoverageHost.renderCanvas(MechanicDemoView(scenario: MechanicDemoScenario(upgrade: kind)))
        }
        for hint in EncounterHint.allCases {
            CoverageHost.renderCanvas(MechanicDemoView(scenario: MechanicDemoScenario(hint: hint)))
            CoverageHost.render(EncounterCard(hint: hint, onDismiss: {}))
            _ = hint.title
            _ = hint.detail
            _ = hint.action
        }
    }

    func testEveryTechnologyPreview() {
        for kind in UpgradeKind.allCases {
            for level in [0, 1, kind.maxLevel] {
                let preview = TechnologyPreviewView(
                    kind: kind,
                    level: level,
                    currentValue: "NOW",
                    nextValue: "NEXT",
                    height: 220
                )
                CoverageHost.render(preview)
                CoverageHost.renderCanvas(preview)
                _ = preview.plateName
                _ = preview.tint
            }
        }
        CoverageHost.renderCanvas(
            Canvas { context, size in
                var ctx = context
                let preview = TechnologyPreviewView(
                    kind: .aegis, level: 3, currentValue: "NOW", nextValue: "NEXT"
                )
                preview.techLightning(
                    context: &ctx,
                    from: CGPoint(x: 8, y: 8),
                    to: CGPoint(x: size.width - 8, y: size.height - 8),
                    color: .cyan,
                    seed: 4
                )
                preview.techShieldBubble(
                    context: &ctx,
                    center: CGPoint(x: size.width / 2, y: size.height / 2),
                    radius: 28,
                    layers: 3,
                    impact: true,
                    strength: 1
                )
                MechanicDemoView(scenario: .laser).mechanicLightning(
                    context: &ctx,
                    from: CGPoint(x: 12, y: size.height / 2),
                    to: CGPoint(x: size.width - 12, y: size.height / 2),
                    color: .white,
                    seed: 2
                )
            }
        )
    }
}

extension MechanicDemoScenario: CaseIterable {
    public static var allCases: [MechanicDemoScenario] {
        [
            .echo, .asteroid, .rift, .freeze, .phase, .collision, .gate, .laser,
            .timeCrystal, .resonance, .blackHole, .shield, .surge, .pulse, .magnet,
            .chrono, .anchor, .repulse, .prism, .blink,
        ]
    }
}
