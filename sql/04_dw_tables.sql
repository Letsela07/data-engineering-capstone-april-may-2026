USE Customer360_DW;
GO

/*==============================================================
  CUSTOMER360 DATA WAREHOUSE
  FILE: 04_dw_tables.sql

  PURPOSE:
  Create the dimensional model for the Customer360 warehouse.

  MODEL:
  Dimensions:
      - dim_client
      - dim_product
      - dim_account
      - dim_date

  Facts:
      - fact_transaction
      - fact_product_enrollment
      - fact_interaction
==============================================================*/


/*==============================================================
  1. CLIENT DIMENSION

  GRAIN:
  One row per client.

  SCD:
  Type 1 because the source provides current client information
  rather than historical client versions.
==============================================================*/

IF OBJECT_ID('dw.dim_client', 'U') IS NULL
BEGIN
    CREATE TABLE dw.dim_client
    (
        client_key      INT IDENTITY(1,1) PRIMARY KEY,
        client_number   VARCHAR(20) NOT NULL UNIQUE,
        first_name      VARCHAR(100),
        last_name       VARCHAR(100),
        email           VARCHAR(255),
        mobile_number   VARCHAR(20),
        date_of_birth   DATE,
        gender          VARCHAR(10),
        province        VARCHAR(50),
        city            VARCHAR(100),
        signup_date     DATE
    );
END;
GO


/*==============================================================
  2. PRODUCT DIMENSION

  GRAIN:
  One row per product type.
==============================================================*/

IF OBJECT_ID('dw.dim_product', 'U') IS NULL
BEGIN
    CREATE TABLE dw.dim_product
    (
        product_key     INT IDENTITY(1,1) PRIMARY KEY,
        product_type    VARCHAR(50) NOT NULL UNIQUE
    );
END;
GO


/*==============================================================
  3. ACCOUNT DIMENSION

  GRAIN:
  One row per account.

  SCD:
  Type 1 for account status.
==============================================================*/

IF OBJECT_ID('dw.dim_account', 'U') IS NULL
BEGIN
    CREATE TABLE dw.dim_account
    (
        account_key      INT IDENTITY(1,1) PRIMARY KEY,
        account_number   VARCHAR(20) NOT NULL UNIQUE,
        account_status   VARCHAR(20)
    );
END;
GO


/*==============================================================
  4. DATE DIMENSION

  GRAIN:
  One row per calendar date.

  date_key uses YYYYMMDD format.
==============================================================*/

IF OBJECT_ID('dw.dim_date', 'U') IS NULL
BEGIN
    CREATE TABLE dw.dim_date
    (
        date_key          INT PRIMARY KEY,
        full_date         DATE NOT NULL UNIQUE,
        day_number        TINYINT NOT NULL,
        month_number      TINYINT NOT NULL,
        month_name        VARCHAR(20) NOT NULL,
        quarter_number    TINYINT NOT NULL,
        year_number       SMALLINT NOT NULL
    );
END;
GO


/*==============================================================
  5. TRANSACTION FACT

  GRAIN:
  One row per transaction event.

  DATA QUALITY:
  orphan_account_flag:
      1 = no matching Product Enrollment account
      0 = matching account found

  zero_amount_flag:
      1 = transaction amount is zero
      0 = transaction amount is non-zero
==============================================================*/

IF OBJECT_ID('dw.fact_transaction', 'U') IS NULL
BEGIN
    CREATE TABLE dw.fact_transaction
    (
        transaction_key       BIGINT IDENTITY(1,1) PRIMARY KEY,

        client_key            INT NOT NULL,
        date_key              INT NOT NULL,
        account_key           INT NOT NULL,
        product_key           INT NOT NULL,

        transaction_type      VARCHAR(50) NOT NULL,
        channel               VARCHAR(50) NOT NULL,
        amount                DECIMAL(18,2) NOT NULL,

        orphan_account_flag   BIT NOT NULL,
        zero_amount_flag      BIT NOT NULL,

        CONSTRAINT fk_transaction_client
            FOREIGN KEY (client_key)
            REFERENCES dw.dim_client(client_key),

        CONSTRAINT fk_transaction_date
            FOREIGN KEY (date_key)
            REFERENCES dw.dim_date(date_key),

        CONSTRAINT fk_transaction_account
            FOREIGN KEY (account_key)
            REFERENCES dw.dim_account(account_key),

        CONSTRAINT fk_transaction_product
            FOREIGN KEY (product_key)
            REFERENCES dw.dim_product(product_key)
    );
END;
GO


/*==============================================================
  6. PRODUCT ENROLLMENT FACT

  GRAIN:
  One row per client account/product enrollment event.

  MEASURES:
  - credit_limit
  - loan_amount
  - account_balance
==============================================================*/

IF OBJECT_ID('dw.fact_product_enrollment', 'U') IS NULL
BEGIN
    CREATE TABLE dw.fact_product_enrollment
    (
        enrollment_key     BIGINT IDENTITY(1,1) PRIMARY KEY,

        client_key         INT NOT NULL,
        date_key           INT NOT NULL,
        account_key        INT NOT NULL,
        product_key        INT NOT NULL,

        credit_limit       DECIMAL(18,2),
        loan_amount        DECIMAL(18,2),
        account_balance    DECIMAL(18,2),

        CONSTRAINT fk_enrollment_client
            FOREIGN KEY (client_key)
            REFERENCES dw.dim_client(client_key),

        CONSTRAINT fk_enrollment_date
            FOREIGN KEY (date_key)
            REFERENCES dw.dim_date(date_key),

        CONSTRAINT fk_enrollment_account
            FOREIGN KEY (account_key)
            REFERENCES dw.dim_account(account_key),

        CONSTRAINT fk_enrollment_product
            FOREIGN KEY (product_key)
            REFERENCES dw.dim_product(product_key)
    );
END;
GO


/*==============================================================
  7. CRM INTERACTION FACT

  GRAIN:
  One row per CRM interaction between a client and the bank.

  CRM records do not contain account or product information,
  therefore account_key and product_key are not included.
==============================================================*/

IF OBJECT_ID('dw.fact_interaction', 'U') IS NULL
BEGIN
    CREATE TABLE dw.fact_interaction
    (
        interaction_key    BIGINT IDENTITY(1,1) PRIMARY KEY,

        client_key         INT NOT NULL,
        date_key           INT NOT NULL,

        interaction_type   VARCHAR(50) NOT NULL,
        channel            VARCHAR(50) NOT NULL,
        resolved_flag      VARCHAR(10) NOT NULL,

        CONSTRAINT fk_interaction_client
            FOREIGN KEY (client_key)
            REFERENCES dw.dim_client(client_key),

        CONSTRAINT fk_interaction_date
            FOREIGN KEY (date_key)
            REFERENCES dw.dim_date(date_key)
    );
END;
GO


/*==============================================================
  VALIDATION
==============================================================*/

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dw'
ORDER BY TABLE_NAME;
GO