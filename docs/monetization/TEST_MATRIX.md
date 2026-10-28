# R1 acceptance evidence

This table maps automated checks to the owner's matrix. Mock results are not physical StoreKit/Sandbox/ad-network verification. The final command counts and remaining gates are recorded in `REPORT.md`.

| Group | Automated evidence | Hardware / cabinet |
| --- | --- | --- |
| A01, A20–23, A26 | Legacy missing/unapproved/rollout/conflicting build, old Sandbox dates, preserved legacy with narrower policy | Actual approved cutover and price-history exports BLOCKED |
| A05–10 | Dynamic price, one purchase operation, cancelled/pending, listener delivery without purchase UI, durable grant before finish | Sandbox/TestFlight pending and approval on another device NOT RUN |
| A02–04, A11–19, A24 | Separate evidence cache; reset retention; empty enumeration/network/cache-read failure protected; unreadable evidence cannot be overwritten; verified refund preserves independent legacy; family gate | Paid owner update/reinstall/second device, account switch and family release NOT RUN |
| A25 | Verified Sandbox/Xcode selects explicit ordinary test policy; production preFree offers no repurchase | Actual product and review setup BLOCKED |
| B01–07, B09–14 | Pure policy checks protected levels/modes/discoveries, placement, minimum wins/time and rolling cap | Actual ready/no-fill creative behavior NOT RUN |
| B08, B15–19 | Duplicate run dedup, crash reservation recovery, backward clock, sticky Watch input, no historical-win migration | Device death/background/power-loss smoke NOT RUN |
| B20 | No rewarded, banner or app-open paths in R1 | R1.1 intentionally excluded |
| C01–12, C21–24 | Mock no-fill immediate Next; repeated callbacks; generation invalidation; purchase after preload; modal lock; leave/background cancellation; signed-policy tamper/expiry and bounded limits | Real SDK consent/refusal/late callbacks, ATT-denied environment and network audit NOT RUN |
| C13–14, C20 | Pinned iOS-only dependencies, separate release configuration, build artifact gate; no unconditional SDK start | Live IDs, cold-launch traffic and signed endpoint BLOCKED |
| C15–18 | EN/RU purchase/checking views rendered at compact phone and iPad sizes with large text; existing gameplay/Archive layout tests | Physical VoiceOver, orientation, controller, silent-mode/interruption NOT RUN |
| C19 | User-initiated mail path with limited safe fields; no automatic send | Inappropriate ad/network blocking workflow NOT RUN |
| D01–04 | Existing progress tests, 77-map save round trip, inventory/research retention, Watch wire/regression tests, duplicate win reward check | Real old-save/real account migration NOT RUN |
| D05–09 | preFree default, freeQuiet/live/adsOff pure states, signature and compiled caps; staged public copy | Price change, live policy, metadata/privacy deployment BLOCKED pending owner release step |
| D10 | No fixture is claimed as a real paid reinstall | NOT RUN |
| E01–10 | No rescue code, reward button or new currency is shipped | NOT RUN; separate R1.1 decision |

StoreKit Integration tests call the real StoreKit APIs against a local `.storekit` configuration. If the platform cannot install that configuration, this is reported as a blocked integration test, not converted into a fake purchase PASS. That test does not establish Sandbox, TestFlight or real paid-owner behavior even when it passes.
