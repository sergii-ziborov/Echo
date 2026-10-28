# ECHO R1 — отчёт реализации

> Последний TestFlight: **1.1.0 (24)** с SDK доступен Keepers, `IN_BETA_TESTING`. [Проверенная доставка и ограничения](TESTFLIGHT_24.md). Политика и условия сайта обновлены на EN/RU. Европейское сообщение UMP сохранено черновиком; runtime privacy и реальные покупки ещё не подтверждены.
>
> Обновление кабинетов 28 октября: единственный Remove Ads создан, настроены EN/RU, цена USD 1.99 и доступность во всех 175 территориях. Правильный app-ads.txt опубликован на действующем сайте. SKU пока `MISSING_METADATA`, проверка Google не завершена. Текущие доказательства и оставшиеся шаги — [CABINET_SETUP_2026-10-28.md](CABINET_SETUP_2026-10-28.md). Ниже сохранён исходный отчёт подготовки; его прежние статусы кабинетов исторические.

> Последующее действие владельца: SDK-free **1.1.0 (23)** загружена во внутренний TestFlight и доступна Keepers. [Подтверждение Apple и заметки](TESTFLIGHT_23.md). Исходный отчёт подготовки ниже не является аппаратной проверкой или разрешением public/free-релиза.

Дата: 28 октября 2026. База: `740c8fc244823249eacf9e39eec35e407ccaa787`, совпала с полученным `origin/main`. Исходники подготовлены для 1.1.0 (23); это не опубликованная версия.

**Статус: код подготовлен, выпуск R1 BLOCKED внешними настройками и аппаратными проверками.** App Store по проверке остаётся 1.0.0 (18), USD 1.99. IAP в кабинете отсутствует. Цена, публикация, App Review, Family Sharing, договоры и live-реклама не изменялись. Сайт не переопубликован. Исходный рабочий каталог с посторонними изменениями не затронут.

Commit реализации: `1acd424da7de4d26150f86ce105744b2d9cad012`, ветка `codex/free-remove-ads`. Отчёт фиксируется отдельным следующим коммитом. Полный перечень файлов — [CHANGED_FILES.md](CHANGED_FILES.md).

## Что сделано

- StoreKit 2: проверяемые AppTransaction и non-consumable, lifetime listener, purchase/restore/pending/cancel/refund, один идемпотентный обработчик доставки, запись права перед `finish()`. Цена читается из `Product.displayPrice`.
- Агрегирование legacy/IAP/family с provenance и device-only Keychain. Неясная подпись, пустая выборка при прежнем праве, другой acquisition или ошибка чтения кэша не включают рекламу и не предлагают повторную оплату. Legacy не снимается возвратом IAP или сужением политики. Reset игрового прогресса не удаляет покупки.
- EN/RU экран из Settings, ненавязчивый Home-вход, восстановление, понятные состояния, privacy options и жалоба с ручной отправкой. На компактном экране с крупным текстом закрытие закреплено над прокруткой.
- Чистая AdPolicy, отдельный budget, поколения прав/согласия, одноразовый creative и navigation ticket, дедупликация побед, защита результата/Архива/Watch, фон и модальный lock. Только явный Next после подходящей solo-победы. Watch-защита запрещает рекламу, сохраняя нормальный переход на следующую карту.
- Победа сохраняется до рекламной возможности. Двойные callbacks не начисляют награды повторно. Reservation и выбранная следующая карта переживают завершение приложения; неопределённый показ учитывается консервативно. Fullscreen-представление не считается уходом с результата и не расходует второй раз Ward при возврате. Remote Retry не запускает арену под рекламой.
- AdMob/UMP адаптеры только iOS; предварительная настройка приватности, `npa=1`, отключён publisher first-party ID, ограничительный G/child request configuration, один creative и backoff. Это не утверждение о соответствии детской аудитории: фактическая аудитория и трафик требуют проверки.
- Ed25519-политика через CryptoKit, HTTPS, версия/срок/границы частоты. Нет ключа подписи, выдуманной даты cutover, live IDs или работающего production endpoint.
- Документы, EN/RU listing/review copy и локальная подготовка сайта: цена/SEO/legal зависят от фактической фазы. `preFree` сохраняет платное описание. R1.1 rescue, новый лор, подписки, валюты и gameplay-баланс не добавлялись.

