-- Q13. What share of orders never reach the customer?
SELECT
    order_status,
    COUNT(*)                                             AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)   AS pct_orders
FROM olist.orders
GROUP BY order_status
ORDER BY orders DESC;
