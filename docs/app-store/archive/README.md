# Archive fragments, first route and arena framing

Current native SwiftUI/SpriteKit captures, verified on a fresh iPhone Duo simulator with iOS 27.1. The final run passed **47 tests with zero failures**. Screens include English and Russian at phone, outer Duo, inner Duo and iPad sizes.

Finds appear as a compact reward strip only after an attempt ends. The collection modal opens on request, shows stable fragment numbers and excerpts, and keeps Back to results visible while the grid scrolls. No encounter or region card interrupts a run; Home marks unread finds on the Archive button.

First launch is an optional interactive route: touch and drag the Signal, collect three sparks and meet a delayed echo. Its single contextual explanation follows the practice; the three topics can also be selected manually. Starting the game is always available. Practice spends no charges and never changes the collection.

The complete arena is drawn between the HUD (including temporary effects) and the footer. All sparks, full orbital paths, bonuses and exits were checked on all 77 maps across eight viewport sizes. Watch remote recipes rebuild the same world.

| Layout | Points | PNG pixels (2×) |
| --- | --- | --- |
| Phone | 390 × 844 | 780 × 1688 |
| Duo outer | 466 × 678 | 932 × 1356 |
| Duo inner | 669 × 951 | 1338 × 1902 |
| iPad portrait | 1032 × 1376 | 2064 × 2752 |
| iPad landscape | 1376 × 1032 | 2752 × 2064 |

`archive-{en,ru}-{layout}.png` shows the recovered collection. `language-*` shows Settings. `practice-*` shows the first route, and `results-finds-*` shows the optional reward strip. `arena-ru-*-map{21,40}.png` captures the live arena layout. These are documentation captures; phone and Duo renderings do not use App Store screenshot-slot dimensions.

Apple-size images are rendered at 3× for iPhone 6.9 and 6.5, and 2× for iPad, by `AppStoreSceneCaptures`, using the game’s actual window viewport. The native view captures omit system status-bar chrome. English images are in the main screenshot folders; matching Russian replacements are in `docs/app-store/ru/`.

Tests: `ArchiveDiscoveryTests`, `TutorialPracticeTests`, `QuietDiscoveryTests`, `ArenaFramingTests`, `GameViewCoverageTests`, `LocalizationTests`, `LoreTests`, and `WristLinkTests`.
