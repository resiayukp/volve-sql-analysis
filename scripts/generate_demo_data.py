"""Create a small SYNTHETIC dataset with the same columns as the Volve daily production sheet.
It is only for trying the SQL files before you load the real data. Do not report its numbers."""
import numpy as np
import pandas as pd
from pathlib import Path

rng = np.random.default_rng(7)
dates = pd.date_range('2020-01-01', '2021-12-31', freq='D')
rows = []

producers = {'DEMO-P1': (1800, 0.0012, 0.05), 'DEMO-P2': (1500, 0.0010, 0.08), 'DEMO-P3': (1100, 0.0016, 0.10),
             'DEMO-P4': (900, 0.0008, 0.15), 'DEMO-P5': (700, 0.0020, 0.20), 'DEMO-P6': (400, 0.0009, 0.30)}
for name, (q0, decline, wc0) in producers.items():
    for i, d in enumerate(dates):
        on = 0.0 if rng.random() < 0.03 else 24.0
        oil = q0 * np.exp(-decline * i) * rng.normal(1, 0.05) * (on / 24)
        wc = min(0.95, wc0 + i * 0.0006)
        water = oil * wc / (1 - wc)
        rows.append(dict(date_prd=d.strftime('%Y-%m-%d'), npd_well_bore_name=name, on_stream_hrs=on,
                         bore_oil_vol=max(oil, 0), bore_gas_vol=max(oil, 0) * 120 * rng.normal(1, 0.03),
                         bore_wat_vol=max(water, 0), bore_wi_vol=0.0, flow_kind='production', well_type='OP'))
for name, rate in {'DEMO-I1': 4500, 'DEMO-I2': 3200}.items():
    for d in dates:
        on = 0.0 if rng.random() < 0.04 else 24.0
        rows.append(dict(date_prd=d.strftime('%Y-%m-%d'), npd_well_bore_name=name, on_stream_hrs=on,
                         bore_oil_vol=0.0, bore_gas_vol=0.0, bore_wat_vol=0.0,
                         bore_wi_vol=rate * rng.normal(1, 0.06) * (on / 24), flow_kind='injection', well_type='WI'))

df = pd.DataFrame(rows)
df['npd_field_name'] = 'DEMO FIELD'
out = Path(__file__).resolve().parents[1] / 'data' / 'demo' / 'daily_production_demo.csv'
out.parent.mkdir(parents=True, exist_ok=True)
df.round(2).to_csv(out, index=False)
print('written', out, len(df), 'rows')
