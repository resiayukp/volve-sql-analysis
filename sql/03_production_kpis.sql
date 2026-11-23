-- 03_production_kpis.sql
-- Business question: how is the field performing and which wells matter most?

-- 3.1 Totals by well type
SELECT well_type,
       COUNT(DISTINCT npd_well_bore_name)   AS wells,
       ROUND(SUM(bore_oil_vol), 0)          AS oil_sm3,
       ROUND(SUM(bore_gas_vol), 0)          AS gas_sm3,
       ROUND(SUM(bore_wat_vol), 0)          AS water_sm3,
       ROUND(SUM(bore_wi_vol), 0)           AS water_inj_sm3
FROM daily_production
GROUP BY well_type;

-- 3.2 Well scorecard (every well that produced oil; totals add up to the field total)
SELECT npd_well_bore_name                                                    AS well,
       ROUND(SUM(bore_oil_vol), 0)                                           AS oil_sm3,
       SUM(CASE WHEN bore_oil_vol > 0 THEN 1 ELSE 0 END)                     AS producing_days,
       ROUND(SUM(bore_oil_vol) * 1.0
             / NULLIF(SUM(CASE WHEN bore_oil_vol > 0 THEN 1 ELSE 0 END), 0), 1) AS avg_daily_oil_sm3,
       ROUND(100.0 * SUM(bore_wat_vol)
             / NULLIF(SUM(bore_oil_vol) + SUM(bore_wat_vol), 0), 1)          AS water_cut_pct,
       ROUND(SUM(bore_gas_vol) * 1.0 / NULLIF(SUM(bore_oil_vol), 0), 1)      AS gas_oil_ratio
FROM daily_production
GROUP BY npd_well_bore_name
HAVING SUM(COALESCE(bore_oil_vol, 0)) > 0
ORDER BY oil_sm3 DESC;

-- 3.3 Pareto: how concentrated is production?
WITH well_oil AS (
    SELECT npd_well_bore_name AS well, SUM(bore_oil_vol) AS oil
    FROM daily_production
    GROUP BY npd_well_bore_name
    HAVING SUM(COALESCE(bore_oil_vol, 0)) > 0
)
SELECT well,
       ROUND(oil, 0)                                                        AS oil_sm3,
       ROUND(100.0 * oil / SUM(oil) OVER (), 1)                             AS share_pct,
       ROUND(100.0 * SUM(oil) OVER (ORDER BY oil DESC) / SUM(oil) OVER (), 1) AS cumulative_share_pct
FROM well_oil
ORDER BY oil DESC;

-- 3.4 Yearly oil production with year-over-year change
WITH yearly AS (
    SELECT prod_year, SUM(oil_sm3) AS oil
    FROM v_monthly_well
    GROUP BY prod_year
)
SELECT prod_year,
       ROUND(oil, 0) AS oil_sm3,
       ROUND(100.0 * (oil - LAG(oil) OVER (ORDER BY prod_year))
             / NULLIF(LAG(oil) OVER (ORDER BY prod_year), 0), 1) AS yoy_pct
FROM yearly
ORDER BY prod_year;
