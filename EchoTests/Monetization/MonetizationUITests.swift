import SwiftUI
import XCTest
@testable import Echo

@MainActor
final class MonetizationUITests: XCTestCase {
    func testBilingualPurchaseAndCheckingLayoutsAtPhoneAndIPadSizes() async throws {
        let previous = LanguagePreference.shared.selection
        defer { LanguagePreference.shared.selection = previous; CoverageHost.teardown() }
        for language in [AppLanguage.english, .russian] {
            LanguagePreference.shared.selection = language
            for size in [CGSize(width: 320, height: 568), CGSize(width: 393, height: 852), CGSize(width: 1024, height: 768)] {
                let client = TestPurchaseClient()
                let service = StoreKitPurchaseService(client: client, entitlements: EntitlementStore(cache: MemoryEvidenceCache()))
                await service.resolve(); await service.loadProduct()
                let name = "purchase-\(language.rawValue)-\(Int(size.width))"
                attach(RemoveAdsView(purchases: service), size: size, name: name)
                client.failure = true; await service.restore()
                attach(RemoveAdsView(purchases: service).environment(\.dynamicTypeSize, .accessibility2), size: size, name: name + "-checking-large")
                XCTAssertNotEqual(service.messageKey, "monetization.restoreNone")
            }
        }
    }
    private func attach<V: View>(_ content: V, size: CGSize, name: String) {
        let view = CoverageHost.render(content, size: size)
        let image = UIGraphicsImageRenderer(bounds: view.bounds).image { _ in view.drawHierarchy(in: view.bounds, afterScreenUpdates: true) }
        let attachment = XCTAttachment(image: image); attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
