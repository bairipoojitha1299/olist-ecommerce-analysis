-- Q7. Monthly cohort retention: of customers who first bought in month X,
--     what % bought again N months later?
WITH first_purchase AS (
    SELECT customer_unique_id, MIN(order_month) AS cohort_month
    FROM olist.v_delivered
    GROUP BY customer_unique_id
),
activity AS (
    SELECT DISTINCT
        f.cohort_month,
        d.customer_unique_id,
        (EXTRACT(YEAR FROM AGE(d.order_month, f.cohort_month)) * 12
         + EXTRACT(MONTH FROM AGE(d.order_month, f.cohort_month)))::INT AS month_number
    FROM olist.v_delivered d
    JOIN first_purchase f USING (customer_unique_id)
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS customers
    FROM first_purchase GROUP BY cohort_month
)
SELECT
    a.cohort_month,
    s.customers                                           AS cohort_customers,
    a.month_number,
    COUNT(*)                                              AS active_customers,
    ROUND(100.0 * COUNT(*) / s.customers, 2)              AS retention_pct
FROM activity a
JOIN cohort_size s USING (cohort_month)
WHERE a.month_number <= 6
GROUP BY a.cohort_month, s.customers, a.month_number
ORDER BY a.cohort_month, a.month_number;
