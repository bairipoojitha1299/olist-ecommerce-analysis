-- =====================================================================
-- 03_create_views.sql
-- Analysis-ready views that the business-question queries build on.
-- =====================================================================
SET search_path TO olist;

-- One row per order with revenue, delivery and review metrics
CREATE OR REPLACE VIEW v_order_facts AS
WITH items AS (
    SELECT order_id,
           COUNT(*)            AS n_items,
           SUM(price)          AS items_value,
           SUM(freight_value)  AS freight_value
    FROM order_items
    GROUP BY order_id
),
reviews AS (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE              AS order_month,
    i.n_items,
    i.items_value,
    i.freight_value,
    i.items_value + i.freight_value                                    AS order_value,
    -- delivery metrics (NULL when not delivered)
    EXTRACT(EPOCH FROM o.order_delivered_customer_date - o.order_purchase_timestamp) / 86400.0
                                                                       AS delivery_days,
    EXTRACT(EPOCH FROM o.order_estimated_delivery_date - o.order_purchase_timestamp) / 86400.0
                                                                       AS promised_days,
    o.order_delivered_customer_date::DATE - o.order_estimated_delivery_date::DATE
                                                                       AS days_late,   -- negative = early
    r.review_score
FROM orders o
JOIN customers c  ON c.customer_id = o.customer_id
LEFT JOIN items i ON i.order_id = o.order_id
LEFT JOIN reviews r ON r.order_id = o.order_id;

-- Delivered orders only: the basis for revenue analysis.
-- Months with very few orders at the edges of the dataset are excluded
-- (Olist data is only complete from 2017-01 to 2018-08).
CREATE OR REPLACE VIEW v_delivered AS
SELECT *
FROM v_order_facts
WHERE order_status = 'delivered'
  AND order_month BETWEEN DATE '2017-01-01' AND DATE '2018-08-01';

-- Item-level view with English category names
CREATE OR REPLACE VIEW v_items AS
SELECT
    oi.order_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name;
