USE Customer360_DW;
GO

/*==============================================================
  CUSTOMER360 DATA WAREHOUSE
  FILE: 03_staging.sql

  PURPOSE:
  Create staging tables and load cleaned, typed data from the
  raw source table.

  STAGING APPROACH:
  - Keep the raw source data unchanged.
  - Clean and standardize values in staging.
  - Convert VARCHAR source values to appropriate data types.
  - Preserve existing staging records.
  - Use NOT EXISTS to prevent duplicate loads.
==============================================================*/


/*==============================================================
  1. PRODUCT ENROLLMENT STAGING TABLE
==============================================================*/

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


/*==============================================================
  2. LOAD PRODUCT ENROLLMENT DATA

  Load decision:
  - Existing staging records are preserved.
  - client_number + account_number identifies an existing
    Product Enrollment record.
  - One client may have multiple accounts, therefore
    client_number alone is not sufficient.
==============================================================*/

INSERT INTO staging.product_enrollment
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
    signup_date,
    event_date,
    account_number,
    product_type,
    account_status,
    credit_limit,
    loan_amount,
    account_balance
)
SELECT
    s.client_number,
    s.first_name,
    s.last_name,

    /* Clean email:
       - Preserve missing values as NULL
       - Remove spaces
       - Convert populated emails to lowercase
    */
    CASE
        WHEN s.email IS NULL OR TRIM(s.email) = ''
            THEN NULL
        ELSE LOWER(REPLACE(TRIM(s.email), ' ', ''))
    END AS email,

    /* Clean and validate South African mobile numbers:
       - Remove common formatting characters
       - Keep valid 10-digit local numbers
       - Convert 27xxxxxxxxx to 0xxxxxxxxx
       - Values that remain invalid become NULL
    */
    CASE
        WHEN cleaned.mobile_number_clean LIKE '0%'
             AND LEN(cleaned.mobile_number_clean) = 10
             AND cleaned.mobile_number_clean NOT LIKE '%[^0-9]%'
            THEN cleaned.mobile_number_clean

        WHEN cleaned.mobile_number_clean LIKE '27%'
             AND LEN(cleaned.mobile_number_clean) = 11
             AND cleaned.mobile_number_clean NOT LIKE '%[^0-9]%'
            THEN '0' + SUBSTRING(cleaned.mobile_number_clean, 3, 9)

        ELSE NULL
    END AS mobile_number,

    /* Convert date fields from VARCHAR to DATE */
    TRY_CONVERT(DATE, TRIM(s.date_of_birth), 23) AS date_of_birth,

    s.gender,

    /* Standardize province naming */
    CASE
        WHEN TRIM(s.province) = 'KwaZulu Natal'
            THEN 'KwaZulu-Natal'
        ELSE TRIM(s.province)
    END AS province,

    s.city,

    TRY_CONVERT(DATE, TRIM(s.signup_date), 23) AS signup_date,
    TRY_CONVERT(DATE, TRIM(s.event_date), 23) AS event_date,

    s.account_number,
    s.product_type,
    s.account_status,

    /* Convert monetary fields from VARCHAR to DECIMAL */
    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(TRIM(s.credit_limit), '')
    ) AS credit_limit,

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(TRIM(s.loan_amount), '')
    ) AS loan_amount,

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(TRIM(s.account_balance), '')
    ) AS account_balance

FROM source.customer_activity_extract AS s

/* Remove common mobile-number formatting before validation */
CROSS APPLY
(
    SELECT
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(TRIM(s.mobile_number), ' ', ''),
                    '-', ''
                ),
                '(', ''
            ),
            ')', ''
        ) AS mobile_number_clean
) AS cleaned

WHERE s.event_type = 'Product Enrollment'

/* Prevent the same client/account enrollment from being loaded again */
AND NOT EXISTS
(
    SELECT 1
    FROM staging.product_enrollment AS p
    WHERE p.client_number = s.client_number
      AND p.account_number = s.account_number
);

