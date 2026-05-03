# 🛒 Customer Retention & Churn Analysis

> **Tools:** MySQL · Excel · SQL Window Functions · Cohort Analysis  
> **Dataset:** 1,100+ e-commerce transactions · 400 customers · 15 months

---

## 📌 Project Overview

This end-to-end data analytics project analyzes **customer purchasing behavior** for an e-commerce store to answer three business-critical questions:

1. **Who is churning** — and when do they leave?
2. **How many customers come back** — month over month?
3. **Which customer cohorts retain best** — and why?

The project follows a real-world analyst workflow:
`Raw CSV → MySQL (Clean + Analyze) → Excel (Dashboard + Charts)`

---

## 📂 Repository Structure

```
customer-retention-churn-analysis/
│
├── data/
│   └── ecommerce_orders.csv          # Raw dataset (1,144 rows)
│
├── sql/
│   ├── 01_schema_setup.sql           # CREATE TABLE + import instructions
│   ├── 02_data_cleaning.sql          # NULL handling, dedup, validation
│   ├── 03_core_analysis.sql          # All analytical queries
│   └── 04_export_for_excel.sql       # Final export queries for dashboard
│
├── excel/
│   └── Customer_Retention_Churn_Dashboard.xlsx   # Full Excel dashboard
│
├── screenshots/
│   ├── dashboard_overview.png        # [Add screenshot here]
│   ├── cohort_heatmap.png            # [Add screenshot here]
│   └── churn_analysis.png            # [Add screenshot here]
│
└── README.md
```

---

## 🗃️ Dataset Structure

| Column | Type | Description |
|---|---|---|
| `customer_id` | VARCHAR | Unique customer identifier |
| `order_id` | VARCHAR | Unique order identifier |
| `order_date` | DATE | Date of purchase |
| `product_id` | VARCHAR | Product SKU |
| `quantity` | INT | Units ordered |
| `price` | DECIMAL | Unit price (₹) |
| `revenue` | DECIMAL | Computed: quantity × price |

**Dataset facts:** 400 customers · 1,100+ rows · Jan 2023 – Mar 2024 · 10 products

---

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| **MySQL 8.0** | Database, data cleaning, all SQL analysis |
| **Microsoft Excel** | Dashboard, charts, cohort heatmap, KPI cards |
| **SQL Window Functions** | ROW_NUMBER, LAG, PARTITION BY |
| **CTEs** | Modular, readable query design |

---

## 📊 Analysis Performed

### 1. Data Cleaning (SQL)
- Removed **duplicate order IDs** using `ROW_NUMBER() OVER (PARTITION BY order_id)`
- Filtered out **negative quantities** and **zero-price** records
- Handled **NULL product_id** and empty customer records
- Cast VARCHAR dates to proper `DATE` type using `STR_TO_DATE()`

### 2. Customer Segmentation
| Segment | Orders | Description |
|---|---|---|
| One-Time | 1 | Never came back |
| Occasional | 2–3 | Returns rarely |
| Loyal | 4–6 | Regular buyer |
| Champion | 7+ | High-frequency buyer |

### 3. Churn Analysis
- **Churn Definition:** No purchase in the last **90 days** from dataset snapshot date
- Identified high-value churned customers for win-back campaigns
- Computed churn rate and active customer %

### 4. Retention Rate
- Monthly: new vs returning customers tracked per month
- Overall: % of customers who made more than one purchase

### 5. Cohort Analysis ⭐
- Customers grouped by **first purchase month** (cohort)
- Tracked what % of each cohort returned in months 1, 2, 3, 4, 5
- Visualized as a **color-coded heatmap** in Excel (green = high retention)

---

## 💡 Key Business Insights

### 🔴 Churn Patterns
- ~**40–45% of customers** are one-time buyers — the biggest churn risk
- Most churn happens within the **first 60 days** after a customer's first purchase
- If a customer doesn't return within 90 days, there is very low probability of recovery

### 🟢 Retention Winners
- **Champion customers** (7+ orders) generate disproportionately high revenue
- Early cohorts (Jan–Mar 2023) showed **better long-term retention** than later ones — possibly due to early promotional pricing or word-of-mouth
- Months 1–2 retention rate is the most predictive of long-term loyalty

### 📦 Product Insights
- **High-ticket items** (Mechanical Keyboard, Webcam, Earbuds) drive majority of revenue
- **Low-ticket repeat products** (Phone Case, USB Cable) drive order frequency

### 📈 Recommendations
1. Launch a **"30-day reactivation email"** for first-time buyers
2. Offer **loyalty discounts** at the 3rd order milestone to convert Occasional → Loyal
3. Prioritize **high-LTV churned customers** for win-back campaigns (identified in SQL query B3)
4. Investigate **why early cohorts retained better** — replicate those conditions

---

## 📋 Excel Dashboard Sheets

| Sheet | Contents |
|---|---|
| **Dashboard** | KPI cards, monthly trend chart, segment bar chart |
| **Raw_Orders** | 500 sample cleaned transaction rows |
| **Segments** | Customer segment breakdown with revenue |
| **Churn_Analysis** | Customer-level churn status + days silent |
| **Monthly_Retention** | Month-by-month new vs returning + line chart |
| **Cohort_Analysis** | Color-coded cohort retention heatmap |
| **Product_Revenue** | Revenue by product + horizontal bar chart |
| **How_To_Use** | Step-by-step guide to connect your SQL data |

---

## 🚀 How to Run This Project

### Step 1 — Set up MySQL
```sql
CREATE DATABASE ecommerce_churn;
USE ecommerce_churn;
-- Run: 01_schema_setup.sql
```

### Step 2 — Import CSV
```sql
LOAD DATA INFILE '/path/to/ecommerce_orders.csv'
INTO TABLE raw_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

### Step 3 — Clean Data
```sql
-- Run: 02_data_cleaning.sql
```

### Step 4 — Run Analysis
```sql
-- Run: 03_core_analysis.sql
-- Run: 04_export_for_excel.sql
```

### Step 5 — Open Excel Dashboard
Open `Customer_Retention_Churn_Dashboard.xlsx` and follow the **How_To_Use** tab.

---

## 📸 Screenshots

> _Add screenshots of your dashboard here after running the project._

| Dashboard | Cohort Heatmap |
|---|---|
| ![](https://github.com/Devaraj-hosur/customer-retention-churn-analysis/blob/8b8745e81029784de9bee4713f2c86531c92a131/1.png) 
| ![](https://github.com/Devaraj-hosur/customer-retention-churn-analysis/blob/13d559be463b8b3807c27a9233406736bf2d30f2/2.png))
| (https://github.com/Devaraj-hosur/customer-retention-churn-analysis/blob/855f93628c1b64dbd086e06c5ec2593e68f309a1/3.png)


---

## 👤 Author

**[Your Name]**  
Aspiring Data Analyst  
📧 [your.email@example.com]  
🔗 [LinkedIn Profile URL]  
💻 [GitHub Profile URL]

---

