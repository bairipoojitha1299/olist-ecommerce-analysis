-- =====================================================================
-- 02_load_data.sql
-- Loads the Kaggle CSVs. Run from the project root:
--   psql -d olist -f sql/02_load_data.sql
-- (Parents are loaded before children so foreign keys are satisfied.)
-- =====================================================================
SET search_path TO olist;

\copy customers            FROM 'data/raw/olist_customers_dataset.csv'          WITH (FORMAT csv, HEADER true)
\copy sellers              FROM 'data/raw/olist_sellers_dataset.csv'            WITH (FORMAT csv, HEADER true)
\copy products             FROM 'data/raw/olist_products_dataset.csv'           WITH (FORMAT csv, HEADER true)
\copy category_translation FROM 'data/raw/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true)
\copy orders               FROM 'data/raw/olist_orders_dataset.csv'             WITH (FORMAT csv, HEADER true)
\copy order_items          FROM 'data/raw/olist_order_items_dataset.csv'        WITH (FORMAT csv, HEADER true)
\copy order_payments       FROM 'data/raw/olist_order_payments_dataset.csv'     WITH (FORMAT csv, HEADER true)
\copy order_reviews        FROM 'data/raw/olist_order_reviews_dataset.csv'      WITH (FORMAT csv, HEADER true)

-- Helpful indexes for the analysis joins
CREATE INDEX ON orders (customer_id);
CREATE INDEX ON orders (order_purchase_timestamp);
CREATE INDEX ON order_items (product_id);
CREATE INDEX ON order_items (seller_id);
CREATE INDEX ON order_payments (order_id);
CREATE INDEX ON order_reviews (order_id);

ANALYZE;

-- Row-count sanity check
SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews;
