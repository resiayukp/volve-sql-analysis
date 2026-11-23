-- 04_window_functions.sql
-- Business question: how does each well behave over time, and how do wells rank?

-- 4.1 Monthly oil per producer with month-over-month change, 3-month moving average and cumulative oil
-- Uses v_monthly_producer_full: months without a record count as zero, so the comparison is always
-- with the calendar month before (has_record = 0 marks a filled month).
SELECT well,
       prod_month,
       ROUND(oil_sm3, 0)                                                        AS oil_sm3,
       has_record,
       ROUND(100.0 * (oil_sm3 - LAG(oil_sm3) OVER (PARTITION BY well ORDER BY prod_month))
             / NULLIF(LAG(oil_sm3) OVER (PARTITION BY well ORDER BY prod_month), 0), 1) AS mom_pct,
       ROUND(AVG(oil_sm3) OVER (PARTITION BY well ORDER BY prod_month
                                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0)   AS moving_avg_3m,
       ROUND(SUM(oil_sm3) OVER (PARTITION BY well ORDER BY prod_month), 0)      AS cumulative_oil_sm3
FROM v_monthly_producer_full
ORDER BY well, prod_month;

-- 4.2 Well ranking inside each year
SELECT prod_year,
       well,
       ROUND(SUM(oil_sm3), 0)                                              AS oil_sm3,
       RANK() OVER (PARTITION BY prod_year ORDER BY SUM(oil_sm3) DESC)     AS rank_in_year
FROM v_monthly_well
WHERE oil_sm3 > 0
GROUP BY prod_year, well
ORDER BY prod_year, rank_in_year;

-- 4.3 Peak month of each well
WITH ranked AS (
    SELECT well, prod_month, oil_sm3,
           ROW_NUMBER() OVER (PARTITION BY well ORDER BY oil_sm3 DESC) AS rn
    FROM v_monthly_well
    WHERE oil_sm3 > 0
)
SELECT well, prod_month AS peak_month, ROUND(oil_sm3, 0) AS peak_oil_sm3
FROM ranked
WHERE rn = 1
ORDER BY peak_oil_sm3 DESC;

-- 4.4 Share of field oil by well each month
SELECT prod_month,
       well,
       ROUND(100.0 * oil_sm3 / NULLIF(SUM(oil_sm3) OVER (PARTITION BY prod_month), 0), 1) AS share_of_month_pct
FROM v_monthly_well
WHERE oil_sm3 > 0
ORDER BY prod_month, share_of_month_pct DESC;
