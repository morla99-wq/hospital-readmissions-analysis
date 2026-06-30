/* ============================================================
   HOSPITAL READMISSIONS ANALYSIS — SQL
   ------------------------------------------------------------
   Business question: Which patient and operational factors most
   predict a 30-day readmission, and what should hospitals act on?

   Dataset: admissions table, loaded from patient_admissions.csv
   Dialect: SQLite (works in PostgreSQL/MySQL with minor tweaks
            noted inline where relevant)
   ============================================================ */


/* ------------------------------------------------------------
   0. SANITY CHECKS
   Always confirm row counts and check for obvious data issues
   before trusting any aggregation.
   ------------------------------------------------------------ */

-- Total records and date range covered
SELECT
    COUNT(*) AS total_admissions,
    MIN(admit_date) AS earliest_admission,
    MAX(admit_date) AS latest_admission
FROM admissions;

-- Check for duplicate patient_ids (would distort per-patient stats)
SELECT patient_id, COUNT(*) AS occurrences
FROM admissions
GROUP BY patient_id
HAVING COUNT(*) > 1;


/* ------------------------------------------------------------
   1. READMISSION RATE BY INSURANCE TYPE
   Question: Are uninsured patients readmitted more often?
   This is the headline finding — insurance type is often a proxy
   for access to follow-up/outpatient care.
   ------------------------------------------------------------ */

SELECT
    insurance_type,
    COUNT(*)                                              AS total_patients,
    SUM(CASE WHEN outcome = 'Readmitted within 30d' THEN 1 ELSE 0 END) AS readmissions,
    ROUND(
        100.0 * SUM(CASE WHEN outcome = 'Readmitted within 30d' THEN 1 ELSE 0 END)
        / COUNT(*), 1
    )                                                      AS readmission_rate_pct
FROM admissions
GROUP BY insurance_type
ORDER BY readmission_rate_pct DESC;


/* ------------------------------------------------------------
   2. READMISSION RATE BY AGE GROUP
   Question: Does age predict readmission risk?
   CASE statement buckets ages into clinically meaningful groups.
   ------------------------------------------------------------ */

SELECT
    CASE
        WHEN age BETWEEN 18 AND 30 THEN '18-30'
        WHEN age BETWEEN 31 AND 45 THEN '31-45'
        WHEN age BETWEEN 46 AND 60 THEN '46-60'
        WHEN age BETWEEN 61 AND 75 THEN '61-75'
        ELSE '76-90'
    END AS age_group,
    COUNT(*) AS total_patients,
    ROUND(
        100.0 * SUM(CASE WHEN outcome = 'Readmitted within 30d' THEN 1 ELSE 0 END)
        / COUNT(*), 1
    ) AS readmission_rate_pct
FROM admissions
GROUP BY age_group
ORDER BY age_group;


/* ------------------------------------------------------------
   3. COST EFFICIENCY BY DEPARTMENT
   Question: Which department costs the most per day of care,
   not just in total (a department with long stays can have a
   high total cost but be efficient on a per-day basis).
   ------------------------------------------------------------ */

SELECT
    department,
    COUNT(*) AS total_patients,
    ROUND(AVG(total_cost_usd), 0) AS avg_total_cost,
    ROUND(AVG(length_of_stay_days), 1) AS avg_length_of_stay,
    ROUND(AVG(total_cost_usd / length_of_stay_days), 0) AS avg_cost_per_day
FROM admissions
GROUP BY department
ORDER BY avg_cost_per_day DESC;


/* ------------------------------------------------------------
   4. HOSPITAL-LEVEL KPI SUMMARY
   Question: How do the 5 hospitals compare on cost, stay length,
   readmissions, and satisfaction?
   ------------------------------------------------------------ */

SELECT
    hospital,
    COUNT(*) AS total_patients,
    ROUND(AVG(total_cost_usd), 0) AS avg_cost,
    ROUND(AVG(length_of_stay_days), 1) AS avg_los,
    ROUND(
        100.0 * SUM(CASE WHEN outcome = 'Readmitted within 30d' THEN 1 ELSE 0 END)
        / COUNT(*), 1
    ) AS readmission_rate_pct,
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction
FROM admissions
GROUP BY hospital
ORDER BY readmission_rate_pct DESC;


/* ------------------------------------------------------------
   5. WINDOW FUNCTION: RANK DEPARTMENTS WITHIN EACH HOSPITAL
   BY READMISSION RATE
   Question: Within each hospital, which department is the
   biggest readmission risk? Window functions let us rank
   *within groups* without collapsing the detail.
   ------------------------------------------------------------ */

WITH dept_readmit AS (
    SELECT
        hospital,
        department,
        COUNT(*) AS total_patients,
        ROUND(
            100.0 * SUM(CASE WHEN outcome = 'Readmitted within 30d' THEN 1 ELSE 0 END)
            / COUNT(*), 1
        ) AS readmission_rate_pct
    FROM admissions
    GROUP BY hospital, department
)
SELECT
    hospital,
    department,
    total_patients,
    readmission_rate_pct,
    RANK() OVER (
        PARTITION BY hospital
        ORDER BY readmission_rate_pct DESC
    ) AS readmission_rank_in_hospital
FROM dept_readmit
ORDER BY hospital, readmission_rank_in_hospital;


/* ------------------------------------------------------------
   6. WINDOW FUNCTION: RUNNING MONTHLY ADMISSION COUNT
   Question: Is admission volume trending up or down over time?
   LAG() compares each month to the previous one to show momentum.
   ------------------------------------------------------------ */

WITH monthly AS (
    SELECT
        TO_CHAR(admit_date, 'YYYY-MM') AS admit_month,
        COUNT(*) AS admissions
    FROM admissions
    GROUP BY TO_CHAR(admit_date, 'YYYY-MM')
)
SELECT
    admit_month,
    admissions,
    LAG(admissions) OVER (ORDER BY admit_month) AS prev_month_admissions,
    admissions - LAG(admissions) OVER (ORDER BY admit_month) AS change_vs_prev_month
FROM monthly
ORDER BY admit_month;

/* ------------------------------------------------------------
   7. TOP 3 MOST EXPENSIVE DIAGNOSES PER DEPARTMENT
   Question: Within each department, which specific diagnoses
   drive the highest average cost? Useful for targeting cost
   -reduction initiatives.
   ------------------------------------------------------------ */

WITH diag_cost AS (
    SELECT
        department,
        diagnosis,
        COUNT(*) AS total_cases,
        ROUND(AVG(total_cost_usd), 0) AS avg_cost
    FROM admissions
    GROUP BY department, diagnosis
)
SELECT
    department,
    diagnosis,
    total_cases,
    avg_cost
FROM (
    SELECT
        *,
        RANK() OVER (PARTITION BY department ORDER BY avg_cost DESC) AS cost_rank
    FROM diag_cost
)
WHERE cost_rank <= 3
ORDER BY department, cost_rank;


/* ------------------------------------------------------------
   8. SATISFACTION VS LENGTH OF STAY (BUCKETED)
   Question: Does a longer hospital stay correlate with lower
   patient satisfaction? Buckets LOS into short/medium/long stays.
   ------------------------------------------------------------ */

SELECT
    CASE
        WHEN length_of_stay_days <= 3  THEN 'Short (1-3 days)'
        WHEN length_of_stay_days <= 7  THEN 'Medium (4-7 days)'
        ELSE 'Long (8+ days)'
    END AS stay_length_bucket,
    COUNT(*) AS total_patients,
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction
FROM admissions
WHERE satisfaction_score IS NOT NULL
GROUP BY stay_length_bucket
ORDER BY avg_satisfaction DESC;
