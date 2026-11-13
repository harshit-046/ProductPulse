# Power BI Desktop setup

No `.pbix`/`.pbip` report was generated: Power BI Desktop is Windows-only and is not available in this WSL execution environment. The DAX and model specification are provided for a real desktop report.

1. Start the PostgreSQL service using the README commands. In Power BI Desktop choose **Get data → PostgreSQL database**.
2. Server: `localhost:5432`; database: `productpulse_db`; choose Import; authenticate with `.env` credentials.
3. Select `events`, create and mark the Calendar table as described in `data_model.md`, then add measures from `measures.dax`.
4. Create one 16:9 page with a light `#F5F7FA` canvas, navy `#17324D`, teal `#14B8A6`, white cards, 16 px page margins.
5. Top row: cards for Total Users, MAU (full calendar month containing the latest selected date), Total Sessions, Purchase Conversion Rate, Cart Abandonment Rate, Total Purchase Value.
6. Middle: line chart `Calendar[Date]` × DAU; funnel visual `View Sessions`, `Cart Sessions`, `Purchase Sessions`; horizontal bar `category_code` × Total Views.
7. Bottom: line chart `Calendar[Date]` × Total Purchase Value; category comparison with category views and purchase conversion. Conversion denominator should use view sessions consistently.
8. Add date, category, and brand slicers. Avoid an event-type slicer on the funnel page because it changes stage denominators. Enable cross-filtering and useful tooltips (views, unique viewers, purchases, value).
9. Save as `powerbi/dashboard/ProductPulse.pbix` and validate slicers, KPI denominators, and date interactions before sharing.
