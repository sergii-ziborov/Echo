# R1 cabinet setup — 28 October 2026

This records actual cabinet changes after the owner requested completion. It does not declare R1 ready or enable live advertising.

## App Store Connect

| Check | Result |
| --- | --- |
| Existing app availability | **PASS**: all 175 returned territories available; new territories enabled. Israel is not an app-distribution restriction. |
| One non-consumable | **PASS**: `6828008885`, `com.sergiiziborov.Echo.removeAds`; created once and read back. |
| English / Russian metadata | **PASS**: Remove Ads / Отключить рекламу, localized one-time-purchase descriptions. |
| Price / availability | **PASS**: real Apple US $1.99 price point selected, schedule created; all 175 territories and future territories enabled. Localized UI prices still come from StoreKit. |
| Family Sharing | **PASS**: read-back `familySharable=false`; irreversible enablement not performed. |
| IAP review instructions | **PASS**: purchase/restore and production/Sandbox behavior saved in the product and read back exactly. No submission performed. |
| IAP approval | **BLOCKED**: read-back `MISSING_METADATA`; real review screenshot and submission with a complete app candidate remain. |
| Public app / price | **PASS**: US listing still 1.0.0, $1.99; no Free transition or submission performed. |

The product is configured, not approved. Historical paid/free promotions and the acquisition cutover are still unverified; no cutoff was invented.

## AdMob and developer website

The owner completed the account's payment-country and agreement steps. Account review was visibly pending in AdMob. Payment country identifies the payment recipient and does not restrict ECHO's App Store availability.

ECHO was already added by the owner. Its wizard reported app-ads.txt verification failure. No duplicate app was created.

The exact line displayed by AdMob is now published:

```text
google.com, pub-7387441604864948, DIRECT, f08c47fec0942fa0
```

