/*
================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
================================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
  Actions performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	-- Variables for tracking individual tables and total batch duration
	DECLARE @start_time DATETIME, @end_time DATETIME;
	DECLARE @batch_start DATETIME, @batch_end DATETIME;

	SET @batch_start = GETDATE();

	BEGIN TRY
		PRINT '=================================';
		PRINT 'Loading Silver Layer';
		PRINT '=================================';

		PRINT '---------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------';

		-- Table 1: Cust Info
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info'
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Data Into: silver.crm_cust_info'
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date

		)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				ELSE 'Unknown'
			END AS cst_marital_status,
			CASE
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				ELSE 'Unknown'
			END AS cst_gndr,
			cst_create_date
		FROM(
			SELECT 
			*,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		)t WHERE flag_last = 1
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';









		-- Table 2: Prod Info
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info'
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.crm_prd_info'
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
			prd_nm, 
			ISNULL(prd_cost, 0) AS prd_cost, 
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				Else 'unknown'
			END AS prd_line, 
			CAST(prd_start_dt AS DATE) AS prd_start_dt, 
			CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';









		-- Table 3: Sales details
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details'
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Data Into: silver.crm_sales_details'
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num, 
			sls_prd_key,                                                             -- Matches prd_key from sliver.crm_prd_info
			sls_cust_id,                                                             -- Matches cst_id from silver.crm_cust_info


			-- =======================================================
			-- sls_order_dt
			-- =======================================================
			CASE                                                                     -- Has zero value dates and has less than 8 character values
				WHEN sls_order_dt >= 10000101 
					THEN CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE)
				ELSE NULL 
			END AS sls_order_dt,


			-- =======================================================
			-- sls_ship_dt
			-- =======================================================
			CASE                                                                     -- The data is clean
				WHEN sls_ship_dt >= 10000101 
					THEN CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE)
				ELSE NULL 
			END AS sls_ship_dt,


			-- =======================================================
			-- sls_due_dt
			-- =======================================================
			CASE                                                                      -- The data is clean
				WHEN sls_due_dt >= 10000101 
					THEN CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE)
				ELSE NULL 
			END AS sls_due_dt,


			-- =======================================================
			-- sls_sales
			-- =======================================================
			sls_quantity * CASE 
				WHEN sls_price IS NULL OR sls_price = 0 THEN 
					CASE WHEN sls_sales IS NOT NULL AND sls_sales > 0 THEN ABS(sls_sales) ELSE 0.00 END
				WHEN sls_price < 0 THEN ABS(sls_price)
				ELSE sls_price
			END AS sls_sales,                                                        -- Has both nulls and negatives


			sls_quantity,                                                            -- The data is clean


			-- =======================================================
			-- sls_price
			-- =======================================================
			CASE 
				-- If price is 0 or NULL, pull price from the raw sales column if it exists
				WHEN sls_price IS NULL OR sls_price = 0 THEN 
					CASE WHEN sls_sales IS NOT NULL AND sls_sales > 0 THEN ABS(sls_sales) ELSE 0.00 END
				-- If price is negative, make it positive
				WHEN sls_price < 0 THEN ABS(sls_price)
				ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_details




		--IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
		--    DROP TABLE silver.crm_sales_details;
		--GO

		---- 3) sales_details
		--CREATE TABLE silver.crm_sales_details(
		--    sls_ord_num         NVARCHAR(50),
		--    sls_prd_key         NVARCHAR(50),
		--    sls_cust_id         INT,
		--    sls_order_dt        DATE,
		--    sls_ship_dt         DATE,
		--    sls_due_dt          DATE,
		--    sls_sales           INT,
		--    sls_quantity        INT,
		--    sls_price           INT,
		--    dwh_create_date     DATETIME2 DEFAULT GETDATE()
		--);
		--GO
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';









		PRINT '---------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '---------------------------------';

		-- Table 4: cust_az12
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_cust_az12'
		TRUNCATE TABLE silver.erp_cust_az12
		PRINT '>> Inserting Data Into: silver.erp_cust_az12'
		INSERT INTO silver.erp_cust_az12(
			CID,
			BDATE,
			GEN
		)
		SELECT
			CASE
				WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
				ELSE CID
			END CID,
			CASE 
				-- If BDATE is in the future or before 1900, set to NULL
				WHEN BDATE > GETDATE() OR BDATE < '1900-01-01' THEN NULL
				ELSE BDATE
			END AS BDATE,
			CASE WHEN UPPER(TRIM(GEN)) = '' THEN 'Unknown'
				WHEN UPPER(TRIM(GEN)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(GEN)) = 'M' THEN 'Male'
				WHEN UPPER(TRIM(GEN)) IS NULL THEN 'Unknown'
				ELSE GEN
			END AS GEN
		FROM bronze.erp_cust_az12
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';








		-- Table 5: loc_a101
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101'
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101'
		INSERT INTO silver.erp_loc_a101(
			CID,
			CNTRY
		)
		SELECT
			REPLACE(CID, '-', '') AS CID,
			CASE 
				-- 1. Handle spaces, empty strings, and NULLs
				WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'Unknown'
        
				-- 2. Standardize United States variants
				WHEN TRIM(CNTRY) IN ('US', 'USA', 'United States') THEN 'United States'
        
				-- 3. Standardize Germany variants
				WHEN TRIM(CNTRY) IN ('DE', 'Germany') THEN 'Germany'
        
				-- 4. Keep all other clean countries as trimmed values
				ELSE TRIM(CNTRY)
			END AS CNTRY
		FROM bronze.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';








		-- Table 6: px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2'
		TRUNCATE TABLE silver.erp_px_cat_g1v2
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2'
		INSERT INTO silver.erp_px_cat_g1v2(
			ID,
			CAT,
			SUBCAT,
			MAINTENANCE
		)
		SELECT
			ID,
			CAT,
			SUBCAT,
			MAINTENANCE
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';

		-- Summary Batch Info
		SET @batch_end = GETDATE();
		PRINT '=================================';
		PRINT 'Silver Layer Loaded Successfully';
		PRINT 'Total Batch Duration: ' + CAST(DATEDIFF(second, @batch_start, @batch_end) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

	END TRY
	BEGIN CATCH
		PRINT '=================================';
		PRINT 'ERROR OCCURRED DURING LOADING';
		PRINT '=================================';
		
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number:  ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
		PRINT 'Error State:   ' + CAST(ERROR_STATE() AS VARCHAR(10));

		THROW; 
	END CATCH
END
