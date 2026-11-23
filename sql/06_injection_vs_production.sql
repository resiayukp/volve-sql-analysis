-- 06_injection_vs_production.sql
-- Business question: how does water injection relate to production?
-- injection_to_liquid_ratio = water injected / (oil + water produced), in Sm3.
-- It is a simple proxy, not a reservoir-condition voidage ratio.

-- 6.1 Monthly injection versus production
SELECT prod_month,
       ROUND(oil_sm3 + water_sm3, 0)           AS liquid_produced_sm3,
       ROUND(water_inj_sm3, 0)                 AS water_injected_sm3,
       ROUND(injection_to_liquid_ratio, 2)     AS injection_to_liquid_ratio
FROM v_monthly_field
ORDER BY prod_month;

-- 6.2 Injectors ranked by total injection
-- A well counts as an injector only if it recorded injection volume. The well_type label is not used
-- because the same well can carry both labels (for example a well converted from injector to producer).
SELECT npd_well_bore_name AS injector,
       ROUND(SUM(COALESCE(bore_wi_vol, 0)), 0) AS total_injected_sm3,
       SUM(CASE WHEN bore_wi_vol > 0 THEN 1 ELSE 0 END) AS injection_days
FROM daily_production
GROUP BY npd_well_bore_name
HAVING SUM(COALESCE(bore_wi_vol, 0)) > 0
ORDER BY total_injected_sm3 DESC;

-- 6.3 Months where injection fell by more than 30% versus the previous month
WITH m AS (
    SELECT prod_month, water_inj_sm3,
           LAG(water_inj_sm3) OVER (ORDER BY prod_month) AS prev_inj
    FROM v_monthly_field
)
SELECT prod_month,
       ROUND(water_inj_sm3, 0) AS water_injected_sm3,
       ROUND(100.0 * (water_inj_sm3 - prev_inj) / NULLIF(prev_inj, 0), 1) AS change_pct
FROM m
WHERE prev_inj > 0 AND water_inj_sm3 < 0.7 * prev_inj
ORDER BY prod_month;
