-- Q5. Does late delivery hurt customer reviews? (CASE bucketing)
SELECT
    CASE
        WHEN days_late <= -10 THEN '1. 10+ days early'
        WHEN days_late <= -1  THEN '2. 1-9 days early'
        WHEN days_late =  0   THEN '3. On the promised day'
        WHEN days_late <= 3   THEN '4. 1-3 days late'
        WHEN days_late <= 7   THEN '5. 4-7 days late'
        ELSE                       '6. 8+ days late'
    END                                               AS delivery_bucket,
    COUNT(*)                                          AS orders,
    ROUND(AVG(review_score)::NUMERIC, 2)              AS avg_review,
    ROUND(100.0 * AVG((review_score <= 2)::INT), 1)   AS pct_1_2_star
FROM olist.v_delivered
WHERE days_late IS NOT NULL AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;
