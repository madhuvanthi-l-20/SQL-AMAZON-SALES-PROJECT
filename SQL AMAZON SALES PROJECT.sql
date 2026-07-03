SELECT TOP (1000) [product_id]
      ,[product_name]
      ,[category]
      ,[discounted_price]
      ,[actual_price]
      ,[discount_percentage]
      ,[rating]
      ,[rating_count]
      ,[about_product]
      ,[user_id]
      ,[user_name]
      ,[review_id]
      ,[review_title]
      ,[review_content]
      ,[img_link]
      ,[product_link]
  FROM [JOINS].[dbo].[amazon (1)]
  USE [JOINS];
GO

-- Row count check
SELECT COUNT(*) AS total_rows FROM [dbo].[amazon (1)];

-- Duplicate product_id check
SELECT product_id, COUNT(*) AS row_cnt
FROM [dbo].[amazon (1)]
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Null check
SELECT
    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS missing_ratings,
    SUM(CASE WHEN actual_price IS NULL THEN 1 ELSE 0 END) AS missing_actual_price,
    SUM(CASE WHEN discounted_price IS NULL THEN 1 ELSE 0 END) AS missing_discounted_price
FROM [dbo].[amazon (1)];

-- Top 10 rated products with a solid review base
SELECT TOP 10
    product_name, rating, rating_count
FROM [dbo].[amazon (1)]
WHERE TRY_CAST(rating_count AS INT) > 1000
ORDER BY rating DESC, TRY_CAST(rating_count AS INT) DESC;

-- Steepest discounts
SELECT TOP 10
    product_name, actual_price, discounted_price, discount_percentage
FROM [dbo].[amazon (1)]
ORDER BY TRY_CAST(REPLACE(discount_percentage, '%', '') AS INT) DESC;

-- Category snapshot
SELECT
    category,
    COUNT(*) AS total_products,
    ROUND(AVG(rating), 2) AS avg_rating,
    ROUND(AVG(discounted_price), 0) AS avg_price
FROM [dbo].[amazon (1)]
GROUP BY category
ORDER BY total_products DESC;

-- Price tier vs rating
SELECT
    CASE
        WHEN discounted_price < 500   THEN '1. Budget (<500)'
        WHEN discounted_price < 2000  THEN '2. Mid-range (500-2000)'
        WHEN discounted_price < 10000 THEN '3. Premium (2000-10000)'
        ELSE '4. Luxury (10000+)'
    END AS price_tier,
    COUNT(*) AS product_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM [dbo].[amazon (1)]
WHERE discounted_price IS NOT NULL
GROUP BY
    CASE
        WHEN discounted_price < 500   THEN '1. Budget (<500)'
        WHEN discounted_price < 2000  THEN '2. Mid-range (500-2000)'
        WHEN discounted_price < 10000 THEN '3. Premium (2000-10000)'
        ELSE '4. Luxury (10000+)'
    END
ORDER BY price_tier;

-- Products priced above average
SELECT TOP 10
    product_name, discounted_price
FROM [dbo].[amazon (1)]
WHERE discounted_price > (SELECT AVG(discounted_price) FROM [dbo].[amazon (1)])
ORDER BY discounted_price DESC;

-- Best rated product per category
SELECT a.category, a.product_name, a.rating
FROM [dbo].[amazon (1)] a
WHERE a.rating = (
    SELECT MAX(b.rating)
    FROM [dbo].[amazon (1)] b
    WHERE b.category = a.category
)
ORDER BY a.category;

-- Categories with discounts far above their own average
WITH CategoryAvg AS (
    SELECT category,
           AVG(TRY_CAST(REPLACE(discount_percentage, '%', '') AS INT)) AS avg_discount
    FROM [dbo].[amazon (1)]
    GROUP BY category
)
SELECT TOP 10
    a.product_name, a.category, a.discount_percentage,
    ROUND(c.avg_discount, 1) AS category_avg_discount
FROM [dbo].[amazon (1)] a
JOIN CategoryAvg c ON a.category = c.category
WHERE TRY_CAST(REPLACE(a.discount_percentage, '%', '') AS INT) > c.avg_discount + 20
ORDER BY TRY_CAST(REPLACE(a.discount_percentage, '%', '') AS INT) DESC;

-- Rank products by rating within category
SELECT
    product_name, category, rating,
    RANK() OVER (PARTITION BY category ORDER BY rating DESC) AS rank_in_category
