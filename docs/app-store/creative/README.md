# App Store header and search artwork

The iOS 1.0.0 product page uses the same language-neutral ECHO scene for English (U.S.) and Russian. The cyan Signal draws a route while its magenta echo follows it; the gold rings evoke the Fold Road exits. This is promotional key art, not a gameplay screenshot.

| Placement | File | Pixels | App Store Connect asset ID |
| --- | --- | --- | --- |
| Product page header | `header-3840x1646.png` | 3840 × 1646 | `5d400019-601e-8206-8039-0c5211634544` |
| Search results | `search-2880x1920.png` | 2880 × 1920 | `12000019-601e-8206-8033-b250916d3f46` |

Both PNGs are opaque RGB and are placed on the `en-US` and `ru` iOS version localizations. Apple processed each asset to `PREPARE_FOR_SUBMISSION`; all four placements are `ACTIVE`. The version still needs App Review approval before the art appears on the public App Store.

`echo-key-art-source.png` is the original generated scene. The two deliverables are center crops of that scene, resized to Apple's placement specifications. Regenerate the crops from the source if a new size is required; do not stretch one placement's final PNG into the other shape.

Art direction prompt: “Deep navy space; a tiny luminous cyan player signal on a precise curved route; its offset magenta ghost trail follows the same path; warm gold sparks and ring-like Fold Road exits; distant cracked planets and restrained asteroids. The player's past path becomes the danger. No text, logo, UI or device frame.”

Apple's [creative asset specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications) define these image sizes and prohibit alpha. The [Asset Library guide](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets) explains version placement, preview and review.
