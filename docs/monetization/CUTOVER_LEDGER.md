# ECHO paid-to-free acquisition ledger

Status: **AUTHORIZED AND APPLIED — freeQuiet rollout**. Updated 29 October 2026.

The owner explicitly requested completing the free + rare ads + one-time Remove Ads transition, and reported that there had been no paid customers. That sales statement is **OWNER_REPORTED**, not independently established by a sales-report export. Protection is retained regardless.

| Field | Verified value / evidence |
| --- | --- |
| App / bundle | 6811673094 / com.sergiiziborov.Echo, unchanged |
| Released compatible build | 1.1.0 (27), READY_FOR_SALE; not cancelled or withdrawn |
| Historical public build | 1.0.0 (18), returned by App Store version/build relationships |
| Paid builds | 18 and 27 were observed publicly while the download price was nonzero; upload history alone is not used |
| Historical free promotions / sales count | No paid customers per owner; complete historical report NOT RUN |
| Price change request | Accepted 2026-10-29T13:40:28.052158Z; USA base point 0, 174 automatic territories also 0 |
| Distribution | Existing 175 territories preserved; no country restriction introduced |
| Initial public observation | US reports 1.1.0 and USD 0; GB/IL initially retained older cached price/version |
| legacyEligibilityEnd | 2026-10-31T13:40:28Z |
| rolloutUncertaintyEnd | Same boundary; the whole 48-hour propagation/goodwill window is protected |
| Goodwill decision | Explicitly overgrant ad-free access to valid acquisitions of protected builds during 48 hours after the actual price-change request. This is a conservative implementation choice under the owner's instruction to preserve prior access, not proof of payment |
| Protected free build | 28, prepared 1.1.1, uses the separate `goodwillBuilds` field; it is not misreported as historically paid |
| Policy ID | echo-free-2026-10-29-v1 |
| Signed policy | v2 freeQuiet: purchases/legacy resolution enabled, no production ad requests; signature verified against the public key compiled into build 27 |
| Ads activation | Pending approval of the corrected advertising age declaration in 1.1.1 and the live-policy rollout; no false live claim |

Before the boundary, matching production acquisitions receive retained legacy evidence. Unknown/conflicting builds stay unresolved and ad-free. Sandbox/Xcode dates never generate production legacy. After the boundary, verified new free acquisitions without IAP are eligible only under all ad-policy rules; protected early acquisitions stay ad-free permanently. No local install date or current clock is substituted for StoreKit acquisition evidence. A later policy cannot revoke granted legacy rights.

The 48-hour window deliberately protects some initial free users too. Policy expiry fails closed; the prepared policy expires 28 November 2026 and must be renewed or replaced before then for continuing ad opportunities. Purchase rights and gameplay do not expire with it.

Evidence: FREE_PRICE_2026-10-29.json, CUTOVER_POLICY_2026-10-29.json, CUTOVER_TESTS_28.json, APP_STORE_RELEASE_27_2026-10-29.json. Hardware original-owner reinstall remains NOT RUN rather than a fabricated PASS. The owner's zero-buyer report does not delete the protection code.
