-- BQ1: Baseline Profitability Overview
-- Saya menghitung semua metric agregat pada dataset
-- untuk menetapkan baselinenya sebelum drill-down per dimensi
SELECT *
FROM retail_clean_dataset;

SELECT *
FROM BQ1; -- Hasil View EDA Business Question 1

SELECT
    -- METRICS
    COUNT(DISTINCT order_no)                          AS total_transactions,
    SUM(sub_total)                                    AS total_gross_revenue,
    SUM(discount_dollar)                              AS total_discount_given,
    SUM(shipping_cost)                                AS total_shipping_cost,
    SUM(order_total)                                  AS net_revenue_after_discount,
    SUM(total)                                        AS net_revenue_afterr_discount_and_shipping_cost,

    -- NET/GROSS PROFIT METRICS
    SUM(profit_margin * order_quantity)											 AS total_gross_profit_before_discount,
    SUM((profit_margin * order_quantity) - discount_dollar - shipping_cost)		 AS total_net_profit_after_discount_shipping_cost,

    -- MARGIN & LEAKAGE RATES
    ROUND(SUM(profit_margin * order_quantity) / SUM(sub_total) * 100, 2)		 AS gross_profit_margin_percentage,
    ROUND(SUM(discount_dollar) / SUM(sub_total) * 100, 2)						 AS discount_leakage_percentage,
    ROUND(SUM(shipping_cost) / SUM(sub_total) * 100, 2)							 AS shipping_leakage_percentage,
    ROUND((SUM(discount_dollar) + SUM(shipping_cost)) / SUM(sub_total) * 100, 2) AS total_discount_and_shipping_cost_leakage_percentage,

    -- AVERAGE METRICS
    ROUND(SUM(sub_total) / COUNT(DISTINCT order_no), 2)						     AS avg_order_value,
    ROUND(SUM(profit_margin * order_quantity) / COUNT(DISTINCT order_no), 2)	 AS avg_gross_profit_per_transaction

FROM retail_clean_dataset;


-- BQ2: Mencari Category Profitability Dengan Membandingkan Revenue Rank vs Profit Rank Based On Products Categoryy
-- CTE 1 agregasi per kategori dan metriks lainnya
-- CTE 2 tambah fungsi ranking untuk membandingkan penyeabaran revenue n profit
-- Kalau revenue rank ≠ profit rank = problem identified (revenue overperform than profit) atau sebaliknya

SELECT *
FROM BQ2; -- Hasil View EDA Business Question 2

-- Saya Menghitung Keseluruhan Metriks Dulu Sebagai "Supporting Context" Dalam Memahami Poin Utama Dari BQ2
CREATE OR REPLACE VIEW BQ2 AS
WITH category_metrics AS (
    SELECT product_category,
        COUNT(DISTINCT order_no)                      AS total_transactions,
        SUM(order_quantity)                           AS total_items_sold,
        ROUND(SUM(sub_total), 2)                      AS total_gross_revenue,
        ROUND(SUM(discount_dollar), 2)                AS total_discount_given,
        ROUND(SUM(shipping_cost), 2)                  AS total_shipping_cost,
        ROUND(SUM(profit_margin * order_quantity), 2) AS total_gross_profit,
        ROUND(SUM((profit_margin * order_quantity) - discount_dollar - shipping_cost), 2) AS total_net_profit,
        
        -- FIXED LINE: Menghitung true weighted margin % (Total Cuan Kotor / Total Omset)
        ROUND(SUM(profit_margin * order_quantity) / NULLIF(SUM(sub_total), 0) * 100, 2)   AS avg_profit_margin_percentage,
        
        ROUND(SUM(discount_dollar) / SUM(sub_total) * 100, 2)                               AS discount_rate_percentage,
        ROUND(SUM(shipping_cost) / SUM(sub_total) * 100, 2)                               AS shipping_rate_percentage
    FROM retail_clean_dataset
    GROUP BY product_category
),
category_ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY total_gross_revenue DESC)               AS revenue_rank,
        RANK() OVER (ORDER BY total_net_profit DESC)                  AS profit_rank,
        RANK() OVER (ORDER BY avg_profit_margin_percentage DESC)      AS margin_rank,
        RANK() OVER (ORDER BY total_gross_revenue DESC) - 
        RANK() OVER (ORDER BY total_net_profit DESC)                    AS rank_delta
    FROM category_metrics
)
SELECT product_category, total_transactions, total_gross_revenue, total_discount_given,
       total_shipping_cost, total_gross_profit, total_net_profit, avg_profit_margin_percentage, discount_rate_percentage,
       shipping_rate_percentage, revenue_rank, profit_rank, margin_rank,
    CASE
        WHEN rank_delta > 0  THEN 'Revenue > Profit Rank (Overperforming di Revenue)'
        WHEN rank_delta < 0  THEN 'Profit > Revenue Rank (Overperforming di Profit)'
        ELSE                      'Balance Perform'
    END    AS profitability_signal
