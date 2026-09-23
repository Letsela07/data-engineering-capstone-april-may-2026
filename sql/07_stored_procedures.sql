USE [Customer360_DW]
GO

/****** Object:  StoredProcedure [dbo].[usp_load_staging]    Script Date: 2026/09/20 20:41:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE  [dbo].[usp_load_staging]
AS
BEGIN
    SET NOCOUNT ON;


    /*==========================================================
      1. LOAD PRODUCT ENROLLMENT
    ==========================================================*/

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

        TRY_CONVERT(DATE, TRIM(s.date_of_birth), 23),

        s.gender,

        CASE
            WHEN TRIM(s.province) = 'KwaZulu Natal'
                THEN 'KwaZulu-Natal'
            ELSE TRIM(s.province)
        END,

        s.city,

        TRY_CONVERT(DATE, TRIM(s.signup_date), 23),
        TRY_CONVERT(DATE, TRIM(s.event_date), 23),

        s.account_number,
        s.product_type,
        s.account_status,

        TRY_CONVERT(
            DECIMAL(18,2),
            NULLIF(TRIM(s.credit_limit), '')
        ),

        TRY_CONVERT(
            DECIMAL(18,2),
            NULLIF(TRIM(s.loan_amount), '')
        ),

        TRY_CONVERT(
            DECIMAL(18,2),
            NULLIF(TRIM(s.account_balance), '')
        )

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

    WHERE s.event_type = 'Product Enrollment'

    AND NOT EXISTS
    (
        SELECT 1
        FROM staging.product_enrollment AS p
        WHERE p.client_number = s.client_number
          AND p.account_number = s.account_number
    );


    /*==========================================================
      2. LOAD CRM INTERACTIONS
    ==========================================================*/

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
        END,

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
        END,

        TRY_CONVERT(DATE, TRIM(s.date_of_birth), 23),

        s.gender,

        CASE
            WHEN TRIM(s.province) = 'KwaZulu Natal'
                THEN 'KwaZulu-Natal'
            ELSE TRIM(s.province)
        END,

        s.city,

        TRY_CONVERT(DATE, TRIM(s.signup_date), 23),
        TRY_CONVERT(DATE, TRIM(s.event_date), 23),

        s.channel,
        s.interaction_type,

        CASE
            WHEN s.resolved_flag IS NULL
                 OR TRIM(s.resolved_flag) = ''
                THEN 'Unknown'
            ELSE TRIM(s.resolved_flag)
        END

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
          AND c.event_date =
              TRY_CONVERT(DATE, TRIM(s.event_date), 23)
          AND c.channel = s.channel
          AND c.interaction_type = s.interaction_type
    );


    /*==========================================================
      3. LOAD TRANSACTIONS
    ==========================================================*/

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
        END,

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
        END,

        TRY_CONVERT(DATE, TRIM(s.date_of_birth), 23),

        s.gender,

        CASE
            WHEN TRIM(s.province) = 'KwaZulu Natal'
                THEN 'KwaZulu-Natal'
            ELSE TRIM(s.province)
        END,

        s.city,

        TRY_CONVERT(DATE, TRIM(s.signup_date), 23),
        TRY_CONVERT(DATE, TRIM(s.event_date), 23),

        s.account_number,
        s.product_type,
        s.transaction_type,
        s.channel,

        TRY_CONVERT(
            DECIMAL(18,2),
            NULLIF(TRIM(s.amount), '')
        )

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

END;
GO


USE [Customer360_DW]
GO

/****** Object:  StoredProcedure [dbo].[usp_load_dimensions]    Script Date: 2026/09/20 20:42:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE  [dbo].[usp_load_dimensions]
AS
BEGIN
    SET NOCOUNT ON;


    /*==========================================================
      1. LOAD DIM_CLIENT
      Business key: client_number
      SCD strategy: Type 1
    ==========================================================*/

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

    /* SCD Type 1 - update existing clients */
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


    /* Insert new clients */
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


    /*==========================================================
      2. LOAD DIM_PRODUCT
      Business key: product_type
    ==========================================================*/

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


    /*==========================================================
      3. LOAD DIM_ACCOUNT
      Business key: account_number
      SCD strategy: Type 1
    ==========================================================*/

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


    /*==========================================================
      4. LOAD DIM_DATE

      Grain:
      One row per calendar date.

      Range:
      Every date between earliest and latest event_date.

      date_key:
      YYYYMMDD
    ==========================================================*/

    DECLARE @min_date DATE;
    DECLARE @max_date DATE;

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
        CONVERT(INT, CONVERT(CHAR(8), full_date, 112)),
        full_date,
        DAY(full_date),
        MONTH(full_date),
        DATENAME(MONTH, full_date),
        DATEPART(QUARTER, full_date),
        YEAR(full_date)
    FROM date_range AS d
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.dim_date AS target
        WHERE target.full_date = d.full_date
    )
    OPTION (MAXRECURSION 0);

