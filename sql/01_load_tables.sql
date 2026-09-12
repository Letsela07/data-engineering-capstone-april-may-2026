/* ============================================================
   CUSTOMER 360 DATA WAREHOUSE
   01 - RAW SOURCE DATA LOAD

   Purpose:
   Load the raw Customer 360 activity extract CSV into the
   source.customer_activity_extract landing table.

   Load Strategy:
   This project uses a full refresh approach. The source table
   is truncated before every load so that the pipeline can be
   safely re-run without creating duplicate records.

   The source data is preserved in its raw form. Cleaning,
   transformation and data type conversion will take place
   downstream in the staging layer.
   ============================================================ */

USE Customer360_DW;
GO


/* ------------------------------------------------------------
   1. PREPARE SOURCE TABLE

   Remove records from the previous load before importing the
   full source extract again.
   ------------------------------------------------------------ */

TRUNCATE TABLE source.customer_activity_extract;
GO


/* ------------------------------------------------------------
   2. LOAD RAW CSV

   FIRSTROW = 2
       Skips the header row.

   FIELDQUOTE = '"'
       Handles CSV fields enclosed in double quotes.

   ROWTERMINATOR = '0x0a'
       Uses the line-feed character to identify the end of
       each record.

   CODEPAGE = '65001'
       Reads the source file using UTF-8 encoding.

   TABLOCK
       Uses a table-level lock during the bulk load.
   ------------------------------------------------------------ */

BULK INSERT source.customer_activity_extract
FROM 'C:\Mydata\activity_extract.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* ------------------------------------------------------------
   3. VALIDATE RAW LOAD

   Confirm that the expected number of records was loaded and
   visually inspect a sample to verify that the CSV columns
   were mapped correctly.

   Expected row count: 21,500
   ------------------------------------------------------------ */

SELECT COUNT(*) AS total_rows
FROM source.customer_activity_extract;


SELECT TOP 20 *
FROM source.customer_activity_extract;
GO