FROM category_ranked
ORDER BY revenue_rank ASC;


-- BQ3: Profit Leakage Analysis Besaran Dampak Discount/Shipping Cost Pada Total Akhir 
-- Classify tiap transaksi berdasarkan
-- tingkat keparahan kebocoran profit (diskon + shipping vs gross profit)
-- lalu agregasi untuk identify pola diskon yang tidak proporsional dengan profit yang dihasilkan

SELECT *
FROM BQ3_Product_Category; -- Hasil View EDA Business Question 3 "Mencari Product Category"
SELECT *
FROM BQ3_Customer_Segmentation; -- Hasil View EDA Business Question 3 "Mencari Customer Segmentation"

-- Mencari "Product Category" yang pola diskon tidak proporsional dengan profit yang dihasilkan
WITH transaction_leakage_pc AS (
    SELECT order_no, product_category, customer_type, order_priority,
        (profit_margin * order_quantity)	   							   AS gross_profit,
        discount_dollar, shipping_cost,
        (discount_dollar + shipping_cost)								   AS total_leakage,
        (profit_margin * order_quantity) - shipping_cost - discount_dollar AS net_profit,
        ROUND(discount_dollar / NULLIF(sub_total, 0) * 100, 2) 			   AS discount_rate_percentage,
        -- Mengklasifikasi tingkat keparahan kebocoran profit per transaction
        CASE
            WHEN (discount_dollar + shipping_cost) > (profit_margin * order_quantity) THEN 'Leakage Melebihi Profit'
            WHEN discount_dollar / NULLIF(sub_total, 0) > 0.10 THEN 'High Discount >10% Revenue'
            WHEN discount_dollar / NULLIF(sub_total, 0) > 0.05 THEN 'Medium Discount 5-10% Revenue'
            ELSE 'Low Discount <5% Revenue'
        END AS leakage_severity
    FROM retail_clean_dataset
),
leakage_by_category_pc AS (
    SELECT product_category,
        COUNT(order_no) 				AS total_orders,
        ROUND(SUM(gross_profit), 2) 	AS total_gross_profit,
        ROUND(SUM(discount_dollar), 2) 	AS total_discount,
        ROUND(SUM(shipping_cost), 2)    AS total_shipping,
        ROUND(SUM(total_leakage), 2)    AS total_leakage,
        ROUND(SUM(net_profit), 2)       AS total_net_profit,
        ROUND(SUM(total_leakage) / SUM(gross_profit) * 100, 2) 													   AS leakage_as_percentage_profit,
        COUNT(CASE WHEN leakage_severity = 'Leakage Melebihi Profit' THEN 1 END) 								   AS total_critical_orders_per_productANDcustomer,
        ROUND(COUNT(CASE WHEN leakage_severity = 'Leakage Melebihi Profit' THEN 1 END) / COUNT(order_no) * 100, 2) AS critical_order_percentage
    FROM transaction_leakage_pc
    GROUP BY product_category
)

SELECT *
FROM leakage_by_category_pc
ORDER BY leakage_as_percentage_profit DESC;

