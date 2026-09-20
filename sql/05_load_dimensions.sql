USE Customer360_DW;
GO

/*==============================================================
  FILE: 05_load_dimensions.sql

  1. LOAD DIM_CLIENT

  Business key: client_number
  SCD strategy: Type 1
  Expected rows: 1,484
==============================================================*/

;WITH all_clients AS
(
    SELECT
        client_number,
        first_name,
        last_name,
        email,
        mobile_number,
        date_of_birth,
        gender,
        province,
        city,
        signup_date
    FROM staging.product_enrollment

    UNION

    SELECT
        client_number,
        first_name,
        last_name,
        email,
        mobile_number,
        date_of_birth,
        gender,
        province,
        city,
        signup_date
    FROM staging.crm_interaction

    UNION

    SELECT
        client_number,
        first_name,
        last_name,
        email,
        mobile_number,
        date_of_birth,
        gender,
        province,
        city,
        signup_date
    FROM staging.[transaction]
)

/* Update existing clients - SCD Type 1 */
UPDATE target
SET
    target.first_name     = source.first_name,
    target.last_name      = source.last_name,
    target.email          = source.email,
    target.mobile_number  = source.mobile_number,
    target.date_of_birth  = source.date_of_birth,
    target.gender         = source.gender,
    target.province       = source.province,
    target.city           = source.city,
    target.signup_date    = source.signup_date
FROM dw.dim_client AS target
INNER JOIN all_clients AS source
    ON target.client_number = source.client_number;
GO


/* Insert clients that do not already exist */
;WITH all_clients AS
(
    SELECT
        client_number,
        first_name,
        last_name,
        email,
        mobile_number,
        date_of_birth,
        gender,
        province,
        city,
        signup_date
    FROM staging.product_enrollment

    UNION

    SELECT
        client_number,
        first_name,
        last_name,
        email,
        mobile_number,
        date_of_birth,
        gender,
        province,
        city,
        signup_date
    FROM staging.crm_interaction

    UNION

    SELECT
        client_number,
        first_name,
        last_name,
        email,
        mobile_number,
        date_of_birth,
        gender,
        province,
        city,
        signup_date
    FROM staging.[transaction]
)

INSERT INTO dw.dim_client
(
    client_number,
    first_name,
    last_name,
    email,
    mobile_number,
    date_of_birth,
    gender,
    province,
    city,
    signup_date
)
SELECT
    source.client_number,
    source.first_name,
    source.last_name,
    source.email,
    source.mobile_number,
    source.date_of_birth,
    source.gender,
    source.province,
    source.city,
    source.signup_date
FROM all_clients AS source
WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.dim_client AS target
    WHERE target.client_number = source.client_number
);
GO


/*==============================================================
  VALIDATION
==============================================================*/

SELECT COUNT(*) AS client_count
FROM dw.dim_client;

SELECT TOP 10 *
FROM dw.dim_client
ORDER BY client_key;
GO


/*==============================================================
  2. LOAD DIM_PRODUCT

  Business key: product_type
  Expected rows: 3
==============================================================*/

;WITH all_products AS
(
    SELECT product_type
    FROM staging.product_enrollment
    WHERE product_type IS NOT NULL

    UNION

    SELECT product_type
    FROM staging.[transaction]
    WHERE product_type IS NOT NULL
)

INSERT INTO dw.dim_product
(
    product_type
)
SELECT
    source.product_type
FROM all_products AS source
WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.dim_product AS target
    WHERE target.product_type = source.product_type
);
GO


/*==============================================================
  VALIDATION
==============================================================*/

SELECT *
FROM dw.dim_product
ORDER BY product_key;
GO


/*==============================================================
  3. LOAD DIM_ACCOUNT

  Business key: account_number
  SCD strategy: Type 1

  Accounts observed only in Transaction data are retained.
  Their account_status is set to 'Unknown' because no matching
  Product Enrollment record exists.
==============================================================*/

;WITH all_accounts AS
(
    /* Accounts with Product Enrollment information */
    SELECT
        account_number,
        account_status
    FROM staging.product_enrollment
    WHERE account_number IS NOT NULL

    UNION

    /* Orphan accounts found only in Transaction data */
    SELECT DISTINCT
        t.account_number,
        'Unknown' AS account_status
    FROM staging.[transaction] AS t
    WHERE t.account_number IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM staging.product_enrollment AS pe
          WHERE pe.client_number = t.client_number
            AND pe.account_number = t.account_number
      )
)

INSERT INTO dw.dim_account
(
    account_number,
    account_status
)
SELECT
    source.account_number,
    source.account_status
FROM all_accounts AS source
WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.dim_account AS target
    WHERE target.account_number = source.account_number
);
GO


/*==============================================================
  VALIDATION
==============================================================*/

SELECT COUNT(*) AS account_count
FROM dw.dim_account;

SELECT account_status, COUNT(*) AS account_count
FROM dw.dim_account
GROUP BY account_status
ORDER BY account_status;

SELECT *
FROM dw.dim_account
WHERE account_status = 'Unknown';
GO


/*==============================================================
  4. LOAD DIM_DATE

  GRAIN:
  One row per calendar date.

  RANGE:
  Every calendar date between the earliest and latest event_date
  across all three staging tables.

  date_key format:
  YYYYMMDD

  Existing dates are preserved to make the load rerunnable.
==============================================================*/

DECLARE @min_date DATE;
DECLARE @max_date DATE;


/* Find the earliest and latest event dates */
SELECT
    @min_date = MIN(event_date),
    @max_date = MAX(event_date)
FROM
(
    SELECT event_date
    FROM staging.product_enrollment
    WHERE event_date IS NOT NULL

    UNION ALL

    SELECT event_date
    FROM staging.crm_interaction
    WHERE event_date IS NOT NULL

    UNION ALL

    SELECT event_date
    FROM staging.[transaction]
    WHERE event_date IS NOT NULL
) AS all_event_dates;


/* Generate every calendar date between MIN and MAX */
;WITH date_range AS
(
    SELECT @min_date AS full_date

    UNION ALL

    SELECT DATEADD(DAY, 1, full_date)
    FROM date_range
    WHERE full_date < @max_date
)

INSERT INTO dw.dim_date
(
    date_key,
    full_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), full_date, 112)) AS date_key,
    full_date,
    DAY(full_date) AS day_number,
    MONTH(full_date) AS month_number,
    DATENAME(MONTH, full_date) AS month_name,
    DATEPART(QUARTER, full_date) AS quarter_number,
    YEAR(full_date) AS year_number
FROM date_range AS d
WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.dim_date AS target
    WHERE target.full_date = d.full_date
)
OPTION (MAXRECURSION 0);
GO


/*==============================================================
  VALIDATION
==============================================================*/

SELECT
    COUNT(*) AS date_count,
    MIN(full_date) AS earliest_date,
    MAX(full_date) AS latest_date
FROM dw.dim_date;

SELECT TOP 10 *
FROM dw.dim_date
ORDER BY full_date;
GO