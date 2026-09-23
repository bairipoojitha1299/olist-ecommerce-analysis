-- Q4. How do customer states compare on sales, delivery speed and satisfaction?
SELECT
    customer_state,
    COUNT(*)                                                   AS orders,
    ROUND(SUM(order_value), 2)                                 AS revenue,
    ROUND(AVG(order_value), 2)                                 AS avg_order_value,
    ROUND(AVG(delivery_days)::NUMERIC, 1)                      AS avg_delivery_days,
    ROUND(100.0 * AVG((days_late > 0)::INT), 1)                AS late_pct,
    ROUND(AVG(review_score)::NUMERIC, 2)                       AS avg_review
FROM olist.v_delivered
GROUP BY customer_state
ORDER BY revenue DESC;
