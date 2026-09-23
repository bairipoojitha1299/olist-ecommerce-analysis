-- Q10. Credit card: do bigger orders get split into more instalments?
SELECT
    CASE WHEN payment_installments <= 1 THEN '01'
         WHEN payment_installments <= 3 THEN '02-03'
         WHEN payment_installments <= 6 THEN '04-06'
         WHEN payment_installments <= 9 THEN '07-09'
         ELSE '10+' END                      AS installments,
    COUNT(*)                                 AS payments,
    ROUND(AVG(payment_value), 2)             AS avg_payment_value
FROM olist.order_payments
WHERE payment_type = 'credit_card'
GROUP BY 1
ORDER BY 1;
