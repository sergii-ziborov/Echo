import SwiftUI
import XCTest
@testable import Echo

/// Reproducible native UI assets, separate from assertions about real hardware
/// models or purchases. Fixtures never replace the owner's gameplay defaults.
@MainActor
final class MarketingCaptureTests: XCTestCase {
    func testCaptureCurrentBilingualMenusAtSupportedViewports() async throws {
        let previous = LanguagePreference.shared.selection
        defer { LanguagePreference.shared.selection = previous; CoverageHost.teardown() }
        let model = CoverageFixtures.model(rich: false)
        model.progress.debugShowcase(cleared: 27)
        model.progress.debugLabShowcase()
        _ = model.progress.toggleEquipped(.shield)
        _ = model.progress.toggleEquipped(.freeze)
        model.progress.lastLevelID = "awakening-28"
        let sizes: [(String, CGSize, CGFloat)] = [
            ("phone69", CGSize(width: 440, height: 956), 3),
            ("phone65", CGSize(width: 428, height: 926), 3),
            ("ipad", CGSize(width: 1032, height: 1376), 2),
            ("duo-outer", CGSize(width: 466, height: 678), 2),
            ("duo-inner", CGSize(width: 669, height: 951), 2),
        ]
        for language in [AppLanguage.english, .russian] {
            LanguagePreference.shared.selection = language
            for (device, size, scale) in sizes {
                let views: [(String, AnyView)] = [
                    ("home", AnyView(HomeView())),
                    ("atlas", AnyView(WorldsView(act: .debris, levelNumber: 28))),
                    ("research", AnyView(ShopView(section: .research, researchBranch: .motion))),
                    ("loadout", AnyView(ShopView(section: .loadout))),
                    ("archive", AnyView(WikiView(section: .story, focusID: "wiki.story.philosophy"))),
                    ("regions", AnyView(WikiView(section: .acts, focusID: "region.trace"))),
                ]
                for (name, content) in views {
                    try await capture(content.environment(model).transaction { $0.disablesAnimations = true },
                                      size: size, scale: scale, name: "current-\(language.rawValue)-\(device)-\(name)")
                }
            }
            let client = TestPurchaseClient()
            let purchases = StoreKitPurchaseService(client: client, entitlements: EntitlementStore(cache: MemoryEvidenceCache()))
            await purchases.resolve(); await purchases.loadProduct()
            try await capture(RemoveAdsView(purchases: purchases), size: CGSize(width: 393, height: 852), scale: 3,
                              name: "review-fixture-\(language.rawValue)-purchase")
        }
    }

    private func capture<V: View>(_ content: V, size: CGSize, scale: CGFloat, name: String) async throws {
        let view = CoverageHost.render(content, size: size)
        try await Task.sleep(for: .milliseconds(450))
        let format = UIGraphicsImageRendererFormat(); format.scale = scale; format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        XCTAssertEqual(image.size, size)
        let attachment = XCTAttachment(image: image)
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
