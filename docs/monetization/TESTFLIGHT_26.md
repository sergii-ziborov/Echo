# ECHO 1.1.0 (26) — 29 October 2026

**PASS: available to Keepers; Apple reports VALID / IN_BETA_TESTING.** This build can be used for App Store distribution; it is not restricted to internal-only delivery. The editable 1.1.0 draft now references build 26. App Review has **not** been submitted: the Mac is locked, and the first non-consumable must be sent with the app through App Store Connect’s website.

Application source: `99a22e63df8b657dee19ba0848bcb94b45a9de6c`. The archive contains this source state; later marketing/report commits do not alter that binary.

- IPA: 41,691,654 bytes; SHA256 `75dd47693072e444bb22362e41990f0e7fa9952806b9972c3f6e7f5b2eeac4b5`.
- Delivery/build: `c17343a5-11ab-4639-b481-1ea57c6c0005`. Server, Keepers membership, EN/RU beta notes and draft build relationship read back.
- Xcode 27.1 (27A9275), iOS SDK 27.1 / watchOS SDK 27.0; stable `/Applications/Xcode.app` selected explicitly.
- Google Mobile Ads 13.11.0 and UMP 3.1.0 are pinned in the explicit iOS SDK variant. Watch contains no ad SDK.
- Production remains **preFree / live ads OFF**, with no invented original-owner cutoff and no price change. Rewarded rescue remains off.

## Verification

| Check | Actual result |
| --- | --- |
| Signed archive, export, Apple validation and upload | PASS |
| Production advertising gate | PASS; `live: false`, zero errors |
| Lore, EN/RU, narrow Russian header OCR, purchase policy/service, native menus | PASS: 53 tests on build 26, zero failures/skips; `/tmp/echo-final26-retry-tests.xcresult`, command exit 0 |
| Latest build-26 label and Watch changes | PASS: Russian next-rank OCR at 320 pt and Watch result visually inspected on watchOS 26.5 Simulator |
| Native EN/RU views at phone, iPad and both Duo widths | PASS: 60 menu views; 10 research and 10 equipped-loadout views refreshed on build 26. Additional capture test ran on an iPad Simulator (1 PASS, zero failures/skips). This is not physical Duo/iPad testing |
| Physical cancellation / verified purchase / restoration | Build 24: owner completed all three; copied journal corroborates purchase and ad-free. Restore remains PASS_USER_REPORTED |
| Original paid-owner reinstall/another device, physical iPad/Watch, regional consent traffic | NOT RUN |
| First IAP review image / product metadata | PASS: UPLOAD_COMPLETE / READY_TO_SUBMIT; screenshot explicitly identified as fixture |
| App Review submission | BLOCKED: Mac locked, web UI needed for first IAP |

Initial test retries were interrupted or failed due disk exhaustion, runner bootstrap/locked-device issues. Those attempts are not PASS. The 53-test result above is a separate completed run. Historical xcresults and archive/IPA are retained; duplicate evidence payloads were hard-linked without deleting content.

## Contents

Eleven sourced region readings, nine expanded Keeper records, a coherent Ashcrown chronology, authentic Lab terminology, Russian Home/Atlas header fallback, wider research effect labels and Watch result safe-area/wrapped Crown hints. Gameplay, costs, stable level IDs, unlock rules and save values are unchanged.

Marketing includes captioned EN/RU screenshots, localized header/search artwork, two actual-gameplay app previews and a separately labeled Grok cinematic teaser. Assets belong to the editable 1.1.0 draft until approved and released; they are not described as public App Store changes.

## Reproduce

```sh
xcodegen --spec project-admob.yml
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Echo.xcodeproj -scheme Echo -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/echo-testflight-26/DerivedData \
  -archivePath /tmp/echo-testflight-26/Echo.xcarchive archive
# Export with existing distribution certificate/profiles; internal-only=false.
xcodebuild -exportArchive -archivePath /tmp/echo-testflight-26/Echo.xcarchive \
  -exportPath /tmp/echo-testflight-26/export \
  -exportOptionsPlist /tmp/echo-testflight-26/ExportOptions.plist
xcrun altool --validate-app --type ios --file /tmp/echo-testflight-26/export/Echo.ipa --use-old-altool
xcrun altool --upload-app --type ios --file /tmp/echo-testflight-26/export/Echo.ipa --use-old-altool
python3 scripts/check_monetization_release.py /tmp/echo-testflight-26/Echo.xcarchive/Products/Applications/Echo.app
```

Private authentication arguments are omitted. Rollback: retain preFree, or publish an approved signed adsOff policy; invalid or expired advertising policy already suppresses new live requests. Do not erase purchase evidence or progress. No new contract, price, Family Sharing or account-wide first-party-ID change was made.

The completed run printed TEST EXECUTE SUCCEEDED. Automatic global simctl diagnostics were collecting after all cases finished; that collector was interrupted to avoid retaining unnecessary system logs. The command then finalized the genuine xcresult successfully (exit 0). Only sanitized test results and native app attachments are copied into the repository.
