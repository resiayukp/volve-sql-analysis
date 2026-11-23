-- 02_data_quality.sql
-- Check the data before analysing it. 

-- 2.1 Size and period
SELECT COUNT(*)                          AS rows_total,
       COUNT(DISTINCT npd_well_bore_name) AS wells,
       MIN(date_prd)                     AS first_date,
       MAX(date_prd)                     AS last_date
FROM daily_production;

-- 2.2 Which well and flow types exist? 
SELECT well_type, flow_kind, COUNT(*) AS rows, COUNT(DISTINCT npd_well_bore_name) AS wells
FROM daily_production
GROUP BY well_type, flow_kind
ORDER BY rows DESC;

-- 2.3 Missing values in the key columns
SELECT
    SUM(CASE WHEN date_prd           IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN bore_oil_vol       IS NULL THEN 1 ELSE 0 END) AS null_oil,
    SUM(CASE WHEN bore_gas_vol       IS NULL THEN 1 ELSE 0 END) AS null_gas,
    SUM(CASE WHEN bore_wat_vol       IS NULL THEN 1 ELSE 0 END) AS null_water,
    SUM(CASE WHEN bore_wi_vol        IS NULL THEN 1 ELSE 0 END) AS null_water_inj,
    SUM(CASE WHEN on_stream_hrs      IS NULL THEN 1 ELSE 0 END) AS null_on_stream
FROM daily_production;

-- 2.4 Negative volumes (should be zero)
SELECT COUNT(*) AS rows_with_negative_volume
FROM daily_production
WHERE bore_oil_vol < 0 OR bore_gas_vol < 0 OR bore_wat_vol < 0 OR bore_wi_vol < 0;

-- 2.5 Duplicate well-day records (should be zero)
SELECT npd_well_bore_name, date_prd, COUNT(*) AS n
FROM daily_production
GROUP BY npd_well_bore_name, date_prd
HAVING COUNT(*) > 1;

-- 2.6 Production recorded while the well was not on stream
SELECT npd_well_bore_name, COUNT(*) AS suspicious_days
FROM daily_production
WHERE COALESCE(on_stream_hrs, 0) = 0 AND COALESCE(bore_oil_vol, 0) > 0
GROUP BY npd_well_bore_name
ORDER BY suspicious_days DESC;

-- 2.7 Gaps: days between the first and last record minus days that exist, per well
SELECT npd_well_bore_name,
       COUNT(*) AS days_recorded,
       CAST(julianday(MAX(date_prd)) - julianday(MIN(date_prd)) AS INTEGER) + 1 AS days_in_period
FROM daily_production
GROUP BY npd_well_bore_name
ORDER BY npd_well_bore_name;

-- 2.8 The rows with negative volumes 
SELECT date_prd, npd_well_bore_name AS well, well_type, flow_kind,
       bore_oil_vol, bore_gas_vol, bore_wat_vol, bore_wi_vol
FROM daily_production
WHERE bore_oil_vol < 0 OR bore_gas_vol < 0 OR bore_wat_vol < 0 OR bore_wi_vol < 0
ORDER BY date_prd;

-- 2.9 Effect of those rows on the field totals (negative values replaced by zero)
SELECT ROUND(SUM(bore_oil_vol), 1)                                        AS oil_all_rows,
       ROUND(SUM(CASE WHEN bore_oil_vol < 0 THEN 0 ELSE bore_oil_vol END), 1) AS oil_without_negatives,
       ROUND(SUM(bore_gas_vol), 1)                                        AS gas_all_rows,
       ROUND(SUM(CASE WHEN bore_gas_vol < 0 THEN 0 ELSE bore_gas_vol END), 1) AS gas_without_negatives,
       ROUND(SUM(bore_wat_vol), 1)                                        AS water_all_rows,
       ROUND(SUM(CASE WHEN bore_wat_vol < 0 THEN 0 ELSE bore_wat_vol END), 1) AS water_without_negatives,
       ROUND(SUM(bore_wi_vol), 1)                                         AS inj_all_rows,
       ROUND(SUM(CASE WHEN bore_wi_vol < 0 THEN 0 ELSE bore_wi_vol END), 1)   AS inj_without_negatives
FROM daily_production;
