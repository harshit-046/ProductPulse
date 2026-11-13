-- Business question: Which products attract attention but relatively few recorded purchases?
-- Calculation: event counts and distinct viewing sessions per product; purchase rate = purchase events / view events.
-- Output: product_id, views, unique_viewers, carts, purchases, view_event_purchase_ratio.
-- Interpretation: A low ratio is a prioritization signal for investigation, not proof a product is poor.
-- Assumptions: event-level ratio is descriptive; user_session may be missing.
WITH p AS (
 SELECT product_id,
   COUNT(*) FILTER (WHERE event_type='view') AS views,
   COUNT(DISTINCT user_id) FILTER (WHERE event_type='view') AS unique_viewers,
   COUNT(*) FILTER (WHERE event_type='cart') AS carts,
   COUNT(*) FILTER (WHERE event_type='purchase') AS purchases
 FROM events GROUP BY product_id
)
SELECT ROW_NUMBER() OVER(ORDER BY views DESC, product_id) AS view_rank,
       *, ROUND(purchases::numeric / NULLIF(views,0),4) AS view_event_purchase_ratio
FROM p WHERE views>0 ORDER BY views DESC, product_id LIMIT 100;

-- Business question: Which substantially viewed products have no recorded purchase events?
-- Calculation: Product-level view and purchase event counts; minimum 100 views avoids ranking one-off items.
-- Output: product_id, views, unique_viewers, carts, purchases, view_event_purchase_ratio.
-- Interpretation: Candidates for product-detail, price, and stock investigation; no purchase event is not proof of failure.
-- Assumptions: Event ratio is descriptive and the threshold is an analyst-selected screening rule.
WITH product_counts AS (
 SELECT product_id,
   COUNT(*) FILTER (WHERE event_type='view') AS views,
   COUNT(DISTINCT user_id) FILTER (WHERE event_type='view') AS unique_viewers,
   COUNT(*) FILTER (WHERE event_type='cart') AS carts,
   COUNT(*) FILTER (WHERE event_type='purchase') AS purchases
 FROM events GROUP BY product_id
)
SELECT *, ROUND(purchases::numeric/NULLIF(views,0),4) AS view_event_purchase_ratio
FROM product_counts WHERE views>=100 AND purchases=0 ORDER BY views DESC LIMIT 25;
