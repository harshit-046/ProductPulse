-- Business question: Which categories attract views and recorded purchase activity/value?
-- Calculation: event counts and summed purchase event prices grouped by category code; unknown category retained.
-- Output: category, views, unique_viewers, purchases, recorded_purchase_value, view_to_purchase_event_ratio.
-- Interpretation: Category comparison informs investigation; view/purchase event ratio is not a user conversion probability.
-- Assumptions: Missing category is labeled (unknown); recorded purchase value is not net revenue.
WITH agg AS (
 SELECT COALESCE(category_code,'(unknown)') AS category,
 COUNT(*) FILTER(WHERE event_type='view') AS views,
 COUNT(DISTINCT user_id) FILTER(WHERE event_type='view') AS unique_viewers,
 COUNT(*) FILTER(WHERE event_type='purchase') AS purchases,
 SUM(price) FILTER(WHERE event_type='purchase') AS recorded_purchase_value
 FROM events GROUP BY 1
)
SELECT *, ROUND(purchases::numeric/NULLIF(views,0),4) AS view_to_purchase_event_ratio
FROM agg ORDER BY recorded_purchase_value DESC NULLS LAST;

-- Session-based category conversion uses sessions with a view in that category as denominator;
-- purchase may concern another item in the same session and does not require ordering.
WITH per_session AS (
 SELECT COALESCE(category_code,'(unknown)') AS category, user_session,
        BOOL_OR(event_type='view') AS viewed,
        BOOL_OR(event_type='purchase') AS purchased
 FROM events WHERE user_session IS NOT NULL GROUP BY 1,2
)
SELECT category,
 COUNT(*) FILTER(WHERE viewed) AS view_sessions,
 COUNT(*) FILTER(WHERE purchased) AS purchase_sessions,
 ROUND(COUNT(*) FILTER(WHERE viewed AND purchased)::numeric / NULLIF(COUNT(*) FILTER(WHERE viewed),0),4) AS session_purchase_conversion
FROM per_session GROUP BY category ORDER BY view_sessions DESC;

-- Top brands, keeping unknown values visible.
SELECT COALESCE(brand,'(unknown)') AS brand,
 COUNT(*) FILTER(WHERE event_type='purchase') AS purchases,
 SUM(price) FILTER(WHERE event_type='purchase') AS recorded_purchase_value
FROM events GROUP BY 1 ORDER BY recorded_purchase_value DESC NULLS LAST LIMIT 25;
