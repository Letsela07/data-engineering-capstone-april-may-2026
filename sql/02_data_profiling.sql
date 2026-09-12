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