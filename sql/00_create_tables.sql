/* ============================================================
   CUSTOMER 360 DATA WAREHOUSE
   Initial Database and Landing Layer Setup
   ============================================================ */


/* ------------------------------------------------------------
   1. CREATE DATABASE
   Create the database only if it does not already exist.
   ------------------------------------------------------------ */

IF DB_ID('Customer360_DW') IS NULL
BEGIN
    CREATE DATABASE Customer360_DW;
END;
GO


USE Customer360_DW;
GO


/* ------------------------------------------------------------
   2. CREATE SCHEMAS
   ------------------------------------------------------------ */

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'source'
)
BEGIN
    EXEC('CREATE SCHEMA source');
END;
GO


IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'staging'
)
BEGIN
    EXEC('CREATE SCHEMA staging');
END;
GO


IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'dw'
)
BEGIN
    EXEC('CREATE SCHEMA dw');
END;
GO


/* ------------------------------------------------------------
   3. CREATE RAW LANDING TABLE

   The columns are intentionally loaded mainly as VARCHAR.
   Data types will be determined downstream after profiling
   the raw source data.
   ------------------------------------------------------------ */

IF OBJECT_ID('source.customer_activity_extract', 'U') IS NULL
BEGIN

    CREATE TABLE source.customer_activity_extract
    (
        client_number       VARCHAR(20),
        first_name          VARCHAR(100),
        last_name           VARCHAR(100),
        email               VARCHAR(200),
        mobile_number       VARCHAR(50),
        date_of_birth       VARCHAR(20),
        gender              VARCHAR(10),
        province            VARCHAR(100),
        city                VARCHAR(100),
        signup_date         VARCHAR(20),

        event_type          VARCHAR(30),
        event_date          VARCHAR(20),

        account_number      VARCHAR(20),
        product_type        VARCHAR(50),
        account_status      VARCHAR(20),
        credit_limit        VARCHAR(20),
        loan_amount         VARCHAR(20),
        account_balance     VARCHAR(20),

        channel             VARCHAR(50),
        interaction_type    VARCHAR(50),
        resolved_flag       VARCHAR(5),

        transaction_type    VARCHAR(50),
        amount              VARCHAR(20)
    );

END;


GO


/* ------------------------------------------------------------
   4. CREATE STAGING TABLES
   Create empty staging tables required by the SSIS pipeline.
   ------------------------------------------------------------ */

IF OBJECT_ID('staging.product_enrollment', 'U') IS NULL
BEGIN
    CREATE TABLE staging.product_enrollment
    (
        client_number      VARCHAR(20),
        first_name         VARCHAR(100),
        last_name          VARCHAR(100),
        email              VARCHAR(255),
        mobile_number      VARCHAR(20),
        date_of_birth      DATE,
        gender             VARCHAR(10),
        province           VARCHAR(50),
        city               VARCHAR(100),
        signup_date        DATE,
        event_date         DATE,
        account_number     VARCHAR(20),
        product_type       VARCHAR(50),
        account_status     VARCHAR(20),
        credit_limit       DECIMAL(18,2),
        loan_amount        DECIMAL(18,2),
        account_balance    DECIMAL(18,2)
    );
END;
GO


IF OBJECT_ID('staging.crm_interaction', 'U') IS NULL
BEGIN
    CREATE TABLE staging.crm_interaction
    (
        client_number      VARCHAR(20),
        first_name         VARCHAR(100),
        last_name          VARCHAR(100),
        email              VARCHAR(255),
        mobile_number      VARCHAR(20),
        date_of_birth      DATE,
        gender             VARCHAR(10),
        province           VARCHAR(50),
        city               VARCHAR(100),
        signup_date        DATE,
        event_date         DATE,
        channel            VARCHAR(50),
        interaction_type   VARCHAR(50),
        resolved_flag      VARCHAR(10)
    );
END;
GO


IF OBJECT_ID('staging.[transaction]', 'U') IS NULL
BEGIN
    CREATE TABLE staging.[transaction]
    (
        client_number      VARCHAR(20),
        first_name         VARCHAR(100),
        last_name          VARCHAR(100),
        email              VARCHAR(255),
        mobile_number      VARCHAR(20),
        date_of_birth      DATE,
        gender             VARCHAR(10),
        province           VARCHAR(50),
        city               VARCHAR(100),
        signup_date        DATE,
        event_date         DATE,
        account_number     VARCHAR(20),
        product_type       VARCHAR(50),
        transaction_type   VARCHAR(50),
        channel            VARCHAR(50),
        amount             DECIMAL(18,2)
    );
END;
GO