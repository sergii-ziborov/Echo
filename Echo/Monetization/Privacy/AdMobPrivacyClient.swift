import UserMessagingPlatform
import UIKit

@MainActor
final class AdMobPrivacyClient: AdPrivacyClient {
    var canRequestAds: Bool { ConsentInformation.shared.canRequestAds }
    var optionsRequired: Bool { ConsentInformation.shared.privacyOptionsRequirementStatus == .required }
    private var configured: Bool {
        let id = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
        return id.hasPrefix("ca-app-pub-") && id.contains("~")
    }
    func updateConsent(mayPresent: @escaping @MainActor () -> Bool) async throws {
        guard configured, mayPresent() else { throw MonetizationError.unavailable }
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = true
        try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
        guard !Task.isCancelled, mayPresent() else { throw MonetizationError.unavailable }
        if ConsentInformation.shared.consentStatus == .required {
            // Load separately so a late response cannot put a form over a new arena.
            let form = try await ConsentForm.load()
            guard !Task.isCancelled, mayPresent(), let host = AdPresentationHost.controller() else { throw MonetizationError.unavailable }
            try await form.present(from: host)
        }
    }
    func showOptions() async throws {
        guard configured, let host = AdPresentationHost.controller(allowExistingSheet: true) else { throw MonetizationError.unavailable }
        // Explicit user action remains available after Remove Ads; never requests an ad.
        if ConsentInformation.shared.privacyOptionsRequirementStatus == .unknown {
            let parameters = RequestParameters()
            parameters.isTaggedForUnderAgeOfConsent = true
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
        }
        guard UIApplication.shared.applicationState == .active, host.viewIfLoaded?.window != nil, optionsRequired else { throw MonetizationError.unavailable }
        try await ConsentForm.presentPrivacyOptionsForm(from: host)
    }
}
