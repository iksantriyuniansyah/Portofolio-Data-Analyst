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