| Check | Result |
| --- | --- |
| Developer website | **PASS**: public App Store lookup returns `https://echo-survive-your-past.serhiiright.chatgpt.site/`. |
| Root file | **PASS**: [app-ads.txt](https://echo-survive-your-past.serhiiright.chatgpt.site/app-ads.txt), HTTP 200, `text/plain`, zero redirects, exact publisher line. Checked 2026-10-28 after publication. |
| Site deployment | **PASS**: existing public Site version 6, source `7ad1a46926ed4c025b7e80b04d27e1ca9574fd72`; native deployment `appgdep_6ae2077c59a88191b3838c0c91b29ff1` succeeded at 14:32:47 UTC. All 14 localized pages, links and assets passed the site's verification. |
| Google recrawl / app verification | **BLOCKED**: after console access resumed, Check for Changes was retried on the existing app's verification page. The page re-rendered the same failure; no successful verification is claimed. Google documents up to 24 hours for crawl/status updates. Early click attempts made while Chrome control failed were not counted as accepted requests. |
| Google account approval | **PENDING** in the last observed Home screen; not a completed review. |
| App ID | **PASS**: existing ECHO app `ca-app-pub-7387441604864948~4899495427`, linked to App Store 6811673094. |
| Interstitial unit | **PASS**: created exactly one `campaign_result_to_next`, `ca-app-pub-7387441604864948/9838007664`. Saved list read-back confirms standard interstitial, 1–1 of 1, unit cap **2 impressions / 24 hours**; no campaigns or mediation groups. Creation does not enable production requests. |
| High-engagement ads | **PASS**: disabled and saved in ECHO's app settings; reopened editor reports OFF. This avoids the console option for extra steps/time before closing fullscreen ads. |
| Publisher first-party ID (console) | **PASS owner preference**: account-wide setting remains ON. Owner explicitly declined irreversible account-wide deletion and chose the per-app ECHO prohibition. Confirmation was never accepted; subsequent read-back shows ON with no dialog. The SDK disables first-party ID before start. Analytics linking and surveys are visibly OFF. |
| UMP European form | **PASS published**: ECHO only, EN default + RU, policy URL set, refusal in every region and close-without-consent ON. Published via the list’s Publish switch and confirmation; subsequent row reports **Опубликовано**. Actual regional presentation on device still NOT RUN. |
| UMP European settings | **PASS saved**: fixed Google-only vendor list (755), automatic partners and fallback/maximized-message coverage OFF, RTB consent checking ON, legitimate-interest default OFF. Advertising consent mode and special feature 2 remain OFF. Actual SDK consent/traffic audit remains NOT RUN. |
| Age declaration | **PASS read-only**: current App Store rating 9+, `kidsAgeBand=null`, `advertising=false`. No category/age changes were made. A low rating alone is not proof of audience compliance; advertising answers must be updated for the eventual live version. |
| Production ads | **OFF**: SDK-enabled TestFlight **1.1.0 (24)** is available in Keepers; production remains preFree. [Delivery evidence](TESTFLIGHT_24.md). The earlier 23 remains SDK-free. |

The deployed website's current source was opened through Sites at `/Users/serhiirihgt/.codex/sites/echo-r1-release`; the repository's older website mirror was not deployed over it. The mirror now retains the same publisher file for future builds.

Public App Store lookup in Israel, the US and the UK returned the same developer hostname. Current listing prices remained ILS 4.90 / USD 1.99 / GBP 1.99 respectively. These current prices do not establish historical acquisition eligibility.

## Signed release policy

**PASS deployment and signature verification**: [monetization-policy.json](https://echo-survive-your-past.serhiiright.chatgpt.site/monetization-policy.json) is HTTP 200 / `application/json`. Public Site version 7, source `5538c0642f711308ee386dde54c648d2d06c08cf`, deployment `appgdep_6ae20c8b995081919fd10a247f971bec` succeeded at 14:54:20 UTC. The app-ads.txt file remains HTTP 200 / `text/plain`, exact contents, no redirects after this deployment.

- Policy v1: `preFree`, issued `2026-10-28T14:52:50Z`, expires `2026-11-04T14:52:50Z`.
- `audienceReviewed=false`, `familySharingEnabled=false`, no cutover field. There is no invented legacy date and no production ad permission.
- Ed25519 key generated with CryptoKit; private key stored outside all repositories with mode 0600. Only its public key is in XcodeGen/build settings. The existing signing tool signs exact payload bytes. The served envelope's signature was independently verified.
- URL and public key are now bound in `project.yml`; actual App/Unit IDs are in the explicit SDK manifest. These are source changes, not an update of the already uploaded SDK-free build 23.
- Invalid, unreachable or expired policy still suppresses production advertising. Future live activation requires the outstanding cutover, privacy, account approval and device gates. Hosting log retention remains **NOT VERIFIED**.

Google verification and account review are separate. A publicly reachable file does not prove that Google's crawler has accepted it. See [Google's setup instructions](https://support.google.com/admob/answer/9363762) and [status meanings](https://support.google.com/admob/answer/9788846).

## Device and regression work

- **PASS backup**: physical iPhone 13 mini, iOS 26.5, Echo 1.1.0 (23). Its actual preferences were copied before testing to an owner-private directory, permissions 0600. No personal save was committed. Backup SHA256: `98ade132c47df59573495438f9903000998a27de5423052c68265d46c85a88d9`.
- **NOT RUN**: real purchase, legacy reinstall, Watch/iPad hardware and SDK traffic checks. Reading device metadata and taking a backup do not satisfy these gates.
- Added an offline path guard before consent, preparation and presentation; losing connectivity invalidates a ready creative. It uses NWPathMonitor without contacting a server.
- A verified family transaction conflicting with the release's Family Sharing setting now remains unresolved and ad-free instead of classifying the family member as free.
- **PASS: 31 tests, zero failures/skips** in PurchaseTests, PurchaseServiceTests, AdPolicyTests and CoordinatorTests, Xcode 27.1 (27A9275), iPhone 17 Pro Simulator / iOS 26.5. Result: `/tmp/echo-r1-completion/policy-regression.xcresult`. Sanitized summary: [CABINET_SETUP_VERIFICATION.json](CABINET_SETUP_VERIFICATION.json).
- **BLOCKED native StoreKit**: an initial run passed the same 31 selected tests, then the native configuration service failed and product lookup stalled. That run was cancelled, not declared successful. Native local StoreKit and genuine Sandbox purchases remain separate from unit fixtures.
- **PASS SDK Release Simulator build** using real App/Unit IDs and the signed-policy URL/public key, Xcode 27.1 (27A9275). Log: `/tmp/echo-r1-completion/sdk-release-build.log`. Built Info.plist matches those exact values, measurement initialization is delayed, and Watch has no ad configuration or imports. This build-23 simulator binary was **not uploaded** and does not replace TestFlight 23.
- **PASS cold launch**: SDK Release on a newly created, isolated iPhone 17 Pro / iOS 26.5 Simulator. Process 45017 remained alive after **183.6 seconds**; [native capture](screenshots/sdk-release-cold-start.png) shows the rendered intro with Tap to Enter. This proves launch/rendering, not real purchase, ad presentation, hardware performance or absence of network traffic. The owned simulator is cleaned up after capture. The prior focused-test simulator was no longer registered; an attempted iOS 27.1 Duo failed initial migration. The successful 26.5 device finished migration; a launch attempted before that finished timed out and was retried after boot completion.

Verification commands (run in the Echo worktree, with stable Xcode selected only for these commands):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project Echo.xcodeproj -scheme Echo -configuration Debug \
  -destination 'platform=iOS Simulator,id=AE7E8883-12F0-4B92-8828-5648512477ED' \
  -derivedDataPath /tmp/echo-r1-completion/dd-sim \
  -resultBundlePath /tmp/echo-r1-completion/policy-regression.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 30 \
  -maximum-test-execution-time-allowance 60 \
  -only-testing:EchoTests/PurchaseTests -only-testing:EchoTests/PurchaseServiceTests \
  -only-testing:EchoTests/AdPolicyTests -only-testing:EchoTests/CoordinatorTests \
  CODE_SIGNING_ALLOWED=NO
python3 website/build.py
python3 website/verify.py
git diff --check
```

The repository mirror passed its 12-page check; the newer canonical hosted source separately passed its 14-page check before publication. The differing page counts are intentional source versions, not a claim that the older mirror replaced the live site.

## Completion update — TestFlight 24 and public legal pages

**PASS**: SDK-enabled build 24 archived, exported, server-validated and uploaded with stable Xcode. Apple reports VALID / INTERNAL_ONLY / IN_BETA_TESTING; Keepers includes it and EN/RU notes were read back. The modern validation endpoint returned HTTP 500; the official legacy altool path completed validation/upload. [TESTFLIGHT_24.md](TESTFLIGHT_24.md) records the exact source SHA, IPA hash and commands.

**PASS**: public Site version 8, source `0e23dd2735364242d589600a67d27355b76ede62`, deployment `appgdep_6ae2191ba8788191a0457a8c9c392170`, succeeded `2026-10-28T15:47:55Z`. EN/RU privacy and terms now explain the current paid public release, the SDK-enabled transition beta, StoreKit, future advertising and signed-policy connection. Public price/brand/marketing remain unchanged. All 14 canonical pages passed links/metadata/assets verification; repository mirror passed 12 pages.

**PASS inspection, not compliance certification**: exact privacy manifests from the archived app, Google 13.11.0, UMP 3.1.0 and Watch are retained in [SDK_PRIVACY_MANIFESTS_24.json](SDK_PRIVACY_MANIFESTS_24.json). Google declares potential device-ID tracking, linked coarse location, ad data and interactions plus diagnostics/performance; UMP declares coarse location/performance/interactions for functionality. ECHO's restrictive request flags do not erase these vendor disclosures or prove their actual network behavior. App Privacy mapping and device traffic tests remain NOT RUN.

**UI limitation, partly resolved below**: native Chrome control returned `noWindowsAvailable`, ScreenCaptureKit -3812 and intermittent non-reacting clicks. European publication and fresh account read-back were subsequently completed and are recorded below. US-state form and fresh successful app verification remain unconfirmed. The owner answered the mechanical-click request; no unanswered approval is claimed.

## Native SDK network smoke

**PASS: 1 test, 0 failures/skips**, Xcode 27.1, isolated iPhone 17 Pro / iOS 26.5 Simulator. Actual UMP update completed, `canRequestAds` allowed the request, and the real AdMobProvider loaded the official Google test interstitial. Discard cleared readiness; presenting the discarded object failed immediately with one completion and no started callback. No mock privacy/readiness or live ad unit was substituted. [Sanitized result](AD_NETWORK_VERIFICATION.json).

This verifies adapter networking and cancellation, not a visible fullscreen presentation/dismissal, choices in ECHO's real-account UMP form, real StoreKit, production data collection or hardware. StoreKit AppTransaction reported a Simulator service error independently; no production legacy right was fabricated. The initial network-test launch was correctly SKIPPED because Xcode inherited the Run environment instead of the dedicated Test environment; the helper now explicitly disables that inheritance. The corrected run is the PASS above. Both owned SDK smoke simulators were removed; archives/IPAs, results and private phone backup were retained.

Reproduce using a newly created isolated simulator (never the owner's phone):

```sh
python3 scripts/test_admob_network.py --simulator <isolated-simulator-UUID> \
  --derived-data /tmp/echo-ad-network-derived \
  --result /tmp/echo-ad-network.xcresult
```

The helper selects the explicit SDK Debug variant and official test App ID, creates an opt-in test scheme, and restores the safe default generated project on exit. Normal unit runs do not initiate this network test.

**Physical status read-back**: the connected iPhone still reports 1.1.0 (23). It was not deleted, overwritten or reset. The original private backup's SHA256 still matches. Update-to-24 data retention and purchases are therefore NOT RUN, rather than inferred from an upload.

## Latest AdMob registration and EU publication read-back

**PASS configuration submitted, approval PENDING**: Home explicitly reports “Ваш платежный профиль готов” and “Ваш аккаунт находится на проверке”. There is no displayed request for more payment-profile data. Google's welcome email dated 28 October confirms publisher `pub-7387441604864948`; the focused mailbox search returned no approval email. A welcome email is not treated as approval. No email was sent or subscribed to.

**PASS EU message publication**: the editor's header button could not be operated reliably, so the existing message’s Publish switch in the list was used. Google displayed “Сообщение готово к публикации”; the native confirmation was accepted after confirming the app has UMP/privacy options. The returned list reports **Опубликовано** for ECHO — European privacy choices. This is distinct from AdMob account/app approval.

US-state message work remains incomplete. Google supports English/Spanish variants for this message type; a Russian US template is not invented. See [Google's supported languages](https://support.google.com/admob/answer/10107561) and [US message setup](https://support.google.com/admob/answer/10860309).

The Mac temporarily fell to 116 MiB free, and screen capture reported failed image destination. Only this task’s temporary DerivedData directories were removed; free space recovered to approximately 2 GiB. Archives, IPAs, result bundles and the private phone backup remain. Intermittent ScreenCaptureKit/noWindowsAvailable errors still occur. The temporary in-app browser attempt returned a stale-tab/session error and its inventory was empty; no separate login was attempted.

The latest attempt to finish US settings again failed to switch from another Chrome window to the existing AdMob window: selecting Google AdMob in the native Window menu left the active window unchanged, and one attempt returned ScreenCaptureKit -3811. Rebinding/resetting CUA and raising the window did not restore reliable input. The Chrome browser adapter also returned `Browser is not available: chrome`. No hidden browser API, alternate UI automation or account-wide first-party-ID deletion was used. A click in the US vendor panel before focus was lost has no verified outcome; no US vendor-list save or message publication is claimed.
