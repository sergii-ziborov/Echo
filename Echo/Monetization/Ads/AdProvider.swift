import Foundation

struct AdRequestContext: Equatable {
    var creative: AdCreative
    var testing: Bool
}
struct AdPresentationTicket: Equatable {
    var id: UUID
    var runID: UUID
    var resultID: UUID
    var navigationGeneration: UInt64
    var entitlementGeneration: UInt64
    var privacyGeneration: UInt64
}
enum AdPresentationOutcome { case dismissed, failed }

@MainActor
protocol AdProvider: AnyObject {
    var creative: AdCreative? { get }
    var diagnosticID: String? { get }
    func prepareInterstitial(context: AdRequestContext) async
    func discardPreparedAds()
    func presentInterstitial(ticket: AdPresentationTicket, started: @escaping @MainActor () -> Void,
        completion: @escaping @MainActor (AdPresentationOutcome) -> Void)
}

extension AdProvider { var diagnosticID: String? { nil } }

/// Default provider has no network, requests, timers or presentation behavior.
@MainActor
final class DisabledAdProvider: AdProvider {
    var creative: AdCreative? { nil }
    func prepareInterstitial(context: AdRequestContext) async {}
    func discardPreparedAds() {}
    func presentInterstitial(ticket: AdPresentationTicket, started: @escaping @MainActor () -> Void,
        completion: @escaping @MainActor (AdPresentationOutcome) -> Void) { completion(.failed) }
}

@MainActor
@Observable
final class MonetizationModalGate {
    enum Owner { case purchase, privacy, ad }
    private(set) var owner: Owner?
    func acquire(_ next: Owner) -> Bool {
        guard owner == nil else { return false }
        owner = next
        return true
    }
    func release(_ previous: Owner) { if owner == previous { owner = nil } }
}
