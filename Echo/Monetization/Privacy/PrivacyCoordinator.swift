import Foundation

@MainActor
protocol AdPrivacyClient: AnyObject {
    var canRequestAds: Bool { get }
    var optionsRequired: Bool { get }
    func updateConsent(mayPresent: @escaping @MainActor () -> Bool) async throws
    func showOptions() async throws
}
@MainActor
final class DisabledPrivacyClient: AdPrivacyClient {
    var canRequestAds: Bool { false }
    var optionsRequired: Bool { false }
    func updateConsent(mayPresent: @escaping @MainActor () -> Bool) async throws { throw MonetizationError.unavailable }
    func showOptions() async throws { throw MonetizationError.unavailable }
}

@MainActor
@Observable
final class PrivacyCoordinator {
    private let client: any AdPrivacyClient
    private(set) var generation: UInt64 = 0
    private(set) var canRequestAds = false
    private(set) var optionsRequired = false
    private(set) var messageKey: String?
    private var updatedThisLaunch = false
    var onChange: (() -> Void)?
    init(client: any AdPrivacyClient = DisabledPrivacyClient()) { self.client = client }
    func prepare(mayPresent: @escaping @MainActor () -> Bool = { true }) async {
        guard !updatedThisLaunch else { return }
        updatedThisLaunch = true
        invalidate()
        do {
            try await client.updateConsent(mayPresent: mayPresent)
            canRequestAds = client.canRequestAds
        } catch { canRequestAds = false }
        optionsRequired = client.optionsRequired
        onChange?()
    }
    func showOptions() async {
        invalidate()
        do {
            try await client.showOptions()
            canRequestAds = client.canRequestAds
        } catch {
            canRequestAds = false
            messageKey = "privacy.unavailable"
        }
        optionsRequired = client.optionsRequired
        onChange?()
    }
    func invalidate() {
        generation &+= 1
        canRequestAds = false
        onChange?()
    }
}
