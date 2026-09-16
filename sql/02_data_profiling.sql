/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: client_number
   ============================================================ */


/* ------------------------------------------------------------
   1. Check for NULL or blank client numbers
   ------------------------------------------------------------ */

SELECT client_number
FROM source.customer_activity_extract
WHERE client_number IS NULL
   OR TRIM(client_number) = '';

/*
Finding:
No NULL or blank client_number values were found.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   2. Check for leading or trailing whitespace
   ------------------------------------------------------------ */

SELECT client_number
FROM source.customer_activity_extract
WHERE TRIM(client_number) <> client_number;

/*
Finding:
No leading or trailing whitespace was found in client_number.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   3. Count distinct client numbers
   ------------------------------------------------------------ */

SELECT COUNT(DISTINCT client_number) AS total_distinct_clients
FROM source.customer_activity_extract;

/*
Finding:
The dataset contains 1,484 distinct client numbers
across 21,500 event records.
*/


/* ------------------------------------------------------------
   4. Check how many times each client appears
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS total,
    client_number
FROM source.customer_activity_extract
GROUP BY client_number;

/*
Finding:
Client numbers appear more than once in the dataset.

This is expected because one client can have multiple events,
such as product enrollments, CRM interactions and transactions.

Repeated client_number values are therefore not automatically
considered duplicate records.
*/


/* ------------------------------------------------------------
   5. Check whether repeated clients have inconsistent signup dates
   ------------------------------------------------------------ */

SELECT
    COUNT(DISTINCT signup_date) AS number_of_signup_dates,
    client_number
FROM source.customer_activity_extract
GROUP BY client_number
HAVING COUNT(DISTINCT signup_date) > 1;

/*
Finding:
No client_number is associated with more than one distinct
signup_date.

Result: 0 rows.

This provides additional evidence that repeated client_number
values consistently represent the same client.
*/


/* ============================================================
   OVERALL FINDING: client_number

   - No NULL or blank values were found.
   - No leading or trailing whitespace was found.
   - 1,484 distinct clients exist across 21,500 event records.
   - Repeated client numbers are expected because clients can
     have multiple events.
   - No client_number was associated with multiple signup dates.
   - No obvious data-quality issue was identified for this column.
   ============================================================ */


   /* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: first_name
   ============================================================ */


/* ------------------------------------------------------------
   1. Check for NULL or blank first names
   ------------------------------------------------------------ */

SELECT first_name
FROM source.customer_activity_extract
WHERE first_name IS NULL
   OR TRIM(first_name) = '';

/*
Finding:
No NULL or blank first_name values were found.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   2. Check for leading or trailing whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT first_name
FROM source.customer_activity_extract
WHERE TRIM(first_name) <> first_name;

/*
Finding:
No leading or trailing whitespace was found.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   3. Check whether one client has multiple first names
   ------------------------------------------------------------ */

SELECT
    client_number,
    COUNT(DISTINCT first_name) AS number_of_first_names
FROM source.customer_activity_extract
GROUP BY client_number
HAVING COUNT(DISTINCT first_name) > 1;

/*
Finding:
No client_number was associated with more than one
distinct first_name.

Result: 0 rows.
*/


/* ------------------------------------------------------------
   4. Check casing using case-sensitive comparison
   ------------------------------------------------------------ */

SELECT DISTINCT first_name
FROM source.customer_activity_extract
WHERE first_name COLLATE Latin1_General_CS_AS <>
      (
          UPPER(LEFT(first_name, 1))
          + LOWER(SUBSTRING(first_name, 2, LEN(first_name)))
      ) COLLATE Latin1_General_CS_AS;

/*
Finding:
No casing exceptions were identified.

Result: 0 rows.
*/


/* ============================================================
   OVERALL FINDING: first_name

   - No NULL or blank values were found.
   - No leading or trailing whitespace was found.
   - No conflicting first names were identified per client.
   - No casing issues were identified.
   - No transformation is required.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: last_name
   ============================================================ */


/* ------------------------------------------------------------
   1. Check for NULL or blank last names
   ------------------------------------------------------------ */

SELECT last_name
FROM source.customer_activity_extract
WHERE last_name IS NULL
   OR TRIM(last_name) = '';

/*
Finding:
No NULL or blank last_name values were found.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   2. Check for leading or trailing whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT last_name
FROM source.customer_activity_extract
WHERE TRIM(last_name) <> last_name;

/*
Finding:
No leading or trailing whitespace was found.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   3. Check whether one client has multiple last names
   ------------------------------------------------------------ */

SELECT
    client_number,
    COUNT(DISTINCT last_name) AS number_of_last_names
FROM source.customer_activity_extract
GROUP BY client_number
HAVING COUNT(DISTINCT last_name) > 1;

/*
Finding:
No client_number was associated with more than one
distinct last_name.

Result: 0 rows.
*/


/* ------------------------------------------------------------
   4. Check casing using case-sensitive comparison
   ------------------------------------------------------------ */

SELECT DISTINCT last_name
FROM source.customer_activity_extract
WHERE last_name COLLATE Latin1_General_CS_AS <>
      (
          UPPER(LEFT(last_name, 1))
          + LOWER(SUBSTRING(last_name, 2, LEN(last_name)))
      ) COLLATE Latin1_General_CS_AS;

/*
Finding:
Two values were identified by the simple casing rule:

Van der Merwe
De Villiers

These are valid surname formats and are not considered
data-quality errors.

No transformation is required.
*/


/* ============================================================
   OVERALL FINDING: last_name

   - No NULL or blank values were found.
   - No leading or trailing whitespace was found.
   - No conflicting last names were identified per client.
   - Van der Merwe and De Villiers were reviewed and determined
     to be valid surname formats.
   - No transformation is required.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: email
   ============================================================ */


/* ------------------------------------------------------------
   1. Check for NULL or blank email values
   ------------------------------------------------------------ */

SELECT email
FROM source.customer_activity_extract
WHERE email IS NULL
   OR TRIM(email) = '';

/*
Finding:
354 rows contain missing email values.

Missing email is allowed according to the source data
specification.
*/


/* ------------------------------------------------------------
   2. Check for leading or trailing whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT email
FROM source.customer_activity_extract
WHERE TRIM(email) <> email;

/*
Finding:
Email values with leading/trailing whitespace were identified.

These values will be trimmed in staging.
*/


/* ------------------------------------------------------------
   3. Check populated emails without @
   ------------------------------------------------------------ */

SELECT DISTINCT email
FROM source.customer_activity_extract
WHERE email IS NOT NULL
  AND TRIM(email) <> ''
  AND email NOT LIKE '%@%';

/*
Finding:
No populated email values without @ were identified.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   4. Check email beginning with @
   ------------------------------------------------------------ */

SELECT DISTINCT email
FROM source.customer_activity_extract
WHERE email LIKE '@%';

/*
Finding:
No email values beginning with @ were identified.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   5. Check email ending with @
   ------------------------------------------------------------ */

