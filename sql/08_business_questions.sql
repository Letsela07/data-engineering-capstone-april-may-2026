USE Customer360_DW;
GO

/* =========================================================
   QUESTION 1
   How many customers are there per province and what share
   of the total customer base does each province represent?
   ========================================================= */

SELECT
    province,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),
        2
    ) AS percentage_share
FROM dw.dim_client
GROUP BY province
ORDER BY customer_count DESC;


/*
FINDING:
The bank has 1,484 customers. Eastern Cape has the largest
share with 191 customers (12.87%), while Limpopo has the
smallest share with 137 customers (9.23%).

Customer distribution is relatively balanced across the
nine provinces.
*/


/* =========================================================
   QUESTION 2
   What is the age distribution of customers?
   Choose and justify appropriate age bands.
   ========================================================= */

WITH customer_ages AS
(
    SELECT
        client_key,
        DATEDIFF(YEAR, date_of_birth, '2026-02-21')
        -
        CASE
            WHEN DATEADD(
                YEAR,
                DATEDIFF(YEAR, date_of_birth, '2026-02-21'),
                date_of_birth
            ) > '2026-02-21'
            THEN 1
            ELSE 0
        END AS age
    FROM dw.dim_client
),

age_bands AS
(
    SELECT
        client_key,
        CASE
            WHEN age BETWEEN 18 AND 24 THEN '18-24'
            WHEN age BETWEEN 25 AND 34 THEN '25-34'
            WHEN age BETWEEN 35 AND 44 THEN '35-44'
            WHEN age BETWEEN 45 AND 54 THEN '45-54'
            WHEN age BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+'
        END AS age_band
    FROM customer_ages
)

SELECT
    age_band,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),
        2
    ) AS percentage_share
FROM age_bands
GROUP BY age_band
ORDER BY
    CASE age_band
        WHEN '18-24' THEN 1
        WHEN '25-34' THEN 2
        WHEN '35-44' THEN 3
        WHEN '45-54' THEN 4
        WHEN '55-64' THEN 5
        WHEN '65+' THEN 6
    END;


/*
METHOD:
Customer age was calculated as of 21 February 2026, the
latest date represented in the dataset.

The age bands separate the youngest adult customers and then
use approximately ten-year intervals, with customers aged
65 and above grouped together.

FINDING:
The largest age group is customers aged 65+, with 306
customers (20.62%), followed by customers aged 25-34,
with 275 customers (18.53%).

The smallest group is 18-24, with 162 customers (10.92%).
Overall, customers are distributed across all age groups,
with a slightly larger representation among customers aged
65 and above.
*/


/* =========================================================
   QUESTION 3
   How many customers signed up per month over the last
   two years? Is the trend increasing, flat or decreasing?
   ========================================================= */

SELECT
    YEAR(signup_date) AS signup_year,
    MONTH(signup_date) AS signup_month,
    COUNT(*) AS customer_signups
FROM dw.dim_client
WHERE signup_date >= DATEADD(YEAR, -2, '2026-02-21')
  AND signup_date <= '2026-02-21'
GROUP BY
    YEAR(signup_date),
    MONTH(signup_date)
ORDER BY
    signup_year,
    signup_month;


/*
FINDING:
Monthly customer signups fluctuated throughout the two-year
period rather than showing a consistent upward trend.

Most complete months recorded approximately 30 to 49 new
customers. Signups were lower toward the end of the available
signup period, reaching 21 in June 2025.

No customer signups were recorded after June 2025, although
the overall dataset extends to February 2026.

February 2024 is a partial month because the two-year analysis
window begins on 21 February 2024.
*/


/* =========================================================
   QUESTION 4
   Which customer records appear to have data-quality
   problems? Define the problem and provide a count.
   ========================================================= */

-- Customers with missing email addresses
SELECT
    COUNT(*) AS customers_missing_email
FROM dw.dim_client
WHERE email IS NULL
   OR LTRIM(RTRIM(email)) = '';


-- Customers with missing mobile numbers
SELECT
    COUNT(*) AS customers_missing_mobile
FROM dw.dim_client
WHERE mobile_number IS NULL
   OR LTRIM(RTRIM(mobile_number)) = '';


-- Customers with at least one missing contact method
SELECT
    COUNT(*) AS customers_with_missing_contact
