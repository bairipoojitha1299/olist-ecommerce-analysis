-- Q14. Is delivery getting faster? Actual vs promised delivery time by month.
SELECT
    order_month,
    ROUND(AVG(delivery_days)::NUMERIC, 1)          AS avg_actual_days,
    ROUND(AVG(promised_days)::NUMERIC, 1)          AS avg_promised_days,
    ROUND(100.0 * AVG((days_late > 0)::INT), 1)    AS late_pct,
    ROUND(AVG(review_score)::NUMERIC, 2)           AS avg_review
FROM olist.v_delivered
WHERE delivery_days IS NOT NULL
GROUP BY order_month
ORDER BY order_month;
