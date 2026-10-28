# R1 privacy audit and release gate

Status: **BLOCKED for live advertising**. Including an SDK is not evidence that its traffic has been audited. Non-personalized requests do not mean no data collection. Do not retain the old App Privacy “Data Not Collected” answer for a future advertising release.

| Source | Configuration / possible data | Recipient / purpose | Verification |
| --- | --- | --- | --- |
| StoreKit 2 | Verified app acquisition and non-consumable transaction metadata; local provenance cache | Apple processes payment; app stores minimal evidence in device-only Keychain | API integration + fixtures; real account NOT RUN |
| Google Mobile Ads | Contextual `npa=1`; publisher first-party ID disabled; content rating G; no IDFA access request by ECHO | Google may receive IP/network, device, diagnostics and ad interaction data for delivery/measurement | Actual traffic, retention, subprocessors and App Privacy mapping BLOCKED |
| UMP | SDK-managed consent updates; options retained after purchase | Google / applicable consent framework | Actual messages, markets and child/audience settings BLOCKED |
| Signed policy endpoint | No device/account/query identifier; ephemeral HTTPS request | Hosting may log IP and user agent | Endpoint, actual log retention and owner key NOT CONFIGURED |
| WatchConnectivity | Existing controls, progress and wrist rewards | Paired user devices | No new monetization payload |
| Optional telemetry | None added | No custom analytics backend | Source audit PASS |
| Ad report | User-written message, app version, placement and UTC; no raw receipt, JWS, advertising ID or routes | Developer email; user sends manually | UI/code path; no automatic submission |

## Required before freeLive

1. Confirm real audience and Kids Category/age responses with the owner. No birth-date collection or made-up 13+ gate. Audience not reviewed means no production ad requests.
2. Inspect the pinned SDKs' privacy manifests and the app's Xcode privacy report. Verify purpose/data/linkage/tracking declarations against actual traffic and Google's current disclosures, including when consent is refused.
3. Verify context-only configuration works without cross-app tracking. ECHO does not request ATT or access IDFA. Do not add an alternate tracking identifier. If this configuration does not meet the intended no-tracking contract, keep ads off and review the design.
4. Configure UMP messages and supported markets in the real account. Test refusal, closure, changed choices, ATT denied/restricted, legacy and cold-start purchase paths.
5. Publish the actual provider/hosting policy and retention, update App Privacy, and capture a dated cabinet audit. Never assert compliance just because `npa=1` is set.
6. Configure a real publisher line in root `/app-ads.txt`, confirm the hostname extracted by AdMob from the App Store developer website and successful crawl. Do not publish a sample publisher ID. No domain purchase is authorized.
7. Verify that an ad-free cold start creates no advertising requests. An already running third-party SDK is not promised to unload; prior network processing is not reversed by buying Remove Ads.

Primary sources: [Google SDK disclosures](https://developers.google.com/admob/ios/privacy/data-disclosure), [UMP](https://developers.google.com/admob/ios/privacy), [Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/), [ATT](https://developer.apple.com/app-store/user-privacy-and-data-use/), [app-ads.txt](https://support.google.com/admob/answer/9363762).

The default `project.yml` build contains no ad SDK. `project-admob.yml` is the explicit SDK variant. This separation was added after a Release cold-start crash exposed Google’s automatic App ID validation before `start()`; Release of the SDK variant is now blocked without a real publisher App ID. The actual vendor-variant cold-launch traffic audit is still required.