GO


/*==============================================================
  3. VALIDATE PRODUCT ENROLLMENT LOAD
==============================================================*/

/* Expected result: 2,000 rows */
SELECT COUNT(*) AS product_enrollment_rows
FROM staging.product_enrollment;


/* Review sample cleaned records */
SELECT TOP 20 *
FROM staging.product_enrollment;


/* Reconcile Product Enrollment records by product type */
SELECT
    product_type,
    COUNT(*) AS total_accounts
FROM staging.product_enrollment
GROUP BY product_type
ORDER BY product_type;

GO


/*==============================================================
  VALIDATION RESULT

  - Product Enrollment staging contains 2,000 records.
  - Re-running the INSERT does not create duplicate records.
  - Row count remains 2,000 after repeated execution.
  - client_number + account_number is used to identify records
    already loaded into staging.
==============================================================*/


/*==============================================================
  4. CRM INTERACTION STAGING TABLE

  PURPOSE:
  Store cleaned and typed CRM Interaction records separately
  from the raw source data.
==============================================================*/

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


/*==============================================================
  5. LOAD CRM INTERACTION DATA

  Load decision:
  - Existing staging records are preserved.
  - The supplied source does not contain a unique interaction ID
    or event timestamp.
  - For this dataset, the following combination is used to
    identify an interaction already loaded:

      client_number + event_date + channel + interaction_type

  Limitation:
  - In a production system, a unique interaction ID or a more
    granular timestamp would be preferred.
  - The current combination could not reliably distinguish two
    identical interaction types made by the same client through
    the same channel on the same date.
  - Profiling of the supplied dataset supports this combination
    for the current learning project.
==============================================================*/

INSERT INTO staging.crm_interaction
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
    signup_date,
    event_date,
    channel,
    interaction_type,
    resolved_flag
)
SELECT
    s.client_number,
    s.first_name,
    s.last_name,

    /* Clean email:
       - Preserve missing values as NULL
       - Remove spaces
       - Convert populated emails to lowercase
    */
    CASE
        WHEN s.email IS NULL OR TRIM(s.email) = ''
            THEN NULL
        ELSE LOWER(REPLACE(TRIM(s.email), ' ', ''))
    END AS email,

    /* Clean and validate South African mobile numbers:
       - Remove common formatting characters
       - Keep valid 10-digit local numbers
       - Convert 27xxxxxxxxx to 0xxxxxxxxx
       - Values that remain invalid become NULL
    */
    CASE
        WHEN cleaned.mobile_number_clean LIKE '0%'
             AND LEN(cleaned.mobile_number_clean) = 10
             AND cleaned.mobile_number_clean NOT LIKE '%[^0-9]%'
            THEN cleaned.mobile_number_clean

        WHEN cleaned.mobile_number_clean LIKE '27%'
             AND LEN(cleaned.mobile_number_clean) = 11
             AND cleaned.mobile_number_clean NOT LIKE '%[^0-9]%'
            THEN '0' + SUBSTRING(cleaned.mobile_number_clean, 3, 9)

        ELSE NULL
    END AS mobile_number,

    /* Convert date fields from VARCHAR to DATE */
    TRY_CONVERT(DATE, TRIM(s.date_of_birth), 23) AS date_of_birth,

    s.gender,

    /* Standardize province naming */
    CASE
        WHEN TRIM(s.province) = 'KwaZulu Natal'
            THEN 'KwaZulu-Natal'
        ELSE TRIM(s.province)
    END AS province,

    s.city,

    TRY_CONVERT(DATE, TRIM(s.signup_date), 23) AS signup_date,
    TRY_CONVERT(DATE, TRIM(s.event_date), 23) AS event_date,

    s.channel,
    s.interaction_type,

    /* Make missing resolution status explicit */
    CASE
        WHEN s.resolved_flag IS NULL
             OR TRIM(s.resolved_flag) = ''
            THEN 'Unknown'
        ELSE TRIM(s.resolved_flag)
    END AS resolved_flag