SELECT DISTINCT email
FROM source.customer_activity_extract
WHERE email LIKE '%@';

/*
Finding:
No email values ending with @ were identified.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   6. Check for missing dot after @
   ------------------------------------------------------------ */

SELECT DISTINCT email
FROM source.customer_activity_extract
WHERE email IS NOT NULL
  AND TRIM(email) <> ''
  AND email LIKE '%@%'
  AND CHARINDEX('.', email, CHARINDEX('@', email)) = 0;

/*
Finding:
No populated email values were found without a dot
after the @ symbol.

Result: 0 rows.
*/


/* ------------------------------------------------------------
   7. Check whether one client has multiple populated emails
   ------------------------------------------------------------ */

SELECT
    client_number,
    COUNT(DISTINCT email) AS number_of_emails
FROM source.customer_activity_extract
GROUP BY client_number
HAVING COUNT(DISTINCT email) > 1;

/*
Finding:
No client_number was associated with multiple distinct
email addresses.

Result: 0 rows.
*/


/* ============================================================
   OVERALL FINDING: email

   - 354 missing email values were identified.
   - Missing email is allowed by the source specification.
   - Whitespace inconsistencies were identified.
   - Inconsistent casing was observed.
   - Basic populated email-format checks passed.
   - No client had multiple distinct populated email addresses.

   Staging decision:
   - Preserve missing email values as NULL.
   - TRIM populated emails.
   - Convert populated emails to lowercase for consistency.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: mobile_number
   ============================================================ */


/* ------------------------------------------------------------
   1. Check for NULL or blank mobile numbers
   ------------------------------------------------------------ */

SELECT mobile_number
FROM source.customer_activity_extract
WHERE mobile_number IS NULL
   OR TRIM(mobile_number) = '';

/*
Finding:
Missing mobile_number values are present.

The exact count can be added when the profiling results
are reviewed again.
*/


/* ------------------------------------------------------------
   2. Check for leading or trailing whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT mobile_number
FROM source.customer_activity_extract
WHERE TRIM(mobile_number) <> mobile_number;


/* ------------------------------------------------------------
   3. Check numbers that are not 10 characters
   ------------------------------------------------------------ */

SELECT DISTINCT mobile_number
FROM source.customer_activity_extract
WHERE mobile_number IS NOT NULL
  AND TRIM(mobile_number) <> ''
  AND LEN(TRIM(mobile_number)) <> 10;


/* ------------------------------------------------------------
   4. Check numbers that do not begin with 0
   ------------------------------------------------------------ */

SELECT DISTINCT mobile_number
FROM source.customer_activity_extract
WHERE mobile_number IS NOT NULL
  AND TRIM(mobile_number) <> ''
  AND TRIM(mobile_number) NOT LIKE '0%';


/* ------------------------------------------------------------
   5. Check values containing non-digit characters
   ------------------------------------------------------------ */

SELECT DISTINCT mobile_number
FROM source.customer_activity_extract
WHERE mobile_number IS NOT NULL
  AND TRIM(mobile_number) <> ''
  AND TRIM(mobile_number) LIKE '%[^0-9]%';


/* ------------------------------------------------------------
   6. Check whether one client has multiple mobile numbers
   ------------------------------------------------------------ */

SELECT
    client_number,
    COUNT(DISTINCT mobile_number) AS number_of_mobile_numbers
FROM source.customer_activity_extract
GROUP BY client_number
HAVING COUNT(DISTINCT mobile_number) > 1;

/*
Finding:
No client_number was associated with more than one
distinct populated mobile_number.

Result: 0 rows.
*/


/* ============================================================
   OVERALL FINDING: mobile_number

   - Missing values are present.
   - Multiple formatting patterns were identified.
   - Examples include +27 format, spaces, dashes and
     varying lengths.
   - No client had multiple distinct populated mobile numbers.

   Staging decision:
   - Standardize populated mobile numbers toward a
     10-digit local format beginning with 0.
   - Remove known formatting characters such as spaces
     and dashes.
   - Convert valid +27-format numbers to local 0-format.
   - Validate the value after standardization.
   - Handling of values that remain invalid will be
     finalized during staging design.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: date_of_birth
   ============================================================ */


/* ------------------------------------------------------------
   1. NULL or blank
   ------------------------------------------------------------ */

SELECT date_of_birth
FROM source.customer_activity_extract
WHERE date_of_birth IS NULL
   OR TRIM(date_of_birth) = '';


/* ------------------------------------------------------------
   2. Whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT date_of_birth
FROM source.customer_activity_extract
WHERE TRIM(date_of_birth) <> date_of_birth;


/* ------------------------------------------------------------
   3. Invalid YYYY-MM-DD dates
   ------------------------------------------------------------ */

SELECT DISTINCT date_of_birth
FROM source.customer_activity_extract
WHERE date_of_birth IS NOT NULL
  AND TRIM(date_of_birth) <> ''
  AND TRY_CONVERT(DATE, TRIM(date_of_birth), 23) IS NULL;


/* ------------------------------------------------------------
   4. Future dates of birth
   ------------------------------------------------------------ */

SELECT DISTINCT date_of_birth
FROM source.customer_activity_extract
WHERE TRY_CONVERT(DATE, TRIM(date_of_birth), 23)
      > CAST(GETDATE() AS DATE);


/* ------------------------------------------------------------
   5. Multiple dates of birth per client
   ------------------------------------------------------------ */

SELECT
    client_number,
    COUNT(DISTINCT date_of_birth) AS number_of_birth_dates
FROM source.customer_activity_extract
GROUP BY client_number
HAVING COUNT(DISTINCT date_of_birth) > 1;


/*
Finding:
All checks returned 0 rows.
*/


/* ============================================================
   OVERALL FINDING: date_of_birth

   - No NULL or blank values were found.
   - No whitespace issues were found.
   - All values successfully convert using YYYY-MM-DD.
   - No future dates were identified.
   - No client had conflicting dates of birth.
   - No transformation is required.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: gender
   ============================================================ */


/* ------------------------------------------------------------
   1. Check unexpected gender values
   ------------------------------------------------------------ */

SELECT DISTINCT gender
FROM source.customer_activity_extract
WHERE gender IS NOT NULL
  AND TRIM(gender) <> ''
  AND gender NOT IN ('F', 'M', 'U');


/* ------------------------------------------------------------
   2. Check whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT gender
FROM source.customer_activity_extract
WHERE TRIM(gender) <> gender;


/* ------------------------------------------------------------
   3. Check conflicting gender values per client
   ------------------------------------------------------------ */

SELECT
    client_number,
    COUNT(DISTINCT gender) AS number_of_gender_values
FROM source.customer_activity_extract
WHERE gender IS NOT NULL
  AND TRIM(gender) <> ''
GROUP BY client_number
HAVING COUNT(DISTINCT gender) > 1;


/*
Finding:
All checks returned 0 rows.

Expected values are:
F = Female
M = Male
U = Unknown
Blank = no value supplied
*/


