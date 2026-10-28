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
| Google recrawl / app verification | **BLOCKED**: not confirmed. Chrome control stopped responding; subsequent native capture failed with `noWindowsAvailable` / ScreenCaptureKit capture error. A click attempt without a visible state change is not counted as an accepted request. Owner asked to unlock Mac. |
| Google account approval | **PENDING** in the last observed Home screen; not a completed review. |
| App ID / interstitial unit / UMP | **NOT RUN**: retrieve the existing app and configure one interstitial once console control resumes. No live IDs invented. |
| Production ads | **OFF**: shipped TestFlight 1.1.0 (23) remains SDK-free, production preFree. |

The deployed website's current source was opened through Sites at `/Users/serhiirihgt/.codex/sites/echo-r1-release`; the repository's older website mirror was not deployed over it. The mirror now retains the same publisher file for future builds.

Google verification and account review are separate. A publicly reachable file does not prove that Google's crawler has accepted it. See [Google's setup instructions](https://support.google.com/admob/answer/9363762) and [status meanings](https://support.google.com/admob/answer/9788846).

## Device and regression work

- **PASS backup**: physical iPhone 13 mini, iOS 26.5, Echo 1.1.0 (23). Its actual preferences were copied before testing to an owner-private directory, permissions 0600. No personal save was committed. Backup SHA256: `98ade132c47df59573495438f9903000998a27de5423052c68265d46c85a88d9`.
- **NOT RUN**: real purchase, legacy reinstall, Watch/iPad hardware and SDK traffic checks. Reading device metadata and taking a backup do not satisfy these gates.
- Added an offline path guard before consent, preparation and presentation; losing connectivity invalidates a ready creative. It uses NWPathMonitor without contacting a server.
- A verified family transaction conflicting with the release's Family Sharing setting now remains unresolved and ad-free instead of classifying the family member as free.
- **PASS: 31 tests, zero failures/skips** in PurchaseTests, PurchaseServiceTests, AdPolicyTests and CoordinatorTests, Xcode 27.1 (27A9275), iPhone 17 Pro Simulator / iOS 26.5. Result: `/tmp/echo-r1-completion/policy-regression.xcresult`. Sanitized summary: [CABINET_SETUP_VERIFICATION.json](CABINET_SETUP_VERIFICATION.json).
- **BLOCKED native StoreKit**: an initial run passed the same 31 selected tests, then the native configuration service failed and product lookup stalled. That run was cancelled, not declared successful. Native local StoreKit and genuine Sandbox purchases remain separate from unit fixtures.

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
