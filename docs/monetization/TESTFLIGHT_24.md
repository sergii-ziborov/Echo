# ECHO 1.1.0 (24) — internal TestFlight

28 October 2026. **PASS: available to Keepers, IN_BETA_TESTING.** This is the SDK-enabled successor to SDK-free build 23. It does not announce a completed free release.

- Source: `f90372363d068dda7e9c535e45ef711066d77710`, explicit `project-admob.yml`.
- Same app/bundles; phone and embedded Watch both 1.1.0 (24).
- Xcode 27.1 (27A9275), iOS SDK 27.1, Watch SDK 27.0.
- Google Mobile Ads **13.11.0**, UMP **3.1.0**, phone only; Watch symbols/configuration checked.
- IPA **41,647,718 bytes**, SHA256 `e7d04e7be75f095c83dafd440923db59e9980a594aaa424a8614c7a4cc6bef52`.
- Delivery/build `11b08b9e-cfce-4a84-a863-ab93a1060d10`: **VALID**, **INTERNAL_ONLY**.
- Keepers relationship lists build 24; beta details report `IN_BETA_TESTING`, auto-notification enabled. EN/RU What to Test was read back exactly.
- No fixture `.storekit` or private key in the app. Existing local Distribution certificate and the phone/Watch App Store profiles were reused, without new credentials or revoked certificates.

## Verification

| Check | Actual result |
| --- | --- |
| Signed SDK archive, manual export, bundle versions and profile entitlements | PASS |
| Apple validation and upload | PASS, `VERIFY SUCCEEDED` / `UPLOAD SUCCEEDED` |
| Processing and internal availability | PASS; server state and Keepers membership confirmed |
| Focused purchase/policy/navigation regressions | PASS: 31, zero failures/skips; see cabinet report |
| SDK Release cold launch/rendering | PASS on isolated iPhone 17 Pro / iOS 26.5 Simulator, alive after 183.6 s; prior build-23 binary with same SDK/configuration code, not a device purchase test |
| Genuine Sandbox purchase / restore / pending / refund | NOT RUN |
| Original production-owner update/reinstall/another device | NOT RUN |
| Real SDK UMP/test-creative load and discard on an isolated Simulator | PASS: 1, zero failures/skips; [evidence](AD_NETWORK_VERIFICATION.json) |
| Visible fullscreen dismissal, real-account consent choices/traffic; physical iPad/Watch | NOT RUN |
| Google account/app verification | PENDING / BLOCKED; a reachable file is not Google approval |

The modern altool validation endpoint returned HTTP 500 and stalled; that validation process was cancelled. The official `--use-old-altool` path validated and uploaded the unchanged IPA successfully. A subsequent beta-detail read briefly returned 404 during processing; a fresh independent read confirmed IN_BETA_TESTING. No unsuccessful attempt is treated as PASS.

## Enabled and disabled behavior

The real ECHO App/Unit IDs and signed HTTPS policy URL/public key are compiled in. Production policy is **preFree**, with no approved legacy cutoff and `audienceReviewed=false`; live ads and repeated purchase offers remain off. Verified Sandbox uses the actual configured Remove Ads product and official Google test interstitials, subject to all gameplay and frequency protections. The IAP is configured but not approved and does not yet have a real review screenshot.

Publisher first-party ID and personalization are disabled by the ECHO SDK configuration before initialization. The account-wide publisher-ID setting remains ON by the owner's explicit choice; irreversible account data deletion was not accepted.

[Cabinet evidence and remaining gates](CABINET_SETUP_2026-10-28.md). [Sanitized package/server evidence](TESTFLIGHT_24_VERIFICATION.json). [Open App Store Connect TestFlight](https://appstoreconnect.apple.com/apps/6811673094/testflight).

## Commands

Credentials were supplied from the existing private host store; authentication arguments are omitted here.

```sh
xcodegen generate --spec project-admob.yml
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Echo.xcodeproj -scheme Echo -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/echo-testflight-24/DerivedData \
  -archivePath /tmp/echo-testflight-24/Echo.xcarchive archive
# Export: existing manual distribution certificate/profiles,
# manageAppVersionAndBuildNumber=false, testFlightInternalTestingOnly=true.
xcodebuild -exportArchive -archivePath /tmp/echo-testflight-24/Echo.xcarchive \
  -exportPath /tmp/echo-testflight-24/export \
  -exportOptionsPlist /tmp/echo-testflight-24/ExportOptions.plist
xcrun altool --validate-app --type ios --file /tmp/echo-testflight-24/export/Echo.ipa --use-old-altool
xcrun altool --upload-app --type ios --file /tmp/echo-testflight-24/export/Echo.ipa --use-old-altool
xcodegen generate --spec project.yml
```

The safe default generated project was restored after archiving. Archive/export/logs are under `/tmp/echo-testflight-24/`. R1 remains protected until the real purchase, original-owner, privacy and cutover checks pass. Rollback: higher-version signed adsOff policy; invalid/expired policy also suppresses new live ads. Purchase evidence and game progress remain independent.
