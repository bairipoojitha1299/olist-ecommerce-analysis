-- Q1. How is revenue trending month over month? (window function: LAG)
SELECT
    order_month,
    COUNT(*)                                   AS orders,
    ROUND(SUM(order_value), 2)                 AS revenue,
    ROUND(AVG(order_value), 2)                 AS avg_order_value,
    ROUND(100.0 * (SUM(order_value) - LAG(SUM(order_value)) OVER (ORDER BY order_month))
          / NULLIF(LAG(SUM(order_value)) OVER (ORDER BY order_month), 0), 1) AS mom_growth_pct
FROM olist.v_delivered
GROUP BY order_month
ORDER BY order_month;
