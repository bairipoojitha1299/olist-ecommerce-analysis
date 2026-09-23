-- Q12. Where is shipping most expensive relative to the product price?
SELECT
    customer_state,
    COUNT(*)                                               AS orders,
    ROUND(AVG(freight_value), 2)                           AS avg_freight,
    ROUND(100.0 * SUM(freight_value) / SUM(items_value), 1) AS freight_pct_of_price
FROM olist.v_delivered
GROUP BY customer_state
ORDER BY freight_pct_of_price DESC;
