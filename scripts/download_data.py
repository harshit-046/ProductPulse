"""Download the official Kaggle archive (requires configured Kaggle credentials)."""
import argparse
import shutil
import subprocess
import zipfile
from pathlib import Path

DATASET = "mkechinov/ecommerce-events-history-in-electronics-store"

def main():
    p=argparse.ArgumentParser(); p.add_argument("--output",type=Path,default=Path("data/raw")); a=p.parse_args()
    a.output.mkdir(parents=True,exist_ok=True)
    archive=a.output/"dataset.zip"
    subprocess.run(["kaggle","datasets","download","-d",DATASET,"-p",str(a.output),"-f","events.csv","-o"],check=True)
    candidates=list(a.output.glob("*.zip"))
    if not candidates: raise SystemExit("Kaggle command completed but no archive was found.")
    with zipfile.ZipFile(candidates[0]) as z:
        names=[n for n in z.namelist() if n.lower().endswith(".csv")]
        if not names: raise SystemExit("Archive has no CSV; inspect it and extract manually.")
        chosen=next((n for n in names if Path(n).name.lower()=="events.csv"),names[0])
        target=a.output/Path(chosen).name
        with z.open(chosen) as src, target.open("wb") as dst: shutil.copyfileobj(src,dst)
    print(f"Extracted {chosen} to {target}")

if __name__=="__main__": main()
