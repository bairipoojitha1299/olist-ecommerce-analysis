-- Q6. How many customers come back for a second order?
WITH per_customer AS (
    SELECT customer_unique_id, COUNT(*) AS n_orders, SUM(order_value) AS spend
    FROM olist.v_delivered
    GROUP BY customer_unique_id
)
SELECT
    CASE WHEN n_orders = 1 THEN '1 order'
         WHEN n_orders = 2 THEN '2 orders'
         ELSE '3+ orders' END                          AS customer_type,
    COUNT(*)                                           AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_customers,
    ROUND(SUM(spend), 2)                               AS revenue,
    ROUND(100.0 * SUM(spend) / SUM(SUM(spend)) OVER (), 2) AS pct_revenue
FROM per_customer
GROUP BY 1
ORDER BY 1;