-- Mencari "Customer Segment" yang pola diskon tidak proporsional dengan profit yang dihasilkan
WITH transaction_leakage_cs AS (
    SELECT order_no, product_category, customer_type, order_priority,
        (profit_margin * order_quantity)	    AS gross_profit,
        discount_dollar, shipping_cost,
        (discount_dollar + shipping_cost)		AS total_leakage,
        (profit_margin * order_quantity) - shipping_cost - discount_dollar AS net_profit,
        ROUND(discount_dollar / NULLIF(sub_total, 0) * 100, 2) 			   AS discount_rate_percentage,
        -- Mengklasifikasi tingkat keparahan kebocoran profit per transaction
        CASE
            WHEN (discount_dollar + shipping_cost) > (profit_margin * order_quantity) THEN 'Leakage Melebihi Profit'
            WHEN discount_dollar / NULLIF(sub_total, 0) > 0.10 THEN 'High Discount >10% Revenue'
            WHEN discount_dollar / NULLIF(sub_total, 0) > 0.05 THEN 'Medium Discount 5-10% Revenue'
            ELSE 'Low Discount <5% Revenue'
        END AS leakage_severity
    FROM retail_clean_dataset
),
leakage_by_category_cs AS (
    SELECT customer_type,
        COUNT(order_no) 				AS total_orders,
        ROUND(SUM(gross_profit), 2) 	AS total_gross_profit,
        ROUND(SUM(discount_dollar), 2) 	AS total_discount,
        ROUND(SUM(shipping_cost), 2)    AS total_shipping,
        ROUND(SUM(total_leakage), 2)    AS total_leakage,
        ROUND(SUM(net_profit), 2)       AS total_net_profit,
        ROUND(SUM(total_leakage) / SUM(gross_profit) * 100, 2) 				    								   AS leakage_as_percentage_profit,
        COUNT(CASE WHEN leakage_severity = 'Leakage Melebihi Profit' THEN 1 END) 								   AS total_critical_orders_per_productANDcustomer,
        ROUND(COUNT(CASE WHEN leakage_severity = 'Leakage Melebihi Profit' THEN 1 END) / COUNT(order_no) * 100, 2) AS critical_order_percentage
    FROM transaction_leakage_cs
    GROUP BY customer_type
)
SELECT *
FROM leakage_by_category_cs
ORDER BY leakage_as_percentage_profit DESC;

-- Memverifikasi apakah corporate memang
-- dominan di kategori Furniture?
SELECT 
    product_category,
    customer_type,
    COUNT(DISTINCT order_no) AS orders,
    ROUND(AVG(discount_dollar/sub_total*100),2) AS avg_discount_pct,
    ROUND(AVG(shipping_cost),2) AS avg_shipping
FROM retail_clean_dataset
WHERE product_category = 'Furniture'
GROUP BY product_category, customer_type
ORDER BY orders DESC;



-- BQ4: Customer Segment Profitability
-- Agregasi per Customer Type untuk identify
-- segment mana yang paling valuable secara profit
-- bukan hanya secara revenue/volume

SELECT *
FROM BQ4; -- Hasil View EDA Business Question 4