FROM dw.dim_client
WHERE email IS NULL
   OR LTRIM(RTRIM(email)) = ''
   OR mobile_number IS NULL
   OR LTRIM(RTRIM(mobile_number)) = '';


-- Check for duplicate client identities
SELECT
    client_number,
    COUNT(*) AS duplicate_count
FROM dw.dim_client
GROUP BY client_number
HAVING COUNT(*) > 1;


/*
DEFINITION:
A customer record was considered a data-quality concern when
the email address or mobile number was missing, or when the
same client_number appeared more than once.

FINDING:
Of the 1,484 customers, 432 (29.11%) have at least one
missing contact method.

This includes 29 customers with missing email addresses and
412 customers with missing mobile numbers.

No duplicate client_number records were identified.
*/


/* =========================================================
   QUESTION 5
   How many customers hold each product type, and how many
   customers hold more than one product?
   ========================================================= */

-- Customers per product type
SELECT
    p.product_type,
    COUNT(DISTINCT f.client_key) AS customer_count
FROM dw.fact_product_enrollment AS f
JOIN dw.dim_product AS p
    ON f.product_key = p.product_key
GROUP BY p.product_type
ORDER BY customer_count DESC;


-- Customers holding more than one product type
SELECT
    COUNT(*) AS customers_with_multiple_products
FROM
(
    SELECT
        f.client_key
    FROM dw.fact_product_enrollment AS f
    GROUP BY f.client_key
    HAVING COUNT(DISTINCT f.product_key) > 1
) AS multi_product_customers;


/*
FINDING:
Savings is the most widely held product, with 678 customers,
followed closely by Credit Cards with 673 customers and
Personal Loans with 649 customers.

A total of 593 customers hold more than one product type,
indicating substantial cross-holding across the bank's
customer base.
*/


/* =========================================================
   QUESTION 6
   What is the total and average account balance by
   product type?
   ========================================================= */

SELECT
    p.product_type,
    COUNT(*) AS account_count,
    CAST(SUM(f.account_balance) AS DECIMAL(18,2))
        AS total_balance,
    CAST(AVG(f.account_balance) AS DECIMAL(18,2))
        AS average_balance
FROM dw.fact_product_enrollment AS f
JOIN dw.dim_product AS p
    ON f.product_key = p.product_key
GROUP BY p.product_type
ORDER BY total_balance DESC;


/*
FINDING:
Savings accounts have the highest total balance at
R26,100,944.34 and also have the highest average balance
at R38,496.97 per account.

Personal Loans have a total balance of R15,446,189.02 and
an average balance of R23,799.98.

Credit Cards have the lowest total and average balances at
R7,218,723.33 and R10,726.19 respectively.
*/


/* =========================================================
   QUESTION 7
   How many customers have a Savings product but no
   Credit Card? Produce a cross-sell customer list.
   ========================================================= */

WITH customer_products AS
(
    SELECT
        f.client_key,
        MAX(CASE
            WHEN p.product_type = 'Savings' THEN 1
            ELSE 0
        END) AS has_savings,
        MAX(CASE
            WHEN p.product_type = 'Credit Card' THEN 1
            ELSE 0
        END) AS has_credit_card
    FROM dw.fact_product_enrollment AS f
    JOIN dw.dim_product AS p
        ON f.product_key = p.product_key
    GROUP BY f.client_key
)

SELECT
    c.client_number,
    c.first_name,
    c.last_name
FROM customer_products AS cp
JOIN dw.dim_client AS c
    ON cp.client_key = c.client_key
WHERE cp.has_savings = 1
  AND cp.has_credit_card = 0
ORDER BY c.client_number;


/*
FINDING:
There are 382 customers who hold a Savings product but do
not have a Credit Card.

These customers represent a potential cross-selling segment
for Credit Card products. The query produces the individual
customer list using client_number, first_name and last_name
for further analysis.
*/


/* =========================================================
   QUESTION 8
   What proportion of Credit Card accounts are within
   90% of their credit limit?
   ========================================================= */

