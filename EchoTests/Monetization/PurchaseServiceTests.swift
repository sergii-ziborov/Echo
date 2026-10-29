import XCTest
@testable import Echo

@MainActor
final class TestPurchaseClient: PurchaseClient {
    var original = OriginalAcquisition(evidenceID: "fixture", bundleID: MonetizationConfiguration.bundleID,
        environment: .sandbox, originalBuild: "18", originalPurchaseDate: .distantPast)
    var active: [PurchaseEvidence] = []
    var available: PurchaseProduct? = PurchaseProduct(id: MonetizationConfiguration.productID, displayPrice: "₪7.90")
    var outcome = PurchaseOutcome.cancelled
    var failure = false
    var buyCount = 0
    var finished: [String] = []
    var onFinish: (() -> Void)?
    var continuation: AsyncStream<PurchaseUpdate>.Continuation?
    func acquisition(refresh: Bool) async throws -> OriginalAcquisition {
        if failure { throw MonetizationError.unavailable }
        return original
    }
    func entitlements() async throws -> [PurchaseEvidence] { active }
    func product() async throws -> PurchaseProduct? { available }
    func purchase() async throws -> PurchaseOutcome {
        buyCount += 1
        try await Task.sleep(for: .milliseconds(30))
        return outcome
    }
    func sync() async throws { if failure { throw MonetizationError.unavailable } }
    func updates() -> AsyncStream<PurchaseUpdate> { AsyncStream { continuation = $0 } }
    func finish(_ evidence: PurchaseEvidence) async { finished.append(evidence.id); onFinish?() }
}

@MainActor
final class PurchaseServiceTests: XCTestCase {
    func evidence() -> PurchaseEvidence {
        PurchaseEvidence(id: "sandbox-iap", source: .purchase, environment: .sandbox,
            productID: MonetizationConfiguration.productID, verifiedAt: Date())
    }
    func service(_ client: TestPurchaseClient, cache: MemoryEvidenceCache = MemoryEvidenceCache()) -> StoreKitPurchaseService {
        StoreKitPurchaseService(client: client, entitlements: EntitlementStore(cache: cache))
    }
    func testDisplayPriceAndOnePurchaseTaskFinishesOnlyAfterDurableGrant() async {
        let client = TestPurchaseClient(), cache = MemoryEvidenceCache()
        let service = service(client, cache: cache)
        await service.resolve(); await service.loadProduct()
        XCTAssertEqual(service.product?.displayPrice, "₪7.90")
        client.outcome = .purchased(evidence())
        client.onFinish = { XCTAssertEqual(cache.evidence.first?.id, "sandbox-iap") }
        let first = Task { await service.buy() }
        await Task.yield()
        await service.buy()
        await first.value
        XCTAssertEqual(client.buyCount, 1)
        XCTAssertTrue(service.entitlements.state.isAdFree)
        XCTAssertFalse(service.canPurchase)
        XCTAssertEqual(client.finished, ["sandbox-iap"])
    }
    func testPendingIsNotFailureAndListenerDeliversWithNoPurchaseScreen() async {
        let client = TestPurchaseClient()
        let live = self.service(client)
        live.start()
        await live.resolve(); await live.loadProduct()
        client.outcome = .pending
        await live.buy()
        XCTAssertEqual(live.messageKey, "monetization.pending")
        XCTAssertFalse(live.canPurchase)
        let done = expectation(description: "transaction finished")
        client.onFinish = { done.fulfill() }
        client.continuation?.yield(PurchaseUpdate(evidence: evidence(), revoked: false))
        await fulfillment(of: [done], timeout: 2)
        XCTAssertTrue(live.entitlements.state.isAdFree)
        client.continuation?.finish()
    }
    func testCancelledUnavailableAndRestoreTimeoutDoNotInventOwnership() async {
        let client = TestPurchaseClient()
        let live = self.service(client)
        await live.resolve(); await live.loadProduct(); await live.buy()
        XCTAssertNil(live.messageKey)
        XCTAssertTrue(live.entitlements.state.isConclusiveFree)
        client.available = nil; await live.loadProduct()
        XCTAssertTrue(live.productUnavailableThisSession)
        XCTAssertFalse(live.canPurchase)
        client.failure = true; await live.restore()
        XCTAssertEqual(live.messageKey, "monetization.restoreError")
        XCTAssertFalse(live.entitlements.state.isConclusiveFree)
        XCTAssertFalse(live.entitlements.state.isAdFree)
    }
    func testProductionWithoutApprovedCutoverOffersNoRepurchase() async {
        let client = TestPurchaseClient(); client.original.environment = .production
        let service = self.service(client)
        await service.resolve(); await service.loadProduct()
        XCTAssertFalse(service.purchaseOffered)
        XCTAssertNil(service.product)
        XCTAssertEqual(service.effectivePolicy.phase, .preFree)
    }
}
