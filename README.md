# Volve Field SQL Analysis

SQL analysis of daily production and injection data from the Volve oil field. It answers the same questions as my [Power BI dashboard](https://github.com/resiayukp/volve-field-production-analytics-dashboard) and checks the dashboard's numbers against the database.

**Tools:** SQL (SQLite, portable to PostgreSQL), Python for loading data.
**Techniques:** CTEs, window functions (`LAG`, `RANK`, `ROW\_NUMBER`, running and moving aggregates), conditional aggregation, views, data quality checks, reconciliation with a BI report.

## Key Findings

Data: 15,634 daily records from 7 wells, September 2007 to December 2016. Oil production starts in February 2008, and production rows end around September 2016. Volumes are in Sm3.

1. **Field totals:** 10,037,081 oil, 15,318,578 water produced, 30,330,134 water injected.
2. **Two wells carry the field.** 15/9-F-12 and 15/9-F-14 produced 45.6% and 39.3% of oil (84.9% together). Adding 15/9-F-11 brings it to 96.3%.
3. **Peak and decline.** Yearly oil peaked in 2009 (2,684,392), then fell 37.0% in 2010 and 49.8% in 2011. It recovered in 2014 (+33.2%) and 2015 (+16.0%). 2016 (-63.6%) is a partial year.
4. **Leadership changed over time.** F-12 ranked first in 2008-2010, F-14 in 2011-2013, and F-11 in 2014.
5. **Water cut.** F-12 and F-14 first passed 50% monthly water cut in June 2010. Over their last three producing months the water cut was 96.6% (F-14), 86.9% (F-12), and 84.9% (F-11).
6. **Declining wells.** Five of six producers are at less than 16% of their peak month in their latest producing month (-84% to -99%). F-5 is not classified because it has only 5 producing months (129 producing days); its latest month is 10.6% below its peak.
7. **Injection.** Only two wells recorded injection volume: F-4 (16.2 million) and F-5 (14.1 million). Total injection was about 1.20 times the produced liquid (oil + water).
8. **Injection interruptions.** Injection fell by more than 30% versus the previous month in 13 months. The sharpest drop was September 2012 (-88.6%), and injection reached zero in October 2016.
9. **Reconciliation.** The totals, well counts by label, well counts by volume, average daily oil, and top performer in `07\_power\_bi\_reconciliation.sql` match the Power BI KPI cards exactly. 

## Business Questions

|#|Question|File|
|-|-|-|
|1|Is the data reliable?|`02_data_quality.sql`|
|2|How is the field performing and which wells matter most?|`03_production_kpis.sql`|
|3|How does each well behave over time and how do wells rank?|`04_window_functions.sql`|
|4|Which wells are declining and where is water cut rising?|`05_decline_and_water_cut.sql`|
|5|How does water injection relate to production?|`06_injection_vs_production.sql`|
|6|Do the SQL totals match the Power BI dashboard?|`07_power_bi_reconciliation.sql`|

## Results

### Well scorecard (every well that made oil, `03` query 3.2)

|Well|Oil (Sm3)|Producing days|Avg daily oil (Sm3)|Water cut|Gas-oil ratio|
|-|-|-|-|-|-|
|15/9-F-12|4,579,610|2,836|1,614.8|59.9%|145.8|
|15/9-F-14|3,942,233|2,723|1,447.8|64.4%|146.6|
|15/9-F-11|1,147,849|1,123|1,022.1|48.7%|151.9|
|15/9-F-1 C|177,709|430|413.3|53.8%|148.8|
|15/9-F-15 D|148,519|767|193.6|26.1%|151.5|
|15/9-F-5|41,161|129|319.1|24.7%|159.4|

Water cut is lifetime water / (oil + water). Average daily oil is over producing days only. A well counts as a producer if it made oil, whatever the well\_type label says, so the oil column adds up to the field total of 10,037,081 Sm3.

### Yearly oil (`03` query 3.4)

|Year|Oil (Sm3)|YoY|
|-|-|-|
|2008|1,764,375|n/a (no 2007 oil)|
|2009|2,684,392|+52.1%|
|2010|1,689,903|-37.0%|
|2011|847,965|-49.8%|
|2012|574,206|-32.3%|
|2013|558,013|-2.8%|
|2014|743,107|+33.2%|
|2015|861,749|+16.0%|
|2016|313,370|-63.6% (partial year)|

### Decline versus peak month (`05` query 5.3)

|Well|Peak month|Peak oil|Last month|Last oil|Change|Status|
|-|-|-|-|-|-|-|
|15/9-F-12|2008-12|166,440|2016-08|1,442|-99.1%|Declining|
|15/9-F-14|2008-10|142,817|2016-07|1,327|-99.1%|Declining|
|15/9-F-1 C|2014-05|24,902|2016-04|1,672|-93.3%|Declining|
|15/9-F-15 D|2014-02|7,899|2016-07|829|-89.5%|Declining|
|15/9-F-11|2015-05|55,029|2016-09|8,609|-84.4%|Declining|
|15/9-F-5|2016-07|9,985|2016-08|8,929|-10.6%|Insufficient history (5 months)|

Status rule: wells with fewer than 12 producing months are not classified; otherwise below 50% of peak is Declining, below 80% is Watch, and the rest is Stable.

### Injectors by recorded volume (`06` query 6.2)

|Injector|Total injected (Sm3)|Injection days|
|-|-|-|
|15/9-F-4|16,240,727|2,846|
|15/9-F-5|14,089,406|2,558|

A well counts as an injector only if it recorded injection volume. 15/9-F-1 C carries an injector label on some rows but never injected, so it is not listed.

## Data Quality (`02`)

|Check|Result|
|-|-|
|Rows, wells, period|15,634 rows, 7 wells, 2007-09-01 to 2016-12-01|
|Duplicate well-day records|None|
|Rows with negative volumes|4, all in water production (see below)|
|Missing on-stream hours|285 rows|
|Missing oil, gas, water|6,473 rows, equal to the number of injection rows, so expected|
|Production with zero hours on stream|1 day (15/9-F-11)|
|Missing days inside a well's period|F-12: 85, F-14: 85, F-4: 53, F-11: 3, F-15 D: 2, F-5 and F-1 C: 0|

### Negative volumes

All four negative values are in water production. Oil, gas, and injection volumes are never negative.

|Date|Well|Oil (Sm3)|Water (Sm3)|
|-|-|-|-|
|2008-04-23|15/9-F-12|2,735.53|-14.19|
|2009-03-03|15/9-F-14|4,339.13|-0.95|
|2012-08-13|15/9-F-12|632.96|-457.84|
|2012-08-13|15/9-F-14|202.53|-59.19|

Replacing them with zero would add 532.2 Sm3 to produced water (15,318,578 to 15,319,111), a change of 0.0035%, and would not change oil, gas, or injection at all.

**Decision: the rows are kept.** The effect is negligible, the source data is not altered, and the SQL totals still match the Power BI dashboard exactly. Water cut and ratios are calculated from monthly or lifetime sums, never from a single day, so one negative day does not distort them. The two largest values fall on the same day (2012-08-13) for two wells whose oil that day is far below their average (632.96 and 202.53 Sm3 against about 1,600 and 1,450), which may point to a start-up or shut-in day with an allocation or metering correction. That is a guess, not a finding, so the rows are flagged rather than corrected.

Rows by type: 9,143 producer rows, 6,473 injector rows with injection flow, and 18 injector-labelled rows with production flow.

## Reconciliation with Power BI (`07`)

|Metric|SQL result|Power BI|
|-|-|-|
|Total oil|10,037,081 Sm3|Match|
|Total gas|1,475,370,436 Sm3|Match|
|Total water produced|15,318,578 Sm3|Match|
|Total water injected|30,330,134 Sm3|Match|
|Producer wells / injector wells (by row label)|6 / 3|Match|
|Wells that recorded oil / injection (by volume)|6 / 2|Match|
|Average daily oil|1,097.4 (all rows) or 1,254.4 (producing days)|Match|
|Top performer|15/9-F-12 (4,579,610 Sm3)|Match|

The dashboard's injector count (3) follows the well\_type label on each row. By recorded injection volume only 2 wells (F-4 and F-5) injected. `07` query 2 shows both counts: 7 distinct wells, 6 producers and 3 injectors by label, 6 wells with oil and 2 with injection by volume.

The producer scorecard (`03` query 3.2) adds up to the same 10,037,081 Sm3. Query 3.1, which groups by the well\_type label, shows 10,033,831 Sm3 for producer-labelled rows because injector-labelled rows record 3,250 Sm3 of oil.

## Method Notes

* `daily_production` holds the raw rows. Views `v_monthly_well` and `v_monthly_field` aggregate them.
* **Producers and injectors are defined by volume.** A producer is a well that made oil and an injector is a well that recorded injection. The well\_type text is used only in query 3.1 and in the label counts of `07`, because it can change within one month: grouping by month with `MAX(well_type)` hid whole months of a well converted from injector to producer (F-5 showed one producing month in the monthly queries although it has 129 producing days; with volume-based filters it shows 5, and the 3,250 Sm3 of oil on injector-labelled rows is now counted for F-5 and F-1 C).
* **Well type is a label on each row, not on the well.** F-5 and F-1 C appear as both producer and injector, so the 6 producers and 3 injectors counted in `07` are well-type pairs. There are 7 distinct wells, and only F-4 and F-5 recorded injection volume.
* Water cut = water / (oil + water). Injection-to-liquid ratio = water injected / (oil + water produced) in Sm3, a simple proxy and not a reservoir-condition voidage ratio.
* Month-over-month change and moving averages run on a continuous monthly calendar (`v_monthly_producer_full`), from each producer's first to its last producing month. A month with no record counts as zero oil and is marked `has_record = 0`, so a change is never calculated across a gap.

## Quick Start

```bash
git clone https://github.com/resiayukp/volve-sql-analysis.git
cd volve-sql-analysis
pip install -r requirements.txt

python scripts/load_data.py data/raw/volve_production_data.xlsx
python scripts/run_sql.py sql/02_data_quality.sql
```

If you change `sql/01_views.sql`, run `python scripts/refresh_views.py` to rebuild the views without reloading the data.

The loader maps the original `DATEPRD` header to `date_prd`, drops rows without a valid date, and reports how many were dropped. To try the project first, generate synthetic demo data with `python scripts/generate_demo_data.py` and load `data/demo/daily_production_demo.csv`. Demo numbers are not findings.

## Project Structure

```
volve-sql-analysis/
├── README.md
├── requirements.txt
├── sql/
│   ├── 00_schema.sql
│   ├── 01_views.sql
│   ├── 02_data_quality.sql
│   ├── 03_production_kpis.sql
│   ├── 04_window_functions.sql
│   ├── 05_decline_and_water_cut.sql
│   ├── 06_injection_vs_production.sql
│   └── 07_power_bi_reconciliation.sql
├── scripts/
│   ├── load_data.py
│   ├── run_sql.py
│   ├── refresh_views.py
│   └── generate_demo_data.py
└── data/
    ├── README.md
    ├── raw/        (real file, git-ignored)
    └── demo/       (synthetic data only)
```

## Limitations

* Daily data only; no reservoir pressure model or forecasting.
* The decline flag compares the latest producing month with the peak month, and only for wells with at least 12 producing months.
* Production rows end around September 2016, so 2016 is a partial year.
* 4 rows with negative volumes are kept, which is consistent with the dashboard. Their effect on the totals is small but unchecked.

## Moving to PostgreSQL

|SQLite (used here)|PostgreSQL|
|-|-|
|`substr(date_prd, 1, 7)` on a text date|`TO_CHAR(date_prd, 'YYYY-MM')` or `DATE_TRUNC('month', date_prd)`|
|`julianday(b) - julianday(a)`|`b::date - a::date`|
|`TEXT` date column|`DATE` column|

## Contact

**Resiayu Kinasih Pangastuti** — [GitHub](https://github.com/resiayukp) · [LinkedIn](https://linkedin.com/in/resiayu) · [Email](mailto:resiayu.97@gmail.com)

