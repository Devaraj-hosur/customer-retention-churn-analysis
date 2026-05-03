-- =============================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 02_data_cleaning.sql
-- PURPOSE : Clean raw data and load into the orders table
-- =============================================================

USE ecommerce_churn;

-- ==============================================================
-- STEP 1 : Inspect raw data before cleaning
-- ==============================================================

-- Check total raw rows
SELECT COUNT(*) AS total_raw_rows FROM raw_orders;

-- Check for NULL or empty values in key columns
SELECT
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END) AS null_customer,
    SUM(CASE WHEN order_id   IS NULL OR order_id   = '' THEN 1 ELSE 0 END) AS null_order,
    SUM(CASE WHEN order_date IS NULL OR order_date = '' THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END) AS null_product,
    SUM(CASE WHEN quantity   IS NULL                    THEN 1 ELSE 0 END) AS null_qty,
    SUM(CASE WHEN price      IS NULL                    THEN 1 ELSE 0 END) AS null_price
FROM raw_orders;

-- Check for invalid quantity values (0 or negative)
SELECT COUNT(*) AS invalid_qty_rows
FROM raw_orders
WHERE quantity <= 0;

-- Check for invalid price values
SELECT COUNT(*) AS invalid_price_rows
FROM raw_orders
WHERE price <= 0;

-- Check for duplicate order_ids
SELECT order_id, COUNT(*) AS cnt
FROM raw_orders
GROUP BY order_id
HAVING cnt > 1
ORDER BY cnt DESC
LIMIT 10;

-- ==============================================================
-- STEP 2 : Populate the clean orders table
-- ==============================================================

-- Clear any previous run
TRUNCATE TABLE orders;

-- Insert cleaned and de-duplicated data
-- Uses ROW_NUMBER() to keep only the first occurrence of each order_id
INSERT INTO orders (customer_id, order_id, order_date, product_id, quantity, price)
WITH ranked_raw AS (
    SELECT
        customer_id,
        order_id,
        -- Cast varchar date to proper DATE type
        STR_TO_DATE(order_date, '%Y-%m-%d')  AS order_date,
        product_id,
        quantity,
        price,
        -- Assign row number per order_id to detect duplicates
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date) AS rn
    FROM raw_orders
    -- Filter: remove records missing critical fields
    WHERE customer_id IS NOT NULL AND customer_id <> ''
      AND order_id    IS NOT NULL AND order_id    <> ''
      AND order_date  IS NOT NULL AND order_date  <> ''
      AND product_id  IS NOT NULL AND product_id  <> ''
      -- Filter: remove invalid quantities
      AND quantity    > 0
      -- Filter: remove zero or negative prices
      AND price       > 0
)
SELECT
    customer_id,
    order_id,
    order_date,
    product_id,
    quantity,
    price
FROM ranked_raw
WHERE rn = 1;        -- keep only first occurrence = remove duplicates

-- ==============================================================
-- STEP 3 : Verify clean data
-- ==============================================================

-- Row count after cleaning
SELECT COUNT(*)              AS clean_rows   FROM orders;
SELECT COUNT(DISTINCT order_id)    AS unique_orders   FROM orders;
SELECT COUNT(DISTINCT customer_id) AS unique_customers FROM orders;

-- Date range check
SELECT MIN(order_date) AS earliest_order,
       MAX(order_date) AS latest_order
FROM orders;

-- Revenue sanity check
SELECT
    MIN(revenue)  AS min_revenue,
    MAX(revenue)  AS max_revenue,
    ROUND(AVG(revenue),2) AS avg_revenue
FROM orders;
