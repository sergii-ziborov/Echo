> **Latest owner instruction, 29 October 2026:** live policy v3 is now published and independently verified; 38 domain checks PASS. This supersedes the earlier manual-after-review hold. Approved 27 remains published; corrected 28 is still WAITING_FOR_REVIEW and was not cancelled. Review Notes were updated to disclose activation now. Rights, 48-hour protected acquisition window and ad limits are unchanged. [Activation evidence](LIVE_ACTIVATION_2026-10-29.md).

> **29 October update:** the owner now explicitly authorized the free-price transition and live activation after checking the remaining conditions. Zero download price was accepted in all 175 territories at 13:40 UTC; build 27 remains released. Current phase is freeQuiet. See CUTOVER_LEDGER.md. The historical instructions below do not revoke this later authorization. The published version’s advertising age declaration was locked, so 1.1.1 is being prepared with advertising=true; live ads remain disabled until its approval.

# R1 release runbook

This branch implements the owner's free + rare interstitial + one non-consumable contract. **It does not authorize changing the live price or submitting to App Store Review.** The production default is `preFree`; there is no approved acquisition cutoff or permission for live ads. Actual publisher IDs and the signed HTTPS policy endpoint/public key are configured; see the cabinet record.

The owner authorized internal TestFlight uploads: **1.1.0 (24)** is now available in Keepers with the iOS SDKs and actual publisher configuration. Production remains preFree. [TESTFLIGHT_24.md](TESTFLIGHT_24.md) records delivery, what can be tested and remaining limits. Build 23 is the earlier SDK-free preparation build.

## Build-time configuration

`project.yml` is the safe default: it excludes both vendor adapters and links no advertising SDK. Run `xcodegen generate` for this SDK-free preFree build. Keep `Package.resolved`; dependencies remain pinned for the explicit variant.

`xcodegen generate --spec project-admob.yml` opts the **same Echo target and bundle ID** into the SDK, adds `ECHO_ADMOB` and includes the two adapters. Debug uses the official Google test app ID. An AdMob **Release** build fails before app compilation unless a real well-formed App ID is configured; it never substitutes a sample. Pass the `ECHO_ADMOB_APP_ID` build setting explicitly, or set `ECHO_ADMOB_APP_ID_FROM_ENV` for Xcode Cloud. `ECHO_BUILD_ADS=1` selects this manifest in `ci_post_clone.sh`; default Cloud builds remain SDK-free. This is not a second app.

The first full R1 review candidate must use the AdMob variant after publisher setup; the default SDK-free binary cannot remotely gain an advertising SDK and does not offer a production repurchase. Do not submit a quiet binary while claiming that its advertising integration is ready. SDK dependencies and metadata belong only to Echo iOS, never Shared/Simulation/Watch.

- `ECHO_ADMOB_APP_ID`: used only by the opt-in AdMob variant. Debug uses Google’s official test app ID; Release requires the owner’s real App ID.
- `ECHO_INTERSTITIAL_UNIT_ID`: empty by default; no production test-ID fallback.
- `ECHO_RELEASE_POLICY_URL` / `ECHO_RELEASE_POLICY_PUBLIC_KEY`: configured to the signed preFree endpoint in `project.yml`. Use HTTPS and the base64 raw Ed25519 public key (32 bytes). The private key stays outside the repo/app.
- Banners, app-open, rewarded and mediation are absent. R1.1 rescue is not implemented or advertised.

## Signed policy format

The HTTPS document is `{ "payload": "<base64 exact UTF-8 JSON>", "signature": "<base64 Ed25519 signature over those bytes>" }`. Payload dates are ISO 8601 UTC. Schema 1 includes `version`, `phase`, `issuedAt`, `expiresAt`, approved `cutover`, `audienceReviewed`, `familySharingEnabled`, and `limits`.

`cutover` has `id`, `approved`, `legacyEligibilityEnd`, `rolloutUncertaintyEnd` and the verified `paidBuilds` list. Use the completed owner-approved acquisition ledger; **never copy a fixture date**. Invalid/expired/missing/unknown/rollback policy suppresses new production ads. A policy cannot add placements or lower the baked-in spacing / raise the caps. Legacy grants are not revoked by a narrowed policy. Test policy is selected only by verified Sandbox/Xcode StoreKit environment, never a reviewer identity or IP.