/* ============================================================
   OVERALL FINDING: gender

   - Only expected values were identified.
   - No whitespace issues were identified.
   - No client had conflicting populated gender values.
   - Blank gender values are allowed.
   - No transformation is currently required.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: province
   ============================================================ */


/* ------------------------------------------------------------
   1. Review province values
   ------------------------------------------------------------ */

SELECT
    province,
    COUNT(*) AS occurrences
FROM source.customer_activity_extract
GROUP BY province
ORDER BY province;


/* ------------------------------------------------------------
   2. Check whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT province
FROM source.customer_activity_extract
WHERE TRIM(province) <> province;

/*
Finding:
No leading or trailing whitespace was identified.
Result: 0 rows.
*/


/* ------------------------------------------------------------
   3. Check against standardized province values
   using case-sensitive comparison
   ------------------------------------------------------------ */

SELECT DISTINCT province
FROM source.customer_activity_extract
WHERE province COLLATE Latin1_General_CS_AS NOT IN
(
    'Eastern Cape',
    'Free State',
    'Gauteng',
    'KwaZulu-Natal',
    'Limpopo',
    'Mpumalanga',
    'Northern Cape',
    'North West',
    'Western Cape'
);

/*
Finding:
KwaZulu Natal was identified as a formatting inconsistency.

2,779 rows contain KwaZulu Natal.

The value represents a valid South African province but
does not follow the chosen standardized spelling.
*/


/* ============================================================
   OVERALL FINDING: province

   - All values represent valid South African provinces.
   - No leading or trailing whitespace was identified.
   - 2,779 rows contain KwaZulu Natal rather than
     KwaZulu-Natal.

   Staging decision:
   Standardize KwaZulu Natal to KwaZulu-Natal.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: city
   ============================================================ */


/* ------------------------------------------------------------
   1. NULL or blank
   ------------------------------------------------------------ */

SELECT city
FROM source.customer_activity_extract
WHERE city IS NULL
   OR TRIM(city) = '';


/* ------------------------------------------------------------
   2. Whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT city
FROM source.customer_activity_extract
WHERE TRIM(city) <> city;


/* ------------------------------------------------------------
   3. Review distinct city values
   ------------------------------------------------------------ */

SELECT
    city,
    COUNT(*) AS occurrences
FROM source.customer_activity_extract
GROUP BY city
ORDER BY city;


/* ------------------------------------------------------------
   4. Check conflicting cities per client
   ------------------------------------------------------------ */

SELECT
    client_number,
    COUNT(DISTINCT city) AS number_of_cities
FROM source.customer_activity_extract
GROUP BY client_number
HAVING COUNT(DISTINCT city) > 1;


/*
Finding:
Checks 1, 2 and 4 returned 0 rows.

Distinct city values were manually reviewed and appeared
valid and consistently formatted.
*/


/* ============================================================
   OVERALL FINDING: city

   - No NULL or blank values were found.
   - No leading or trailing whitespace was found.
   - No client was associated with multiple cities.
   - Distinct city values were reviewed and appeared
     consistently formatted.
   - No transformation is required.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: signup_date
   ============================================================ */


/* ------------------------------------------------------------
   1. NULL or blank
   ------------------------------------------------------------ */

SELECT signup_date
FROM source.customer_activity_extract
WHERE signup_date IS NULL
   OR TRIM(signup_date) = '';


/* ------------------------------------------------------------
   2. Whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT signup_date
FROM source.customer_activity_extract
WHERE TRIM(signup_date) <> signup_date;


/* ------------------------------------------------------------
   3. Invalid YYYY-MM-DD dates
   ------------------------------------------------------------ */

SELECT DISTINCT signup_date
FROM source.customer_activity_extract
WHERE signup_date IS NOT NULL
  AND TRIM(signup_date) <> ''
  AND TRY_CONVERT(DATE, TRIM(signup_date), 23) IS NULL;


/* ------------------------------------------------------------
   4. Future signup dates
   ------------------------------------------------------------ */

SELECT DISTINCT signup_date
FROM source.customer_activity_extract
WHERE TRY_CONVERT(DATE, TRIM(signup_date), 23)
      > CAST(GETDATE() AS DATE);


/* ------------------------------------------------------------
   5. Multiple signup dates per client
   ------------------------------------------------------------ */

SELECT
    client_number,
    COUNT(DISTINCT signup_date) AS number_of_signup_dates
FROM source.customer_activity_extract
GROUP BY client_number
HAVING COUNT(DISTINCT signup_date) > 1;


/* ------------------------------------------------------------
   6. Signup date before date of birth
   ------------------------------------------------------------ */

SELECT
    client_number,
    date_of_birth,
    signup_date
FROM source.customer_activity_extract
WHERE TRY_CONVERT(DATE, signup_date, 23)
      < TRY_CONVERT(DATE, date_of_birth, 23);


/*
Finding:
All checks returned 0 rows.
*/


/* ============================================================
   OVERALL FINDING: signup_date

   - No NULL or blank values were found.
   - No whitespace issues were found.
   - All values successfully convert using YYYY-MM-DD.
   - No future signup dates were identified.
   - No conflicting signup dates were identified per client.
   - No signup date occurs before the client's date of birth.
   - No transformation is required.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: event_type
   ============================================================ */


/* ------------------------------------------------------------
   1. NULL or blank
   ------------------------------------------------------------ */

SELECT event_type
FROM source.customer_activity_extract
WHERE event_type IS NULL
   OR TRIM(event_type) = '';


/* ------------------------------------------------------------
   2. Whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT event_type
FROM source.customer_activity_extract
WHERE TRIM(event_type) <> event_type;


/* ------------------------------------------------------------
   3. Unexpected values
   ------------------------------------------------------------ */

SELECT DISTINCT event_type
FROM source.customer_activity_extract
WHERE event_type COLLATE Latin1_General_CS_AS NOT IN
(
    'Product Enrollment',
    'CRM Interaction',
    'Transaction'
);


/* ------------------------------------------------------------
   4. Count each event type
   ------------------------------------------------------------ */

SELECT
    event_type,
    COUNT(*) AS number_of_events
FROM source.customer_activity_extract
GROUP BY event_type
ORDER BY event_type;

/*
Finding:

CRM Interaction      = 4,500
Product Enrollment   = 2,000
Transaction          = 15,000

Total                = 21,500

The first three checks returned 0 rows.
*/


/* ============================================================
   OVERALL FINDING: event_type

   - No NULL or blank values were found.
   - No whitespace issues were identified.
   - No unexpected event types were found.
   - The dataset contains:
       4,500 CRM Interaction events
       2,000 Product Enrollment events
       15,000 Transaction events
   - Event counts reconcile to the 21,500 source rows.
   ============================================================ */



/* ============================================================
   CUSTOMER 360 DATA PROFILING
   Column: event_date
   ============================================================ */


/* ------------------------------------------------------------
   1. NULL or blank
   ------------------------------------------------------------ */

