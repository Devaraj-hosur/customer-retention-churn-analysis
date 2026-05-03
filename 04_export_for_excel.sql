-- =============================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 04_export_for_excel.sql
-- PURPOSE : Final clean queries — copy output into Excel tabs
-- =============================================================

USE ecommerce_churn;

-- ================================================================
-- EXPORT 1 : KPI Summary  →  Paste into Excel sheet "KPIs"
-- ================================================================
SELECT
    COUNT(DISTINCT customer_id)                              AS total_customers,
    COUNT(DISTINCT order_id)                                 AS total_orders,
    ROUND(SUM(revenue),2)                                    AS total_revenue,
    ROUND(AVG(revenue),2)                                    AS avg_order_value,
    -- Retention %
    ROUND(100.0 *
        COUNT(DISTINCT CASE WHEN ord_count > 1 THEN customer_id END)
        / COUNT(DISTINCT customer_id), 1)                    AS retention_pct,
    -- Churn % (no purchase in last 90 days)
    ROUND(100.0 *
        SUM(CASE WHEN days_silent > 90 THEN 1 ELSE 0 END)
        / COUNT(*), 1)                                       AS churn_pct
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)                             AS ord_count,
        ROUND(SUM(revenue),2)                               AS ltv,
        DATEDIFF(
            (SELECT MAX(order_date) FROM orders),
            MAX(order_date)
        )                                                    AS days_silent
    FROM orders
    GROUP BY customer_id
) base;


-- ================================================================
-- EXPORT 2 : Customer Segments  →  Sheet "Segments"
-- ================================================================
SELECT
    CASE
        WHEN total_orders = 1             THEN 'One-Time'
        WHEN total_orders BETWEEN 2 AND 3 THEN 'Occasional'
        WHEN total_orders BETWEEN 4 AND 6 THEN 'Loyal'
        ELSE 'Champion'
    END                                             AS segment,
    COUNT(*)                                        AS customers,
    ROUND(SUM(total_revenue),2)                     AS revenue,
    ROUND(AVG(total_revenue),2)                     AS avg_ltv,
    ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(),1)    AS pct_customers
FROM (
    SELECT customer_id,
           COUNT(DISTINCT order_id) AS total_orders,
           SUM(revenue)             AS total_revenue
    FROM orders
    GROUP BY customer_id
) t
GROUP BY segment
ORDER BY FIELD(segment,'One-Time','Occasional','Loyal','Champion');


-- ================================================================
-- EXPORT 3 : Monthly Retention Trend  →  Sheet "Monthly_Retention"
-- ================================================================
WITH monthly_customers AS (
    SELECT customer_id,
           DATE_FORMAT(order_date,'%Y-%m') AS order_month
    FROM orders
    GROUP BY customer_id, order_month
),
first_purchase AS (
    SELECT customer_id, MIN(order_month) AS first_month
    FROM monthly_customers GROUP BY customer_id
)
SELECT
    mc.order_month,
    COUNT(DISTINCT mc.customer_id)                              AS active_customers,
    COUNT(DISTINCT CASE WHEN mc.order_month = fp.first_month
                        THEN mc.customer_id END)               AS new_customers,
    COUNT(DISTINCT CASE WHEN mc.order_month > fp.first_month
                        THEN mc.customer_id END)               AS returning_customers,
    ROUND(100.0*
        COUNT(DISTINCT CASE WHEN mc.order_month > fp.first_month
                            THEN mc.customer_id END)
        / NULLIF(COUNT(DISTINCT mc.customer_id),0), 1)         AS retention_pct
FROM monthly_customers mc
JOIN first_purchase fp ON mc.customer_id = fp.customer_id
GROUP BY mc.order_month
ORDER BY mc.order_month;


-- ================================================================
-- EXPORT 4 : Cohort Pivot  →  Sheet "Cohort_Analysis"
-- ================================================================
WITH first_purchase AS (
    SELECT customer_id,
           DATE_FORMAT(MIN(order_date),'%Y-%m') AS cohort_month
    FROM orders
    GROUP BY customer_id
),
activity AS (
    SELECT customer_id,
           DATE_FORMAT(order_date,'%Y-%m') AS activity_month
    FROM orders GROUP BY customer_id, activity_month
),
base AS (
    SELECT fp.cohort_month, fp.customer_id,
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
    cs.total                                                             AS cohort_size,
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


-- ================================================================
-- EXPORT 5 : Churn Details  →  Sheet "Churn_Details"
-- ================================================================
WITH last_purchase AS (
    SELECT customer_id,
           MAX(order_date)          AS last_order_date,
           COUNT(DISTINCT order_id) AS total_orders,
           ROUND(SUM(revenue),2)    AS lifetime_value
    FROM orders
    GROUP BY customer_id
),
snap AS (SELECT MAX(order_date) AS snap_date FROM orders)
SELECT
    lp.customer_id,
    lp.last_order_date,
    lp.total_orders,
    lp.lifetime_value,
    DATEDIFF(s.snap_date, lp.last_order_date)   AS days_since_last_order,
    CASE WHEN DATEDIFF(s.snap_date, lp.last_order_date) > 90
         THEN 'Churned' ELSE 'Active'
    END                                          AS churn_status
FROM last_purchase lp
CROSS JOIN snap s
ORDER BY days_since_last_order DESC;


-- ================================================================
-- EXPORT 6 : Product Revenue  →  Sheet "Product_Revenue"
-- ================================================================
SELECT
    o.product_id,
    p.product_name,
    COUNT(DISTINCT o.order_id)   AS total_orders,
    SUM(o.quantity)              AS units_sold,
    ROUND(SUM(o.revenue),2)      AS total_revenue,
    ROUND(AVG(o.revenue),2)      AS avg_order_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY o.product_id, p.product_name
ORDER BY total_revenue DESC;
