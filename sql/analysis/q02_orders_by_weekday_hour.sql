-- Q2. When do customers shop? Orders by day of week and hour of day.
SELECT
    EXTRACT(ISODOW FROM order_purchase_timestamp)::INT AS weekday,   -- 1 = Monday
    TO_CHAR(order_purchase_timestamp, 'Dy')           AS weekday_name,
    EXTRACT(HOUR FROM order_purchase_timestamp)::INT  AS hour,
    COUNT(*)                                          AS orders
FROM olist.v_delivered
GROUP BY 1, 2, 3
ORDER BY 1, 3;
