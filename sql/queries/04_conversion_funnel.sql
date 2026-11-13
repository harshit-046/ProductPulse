-- Business question: What share of observed sessions reaches each event stage?
-- Calculation: Distinct sessions with each event; stage rates use event presence, plus a separate ordered full-funnel count.
-- Output: view_sessions, cart_sessions, purchase_sessions, view_to_cart_rate, cart_to_purchase_rate, session_purchase_rate.
-- Interpretation: Rates use view-session, cart-session, and view-session denominators respectively.
-- Assumptions: Only sessions with IDs are included. Stages require a strictly later event timestamp; simultaneous ties are unordered.
WITH per_session AS (
 SELECT user_session,
   BOOL_OR(event_type='view') AS has_view,
   BOOL_OR(event_type='cart') AS has_cart,
   BOOL_OR(event_type='purchase') AS has_purchase,
   EXISTS (SELECT 1 FROM events v JOIN events c ON c.user_session=v.user_session AND c.event_type='cart' AND c.event_time>v.event_time WHERE v.user_session=e.user_session AND v.event_type='view') AS ordered_view_cart,
   EXISTS (SELECT 1 FROM events c JOIN events p ON p.user_session=c.user_session AND p.event_type='purchase' AND p.event_time>c.event_time WHERE c.user_session=e.user_session AND c.event_type='cart') AS ordered_cart_purchase,
   EXISTS (SELECT 1 FROM events v JOIN events c ON c.user_session=v.user_session AND c.event_type='cart' AND c.event_time>v.event_time JOIN events p ON p.user_session=c.user_session AND p.event_type='purchase' AND p.event_time>c.event_time WHERE v.user_session=e.user_session AND v.event_type='view') AS ordered_full_funnel
 FROM events e WHERE user_session IS NOT NULL GROUP BY user_session
), counts AS (
 SELECT COUNT(*) FILTER(WHERE has_view) AS view_sessions,
        COUNT(*) FILTER(WHERE has_cart) AS cart_sessions,
        COUNT(*) FILTER(WHERE has_purchase) AS purchase_sessions,
        COUNT(*) FILTER(WHERE has_view AND ordered_view_cart) AS ordered_view_cart,
        COUNT(*) FILTER(WHERE has_cart AND ordered_cart_purchase) AS ordered_cart_purchase,
        COUNT(*) FILTER(WHERE has_view AND ordered_full_funnel) AS ordered_full_funnel
 FROM per_session
)
SELECT view_sessions, cart_sessions, purchase_sessions,
 ROUND(ordered_view_cart::numeric/NULLIF(view_sessions,0),4) AS view_to_cart_rate,
 ROUND(ordered_cart_purchase::numeric/NULLIF(cart_sessions,0),4) AS cart_to_purchase_rate,
 ROUND(purchase_sessions::numeric/NULLIF(view_sessions,0),4) AS session_purchase_rate,
 ROUND(ordered_full_funnel::numeric/NULLIF(view_sessions,0),4) AS ordered_view_cart_purchase_rate,
 ordered_view_cart, ordered_cart_purchase, ordered_full_funnel
FROM counts;
