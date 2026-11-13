"""Clean the Kaggle event CSV conservatively and write a quality report."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import pandas as pd

REQUIRED = ["event_time", "event_type", "product_id", "category_id", "category_code", "brand", "price", "user_id", "user_session"]
VALID_EVENTS = {"view", "cart", "purchase"}


def clean_file(source: Path, output: Path, report_path: Path) -> dict:
    df = pd.read_csv(source, dtype={"product_id": "string", "category_id": "string", "user_id": "string", "user_session": "string"}, low_memory=False)
    missing_columns = sorted(set(REQUIRED) - set(df.columns))
    if missing_columns:
        raise ValueError(f"Missing required columns: {missing_columns}")
    df = df[REQUIRED].copy()
    original_rows = len(df)
    missing_before = df.isna().sum().astype(int).to_dict()
    duplicates = int(df.duplicated(keep=False).sum())
    # Identical rows are reported but retained: the source has no event ID and
    # repeated events can be legitimate observations.
    parsed_time = pd.to_datetime(df["event_time"], utc=True, errors="coerce")
    invalid_timestamp = int(parsed_time.isna().sum())
    valid_event = df["event_type"].isin(VALID_EVENTS)
    invalid_event_type = int((~valid_event).sum())
    price = pd.to_numeric(df["price"], errors="coerce")
    invalid_price = int((price.isna() | (price < 0)).sum())
    invalid_product = int(df["product_id"].isna().sum() + (df["product_id"].str.strip() == "").fillna(False).sum())
    invalid_user = int(df["user_id"].isna().sum() + (df["user_id"].str.strip() == "").fillna(False).sum())
    keep = parsed_time.notna() & valid_event & price.notna() & (price >= 0) & df["product_id"].notna() & df["user_id"].notna()
    # Preserve blank category and brand as null; preserve missing session so
    # user/event analyses remain possible and session analyses can exclude it.
    cleaned = df.loc[keep].copy()
    cleaned["event_time"] = parsed_time.loc[keep].dt.strftime("%Y-%m-%d %H:%M:%S+00")
    cleaned["event_type"] = cleaned["event_type"].str.lower().str.strip()
    for col in ("category_code", "brand", "user_session"):
        cleaned[col] = cleaned[col].replace(r"^\s*$", pd.NA, regex=True)
    cleaned["price"] = price.loc[keep].astype("float64")
    output.parent.mkdir(parents=True, exist_ok=True)
    cleaned.to_csv(output, index=False)
    excluded = original_rows - len(cleaned)
    report = {
        "source": str(source), "output": str(output), "original_rows": original_rows,
        "cleaned_rows": len(cleaned), "excluded_rows": excluded,
        "excluded_reasons": {"invalid_timestamp": invalid_timestamp, "invalid_event_type": invalid_event_type, "invalid_price": invalid_price, "missing_product_id": invalid_product, "missing_user_id": invalid_user},
        "missing_values_before_cleaning": missing_before, "missing_values_after_cleaning": cleaned.isna().sum().astype(int).to_dict(),
        "duplicate_rows_investigated_and_retained": duplicates,
        "event_types": cleaned["event_type"].value_counts().to_dict(),
        "date_min_utc": cleaned["event_time"].min() if len(cleaned) else None,
        "date_max_utc": cleaned["event_time"].max() if len(cleaned) else None,
        "policy": "Rows are excluded only for unusable timestamp, unsupported event type, invalid/negative price, or missing product/user identifiers. Missing session/category/brand values are retained as unknown; exact duplicate rows are reported and retained."
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, default=str) + "\n", encoding="utf-8")
    return report


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", type=Path, default=Path("data/raw/events.csv"))
    p.add_argument("--output", type=Path, default=Path("data/processed/events_clean.csv"))
    p.add_argument("--report", type=Path, default=Path("reports/generated/data_quality.json"))
    args = p.parse_args()
    print(json.dumps(clean_file(args.input, args.output, args.report), indent=2))


if __name__ == "__main__":
    main()
