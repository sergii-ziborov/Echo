# ECHO App Store release guide

App Store Connect record: [ECHO: Survive Your Past](https://appstoreconnect.apple.com/apps/6811673094/distribution/ios/version/inflight). App ID `com.sergiiziborov.Echo`. Version **1.0.0**, current build **18**. The listing is not public yet.

## Price and product type

Intended sale: **$1.99 USD one-time iOS app**. No ads, no in-app purchases, no subscriptions, no account. A paid price requires the account holder to accept the Paid Apps Agreement and complete banking/tax in App Store Connect before the price can be saved.

## TestFlight / Xcode Cloud

`project.yml` and the generated Xcode project use marketing version **1.0.0** and build **18**. Xcode Cloud numbers its own builds, so set its next build number above the last uploaded build. `ci_scripts/ci_post_clone.sh` installs XcodeGen if needed and regenerates the project.

After signing in to App Store Connect:

1. Connect an Xcode Cloud workflow to `sergii-ziborov/Echo` on `main`.
2. Use **Archive - iOS**, **App Store Connect** distribution, and **TestFlight Internal Testing**.
3. Confirm the processed build is 1.0.0 (19) or later before assigning testers.

Suggested **What to Test**: region arrival cards and the Atlas route (Möbius loop, region skies); Deep Time; the Apple Watch app on its own and as a remote for a phone run; Settings → About / Terms / Privacy / Report a bug.

## Prepared assets

Screenshots are opaque JPEGs captured from the running app:

| Group | Size | Folder |
| --- | --- | --- |
| iPhone 6.9-inch | 1320 × 2868 | `docs/app-store/iphone/` |
| iPhone 6.5-inch | 1284 × 2778 | `docs/app-store/iphone65/` |
| iPad 13-inch | 2064 × 2752 | `docs/app-store/ipad/` |
| Apple Watch 46 mm | 416 × 496 | `docs/app-store/watch/` |

Keep the two iPhone groups separate in App Store Connect. The first image in each group is gameplay, not a splash screen.

| iPhone (both sizes) | iPad | Feature |
| --- | --- | --- |
| `play/01-gameplay.jpg` | `01-gameplay.jpg` | Orb, rocks and the Hollow Belt sky |
| `play/02-lasers.jpg` | — | Laser arena under Ashcrown |
| `menu/03-atlas.jpg` | `02-atlas.jpg` | Atlas route with the Signal's loop |
| `play/04-deep-time.jpg` | `03-deep-time.jpg` | Endless Deep Time |
| `play/05-arrival.jpg` | — | Region arrival card (story) |
| `menu/06-research.jpg` | `04-research.jpg` | Research tree |
| `menu/07-lab.jpg` | `05-lab.jpg` | Ability loadout |
| `menu/08-wiki.jpg` | — | Archive: Story |
| `menu/09-home.jpg` | `06-home.jpg` | Home screen |

Apple Watch (`watch/`): `01-wrist-run.jpg`, `02-wrist-maps.jpg`, `03-relics.jpg`, `04-skills.jpg`.

## English (U.S.) listing

- Name: **ECHO: Survive Your Past**
- Subtitle: **Every route becomes a rival**
- Promotional text: **Carry the last light of the Lighthouse through 11 regions of space, outlive your own echoes, and dive into endless Deep Time — on iPhone, iPad and Apple Watch.**
- Keywords: `time,puzzle,arcade,survival,echo,maze,skill,laser,space,offline,watch,endless`
- Category: Games / Puzzle (secondary: Action)
- Age rating: complete against the shipped binary; the game has cartoon violence against abstract orbs, no accounts, and no user-generated content
- Support URL: `https://github.com/sergii-ziborov/Echo#support`
- Marketing URL: optional
- Privacy Policy URL: `https://github.com/sergii-ziborov/Echo/blob/main/PRIVACY.md`
- Terms of Use / custom EULA URL (optional): `https://github.com/sergii-ziborov/Echo/blob/main/TERMS.md`
- Copyright: © 2026 Sergii Ziborov

Suggested description:

> Your route becomes the hazard. After the Break, the Keepers' recovery network replays every recorded movement a few seconds late — including yours. Guide the Signal down the Fold Road, collect every spark, and reach the exit before your own route returns as an echo.
>
> • 77 handcrafted maps across 11 regions, each with its own sky, walls, hazards and recovered story records
> • Shattering asteroids of eight materials, beams, field wells, timed gates and fold faults
> • Deep Time: a separate expedition of generated arenas, each checked for a connected route
> • A Daily Rift that reopens one stop of the Road every day
> • A loadout of timed skills and the 24-node Signal Matrix
> • Apple Watch: thirty-six Keeper Chronometer rooms, rewards for the phone game, and a remote that steers your iPhone run
> • Two ratings, one for iPhone and one for Apple Watch
> • The Keeper Archive explains every rule, and science notes separate real physics from fiction
> • In English and Russian
>
> Progress stays on your device. No account, ads, in-app purchases or network connection needed.

Russian listing (add **Russian** under App Store Connect → the version's localizations). Subtitle: «Твой маршрут — твоя опасность».

> Твой маршрут становится опасностью. После Разлада сеть восстановления Хранителей повторяет каждое записанное движение с опозданием в несколько секунд — и твоё тоже. Веди Сигнал по Дороге складок, собирай все искры и доберись до выхода, пока твой же маршрут не вернулся эхом.
>
> • 77 карт в 11 регионах — у каждого своё небо, стены, опасности и восстановленные записи
> • Астероиды из восьми материалов, лучи, полевые ловушки, циклические шлюзы и разрывы Дороги
> • Глубокое время: отдельная экспедиция по сгенерированным аренам, у каждой проверен связный маршрут
> • Ежедневный разрыв каждый день заново открывает одну остановку Дороги
> • Способности с таймером и Матрица Сигнала из 24 узлов
> • Apple Watch: тридцать шесть комнат Хронометра Хранителей, награды для игры на iPhone и пульт, который управляет попыткой на телефоне
> • Два рейтинга: для iPhone и для Apple Watch
> • Архив Хранителей объясняет каждое правило, а научные заметки отделяют настоящую физику от вымысла
>
> Прогресс хранится на устройстве. Без аккаунта, рекламы, встроенных покупок и подключения к сети.

App Privacy answers: **no data collected**. Confirm against `PRIVACY.md` and the shipped binary before publishing.

App Review notes: no sign-in. Settings contains About, Terms, Privacy, Report a bug (a prefilled email), and a confirmed progress reset. The Apple Watch app is embedded: wrist maps play on their own, and Remote steers a map that is running on the paired iPhone. Contact email `sergii.ziborov@gmail.com`. Add a reachable phone number in App Store Connect.

## Submission sequence

1. Confirm the explicit App ID and the iOS app record. English (U.S.) primary language.
2. Archive 1.0.0 (19) with a release Xcode (or let Xcode Cloud archive it), validate, and upload. Wait for processing.
3. Attach screenshots, listing copy, support and privacy URLs, age rating, and content rights. Export compliance: the app uses only exempt encryption (`ITSAppUsesNonExemptEncryption` is false).
4. Choose **Paid** only after the Paid Apps Agreement is accepted. Set $1.99 and the intended countries.
5. Review the product page and submit. “Prepare for Submission” is not a public release.

Do not accept new Apple legal agreements or set a paid price without the account holder’s explicit decision.