SELECT event_date
FROM source.customer_activity_extract
WHERE event_date IS NULL
   OR TRIM(event_date) = '';


/* ------------------------------------------------------------
   2. Whitespace
   ------------------------------------------------------------ */

SELECT DISTINCT event_date
FROM source.customer_activity_extract
WHERE TRIM(event_date) <> event_date;


/* ------------------------------------------------------------
   3. Invalid YYYY-MM-DD dates
   ------------------------------------------------------------ */

SELECT DISTINCT event_date
FROM source.customer_activity_extract
WHERE event_date IS NOT NULL
  AND TRIM(event_date) <> ''
  AND TRY_CONVERT(DATE, TRIM(event_date), 23) IS NULL;


/* ------------------------------------------------------------
   4. Future event dates
   ------------------------------------------------------------ */

SELECT DISTINCT event_date
FROM source.customer_activity_extract
WHERE TRY_CONVERT(DATE, TRIM(event_date), 23)
      > CAST(GETDATE() AS DATE);


/* ------------------------------------------------------------
   5. Event date before signup date
   ------------------------------------------------------------ */

SELECT
    client_number,
    event_type,
    signup_date,
    event_date
FROM source.customer_activity_extract
WHERE TRY_CONVERT(DATE, event_date, 23)
      < TRY_CONVERT(DATE, signup_date, 23);


/*
Finding:
All checks returned 0 rows.
*/


/* ============================================================
   OVERALL FINDING: event_date

   - No NULL or blank values were found.
   - No whitespace issues were identified.
   - All values successfully convert using YYYY-MM-DD.
   - No future event dates were identified.
   - No event occurs before the corresponding client's
     signup_date.
   - No transformation is required.
   ============================================================ */



/* ============================================================
   DATASET-LEVEL DUPLICATE PROFILING
   ============================================================ */


/* ------------------------------------------------------------
   1. Confirm total source rows
   ------------------------------------------------------------ */

SELECT COUNT(*) AS total_rows
FROM source.customer_activity_extract;

/*
Finding:
The correctly loaded source contains 21,500 rows.
*/


/* ------------------------------------------------------------
   2. Count completely unique rows
   ------------------------------------------------------------ */

SELECT COUNT(*) AS unique_rows
FROM
(
    SELECT DISTINCT *
    FROM source.customer_activity_extract
) AS x;

/*
Finding:
21,499 completely unique rows were identified.

Since the source contains 21,500 total rows, this indicates
that one exact duplicate record exists in the original
source data.

During development, the source table was accidentally loaded
twice. This was detected because all row patterns appeared
twice. The source table was subsequently truncated and reloaded
once before profiling continued.

The current source table therefore correctly contains
21,500 rows.
*/


/* ============================================================
   PRODUCT ENROLLMENT PROFILING
   Column: account_number
   ============================================================ */

/* ------------------------------------------------------------
   1. Check for missing account numbers where expected

   account_number is expected for:
   - Product Enrollment
   - Transaction
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_account_numbers
FROM source.customer_activity_extract
WHERE event_type IN ('Product Enrollment', 'Transaction')
  AND (
        account_number IS NULL
        OR TRIM(account_number) = ''
      );

/*
Finding:
0 records were found.

All Product Enrollment and Transaction records contain an
account_number.
*/


/* ------------------------------------------------------------
   2. Check whether CRM Interaction records contain
      account numbers
   ------------------------------------------------------------ */
SELECT COUNT(*) AS crm_with_account_number
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND account_number IS NOT NULL
  AND TRIM(account_number) <> '';

/*
Finding:
0 records were found.

CRM Interaction records do not contain account numbers,
which is consistent with the source data dictionary.
*/


/* ------------------------------------------------------------
   3. Check for leading or trailing whitespace
   ------------------------------------------------------------ */
SELECT COUNT(*) AS account_number_whitespace
FROM source.customer_activity_extract
WHERE account_number IS NOT NULL
  AND account_number <> TRIM(account_number);

/*
Finding:
0 records were found.

No leading or trailing whitespace was identified.
*/


/* ------------------------------------------------------------
   4. Count distinct account numbers
   ------------------------------------------------------------ */
SELECT COUNT(DISTINCT account_number) AS distinct_account_numbers
FROM source.customer_activity_extract
WHERE account_number IS NOT NULL
  AND TRIM(account_number) <> '';

/*
Finding:
2,010 distinct account numbers were identified.
*/


/* ------------------------------------------------------------
   5. Check whether the same account number belongs to
      multiple clients
   ------------------------------------------------------------ */
SELECT
    account_number,
    COUNT(DISTINCT client_number) AS client_count
FROM source.customer_activity_extract
WHERE account_number IS NOT NULL
  AND TRIM(account_number) <> ''
GROUP BY account_number
HAVING COUNT(DISTINCT client_number) > 1;

/*
Finding:
0 records were returned.

No account number is associated with multiple clients.
*/


/* ------------------------------------------------------------
   6. Check Transaction accounts against Product Enrollment

   A Transaction account should have a matching Product
   Enrollment record for the same client and account.
   ------------------------------------------------------------ */
SELECT DISTINCT
    t.client_number,
    t.account_number
FROM source.customer_activity_extract AS t
WHERE t.event_type = 'Transaction'
  AND NOT EXISTS
  (
      SELECT 1
      FROM source.customer_activity_extract AS p
      WHERE p.event_type = 'Product Enrollment'
        AND p.client_number = t.client_number
        AND p.account_number = t.account_number
  )
ORDER BY t.client_number;

/*
Finding:
10 client/account combinations could not be matched to a
Product Enrollment record.

These are treated as orphan account relationships within
the supplied dataset.

Staging decision:
- Retain the affected Transaction records.
- Do not invent Product Enrollment records.
- Flag the unresolved account relationship so that it can
  be identified during downstream analysis.
*/


/* ------------------------------------------------------------
   7. Check account_number to product_type consistency
   ------------------------------------------------------------ */
SELECT
    account_number,
    COUNT(DISTINCT product_type) AS product_type_count
FROM source.customer_activity_extract
WHERE account_number IS NOT NULL
  AND TRIM(account_number) <> ''
GROUP BY account_number
HAVING COUNT(DISTINCT product_type) > 1;

/*
Finding:
0 records were returned.

Each account_number is consistently associated with one
product_type.
*/


/* ============================================================
   OVERALL FINDING: account_number

   - account_number is populated where expected.
   - CRM Interaction records correctly contain no account number.
   - No whitespace issues were identified.
   - 2,010 distinct account numbers were identified.
   - No account number belongs to multiple clients.
   - Account-to-product relationships are consistent.
   - 10 Transaction client/account combinations do not have a
     matching Product Enrollment record.

   Staging decision:
   Retain the orphan Transaction records and flag the unresolved
   account relationship rather than deleting or fabricating data.
   ============================================================ */


   /* ============================================================
   PRODUCT ENROLLMENT PROFILING
   Column: product_type
   ============================================================ */

