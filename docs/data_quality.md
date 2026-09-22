# Customer360 Data Quality Note

## Overview

The raw Customer360 extract contained 21,500 event records covering Product Enrollments, CRM Interactions and Transactions. Data profiling was performed before building the staging and dimensional warehouse layers.

The approach was to standardise values where the intended value was clear, preserve valid business records where possible, and flag questionable records rather than automatically deleting them.

## Data Quality Findings and Handling

### 1. Mobile Number Formatting

Mobile numbers appeared in multiple formats, including spaces, hyphens, brackets and the South African `+27` country code.

**Handling:**
- Removed spaces, hyphens, brackets and the `+` character.
- Converted valid numbers beginning with `27` to the local `0` format.
- Valid local mobile numbers were standardised to 10 digits beginning with `0`.
- Values that could not be converted to the expected format were stored as `NULL`.

### 2. Missing and Inconsistent Email Addresses

354 records had missing email addresses. Some populated email addresses also contained spaces or inconsistent upper/lowercase formatting.

**Handling:**
- Missing or blank email addresses were stored as `NULL`.
- Populated email addresses were trimmed.
- Spaces were removed.
- Email addresses were converted to lowercase.

### 3. Province Naming

The province `KwaZulu Natal` appeared without the standard hyphen.

**Handling:**

`KwaZulu Natal` was standardised to `KwaZulu-Natal` during the staging transformation.

### 4. Gender Values

The gender field contained `F`, `M`, `U` and blank values.

**Handling:**

The existing values were preserved rather than assuming or creating a gender value where the source did not provide one.

### 5. CRM Resolved Flag

Some CRM Interaction records contained a blank or missing `resolved_flag`.

**Handling:**

Blank or missing values were converted to `Unknown` so that missing resolution status could be distinguished from known `Y` and `N` values.

### 6. Orphan Transactions

10 transaction records contained client/account combinations for which no matching Product Enrollment record existed.

**Handling:**

The transactions were retained because the absence of an enrollment record did not prove that the transaction itself was invalid. The related accounts were retained in the account dimension with an `Unknown` account status where necessary.

An `orphan_account_flag` was added to `dw.fact_transaction` to identify these records for analysis.

### 7. Zero-Amount Transactions

26 transaction records had an amount of `0`.

**Handling:**

The records were retained because a zero amount alone was not sufficient evidence that the transaction was invalid.

A `zero_amount_flag` was added to `dw.fact_transaction` so that these transactions remain visible and can be investigated separately.

### 8. Duplicate and Rerun Handling

During profiling, one exact duplicate row pattern was identified in the raw source data. The ETL process also needed protection against creating additional duplicates when the pipeline was rerun.

**Handling:**
- The raw landing table is truncated before each CSV load.
- Staging loads use matching conditions to prevent the same business events from being repeatedly inserted.
- Dimension and fact loads use rerunnable logic so repeated SSIS executions do not continually increase warehouse row counts.

## Conclusion

The data quality process focused on preserving source information while applying justified standardisation and validation rules. Records were not removed simply because they appeared unusual. Where validity could not be determined with certainty, the data was retained, represented as `NULL` or `Unknown` where appropriate, or flagged in the warehouse for further analysis.