SELECT
    COUNT(*) AS total_credit_card_accounts,

    SUM(
        CASE
            WHEN f.account_balance >= f.credit_limit * 0.90
            THEN 1
            ELSE 0
        END
    ) AS accounts_within_90_percent,

    CAST(
        SUM(
            CASE
                WHEN f.account_balance >= f.credit_limit * 0.90
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS percentage_within_90_percent

FROM dw.fact_product_enrollment AS f
JOIN dw.dim_product AS p
    ON f.product_key = p.product_key
WHERE p.product_type = 'Credit Card'
  AND f.credit_limit IS NOT NULL
  AND f.credit_limit > 0;


/*
DEFINITION:
A Credit Card account was considered within 90% of its
credit limit when its account balance was equal to or
greater than 90% of the recorded credit limit.

FINDING:
Of the 673 Credit Card accounts with a valid credit limit,
68 accounts (10.10%) have an account balance equal to or
greater than 90% of their credit limit.

This means approximately one in ten Credit Card accounts
is operating close to its available credit limit.
*/


/* =========================================================
   QUESTION 9
   What is the total transaction value by month and
   transaction type? Are there any seasonal patterns?
   ========================================================= */

-- Monthly transaction value by transaction type
SELECT
    d.year_number,
    d.month_number,
    d.month_name,
    f.transaction_type,
    COUNT(*) AS transaction_count,
    CAST(SUM(f.amount) AS DECIMAL(18,2))
        AS total_transaction_value
FROM dw.fact_transaction AS f
JOIN dw.dim_date AS d
    ON f.date_key = d.date_key
GROUP BY
    d.year_number,
    d.month_number,
    d.month_name,
    f.transaction_type
ORDER BY
    d.year_number,
    d.month_number,
    f.transaction_type;


-- Monthly summary used to examine the overall pattern
SELECT
    d.month_number,
    d.month_name,
    COUNT(*) AS transaction_count,
    CAST(SUM(f.amount) AS DECIMAL(18,2))
        AS net_transaction_value,
    CAST(SUM(ABS(f.amount)) AS DECIMAL(18,2))
        AS total_activity_value
FROM dw.fact_transaction AS f
JOIN dw.dim_date AS d
    ON f.date_key = d.date_key
GROUP BY
    d.month_number,
    d.month_name
ORDER BY d.month_number;


/*
FINDING:
Transaction activity increases substantially from April
through August, with August recording 3,460 transactions
and approximately R13.86 million in total absolute
transaction value.

August also recorded the largest negative net transaction
value at approximately -R2.83 million.

This pattern should not automatically be interpreted as
seasonality because calendar months may have unequal data
coverage. A recurring pattern across comparable years would
be required to establish seasonality more confidently.
*/


/* =========================================================
   QUESTION 10
   Which channel has the most transactions and which has
   the highest total transaction value? Explain if they
   differ.
   ========================================================= */

SELECT
    f.channel,
    COUNT(*) AS transaction_count,
    CAST(SUM(f.amount) AS DECIMAL(18,2))
        AS net_transaction_value,
    CAST(SUM(ABS(f.amount)) AS DECIMAL(18,2))
        AS total_activity_value
FROM dw.fact_transaction AS f
GROUP BY f.channel
ORDER BY transaction_count DESC;


/*
METHOD:
Absolute transaction value was used to compare total
transaction activity because positive and negative values
represent transaction direction. Using only the net value
could cause incoming and outgoing transactions to cancel
each other out.

FINDING:
POS is the most frequently used transaction channel, with
4,122 transactions.

POS also has the highest total activity value at
approximately R16.55 million. Therefore, the channel with
the highest transaction volume is also the channel through
which the greatest absolute transaction value moved.

POS has a negative net transaction value of approximately
-R13.42 million, which is consistent with the predominantly
outgoing nature of POS transactions in this dataset.
*/


/* =========================================================
   QUESTION 11
   Define an active customer using transaction or interaction
   recency. How many customers are active versus not active
   as of the latest date in the dataset?
   ========================================================= */

WITH all_activity AS
(
    SELECT
        t.client_key,
        d.full_date AS activity_date
    FROM dw.fact_transaction AS t
    JOIN dw.dim_date AS d
        ON t.date_key = d.date_key

    UNION ALL

    SELECT
        i.client_key,
        d.full_date AS activity_date
    FROM dw.fact_interaction AS i
    JOIN dw.dim_date AS d
        ON i.date_key = d.date_key
),

last_activity AS
(
    SELECT
        client_key,
        MAX(activity_date) AS last_activity_date
    FROM all_activity
    GROUP BY client_key
)

SELECT
    CASE
        WHEN la.last_activity_date >=
             DATEADD(DAY, -90, '2026-02-21')
        THEN 'Active'
        ELSE 'Not Active'
    END AS activity_status,

    COUNT(*) AS customer_count

FROM dw.dim_client AS c
LEFT JOIN last_activity AS la
    ON c.client_key = la.client_key

GROUP BY
    CASE
        WHEN la.last_activity_date >=
             DATEADD(DAY, -90, '2026-02-21')
        THEN 'Active'
        ELSE 'Not Active'
    END;


/*
DEFINITION:
A customer was defined as active if they had at least one
transaction or CRM interaction within the 90 days preceding
21 February 2026, the latest date represented in the dataset.

FINDING:
Using this definition, 22 customers are Active and 1,462
customers are Not Active.

This means approximately 1.48% of the 1,484 customers meet
the 90-day activity threshold.

The low active rate should be interpreted in the context of
the available event dates rather than assumed to represent
the bank's current real-world customer activity.
*/


/* =========================================================
   QUESTION 12
   Who are the top 20 customers by total transaction value
   in the last 12 months? Use the latest transaction date
   as the reference point.
   ========================================================= */

DECLARE @latest_transaction_date DATE;

SELECT
    @latest_transaction_date = MAX(d.full_date)
FROM dw.fact_transaction AS f
JOIN dw.dim_date AS d
    ON f.date_key = d.date_key;


SELECT TOP 20
    c.client_number,
    c.first_name,
    c.last_name,
    COUNT(*) AS transaction_count,

    CAST(
        SUM(ABS(f.amount))
        AS DECIMAL(18,2)
    ) AS total_transaction_value

FROM dw.fact_transaction AS f

JOIN dw.dim_client AS c
    ON f.client_key = c.client_key

JOIN dw.dim_date AS d
    ON f.date_key = d.date_key

WHERE d.full_date >=
      DATEADD(YEAR, -1, @latest_transaction_date)

  AND d.full_date <=
      @latest_transaction_date

GROUP BY
    c.client_number,
    c.first_name,
    c.last_name

ORDER BY total_transaction_value DESC;


/*
METHOD:
The latest transaction date in the warehouse is
16 January 2026.

The analysis therefore uses the 12-month period preceding
this date. Absolute transaction values were used so that
incoming and outgoing transactions do not cancel each other
out when measuring customer transaction activity.

FINDING:
CL01495, Michelle Steyn, recorded the highest transaction
activity at R129,162.49 across 26 transactions.

She was followed by CL01093, Ayesha Pillay, at R119,604.46
and CL00155, Ruan Smith, at R119,429.71.
*/


/* =========================================================
   QUESTION 13
   What is the average number of CRM interactions per
   customer, split by interaction type?
   ========================================================= */

SELECT
    interaction_type,
    COUNT(*) AS total_interactions,
    COUNT(DISTINCT client_key) AS customers_with_interaction,

    CAST(
        COUNT(*) * 1.0 /
        COUNT(DISTINCT client_key)
        AS DECIMAL(10,2)
    ) AS average_interactions_per_customer

FROM dw.fact_interaction
GROUP BY interaction_type
ORDER BY average_interactions_per_customer DESC;


/*
METHOD:
The average for each interaction type is calculated using
customers who had that particular type of interaction.

FINDING:
Queries are the most frequent CRM interaction type, with
2,028 interactions across 1,125 customers, averaging
1.80 interactions per participating customer.

Product Applications and Complaints both average 1.31
interactions per customer. Feedback averages 1.16 and
Fraud Reports average 1.10.

Customers who raise queries therefore tend to have more
repeat interactions than customers using the other
interaction types in this dataset.
*/


/* =========================================================
   QUESTION 14
   Which CRM channel is most frequently used for complaints,
   and how does this compare with other interaction types?
   ========================================================= */

SELECT
    interaction_type,
    channel,
    COUNT(*) AS interaction_count
FROM dw.fact_interaction
GROUP BY
    interaction_type,
    channel
ORDER BY
    interaction_type,
    interaction_count DESC;


/*
FINDING:
Call is the most frequently used channel for Complaints,
with 195 interactions, followed by Branch with 186 and
Chat with 182.

Channel preference differs across the other interaction
types. WhatsApp leads for Feedback with 107 interactions
and Fraud Reports with 50. Email leads for Product
Applications with 193 interactions, while Chat leads for
Queries with 435.

This indicates that the preferred CRM channel varies
depending on the purpose of the customer interaction.
*/


/* =========================================================
   QUESTION 15
   What is the CRM resolution rate by channel?
   Which channel has the lowest rate, and could the result
   be affected by small sample sizes?
   ========================================================= */

SELECT
    channel,
    COUNT(*) AS total_interactions,

    SUM(
        CASE
            WHEN resolved_flag = 'Y' THEN 1
            ELSE 0
        END
    ) AS resolved_interactions,

    CAST(
        SUM(
            CASE
                WHEN resolved_flag = 'Y' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS resolution_rate

FROM dw.fact_interaction
GROUP BY channel
ORDER BY resolution_rate DESC;


/*
FINDING:
Chat has the highest resolution rate at 77.19%, with
704 of 912 interactions resolved.

It is followed by Branch at 76.27% and Email at 76.02%.

WhatsApp has the lowest resolution rate at 74.58%
(663 of 889 interactions), closely followed by Call
at 74.77%.

The channel sample sizes are relatively similar, ranging
from 888 to 912 interactions. Therefore, the lower
WhatsApp rate is unlikely to be explained simply by a much
smaller sample size.

However, the differences between channels are relatively
small and should not be interpreted as evidence that one
channel inherently performs better without further analysis.
*/


/* =========================================================
   QUESTION 16
   Create customer value tiers based on transaction activity.
   Explain the method and show the customer count and total
   transaction value for each tier.
   ========================================================= */

WITH customer_value AS
(
    SELECT
        client_key,
        SUM(ABS(amount)) AS total_transaction_value
    FROM dw.fact_transaction
    GROUP BY client_key
),

value_tiers AS
(
    SELECT
        client_key,
        total_transaction_value,
        NTILE(3) OVER (
            ORDER BY total_transaction_value DESC
        ) AS tier_number
    FROM customer_value
)

SELECT
    CASE
        WHEN tier_number = 1 THEN 'High Value'
        WHEN tier_number = 2 THEN 'Medium Value'
        WHEN tier_number = 3 THEN 'Low Value'
    END AS value_tier,

    COUNT(*) AS customer_count,

    CAST(
        SUM(total_transaction_value)
        AS DECIMAL(18,2)
    ) AS total_transaction_value,

    CAST(
        AVG(total_transaction_value)
        AS DECIMAL(18,2)
    ) AS average_customer_value

FROM value_tiers
GROUP BY tier_number
ORDER BY tier_number;


/*
METHOD:
Customer value was measured using total absolute transaction
value. Absolute values were used so that incoming and outgoing
transactions did not cancel each other out.

NTILE(3) was used to divide customers with transaction
activity into three approximately equal-sized groups based
on the observed distribution rather than arbitrary monetary
thresholds.

FINDING:
The High Value tier contains 418 customers and generates
R32,935,904.23 in transaction activity, with an average
customer value of R78,794.03.

The Medium Value tier contains 418 customers and generates
R18,057,403.97, with an average of R43,199.53.

The Low Value tier contains 417 customers and generates
R9,088,642.49, with an average of R21,795.31.

The tiers cover 1,253 customers with recorded transaction
activity.
*/


/* =========================================================
   QUESTION 17
   Segment customers into New, Active, At Risk and Dormant
   using signup date and activity recency. Explain the
   thresholds and show the customer counts.
   ========================================================= */

WITH customer_activity AS
(
    SELECT
        client_key,
        MAX(activity_date) AS last_activity_date
    FROM
    (
        SELECT
            t.client_key,
            d.full_date AS activity_date
        FROM dw.fact_transaction AS t
        JOIN dw.dim_date AS d
            ON t.date_key = d.date_key

        UNION ALL

        SELECT
            i.client_key,
            d.full_date AS activity_date
        FROM dw.fact_interaction AS i
        JOIN dw.dim_date AS d
            ON i.date_key = d.date_key
    ) AS all_activity
    GROUP BY client_key
),

lifecycle AS
(
    SELECT
        c.client_key,

        CASE
            WHEN c.signup_date >=
                 DATEADD(DAY, -90, '2026-02-21')
                THEN 'New'

            WHEN ca.last_activity_date >=
                 DATEADD(DAY, -90, '2026-02-21')
                THEN 'Active'

            WHEN ca.last_activity_date >=
                 DATEADD(DAY, -180, '2026-02-21')
                THEN 'At Risk'

            ELSE 'Dormant'
        END AS lifecycle_segment

    FROM dw.dim_client AS c
    LEFT JOIN customer_activity AS ca
        ON c.client_key = ca.client_key
)

SELECT
    lifecycle_segment,
    COUNT(*) AS customer_count
FROM lifecycle
GROUP BY lifecycle_segment
ORDER BY
    CASE lifecycle_segment
        WHEN 'New' THEN 1
        WHEN 'Active' THEN 2
        WHEN 'At Risk' THEN 3
        WHEN 'Dormant' THEN 4
    END;


/*
METHOD:
21 February 2026 was used as the dataset reference date.

New:
Signed up within the previous 90 days.

Active:
Not New, but had a transaction or CRM interaction within
the previous 90 days.

At Risk:
Latest activity was between 91 and 180 days ago.

Dormant:
Latest activity was more than 180 days ago or there was
no recorded transaction or CRM activity.

FINDING:
There are 22 Active customers, 413 At Risk customers and
1,049 Dormant customers.

No customers qualified as New because no customer signup
occurred within the final 90 days of the dataset.

The segments account for all 1,484 customers.
*/


/* =========================================================
   QUESTION 18
   Is there a relationship between CRM interaction activity
   and transaction value? Use a simple grouped comparison.
   ========================================================= */

WITH crm_activity AS
(
    SELECT
        client_key,
        COUNT(*) AS interaction_count
    FROM dw.fact_interaction
    GROUP BY client_key
),

transaction_activity AS
(
    SELECT
        client_key,
        SUM(ABS(amount)) AS transaction_value
    FROM dw.fact_transaction
    GROUP BY client_key
),

customer_summary AS
(
    SELECT
        c.client_key,
        ISNULL(crm.interaction_count, 0) AS interaction_count,
        ISNULL(t.transaction_value, 0) AS transaction_value
    FROM dw.dim_client AS c
    LEFT JOIN crm_activity AS crm
        ON c.client_key = crm.client_key
    LEFT JOIN transaction_activity AS t
        ON c.client_key = t.client_key
),

interaction_groups AS
(
    SELECT
        *,
        CASE
            WHEN interaction_count = 0
                THEN 'No interactions'
            WHEN interaction_count BETWEEN 1 AND 2
                THEN 'Low (1-2)'
            WHEN interaction_count BETWEEN 3 AND 5
                THEN 'Medium (3-5)'
            ELSE 'High (6+)'
        END AS interaction_group
    FROM customer_summary
)

SELECT
    interaction_group,
    COUNT(*) AS customer_count,

    CAST(
        AVG(transaction_value)
        AS DECIMAL(18,2)
    ) AS average_transaction_value,

    CAST(
        SUM(transaction_value)
        AS DECIMAL(18,2)
    ) AS total_transaction_value

FROM interaction_groups
GROUP BY interaction_group
ORDER BY
    CASE interaction_group
        WHEN 'No interactions' THEN 1
        WHEN 'Low (1-2)' THEN 2
        WHEN 'Medium (3-5)' THEN 3
        WHEN 'High (6+)' THEN 4
    END;


/*
FINDING:
Customers with no CRM interactions have the highest average
transaction activity at R45,658.87.

Customers with 1-2 interactions average R40,692.07, those
with 3-5 interactions average R40,507.23, and customers
with 6 or more interactions average R36,955.62.

In this dataset, higher CRM interaction frequency does not
correspond with higher average transaction value. The grouped
comparison shows a modest decline in average transaction
activity as interaction frequency increases.

This is a descriptive relationship and does not establish
that CRM interactions cause lower transaction activity.

The No interactions group contains only 53 customers,
compared with 566 in the Low group, 750 in the Medium group
and 115 in the High group, so the unequal group sizes should
also be considered when interpreting the averages.
*/


/* =========================================================
   QUESTION 19 - STRETCH
   What proportion of customers active in month N are also
   active in month N+1?
   ========================================================= */

WITH monthly_active AS
(
    SELECT DISTINCT
        t.client_key,

        DATEFROMPARTS(
            d.year_number,
            d.month_number,
            1
        ) AS activity_month

    FROM dw.fact_transaction AS t
    JOIN dw.dim_date AS d
        ON t.date_key = d.date_key
),

monthly_retention AS
(
    SELECT
        current_month.activity_month,

        COUNT(DISTINCT current_month.client_key)
            AS active_customers,

        COUNT(DISTINCT next_month.client_key)
            AS retained_customers

    FROM monthly_active AS current_month

    LEFT JOIN monthly_active AS next_month
        ON current_month.client_key = next_month.client_key
        AND next_month.activity_month =
            DATEADD(MONTH, 1, current_month.activity_month)

    GROUP BY current_month.activity_month
)

SELECT
    activity_month,
    active_customers,
    retained_customers,

    CAST(
        retained_customers * 100.0 /
        NULLIF(active_customers, 0)
        AS DECIMAL(5,2)
    ) AS retention_rate

FROM monthly_retention
ORDER BY activity_month;


/*
DEFINITION:
A customer was considered active in a month when they had
at least one transaction during that month.

A retained customer is a customer who was active in month N
and was also active in the immediately following month.

FINDING:
Month-over-month transaction retention generally increased
during the more populated portion of the dataset.

Retention reached 50.83% in December 2024, 59.19% in
March 2025, 71.13% in June 2025 and 75.34% in July 2025.

July 2025 had 746 active customers, of whom 562 were also
active in August.

A sharp decline occurs after August 2025. August had 799
active customers but only 6 were active in September,
producing a retention rate of 0.75%.

Monthly transaction activity also becomes very sparse after
August 2025. The sharp decline should therefore be interpreted
in the context of limited transaction data coverage rather
than automatically treated as a genuine collapse in customer
retention.
*/


/* =========================================================
   QUESTION 20 - STRETCH
   Identify unusual account transaction patterns or spikes.
   What additional information would be required to
   investigate potential fraud?
   ========================================================= */

WITH customer_stats AS
(
    SELECT
        client_key,
        AVG(ABS(amount)) AS average_transaction_value
    FROM dw.fact_transaction
    GROUP BY client_key
)

SELECT TOP 20
    c.client_number,
    a.account_number,
    d.full_date AS transaction_date,
    t.transaction_type,
    t.channel,
    t.amount,

    CAST(
        cs.average_transaction_value
        AS DECIMAL(18,2)
    ) AS customer_average,

    CAST(
        ABS(t.amount) /
        NULLIF(cs.average_transaction_value, 0)
        AS DECIMAL(10,2)
    ) AS times_customer_average

FROM dw.fact_transaction AS t

JOIN customer_stats AS cs
    ON t.client_key = cs.client_key

JOIN dw.dim_client AS c
    ON t.client_key = c.client_key

JOIN dw.dim_account AS a
    ON t.account_key = a.account_key

JOIN dw.dim_date AS d
    ON t.date_key = d.date_key

WHERE ABS(t.amount) >=
      (cs.average_transaction_value * 3)

ORDER BY times_customer_average DESC;


/*
METHOD:
A transaction was flagged as unusual when its absolute value
was at least three times the customer's average absolute
transaction value.

This is an anomaly-detection rule only. A flagged transaction
should not automatically be classified as fraudulent.

FINDING:
Five transactions met the three-times-average threshold.

The strongest relative spike was customer CL00005. A
R7,391.14 Debit Order was 4.02 times the customer's average
transaction value of R1,840.01.

The other flagged transactions ranged from approximately
3.07 to 3.56 times their respective customer averages.

These transactions represent unusual activity that could
justify further investigation, but they do not provide
evidence of fraud on their own.

ADDITIONAL DATA REQUIRED:
A fraud investigation would benefit from transaction
timestamps, merchant or beneficiary details, transaction
location, device and IP information, authentication method,
card-present or card-not-present indicators, failed
authentication attempts, historical customer behaviour and
information showing whether the customer authorised or
disputed the transaction.
*/