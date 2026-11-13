-- Business question: How many users appear in more than one observed session?
-- Calculation: Count distinct non-null sessions per user; classify as one or repeat session.
-- Output: user_group, users, share_of_users.
-- Interpretation: Repeat observed activity can support engagement hypotheses, not true retention since dataset boundaries are unknown.
-- Assumptions: Users with only null session IDs are omitted from session classification.
WITH user_sessions AS (
 SELECT user_id, COUNT(DISTINCT user_session) AS sessions
 FROM events WHERE user_session IS NOT NULL GROUP BY user_id
 HAVING COUNT(DISTINCT user_session) >= 1
), groups AS (
 SELECT CASE WHEN sessions>1 THEN 'repeat_session_users' ELSE 'one_session_users' END AS user_group,
        COUNT(*) AS users
 FROM user_sessions GROUP BY 1
), totals AS (SELECT SUM(users) AS total FROM groups)
SELECT g.user_group, g.users, ROUND(g.users::numeric/NULLIF(t.total,0),4) AS share_of_users
FROM groups g CROSS JOIN totals t ORDER BY g.user_group;
