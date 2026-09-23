-- Q11. Who are the top sellers, and how much of revenue do the top 10% control?
WITH s AS (
    SELECT i.seller_id,
           COUNT(DISTINCT i.order_id)                  AS orders,
           SUM(i.price)                                AS revenue,
           AVG(d.review_score)                         AS avg_review,
           AVG((d.days_late > 0)::INT)                 AS late_rate
    FROM olist.v_items i
    JOIN olist.v_delivered d ON d.order_id = i.order_id
    GROUP BY i.seller_id
),
ranked AS (
    SELECT *,
           NTILE(10) OVER (ORDER BY revenue DESC)      AS revenue_decile,
           RANK()    OVER (ORDER BY revenue DESC)      AS revenue_rank
    FROM s
)
SELECT
    revenue_decile,
    COUNT(*)                                           AS sellers,
    ROUND(SUM(revenue), 2)                             AS revenue,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct_revenue,
    ROUND(AVG(avg_review)::NUMERIC, 2)                 AS avg_review,
    ROUND(100.0 * AVG(late_rate)::NUMERIC, 1)          AS avg_late_pct
FROM ranked
GROUP BY revenue_decile
ORDER BY revenue_decile;
