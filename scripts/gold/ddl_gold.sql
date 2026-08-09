/*
================================================================================
DDL Script: Create Gold Views
================================================================================
Script Purpose:
    This script creates views for the Gold Layer in the data warehouse.
    The Gold layer represents the final dimensions and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
================================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

IF OBJECT_ID ('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.CNTRY AS country,
	ci.cst_marital_status AS marital_status,
	CASE 
		WHEN ci.cst_gndr IN ('Male', 'Female') THEN ci.cst_gndr
		WHEN ci.cst_gndr = 'Unknown' AND ca.GEN IN ('Male', 'Female') THEN ca.GEN
		ELSE 'Unknown'
	END AS gender,
	ca.BDATE AS birthday,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca ON ci.cst_key = ca.CID
LEFT JOIN silver.erp_loc_a101 AS la ON ci.cst_key = la.CID

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================

IF OBJECT_ID ('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	px.CAT AS category,
	px.SUBCAT AS subcategory,
	px.MAINTENANCE AS maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 AS px ON px.ID = pn.cat_id
WHERE prd_end_dt IS NULL           -- Filter out all the historical data

-- =============================================================================
-- Create Dimension: gold.fact_sales
-- =============================================================================

IF OBJECT_ID ('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT 
	sd.sls_ord_num AS order_number, 
	pr.product_key, 
	cst.customer_key, 
	sd.sls_order_dt AS order_date, 
	sd.sls_ship_dt AS shipping_date, 
	sd.sls_due_dt AS due_date, 
	sd.sls_sales AS sales_amount, 
	sd.sls_quantity AS quantity, 
	sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cst ON sd.sls_cust_id = cst.customer_id
