/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    -  Truncates the bronze tables before loading data.
    -  Uses the 'BULK INSERT' command to load data from CSV files to bronze tables.

Parameters:
    None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	-- Variables for tracking individual tables and total batch duration
	DECLARE @start_time DATETIME, @end_time DATETIME;
	DECLARE @batch_start DATETIME, @batch_end DATETIME;

	SET @batch_start = GETDATE();

	BEGIN TRY
		PRINT '=================================';
		PRINT 'Loading Bronze Layer';
		PRINT '=================================';

		PRINT '---------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------';

		-- Table 1: Cust Info
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_cust_info'
		TRUNCATE TABLE bronze.crm_cust_info

		PRINT '>> Inserting Data Into: bronze.crm_cust_info'
		BULK INSERT bronze.crm_cust_info
		FROM 'E:\Career\SQL_Datasets\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\r\n',
			TABLOCK
		)
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';


		-- Table 2: Prod Info
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info'
		TRUNCATE TABLE bronze.crm_prd_info

		PRINT '>> Inserting Data Into: bronze.crm_prd_info'
		BULK INSERT bronze.crm_prd_info
		FROM 'E:\Career\SQL_Datasets\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\r\n',
			TABLOCK
		)
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';


		-- Table 3: Sales details
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details'
		TRUNCATE TABLE bronze.crm_sales_details

		PRINT '>> Inserting Data Into: bronze.crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'E:\Career\SQL_Datasets\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\r\n',
			TABLOCK
		)
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';


		PRINT '---------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '---------------------------------';

		-- Table 4: cust_az12
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_cust_az12'
		TRUNCATE TABLE bronze.erp_cust_az12

		PRINT '>> Inserting Data Into: bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM 'E:\Career\SQL_Datasets\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\r\n',
			TABLOCK
		)
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';


		-- Table 5: loc_a101
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101'
		TRUNCATE TABLE bronze.erp_loc_a101

		PRINT '>> Inserting Data Into: bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		FROM 'E:\Career\SQL_Datasets\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\r\n',
			TABLOCK
		)
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';


		-- Table 6: px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2'
		TRUNCATE TABLE bronze.erp_px_cat_g1v2

		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'E:\Career\SQL_Datasets\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\r\n',
			TABLOCK
		)
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';

		-- Summary Batch Info
		SET @batch_end = GETDATE();
		PRINT '=================================';
		PRINT 'Bronze Layer Loaded Successfully';
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
