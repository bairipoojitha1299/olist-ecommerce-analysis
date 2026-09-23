-- Q9. How do customers pay, and how do instalments relate to order value?
SELECT
    p.payment_type,
    COUNT(DISTINCT p.order_id)                                  AS orders,
    ROUND(100.0 * COUNT(DISTINCT p.order_id)
          / SUM(COUNT(DISTINCT p.order_id)) OVER (), 1)          AS pct_orders,
    ROUND(SUM(p.payment_value), 2)                              AS total_paid,
    ROUND(AVG(p.payment_value), 2)                              AS avg_payment,
    ROUND(AVG(p.payment_installments), 2)                       AS avg_installments
FROM olist.order_payments p
JOIN olist.v_delivered d ON d.order_id = p.order_id
WHERE p.payment_type <> 'not_defined'
GROUP BY p.payment_type
ORDER BY orders DESC;
