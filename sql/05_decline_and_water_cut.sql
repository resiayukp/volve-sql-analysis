-- 05_decline_and_water_cut.sql
-- Business question: which wells are declining, and where is water production growing?

-- 5.1 Field water cut trend
SELECT prod_month,
       ROUND(oil_sm3, 0)         AS oil_sm3,
       ROUND(water_sm3, 0)       AS water_sm3,
       ROUND(100.0 * water_cut, 1) AS water_cut_pct
FROM v_monthly_field
ORDER BY prod_month;

-- 5.2 First month each well reached 50% water cut
SELECT well, MIN(prod_month) AS first_month_over_50pct
FROM v_monthly_well
WHERE oil_sm3 > 0 AND water_cut >= 0.5
GROUP BY well
ORDER BY first_month_over_50pct;

-- 5.3 Decline flag: latest producing month versus the well's peak month
-- Wells with fewer than 12 producing months are not classified (the peak and the latest month
-- can be the same month, which would wrongly look "Stable").
-- Note: check that the last month in the data is a complete month before reading this.
WITH ranked AS (
    SELECT well, prod_month, oil_sm3,
           ROW_NUMBER() OVER (PARTITION BY well ORDER BY oil_sm3 DESC)    AS rn_peak,
           ROW_NUMBER() OVER (PARTITION BY well ORDER BY prod_month DESC) AS rn_last,
           COUNT(*)     OVER (PARTITION BY well)                          AS producing_months
    FROM v_monthly_well
    WHERE oil_sm3 > 0
)
SELECT p.well,
       p.producing_months,
       p.prod_month                                           AS peak_month,
       ROUND(p.oil_sm3, 0)                                    AS peak_oil_sm3,
       l.prod_month                                           AS last_month,
       ROUND(l.oil_sm3, 0)                                    AS last_oil_sm3,
       ROUND(100.0 * (l.oil_sm3 - p.oil_sm3) / p.oil_sm3, 1)  AS change_from_peak_pct,
       CASE WHEN p.producing_months < 12 THEN 'Insufficient history'
            WHEN l.oil_sm3 < 0.5 * p.oil_sm3 THEN 'Declining'
            WHEN l.oil_sm3 < 0.8 * p.oil_sm3 THEN 'Watch'
            ELSE 'Stable' END                                 AS status
FROM ranked AS p
JOIN ranked AS l ON l.well = p.well AND l.rn_last = 1
WHERE p.rn_peak = 1
ORDER BY change_from_peak_pct;

-- 5.4 Wells with the highest water cut in their last 3 producing months
WITH last3 AS (
    SELECT well, prod_month, oil_sm3, water_sm3,
           ROW_NUMBER() OVER (PARTITION BY well ORDER BY prod_month DESC) AS rn
    FROM v_monthly_well
    WHERE oil_sm3 > 0
)
SELECT well,
       ROUND(100.0 * SUM(water_sm3) / NULLIF(SUM(oil_sm3) + SUM(water_sm3), 0), 1) AS water_cut_last_3m_pct
FROM last3
WHERE rn <= 3
GROUP BY well
ORDER BY water_cut_last_3m_pct DESC;