FROM source.customer_activity_extract AS s

/* Remove common mobile-number formatting before validation */
CROSS APPLY
(
    SELECT
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(TRIM(s.mobile_number), ' ', ''),
                    '-', ''
                ),
                '(', ''
            ),
            ')', ''
        ) AS mobile_number_clean
) AS cleaned

WHERE s.event_type = 'CRM Interaction'

/* Prevent previously loaded CRM interactions from being inserted again */
AND NOT EXISTS
(
    SELECT 1
    FROM staging.crm_interaction AS c
    WHERE c.client_number = s.client_number
      AND c.event_date = TRY_CONVERT(DATE, TRIM(s.event_date), 23)
      AND c.channel = s.channel
      AND c.interaction_type = s.interaction_type
);

GO


/*==============================================================
  6. VALIDATE CRM INTERACTION LOAD
==============================================================*/

/* Expected result: 4,500 CRM Interaction records */
SELECT COUNT(*) AS crm_interaction_rows
FROM staging.crm_interaction;


/* Review sample cleaned records */
SELECT TOP 20 *
FROM staging.crm_interaction;


/* Check resolved status after transformation */
SELECT
    resolved_flag,
    COUNT(*) AS total_interactions
FROM staging.crm_interaction
GROUP BY resolved_flag
ORDER BY resolved_flag;


/* Reconcile interactions by channel */
SELECT
    channel,
    COUNT(*) AS total_interactions
FROM staging.crm_interaction
GROUP BY channel
ORDER BY channel;

GO


/*==============================================================
  EXPECTED VALIDATION

  Total CRM records:
  - 4,500

  resolved_flag:
  - Y       = 3,410
  - N       =   873
  - Unknown =   217

  Re-running this load should not increase the row count beyond
  4,500 for the supplied dataset.
==============================================================*/


/*==============================================================
  7. TRANSACTION STAGING TABLE

  PURPOSE:
  Store cleaned and typed Transaction records separately from
  the raw source data.
==============================================================*/

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


/*==============================================================
  8. LOAD TRANSACTION DATA

  Load decision:
  - Existing staging records are preserved.
  - The source does not provide a unique transaction ID or
    transaction timestamp.
  - For the supplied dataset, the following combination is used
    to identify a transaction already loaded:

      client_number
      + account_number
      + event_date
      + transaction_type
      + channel
      + amount

  Limitation:
  - This is a dataset-specific solution.
  - In a production system, a source-provided transaction ID
    would be preferred.
  - Two genuine transactions with exactly the same values could
    not be distinguished using the available source fields.

  Data-quality decisions:
  - Source amount signs are preserved.
  - Zero-value transactions are retained.
  - Transactions without matching Product Enrollment accounts
    are retained.
  - Data-quality flags can be considered later during warehouse
    modelling.
==============================================================*/

