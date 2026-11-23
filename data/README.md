# Data

Download the Volve production data from [Equinor's Volve data page](https://www.equinor.com/energy/volve-data-sharing).
Place the Excel file in `data/raw/` and load it:

```bash
python scripts/load\_data.py data/raw/volve\_production\_data.xlsx
```

The loader reads the sheet `Daily Production Data` (or the first sheet if that name is missing).
`data/raw/` is git-ignored. Commit the raw file only if the licence allows redistribution.

## Expected columns

The table `daily\_production` in `sql/00\_schema.sql` uses the lower-cased headers of the Volve daily sheet:
`date\_prd`, `npd\_well\_bore\_name`, `on\_stream\_hrs`, `bore\_oil\_vol`, `bore\_gas\_vol`, `bore\_wat\_vol`, `bore\_wi\_vol`, `flow\_kind`, `well\_type`, and the pressure, temperature and choke columns.
Volumes are in Sm3. If your headers differ, adjust `sql/00\_schema.sql`.

The analysis assumes `well\_type = 'OP'` for oil producers and `'WI'` for water injectors. Run query 2.2 in `sql/02\_data\_quality.sql` first and change the filters if your values differ.

## 

