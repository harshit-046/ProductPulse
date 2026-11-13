# KPI definitions

All dates use UTC. `user_id` metrics are user-level; funnel and abandonment metrics are session-level. Event values are descriptive of the recorded source.

| KPI | Definition / SQL calculation | Denominator | Window | Significance | Limitations |
|---|---|---|---|---|---|
| DAU | `COUNT(DISTINCT user_id)` with an event per UTC date | None | Calendar day | Daily observed reach | Not necessarily human or signed-in active users |
| MAU | Distinct users with any event in calendar month | None | Calendar month | Monthly observed reach | Partial edge months; not rolling 30 days |
| DAU/MAU stickiness | Last observed day's DAU / calendar-month MAU | Month MAU | Month endpoint | Daily intensity relative to monthly reach | One endpoint day, not monthly average retention |
| Unique product viewers | Distinct users where event_type=view per product | None | Selected period | Product reach | Repeat sessions and anonymous IDs affect interpretation |
| Product view count | Count of view events | None | Selected period | Attention volume | Repeated views count repeatedly |
| View-to-cart conversion | Sessions with later cart / sessions with view | View sessions | Selected period | Progression to cart | Session-level; SQL funnel requires chronology |
| Cart-to-purchase conversion | Sessions with later purchase / cart sessions | Cart sessions | Selected period | Checkout completion after cart | Purchase may concern another item in that session |
| Session purchase conversion | Sessions with any purchase / sessions with a view (`session_purchase_rate`); query also reports ordered view→cart→purchase separately | View sessions | Selected period | Overall session-level purchase outcome | Purchase may precede the view or involve another product; inspect the ordered full-funnel rate separately |
| Observed cart abandonment | Cart sessions without a later purchase / cart sessions | Cart sessions | Selected period | Potential checkout friction signal | Not permanently abandoned; incomplete window and cross-product purchases |
| Repeat user rate | Users with >1 non-null observed session / users with ≥1 non-null session | Session-observed users | Full extract | Repeated observed usage | Not cohort retention; no signup or complete identity history |
| Recorded purchase value | Sum of `price` for purchase events | None | Day/month/selection | Relative value trend | Not verified revenue, net of refunds, tax, quantity, or order reconciliation |

The SQL files provide canonical query definitions. Funnel rates deliberately use session denominators. Product event purchase/view ratio is a different descriptive event ratio and must not be described as session conversion.
