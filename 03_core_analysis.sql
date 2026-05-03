-- =============================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 03_core_analysis.sql
-- PURPOSE : All analytical SQL queries
--           A. Repeat vs One-Time Customers
--           B. Churn Analysis
--           C. Retention Rate
--           D. Cohort Analysis
-- =============================================================

USE ecommerce_churn;

-- ================================================================
-- A. REPEAT vs ONE-TIME CUSTOMERS
-- ================================================================

-- A1. Order frequency per customer with classification
-- Technique: CTE + CASE WHEN
WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)          AS total_orders,
        MIN(order_date)                   AS first_order_date,
        MAX(order_date)                   AS last_order_date,
        ROUND(SUM(revenue), 2)            AS total_revenue
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_orders,
    first_order_date,
    last_order_date,
    total_revenue,
    -- Classify customer type
    CASE
        WHEN total_orders = 1 THEN 'One-Time'
        WHEN total_orders BETWEEN 2 AND 3 THEN 'Occasional'
        WHEN total_orders BETWEEN 4 AND 6 THEN 'Loyal'
        ELSE 'Champion'
    END AS customer_segment
FROM customer_order_counts
ORDER BY total_revenue DESC;


-- A2. Summary: count and revenue split by segment
WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)  AS total_orders,
        ROUND(SUM(revenue), 2)    AS total_revenue
    FROM orders
    GROUP BY customer_id
),
segmented AS (
    SELECT
        CASE
            WHEN total_orders = 1               THEN 'One-Time'
            WHEN total_orders BETWEEN 2 AND 3   THEN 'Occasional'
            WHEN total_orders BETWEEN 4 AND 6   THEN 'Loyal'
            ELSE 'Champion'
        END AS customer_segment,
        COUNT(*)                  AS customer_count,
        ROUND(SUM(total_revenue),2) AS segment_revenue
    FROM customer_order_counts
    GROUP BY customer_segment
)
SELECT
    customer_segment,
    customer_count,
    segment_revenue,
    -- % of total customers
    ROUND(100.0 * customer_count / SUM(customer_count) OVER(), 1) AS pct_customers,
    -- % of total revenue
    ROUND(100.0 * segment_revenue / SUM(segment_revenue) OVER(), 1) AS pct_revenue
FROM segmented
ORDER BY
    FIELD(customer_segment,'One-Time','Occasional','Loyal','Champion');


-- ================================================================
-- B. CUSTOMER CHURN ANALYSIS
-- ================================================================
-- CHURN DEFINITION: A customer who has NOT placed any order
-- in the last 90 days relative to the dataset's max date.

-- B1. Identify churned vs active customers
WITH last_purchase AS (
    SELECT
        customer_id,
        MAX(order_date)          AS last_order_date,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(revenue),2)    AS lifetime_value
    FROM orders
    GROUP BY customer_id
),
dataset_snapshot AS (
    -- Use the latest date in data as "today"
    SELECT MAX(order_date) AS snapshot_date FROM orders
)
SELECT
    lp.customer_id,
    lp.last_order_date,
    lp.total_orders,
    lp.lifetime_value,
    ds.snapshot_date,
    DATEDIFF(ds.snapshot_date, lp.last_order_date) AS days_since_last_order,
    CASE
        WHEN DATEDIFF(ds.snapshot_date, lp.last_order_date) > 90
             THEN 'Churned'
        ELSE 'Active'
    END AS churn_status
FROM last_purchase lp
CROSS JOIN dataset_snapshot ds
ORDER BY days_since_last_order DESC;


-- B2. Churn summary (rates)
WITH last_purchase AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY customer_id
),
snapshot AS (
    SELECT MAX(order_date) AS snap FROM orders
),
churn_flag AS (
    SELECT
        lp.customer_id,
        CASE WHEN DATEDIFF(s.snap, lp.last_order_date) > 90
             THEN 'Churned' ELSE 'Active' END AS churn_status
    FROM last_purchase lp CROSS JOIN snapshot s
)
SELECT
    churn_status,
    COUNT(*)  AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM churn_flag
GROUP BY churn_status;


-- B3. High-value churned customers (priority win-back list)
WITH last_purchase AS (
    SELECT
        customer_id,
        MAX(order_date)          AS last_order_date,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(revenue),2)    AS lifetime_value
    FROM orders
    GROUP BY customer_id
),
snapshot AS (SELECT MAX(order_date) AS snap FROM orders)
SELECT
    lp.customer_id,
    lp.last_order_date,
    lp.total_orders,
    lp.lifetime_value,
    DATEDIFF(s.snap, lp.last_order_date) AS days_silent
FROM last_purchase lp
CROSS JOIN snapshot s
WHERE DATEDIFF(s.snap, lp.last_order_date) > 90   -- churned
  AND lp.lifetime_value > (                         -- above average LTV
          SELECT AVG(lifetime_value)
          FROM (SELECT customer_id, SUM(revenue) AS lifetime_value
                FROM orders GROUP BY customer_id) t
      )
ORDER BY lp.lifetime_value DESC
LIMIT 50;


-- ================================================================
-- C. RETENTION RATE CALCULATION
-- ================================================================

