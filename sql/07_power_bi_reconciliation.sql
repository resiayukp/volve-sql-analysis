-- 07_power_bi_reconciliation.sql
-- Compare these numbers with the KPI cards on Power BI Executive Summary page.

SELECT ROUND(SUM(bore_oil_vol), 0)  AS total_oil_sm3,
       ROUND(SUM(bore_gas_vol), 0)  AS total_gas_sm3,
       ROUND(SUM(bore_wat_vol), 0)  AS total_water_sm3,
       ROUND(SUM(bore_wi_vol), 0)   AS total_water_injection_sm3
FROM daily_production;

-- Well counts two ways. The label columns follow the well_type text on each row, so a well that
-- changed role is counted twice. The volume columns count wells that actually recorded oil or injection.
SELECT COUNT(*)                                     AS distinct_wells,
       SUM(CASE WHEN has_op_label = 1 THEN 1 ELSE 0 END) AS producers_by_label,
       SUM(CASE WHEN has_wi_label = 1 THEN 1 ELSE 0 END) AS injectors_by_label,
       SUM(CASE WHEN oil > 0 THEN 1 ELSE 0 END)     AS wells_with_oil,
       SUM(CASE WHEN inj > 0 THEN 1 ELSE 0 END)     AS wells_with_injection
FROM (
    SELECT npd_well_bore_name,
           MAX(CASE WHEN well_type = 'OP' THEN 1 ELSE 0 END) AS has_op_label,
           MAX(CASE WHEN well_type = 'WI' THEN 1 ELSE 0 END) AS has_wi_label,
           SUM(COALESCE(bore_oil_vol, 0))                    AS oil,
           SUM(COALESCE(bore_wi_vol, 0))                     AS inj
    FROM daily_production
    GROUP BY npd_well_bore_name
);

SELECT ROUND(AVG(bore_oil_vol), 1) AS avg_daily_oil_all_rows,
       ROUND(AVG(CASE WHEN bore_oil_vol > 0 THEN bore_oil_vol END), 1) AS avg_daily_oil_producing_days
FROM daily_production
WHERE well_type = 'OP';

SELECT npd_well_bore_name AS top_performer_well, ROUND(SUM(bore_oil_vol), 0) AS oil_sm3
FROM daily_production
GROUP BY npd_well_bore_name
ORDER BY oil_sm3 DESC
LIMIT 1;
