# ECHO 1.1.0 (27) — released approved build

**PASS: VALID, APP_STORE_ELIGIBLE, IN_BETA_TESTING; available to Keepers.** **App Review: APPROVED; release requested, READY_FOR_SALE.** ECHO 1.1.0 and its first Remove Ads IAP were submitted together on 29 October 2026. The owner-authorized manual release succeeded on 29 October 2026; production remains preFree/live ads off. [Release evidence](APP_STORE_RELEASE_27_2026-10-29.md). [Submission evidence](APP_REVIEW_27_2026-10-29.md).

Application source: `3952d80e210ab0b07fdfbb34520c094438799aa4`. IPA: 41,699,353 bytes, SHA256 `95c875bd311e801cbec3026496fbf999b2bfb1e225246d8715844abd56393814`. Delivery/build: `e1970e5e-1646-4cf1-af84-b1d900a0df89`. Stable Xcode 27.1 (27A9275), iOS SDK 27.1 and watchOS SDK 27.0. Google Mobile Ads 13.11.0 / UMP 3.1.0 are pinned, iOS only. The generated default project was restored to SDK-free configuration after archiving.

## Actual checks

| Check | Result |
| --- | --- |
| Archive, export, Apple validation, upload and processing | PASS |
| Keepers, EN/RU beta notes and draft build association | PASS, read back |
| Production advertising release guard | PASS; live=false, zero errors |
| R1 policy, purchase, coordinator, baseline preservation, Watch protocol, localization and UI regression run | PASS: 53 tests on build 26, zero failures/skips |
| Latest source: Russian header/rank/node OCR, sourced region notes, localization and menu capture | PASS: 11 tests on build 27, zero failures/skips |
| Native menu assets | PASS: 60 EN/RU captures; phone, iPad and both Duo viewports |
| Equipped-loadout capture fixture | PASS: 1 additional test on an iPad Simulator; current full menu run also captures two equipped abilities |
| Watch result | PASS visual inspection: title below system clock, Crown hint readable |
| Physical TestFlight purchase | Build 24 PASS in device journal; cancellation and restore also completed by owner, restore PASS_USER_REPORTED |
| Physical installed build / existing save / retained ad-free state | PASS on iPhone 13 mini, iOS 26.5: installed 27, all 16 prior progress/settings keys retained, prior records not downgraded, campaign advanced from 4/11 to 15/42 maps/stars; ad-free state and protected Next transitions in local journal. [Evidence](PHYSICAL_27_VERIFICATION.json) |
| Physical build-27 launch and visual UI pass | BLOCKED: launch denied as Locked; Device Hub requires iOS 27+ for screen sharing. No UI case executed, no repeated purchase/restore, no app replacement/reset |
| Original paid-owner reinstall / other device, physical iPad/Watch, regional consent traffic | NOT RUN |
| First IAP metadata | Review screenshot COMPLETE; IAP version and product APPROVED; fixture provenance explicit |
| App Review / free-price cutover / live advertising | Review PASS: COMPLETE; app READY_FOR_SALE; price and live advertising NOT CHANGED |

The initial node-label View implementation failed during native UI tests and was replaced before delivery. Its failed result bundle remains `/tmp/echo-russian27-tests.xcresult`; it is not a passing run. The current source uses an ordinary Text with measured, balanced lines and passed `/tmp/echo-russian27-fixed-tests.xcresult`. An automatic global diagnostic collector was interrupted after the earlier 53 cases had completed; that run finalized successfully with exit 0. Raw system diagnostics are not published.

## Change and provenance

Eleven region readings connect clearly attributed philosophy to separate science notes; nine Keeper records deepen the story. Ashcrown observations have a coherent chronology. Lab terminology fits the Signal/Archive world. Home and Atlas use a narrow-layout fallback, research labels preserve whole Russian words and Watch results respect the system clock. Gameplay, economy, stable IDs and save values are unchanged. Baseline fixtures and the 77 stable level identities are tested; this does not stand in for a real original-buyer reinstall.

The marketing package has 56 captioned images plus 8 native Watch screenshots, two localized header/search sets, two real-gameplay App Store previews and separate Grok teasers. The remote slide shows setup, not fabricated proof of a live remote session. The gameplay video is a sanitized earlier physical-device recording of the unchanged arena renderer. The artistic clip is labeled separately on the public website.

## Release boundary and rollback

Production remains **preFree / live ads OFF**. No price, contract, Family Sharing or account-wide publisher-ID change was made. Original-owner cutoff is unapproved; uncertain rights suppress advertising. The remaining paid-to-free safety gates in CUTOVER_LEDGER.md and the cabinet report still apply. Review approval does not itself authorize the price/cutover or live-ad switch.

Keep preFree, or use an owner-approved signed adsOff policy to stop future ad requests. Invalid/expired policy also suppresses them. Preserve purchase evidence and gameplay progress. The prior working build 26 remains available as historical beta evidence.

## Commands

```sh
xcodegen --spec project-admob.yml
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Echo.xcodeproj -scheme Echo -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath /tmp/echo-testflight-27/DerivedData \
  -archivePath /tmp/echo-testflight-27/Echo.xcarchive archive
# Existing distribution certificate and profiles; internal-only=false.
xcrun altool --validate-app --type ios --file /tmp/echo-testflight-27/export/Echo.ipa --use-old-altool
xcrun altool --upload-app --type ios --file /tmp/echo-testflight-27/export/Echo.ipa --use-old-altool
python3 scripts/check_monetization_release.py /tmp/echo-testflight-27/Echo.xcarchive/Products/Applications/Echo.app
xcodegen --spec project.yml
```

Changed-file list: CHANGED_FILES_2026-10-29.txt (relative to the original main source). Private authentication arguments are omitted. Archive, export and logs are under `/tmp/echo-testflight-27/`. See TESTFLIGHT_27_VERIFICATION.json for hashes and server evidence.

The subsequent [bilingual editorial and rights review](../lore/EDITORIAL_RIGHTS_AUDIT_2026-10-29.md) checks all 50 changed EN/RU pairs and the new media provenance. The Site credits Grok explicitly in both languages. This documentation-only follow-up does not change the build-27 binary.
