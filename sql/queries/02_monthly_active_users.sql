-- Business question: How many distinct users were active in each calendar month, and how sticky was the service?
-- Calculation: Monthly distinct users / daily active users on the month's last observed date (approximate endpoint stickiness).
-- Output: month, monthly_active_users, month_end_dau, endpoint_dau_mau_stickiness.
-- Interpretation: Stickiness compares one day's activity with the month's reach; not cohort retention.
-- Assumptions: UTC calendar windows; incomplete first/last months are marked partial by date range.
WITH monthly AS (
  SELECT DATE_TRUNC('month', event_time AT TIME ZONE 'UTC')::date AS month,
         COUNT(DISTINCT user_id) AS monthly_active_users,
         MAX((event_time AT TIME ZONE 'UTC')::date) AS last_observed_date
  FROM events GROUP BY 1
), day_counts AS (
  SELECT (event_time AT TIME ZONE 'UTC')::date AS d, COUNT(DISTINCT user_id) AS dau
  FROM events GROUP BY 1
)
SELECT m.month, m.monthly_active_users, d.dau AS month_end_dau,
       ROUND(d.dau::numeric / NULLIF(m.monthly_active_users,0), 4) AS endpoint_dau_mau_stickiness,
       m.last_observed_date
FROM monthly m INNER JOIN day_counts d ON d.d=m.last_observed_date ORDER BY m.month;
