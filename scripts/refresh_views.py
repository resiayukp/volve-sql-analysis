"""Re-create the views in an existing volve.db without reloading the data.
Run this after you update sql/01_views.sql.

Usage:
    python scripts/refresh_views.py
"""
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
con = sqlite3.connect(ROOT / 'volve.db')
con.executescript((ROOT / 'sql' / '01_views.sql').read_text())
con.close()
print('views refreshed')
