# R1 evidence — 28 October 2026

Current cabinet changes and root-file deployment are recorded in [CABINET_SETUP_2026-10-28.md](CABINET_SETUP_2026-10-28.md). The initial read-only audit below predates those authorized changes.

## Scope

Implementation baseline: `740c8fc244823249eacf9e39eec35e407ccaa787` (`origin/main`, fetched 28 October 2026). The owner's 27 October specification governs this package. R1.1 rescue, new lore, new maps, progression changes, subscriptions, and paid content unlocks are excluded.

The original checkout contains unrelated uncommitted work. This task uses the managed `free-remove-ads` checkout based on main.

## Confirmed from source

- Swift 6, iOS 18, watchOS 11; XcodeGen `project.yml` is the project source.
- Main had no StoreKit, Mobile Ads or UMP imports/dependencies. New code stays under iOS-only `Echo/Monetization`; Watch compiles Shared and Simulation, not that directory. The default manifest excludes vendor adapters and SDK linking. `project-admob.yml` is an explicit same-target opt-in with a mandatory real App ID for Release.
- GameViewActions saves a win before presenting its result. The sole ad opportunity is explicit Next on a successful, ordinary solo campaign result. Death, Retry, Rewind, Daily and Deep Time do not enter an ad placement.
- Progress reset removes an explicit list of game keys, not a whole defaults domain. It already preserves audio/language and wrist progress. Purchase evidence is separate in Keychain; ad budget/preferences use their own keys.
- All existing recovered records are conservatively treated as protected discoveries. Reading/acknowledging a record does not remove protection from that result. Unknown new discoveries are protected by default.
- The Watch remote sets a sticky flag on the current attempt. Disconnecting does not clear it. No advertising code, telemetry or SDK is added to Watch.

## Confirmed read-only in App Store Connect

Read with the existing authorized API credential; no cabinet mutation was made.

- App `6811673094`, bundle `com.sergiiziborov.Echo`.
- Version 1.0.0: `READY_FOR_DISTRIBUTION` (legacy API state `READY_FOR_SALE`).
- Current base price: USD 1.99, no scheduled start/end date in the returned manual base-price record.
- In-app purchases endpoint returned an empty list. `com.sergiiziborov.Echo.removeAds` is therefore the proposed SKU, not a registered/approved product.

This does **not** establish historical promotions, every storefront's paid history, bank/tax completion, active contractual status, an approved cutover, or actual legacy-account purchase evidence. No cutoff is inferred from the audit date or build 18.

## Still external / not verified

- AdMob app/unit/publisher IDs, UMP messages, audience/children configuration and app-ads.txt crawl.
- Production signing public key / HTTPS policy endpoint and its log retention.
- Approved acquisition boundary, goodwill interval and complete paid/free history.
- Product creation, USD 1.99 price schedule, availability, first-IAP review, Family Sharing decision.
- Real account update/reinstall/second-device restoration; pending, refund and family tests on physical devices.
- Device performance, actual SDK traffic and corresponding App Privacy questionnaire.

## Verified API boundaries

Implementation checks the installed Xcode 27 StoreKit interface: `AppTransaction.shared` is async/throws; `refresh()` is explicit-user only; original build/date and environment are read from a verified transaction. AppTransaction has no fabricated price/storefront/refund property. The documented opaque AppTransaction ID (or a stable acquisition-field fallback) is hashed for local provenance. Raw JWS is not stored or logged. IAP transactions require the exact product and `.nonConsumable` type before delivery/finish.

Primary references (checked 28 October 2026): [Apple App Transaction](https://developer.apple.com/documentation/storekit/supporting-business-model-changes-by-using-the-app-transaction), [StoreKit 2](https://developer.apple.com/videos/play/wwdc2021/10114/), [AdMob setup](https://developers.google.com/admob/ios/quick-start), [interstitials](https://developers.google.com/admob/ios/interstitial), [UMP](https://developers.google.com/admob/ios/privacy), [SDK data disclosures](https://developers.google.com/admob/ios/privacy/data-disclosure), [publisher first-party ID](https://developers.google.com/admob/ios/privacy/strategies).

## Frozen save fixture

`EchoTests/Monetization/BaselineProgress.json` contains 15 native defaults keys with 77 maps and existing inventory/research. It was captured from the isolated simulator suite’s synthetic showcase, written through the unchanged baseline ProgressStore schema. It contains no personal, advertising or purchase evidence. It is a regression fixture, not a physical paid-account migration claim.
