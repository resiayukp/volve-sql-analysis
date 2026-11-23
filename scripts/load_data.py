"""Load a Volve daily production file (.xlsx or .csv) into a SQLite database.

Usage:
    python scripts/load_data.py path/to/Volve_production_data.xlsx
    python scripts/load_data.py data/demo/daily_production_demo.csv   (synthetic demo data)
"""
import sqlite3
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / 'volve.db'
SHEET = 'Daily Production Data'
ALIASES = {'dateprd': 'date_prd'}


def read_source(path: Path) -> pd.DataFrame:
    if path.suffix.lower() in ('.xlsx', '.xls'):
        sheets = pd.ExcelFile(path).sheet_names
        sheet = SHEET if SHEET in sheets else sheets[0]
        print(f'reading sheet: {sheet}')
        df = pd.read_excel(path, sheet_name=sheet)
    else:
        df = pd.read_csv(path)
    df.columns = [str(c).strip().lower().replace(' ', '_') for c in df.columns]
    # the original Volve sheet writes the date column as DATEPRD (no underscore)
    df = df.rename(columns=ALIASES)
    return df


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    df = read_source(Path(sys.argv[1]))

    schema = (ROOT / 'sql' / '00_schema.sql').read_text()
    con = sqlite3.connect(DB)
    con.executescript(schema)

    table_cols = [r[1] for r in con.execute('PRAGMA table_info(daily_production)')]
    missing = [c for c in ('date_prd', 'npd_well_bore_name') if c not in df.columns]
    if missing:
        sys.exit(f'required columns not found in the file: {missing}.\n'
                 f'columns found: {list(df.columns)}\n'
                 'Add a rename to ALIASES at the top of load_data.py.')

    raw = df['date_prd']
    if pd.api.types.is_numeric_dtype(raw):
        # Excel stores some dates as serial numbers (days since 1899-12-30)
        dates = pd.to_datetime(raw, unit='D', origin='1899-12-30', errors='coerce')
    else:
        dates = pd.to_datetime(raw, errors='coerce')

    # blank rows at the bottom of the sheet or unreadable dates would break the NOT NULL rule
    bad = dates.isna() | df['npd_well_bore_name'].isna()
    if bad.any():
        print(f'dropping {int(bad.sum()):,} of {len(df):,} rows without a valid date or well name')
        print('examples of the raw date values dropped:', raw[bad].head(5).tolist())
        if bad.mean() > 0.05:
            sys.exit('more than 5% of the rows were dropped, so the date format is probably not being read '
                     'correctly. Check the raw values printed above.')
    df = df[~bad].copy()
    df['date_prd'] = dates[~bad].dt.strftime('%Y-%m-%d')
    df = df[[c for c in table_cols if c in df.columns]]
    df.to_sql('daily_production', con, if_exists='append', index=False)

    con.executescript((ROOT / 'sql' / '01_views.sql').read_text())
    n = con.execute('SELECT COUNT(*) FROM daily_production').fetchone()[0]
    print(f'loaded {n:,} rows into {DB.name}')
    con.close()


if __name__ == '__main__':
    main()
