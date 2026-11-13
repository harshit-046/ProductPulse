# ProductPulse interview preparation

## A. Project introduction

**30 seconds:** “ProductPulse is a product analytics project using a public e-commerce event history. I built a Python cleaning and quality-reporting step, designed PostgreSQL event storage, and wrote SQL for engagement, session funnels, category behavior, and recorded purchase value. I prepared a Power BI model and DAX measures. I treat the findings as behavioral signals because the dataset has no order reconciliation or signup data.”

**60 seconds:** Add that the raw file has 885,129 rows and nine fields. Missing brand/category/session values remain unknown rather than causing event deletion. Exact duplicate rows are reported and retained because there is no event ID to prove they are errors. Funnel steps use distinct sessions and chronology. The recommendations are investigation hypotheses, not measured business impact.

**2 minutes:** Explain source and limits, cleaning rules, the indexed event table, SQL definitions, Power BI design, and one example: a product with high views and relatively low purchase events could merit an inspection of its product information, price, availability, or checkout context. Then describe a controlled test with view-to-cart conversion as the primary metric and purchase progression as a guardrail. Avoid claiming causation from this observational dataset.

## B. Architecture walkthrough

1. The CSV comes from Michael Kechinov's Kaggle dataset, not from personally collected users.
2. Pandas parses UTC time and checks event type, identifiers, and nonnegative price. It keeps rows with unknown brand/category/session and records duplicate observations.
3. PostgreSQL gives durable typed storage and lets analysts reuse indexed event data.
4. SQL aggregates by date, product, category, user, or session. The grain and denominator change with the business question.
5. Power BI imports the event table, relates a calendar dimension, and presents measures with slicers; event-type filters should not silently remove funnel stages.
6. Findings lead to product hypotheses and metric plans, not assertions that a change caused an outcome.

## C. SQL questions and answers

1. **What does a JOIN do?** Combines rows using a relationship; aggregate after checking join cardinality to avoid duplication.
2. **INNER vs LEFT JOIN?** Inner keeps matches only; left keeps every left row and fills unmatched right columns with null.
3. **What is GROUP BY?** It creates groups so aggregate functions return one result per group.
4. **WHERE vs HAVING?** WHERE filters source rows before grouping; HAVING filters aggregate groups afterward.
5. **COUNT(*) vs COUNT(column)?** The first counts rows; the second excludes null values.
6. **COUNT DISTINCT?** Counts unique non-null values, appropriate for distinct users or sessions.
7. **What is a CTE?** A named query block (`WITH`) that makes multi-step logic easier to read.
8. **What is a window function?** Calculates across related rows without collapsing them, e.g. `LAG` alongside daily counts.
9. **ROW_NUMBER vs RANK?** Row number assigns a unique sequence; rank preserves ties and can skip following numbers.
10. **What does LAG do?** Reads a preceding row in an ordered partition; used for day-over-day comparison.
11. **What is DATE_TRUNC?** Buckets timestamps to a boundary such as month start.
12. **How would you calculate DAU?** Group by UTC date and count distinct user IDs with any event.
13. **How would you calculate MAU?** Group by calendar month and count distinct user IDs; do not sum DAU.
14. **Why not sum daily users for MAU?** The same person can be active on many days; distinct users across the month is the correct grain.
15. **How is stickiness calculated here?** DAU from the last observed date in each month divided by that month's distinct users; disclose endpoint choice.
16. **How do you avoid event inflation in a funnel?** First reduce events to one row per session with stage flags/timestamps, then count sessions.
17. **Why chronology?** A cart timestamp before a view should not count as view-to-cart progression.
18. **What is observed abandonment?** Cart sessions without a later purchase in the observed extract divided by cart sessions.
19. **Why can joins inflate purchase value?** One-to-many joins duplicate purchase rows; aggregate at event grain before joining dimensions.
20. **How can you select top viewed products?** Group by product, count only view events, order descending, and limit; report purchase behavior separately.

**Funnel query explanation:** `per_session` creates one row per non-null session and obtains first event timestamps using filtered `MIN`. `counts` counts flags and ordered timestamp combinations. Final `NULLIF` protects zero denominators. It distinguishes sessions that contain an event from sessions that complete an ordered progression.

