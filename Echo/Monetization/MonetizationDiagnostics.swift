import Foundation

/// Small on-device log. Never accepts arbitrary SDK errors, transaction IDs or payloads.
@MainActor
final class MonetizationDiagnostics {
    enum Event: String, Codable { case entitlementResolution, adOpportunity, adStarted, adClosed, purchaseResult, restoreResult, nextTransition }
    struct Entry: Codable { var time: Date; var event: Event; var result: String; var placement: AdPlacement? }
    static let shared = MonetizationDiagnostics()
    private let defaults: UserDefaults
    private let key = "echo.monetization.diagnostics.v1"
    private(set) var entries: [Entry]
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        entries = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([Entry].self, from: $0) } ?? []
    }
    func record(_ event: Event, _ result: String, placement: AdPlacement? = nil) {
        // Callers supply fixed application-owned result classes, never SDK descriptions.
        entries.append(Entry(time: Date(), event: event, result: String(result.prefix(64)), placement: placement))
        entries = Array(entries.suffix(60))
        if let data = try? JSONEncoder().encode(entries) { defaults.set(data, forKey: key) }
    }
}
