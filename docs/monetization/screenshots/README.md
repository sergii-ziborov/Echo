# Native purchase UI captures

Twelve unedited XCTest attachments from `/tmp/echo-monetization-sdk-accepted.xcresult`: EN/RU, 320×568 and 393×852 point phone layouts, 1024×768 point iPad layout, regular text and accessibility2 checking/error state. These are native SwiftUI renders in the isolated iOS 26.5 simulator, not physical-device or StoreKit purchase screenshots.

The displayed ₪7.90 is supplied by the fake client's `displayPrice` fixture. It proves that the view accepts a localized StoreKit-style value; it does not establish a real storefront price or a successful payment. The compact large-text view scrolls, while its 44-point close button stays pinned and visible. No image pixels were edited.

Export command and the final result bundle are recorded in [REPORT.md](../REPORT.md). Do not upload these as evidence of a real purchase without completing the actual SKU/Sandbox review path.

`release-cold-start.png` is a separate actual SDK-free Release cold-start capture of the entry screen, not a purchase fixture.
