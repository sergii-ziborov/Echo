# R1 privacy audit and release gate

Status: **BLOCKED for live advertising**. Including an SDK is not evidence that its traffic has been audited. Non-personalized requests do not mean no data collection. Do not retain the old App Privacy “Data Not Collected” answer for a future advertising release.

| Source | Configuration / possible data | Recipient / purpose | Verification |
| --- | --- | --- | --- |
| StoreKit 2 | Verified app acquisition and non-consumable transaction metadata; local provenance cache | Apple processes payment; app stores minimal evidence in device-only Keychain | API integration + fixtures; real account NOT RUN |
| Google Mobile Ads | Contextual `npa=1`; publisher first-party ID disabled; content rating G; no IDFA access request by ECHO | Google may receive IP/network, device, diagnostics and ad interaction data for delivery/measurement | Actual traffic, retention, subprocessors and App Privacy mapping BLOCKED |
| UMP | SDK-managed consent updates; options retained after purchase | Google / applicable consent framework | European EN/RU form published, exact list read-back; Google-only vendor and restrictive consent settings saved. US form and real-account regional presentation remain BLOCKED/NOT RUN |
| Signed policy endpoint | No device/account/query identifier; ephemeral HTTPS request | Hosting may log IP and user agent | Signed HTTPS preFree endpoint/key configured 28 October; actual host log retention NOT VERIFIED. See CABINET_SETUP_2026-10-28.md. |
| WatchConnectivity | Existing controls, progress and wrist rewards | Paired user devices | No new monetization payload |
| Optional telemetry | None added | No custom analytics backend | Source audit PASS |
| Ad report | User-written message, app version, placement and UTC; no raw receipt, JWS, advertising ID or routes | Developer email; user sends manually | UI/code path; no automatic submission |

## Required before freeLive

1. Read-only App Store Connect returns rating 9+, kidsAgeBand=null and advertising=false. Confirm actual audience and update the eventual advertising release’s age answers with the owner. No birth-date collection or made-up 13+ gate. Audience not reviewed means no production ad requests.
2. Inspect the pinned SDKs' privacy manifests and the app's Xcode privacy report. Verify purpose/data/linkage/tracking declarations against actual traffic and Google's current disclosures, including when consent is refused.
3. Verify context-only configuration works without cross-app tracking. ECHO does not request ATT or access IDFA. Do not add an alternate tracking identifier. If this configuration does not meet the intended no-tracking contract, keep ads off and review the design.
4. Configure UMP messages and supported markets in the real account. Test refusal, closure, changed choices, ATT denied/restricted, legacy and cold-start purchase paths.
5. Publish the actual provider/hosting policy and retention, update App Privacy, and capture a dated cabinet audit. Never assert compliance just because `npa=1` is set.
6. Real publisher line is published at the existing developer website's root `/app-ads.txt` and matches the console. Google verification still returns failure after retry; successful crawl remains required. Do not equate HTTP 200 with Google acceptance. No domain purchase is authorized.
7. Verify that an ad-free cold start creates no advertising requests. An already running third-party SDK is not promised to unload; prior network processing is not reversed by buying Remove Ads.

Primary sources: [Google SDK disclosures](https://developers.google.com/admob/ios/privacy/data-disclosure), [UMP](https://developers.google.com/admob/ios/privacy), [Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/), [ATT](https://developer.apple.com/app-store/user-privacy-and-data-use/), [app-ads.txt](https://support.google.com/admob/answer/9363762).

The default `project.yml` build contains no ad SDK. `project-admob.yml` is the explicit SDK variant. This separation was added after a Release cold-start crash exposed Google’s automatic App ID validation before `start()`; Release of the SDK variant is now blocked without a real publisher App ID. The actual vendor-variant cold-launch traffic audit is still required.

## Actual build-24 manifest inspection

[SDK_PRIVACY_MANIFESTS_24.json](SDK_PRIVACY_MANIFESTS_24.json) is the exact plist-to-JSON extraction from the distribution archive. Google declares potential device-ID tracking plus linked coarse location, ad data and interactions; diagnostics/performance are also declared. UMP declares coarse location, performance and interactions for app functionality. Watch declares only its existing required-reason UserDefaults API. No vendor manifest was edited. This is a source disclosure inspection, not proof of runtime data collection or its absence.

The public EN/RU privacy and terms pages were updated in Site version 8 to cover the transition beta while identifying 1.0.0 as the current paid, advertising-free public release. No fictional hosting retention period is asserted.

The opt-in Simulator SDK smoke now confirms a real UMP update followed by an allowed official test-creative request and discard. See AD_NETWORK_VERIFICATION.json. It does not exercise ECHO's real-account regional forms, production tracking/refusal behavior or physical-device traffic, so those gates remain open.
