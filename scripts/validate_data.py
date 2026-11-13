"""Validate cleaned CSV invariants and optionally database row count."""
import argparse
import os
from pathlib import Path
import pandas as pd

EXPECTED = {"event_time", "event_type", "product_id", "category_id", "category_code", "brand", "price", "user_id", "user_session"}


def validate(path: Path) -> dict:
    df = pd.read_csv(path, parse_dates=["event_time"])
    errors = []
    if set(df.columns) != EXPECTED: errors.append("Unexpected columns")
    if df.event_time.isna().any(): errors.append("Null/invalid timestamps")
    if not set(df.event_type.dropna().unique()).issubset({"view", "cart", "purchase"}): errors.append("Unsupported event type")
    if (df.price.isna() | (df.price < 0)).any(): errors.append("Invalid price")
    if df.product_id.isna().any() or df.user_id.isna().any(): errors.append("Missing required identifier")
    result = {"rows": len(df), "distinct_users": int(df.user_id.nunique()), "distinct_sessions": int(df.user_session.nunique()), "event_types": df.event_type.value_counts().to_dict(), "errors": errors}
    if errors: raise ValueError(result)
    return result


def main():
    p=argparse.ArgumentParser(); p.add_argument("--input",type=Path,default=Path("data/processed/events_clean.csv")); p.add_argument("--database",action="store_true"); a=p.parse_args()
    print(validate(a.input))
    if a.database:
        import psycopg
        with psycopg.connect(os.environ["DATABASE_URL"]) as c, c.cursor() as cur:
            cur.execute("SELECT count(*) FROM events"); print({"database_rows":cur.fetchone()[0]})


if __name__ == "__main__": main()
