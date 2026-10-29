# TestFlight — ECHO 1.1.0 (23)

28 October 2026. The owner explicitly authorized this internal TestFlight upload with “Залей на тестфлайт проверить”. This does not authorize an App Store release, a price transition or live advertising.

## Package

- Source: `49a602a63a747fef3ea4b3891d7a9e4acc3e6e47`; `project.yml`, SDK-free configuration.
- Same existing app: `6811673094`, `com.sergiiziborov.Echo`; embedded Watch: `com.sergiiziborov.Echo.watchkitapp`.
- Both bundles: version **1.1.0**, build **23**.
- Distribution archive: stable **Xcode 27.1 (27A9275)**; iPhone SDK 27.1, Watch SDK 27.0.
- Exported IPA: **40,155,564 bytes**, SHA-256 `e021ddf7fdb3c7c35fbefac95ac778c61f28cb173ba9b7727c4f8e61e8ed29ee`.
- `TFInternalTestingOnly=true` is present in the exported app. There are no advertising SDKs, `.storekit` fixtures or private key files in the package. Game Center entitlement is preserved in both distribution profiles.

## Actual results

| Stage | Result |
| --- | --- |
| Signed archive | PASS |
| App identity, versions, SDK-free flag, symbol and archive signature checks | PASS |
| Export with the existing local Apple Distribution certificate | PASS |
| IPA/profile checks: correct team, explicit app identities, no development entitlement or device list | PASS |
| Apple server validation | PASS — `VERIFY SUCCEEDED with no errors` |
| Apple upload | PASS — `UPLOAD SUCCEEDED with no errors` |
| Delivery | `eba105bd-70d5-480d-aa15-c9762d8fc707` |
| Apple processing | PASS — `VALID`, `INTERNAL_ONLY` |
| Keepers availability | PASS — `IN_BETA_TESTING`, confirmed 2026-10-28 10:35 UTC |
| EN/RU What to Test | PASS — exact text read back from Apple for `en-US` and `ru` |
| Real device purchases / legacy restoration / ad-network behavior | NOT RUN; not established by uploading a binary |

Automatic export initially failed because the account lacked cloud-managed signing access and matching App Store profiles. Resolved by reusing the already installed Distribution certificate and creating two routine App Store provisioning profiles for the existing phone/Watch bundle IDs. No certificate was created or revoked, no bundle capability was changed, and no Apple agreement was accepted.

The first local archive used Xcode 27.0 beta; it was replaced before validation/upload by the stable Xcode 27.1 archive. The uploaded artifact is the stable archive identified above.

Sanitized server and package evidence: [TESTFLIGHT_23_VERIFICATION.json](TESTFLIGHT_23_VERIFICATION.json). [Open TestFlight in App Store Connect](https://appstoreconnect.apple.com/apps/6811673094/testflight).

## Scope of this test build

Production remains protected in `preFree`. `EchoAdSDKIncluded=false`; live ads cannot start. TestFlight uses verified StoreKit Sandbox behavior. The proposed Remove Ads SKU is still absent from App Store Connect, so a real purchase is unavailable and no fake success is substituted. This build can test gameplay, saved progress and the purchase UI's protected/unavailable/restore states; it cannot verify real ad presentation or production legacy ownership.

No price, public listing, public website, App Store Review submission, Family Sharing setting or IAP product was changed by this upload. Distribution is for the existing internal **Keepers** group, not external beta review.

## Commands and local evidence

The private authorization arguments are intentionally omitted. Credentials stay in the existing secure host store, outside the repo and app.

```sh
xcodegen generate --spec project.yml
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project Echo.xcodeproj -scheme Echo -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/echo-testflight-23/DerivedData \
  -archivePath /tmp/echo-testflight-23/Echo.xcarchive archive
# Export uses app-store-connect, manual local signing, both explicit profiles,
# manageAppVersionAndBuildNumber=false and testFlightInternalTestingOnly=true.
xcodebuild -exportArchive -archivePath /tmp/echo-testflight-23/Echo.xcarchive \
  -exportPath /tmp/echo-testflight-23/export \
  -exportOptionsPlist /tmp/echo-testflight-23/ExportOptions.plist
xcrun altool --validate-app --type ios --file /tmp/echo-testflight-23/export/Echo.ipa
xcrun altool --upload-app --type ios --file /tmp/echo-testflight-23/export/Echo.ipa
```

The actual authenticated commands ran with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Logs, archive, IPA and sanitized artifact metadata are under `/tmp/echo-testflight-23/`. The underlying source tests remain documented in [REPORT.md](REPORT.md); this upload is not an additional full regression or physical-device test.

## What to Test

### en-US

R1 preparation build 1.1.0 (23). Advertising SDK and all ad formats are absent. The public paid-to-free transition is not enabled.

Please check:
• Update the installed app without deleting it: campaign progress, research, inventory and Archive must remain intact.
• Settings → Ads and Purchases: status, Restore Purchases, errors and close controls. Uncertain ownership must never request a second payment.
• English/Russian, large text and compact iPhone; iPad portrait/landscape.
• Solo wins → Next, Retry, Rewind, Archive finds and offline play.
• Apple Watch standalone/remote; Next after a watch-controlled win.

Remove Ads is not configured in App Store Connect yet. Real purchases and advertising cannot be validated in this build. No mock purchase or production legacy cutoff is included.
TestFlight uses Sandbox; this does not verify original production-owner restoration.

### ru

Подготовительная сборка R1: 1.1.0 (23). Рекламного SDK и показов нет. Переход публичной версии на бесплатную загрузку не включён.

Проверьте:
• Обновление установленной игры без удаления: карты, исследования, инвентарь и Архив должны сохраниться.
• Настройки → Реклама и покупки: статус, восстановление, ошибки и закрытие. При неясном праве повторная оплата не предлагается.
• Английский/русский, крупный текст, небольшой iPhone; iPad в обеих ориентациях.
• Победа → Далее, Retry, Rewind, находки Архива и игра offline.
• Apple Watch отдельно и как пульт; Далее после победы с управлением с часов.

Продукт Remove Ads ещё не настроен в App Store Connect. Настоящую покупку и рекламу в этой сборке проверить нельзя. Фиктивных покупок и придуманной границы legacy нет.
TestFlight использует Sandbox; это не подтверждает восстановление права исходного production-покупателя.

