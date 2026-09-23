-- Q3. Which product categories drive revenue, and how concentrated is it? (Pareto)
WITH cat AS (
    SELECT i.category,
           COUNT(DISTINCT i.order_id) AS orders,
           SUM(i.price)               AS revenue,
           AVG(i.price)               AS avg_price
    FROM olist.v_items i
    JOIN olist.v_delivered d ON d.order_id = i.order_id
    GROUP BY i.category
)
SELECT
    RANK() OVER (ORDER BY revenue DESC)                              AS rank,
    category,
    orders,
    ROUND(revenue, 2)                                                AS revenue,
    ROUND(avg_price, 2)                                              AS avg_price,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)                 AS revenue_share_pct,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
          / SUM(revenue) OVER (), 2)                                 AS cumulative_share_pct
FROM cat
ORDER BY revenue DESC;
