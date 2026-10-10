# ECHO App Store release guide

App Store Connect record: [ECHO: Survive Your Past](https://appstoreconnect.apple.com/apps/6811673094/distribution/ios/version/inflight). App ID `com.sergiiziborov.Echo`. Version **1.0.0**, local project build **20**. The listing is not public yet.

## Price and product type

Intended sale: **$1.99 USD one-time iOS app**. No ads, no in-app purchases, no subscriptions, no account. A paid price requires the account holder to accept the Paid Apps Agreement and complete banking/tax in App Store Connect before the price can be saved.

## TestFlight / Xcode Cloud

`project.yml` and the generated Xcode project use marketing version **1.0.0** and local build **20**. Xcode Cloud numbers its own builds. `ci_scripts/ci_post_clone.sh` installs XcodeGen if needed and regenerates the project.

After signing in to App Store Connect:

1. Connect an Xcode Cloud workflow to `sergii-ziborov/Echo` on `main`.
2. Use **Archive - iOS**, **App Store Connect** distribution, and **TestFlight Internal Testing**.
3. Confirm that the latest processed build is available to the Keepers internal group.

Suggested **What to Test**: on iPad, inspect the two-column Atlas and Home in portrait and landscape, then narrow the window to check the compact layout; change the two equipped abilities, inspect live research effects and cross-branch prerequisites, and buy a single charge; check the compact outer and side-by-side inner iPhone Duo layouts; region arrival cards and Deep Time; the Apple Watch app on its own and as a remote for a phone run.

## Prepared assets

The iPhone, iPad and Watch screenshots are opaque JPEGs captured from the running app. Duo uses opaque PNG renderings of the same SwiftUI views at its display sizes:

| Group | Size | Folder |
| --- | --- | --- |
| iPhone 6.9-inch | 1320 × 2868 | `docs/app-store/iphone/` |
| iPhone 6.5-inch | 1284 × 2778 | `docs/app-store/iphone65/` |
| iPad 13-inch | 2064 × 2752 | `docs/app-store/ipad/` |
| iPhone Duo outer display | 1398 × 2034 | `docs/app-store/duo/` |
| iPhone Duo inner display | 2007 × 2853 | `docs/app-store/duo/` |
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
| `menu/10-recharge.jpg` | — | Buy one ability charge |

Apple Watch (`watch/`): `01-wrist-run.jpg`, `02-wrist-maps.jpg`, `03-relics.jpg`, `04-skills.jpg`.

The Lab captures show the simplified loadout, exact research dependencies, live upgrade effects and one-charge prices. Run `scripts/capture_app_store_shots.sh` to regenerate the complete iPhone and iPad sets, or `scripts/capture_lab_shots.sh` for just the Lab screens. The full capture script looks up the three `Echo Shots` simulators by name.

Run `scripts/capture_watch_shots.sh` for the four Watch screenshots. It uses the `Echo Shots Watch 46` simulator and an eight-second run capture so the gameplay image shows a live room. Watch screenshots retain the simulator clock because watchOS does not support status bar overrides.

The Duo set contains `duo-outer-loadout.png`, `duo-outer-research.png`, `duo-inner-loadout.png` and `duo-inner-research.png`. They are rendered from the actual SwiftUI Lab at Apple's outer and inner display sizes by `LabCoverageTests.testDuoOuterAndInnerDisplayLayouts`. Xcode 27.0 on this Mac does not include a Duo simulator, so the test verifies layout at the exact viewports but does not replace a device or Duo simulator run. Recheck both displays when that simulator is installed.

The English (U.S.) App Store version has 10 screenshots in each large iPhone group, 6 for iPad, 4 for Duo and 4 for Apple Watch. The Russian product page uses the same image set. Game Center's localized leaderboard names are **iPhone** and **Apple Watch** in English and Russian; keep them short so the ranked card does not wrap.

The Product Page Information → Header and Search Results tab uses two language-neutral creative assets in both localizations. The [creative artwork manifest](app-store/creative/README.md) records the source, final sizes and App Store Connect asset IDs. These are key art alongside the separate device screenshots. Check Apple's iPhone and iPad previews before resubmitting the version.

The iOS and Watch icons are included in the uploaded build's asset catalog and appear under **Included Assets** after a build is associated with version 1.0.0. The generic thumbnail in Xcode Cloud's navigation is a separate App Store Connect display state.

## Product page copy and search terms

The current English (U.S.) and Russian names, subtitles, promotional text, descriptions and keywords are in [the listing source](app-store/LISTING.md). Keep both App Store Connect localizations aligned with that file. The copy describes the 36 Watch rooms, optional Game Center, the iPad layout, and the current Lab economy; older copy describing twelve Watch rooms is obsolete.

- Primary category: Games, with Puzzle and Action as its two game subcategories.
- Support URL: `https://github.com/sergii-ziborov/Echo#support`.
- Privacy Policy URL: `https://github.com/sergii-ziborov/Echo/blob/main/PRIVACY.md`.
- Copyright: © 2026 Sergii Ziborov.

App Privacy answers: **no data collected**. Confirm against `PRIVACY.md` and the shipped binary before publishing.

App Review notes: no sign-in. Settings contains About, Terms, Privacy, Report a bug (a prefilled email), and a confirmed progress reset. The Apple Watch app is embedded: wrist maps play on their own, and Remote steers a map that is running on the paired iPhone. Contact email `sergii.ziborov@gmail.com`. Add a reachable phone number in App Store Connect.

## Submission sequence

1. Confirm the explicit App ID and the iOS app record. English (U.S.) primary language.
2. Archive 1.0.0 (20) with a release Xcode (or let Xcode Cloud archive it), validate, and upload. Wait for processing.
3. Attach screenshots, listing copy, support and privacy URLs, age rating, and content rights. Export compliance: the app uses only exempt encryption (`ITSAppUsesNonExemptEncryption` is false).
4. Choose **Paid** only after the Paid Apps Agreement is accepted. Set $1.99 and the intended countries.
5. Review the product page and submit. “Prepare for Submission” is not a public release.

Do not accept new Apple legal agreements or set a paid price without the account holder’s explicit decision.
