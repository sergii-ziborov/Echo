# ECHO 1.1.0 (27) — release requested and READY_FOR_SALE

On 29 October 2026 the owner authorized release after approval ("go"). Before the mutation, Apple's API independently confirmed version 1.1.0, VALID build 27, PENDING_DEVELOPER_RELEASE, completed review and an approved Remove Ads product. The public `POST /v1/appStoreVersionReleaseRequests` request succeeded at approximately 13:01 UTC. Its returned release-request ID is the application version ID. An immediate independent version read returned **READY_FOR_SALE**.

This was a release of the approved binary and its saved metadata only. No price schedule, original-owner cutoff, advertising policy, Family Sharing, contract or privacy-account setting was changed. Production remains preFree with live ads disabled. The remaining paid-to-free safety gates are still open. This release does not claim to have completed the blocked hardware visual run or original paid-owner reinstall checks.

The immediate public US and Israel lookup still returned 1.0.0 at 13:01:27 UTC; storefront distribution was therefore pending at that check, rather than independently confirmed everywhere. US price remained USD 1.99 and Israel ILS 4.90. No worldwide propagation or free-price claim is inferred from READY_FOR_SALE.

[Machine-readable release and public-lookup evidence](APP_STORE_RELEASE_27_2026-10-29.json). [Approval evidence](APP_REVIEW_27_2026-10-29.json). No application rebuild or retest was needed for this server-side release action.