## D. Product analytics questions and answers

1. **What problem does ProductPulse solve?** It turns raw event rows into interpretable engagement and conversion measures.
2. **DAU?** Distinct users with at least one event on a day.
3. **MAU?** Distinct users with at least one event in a calendar month.
4. **Stickiness?** A measure of daily activity relative to monthly reach; definition must state which DAU is used.
5. **Conversion rate?** Users or sessions completing a target action divided by an explicitly defined eligible population.
6. **Funnel?** Ordered stages that show how an eligible cohort progresses through a journey.
7. **Cart abandonment?** Cart-eligible sessions without an observed later purchase; incomplete journeys make it an estimate.
8. **Why might users abandon?** Price, delivery terms, stock, usability, payment, or simply later purchase; the data alone does not identify cause.
9. **Retention?** Return activity in a later period among a defined cohort; this dataset lacks signup dates, so repeat sessions are not true retention.
10. **Segmentation?** Comparing behavior across meaningful groups such as category or brand while checking sample size and bias.
11. **How identify a product problem?** Locate a metric change or segment gap, validate instrumentation and denominators, then investigate user context.
12. **How prioritize improvements?** Consider user impact, evidence, effort, risk, and strategic fit; state uncertainty.
13. **How measure product success?** Define a primary outcome, eligible population, timeframe, and guardrails before launch.
14. **What if conversion falls?** Check data freshness, event definitions, traffic mix, funnel stages, device/segment patterns, and release timeline.
15. **How improve onboarding?** Identify where intended users fail to reach value, test a focused intervention, and track completion plus guardrails.
16. **How communicate to a PM?** Lead with decision, metric and denominator, evidence window, uncertainty, recommendation, and next measurement.
17. **Post-launch metrics?** Adoption, task completion, repeat use, conversion, and guardrails such as errors or cancellations.
18. **Leading vs lagging indicators?** Leading signals may precede outcomes; lagging results confirm outcomes later. Validate the relationship.
19. **How design an A/B test?** Randomize eligible units, predefine hypothesis, primary metric, guardrails, duration/sample plan, and analysis.
20. **Correlation vs causation?** Correlation is co-movement; causation requires a design or assumptions that rule out alternatives.

## E. Technical counterquestions

- **Why PostgreSQL?** Strong SQL support, constraints, indexes, transactions, and broad local tooling; the project uses standard relational concepts.
- **Why SQL instead of only Pandas?** SQL makes reusable database-side aggregation and clear grain explicit; Pandas handles ingestion and cleaning well.
- **Why Power BI?** It lets stakeholders filter and explore the defined measures; visualization does not replace metric governance.
- **What is DAX?** Power BI's expression language for measures and calculated tables/columns.
- **Why separate database?** It stores typed, queryable data independently from the raw file and supports repeatable analytical queries.
- **Why clean data?** Invalid timestamps, IDs, and prices can distort groupings and rates; unknown optional attributes should be preserved.
- **Why indexes?** They can accelerate common filters and joins at the cost of storage and slower writes; choose based on query patterns.
- **How handle missing values?** Keep valid events and mark missing descriptive/session fields as unknown; exclude from analyses needing that field.
- **How scale?** Partition by event date, load incrementally with stable IDs, monitor query plans, and consider a warehouse if needs grow.
- **Limitations?** Historical e-commerce data, incomplete journeys, no verified orders/revenue/signup/marketing context, and no causal evidence.

## F. Honest project discussion

The workspace supplies the Kaggle CSV. The repository includes a cleaning pipeline, a database schema, eight analysis query files, KPI definitions, tests, DAX measures, a data model, and a Power BI build guide. PostgreSQL validation and SQL analyses have been executed on the supplied extract; use their exported CSVs when discussing numerical findings. Power BI Desktop must still be used to assemble and validate the report. Recommendations are hypothetical investigation plans. The project demonstrates skills relevant to product analysis—metric definitions, behavior analysis, SQL, data quality, communication, and experiment thinking—without implying MoveInSync data or experience.
