# ECHO App Store release guide

App Store Connect record: [ECHO: Survive Your Past](https://appstoreconnect.apple.com/apps/6811673094/distribution/ios/version/inflight), currently **Prepare for Submission**. Its explicit App ID `com.sergiiziborov.Echo` is registered. It is not yet public. Version 1.0.0 has been selected. All seven iPhone and five iPad screenshots are uploaded; the TestFlight build and required public-review fields are still missing.

## TestFlight build 1.0.0 (2)

The repository is prepared for the same Xcode Cloud release route used by GopherForge and Crabrix. `project.yml` and the checked-in Xcode project have build number **2**. `ci_scripts/ci_post_clone.sh` installs XcodeGen if needed and regenerates the project in the Cloud checkout. A local signed Release archive at `/tmp/EchoVariant2.xcarchive` and the iPhone simulator tests succeeded after the expanded sprite pass. This archive has **not** been uploaded to TestFlight yet; Apple sign-in and the Cloud workflow still require completion.

After signing in to App Store Connect in Chrome:

1. Open ECHO → Xcode Cloud and create or reuse a workflow connected to `sergii-ziborov/Echo` on `main`. Use manual start for the first run and a released Xcode/macOS environment.
2. Select **Archive - iOS**, **App Store Connect** distribution preparation, and **TestFlight Internal Testing** for the intended internal testing group. If Cloud assigns a different build number, set the next build number to **2** before running.
3. Start the workflow from the pushed source commit. Confirm that Build and Archive succeed, the reported app version is 1.0.0 (2), and App Store Connect finishes processing before assigning the build to testers. A successful archive alone is not a TestFlight delivery.

Suggested **What to Test**: compare the twelve asteroid appearances across four collision materials; collide breakable rocks with walls and check that cracks and chips progress without a countdown overlay; inspect the twelve wall finishes for seams and stretched textures, especially distant wall islands; check closed/red and open/cyan time-gate actuators, slow-field membranes and laser emitters; pause/freeze around timed hazards; check the map atlas and research tree on a phone.

## Prepared assets

The `docs/app-store/` screenshots are direct captures of the running app, converted to opaque JPEG. The `iphone-` images are 1320 × 2868 (6.9-inch portrait); the corresponding `iphone65-` upload variants are 1284 × 2778 (6.5-inch portrait). The `ipad-` images are 2064 × 2752 (13-inch portrait). The first image in each group shows gameplay rather than a splash screen. Keep the two device groups separate in App Store Connect and inspect the uploaded previews before saving. The iPad batch uploaded out of order; arrange it as gameplay, atlas, research, lab, home before submission.

| iPhone 6.5-inch upload | iPhone 6.9-inch source | iPad | Feature |
| --- | --- | --- | --- |
| `iphone65-01-gameplay.jpg` | `iphone-01-gameplay.jpg` | `ipad-01-gameplay.jpg` | Orb, asteroid, clocks and shield |
| `iphone65-02-lasers.jpg` | `iphone-02-lasers.jpg` | — | Laser hazard |
| `iphone65-03-atlas.jpg` | `iphone-03-atlas.jpg` | `ipad-02-atlas.jpg` | Regions and map route |
| `iphone65-04-research.jpg` | `iphone-04-research.jpg` | `ipad-03-research.jpg` | Upgrade tree |
| `iphone65-05-lab.jpg` | `iphone-05-lab.jpg` | `ipad-04-lab.jpg` | Ability loadout |
| `iphone65-06-wiki.jpg` | `iphone-06-wiki.jpg` | — | In-game guide |
| `iphone65-07-home.jpg` | `iphone-07-home.jpg` | `ipad-05-home.jpg` | Home screen |

## Proposed English (U.S.) listing

- Name: **ECHO: Survive Your Past**
- Subtitle: **Every route becomes a rival**
- Promotional text: **Draw a path, outlive its replay, and master 77 shifting maps.**
- Keywords: `time,puzzle,arcade,survival,echo,maze,skill,laser,space,offline`
- Category: Games / Puzzle (secondary: Action, if available and appropriate)
- Support URL: `https://github.com/sergii-ziborov/Echo#support`
- Privacy Policy URL after pushing this repository: `https://github.com/sergii-ziborov/Echo/blob/main/PRIVACY.md`

Suggested description:

> Your path comes back to hunt you. Steer the bright orb, collect sparks, and reach the exit before your recorded route turns into a dangerous Echo.
>
> Explore 77 maps across 11 visual epochs. Dodge shattering asteroids, pulsing lasers, gravity wells and reality rifts. Build a loadout of timed abilities, then grow a 24-node research tree to shape your speed, slots, shields and cooldowns.
>
> Clear optional seals, master each difficulty cycle, and use the in-game Wiki to learn every clock and hazard. Progress stays on your device. No account, ads or network connection are required to play.

Do not describe the app as being in Apple's Kids category or claim a public launch before approval. Confirm all marketing claims against the final release build.

## Submission sequence

1. Register the explicit App ID `com.sergiiziborov.Echo` and create an iOS app record in App Store Connect. Use English (U.S.) as the primary language and a stable SKU.
2. Verify signing, archive the release scheme, validate, and upload a uniquely numbered build. The local archive succeeded, but export/upload currently fails because Xcode's Apple Account lacks App Store Connect access for team `XMS5ZC28UJ`; signing in to Chrome does not authorize Xcode. Wait for App Store processing before selecting the build for version 1.0.0.
3. Complete the listing: the screenshot device groups, description, subtitle, keywords, support and privacy URLs, and age rating are saved. Reorder the iPad screenshots. Add an App Review contact phone, turn off sign-in required (the app has no accounts), finish content rights and export compliance, then publish the drafted App Privacy answer only after the account holder confirms its accuracy against the shipped binary and `PRIVACY.md`.
4. Set the distribution method to **Public** and choose the intended countries/regions. Decide whether the app is free or paid; a paid release may require the Paid Apps Agreement and financial setup.
5. Review the complete product page, choose release timing, submit for App Review, and wait for approval. “Prepare for Submission” or an uploaded build is **not** a public App Store release.

Do not accept new Apple legal agreements or choose a paid price without the account holder's explicit decision. Public App Store distribution does not make repository source code reusable; the current revision's terms are in `LICENSE`. Earlier MIT revisions remain MIT.
