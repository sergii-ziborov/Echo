import StoreKit
import StoreKitTest
import XCTest
@testable import Echo

/// Real StoreKit APIs against a local .storekit configuration, not production or Sandbox purchases.
@MainActor
final class StoreKitIntegrationTests: XCTestCase {
    func testLocalProductPurchaseReenumerationAndVerifiedRefund() async throws {
        let file = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "RemoveAds", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: file)
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }
        let nativeProducts = try await Product.products(for: [MonetizationConfiguration.productID])
        guard !nativeProducts.isEmpty else {
            throw XCTSkip("BLOCKED: StoreKit test service did not install the local configuration under xcodebuild; no mock purchase is substituted. See REPORT.md and Apple FB22237318.")
        }
        let client = StoreKitClient()
        let product = try await client.product()
        XCTAssertEqual(product?.id, MonetizationConfiguration.productID)
        XCTAssertFalse(try XCTUnwrap(product?.displayPrice).isEmpty)
        let outcome = try await client.purchase()
        guard case .purchased(let evidence) = outcome else { return XCTFail("Local purchase should complete") }
        XCTAssertEqual(evidence.environment, .xcode)
        let store = EntitlementStore(cache: MemoryEvidenceCache())
        try store.grant(evidence, familySharingEnabled: false)
        await client.finish(evidence)
        let fresh = StoreKitClient()
        let current = try await fresh.entitlements()
        XCTAssertTrue(current.contains { $0.id == evidence.id })
        let updates = fresh.updates()
        let revoked = expectation(description: "verified local refund")
        let listener = Task {
            for await update in updates {
                if let item = update.evidence, item.id == evidence.id, update.revoked {
                    try store.revoke(id: item.id, environment: item.environment)
                    await fresh.finish(item)
                    revoked.fulfill()
                    return
                }
            }
        }
        defer { listener.cancel() }
        try session.refundTransaction(identifier: try XCTUnwrap(UInt(evidence.id)))
        await fulfillment(of: [revoked], timeout: 5)
        XCTAssertFalse(store.state.isAdFree)
        XCTAssertFalse(store.state.isConclusiveFree) // Refund still requires acquisition re-evaluation.
    }
}