## Флаги и зависимости

| Параметр | Текущее значение |
| --- | --- |
| Production phase / live ads | `preFree` / выключены |
| Основной `project.yml` | `EchoAdSDKIncluded=false`, vendor adapters исключены, SDK не линкуется |
| `project-admob.yml` | Явный вариант того же iOS target/bundle; `ECHO_ADMOB`, test App ID только Debug |
| SDK Release без настоящего App ID | Сборка завершается ошибкой; test/пустой ID не подставляется |
| SKU | `com.sergiiziborov.Echo.removeAds`, предложен, не создан в кабинете |
| Cutover / public key / policy URL / live unit | Не настроены; production не получает разрешение |
| Sandbox/Xcode | Только проверенное окружение StoreKit выбирает тестовую free-политику; не выдаёт production legacy |
| Rewarded / banners / app-open / mediation | Отсутствуют |
| Google Mobile Ads | **13.11.0**, revision `d1fa1f5c1dfe3b43d56c73f4de388ad3316618bc` |
| UMP | **3.1.0**, revision `13b248eaa73b7826f0efb1bcf455e251d65ecb1b` |

Версии зафиксированы exact в XcodeGen и Package.resolved. Watch не зависит от рекламных пакетов. SDK-free production не предлагает повторную покупку даже при ошибочно разрешающей remote policy.

## Реально выполненные проверки

Среда: Xcode 27.0 (27A5228h), Swift 6; iOS Simulator 26.5 на отдельном iPhone 17 Pro. Дополнительный StoreKit-прогон — отдельный iPhone Duo с iOS 27.1. Это не физические устройства. Read-only `devicectl list devices` показал, что подключённые записи принадлежат CoreSimulator, а известное физическое устройство отключено. Поддерживаемые deployment targets сохранены: iOS 18 / watchOS 11.

| Проверка | Результат |
| --- | --- |
| Свежий main, reset/save/Next/Watch audit, read-only cabinet | **PASS**, границы подтверждения в EVIDENCE.md |
| Финальный SDK Debug: выбранные unit/regression suites | **PASS: 77**, **BLOCKED/skipped: 1**, failures 0; `/tmp/echo-monetization-sdk-accepted.xcresult` |
| Финальная SDK-free suite после UI/Watch исправлений | **PASS: 77**, **BLOCKED/skipped: 1**, failures 0; `/tmp/echo-monetization-default-accepted.xcresult` |
| Отдельная повторная UI-проверка закреплённого close | **PASS: 1**, 12 native captures; `/tmp/echo-monetization-layout-final.xcresult` |
| SDK Release без реального App ID | **PASS защитного gate**: ожидаемый `BUILD FAILED`, exit 65, `/tmp/echo-admob-release-gate.log` |
| SDK-free Release Simulator + встроенный Watch | **PASS**, `BUILD SUCCEEDED`, `/tmp/echo-quiet-release-simulator.log` и финальная инкрементальная `/tmp/echo-quiet-release-final.log` |
| SDK-free Release generic iOS + встроенный Watch, unsigned | **PASS**, `BUILD SUCCEEDED`, `/tmp/echo-quiet-release-device.log`; установка на устройство не выполнялась |
| Исправленный холодный запуск SDK-free Release | **PASS** в Simulator: PID 99963 жив после 13 секунд; после финальной сборки повторный запуск PID 13884 также жив; получен экран входа, `/tmp/echo-quiet-release-cold.png` |
| Бинарные символы и artifact gate | **PASS**: phone/Watch — 0 рекламных символов; non-live gate PASS; `--live` **BLOCKED**, ожидаемый exit 1 с перечнем отсутствующих inputs |
| Сайт | **PASS**: 12 страниц, ссылки/якоря/assets/EN-RU metadata; 48 комбинаций фаза/язык/страница и корректная цена JSON-LD |
| Инструмент подписи / whitespace | **PASS**: `swiftc -typecheck scripts/sign_release_policy.swift`, `git diff --check` |
| StoreKit local integration | **BLOCKED**, не fake PASS: native `Product.products` пуст; служба не устанавливает `.storekit` configuration |
| Sandbox/TestFlight, paid-account update/reinstall/второе устройство | **NOT RUN**: нужен настоящий SKU и устройства/аккаунты |
| Pending/refund/Family Sharing на устройствах | **NOT RUN**; unit fixtures не заменяют эти проверки |
| Реальные объявления/UMP/ATT denied/трафик/память/FPS | **NOT RUN**, publisher setup отсутствует |
| Физические iPad/Watch, VoiceOver, контроллер, аудиопрерывания | **NOT RUN**; native renders и wire tests не выданы за аппаратный PASS |
| Деплой сайта, App Privacy, цена Free, подача на review | **NOT RUN**, нужен релизный шаг владельца после gates |

