-- =============================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 01_schema_setup.sql
-- PURPOSE : Create database, tables, and import raw data
-- AUTHOR  : [Your Name]
-- =============================================================

-- Step 1: Create and select the database
CREATE DATABASE IF NOT EXISTS ecommerce_churn;
USE ecommerce_churn;

-- ---------------------------------------------------------------
-- Raw orders table (holds imported CSV data before cleaning)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS raw_orders;
CREATE TABLE raw_orders (
    customer_id  VARCHAR(10),
    order_id     VARCHAR(15),
    order_date   VARCHAR(20),   -- stored as VARCHAR initially for safe import
    product_id   VARCHAR(10),
    quantity     INT,
    price        DECIMAL(10,2)
);

-- ---------------------------------------------------------------
-- HOW TO IMPORT THE CSV (run this in MySQL terminal)
-- ---------------------------------------------------------------
-- LOAD DATA INFILE '/path/to/ecommerce_orders.csv'
-- INTO TABLE raw_orders
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;                  -- skips the header row
--
-- If LOAD DATA is blocked, use MySQL Workbench:
--   Server > Data Import > Import from CSV
-- ---------------------------------------------------------------

-- ---------------------------------------------------------------
-- Clean orders table (used for ALL analysis)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_pk     INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  VARCHAR(10)    NOT NULL,
    order_id     VARCHAR(15)    NOT NULL,
    order_date   DATE           NOT NULL,
    product_id   VARCHAR(10)    NOT NULL,
    quantity     INT            NOT NULL,
    price        DECIMAL(10,2)  NOT NULL,
    revenue      DECIMAL(10,2)  GENERATED ALWAYS AS (quantity * price) STORED
);

-- ---------------------------------------------------------------
-- Products reference table (for joins)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id    VARCHAR(10)  PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    base_price    DECIMAL(10,2) NOT NULL
);

INSERT INTO products VALUES
  ('P001','Wireless Earbuds',1299.00),
  ('P002','Phone Case',299.00),
  ('P003','USB-C Cable',199.00),
  ('P004','Laptop Stand',899.00),
  ('P005','Mechanical Keyboard',2499.00),
  ('P006','Mouse Pad',399.00),
  ('P007','Webcam HD',1599.00),
  ('P008','Desk Lamp',749.00),
  ('P009','Power Bank',999.00),
  ('P010','Screen Cleaner',149.00);
