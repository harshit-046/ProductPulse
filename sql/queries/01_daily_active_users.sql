-- Business question: How many distinct users generated an event each UTC day?
-- Calculation: COUNT DISTINCT over all recorded event types; LAG compares prior calendar date.
-- Output: activity_date, daily_active_users, previous_day_users, dod_change.
-- Interpretation: A change in observed activity, not a measure of retention or product quality.
-- Assumptions: event_time is stored in UTC; source contains event activity only.
WITH daily AS (
  SELECT (event_time AT TIME ZONE 'UTC')::date AS activity_date,
         COUNT(DISTINCT user_id) AS daily_active_users
  FROM events GROUP BY 1
)
SELECT activity_date, daily_active_users,
       LAG(daily_active_users) OVER (ORDER BY activity_date) AS previous_day_users,
       daily_active_users - LAG(daily_active_users) OVER (ORDER BY activity_date) AS dod_change
FROM daily ORDER BY activity_date;
