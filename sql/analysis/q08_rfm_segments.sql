-- Q8. RFM customer segmentation (Recency, Frequency, Monetary) using NTILE.
WITH ref AS (
    SELECT MAX(order_purchase_timestamp)::DATE + 1 AS ref_date FROM olist.v_delivered
),
rfm AS (
    SELECT
        customer_unique_id,
        (SELECT ref_date FROM ref) - MAX(order_purchase_timestamp)::DATE AS recency_days,
        COUNT(*)                                                          AS frequency,
        SUM(order_value)                                                  AS monetary
    FROM olist.v_delivered
    GROUP BY customer_unique_id
),
scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,   -- more recent = higher
        CASE WHEN frequency >= 3 THEN 5
             WHEN frequency = 2  THEN 4
             ELSE 1 END                          AS f_score,   -- most customers buy once, so NTILE on F is meaningless
        NTILE(5) OVER (ORDER BY monetary)        AS m_score
    FROM rfm
),
segmented AS (
    SELECT *,
        CASE
            WHEN f_score >= 4 AND r_score >= 4                THEN 'Loyal - active'
            WHEN f_score >= 4                                 THEN 'Loyal - lapsing'
            WHEN r_score >= 4 AND m_score >= 4                THEN 'New big spenders'
            WHEN r_score >= 4                                 THEN 'New customers'
            WHEN r_score <= 2 AND m_score >= 4                THEN 'Lost big spenders'
            WHEN r_score <= 2                                 THEN 'Lost / hibernating'
            ELSE                                                   'Needs attention'
        END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*)                                            AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct_customers,
    ROUND(AVG(recency_days), 0)                         AS avg_recency_days,
    ROUND(AVG(frequency), 2)                            AS avg_orders,
    ROUND(AVG(monetary), 2)                             AS avg_spend,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue
FROM segmented
GROUP BY segment
ORDER BY pct_revenue DESC;
