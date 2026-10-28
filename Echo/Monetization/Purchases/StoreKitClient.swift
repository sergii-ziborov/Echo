import StoreKit
import CryptoKit

struct PurchaseProduct: Equatable, Sendable { var id: String; var displayPrice: String }
enum PurchaseOutcome: Equatable { case purchased(PurchaseEvidence), pending, cancelled }
struct PurchaseUpdate: Sendable { var evidence: PurchaseEvidence?; var revoked: Bool }

@MainActor
protocol PurchaseClient: AnyObject {
    func acquisition(refresh: Bool) async throws -> OriginalAcquisition
    func entitlements() async throws -> [PurchaseEvidence]
    func product() async throws -> PurchaseProduct?
    func purchase() async throws -> PurchaseOutcome
    func sync() async throws
    func updates() -> AsyncStream<PurchaseUpdate>
    func finish(_ evidence: PurchaseEvidence) async
}

@MainActor
final class StoreKitClient: PurchaseClient {
    private var storeProduct: Product?
    private var unfinished: [String: Transaction] = [:]

    func acquisition(refresh: Bool) async throws -> OriginalAcquisition {
        let result = try await (refresh ? AppTransaction.refresh() : AppTransaction.shared)
        guard case .verified(let transaction) = result,
              transaction.bundleID == MonetizationConfiguration.bundleID,
              transaction.appID == nil || transaction.appID == 6811673094 else { throw MonetizationError.unverified }
        return OriginalAcquisition(evidenceID: Self.digest(transaction.appTransactionID.isEmpty
            ? "\(transaction.bundleID)|\(transaction.originalAppVersion)|\(transaction.originalPurchaseDate.timeIntervalSince1970)|\(transaction.environment)"
            : transaction.appTransactionID), bundleID: transaction.bundleID,
            environment: Self.environment(transaction.environment), originalBuild: transaction.originalAppVersion,
            originalPurchaseDate: transaction.originalPurchaseDate)
    }
    func entitlements() async throws -> [PurchaseEvidence] {
        var result: [PurchaseEvidence] = []
        for await value in Transaction.currentEntitlements {
            guard case .verified(let transaction) = value else { throw MonetizationError.unverified }
            guard transaction.productID == MonetizationConfiguration.productID else { continue }
            guard transaction.productType == .nonConsumable else { throw MonetizationError.unverified }
            if transaction.revocationDate == nil { result.append(Self.evidence(transaction)) }
        }
        return result
    }
    func product() async throws -> PurchaseProduct? {
        let products = try await Product.products(for: [MonetizationConfiguration.productID])
        guard let item = products.first(where: { $0.id == MonetizationConfiguration.productID && $0.type == .nonConsumable }) else {
            storeProduct = nil
            return nil
        }
        storeProduct = item
        return PurchaseProduct(id: item.id, displayPrice: item.displayPrice)
    }
    func purchase() async throws -> PurchaseOutcome {
        guard let storeProduct else { throw MonetizationError.unavailable }
        switch try await storeProduct.purchase() {
        case .success(let result):
            guard case .verified(let transaction) = result,
                  transaction.productID == MonetizationConfiguration.productID,
                  transaction.productType == .nonConsumable, transaction.revocationDate == nil
            else { throw MonetizationError.unverified }
            let evidence = Self.evidence(transaction)
            unfinished[evidence.id] = transaction
            return .purchased(evidence)
        case .pending: return .pending
        case .userCancelled: return .cancelled
        @unknown default: throw MonetizationError.unavailable
        }
    }
    func sync() async throws { try await AppStore.sync() }
    func updates() -> AsyncStream<PurchaseUpdate> {
        AsyncStream { continuation in
            let task = Task { [weak self] in
                for await value in Transaction.updates {
                    guard !Task.isCancelled else { break }
                    guard case .verified(let transaction) = value else {
                        // No unverified transaction may grant, revoke or finish a purchase.
                        continuation.yield(PurchaseUpdate(evidence: nil, revoked: false))
                        continue
                    }
                    guard transaction.productID == MonetizationConfiguration.productID,
                          transaction.productType == .nonConsumable else { continue }
                    let evidence = Self.evidence(transaction)
                    self?.unfinished[evidence.id] = transaction
                    continuation.yield(PurchaseUpdate(evidence: evidence, revoked: transaction.revocationDate != nil))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    func finish(_ evidence: PurchaseEvidence) async {
        guard let transaction = unfinished.removeValue(forKey: evidence.id) else { return }
        await transaction.finish()
    }
    private static func evidence(_ transaction: Transaction) -> PurchaseEvidence {
        PurchaseEvidence(id: String(transaction.id), source: transaction.ownershipType == .familyShared ? .family : .purchase,
            environment: environment(transaction.environment), productID: transaction.productID, verifiedAt: Date())
    }
    private static func environment(_ value: AppStore.Environment) -> PurchaseEnvironment {
        switch value {
        case .production: .production
        case .sandbox: .sandbox
        case .xcode: .xcode
        default: .unknown
        }
    }
    private static func digest(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
