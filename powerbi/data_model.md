# Power BI data model

Import `events` from PostgreSQL (`productpulse_db`) and create a calculated `Calendar` table:

```DAX
Calendar =
ADDCOLUMNS(
    CALENDAR(MIN(events[event_time]), MAX(events[event_time])),
    "Year", YEAR([Date]), "Month", FORMAT([Date], "YYYY-MM"),
    "MonthStart", DATE(YEAR([Date]), MONTH([Date]), 1)
)
```

Mark Calendar as the date table and create a one-to-many relationship from `Calendar[Date]` to `events[event_time]` (use a date-only `Event Date = DATE(YEAR(events[event_time]),MONTH(events[event_time]),DAY(events[event_time]))` column if necessary). Keep the relationship single-direction. Use the event table's `category_code` and `brand` for slicers; use purchase-event filter context in the measures. Do not filter `events` to only purchases for funnel cards, or the view/cart denominators disappear.

`Total Users` counts the user population present in the current filter context; `Active Users` is equivalent. MAU returns distinct users for the full calendar month containing the latest selected date, matching SQL's calendar-month definition. Funnel session measures count distinct non-null session IDs. The chronology-sensitive cart abandonment measure checks for a purchase after the first cart; SQL query 05 is canonical. DAX funnel stage cards count sessions containing each event; purchase conversion is purchase sessions / view sessions, consistent with SQL `session_purchase_rate`. SQL separately reports ordered view→cart→purchase progression.
