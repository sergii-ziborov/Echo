# ECHO — The Fold Road website

A portable, bilingual static website for the world, philosophy, field guide, support and legal information of ECHO. Original lore and legal source text are retained in `sources/`; editorial interpretation is labeled as a reading of the game. Real game screenshots and existing ECHO artwork are optimized into `public/assets/`.

## Build and preview

Run `python3 build.py` and `python3 verify.py`, then `python3 -m http.server 4173 --directory dist`. No package installation or external services are required. The English homepage is `/`; Russian is `/ru/`. Every page has its own title, description, canonical URL and alternate language links.

## Move to another host

Change `origin` in `site.json` to the new HTTPS origin, rebuild, and upload all of `dist/` to any static host. Preserve directory URLs with `index.html` resolution. The sitemap and metadata rebuild for the new domain. `.openai/hosting.json` is only needed for the temporary Sites deployment.

The App Store link is fixed to app ID 6811673094. `site.json` defaults to `release_phase: preFree` with the verified paid download price USD 1.99. It does not announce a free release. Change phase only after the owner-approved price transition is observed: freeQuiet/freeLive/adsOff select free copy, zero download price in JSON-LD, restore/legacy FAQ and the EN/RU R1 legal sources. Remove Ads is explained separately from download price. Complete the actual privacy/provider/retention audit before publishing those R1 legal texts. The newer canonical hosted source is maintained separately through Sites. Site version 8 published the EN/RU transition-beta privacy and terms while retaining current paid public marketing. This older mirror retains matching transition legal sources without replacing the hosted 14-page source.

## Content maintenance

`build.py` contains bilingual editorial and guide text. `sources/canon.json` keeps the game’s localized region and Archive text. Refresh it from `Shared/Localization/Localizable.xcstrings` when canon changes. Keep the app Privacy Policy and Terms source files in sync with the Echo repository; the Russian legal pages are faithful translations. Website hosting and app data handling are described separately.

The echo canvas is an explicitly labeled illustration, not a playable version of Echo. It pauses offscreen and does not autoplay when reduced motion is enabled. Its replay button supports keyboard use. The region atlas supports arrow keys, Home and End.
