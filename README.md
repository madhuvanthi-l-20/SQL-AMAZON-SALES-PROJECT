# SQL-AMAZON-SALES-PROJECT
End-to-end T-SQL analysis of Amazon e-commerce data. Features data cleaning, ETL relational modeling via temp tables, CTEs, and advanced window functions.


# Amazon E-Commerce Data Analysis & ETL Pipeline

## Project Overview
This repository contains an end-to-end T-SQL development project focused on exploring, cleaning, and transforming e-commerce data from Amazon. The project transitions a flat data structure into a performance-optimized relational model to extract deep business insights regarding product pricing strategies, category performance, and consumer review patterns.

---

## Technical Skills Showcased
* **Data Cleansing & ETL:** Implemented structural transformations using `TRY_CAST`, string manipulation (`REPLACE`), and defensive handling for missing values (`COALESCE`, `ISNULL`).
* **Relational Database Design:** Transitioned a flat architecture into normalized temporary tables (`#DimProduct`, `#FactReviews`) to execute complex multi-table analysis.
* **Advanced Analytical Window Functions:** Utilized `RANK()`, `ROW_NUMBER()`, `LAG()`, `LEAD()`, and rolling aggregations (`SUM() OVER()`) to track market changes and category baselines.
* **Complex Query Logic:** Applied Common Table Expressions (CTEs), multi-segment `UNION ALL` logic, and multi-level correlated subqueries.
* **Database Objects:** Created reusable database architectural structures using `CREATE OR ALTER VIEW`.

---

## Core Analytics Breakdown

### 1. Data Cleaning & Integrity Check
* Identified and flagged missing records across key dimensions (`rating`, `actual_price`, `discounted_price`).
* Executed data manipulation operations (`DML`) to standardize numeric formatting, eliminate parsing errors, and scrub non-numeric percentage characters.

### 2. Multi-Table ETL Pipeline
To simulate production enterprise environments, the raw dataset was normalized into decoupled structures:
* `#DimProduct`: Holds uniquely mapped product IDs, categorization structures, and pricing matrix bands.
* `#FactReviews`: Tracks granular review engagement data, active rating distributions, and traffic patterns.

### 3. Advanced Window Analysis & Deep Insights
* **Price Tier vs. Consumer Satisfaction:** Segmented inventory into explicit pricing bands (Budget, Mid-Range, Premium, Luxury) to analyze how investment variance correlates with average user sentiment.
* **Competitive Pricing Gaps:** Deployed `LAG()` and `LEAD()` functions inside product sectors to identify immediate price barriers against adjacent rival listings.
* **Category Performance Snapshot:** Captured rolling moving averages and product density ratios to isolate sectors maintaining high engagement metrics despite aggressive price discounting.

---

## How to Run the Project
1. Clone this repository to your local directory.
2. Initialize your local database instance in **SQL Server Management Studio (SSMS)**.
3. Execute the full script to automatically establish the source data, clean anomalies, build temp storage dimensions, and return the analytical outputs.
