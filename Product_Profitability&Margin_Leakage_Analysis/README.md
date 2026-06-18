# Product Profitability & Margin Leakage Analysis
**Industry:** Retail (B2B & B2C) | **Period:** FY 2013–2017 | **Currency:** AUD

---

## Project Overview
 
This project investigates whether high revenue actually translates to high profitability in a retail business — and where profit leakage occurs across product categories and customer segments.
 
**Main Business Problem:** Management allocates resources based on revenue performance, not profitability. Without understanding true profit contribution per category and segment, the business risks over-investing in areas that erode margin.
 
**Objective:** Identify categories and customer segments driving true profit, quantify leakage sources (discounts & shipping), and detect concentration risk at the product level.
 
---
 
## Dataset Overview
 
| Attribute | Detail |
|---|---|
| Source | Australian Retail B2B/B2C |
| Rows | 4,999 transactions |
| Columns | 23 |
| Unique Products | 257 SKUs |
| Unique Customers | 788 |
| Categories | Office Supplies, Technology, Furniture |
| Customer Types | Corporate, Consumer, Home Office, Small Business |
 
---

### Data Dictionary
 
| Column | Data Type | Description | Notes |
|---|---|---|---|
| Order No | VARCHAR | Unique order identifier | 1 order bisa multi-row (multi-item) |
| Order Date | DATE | Tanggal order dibuat | Format: YYYY/MM/DD |
| Ship Date | DATE | Tanggal pengiriman | |
| Customer Name | VARCHAR | Nama customer | |
| City | VARCHAR | Kota customer | |
| State | VARCHAR | State (NSW / VIC) | |
| Customer Type | VARCHAR | Segmen customer | Corporate, Consumer, Home Office, Small Business |
| Account Manager | VARCHAR | Sales representative | |
| Order Priority | VARCHAR | Prioritas order | Low, Medium, High, Critical |
| Product Name | VARCHAR | Nama produk | |
| Product Category | VARCHAR | Kategori produk | Office Supplies, Technology, Furniture |
| Product Container | VARCHAR | Jenis packaging | |
| Ship Mode | VARCHAR | Metode pengiriman | |
| Cost Price | DECIMAL | Harga beli per unit (COGS) | AUD |
| Retail Price | DECIMAL | Harga jual per unit | AUD |
| Profit Margin | DECIMAL | Retail Price − Cost Price per unit | AUD, bisa negatif |
| Order Quantity | INTEGER | Jumlah item dipesan | |
| Sub Total | DECIMAL | Retail Price × Order Quantity | Gross Revenue |
| Discount Percentage | DECIMAL | % diskon yang diberikan | 0–1 format |
| Discount Dollar | DECIMAL | Sub Total × Discount % | AUD |
| Order Total | DECIMAL | Sub Total − Discount Dollar | Net revenue after discount |
| Shipping Cost | DECIMAL | Biaya pengiriman ditanggung bisnis | AUD |
| Total | DECIMAL | Order Total − Shipping Cost | Net revenue after all deductions |

---

## Data Cleaning (Power Query / M Language)
 
**Key Issues Found:**
 
| Issue | Action Taken |
|---|---|
| All financial columns stored as text with `$` and `,` | Converted to numeric via Power Query |
| Date columns stored as strings | Converted to DATE type |
| 4 derived columns (Sub Total, Discount $, Order Total, Total) had mathematical inconsistencies across ~99% of rows | Recalculated from valid raw inputs |
| 1 completely blank row | Removed |
| 4 rows: Cost Price > Retail Price with positive Profit Margin (mathematical contradiction) | Margin recalculated — resulted in negative values, kept as valid business finding |
 
**Before vs After:**
```
Rows              : 5,000 → 4,999
Math Consistency  : 0.76% → 99.98%
Null Values       : 1 blank row → 0
```
 
**Cleaning Decision Note:**
> Sub Total, Discount Dollar, Order Total, and Total columns had near-universal mathematical inconsistencies — likely caused by data entry errors at the source system. All four derived columns were recalculated from raw inputs (Retail Price, Quantity, Discount %, Shipping Cost) which proved 99.56% consistent.
 
---

## Key Insights
 
```
1. Revenue $5.19M — Net Profit $2.14M (41.2% margin)
   Gap 58.8% tergerus oleh COGS, discount, dan shipping.
 
2. Furniture memiliki gross margin tertinggi (51.4%)
   tapi leakage rate tertinggi (14.5%) — masalah ada
   di discount + shipping policy, bukan produknya.
 
3. Furniture × Corporate dan × Consumer sama-sama
   14.8% leakage rate → Corporate dominant buyer
   (92 orders) dengan avg shipping cost tertinggi ($4.97).
 
4. Corporate berkontribusi 34.4% net profit —
   tapi dengan leakage yang ada, angka ini
   belum optimal.
 
5. 7 produk (1.5% SKU) menopang 50% gross profit
   → high concentration risk.
```
 
---
 
## Recommendations
 
| Priority | Action |
|---|---|---|
| 🔴 High | Revisi Discount Policy untuk Kategori Produk Furniture × Corporate & Consumer. Discount yang diberikan ke Corporate dan Consumer di Furniture tidak mempertimbangkan bahwa kategori ini sudah punya structural cost disadvantage dari shipping. Solusinya bukan menghapus diskon, tapi menyesuaikan maximum discount % untuk Furniture dengan memasukkan "cost to serve" (shipping) sebagai variabel dalam formula diskon. Expected impactnya: Reduce Furniture leakage dari 14.5% ke <11%. |
| 🟡 Medium | Diversifikasi dari Long Tail ke Core. Dari 436 produk di Long Tail, identifikasi produk mana yang memiliki margin tertinggi tapi volume rendah. Berikan push promosi atau visibility lebih ke produk-produk ini agar secara volume bisa meningkat dan "naik kelas" ke Core. Expected Impactnya: Diversifikasi profit base dari 7 ke 15+ produk. |
| 🟡 Medium | Protect The Head. 7 produk yang generate 50% profit harus diprioritaskan dalam hal: ketersediaan stok, SLA pengiriman, dan tidak dijadikan subjek eksperimen diskon agresif. Once ada gangguan di level ini langsung terasa ke bottom line. Expected Impact: Melindungi $1.17M gross profit (The Head) dari disruption. |
 
---
 
## Analysis Method
 
```
Primary   : Product Profitability Analysis
Secondary : Pareto Analysis (80/20 Rule)
Supporting: Profit Leakage Analysis
            Customer Segment Profitability Analysis
```
 
## KPI Framework
 
| KPI | Formula | Result |
|---|---|---|
| Gross Profit Margin % | Gross Profit / Gross Revenue × 100 | 46.6% |
| Net Profit Margin % | Net Profit / Gross Revenue × 100 | 41.2% |
| Total Leakage Rate | (Discount + Shipping) / Gross Profit × 100 | 11.6% |
| Net Profit Contribution % per Segment | Net Profit Segment / Total Net Profit × 100 | Corporate 34.4% |
| Pareto Concentration Ratio | % Profit from Top 1.5% SKUs | 50% |
 
---
 
## Tools
 
| Tool | Purpose |
|---|---|
| Excel Power Query | Data cleaning, type conversion, derived column recalculation |
| MySQL Workbench 8.0 | EDA queries, window functions, CTEs |
| Tableau Public 2026.1 | Interactive dashboard, KPI cards, heatmap, Pareto chart |
 
---