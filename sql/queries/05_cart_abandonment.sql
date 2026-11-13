-- Business question: What portion of sessions containing a cart have no observed later purchase?
-- Calculation: cart sessions with no purchase after the first cart / sessions with any cart.
-- Output: cart_sessions, observed_abandoned_sessions, observed_session_cart_abandonment_rate.
-- Interpretation: Estimate of observed session-level abandonment, not permanent abandonment.
-- Assumptions: A purchase of any product in the same session counts as checkout completion; right-censoring and missing sessions limit inference.
WITH sessions AS (
 SELECT user_session, MIN(event_time) FILTER(WHERE event_type='cart') AS first_cart
 FROM events WHERE user_session IS NOT NULL GROUP BY user_session
), metrics AS (
 SELECT COUNT(*) FILTER(WHERE first_cart IS NOT NULL) AS cart_sessions,
        COUNT(*) FILTER(WHERE first_cart IS NOT NULL AND NOT EXISTS (
          SELECT 1 FROM events p WHERE p.user_session=s.user_session AND p.event_type='purchase' AND p.event_time> s.first_cart
        )) AS observed_abandoned_sessions
 FROM sessions s
)
SELECT cart_sessions, observed_abandoned_sessions,
 ROUND(observed_abandoned_sessions::numeric/NULLIF(cart_sessions,0),4) AS observed_session_cart_abandonment_rate
FROM metrics;
