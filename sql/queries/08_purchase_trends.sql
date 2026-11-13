-- Business question: How does recorded purchase activity and value vary over time?
-- Calculation: purchase event count, sum and average price; 7-observed-day moving average for daily value.
-- Output: purchase_date, purchase_events, recorded_purchase_value, average_item_price, rolling_7_day_value_avg.
-- Interpretation: Value sums prices on purchase events; it is not verified net revenue or profit.
-- Assumptions: UTC dates; rolling frame covers seven calendar dates after building a dense date series.
WITH daily AS (
 SELECT (event_time AT TIME ZONE 'UTC')::date AS purchase_date,
        COUNT(*) AS purchase_events, SUM(price) AS recorded_purchase_value, AVG(price) AS average_item_price
 FROM events WHERE event_type='purchase' GROUP BY 1
), bounds AS (SELECT MIN(purchase_date) AS lo, MAX(purchase_date) AS hi FROM daily), dense AS (
 SELECT d::date AS purchase_date FROM bounds, GENERATE_SERIES(lo,hi,INTERVAL '1 day') d
), complete AS (
 SELECT d.purchase_date, COALESCE(a.purchase_events,0) AS purchase_events,
        COALESCE(a.recorded_purchase_value,0) AS recorded_purchase_value, a.average_item_price
 FROM dense d LEFT JOIN daily a USING(purchase_date)
)
SELECT *, AVG(recorded_purchase_value) OVER (ORDER BY purchase_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7_day_value_avg
FROM complete ORDER BY purchase_date;
