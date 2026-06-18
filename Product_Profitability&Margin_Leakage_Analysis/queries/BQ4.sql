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