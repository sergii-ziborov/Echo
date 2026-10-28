# Privacy Policy — ECHO

Source update: 28 October 2026. This source accompanies the prepared 1.1.0 transition build; it does not announce that the paid App Store 1.0.0 has changed price. Production starts in `preFree`, without advertising requests or an additional purchase offer. Live advertising remains gated by the release and privacy audit in [docs/monetization/](docs/monetization/RELEASE.md).

## Local game data

ECHO does not require a developer account. Campaign records, abilities, research, inventory, recovered Archive entries, language and audio preferences stay on the device using Apple storage. Reset progress deletes game progress, not purchase evidence or advertising privacy choices. Uninstalling may remove local progress; restoring a purchase does not synchronize game progress between iPhone and iPad.

## Purchases and original owners

Apple handles App Store payments. StoreKit checks signed app-acquisition and Remove Ads transactions. ECHO keeps the minimum local verification evidence (source, environment, product/transaction reference and legacy-policy reference) in device-only Keychain for restoration and offline protection. ECHO does not receive payment card details or collect an Apple ID. Uncertain entitlement means no ads while checking; it does not mean a new permanent purchase has been granted.

Original acquisitions in the approved protected period keep ad-free access. Resetting game progress does not remove this right. Purchasing and first restoration on another device may require an App Store connection; ordinary gameplay works offline.

## Advertising and privacy choices

In an enabled free release, eligible players may see rare interstitials only after successful solo campaign results and explicit Next. Maps 1–5, deaths, Retry/Rewind, discoveries, educational content, region ends, Daily, Deep Time, Apple Watch and Watch-controlled attempts are protected. Remove Ads disables all future advertising requests and shows from ECHO. Rewarded, banners and app-open advertising are not part of this release.

The explicit AdMob iOS variant includes Google Mobile Ads and Google’s User Messaging Platform (UMP); the default SDK-free build excludes these SDKs; TestFlight 24 uses the explicit SDK variant. Advertising does not initialize unconditionally at launch: commercial rights, release policy, context and privacy eligibility must allow it. Request configuration disables publisher first-party ID and personalization, and applies restrictive content/age treatment. This does not establish that no data is collected. When used, the SDK may process IP/network information (including approximate location inferred from IP), device information, crash/performance diagnostics, ad activity and interactions for advertising delivery and measurement. See [Google's disclosures](https://developers.google.com/admob/ios/privacy/data-disclosure) and [Google Privacy Policy](https://policies.google.com/privacy).

ECHO does not request the advertising identifier or add a developer analytics SDK. The exact production SDK disclosures, regional consent messages, audience restrictions and retention must be verified before live advertising is enabled; the release is blocked until that audit is complete. “Non-personalized” is not presented as a synonym for “no data collection.”

Settings → Ads and Purchases provides privacy options when the provider requires them and a user-initiated ad report. Buying Remove Ads stops ECHO's future ad loads/shows; it does not erase previously transmitted data or unload a running third-party framework. The provider's privacy-choice path remains available after purchase without requesting a new ad.

## Release-policy connection

A configured transition build may retrieve a small, signed policy over HTTPS to disable or restrict advertising and protect acquisition cohorts. The request has no device/account identifier or gameplay payload. Its host may process technical request logs such as IP and user agent. The endpoint is this website’s root `/monetization-policy.json`, configured on 28 October 2026. Hosting log retention remains unverified and blocks live activation. A missing, invalid or expired policy blocks new live advertising while gameplay and purchase rights remain available.

## Apple services and Watch

Optional Game Center sign-in sends the two ratings and achievements to Apple's service under Apple's privacy policy. ECHO's developer does not receive your Apple ID or contact details. Watch clears, rewards and remote controls pass between your paired devices through WatchConnectivity. The Watch target contains no advertising SDK or new advertising telemetry.

## Reports and contact

Report a bug opens your mail app with app version, device model and OS version. Report an inappropriate ad includes app version, placement, UTC and, when available, a limited ad diagnostic reference. Neither report includes receipts, raw signed transactions, advertising identifiers, route history or Archive answers. Nothing is sent unless you send the message.

Contact: [sergii.ziborov@gmail.com](mailto:sergii.ziborov@gmail.com). Published App Privacy answers, in-app text and website policy must be reconciled with the actual enabled configuration before release; the old advertising-free build's Data Not Collected declaration is not inherited by this SDK integration.