INSERT INTO staging.[transaction]
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
    signup_date,
    event_date,
    account_number,
    product_type,
    transaction_type,
    channel,
    amount
)
SELECT
    s.client_number,
    s.first_name,
    s.last_name,

    /* Clean email:
       - Preserve missing values as NULL
       - Remove spaces
       - Convert populated emails to lowercase
    */
    CASE
        WHEN s.email IS NULL OR TRIM(s.email) = ''
            THEN NULL
        ELSE LOWER(REPLACE(TRIM(s.email), ' ', ''))
    END AS email,

    /* Clean and validate South African mobile numbers:
       - Remove common formatting characters
       - Keep valid 10-digit local numbers
       - Convert 27xxxxxxxxx to 0xxxxxxxxx
       - Values that remain invalid become NULL
    */
    CASE
        WHEN cleaned.mobile_number_clean LIKE '0%'
             AND LEN(cleaned.mobile_number_clean) = 10
             AND cleaned.mobile_number_clean NOT LIKE '%[^0-9]%'
            THEN cleaned.mobile_number_clean

        WHEN cleaned.mobile_number_clean LIKE '27%'
             AND LEN(cleaned.mobile_number_clean) = 11
             AND cleaned.mobile_number_clean NOT LIKE '%[^0-9]%'
            THEN '0' + SUBSTRING(cleaned.mobile_number_clean, 3, 9)

        ELSE NULL
    END AS mobile_number,

    /* Convert date fields from VARCHAR to DATE */
    TRY_CONVERT(DATE, TRIM(s.date_of_birth), 23) AS date_of_birth,

    s.gender,

    /* Standardize province naming */
    CASE
        WHEN TRIM(s.province) = 'KwaZulu Natal'
            THEN 'KwaZulu-Natal'
        ELSE TRIM(s.province)
    END AS province,

    s.city,

    TRY_CONVERT(DATE, TRIM(s.signup_date), 23) AS signup_date,
    TRY_CONVERT(DATE, TRIM(s.event_date), 23) AS event_date,

    s.account_number,
    s.product_type,
    s.transaction_type,
    s.channel,

    /* Convert amount to DECIMAL.
       Preserve the source sign and zero-value transactions.
    */
    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(TRIM(s.amount), '')
    ) AS amount

FROM source.customer_activity_extract AS s

/* Remove common mobile-number formatting before validation */
CROSS APPLY
(
    SELECT
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(TRIM(s.mobile_number), ' ', ''),
                    '-', ''
                ),
                '(', ''
            ),
            ')', ''
        ) AS mobile_number_clean
) AS cleaned

WHERE s.event_type = 'Transaction'

/* Prevent previously loaded transactions from being inserted again */
AND NOT EXISTS
(
    SELECT 1
    FROM staging.[transaction] AS t
    WHERE t.client_number = s.client_number
      AND t.account_number = s.account_number
      AND t.event_date =
          TRY_CONVERT(DATE, TRIM(s.event_date), 23)
      AND t.transaction_type = s.transaction_type
      AND t.channel = s.channel
      AND t.amount =
          TRY_CONVERT(
              DECIMAL(18,2),
              NULLIF(TRIM(s.amount), '')
          )
);

GO


/*==============================================================
  9. VALIDATE TRANSACTION LOAD
==============================================================*/

/* Expected result: 15,000 Transaction records */
SELECT COUNT(*) AS transaction_rows
FROM staging.[transaction];


/* Review sample cleaned records */
SELECT TOP 20 *
FROM staging.[transaction];


/* Reconcile transactions by transaction type */
SELECT
    transaction_type,
    COUNT(*) AS total_transactions
FROM staging.[transaction]
GROUP BY transaction_type
ORDER BY transaction_type;


/* Check amount signs and zero-value transactions */
SELECT
    transaction_type,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN amount > 0 THEN 1 ELSE 0 END) AS positive_amounts,
    SUM(CASE WHEN amount < 0 THEN 1 ELSE 0 END) AS negative_amounts,
    SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END) AS zero_amounts
FROM staging.[transaction]
GROUP BY transaction_type
ORDER BY transaction_type;

GO


/*==============================================================
  EXPECTED VALIDATION

  Total Transaction records:
  - 15,000

  Transaction types:
  - Debit Order   = 1,548
  - Deposit       = 2,986
  - EFT Payment   = 2,252
  - Fee           =   755
  - POS Purchase  = 3,740
  - Refund        =   767
  - Withdrawal    = 2,952

  Data-quality checks:
  - 26 zero-value transactions are intentionally retained.
  - Source amount signs are preserved.
  - Orphan transaction accounts are intentionally retained.
  - Re-running this load should not increase the row count beyond
    15,000 for the supplied dataset.
==============================================================*/