-- C1. Monthly new vs returning customer counts
WITH monthly_customers AS (
    SELECT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS order_month
    FROM orders
    GROUP BY customer_id, order_month
),
first_purchase AS (
    SELECT customer_id,
           MIN(order_month) AS first_month
    FROM monthly_customers
    GROUP BY customer_id
)
SELECT
    mc.order_month,
    COUNT(DISTINCT mc.customer_id)                                   AS total_active_customers,
    COUNT(DISTINCT CASE WHEN mc.order_month = fp.first_month
                        THEN mc.customer_id END)                     AS new_customers,
    COUNT(DISTINCT CASE WHEN mc.order_month > fp.first_month
                        THEN mc.customer_id END)                     AS returning_customers,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN mc.order_month > fp.first_month
                                    THEN mc.customer_id END)
              / NULLIF(COUNT(DISTINCT mc.customer_id),0)
    , 1)                                                             AS retention_pct
FROM monthly_customers mc
JOIN first_purchase fp ON mc.customer_id = fp.customer_id
GROUP BY mc.order_month
ORDER BY mc.order_month;


-- C2. Overall retention rate (simple)
SELECT
    COUNT(DISTINCT customer_id)                          AS total_customers,
    COUNT(DISTINCT CASE WHEN total_orders > 1
                        THEN customer_id END)            AS retained_customers,
    ROUND(100.0 *
        COUNT(DISTINCT CASE WHEN total_orders > 1
                            THEN customer_id END)
        / COUNT(DISTINCT customer_id), 2)               AS overall_retention_pct
FROM (
    SELECT customer_id, COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
) t;


-- ================================================================
-- D. COHORT ANALYSIS  ← MOST IMPORTANT
-- ================================================================
-- A cohort = all customers who made their FIRST purchase in the same month.
-- We track what % of that cohort came back in month 1, 2, 3 … after joining.

-- D1. Build cohort base
WITH first_purchase AS (
    -- Each customer's cohort = their first purchase month
    SELECT
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM orders
    GROUP BY customer_id
),
customer_activity AS (
    -- All months each customer was active
    SELECT
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS activity_month
    FROM orders o
    GROUP BY o.customer_id, activity_month
),
cohort_data AS (
    -- Join to compute how many months after cohort each activity is
    SELECT
        fp.cohort_month,
        ca.activity_month,
        fp.customer_id,
        -- Months since first purchase (period index)
        PERIOD_DIFF(
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(ca.activity_month,'-01'),'%Y-%m-%d')),
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(fp.cohort_month,'-01'),'%Y-%m-%d'))
        ) AS period_number
    FROM first_purchase fp
    JOIN customer_activity ca ON fp.customer_id = ca.customer_id
),
cohort_size AS (
    -- Total customers acquired each cohort month
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_total
    FROM first_purchase
    GROUP BY cohort_month
)
SELECT
    cd.cohort_month,
    cs.cohort_total,
    cd.period_number,
    COUNT(DISTINCT cd.customer_id)                             AS retained_customers,
    ROUND(
        100.0 * COUNT(DISTINCT cd.customer_id) / cs.cohort_total
    , 1)                                                       AS retention_rate_pct
FROM cohort_data cd
JOIN cohort_size cs ON cd.cohort_month = cs.cohort_month
WHERE cd.period_number BETWEEN 0 AND 11     -- track up to 12 months (period 0–11)
GROUP BY cd.cohort_month, cs.cohort_total, cd.period_number
ORDER BY cd.cohort_month, cd.period_number;


-- D2. Pivot-style cohort for easy Excel paste
-- (Months 0-5 as columns for dashboard)
WITH first_purchase AS (
    SELECT customer_id,
           DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM orders
    GROUP BY customer_id
),
activity AS (
    SELECT customer_id,
           DATE_FORMAT(order_date, '%Y-%m') AS activity_month
    FROM orders
    GROUP BY customer_id, activity_month
),
base AS (
    SELECT
        fp.cohort_month,
        fp.customer_id,
        PERIOD_DIFF(
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(a.activity_month,'-01'),'%Y-%m-%d')),
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(fp.cohort_month,'-01'),'%Y-%m-%d'))
        ) AS period_num
    FROM first_purchase fp
    JOIN activity a ON fp.customer_id = a.customer_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS total
    FROM first_purchase GROUP BY cohort_month
)
SELECT
    b.cohort_month,
    cs.total                                  AS cohort_size,
    -- Period 0 = month they first purchased (should be 100%)
    ROUND(100*COUNT(DISTINCT CASE WHEN period_num=0 THEN b.customer_id END)/cs.total,1) AS `M0_%`,
    ROUND(100*COUNT(DISTINCT CASE WHEN period_num=1 THEN b.customer_id END)/cs.total,1) AS `M1_%`,
    ROUND(100*COUNT(DISTINCT CASE WHEN period_num=2 THEN b.customer_id END)/cs.total,1) AS `M2_%`,
    ROUND(100*COUNT(DISTINCT CASE WHEN period_num=3 THEN b.customer_id END)/cs.total,1) AS `M3_%`,
    ROUND(100*COUNT(DISTINCT CASE WHEN period_num=4 THEN b.customer_id END)/cs.total,1) AS `M4_%`,
    ROUND(100*COUNT(DISTINCT CASE WHEN period_num=5 THEN b.customer_id END)/cs.total,1) AS `M5_%`
FROM base b
JOIN cohort_size cs ON b.cohort_month = cs.cohort_month
GROUP BY b.cohort_month, cs.total
ORDER BY b.cohort_month;
