-- Dataset and warehouse checks. Every row should satisfy schema constraints after load.
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT user_id) AS distinct_users,
       COUNT(DISTINCT user_session) AS distinct_sessions,
       MIN(event_time) AS first_event_utc,
       MAX(event_time) AS last_event_utc,
       COUNT(*) FILTER (WHERE user_session IS NULL) AS missing_session_rows,
       COUNT(*) FILTER (WHERE category_code IS NULL) AS missing_category_rows,
       COUNT(*) FILTER (WHERE brand IS NULL) AS missing_brand_rows,
       COUNT(*) FILTER (WHERE price < 0) AS negative_price_rows
FROM events;

SELECT event_type, COUNT(*) AS event_count,
       COUNT(DISTINCT user_id) AS distinct_users,
       COUNT(DISTINCT user_session) AS distinct_sessions
FROM events GROUP BY event_type ORDER BY event_type;