/* ------------------------------------------------------------
   1. Check for missing product_type where expected

   product_type is expected for:
   - Product Enrollment
   - Transaction
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_product_type
FROM source.customer_activity_extract
WHERE event_type IN ('Product Enrollment', 'Transaction')
  AND (
        product_type IS NULL
        OR TRIM(product_type) = ''
      );

/*
Finding:
0 records were found.

All Product Enrollment and Transaction records contain
a product_type.
*/


/* ------------------------------------------------------------
   2. Check whether CRM Interaction records contain
      product_type
   ------------------------------------------------------------ */
SELECT COUNT(*) AS crm_with_product_type
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND product_type IS NOT NULL
  AND TRIM(product_type) <> '';

/*
Finding:
0 records were found.

CRM Interaction records do not contain product_type,
which is consistent with the source data dictionary.
*/


/* ------------------------------------------------------------
   3. Check for leading or trailing whitespace
   ------------------------------------------------------------ */
SELECT COUNT(*) AS product_type_whitespace
FROM source.customer_activity_extract
WHERE product_type IS NOT NULL
  AND product_type <> TRIM(product_type);

/*
Finding:
0 records were found.

No leading or trailing whitespace was identified.
*/


/* ------------------------------------------------------------
   4. Check for unexpected product_type values
   ------------------------------------------------------------ */
SELECT DISTINCT product_type
FROM source.customer_activity_extract
WHERE event_type IN ('Product Enrollment', 'Transaction')
  AND product_type COLLATE Latin1_General_CS_AS
      NOT IN ('Savings', 'Credit Card', 'Personal Loan');

/*
Finding:
0 unexpected values were found.

All populated product_type values match the expected
values and casing.
*/


/* ------------------------------------------------------------
   5. Review product_type distribution
   ------------------------------------------------------------ */
SELECT
    product_type,
    COUNT(*) AS record_count
FROM source.customer_activity_extract
WHERE event_type IN ('Product Enrollment', 'Transaction')
GROUP BY product_type
ORDER BY product_type;

/*
Finding:

Credit Card      5,765
Personal Loan    5,481
Savings          5,754

Total:          17,000

The total reconciles with:
- 2,000 Product Enrollment records
- 15,000 Transaction records
*/


/* ============================================================
   OVERALL FINDING: product_type

   - product_type is populated for all Product Enrollment
     and Transaction records.
   - CRM Interaction records correctly contain no product_type.
   - No whitespace issues were identified.
   - No unexpected values or casing inconsistencies were found.
   - All 17,000 relevant records contain one of the expected
     product types: Savings, Credit Card or Personal Loan.

   Staging decision:
   No data-cleaning transformation is required for product_type.
   The existing values will be retained.
   ============================================================ */


   /* ============================================================
   PRODUCT ENROLLMENT PROFILING
   Column: account_status
   ============================================================ */

/* ------------------------------------------------------------
   1. Check for missing account_status on Product Enrollment
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_account_status
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND (
        account_status IS NULL
        OR TRIM(account_status) = ''
      );

/*
Finding:
0 records were found.

All Product Enrollment records contain an account_status.
*/


/* ------------------------------------------------------------
   2. Check whether account_status is populated outside
      Product Enrollment
   ------------------------------------------------------------ */
SELECT COUNT(*) AS account_status_outside_enrollment
FROM source.customer_activity_extract
WHERE event_type <> 'Product Enrollment'
  AND account_status IS NOT NULL
  AND TRIM(account_status) <> '';

/*
Finding:
0 records were found.

account_status is populated only for Product Enrollment
records, as expected.
*/


/* ------------------------------------------------------------
   3. Check for leading or trailing whitespace
   ------------------------------------------------------------ */
SELECT COUNT(*) AS account_status_whitespace
FROM source.customer_activity_extract
WHERE account_status IS NOT NULL
  AND account_status <> TRIM(account_status);

/*
Finding:
0 records were found.

No leading or trailing whitespace was identified.
*/


/* ------------------------------------------------------------
   4. Check for unexpected account_status values
   ------------------------------------------------------------ */
SELECT DISTINCT account_status
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND account_status COLLATE Latin1_General_CS_AS
      NOT IN ('Active', 'Closed', 'Suspended');

/*
Finding:
0 unexpected values were found.

All values match the expected account statuses and casing.
*/


/* ------------------------------------------------------------
   5. Review account_status distribution
   ------------------------------------------------------------ */
SELECT
    account_status,
    COUNT(*) AS record_count
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
GROUP BY account_status
ORDER BY account_status;

/*
Finding:

Active       1,585
Closed         312
Suspended      103

Total:       2,000

The total reconciles with the 2,000 Product Enrollment
records in the source dataset.
*/


/* ============================================================
   OVERALL FINDING: account_status

   - account_status is populated for all Product Enrollment
     records.
   - It is not populated outside Product Enrollment.
   - No whitespace issues were identified.
   - No unexpected values or casing inconsistencies were found.
   - Distribution:
       Active     = 1,585
       Closed     =   312
       Suspended  =   103

   Staging decision:
   No cleaning transformation is required for account_status.
   The existing values will be retained.
   ============================================================ */


   /* ============================================================
   PRODUCT ENROLLMENT PROFILING
   Column: credit_limit
   ============================================================ */

/* ------------------------------------------------------------
   1. Check for missing credit_limit on Credit Card enrollments
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_credit_limit
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND product_type = 'Credit Card'
  AND (
        credit_limit IS NULL
        OR TRIM(credit_limit) = ''
      );

/*
Finding:
0 records were found.

All Credit Card Product Enrollment records contain
a credit_limit.
*/


/* ------------------------------------------------------------
   2. Check whether credit_limit is populated for products
      other than Credit Card
   ------------------------------------------------------------ */
SELECT COUNT(*) AS credit_limit_other_products
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND product_type <> 'Credit Card'
  AND credit_limit IS NOT NULL
  AND TRIM(credit_limit) <> '';

/*
Finding:
0 records were found.

credit_limit is populated only for Credit Card
Product Enrollment records.
*/


/* ------------------------------------------------------------
   3. Check for non-numeric credit_limit values
   ------------------------------------------------------------ */
SELECT credit_limit
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND credit_limit IS NOT NULL
  AND TRIM(credit_limit) <> ''
  AND TRY_CONVERT(DECIMAL(18,2), credit_limit) IS NULL;

/*
Finding:
0 invalid numeric values were found.

All populated credit_limit values can be converted
to DECIMAL(18,2).
*/


/* ------------------------------------------------------------
   4. Check for zero or negative credit limits
   ------------------------------------------------------------ */
SELECT COUNT(*) AS non_positive_credit_limits
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND product_type = 'Credit Card'
  AND TRY_CONVERT(DECIMAL(18,2), credit_limit) <= 0;

/*
Finding:
0 records were found.

All Credit Card credit limits are greater than zero.
*/


/* ------------------------------------------------------------
   5. Profile Credit Card credit_limit values
   ------------------------------------------------------------ */