FROM [dbo].[amazon (1)]
WHERE rating IS NOT NULL;

-- Top 3 most-reviewed products per category
WITH RankedByPopularity AS (
    SELECT
        product_name, category, rating_count,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY TRY_CAST(REPLACE(rating_count, ',', '') AS INT) DESC
        ) AS popularity_rank
    FROM [dbo].[amazon (1)]
    WHERE rating_count IS NOT NULL
)
SELECT category, popularity_rank, product_name, rating_count
FROM RankedByPopularity
WHERE popularity_rank <= 3;

-- Rough brand extraction from product title
SELECT
    LEFT(product_name, CHARINDEX(' ', product_name + ' ') - 1) AS likely_brand,
    COUNT(*) AS item_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM [dbo].[amazon (1)]
GROUP BY LEFT(product_name, CHARINDEX(' ', product_name + ' ') - 1)
HAVING COUNT(*) >= 5
ORDER BY item_count DESC;
GO
-- Reusable view for category performance
CREATE VIEW view_category_performance AS
SELECT
    category,
    COUNT(*) AS total_products,
    AVG(rating) AS avg_rating,
    AVG(discounted_price) AS avg_price
FROM [dbo].[amazon (1)]
GROUP BY category;
GO

SELECT * FROM view_category_performance ORDER BY total_products DESC;

-- Categories that stay well-rated despite heavy discounting
SELECT
    category,
    ROUND(AVG(TRY_CAST(REPLACE(discount_percentage, '%', '') AS INT)), 1) AS avg_discount,
    ROUND(AVG(rating), 2) AS avg_rating
FROM [dbo].[amazon (1)]
GROUP BY category
HAVING AVG(rating) >= 4.0
ORDER BY avg_discount DESC;

-- Do higher price bands earn better ratings?
SELECT
    CASE
        WHEN actual_price < 1000  THEN 'Tier 1: Economy (<1000)'
        WHEN actual_price < 5000  THEN 'Tier 2: Mid (1000-5000)'
        WHEN actual_price < 20000 THEN 'Tier 3: Upper (5000-20000)'
        ELSE 'Tier 4: Premium (20000+)'
    END AS price_band,
    COUNT(*) AS product_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM [dbo].[amazon (1)]
WHERE actual_price IS NOT NULL
GROUP BY
    CASE
        WHEN actual_price < 1000  THEN 'Tier 1: Economy (<1000)'
        WHEN actual_price < 5000  THEN 'Tier 2: Mid (1000-5000)'
        WHEN actual_price < 20000 THEN 'Tier 3: Upper (5000-20000)'
        ELSE 'Tier 4: Premium (20000+)'
    END
ORDER BY price_band;
-- ETL & DATA TRANSFORMATION (DML, COALESCE, ISNULL)

-- Handle missing values using COALESCE and ISNULL during transformation checks
SELECT TOP 10
    product_id,
    product_name,
    ISNULL(rating, 0.0) AS fallback_rating,
    COALESCE(rating_count, '0') AS fallback_rating_count
FROM [dbo].[amazon (1)]
WHERE rating IS NULL OR rating_count IS NULL;

-- DML: Clean up trailing characters or spaces safely using an UPDATE statement
UPDATE [dbo].[amazon (1)]
SET discount_percentage = REPLACE(discount_percentage, '%', '')
WHERE discount_percentage LIKE '%$%';

-- DML: Simulating an INSERT into a temporary analytics table for tracking luxury inventory
CREATE TABLE #PremiumProducts (
    product_id VARCHAR(50),
    product_name VARCHAR(MAX),
    discounted_price DECIMAL(10,2)
);

INSERT INTO #PremiumProducts (product_id, product_name, discounted_price)
SELECT 
    product_id, 
    product_name, 
    TRY_CAST(REPLACE(discounted_price, ',', '') AS DECIMAL(10,2))
FROM [dbo].[amazon (1)]
WHERE TRY_CAST(REPLACE(discounted_price, ',', '') AS DECIMAL(10,2)) > 10000;

-- DML: Delete anomaies or records failing business rules from our targeted tracking table
DELETE FROM #PremiumProducts
WHERE discounted_price IS NULL;

-- ADVANCED EXPLORATORY DATA ANALYSIS (EDA)


