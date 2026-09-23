-- Q15. Which large categories have the worst customer satisfaction? (HAVING)
SELECT
    i.category,
    COUNT(DISTINCT d.order_id)                         AS orders,
    ROUND(AVG(d.review_score)::NUMERIC, 2)             AS avg_review,
    ROUND(100.0 * AVG((d.review_score <= 2)::INT), 1)  AS pct_1_2_star,
    ROUND(AVG(d.delivery_days)::NUMERIC, 1)            AS avg_delivery_days
FROM olist.v_items i
JOIN olist.v_delivered d ON d.order_id = i.order_id
WHERE d.review_score IS NOT NULL
GROUP BY i.category
HAVING COUNT(DISTINCT d.order_id) >= 500
ORDER BY avg_review ASC
LIMIT 15;
