# ECHO free transition — 29 October 2026

**Download price: zero in all 175 configured territories. Approved 1.1.0 (27) remains released. Production advertising: OFF, signed freeQuiet v2. Corrected 1.1.1 (28): WAITING_FOR_REVIEW, available in Keepers TestFlight.**

The owner explicitly authorized finishing free download, rare advertising and one-time Remove Ads, and subsequently asked not to withdraw the approved App Store version. Build 27 was not cancelled or withdrawn. The owner chose **manual continuation after review**, not background monitoring or automatic live-ad activation. No automation was created. The new version's configured release type remains AFTER_APPROVAL; this is distinct from the signed live-ad switch.

## Executed and verified

| Action or check | Result / evidence |
| --- | --- |
| Zero-price schedule | **PASS**: accepted 2026-10-29T13:40:28.052158Z; USA base point zero, 174 automatic territories zero. No territorial availability restriction added. FREE_PRICE_2026-10-29.json |
| Public Store | **PASS US**: actual browser shows 1.1.0, Free · In-App Purchases, new EN promotional text and current privacy categories. Public lookup also reports free in DE/FR/JP/CA/UA; initial IL/GB lookup still cached the previous price/version, so worldwide propagation is not fabricated. FREE_PUBLIC_STOREFRONTS_2026-10-29.json |
| Remove Ads | **PASS**: existing product 6828008885 / com.sergiiziborov.Echo.removeAds, NON_CONSUMABLE, APPROVED, base USD 1.99 with localized StoreKit pricing. No duplicate SKU or subscription; no Family Sharing change |
| AdMob | **PASS CONSOLE**: ECHO Ready, ad serving enabled, one active interstitial unit. Account also approved. Publisher/app/unit unchanged; root app-ads.txt matches the real publisher |
| App Privacy | **PASS PUBLISHED**: all seven categories completed. Linked: Coarse Location, Device ID, Product Interaction, Advertising Data. Unlinked: Crash, Performance, Other Diagnostics. No cross-app tracking use declared for this restricted configuration. Public US page independently shows the updated categories |
| Data purposes | Advertising/interaction/device categories: third-party advertising and analytics; Coarse Location, Product Interaction and Performance also app functionality (UMP). Crash: analytics. Other diagnostics: third-party advertising/analytics. No developer first-party marketing purpose added |
| SDK configuration | **PASS SOURCE/ARCHIVE**: Google Mobile Ads 13.11.0 and UMP 3.1.0, only iOS. Personalization and publisher first-party ID disabled; child-restricted treatment and General creatives. ECHO does not request ATT/IDFA. Watch archive has no AdMob App ID. These facts do not claim complete regional traffic observation |
| Advertising declaration | **PASS DRAFT / WAITING REVIEW**: released declaration was locked (Apple 409). Created 1.1.1 with advertising=true, kidsAgeBand=null, preserved category/content answers. Old version remains released |
| Purchase/cohort/navigation/save tests | **PASS: 36, zero failures/skips** on an isolated iOS 26.5 Simulator using stable Xcode 27.1. Includes explicit goodwill-free-build, immutable grant and old-policy JSON compatibility checks. CUTOVER_TESTS_28.json |
| 1.1.1 (28) archive/export/validation/upload | **PASS**: source 62c2f3f, phone and Watch both 1.1.1 (28), production guard live=false, no errors. IPA 41,699,685 bytes; SHA256 44a2ce3ed5a4cb600ade2d4e31fc5d9d73238b98d419dd76a6d4d65739ccd514 |
| TestFlight 28 | **PASS**: VALID, IN_BETA_TESTING, Keepers membership and EN/RU beta notes read back |
| Review 28 | **PASS submitted**: 000de90f-3771-4802-b207-732c88f47321, WAITING_FOR_REVIEW; application version 7ddefcbd-f211-468c-a392-d22c268dd46e. Submitted 2026-10-29T14:17:12.91Z. APP_REVIEW_28_2026-10-29.json |
| Listing and media | **PASS**: current EN/RU free promotional text saved/read back. New 1.1.1 descriptions/What's New and privacy-choice URLs saved. All 64 screenshots, 2 previews and 4 header/search placements cloned and ACTIVE. No new claim that generated artwork is gameplay |
| Site/legal/SEO | **PASS**: public Site v15, source 324ed19496a32274c3ff3dbde01ac74cba683640, deployment appgdep_6ae351e88e9481919ab6bdc72c563c11. Fourteen EN/RU pages passed links/assets/metadata checks. Homepage/FAQ/press/legal copy now describes free download and optional Remove Ads; structured offer price is zero |
| Signed production policy | **PASS**: public v2 freeQuiet fetched and signature independently verified against the key compiled into build 27. The real app-ads line remains HTTP 200 / matching. FREE_QUIET_DEPLOYMENT_2026-10-29.json |