-- ETL Architecture Setup: Normalizing the flat table into relational structures to execute Multi-table JOINs
SELECT DISTINCT 
    product_id, product_name, category, 
    TRY_CAST(REPLACE(actual_price, ',', '') AS DECIMAL(10,2)) AS actual_price, 
    TRY_CAST(REPLACE(discounted_price, ',', '') AS DECIMAL(10,2)) AS discounted_price 
INTO #DimProduct
FROM [dbo].[amazon (1)];

SELECT 
    review_id, product_id, user_id, user_name, rating, 
    TRY_CAST(REPLACE(rating_count, ',', '') AS INT) AS rating_count, 
    review_title, review_content
INTO #FactReviews
FROM [dbo].[amazon (1)];


-- Multi-table JOINs (INNER, LEFT, RIGHT) executing across normalized dimensions & facts
SELECT TOP 10
    p.product_name,
    p.category,
    r.user_name,
    r.rating,
    pp.discounted_price AS luxury_tier_price
FROM #DimProduct p
INNER JOIN #FactReviews r ON p.product_id = r.product_id
LEFT JOIN #PremiumProducts pp ON p.product_id = pp.product_id
WHERE r.rating >= 4.5
ORDER BY r.rating_count DESC;


-- UNION vs UNION ALL: Merging distinct customer segments for comparison
WITH LowEndUnderperforming AS (
    SELECT TOP 5 'Low-End Underperforming' AS segment, product_name, rating, discounted_price
    FROM #DimProduct p
    JOIN #FactReviews r ON p.product_id = r.product_id
    WHERE p.discounted_price < 500 AND r.rating IS NOT NULL
    ORDER BY r.rating ASC
),
HighEndStar AS (
    SELECT TOP 5 'High-End Star' AS segment, product_name, rating, discounted_price
    FROM #DimProduct p
    JOIN #FactReviews r ON p.product_id = r.product_id
    WHERE p.discounted_price > 10000 AND r.rating IS NOT NULL
    ORDER BY r.rating DESC
)
SELECT * FROM LowEndUnderperforming
UNION ALL
SELECT * FROM HighEndStar;

-- LAG() & LEAD(): Window functions evaluating pricing gaps against adjacent tier rivals
SELECT 
    category,
    product_name,
    discounted_price,
    LAG(discounted_price) OVER (PARTITION BY category ORDER BY discounted_price ASC) AS next_cheapest_sibling,
    LEAD(discounted_price) OVER (PARTITION BY category ORDER BY discounted_price ASC) AS next_expensive_sibling,
    discounted_price - LAG(discounted_price) OVER (PARTITION BY category ORDER BY discounted_price ASC) AS price_gap_jump
FROM #DimProduct
WHERE discounted_price IS NOT NULL;


-- Running totals and moving averages using SUM() OVER() and AVG() OVER()
SELECT 
    category,
    product_name,
    discounted_price,
    SUM(discounted_price) OVER (PARTITION BY category ORDER BY discounted_price ASC ROWS UNBOUNDED PRECEDING) AS cumulative_category_value,
    AVG(discounted_price) OVER (PARTITION BY category ORDER BY discounted_price ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_product_window
FROM #DimProduct;


-- EXISTS / NOT EXISTS: Identifying highly engaging items with massive user validation bases
SELECT TOP 10 
    p.product_name, 
    p.category
FROM #DimProduct p
WHERE EXISTS (
    SELECT 1 
    FROM #FactReviews r
    WHERE r.product_id = p.product_id 
      AND r.rating_count > 100000
);


-- Correlated Subquery Example 2: Flagging items priced above their explicit category baseline
SELECT 
    outr.category, 
    outr.product_name, 
    outr.discounted_price
FROM #DimProduct outr
WHERE outr.discounted_price > (
    SELECT AVG(innr.discounted_price)
    FROM #DimProduct innr
    WHERE innr.category = outr.category
)
ORDER BY outr.category;


-- Correlated Subquery Example 3: Extracting items matching the exact maximum review traffic baseline of their sector
SELECT 
    outr.product_id, 
    outr.rating_count
FROM #FactReviews outr
WHERE outr.rating_count = (
    SELECT MAX(innr.rating_count)
    FROM #FactReviews innr
    WHERE innr.product_id = outr.product_id
)
ORDER BY outr.rating_count DESC;


-- Cleanup temp architectural structures
DROP TABLE #DimProduct;
DROP TABLE #FactReviews;
DROP TABLE #PremiumProducts;
GO