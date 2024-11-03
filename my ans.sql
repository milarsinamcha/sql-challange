
/* Answer to Request 1 */

SELECT market FROM dim_customer 
WHERE customer = 'Atliq Exclusive' AND region = 'APAC'
GROUP BY market
ORDER BY market ;

/* Answer to Request 2 */
SELECT * FROM `fact_sales_monthly`;
WITH unique_products AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021
    FROM 
        `fact_sales_monthly`
)
SELECT 
    unique_products_2020,
    unique_products_2021,
    ROUND(
        (unique_products_2021 - unique_products_2020) * 100.0 / unique_products_2020, 
        2
    ) AS percentage_chg
FROM 
    unique_products;

/* Answer to Request 3 */
SELECT 
    segment, 
    COUNT(DISTINCT product_code) AS product_count  -- Count of unique products in each segment
FROM 
    `dim_product`
GROUP BY 
    segment
ORDER BY 
    product_count DESC;  -- Sort in descending order of product counts

/* Answer to Request 4 */
WITH unique_counts AS (
    SELECT 
        dp.segment,
        COUNT(DISTINCT CASE WHEN fs.fiscal_year = 2020 THEN fs.product_code END) AS unique_2020,
        COUNT(DISTINCT CASE WHEN fs.fiscal_year = 2021 THEN fs.product_code END) AS unique_2021
    FROM 
        `fact_sales_monthly` fs
    JOIN  
        `dim_product` dp ON fs.product_code = dp.product_code
    GROUP BY 
        dp.segment
)

/* Answer to Request 5 */
SELECT *,
    unique_2020 - unique_2021 AS difference
FROM 
    unique_counts;
    
SELECT f.product_code, d.product, f.manufacturing_cost
FROM `fact_manufacturing_cost` f
JOIN `dim_product` d ON f.product_code = d.product_code
WHERE f.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM `fact_manufacturing_cost`)
   OR f.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM `fact_manufacturing_cost`);
   
/* Answer to Request 7 */
   SELECT 
    MONTH(s.date) AS Month,
    YEAR(s.date) AS Year,
    SUM(g.gross_price * s.sold_quantity) AS Gross_sales_amount
FROM 
    `fact_sales_monthly` s
JOIN 
    `fact_gross_price` g ON s.product_code = g.product_code
JOIN 
    `dim_customer` d ON s.customer_code = d.customer_code
WHERE 
    d.customer = "Atliq Exclusive"
GROUP BY 
    YEAR(s.date), MONTH(s.date)
ORDER BY 
    Year, Month;
    
/* Answer to Request 6 */
 
WITH TBL1 AS
(SELECT customer_code AS A, AVG(pre_invoice_discount_pct) AS B FROM fact_pre_invoice_deductions
WHERE fiscal_year = '2021'
GROUP BY customer_code),
     TBL2 AS
(SELECT customer_code AS C, customer AS D FROM dim_customer
WHERE market = 'India')

SELECT TBL2.C AS customer_code, TBL2.D AS customer, ROUND (TBL1.B, 4) AS average_discount_percentage
FROM TBL1 JOIN TBL2
ON TBL1.A = TBL2.C
ORDER BY average_discount_percentage DESC
LIMIT 5 

/* Answer to Request 8 */
SELECT 
    SUM(sold_quantity) AS _sold_quantity,
    CASE 
        WHEN MONTH(date) BETWEEN 1 AND 3 THEN 1
        WHEN MONTH(date) BETWEEN 4 AND 6 THEN 2
        WHEN MONTH(date) BETWEEN 7 AND 9 THEN "3RD"
        WHEN MONTH(date) BETWEEN 10 AND 12 THEN 4
    END AS Quarter
FROM 
    `fact_sales_monthly`
WHERE 
    YEAR(date) = 2020
GROUP BY 
    Quarter;

/* Answer to Request 9 */
WITH channel_sales AS (
    SELECT 
        dc.channel,
        SUM(f.sold_quantity * g.gross_price) / 1e6 AS gross_sales_mln
    FROM 
        `fact_sales_monthly` f
    JOIN 
        `fact_gross_price` g ON g.product_code = f.product_code 
    JOIN 
        `dim_customer` dc ON dc.customer_code = f.customer_code
    WHERE 
        f.fiscal_year = 2021
    GROUP BY 
        dc.channel
)

SELECT 
    channel,
    gross_sales_mln,
    ROUND((gross_sales_mln / (SELECT SUM(gross_sales_mln) FROM channel_sales)) * 100, 2) AS percentage
FROM 
    channel_sales
ORDER BY 
    gross_sales_mln DESC;

/* Answer to Request 10 */
WITH product_sales AS (
    SELECT 
        dp.division,
        dp.product_code,
        dp.product,
        SUM(fs.sold_quantity) AS total_sold_quantity
    FROM 
        `dim_product` dp
    JOIN 
        `fact_sales_monthly` fs ON dp.product_code = fs.product_code
    WHERE 
        fs.fiscal_year = 2021
    GROUP BY 
        dp.division, dp.product_code, dp.product
),

ranked_sales AS (
    SELECT 
        division,
        product_code,
        product,
        total_sold_quantity,
        ROW_NUMBER() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
    FROM 
        product_sales
)

SELECT 
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM 
    ranked_sales
WHERE 
    rank_order <= 3
ORDER BY 
    division, rank_order;