SELECT
    COUNT(*) AS credit_card_accounts,
    MIN(TRY_CONVERT(DECIMAL(18,2), credit_limit)) AS minimum_credit_limit,
    MAX(TRY_CONVERT(DECIMAL(18,2), credit_limit)) AS maximum_credit_limit,
    AVG(TRY_CONVERT(DECIMAL(18,2), credit_limit)) AS average_credit_limit
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND product_type = 'Credit Card';

/*
Finding:

Credit Card accounts:       673
Minimum credit_limit:      5,000.00
Maximum credit_limit:     50,000.00
Average credit_limit:     approximately 21,582.47
*/


/* ============================================================
   OVERALL FINDING: credit_limit

   - credit_limit is populated for all 673 Credit Card
     Product Enrollment records.
   - It is not populated for other product types.
   - All populated values are valid numeric values.
   - No zero or negative credit limits were identified.
   - Values range from 5,000.00 to 50,000.00.

   Staging decision:
   No business-value cleaning is required.
   Convert credit_limit from VARCHAR to DECIMAL(18,2)
   during the staging load.
   ============================================================ */


   /* ============================================================
   PRODUCT ENROLLMENT PROFILING
   Column: loan_amount
   ============================================================ */

/* ------------------------------------------------------------
   1. Check for missing loan_amount on Personal Loan enrollments
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_loan_amount
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND product_type = 'Personal Loan'
  AND (
        loan_amount IS NULL
        OR TRIM(loan_amount) = ''
      );

/*
Finding:
0 records were found.

All Personal Loan Product Enrollment records contain
a loan_amount.
*/


/* ------------------------------------------------------------
   2. Check whether loan_amount is populated for products
      other than Personal Loan
   ------------------------------------------------------------ */
SELECT COUNT(*) AS loan_amount_other_products
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND product_type <> 'Personal Loan'
  AND loan_amount IS NOT NULL
  AND TRIM(loan_amount) <> '';

/*
Finding:
0 records were found.

loan_amount is populated only for Personal Loan
Product Enrollment records.
*/


/* ------------------------------------------------------------
   3. Check for non-numeric loan_amount values
   ------------------------------------------------------------ */
SELECT loan_amount
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND loan_amount IS NOT NULL
  AND TRIM(loan_amount) <> ''
  AND TRY_CONVERT(DECIMAL(18,2), loan_amount) IS NULL;

/*
Finding:
0 invalid numeric values were found.

All populated loan_amount values can be converted
to DECIMAL(18,2).
*/


/* ------------------------------------------------------------
   4. Check for zero or negative loan amounts
   ------------------------------------------------------------ */
SELECT COUNT(*) AS non_positive_loan_amounts
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND product_type = 'Personal Loan'
  AND TRY_CONVERT(DECIMAL(18,2), loan_amount) <= 0;

/*
Finding:
0 records were found.

All Personal Loan amounts are greater than zero.
*/


/* ------------------------------------------------------------
   5. Profile Personal Loan loan_amount values
   ------------------------------------------------------------ */
SELECT
    COUNT(*) AS personal_loan_accounts,
    MIN(TRY_CONVERT(DECIMAL(18,2), loan_amount)) AS minimum_loan_amount,
    MAX(TRY_CONVERT(DECIMAL(18,2), loan_amount)) AS maximum_loan_amount,
    AVG(TRY_CONVERT(DECIMAL(18,2), loan_amount)) AS average_loan_amount
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND product_type = 'Personal Loan';

/*
Finding:

Personal Loan accounts:      649
Minimum loan_amount:      10,000.00
Maximum loan_amount:     100,000.00
Average loan_amount:      approximately 49,899.85
*/


/* ============================================================
   OVERALL FINDING: loan_amount

   - loan_amount is populated for all 649 Personal Loan
     Product Enrollment records.
   - It is not populated for other product types.
   - All populated values are valid numeric values.
   - No zero or negative loan amounts were identified.
   - Values range from 10,000.00 to 100,000.00.

   Staging decision:
   No business-value cleaning is required.
   Convert loan_amount from VARCHAR to DECIMAL(18,2)
   during the staging load.
   ============================================================ */


/* ============================================================
   PRODUCT ENROLLMENT PROFILING
   Column: account_balance
   ============================================================ */

/* ------------------------------------------------------------
   1. Check for missing account_balance on Product Enrollment
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_account_balance
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND (
        account_balance IS NULL
        OR TRIM(account_balance) = ''
      );

/*
Finding:
0 records were found.

All Product Enrollment records contain an account_balance.
*/


/* ------------------------------------------------------------
   2. Check whether account_balance is populated outside
      Product Enrollment
   ------------------------------------------------------------ */
SELECT COUNT(*) AS account_balance_outside_enrollment
FROM source.customer_activity_extract
WHERE event_type <> 'Product Enrollment'
  AND account_balance IS NOT NULL
  AND TRIM(account_balance) <> '';

/*
Finding:
0 records were found.

account_balance is populated only for Product Enrollment
records.
*/


/* ------------------------------------------------------------
   3. Check for non-numeric account_balance values
   ------------------------------------------------------------ */
SELECT account_balance
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND account_balance IS NOT NULL
  AND TRIM(account_balance) <> ''
  AND TRY_CONVERT(DECIMAL(18,2), account_balance) IS NULL;

/*
Finding:
0 invalid numeric values were found.

All populated account_balance values can be converted
to DECIMAL(18,2).
*/


/* ------------------------------------------------------------
   4. Check for negative account balances
   ------------------------------------------------------------ */
SELECT COUNT(*) AS negative_account_balances
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
  AND TRY_CONVERT(DECIMAL(18,2), account_balance) < 0;

/*
Finding:
0 negative account balances were found.
*/


/* ------------------------------------------------------------
   5. Profile account_balance by product_type
   ------------------------------------------------------------ */
SELECT
    product_type,
    COUNT(*) AS account_count,
    MIN(TRY_CONVERT(DECIMAL(18,2), account_balance)) AS minimum_balance,
    MAX(TRY_CONVERT(DECIMAL(18,2), account_balance)) AS maximum_balance,
    AVG(TRY_CONVERT(DECIMAL(18,2), account_balance)) AS average_balance
FROM source.customer_activity_extract
WHERE event_type = 'Product Enrollment'
GROUP BY product_type
ORDER BY product_type;

/*
Finding:

Credit Card
- Accounts: 673
- Minimum: 7.48
- Maximum: 48,942.42
- Average: approximately 10,726.19

Personal Loan
- Accounts: 649
- Minimum: 20.17
- Maximum: 97,448.63
- Average: approximately 23,799.98

Savings
- Accounts: 678
- Minimum: 100.98
- Maximum: 79,993.90
- Average: approximately 38,496.97

Total accounts:
673 + 649 + 678 = 2,000 Product Enrollment records.
*/


