import Foundation
import Security

@MainActor
protocol PurchaseEvidenceCaching {
    func load() throws -> [PurchaseEvidence]
    func save(_ evidence: [PurchaseEvidence]) throws
}

enum MonetizationError: Error { case unverified, persistence, unavailable, invalidPolicy }

struct KeychainEvidenceCache: PurchaseEvidenceCaching {
    private let service = "com.sergiiziborov.Echo.purchases.v1"
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service, kSecAttrAccount as String: "verified-evidence"]
    }
    func load() throws -> [PurchaseEvidence] {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let data = result as? Data else { throw MonetizationError.persistence }
        return try JSONDecoder().decode([PurchaseEvidence].self, from: data)
    }
    func save(_ evidence: [PurchaseEvidence]) throws {
        let data = try JSONEncoder().encode(evidence)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw MonetizationError.persistence }
        } else if status != errSecSuccess { throw MonetizationError.persistence }
    }
}
