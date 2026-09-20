import SwiftUI
import XCTest
@testable import Echo

@MainActor
final class ChromeCoverageTests: XCTestCase {
    func testPrimitivesAndIcons() {
        CoverageHost.render(
            VStack(spacing: 12) {
                ScreenBackground()
                EchoAmbientOrbs()
                EchoMark()
                Wordmark()
                PrimaryButton(title: "Play", systemImage: "play.fill", action: {})
                SecondaryButton(title: "Atlas", systemImage: "map", action: {})
                GhostButton(title: "Wiki", action: {})
                StarRow(filled: 0)
                StarRow(filled: 2)
                StarRow(filled: 3)
                IconCircle(system: "gearshape.fill", action: {})
                ForEach(BonusKind.allCases) { kind in
                    AbilityIconView(kind: kind)
                }
            }
            .padding()
        )
    }
}
