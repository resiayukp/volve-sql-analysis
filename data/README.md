# Data

Download the Volve production data from [Equinor's Volve data page](https://www.equinor.com/energy/volve-data-sharing).
Place the Excel file in `data/raw/` and load it:

```bash
python scripts/load_data.py data/raw/volve_production_data.xlsx
```

The loader reads the sheet `Daily Production Data` (or the first sheet if that name is missing).
`data/raw/` is git-ignored. Commit the raw file only if the licence allows redistribution.

## Expected columns

The table `daily_production` in `sql/00_schema.sql` uses the lower-cased headers of the Volve daily sheet:
`date_prd`, `npd_well_bore_name`, `on_stream_hrs`, `bore_oil_vol`, `bore_gas_vol`, `bore_wat_vol`, `bore_wi_vol`, `flow_kind`, `well_type`, and the pressure, temperature and choke columns.
Volumes are in Sm3. If your headers differ, adjust `sql/00_schema.sql`.

The analysis assumes `well_type = 'OP'` for oil producers and `'WI'` for water injectors. Run query 2.2 in `sql/02_data_quality.sql` first and change the filters if your values differ.

## 

