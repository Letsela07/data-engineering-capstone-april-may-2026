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
   PROFILING PROGRESS

   Completed:
   - client_number
   - first_name
   - last_name
   - email
   - mobile_number
   - date_of_birth
   - gender
   - province
   - city
   - signup_date
   - event_type
   - event_date

   Next profiling section:
   Product Enrollment fields, beginning with account_number.
   ============================================================ */