### Обнаруженные ошибки и ограничения

1. **FAIL на раннем холодном Release-запуске:** Google SDK аварийно проверял пустой App ID до явного `start()` (`GADApplicationVerifyPublisherInitializedCorrectly`). Исправлено разделением SDK-free подготовки и явно включаемого SDK-варианта с обязательным Release gate. Ранние успешные компиляции не считаются доказательством холодного запуска.
2. **BLOCKED настоящая локальная покупка:** ранние попытки StoreKit-теста завершились ошибками продукта/конфигурации на iOS 26.5 и повторно на iOS 27.1 Duo. Итоговый тест проверяет нативный продукт до покупки и явно пропускается при недоступности, без подмены успешной транзакцией. Похожее ограничение CLI описано Apple DTS: [FB22237318](https://developer.apple.com/forums/thread/826971). Это не обещание исправления Apple и не аппаратный результат.
3. **Исправлены при просмотре/регрессии:** close за краем при accessibility2; ложная отмена навигации при fullscreen; повторное расходование Ward при onAppear; блокировка Next защищённой Watch-попытки. Фактические сетевые lifecycle callbacks всё ещё проверяются на устройствах. Дополнительный Watch-тест сначала обнаружил незавершённый tutorial в своём fixture; fixture приведён к реально пройденным первым картам, повторный полный выбранный прогон зелёный.
4. Логи render harness содержат SwiftUI appearance/Environment warnings. Assertions не падают; аппаратная визуальная и VoiceOver-проверка остаётся отдельным gate. Один ранний сбор диагностик Simulator завис после тестов; остановлен только принадлежащий этому запуску diagnostic child. Финальные команды используют `-collect-test-diagnostics never` и завершаются штатно.

## Сохранения

`BaselineProgress.json` — фиксированные **15 native defaults keys**, 77 карт, исследования, инвентарь, Archive/Watch-поля из синтетического showcase, записанного неизменённой схемой ProgressStore. Snapshot tests проверяют сохранность при инициализации/записи монетизации. Существующие progress/regression tests проходят. Simulation/уровни/экономика не менялись; новые budget/preferences отдельны, purchase evidence в Keychain. Это доказательство регрессии схемы, **не** реальный save платного пользователя. Реальная миграция после reinstall и на другом устройстве — NOT RUN.

## Команды

```sh
xcodegen generate --spec project-admob.yml
# Проверенный защитный gate: Release без настоящего App ID должен завершиться exit 65.
# xcodebuild -project Echo.xcodeproj -scheme Echo -configuration Release \
#   -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/echo-monetization-sdk \
#   ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Echo.xcodeproj -scheme Echo \
  -destination 'platform=iOS Simulator,id=C888ADCD-FA2E-49AB-B3AD-D82E28057C13' \
  -parallel-testing-enabled NO -enableCodeCoverage NO -collect-test-diagnostics never \
  -derivedDataPath /tmp/echo-monetization-sdk \
  -only-testing:EchoTests/PurchaseTests -only-testing:EchoTests/PurchaseServiceTests \
  -only-testing:EchoTests/AdPolicyTests -only-testing:EchoTests/CoordinatorTests \
  -only-testing:EchoTests/StoreKitIntegrationTests -only-testing:EchoTests/MonetizationUITests \
  -only-testing:EchoTests/ProgressStoreTests -only-testing:EchoTests/WristLinkTests \
  -only-testing:EchoTests/GameViewCoverageTests -only-testing:EchoTests/ArchiveDiscoveryTests \
  -only-testing:EchoTests/LocalizationTests -only-testing:EchoTests/BaselineSnapshotTests \
  -resultBundlePath /tmp/echo-monetization-sdk-accepted.xcresult CODE_SIGNING_ALLOWED=NO test

# Та же команда после генерации основного manifest:
xcodegen generate --spec project.yml
# resultBundlePath: /tmp/echo-monetization-default-accepted.xcresult
# Только UI повторно: -only-testing:EchoTests/MonetizationUITests
# resultBundlePath: /tmp/echo-monetization-layout-final.xcresult

xcodebuild -project Echo.xcodeproj -scheme Echo -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/echo-monetization-quiet \
  ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Echo.xcodeproj -scheme Echo -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath /tmp/echo-monetization-quiet \
  CODE_SIGNING_ALLOWED=NO build
python3 scripts/check_monetization_release.py /tmp/echo-monetization-quiet/Build/Products/Release-iphonesimulator/Echo.app
# --live обязан завершиться FAIL при ненастроенных production inputs.
python3 website/build.py
python3 website/verify.py
swiftc -typecheck scripts/sign_release_policy.swift
git diff --check
```

Созданные этой задачей два QA Simulator удалены, локальный preview server остановлен; чужие симуляторы и основной checkout не затронуты. ID в командах относится к выделенному временному QA Simulator; для повторения создайте новый и подставьте его ID. Полные logs/xcresult хранятся локально в `/tmp`, не содержат заявления о фактической оплате. Санитизированные счётчики из xcresult и метаданные бинарей сохранены в [VERIFICATION.json](VERIFICATION.json). Native attachments сохранены в [screenshots](screenshots/README.md). Эта suite покрывает выбранные затронутые сценарии, не заявляет прогон абсолютно всех тестов репозитория.

## Незакрытые gates и выпуск

1. История paid/free по витринам, реальные paid builds, UTC-переход, goodwill и утверждённый cutover — **BLOCKED**, [ledger](CUTOVER_LEDGER.template.md). Дата не придумана.
2. Создание единственного SKU, цена/доступность, review screenshot, соглашения/банк/налоги — **BLOCKED**. Family Sharing не включён и не обещан.
3. Настоящие AdMob app/unit/publisher, app-ads.txt crawl, UMP markets/messages/audience и SDK privacy audit — **BLOCKED**. `npa=1` не приравнен к Data Not Collected.
4. Контролируемый HTTPS policy endpoint, private signing key вне git, public key в сборке, hosting logs/retention — **BLOCKED**.
5. Физический прогон и покупки исходного владельца после update/reset/reinstall/другого устройства — **NOT RUN**. Пока нет этих доказательств, R1 не соответствует полному Definition of Done.

После закрытия gates: реальный SDK Release → Sandbox/устройства → действие владельца на подачу версии и IAP → одобрение → preFree выпуск → согласованная смена цены → наблюдение витрин/ledger → freeQuiet → проверки → подписанный freeLive. Только затем публичные free-тексты/SEO. Подробности в [RELEASE.md](RELEASE.md), privacy-поля в [PRIVACY_AUDIT.md](PRIVACY_AUDIT.md), соответствие матрице в [TEST_MATRIX.md](TEST_MATRIX.md).

## Остановка и откат

Публикация более новой подписанной `adsOff` либо безопасное истечение политики запрещает новые запросы/показы, сохраняя игру и права. Уже открытый SDK-экран закрывается обычным lifecycle. При SDK startup crash нужен исправленный бинарь; remote kill switch этого не гарантирует. После SDK-релиза сохранять его privacy options в исправляющей сборке. Не возвращать платную загрузку и не сужать выданный legacy-доступ ради устранения бага.
