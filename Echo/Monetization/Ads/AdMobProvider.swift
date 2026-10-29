import GoogleMobileAds
import UIKit

/// All vendor objects are isolated to the main actor and to the iOS target.
@MainActor
final class AdMobProvider: NSObject, AdProvider, FullScreenContentDelegate {
    private(set) var diagnosticID: String?
    private(set) var creative: AdCreative?
    private var prepared: InterstitialAd?
    private var presenting: InterstitialAd?
    private var started: (() -> Void)?
    private var completion: ((AdPresentationOutcome) -> Void)?
    private var initialized = false
    private var loading = false
    private var generation: UInt64 = 0
    private var retryAfter = Date.distantPast
    private let configuration: MonetizationConfiguration

    init(configuration: MonetizationConfiguration = .init()) { self.configuration = configuration }
    func prepareInterstitial(context: AdRequestContext) async {
        guard !loading, presenting == nil, Date() >= retryAfter,
              configuration.liveAppID.hasPrefix("ca-app-pub-"), configuration.liveAppID.contains("~"),
              context.testing || configuration.hasLiveIdentifiers else { return }
        loading = true
        let token = generation
        defer { loading = false }
        if !initialized {
            let request = MobileAds.shared.requestConfiguration
            request.setPublisherFirstPartyIDEnabled(false)
            request.maxAdContentRating = .general
            // Conservative family-safe defaults; audience review is still a separate release gate.
            request.ageRestrictedTreatment = .child
            request.publisherPrivacyPersonalizationState = .disabled
            await MobileAds.shared.start()
            initialized = true
        }
        guard !Task.isCancelled, generation == token else { return }
        do {
            let request = Request()
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
            let ad = try await InterstitialAd.load(with: context.testing
                ? MonetizationConfiguration.testInterstitialID : configuration.liveInterstitialID, request: request)
            guard !Task.isCancelled, generation == token else { return }
            ad.fullScreenContentDelegate = self
            prepared = ad
            var metadata = context.creative
            metadata.loadedAt = Date()
            creative = metadata
        } catch { retryAfter = Date().addingTimeInterval(60) }
    }
    func discardPreparedAds() {
        generation &+= 1
        prepared = nil
        creative = nil
        // A currently visible SDK view is left to its documented dismissal lifecycle.
    }
    func presentInterstitial(ticket: AdPresentationTicket, started: @escaping @MainActor () -> Void,
                             completion: @escaping @MainActor (AdPresentationOutcome) -> Void) {
        guard presenting == nil, let ad = prepared, creative != nil,
              let controller = AdPresentationHost.controller() else { completion(.failed); return }
        prepared = nil; creative = nil
        do { try ad.canPresent(from: controller) }
        catch { completion(.failed); return }
        presenting = ad; self.started = started; self.completion = completion
        ad.present(from: controller)
    }
    func adWillPresentFullScreenContent(_ ad: any FullScreenPresentingAd) {
        guard presenting != nil else { return }
        diagnosticID = presenting?.responseInfo.responseIdentifier.map {
            String($0.filter { $0.isLetter || $0.isNumber || "._-".contains($0) }.prefix(128))
        }
        let action = started; started = nil
        action?() // Frequency protection does not depend on the impression/revenue callback.
    }
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) { end(.dismissed) }
    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { end(.failed) }
    private func end(_ outcome: AdPresentationOutcome) {
        guard presenting != nil else { return }
        presenting = nil; started = nil
        let action = completion; completion = nil
        action?(outcome)
    }
}