END;
GO


USE [Customer360_DW]
GO

/****** Object:  StoredProcedure [dbo].[usp_load_facts]    Script Date: 2026/09/20 20:43:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE  [dbo].[usp_load_facts]
AS
BEGIN
    SET NOCOUNT ON;

    /*==========================================================
      1. LOAD FACT_PRODUCT_ENROLLMENT

      Grain:
      One row per client account/product enrollment event
    ==========================================================*/

    INSERT INTO dw.fact_product_enrollment
    (
        client_key,
        date_key,
        account_key,
        product_key,
        credit_limit,
        loan_amount,
        account_balance
    )
    SELECT
        dc.client_key,
        dd.date_key,
        da.account_key,
        dp.product_key,
        pe.credit_limit,
        pe.loan_amount,
        pe.account_balance
    FROM staging.product_enrollment AS pe

    INNER JOIN dw.dim_client AS dc
        ON pe.client_number = dc.client_number

    INNER JOIN dw.dim_date AS dd
        ON pe.event_date = dd.full_date

    INNER JOIN dw.dim_account AS da
        ON pe.account_number = da.account_number

    INNER JOIN dw.dim_product AS dp
        ON pe.product_type = dp.product_type

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.fact_product_enrollment AS f
        WHERE f.client_key = dc.client_key
          AND f.date_key = dd.date_key
          AND f.account_key = da.account_key
          AND f.product_key = dp.product_key
    );


    /*==========================================================
      2. LOAD FACT_INTERACTION

      Grain:
      One row per CRM interaction between client and bank
    ==========================================================*/

    INSERT INTO dw.fact_interaction
    (
        client_key,
        date_key,
        interaction_type,
        channel,
        resolved_flag
    )
    SELECT
        dc.client_key,
        dd.date_key,
        ci.interaction_type,
        ci.channel,
        ci.resolved_flag
    FROM staging.crm_interaction AS ci

    INNER JOIN dw.dim_client AS dc
        ON ci.client_number = dc.client_number

    INNER JOIN dw.dim_date AS dd
        ON ci.event_date = dd.full_date

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.fact_interaction AS f
        WHERE f.client_key = dc.client_key
          AND f.date_key = dd.date_key
          AND f.interaction_type = ci.interaction_type
          AND f.channel = ci.channel
    );


    /*==========================================================
      3. LOAD FACT_TRANSACTION

      Grain:
      One row per transaction event
    ==========================================================*/

    INSERT INTO dw.fact_transaction
    (
        client_key,
        date_key,
        account_key,
        product_key,
        transaction_type,
        channel,
        amount,
        orphan_account_flag,
        zero_amount_flag
    )
    SELECT
        dc.client_key,
        dd.date_key,
        da.account_key,
        dp.product_key,
        t.transaction_type,
        t.channel,
        t.amount,

        /* Account/client combination has no enrollment record */
        CASE
            WHEN NOT EXISTS
            (
                SELECT 1
                FROM staging.product_enrollment AS pe
                WHERE pe.client_number = t.client_number
                  AND pe.account_number = t.account_number
            )
            THEN 1
            ELSE 0
        END AS orphan_account_flag,

        /* Preserve zero-value transactions but flag them */
        CASE
            WHEN t.amount = 0 THEN 1
            ELSE 0
        END AS zero_amount_flag

    FROM staging.[transaction] AS t

    INNER JOIN dw.dim_client AS dc
        ON t.client_number = dc.client_number

    INNER JOIN dw.dim_date AS dd
        ON t.event_date = dd.full_date

    INNER JOIN dw.dim_account AS da
        ON t.account_number = da.account_number

    INNER JOIN dw.dim_product AS dp
        ON t.product_type = dp.product_type

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.fact_transaction AS f
        WHERE f.client_key = dc.client_key
          AND f.date_key = dd.date_key
          AND f.account_key = da.account_key
          AND f.product_key = dp.product_key
          AND f.transaction_type = t.transaction_type
          AND f.channel = t.channel
          AND f.amount = t.amount
    );

END;
GO





