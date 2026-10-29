# Eleven places, eleven original illustrations

Replaced the website Atlas's CSS spheres, rings and colored shapes for all eleven regions. The new illustrations show the actual narrative places: Lighthouse relay and blue ringed giant; abandoned orbital gardens; Tessera's ice fissures; Cinder's remains; the verification array and pulsar; Ashcrown optical receivers; damaged transfer frames; Undertow's compact remnant; glass optics; pastel training habitat; and the first light of Last Dawn.

Images were generated separately with the built-in image tool, reviewed individually, encoded as JPEG without changing their compositions, and saved in [website/public/assets/regions](../../website/public/assets/regions/). Native EN/RU titles, map ranges, alt text and the label “Atlas illustration” remain outside the bitmap. These are original artistic views of ECHO's fiction, not screenshots or scientific photographs. The same image files serve both languages; the three world previews on Home now use the matching art.

Removed the placeholder-specific CSS. Fixed an observed tablet/desktop gap above the image and increased small region-tab labels. Browser checks confirmed all eleven regions decode and switch correctly across five EN/RU viewport combinations (55 cases), with no horizontal page overflow. After the spacing/type adjustment, final 375px RU, 768px RU and default desktop views were checked again. This is responsive browser QA, not physical iPad testing.

- [Final desktop EN view](atlas-illustrations-desktop-en.png)
- [Final mobile RU view](atlas-illustrations-mobile-ru.png)
- [Final tablet RU view](atlas-illustrations-tablet-ru.png)
- [Browser evidence](ATLAS_BROWSER_QA_2026-10-29.json)
- [Exact prompts](ATLAS_ILLUSTRATION_PROMPTS_2026-10-29.json)
- [Generation files, checksums and final assets](ATLAS_ILLUSTRATION_PROVENANCE_2026-10-29.json)

This is a website-only change. ECHO 1.1.0 (27) remains available in Keepers TestFlight and is submitted with Remove Ads for App Review. No app bundle, price, paid-owner boundary or live advertising flag changed with this artwork correction.