/* ============================================================
   OVERALL FINDING: account_balance

   - account_balance is populated for all 2,000 Product
     Enrollment records.
   - It is not populated outside Product Enrollment.
   - All values are valid numeric values.
   - No negative balances were identified.
   - account_balance is meaningful across all three product
     types in the supplied dataset.

   Staging decision:
   No business-value cleaning is required.
   Convert account_balance from VARCHAR to DECIMAL(18,2)
   during the staging load.
   ============================================================ */


   /* ============================================================
   CRM INTERACTION PROFILING
   Columns: channel and interaction_type
   ============================================================ */

/* ------------------------------------------------------------
   1. Check for missing channel on CRM Interaction records
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_crm_channel
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND (
        channel IS NULL
        OR TRIM(channel) = ''
      );

/*
Finding:
0 records were found.

All CRM Interaction records contain a channel.
*/


/* ------------------------------------------------------------
   2. Check for missing interaction_type
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_interaction_type
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND (
        interaction_type IS NULL
        OR TRIM(interaction_type) = ''
      );

/*
Finding:
0 records were found.

All CRM Interaction records contain an interaction_type.
*/


/* ------------------------------------------------------------
   3. Check whether interaction_type is populated outside CRM
   ------------------------------------------------------------ */
SELECT COUNT(*) AS interaction_type_outside_crm
FROM source.customer_activity_extract
WHERE event_type <> 'CRM Interaction'
  AND interaction_type IS NOT NULL
  AND TRIM(interaction_type) <> '';

/*
Finding:
0 records were found.

interaction_type is populated only for CRM Interaction
records.
*/


/* ------------------------------------------------------------
   4. Check for whitespace
   ------------------------------------------------------------ */
SELECT COUNT(*) AS crm_whitespace_issues
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND (
       channel <> TRIM(channel)
       OR interaction_type <> TRIM(interaction_type)
      );

/*
Finding:
0 records were found.

No leading or trailing whitespace was identified.
*/


/* ------------------------------------------------------------
   5. Check for unexpected CRM channel values
   ------------------------------------------------------------ */
SELECT DISTINCT channel
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND channel COLLATE Latin1_General_CS_AS
      NOT IN ('Call', 'Chat', 'Email', 'Branch', 'WhatsApp');

/*
Finding:
0 unexpected values were found.

All CRM channel values match the expected values and casing.
*/


/* ------------------------------------------------------------
   6. Check for unexpected interaction_type values
   ------------------------------------------------------------ */
SELECT DISTINCT interaction_type
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND interaction_type COLLATE Latin1_General_CS_AS
      NOT IN
      (
          'Query',
          'Complaint',
          'Product Application',
          'Feedback',
          'Fraud Report'
      );

/*
Finding:
0 unexpected values were found.

All interaction_type values match the expected values
and casing.
*/


/* ------------------------------------------------------------
   7. Review interaction_type by channel
   ------------------------------------------------------------ */
SELECT
    channel,
    interaction_type,
    COUNT(*) AS interaction_count
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
GROUP BY
    channel,
    interaction_type
ORDER BY
    channel,
    interaction_type;

/*
Finding:

All five CRM channels occur across all five interaction
types.

The combinations reconcile to 4,500 CRM Interaction
records.

No invalid channel / interaction_type combinations were
identified from the supplied data dictionary.
*/


/* ============================================================
   OVERALL FINDING: channel and interaction_type

   - All 4,500 CRM Interaction records contain both fields.
   - interaction_type is not populated outside CRM Interaction.
   - No whitespace issues were identified.
   - No unexpected values or casing inconsistencies were found.
   - All five expected channels and all five expected
     interaction types are represented.
   - Multiple valid channel / interaction_type combinations
     occur throughout the dataset.

   Staging decision:
   No cleaning transformation is required for CRM channel
   or interaction_type. Existing values will be retained.
   ============================================================ */


   /* ============================================================
   CRM INTERACTION PROFILING
   Column: resolved_flag
   ============================================================ */

/* ------------------------------------------------------------
   1. Review resolved_flag distribution
   ------------------------------------------------------------ */
SELECT
    CASE
        WHEN resolved_flag IS NULL OR TRIM(resolved_flag) = ''
            THEN 'Blank'
        ELSE resolved_flag
    END AS resolved_status,
    COUNT(*) AS record_count
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
GROUP BY
    CASE
        WHEN resolved_flag IS NULL OR TRIM(resolved_flag) = ''
            THEN 'Blank'
        ELSE resolved_flag
    END
ORDER BY resolved_status;

/*
Finding:

Y       3,410
N         873
Blank     217

Total:  4,500

The total reconciles with all CRM Interaction records.
*/


/* ------------------------------------------------------------
   2. Check for unexpected populated resolved_flag values
   ------------------------------------------------------------ */
SELECT DISTINCT resolved_flag
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND resolved_flag IS NOT NULL
  AND TRIM(resolved_flag) <> ''
  AND resolved_flag COLLATE Latin1_General_CS_AS
      NOT IN ('Y', 'N');

/*
Finding:
0 unexpected populated values were found.

Populated resolved_flag values contain only Y or N.
*/


/* ------------------------------------------------------------
   3. Check for leading or trailing whitespace
   ------------------------------------------------------------ */
SELECT COUNT(*) AS resolved_flag_whitespace
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND resolved_flag IS NOT NULL
  AND resolved_flag <> TRIM(resolved_flag);

/*
Finding:
0 records were found.

No leading or trailing whitespace was identified.
*/


/* ------------------------------------------------------------
   4. Check whether resolved_flag is populated outside CRM
   ------------------------------------------------------------ */
SELECT COUNT(*) AS resolved_flag_outside_crm
FROM source.customer_activity_extract
WHERE event_type <> 'CRM Interaction'
  AND resolved_flag IS NOT NULL
  AND TRIM(resolved_flag) <> '';

/*
Finding:
0 records were found.

resolved_flag is populated only for CRM Interaction records.
*/


/* ------------------------------------------------------------
   5. Investigate blank resolved_flag records by channel
      and interaction_type
   ------------------------------------------------------------ */
SELECT
    channel,
    interaction_type,
    COUNT(*) AS blank_resolved_count
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND (
        resolved_flag IS NULL
        OR TRIM(resolved_flag) = ''
      )
GROUP BY
    channel,
    interaction_type
ORDER BY
    interaction_type,
    channel;

/*
Finding:

217 CRM Interaction records have a blank resolved_flag.

Blank values occur across multiple channels and all
interaction types. No pattern in the available attributes
provides sufficient evidence that a blank value means N.

Therefore, blank resolved_flag values cannot safely be
interpreted as "Not Resolved".
*/


/* ------------------------------------------------------------
   6. Investigate repeated Complaint events

   Multiple complaints by the same client are not automatically
   duplicates because a client may have multiple legitimate
   interactions.
   ------------------------------------------------------------ */
SELECT
    client_number,
    COUNT(*) AS complaint_count
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND interaction_type = 'Complaint'
GROUP BY client_number
HAVING COUNT(*) > 1
ORDER BY complaint_count DESC;

