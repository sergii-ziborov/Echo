# ECHO — The Fold Road website

A portable, bilingual static website for the world, philosophy, field guide, support and legal information of ECHO. Original lore and legal source text are retained in `sources/`; editorial interpretation is labeled as a reading of the game. Real game screenshots and existing ECHO artwork are optimized into `public/assets/`.

## Build and preview

Run `python3 build.py` and `python3 verify.py`, then `python3 -m http.server 4173 --directory dist`. No package installation or external services are required. The English homepage is `/`; Russian is `/ru/`. Every page has its own title, description, canonical URL and alternate language links.

## Move to another host

Change `origin` in `site.json` to the new HTTPS origin, rebuild, and upload all of `dist/` to any static host. Preserve directory URLs with `index.html` resolution. The sitemap and metadata rebuild for the new domain. `.openai/hosting.json` is only needed for the temporary Sites deployment.

When the app is publicly available, update the release status and add the actual App Store URL. The site currently states that ECHO is coming to the App Store.

## Content maintenance

`build.py` contains bilingual editorial and guide text. `sources/canon.json` keeps the game’s localized region and Archive text. Refresh it from `Shared/Localization/Localizable.xcstrings` when canon changes. Keep the app Privacy Policy and Terms source files in sync with the Echo repository; the Russian legal pages are faithful translations. Website hosting and app data handling are described separately.

The echo canvas is an explicitly labeled illustration, not a playable version of Echo. It pauses offscreen and does not autoplay when reduced motion is enabled. Its replay button supports keyboard use. The region atlas supports arrow keys, Home and End.
