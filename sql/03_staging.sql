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
       - Remove spaces, dashes, brackets and +
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

    TRY_CONVERT(DATE, TRIM(s.date_of_birth), 23) AS date_of_birth,

    s.gender,

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
                    REPLACE(
                        REPLACE(TRIM(s.mobile_number), ' ', ''),
                        '-', ''
                    ),
                    '(', ''
                ),
                ')', ''
            ),
            '+', ''
        ) AS mobile_number_clean
) AS cleaned

WHERE s.event_type = 'Product Enrollment'

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

SELECT COUNT(*) AS product_enrollment_rows
FROM staging.product_enrollment;

SELECT TOP 20 *
FROM staging.product_enrollment;

SELECT
    product_type,
    COUNT(*) AS total_accounts
FROM staging.product_enrollment
GROUP BY product_type
ORDER BY product_type;

GO


/*==============================================================
  4. CRM INTERACTION STAGING TABLE
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
  - Dataset-specific existing-record check:

    client_number + event_date + channel + interaction_type

  Limitation:
  - The source does not provide a unique interaction ID or
    event timestamp.
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

    CASE
        WHEN s.email IS NULL OR TRIM(s.email) = ''
            THEN NULL
        ELSE LOWER(REPLACE(TRIM(s.email), ' ', ''))
    END AS email,

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

    TRY_CONVERT(DATE, TRIM(s.date_of_birth), 23) AS date_of_birth,

    s.gender,

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

    CASE
        WHEN s.resolved_flag IS NULL
             OR TRIM(s.resolved_flag) = ''
            THEN 'Unknown'
        ELSE TRIM(s.resolved_flag)
    END AS resolved_flag

FROM source.customer_activity_extract AS s

CROSS APPLY
(
    SELECT
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(TRIM(s.mobile_number), ' ', ''),
                        '-', ''
                    ),
                    '(', ''
                ),
                ')', ''
            ),
            '+', ''
        ) AS mobile_number_clean
) AS cleaned

WHERE s.event_type = 'CRM Interaction'

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

SELECT COUNT(*) AS crm_interaction_rows
FROM staging.crm_interaction;

SELECT TOP 20 *
FROM staging.crm_interaction;

SELECT
    resolved_flag,
    COUNT(*) AS total_interactions
FROM staging.crm_interaction
GROUP BY resolved_flag
ORDER BY resolved_flag;

SELECT
    channel,
    COUNT(*) AS total_interactions
FROM staging.crm_interaction
GROUP BY channel
ORDER BY channel;

GO


/*==============================================================
  7. TRANSACTION STAGING TABLE
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
  - Dataset-specific existing-record check:

    client_number
    + account_number
    + event_date
    + transaction_type
    + channel
    + amount

  Data-quality decisions:
  - Source amount signs are preserved.
  - Zero-value transactions are retained.
  - Orphan transaction accounts are retained.
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

    CASE
        WHEN s.email IS NULL OR TRIM(s.email) = ''
            THEN NULL
        ELSE LOWER(REPLACE(TRIM(s.email), ' ', ''))
    END AS email,

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

    TRY_CONVERT(DATE, TRIM(s.date_of_birth), 23) AS date_of_birth,

    s.gender,

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

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(TRIM(s.amount), '')
    ) AS amount

FROM source.customer_activity_extract AS s

CROSS APPLY
(
    SELECT
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(TRIM(s.mobile_number), ' ', ''),
                        '-', ''
                    ),
                    '(', ''
                ),
                ')', ''
            ),
            '+', ''
        ) AS mobile_number_clean
) AS cleaned

WHERE s.event_type = 'Transaction'

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

SELECT COUNT(*) AS transaction_rows
FROM staging.[transaction];

SELECT TOP 20 *
FROM staging.[transaction];

SELECT
    transaction_type,
    COUNT(*) AS total_transactions
FROM staging.[transaction]
GROUP BY transaction_type
ORDER BY transaction_type;

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