WITH customer_segment_metrics AS (
    SELECT customer_type,
        COUNT(DISTINCT order_no)                      AS total_transactions,
        SUM(order_quantity)                           AS total_items_sold,
        ROUND(SUM(sub_total), 2)                      AS total_gross_revenue,
        ROUND(SUM(discount_dollar), 2)                AS total_discount,
        ROUND(SUM(shipping_cost), 2)                  AS total_shipping,
        ROUND(SUM(profit_margin * order_quantity), 2)                               	  AS total_gross_profit,
        ROUND(SUM((profit_margin * order_quantity) - shipping_cost - discount_dollar), 2) AS total_net_profit,
        ROUND(AVG(profit_margin / NULLIF(retail_price,0)) * 100, 2)       				  AS avg_margin_percentage,
        ROUND(SUM((profit_margin * order_quantity) - shipping_cost - discount_dollar)
        / COUNT(DISTINCT order_no), 2)	      											  AS avg_profit_per_order,
        ROUND(SUM(sub_total) / COUNT(DISTINCT order_no), 2)            					  AS avg_order_value,
        ROUND(SUM(discount_dollar) / SUM(sub_total) * 100, 2)                			  AS avg_discount_rate_percentage
    FROM retail_clean_dataset
    GROUP BY customer_type
),
segment_with_contribution AS (
    SELECT *,
        RANK() OVER (ORDER BY total_net_profit DESC)          					AS profit_rank,
        RANK() OVER (ORDER BY total_gross_revenue DESC)       					AS revenue_rank,
        ROUND(total_net_profit / SUM(total_net_profit) OVER () * 100, 2)  		AS profit_contribution_percentage,
        ROUND(total_gross_revenue / SUM(total_gross_revenue) OVER () * 100, 2)  AS revenue_contribution_percentage
    FROM customer_segment_metrics
)
SELECT customer_type, total_transactions, total_gross_revenue, revenue_contribution_percentage,
    total_discount, avg_discount_rate_percentage, total_gross_profit, total_net_profit, profit_contribution_percentage, 
    avg_profit_per_order, avg_order_value, avg_margin_percentage, profit_rank, revenue_rank,
    CASE
        WHEN profit_rank < revenue_rank THEN 'More Profitable Than Revenue Customer Type '
        WHEN profit_rank > revenue_rank THEN 'Less Profitable Than Revenue Customer Type'
        ELSE 'Consistent Revenue and Profit Rank Aligned'
    END	AS segment_value_signal
FROM segment_with_contribution
ORDER BY profit_rank;


-- BQ5: Pareto Analysis Besaran Profit Concentration Yang Hanya Rely On Ke Sebagian Kecil Products 
-- Mengidentifikasi apakah 80% profit terkonsentrasi
-- di sedikit produk (concentration risk cenderung tinggi)
-- Menggunakan Window Function untuk membuat cumulative/rolling sum 

SELECT *
FROM BQ5; -- Hasil View EDA Business Question 5

WITH product_profit AS (
    SELECT product_name, product_category,
        COUNT(DISTINCT order_no)                        				AS total_orders,
        SUM(order_quantity)                            			    	AS total_items_sold,
        ROUND(SUM(sub_total), 2)										AS gross_revenue,
        ROUND(SUM(profit_margin * order_quantity), 2) 					AS gross_profit,
        ROUND(AVG(profit_margin / NULLIF(retail_price, 0)) * 100, 2) 	AS avg_margin_percentage
    FROM retail_clean_dataset
    GROUP BY product_name, product_category
),
product_ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY gross_profit DESC)        												AS profit_rank,
        ROUND(gross_profit / SUM(gross_profit) OVER () * 100, 2)    									AS profit_contribution_percentage,
        ROUND(SUM(gross_profit) OVER (ORDER BY gross_profit DESC) / SUM(gross_profit) OVER () * 100, 2) AS cumulative_profit_percentage
    FROM product_profit
),
pareto_classified AS (
    SELECT *,
        CASE
            WHEN cumulative_profit_percentage <= 50 THEN 'The Head — Top 50% Profit'
            WHEN cumulative_profit_percentage <= 80 THEN 'Core — 50-80% Cumulative Profit'
            ELSE 'Long Tail — Bottom 20% Profit'
        END	AS pareto_tier
    FROM product_ranked
)

SELECT
    pareto_tier,
    COUNT(product_name)                               						      AS total_products,
    CONCAT(ROUND(COUNT(product_name) / (SELECT COUNT(*) FROM product_profit) * 100, 1), '%')   AS percentage_of_total_products,
    ROUND(SUM(gross_profit), 2)                         					      AS tier_gross_profit,
    ROUND(SUM(gross_revenue), 2)                        					      AS tier_gross_revenue,
    ROUND(AVG(avg_margin_percentage), 2)                       				      AS avg_margin_in_tier
FROM pareto_classified
GROUP BY pareto_tier
ORDER BY tier_gross_profit DESC;

SELECT customer_type, product_category, 
	ROUND(SUM(discount_dollar + shipping_cost) / SUM(profit_margin * order_quantity) * 100, 2) AS Total_Leakage
FROM retail_clean_dataset
GROUP BY customer_type, product_category
ORDER BY 2;
