# Product insights

## Executive summary

This is an observational history for an electronics e-commerce site, not MoveInSync product telemetry. PostgreSQL validation and all SQL analyses were run on the 885,129-row extract. The results show that view sessions often do not progress to cart, about half of observed cart sessions have no later purchase event, repeat sessions are limited to a subset of users, and category performance varies. These are investigation signals, not explanations of user intent or causal evidence.

## Key findings from the cleaned CSV

These figures come from the PostgreSQL validation query and SQL outputs under `reports/generated/sql/`. They cover the full recorded range, 2020-09-24 through 2021-02-28 UTC. SQL exports are generated locally and ignored by Git; rerun `python scripts/run_analytics.py` to recreate them.

1. **Observed event volume:** 793,748 views, 54,035 cart events, and 37,346 purchase events. Events are not users or sessions, so this mix is descriptive and not a conversion rate.
2. **Session funnel:** 488,360 sessions contained a view and 41,270 contained a cart. The chronological view-to-cart rate is 8.44% (41,222 sessions with view before cart / view sessions). Of cart sessions, 20,717 had a later purchase, giving 50.20% cart-to-purchase conversion. The ordered full view→cart→purchase rate is 4.24% of view sessions; any-purchase session conversion is 4.98%.
3. **Observed cart abandonment:** 20,553 of 41,270 cart sessions (49.80%) had no later purchase event in the same session. This is observed session-level abandonment, not a count of permanently abandoned carts.
4. **Repeat observed sessions:** 52,347 of 407,237 users with at least one non-null session ID had multiple sessions (12.85%). This does not establish retention because there is no signup date or guarantee of complete user history.
5. **Category coverage and outcomes:** 236,219 rows (26.7%) lack `category_code`; unknown-category events include 218,242 views. Named category `computers.components.videocards` led in recorded purchase value (2,604,764.80) and had 44,083 view sessions with 9.85% session purchase conversion. The `computers.peripherals.camera` category had 13.07% session purchase conversion across 2,532 view sessions. Category conversion counts a session with both a view and purchase for that category; it does not require event order or prove a same-product purchase. Differences are descriptive and should be checked for sample and mix effects.
6. **Recorded purchase value:** Purchase events summed to 5,125,395.62 in unspecified currency units; average purchase-event price was 137.24. This is not net revenue or profit.
7. **Daily and monthly activity:** DAU ranged from 1,358 on the partial first date (2020-09-24) to 4,287 on 2020-11-18; mean DAU was 2,955.9. November had the highest MAU (92,600); September is a partial month and should not be compared directly with full months.
8. **High-view, zero-purchase examples:** Product 229036 had 1,150 views, 808 unique viewers, 9 cart events, and no purchase event. Product 775032 had 1,087 views, 828 unique viewers, and no cart or purchase event. These are candidates to check for availability, pricing, or product-detail issues; zero recorded purchases does not prove the items failed to convert.

## Recommendations

1. **Improve category metadata coverage.** Because 26.7% of rows have no category code and unknown-category views are the largest group, investigate upstream taxonomy mapping. Track the unknown-category share and category session conversion after correction.
2. **Investigate high-view, zero-purchase products.** Check stock, price, product detail quality, and whether views are concentrated in a few users. Track ordered view-to-cart and session purchase conversion for the affected products, with enough eligible sessions to interpret changes.
3. **Review cart progression.** The observed session cart-abandonment rate is 49.80%. Inspect checkout steps and the observation window before changing the experience; track later-purchase session rate and recorded purchase value per view session as a guardrail.

The observations do not prove why users behave this way, and the recommendations are hypotheses rather than demonstrated business impact.

## Hypothetical experiment

Hypothesis: showing clearer delivery and return information on product pages may improve progression from product view to cart. Control: current page. Treatment: concise delivery/return summary. Primary metric: chronological session-level view-to-cart conversion. Guardrail: session purchase conversion and recorded purchase value per view session. Investigate further only if the pre-specified primary metric improves without a material guardrail decline; randomization, sample sizing, and a fixed duration would be required before a real test.
