"""Bulk load the cleaned CSV into PostgreSQL with an idempotent table reload."""
import argparse
import os
from pathlib import Path

import psycopg


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=Path(os.getenv("CLEAN_DATA_PATH", "data/processed/events_clean.csv")))
    args = parser.parse_args()
    dsn = os.getenv("DATABASE_URL")
    if not dsn:
        raise SystemExit("Set DATABASE_URL (copy .env.example to .env and export its values).")
    if not args.input.exists():
        raise SystemExit(f"Cleaned file not found: {args.input}. Run scripts/clean_data.py first.")
    with psycopg.connect(dsn) as conn, conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE events RESTART IDENTITY")
        with cur.copy("COPY events (event_time,event_type,product_id,category_id,category_code,brand,price,user_id,user_session) FROM STDIN WITH (FORMAT CSV, HEADER TRUE, NULL '')") as copy:
            with args.input.open("rb") as f:
                while chunk := f.read(1024 * 1024):
                    copy.write(chunk)
        cur.execute("ANALYZE events")
        cur.execute("SELECT count(*) FROM events")
        print(f"Loaded {cur.fetchone()[0]:,} rows from {args.input}")


if __name__ == "__main__":
    main()
