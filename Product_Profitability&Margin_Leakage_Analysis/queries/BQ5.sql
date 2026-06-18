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