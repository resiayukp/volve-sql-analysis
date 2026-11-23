-- 01_views.sql
-- Reusable views. Run once after loading the data.
-- Month and year are taken from the text date (YYYY-MM-DD), which works in SQLite.
-- PostgreSQL: use DATE_TRUNC('month', date_prd) or TO_CHAR(date_prd, 'YYYY-MM').

DROP VIEW IF EXISTS v_daily;
CREATE VIEW v_daily AS
SELECT
    d.*,
    substr(date_prd, 1, 7) AS prod_month,
    substr(date_prd, 1, 4) AS prod_year
FROM daily_production AS d;

DROP VIEW IF EXISTS v_monthly_well;
CREATE VIEW v_monthly_well AS
SELECT
    npd_well_bore_name                                            AS well,
    MAX(well_type)                                                AS well_type,
    prod_month,
    prod_year,
    SUM(COALESCE(bore_oil_vol, 0))                                AS oil_sm3,
    SUM(COALESCE(bore_gas_vol, 0))                                AS gas_sm3,
    SUM(COALESCE(bore_wat_vol, 0))                                AS water_sm3,
    SUM(COALESCE(bore_wi_vol, 0))                                 AS water_inj_sm3,
    SUM(CASE WHEN bore_oil_vol > 0 THEN 1 ELSE 0 END)             AS producing_days,
    SUM(COALESCE(bore_wat_vol, 0)) * 1.0
        / NULLIF(SUM(COALESCE(bore_oil_vol, 0)) + SUM(COALESCE(bore_wat_vol, 0)), 0) AS water_cut
FROM v_daily
GROUP BY npd_well_bore_name, prod_month, prod_year;

DROP VIEW IF EXISTS v_monthly_field;
CREATE VIEW v_monthly_field AS
SELECT
    prod_month,
    SUM(oil_sm3)       AS oil_sm3,
    SUM(gas_sm3)       AS gas_sm3,
    SUM(water_sm3)     AS water_sm3,
    SUM(water_inj_sm3) AS water_inj_sm3,
    SUM(water_sm3) * 1.0 / NULLIF(SUM(oil_sm3) + SUM(water_sm3), 0) AS water_cut,
    SUM(water_inj_sm3) * 1.0 / NULLIF(SUM(oil_sm3) + SUM(water_sm3), 0) AS injection_to_liquid_ratio
FROM v_monthly_well
GROUP BY prod_month;

-- Calendar of months that exist in the data, used to fill months without records.
DROP VIEW IF EXISTS v_month_calendar;
CREATE VIEW v_month_calendar AS
SELECT DISTINCT prod_month FROM v_daily;

-- First and last month in which each producer made oil.
-- Producers are defined by oil volume. The well_type text can change inside a month (a well converted
-- from injector to producer), and MAX(well_type) in v_monthly_well would then hide that whole month.
DROP VIEW IF EXISTS v_producer_span;
CREATE VIEW v_producer_span AS
SELECT well,
       MIN(prod_month) AS first_month,
       MAX(prod_month) AS last_month
FROM v_monthly_well
WHERE oil_sm3 > 0
GROUP BY well;

-- One row per producer and calendar month between its first and last producing month.
-- A month with no record counts as zero oil, so LAG and moving averages never jump over a gap.
DROP VIEW IF EXISTS v_monthly_producer_full;
CREATE VIEW v_monthly_producer_full AS
SELECT s.well,
       c.prod_month,
       substr(c.prod_month, 1, 4)           AS prod_year,
       COALESCE(m.oil_sm3, 0)               AS oil_sm3,
       COALESCE(m.water_sm3, 0)             AS water_sm3,
       CASE WHEN m.well IS NULL THEN 0 ELSE 1 END AS has_record
FROM v_producer_span AS s
JOIN v_month_calendar AS c
     ON c.prod_month BETWEEN s.first_month AND s.last_month
LEFT JOIN v_monthly_well AS m
     ON m.well = s.well AND m.prod_month = c.prod_month;
