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