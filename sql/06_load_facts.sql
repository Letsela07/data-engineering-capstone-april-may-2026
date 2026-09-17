USE Customer360_DW;
GO

/*==============================================================
  FILE: 06_load_facts.sql

  1. LOAD FACT_PRODUCT_ENROLLMENT

  GRAIN:
  One row per client account/product enrollment event.

  Expected rows: 2,000
==============================================================*/

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
GO


/*==============================================================
  VALIDATION
==============================================================*/

SELECT COUNT(*) AS enrollment_fact_count
FROM dw.fact_product_enrollment;

SELECT TOP 10 *
FROM dw.fact_product_enrollment
ORDER BY enrollment_key;
GO


/*==============================================================
  2. LOAD FACT_INTERACTION

  GRAIN:
  One row per CRM interaction between a client and the bank.

  Expected rows: 4,500
==============================================================*/

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
    crm.interaction_type,
    crm.channel,
    crm.resolved_flag
FROM staging.crm_interaction AS crm

INNER JOIN dw.dim_client AS dc
    ON crm.client_number = dc.client_number

INNER JOIN dw.dim_date AS dd
    ON crm.event_date = dd.full_date

WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.fact_interaction AS f
    WHERE f.client_key = dc.client_key
      AND f.date_key = dd.date_key
      AND f.interaction_type = crm.interaction_type
      AND f.channel = crm.channel
      AND f.resolved_flag = crm.resolved_flag
);
GO


/*==============================================================
  VALIDATION
==============================================================*/

SELECT COUNT(*) AS interaction_fact_count
FROM dw.fact_interaction;

SELECT TOP 10 *
FROM dw.fact_interaction
ORDER BY interaction_key;
GO


/*==============================================================
  3. LOAD FACT_TRANSACTION

  GRAIN:
  One row per transaction event.

  Expected rows: 15,000

  DATA QUALITY:
  orphan_account_flag = 1 when the client/account combination
  has no matching Product Enrollment record.

  zero_amount_flag = 1 when amount = 0.
==============================================================*/

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

    /* Orphan account flag */
    CASE
        WHEN pe.account_number IS NULL THEN 1
        ELSE 0
    END AS orphan_account_flag,

    /* Zero amount flag */
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

LEFT JOIN staging.product_enrollment AS pe
    ON t.client_number = pe.client_number
   AND t.account_number = pe.account_number

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
GO


/*==============================================================
  VALIDATION
==============================================================*/

SELECT COUNT(*) AS transaction_fact_count
FROM dw.fact_transaction;


/* Check orphan transactions */
SELECT
    SUM(CASE WHEN orphan_account_flag = 1 THEN 1 ELSE 0 END)
        AS orphan_transaction_count
FROM dw.fact_transaction;


/* Check zero-value transactions */
SELECT
    SUM(CASE WHEN zero_amount_flag = 1 THEN 1 ELSE 0 END)
        AS zero_amount_transaction_count
FROM dw.fact_transaction;


/* Final fact reconciliation */
SELECT
    (SELECT COUNT(*) FROM dw.fact_product_enrollment)
        AS product_enrollment_rows,

    (SELECT COUNT(*) FROM dw.fact_interaction)
        AS crm_interaction_rows,

    (SELECT COUNT(*) FROM dw.fact_transaction)
        AS transaction_rows,

    (SELECT COUNT(*) FROM dw.fact_product_enrollment)
    + (SELECT COUNT(*) FROM dw.fact_interaction)
    + (SELECT COUNT(*) FROM dw.fact_transaction)
        AS total_fact_rows;
GO