## Earlier acquisitions

The owner reports that there had been no paid buyers. This is OWNER_REPORTED, not a claimed independent sales-report audit. Protection remains implemented. Paid builds 18 and 27 were observed publicly before the price change. The 48-hour propagation/goodwill boundary is **2026-10-31T13:40:28Z**. A separate `goodwillBuilds: ["28"]` deliberately protects initial free acquisitions of the new version without misreporting it as historically paid. Unknown evidence remains ad-free; already granted legacy rights are retained. Sandbox/Xcode dates do not create production legacy. See CUTOVER_LEDGER.md.

The goodwill window means some first free users also retain ad-free access. After the boundary, conclusive new free acquisitions may use the ad-supported model only when freeLive is explicitly enabled and every contextual/cadence/privacy gate passes. Core game content and balance are unchanged. Retry/Rewind, the first five maps, discoveries, region ends, Daily, Deep Time, Watch and Watch remote remain protected.

## Remaining manual step after review

1. Read back 1.1.1 approval/release and the corrected advertising declaration. Preserve the already released 27, zero-price schedule, approved IAP and consumer progress.
2. Recheck publisher readiness, public policy and privacy declaration. No new contract, Family Sharing, global publisher-ID deletion or account permission is authorized by this step.
3. Publish a higher-version signed **freeLive** policy with the same approved acquisition boundary and baked-in limits: 3 eligible wins, 240 active solo seconds, at most 2 interstitial starts per rolling 24 hours, no rewarded/banner/app-open. Mark audience reviewed based on the recorded restricted configuration and corrected declaration; do not manufacture missing test results.
4. Re-fetch and verify the deployed envelope, check the runtime free/ad-free paths and report actual results. Existing ad-free rights must suppress SDK requests. Offline/no-fill/uncertainty must continue normally.

Policy v2 expires 28 November 2026. Expiry stops new ad requests; it does not expire purchases or gameplay. Renew/replace the policy before then if ongoing advertising is desired. Emergency rollback is a higher-version signed adsOff policy; never make the app paid again as a rollback.

## Limits not disguised as completion

Physical purchase/cancellation/restore were executed earlier on build 24 (restore owner-reported); build 27 save and ad-free diagnostics were independently read. No new hardware purchase or reinstall was performed for build 28. Original-owner reinstall/second device, physical iPad/Watch, pending/refund, complete regional consent/refusal traffic and exact hosting-log retention remain NOT RUN/NOT VERIFIED as appropriate. Console readiness, static configuration, simulator tests and review submission do not prove those scenarios. The redundant altool build-status endpoint returned Apple HTTP 500 and was stopped; the later public build API independently confirmed VALID and the successful upload was not repeated.

No live ad was requested or clicked for testing. No live flag, price increase, gameplay balance change or forced paid upgrade was introduced. The SDK-free default project was regenerated after archiving; the shipping archive used the explicit project-admob.yml manifest.