/*
Finding:
Some clients have more than one Complaint interaction.

This is expected at event level and does not by itself
indicate duplicate data.
*/


/* ------------------------------------------------------------
   7. Check for repeated Complaint events for the same client,
      date and channel
   ------------------------------------------------------------ */
SELECT
    client_number,
    event_date,
    channel,
    COUNT(*) AS complaint_count
FROM source.customer_activity_extract
WHERE event_type = 'CRM Interaction'
  AND interaction_type = 'Complaint'
GROUP BY
    client_number,
    event_date,
    channel
HAVING COUNT(*) > 1;

/*
Finding:
0 records were returned.

No client has multiple Complaint records with the same
event_date and channel.
*/


/* ============================================================
   OVERALL FINDING: resolved_flag

   - Y: 3,410 records.
   - N: 873 records.
   - Blank: 217 records.
   - No unexpected populated values were identified.
   - No whitespace issues were identified.
   - resolved_flag is populated only for CRM Interaction.
   - Blank values occur across different channels and
     interaction types.
   - There is insufficient evidence to interpret blank as N.
   - Multiple Complaint interactions for a client are valid
     event-level records and should not automatically be
     treated as duplicates.

   Staging decision:
   - Retain all CRM Interaction records.
   - Convert blank/NULL resolved_flag values to 'Unknown'.
   - Do not assume that a missing resolved_flag means
     'Not Resolved'.
   ============================================================ */


   /* ============================================================
   TRANSACTION PROFILING
   Columns: transaction_type and channel
   ============================================================ */

/* ------------------------------------------------------------
   1. Check for missing transaction_type
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_transaction_type
FROM source.customer_activity_extract
WHERE event_type = 'Transaction'
  AND (
        transaction_type IS NULL
        OR TRIM(transaction_type) = ''
      );

/*
Finding:
0 records were found.

All Transaction records contain a transaction_type.
*/


/* ------------------------------------------------------------
   2. Check whether transaction_type is populated outside
      Transaction records
   ------------------------------------------------------------ */
SELECT COUNT(*) AS transaction_type_outside_transaction
FROM source.customer_activity_extract
WHERE event_type <> 'Transaction'
  AND transaction_type IS NOT NULL
  AND TRIM(transaction_type) <> '';

/*
Finding:
0 records were found.

transaction_type is populated only for Transaction records.
*/


/* ------------------------------------------------------------
   3. Check transaction_type for whitespace
   ------------------------------------------------------------ */
SELECT COUNT(*) AS transaction_type_whitespace
FROM source.customer_activity_extract
WHERE event_type = 'Transaction'
  AND transaction_type <> TRIM(transaction_type);

/*
Finding:
0 records were found.

No leading or trailing whitespace was identified.
*/


/* ------------------------------------------------------------
   4. Check for unexpected transaction_type values
   ------------------------------------------------------------ */
SELECT DISTINCT transaction_type
FROM source.customer_activity_extract
WHERE event_type = 'Transaction'
  AND transaction_type COLLATE Latin1_General_CS_AS
      NOT IN
      (
          'Deposit',
          'Withdrawal',
          'POS Purchase',
          'EFT Payment',
          'Debit Order',
          'Fee',
          'Refund'
      );

/*
Finding:
0 unexpected values were found.

All transaction_type values match the expected values
and casing.
*/


/* ------------------------------------------------------------
   5. Review transaction_type distribution
   ------------------------------------------------------------ */
SELECT
    transaction_type,
    COUNT(*) AS transaction_count
FROM source.customer_activity_extract
WHERE event_type = 'Transaction'
GROUP BY transaction_type
ORDER BY transaction_type;

/*
Finding:

POS Purchase      3,740
Deposit           2,986
Withdrawal        2,952
EFT Payment       2,252
Debit Order       1,548
Refund              767
Fee                 755

Total:           15,000

The distribution reconciles with all Transaction records.
*/


/* ------------------------------------------------------------
   6. Check for missing Transaction channel
   ------------------------------------------------------------ */
SELECT COUNT(*) AS missing_transaction_channel
FROM source.customer_activity_extract
WHERE event_type = 'Transaction'
  AND (
        channel IS NULL
        OR TRIM(channel) = ''
      );

/*
Finding:
0 records were found.

All Transaction records contain a channel.
*/


/* ------------------------------------------------------------
   7. Check Transaction channel for whitespace
   ------------------------------------------------------------ */
SELECT COUNT(*) AS transaction_channel_whitespace
FROM source.customer_activity_extract
WHERE event_type = 'Transaction'
  AND channel <> TRIM(channel);

/*
Finding:
0 records were found.

No leading or trailing whitespace was identified.
*/


/* ------------------------------------------------------------
   8. Check for unexpected Transaction channel values
   ------------------------------------------------------------ */
SELECT DISTINCT channel
FROM source.customer_activity_extract
WHERE event_type = 'Transaction'
  AND channel COLLATE Latin1_General_CS_AS
      NOT IN
      (
          'ATM',
          'POS',
          'Branch',
          'Online Banking',
          'Mobile App',
          'EFT'
      );

/*
Finding:
0 unexpected values were found.

All Transaction channel values match the expected
values and casing.
*/


/* ------------------------------------------------------------
   9. Review transaction_type and channel relationship
   ------------------------------------------------------------ */
SELECT
    transaction_type,
    channel,
    COUNT(*) AS transaction_count
FROM source.customer_activity_extract
WHERE event_type = 'Transaction'
GROUP BY
    transaction_type,
    channel
ORDER BY
    transaction_type,
    channel;

/*
Finding:

Debit Order / EFT                 1,548

Deposit / Branch                  1,015
Deposit / ATM                       993
Deposit / EFT                       978

EFT Payment / Mobile App          1,137
EFT Payment / Online Banking      1,115

Fee / EFT                           755

POS Purchase / POS                3,740

Refund / Online Banking             385
Refund / POS                        382

Withdrawal / ATM                  1,495
Withdrawal / Branch               1,457

The combinations reconcile with all 15,000 Transaction
records.
*/


/* ============================================================
   OVERALL FINDING: transaction_type and channel

   - All 15,000 Transaction records contain both fields.
   - transaction_type is populated only for Transaction records.
   - No whitespace issues were identified.
   - No unexpected values or casing inconsistencies were found.
   - Seven transaction types are represented.
   - Six Transaction channel values are represented.
   - transaction_type/channel combinations are consistent
     with the supplied dataset.

   Staging decision:
   No cleaning transformation is required for transaction_type
   or Transaction channel. Existing values will be retained.
   ============================================================ */


   /* ============================================================
   PROFILING STATUS

   Client/common fields:       COMPLETE
   Product Enrollment fields:  COMPLETE
   CRM Interaction fields:     COMPLETE
   Transaction fields:         COMPLETE

   Next phase:
   Build and load cleaned, correctly typed staging tables
   based on the transformations and data-quality decisions
   identified during profiling.
   ============================================================ */