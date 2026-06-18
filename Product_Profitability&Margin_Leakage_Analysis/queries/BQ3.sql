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