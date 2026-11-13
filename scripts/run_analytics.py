"""Execute project SQL files and export each result as CSV."""
import argparse, csv, os, re
from pathlib import Path
import psycopg

def statements(path):
    sql=path.read_text(encoding="utf-8")
    sql="\n".join(line for line in sql.splitlines() if not line.lstrip().startswith("--"))
    return [s.strip() for s in sql.split(";") if s.strip()]

def main():
    p=argparse.ArgumentParser(); p.add_argument("--output",type=Path,default=Path("reports/generated/sql")); a=p.parse_args()
    dsn=os.getenv("DATABASE_URL")
    if not dsn: raise SystemExit("Set DATABASE_URL before running analytics.")
    a.output.mkdir(parents=True,exist_ok=True)
    with psycopg.connect(dsn) as conn:
        for file in sorted(Path("sql/queries").glob("*.sql")):
            for idx,query in enumerate(statements(file),1):
                with conn.cursor() as cur:
                    cur.execute(query)
                    if cur.description is None: continue
                    headers=[c.name for c in cur.description]; rows=cur.fetchall()
                out=a.output/f"{file.stem}_{idx:02d}.csv"
                with out.open("w",newline="",encoding="utf-8") as f:
                    writer=csv.writer(f); writer.writerow(headers); writer.writerows(rows)
                print(f"{file.name}: {len(rows)} result rows → {out}")

if __name__=="__main__": main()