## Order of operations — owner-controlled gates

1. Complete `CUTOVER_LEDGER.template.md` from actual price/distribution history. Decide the goodwill interval. The initial read-only audit found no IAP; the later authorized setup created exactly one.
2. The single configured non-consumable uses ID `com.sergiiziborov.Echo.removeAds`. EN/RU, base USD 1.99 and all 175 territories are configured; approval/review screenshot remain. Do not enable irrevocable Family Sharing without explicit owner approval.
3. Configure real AdMob app/unit/publisher, UMP messages/markets/audience, family-appropriate filtering, and root app-ads.txt. Verify the actual hosting hostname and network crawl. No domain purchase is authorized.
4. Complete the traffic/device/privacy audit. Update App Privacy answers from the real SDK behavior; the historical Data Not Collected answer is not inherited.
5. Run StoreKit Testing, real Sandbox/TestFlight purchases, pending, refund, offline, previous paid account update/reinstall/another device, Watch remote, iPad and accessibility smoke tests. Mark actual results, never infer hardware PASS from simulator fixtures.
6. Submit the binary and first non-consumable together **only after owner action**. Attach a purchase screenshot and honest Review Notes. Keep production `preFree` while paid; the Sandbox path uses the same UI, real Sandbox transactions and test creatives.
7. After approval release the compatible binary in `preFree`, then schedule Free in App Store Connect with owner approval. Observe storefront propagation and record the actual window.
8. Publish an approved, valid `freeQuiet` policy: no live ads. Verify old and new acquisition accounts and product availability. Only then publish `freeLive` with reviewed audience and valid live IDs.
9. Publish the prepared free-phase listing, website, privacy, terms and press copy. Keep the same App Store ID and brand. Set website download price to zero only after actual Free; do not invent ratings.

## Test path

Open `EchoTests/Monetization/RemoveAds.storekit` in Xcode and select it in the Echo Run scheme's StoreKit Configuration for local testing. It is a fixture, not a cabinet product. Test `.pending`, cancellation, purchase, duplicate updates, refund and restore. Release production is not assigned a testing configuration. TestFlight/Sandbox require the real configured SKU and ad app ID before end-to-end tests can pass.

Normal path: Settings → Ads and Purchases → Remove Ads / Restore Purchases. Production `preFree` displays its protected status and offers no second payment. A verified Sandbox/Xcode acquisition tests the free cohort; its artificial original date never grants legacy. A verified IAP disables all future test advertising too.

## Recovery

Publish a higher-version signed `adsOff` policy to disable new requests/presentations while preserving game and purchase rights. Endpoint/signature/expiry failure also suppresses new ads. An already displayed third-party creative ends through its SDK lifecycle. A crash caused by SDK load can require a corrected binary; a remote flag is not promised to repair startup code. Do not revert the app to paid as a bug workaround.

After an SDK-enabled release, keep that variant when shipping an `adsOff` fix so existing purchasers can still open the provider's privacy options. The SDK-free default is a preparation build before that rollout, not a replacement for the privacy controls of an already deployed advertising version.

## Review Notes (draft, update before submission)

The app is transitioning from paid to free with one non-consumable Remove Ads. Original acquisitions in our approved protected period remain ad-free, including after restoration; gameplay and content are not paid-gated. Production remains preFree until the price transition is confirmed. Verified Sandbox uses the ordinary Settings purchase/restore UI and test interstitials with the same strict cadence and protected contexts. Interstitials occur only on explicit Next after eligible solo campaign wins: never maps 1–5, death/retry/rewind, discoveries, region ends, Daily, Deep Time, Watch or Watch-controlled sessions. The signed configuration is data-only and can reduce frequency or disable ads; it cannot add placements or change gameplay. No reviewer-specific bypass exists. No live advertising is enabled before the published gates. Update these notes to actual configured facts; this draft is not a claim of a successful end-to-end review test.

## Startup failure found and prevented

A Release cold-start smoke test found that the linked Google SDK runs `GADApplicationVerifyPublisherInitializedCorrectly` before our explicit start call and aborts with an empty App ID. The corrected default manifest excludes the SDK completely. The opt-in SDK Release manifest validates real bootstrap configuration at build time. A remote policy cannot repair a +load crash; never weaken this gate or fill Release with a test ID.
