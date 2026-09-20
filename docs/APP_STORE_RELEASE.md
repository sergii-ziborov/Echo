# ECHO App Store release guide

App Store Connect record: [ECHO: Survive Your Past](https://appstoreconnect.apple.com/apps/6811673094/distribution/ios/version/inflight). App ID `com.sergiiziborov.Echo`. Version **1.0.0**, current build **17**. The listing is not public yet.

## Price and product type

Intended sale: **$1.99 USD one-time iOS app**. No ads, no in-app purchases, no subscriptions, no account. A paid price requires the account holder to accept the Paid Apps Agreement and complete banking/tax in App Store Connect before the price can be saved.

## TestFlight / Xcode Cloud

`project.yml` and the generated Xcode project use marketing version **1.0.0** and build **17**. `ci_scripts/ci_post_clone.sh` installs XcodeGen if needed and regenerates the project.

After signing in to App Store Connect:

1. Connect an Xcode Cloud workflow to `sergii-ziborov/Echo` on `main`.
2. Use **Archive - iOS**, **App Store Connect** distribution, and **TestFlight Internal Testing**.
3. Confirm the processed build is 1.0.0 (17) before assigning testers.

Suggested **What to Test**: player orb size and idle pulse; trail thickness near the head; asteroid fracture without a countdown overlay; wall seams; laser telegraph; Atlas, Lab, Wiki, and Settings → About / Terms / Privacy.

## Prepared assets

Screenshots are opaque JPEGs captured from the running app:

| Group | Size | Folder |
| --- | --- | --- |
| iPhone 6.9-inch | 1320 × 2868 | `docs/app-store/iphone/` |
| iPhone 6.5-inch | 1284 × 2778 | `docs/app-store/iphone65/` |
| iPad 13-inch | 2064 × 2752 | `docs/app-store/ipad/` |

Keep the two iPhone groups separate in App Store Connect. The first image in each group is gameplay, not a splash screen.

| iPhone 6.5-inch | iPhone 6.9-inch | iPad | Feature |
| --- | --- | --- | --- |
| `iphone65/play/01-gameplay.jpg` | `iphone/play/01-gameplay.jpg` | `ipad/01-gameplay.jpg` | Orb, asteroids, clocks |
| `iphone65/play/02-lasers.jpg` | `iphone/play/02-lasers.jpg` | — | Laser arena |
| `iphone65/menu/03-atlas.jpg` | `iphone/menu/03-atlas.jpg` | `ipad/02-atlas.jpg` | Timeline Atlas |
| `iphone65/menu/04-research.jpg` | `iphone/menu/04-research.jpg` | `ipad/03-research.jpg` | Research tree |
| `iphone65/menu/05-lab.jpg` | `iphone/menu/05-lab.jpg` | `ipad/04-lab.jpg` | Ability loadout |
| `iphone65/menu/06-wiki.jpg` | `iphone/menu/06-wiki.jpg` | — | In-game guide |
| `iphone65/menu/07-home.jpg` | `iphone/menu/07-home.jpg` | `ipad/05-home.jpg` | Home screen |

## English (U.S.) listing

- Name: **ECHO: Survive Your Past**
- Subtitle: **Every route becomes a rival**
- Promotional text: **Draw a path, outlive its replay, and master 77 shifting maps.**
- Keywords: `time,puzzle,arcade,survival,echo,maze,skill,laser,space,offline`
- Category: Games / Puzzle (secondary: Action)
- Age rating: complete against the shipped binary; the game has cartoon violence against abstract orbs, no accounts, and no user-generated content
- Support URL: `https://github.com/sergii-ziborov/Echo#support`
- Marketing URL: optional
- Privacy Policy URL: `https://github.com/sergii-ziborov/Echo/blob/main/PRIVACY.md`
- Terms of Use / custom EULA URL (optional): `https://github.com/sergii-ziborov/Echo/blob/main/TERMS.md`
- Copyright: © 2026 Sergii Ziborov

Suggested description:

> Your path comes back to hunt you. Steer the bright orb, collect sparks, and reach the exit before your recorded route turns into a dangerous Echo.
>
> Explore 77 maps across 11 visual epochs. Dodge shattering asteroids, pulsing lasers, gravity wells and reality rifts. Build a loadout of timed abilities, then grow a 24-node research tree to shape your speed, slots, shields and cooldowns.
>
> Clear optional seals, master each difficulty cycle, and use the in-game Wiki to learn every clock and hazard. Progress stays on your device. No account, ads or network connection are required to play.

App Privacy answers: **no data collected**. Confirm against `PRIVACY.md` and the shipped binary before publishing.

App Review notes: no sign-in. Settings contains About, Terms, Privacy, and a confirmed progress reset. Contact email `sergii.ziborov@gmail.com`. Add a reachable phone number in App Store Connect.

## Submission sequence

1. Confirm the explicit App ID and the iOS app record. English (U.S.) primary language.
2. Archive 1.0.0 (17), validate, and upload. Wait for processing.
3. Attach screenshots, listing copy, support and privacy URLs, age rating, and content rights. Export compliance: the app uses only exempt encryption (`ITSAppUsesNonExemptEncryption` is false).
4. Choose **Paid** only after the Paid Apps Agreement is accepted. Set $1.99 and the intended countries.
5. Review the product page and submit. “Prepare for Submission” is not a public release.

Do not accept new Apple legal agreements or set a paid price without the account holder’s explicit decision.
