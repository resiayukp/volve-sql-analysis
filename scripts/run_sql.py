"""Run a .sql file against volve.db and print the result of every SELECT.

Usage:
    python scripts/run_sql.py sql/03_production_kpis.sql
"""
import sqlite3
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
pd.set_option('display.width', 200)
pd.set_option('display.max_columns', 30)


def statements(text):
    # split on ';' at the end of a line; good enough for the files in this project
    return [s.strip() for s in text.split(';\n') if s.strip() and not all(l.startswith('--') or not l.strip() for l in s.splitlines())]


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    con = sqlite3.connect(ROOT / 'volve.db')
    for i, stmt in enumerate(statements(Path(sys.argv[1]).read_text()), 1):
        print(f'\n--- query {i} ---')
        print(pd.read_sql_query(stmt.rstrip(';'), con).head(15).to_string(index=False))
    con.close()


if __name__ == '__main__':
    main()
