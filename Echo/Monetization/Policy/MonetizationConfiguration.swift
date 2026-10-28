import Foundation

struct MonetizationConfiguration {
    static let bundleID = "com.sergiiziborov.Echo"
    /// App Store Connect non-consumable 6828008885; approval is a separate release gate.
    static let productID = "com.sergiiziborov.Echo.removeAds"
    static var adsCompiledIn: Bool {
#if ECHO_ADMOB
        true
#else
        false
#endif
    }
    static var requiresTestAds: Bool {
#if DEBUG
        true
#else
        false
#endif
    }
    static let testAppID = "ca-app-pub-3940256099942544~1458002511"
    static let testInterstitialID = "ca-app-pub-3940256099942544/4411468910"
    var liveAppID: String = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
    var liveInterstitialID: String = Bundle.main.object(forInfoDictionaryKey: "EchoInterstitialUnitID") as? String ?? ""
    var policyURL: URL? = (Bundle.main.object(forInfoDictionaryKey: "EchoReleasePolicyURL") as? String).flatMap(URL.init(string:))
    var publicKey: Data? = (Bundle.main.object(forInfoDictionaryKey: "EchoReleasePolicyPublicKey") as? String).flatMap { Data(base64Encoded: $0) }
    var hasLiveIdentifiers: Bool {
        liveAppID.hasPrefix("ca-app-pub-") && liveAppID.contains("~") && !liveAppID.contains("3940256099942544")
            && liveInterstitialID.hasPrefix("ca-app-pub-") && liveInterstitialID.contains("/")
            && !liveInterstitialID.contains("3940256099942544")
    }
}
