# 🏥 Hospital Readmissions Analysis

**Which patient and operational factors most predict a 30-day readmission — and what can hospitals actually do about it?**

A data analytics project using **SQL, Python, and Excel** to analyze 750 hospital admission records and surface insights hospital administrators could act on to reduce avoidable readmissions and control cost.

---

## 📌 Problem Statement

Hospitals face financial penalties from Medicare for excessive 30-day readmissions, and every readmission represents both a cost and a potential gap in patient care. This project investigates:

- Which patients are most at risk of being readmitted within 30 days?
- Which departments and hospitals are the least cost-efficient?
- Does length of stay affect patient satisfaction?

The goal: turn raw admissions data into findings a hospital operations team could use to prioritize interventions.

---

## 📊 Dataset

- **750 patient admission records** across 5 hospitals (2022–2023)
- **13 fields** including age, department, diagnosis, insurance type, length of stay, total cost, outcome, and satisfaction score
- Source: synthetic dataset generated to model realistic healthcare admission patterns

| Column | Description |
|---|---|
| `patient_id` | Unique patient identifier |
| `age`, `gender` | Patient demographics |
| `hospital`, `department`, `diagnosis` | Where and why the patient was admitted |
| `insurance_type` | Medicare, Medicaid, Blue Cross, Uninsured, etc. |
| `admit_date`, `discharge_date`, `length_of_stay_days` | Stay duration |
| `total_cost_usd` | Total billed cost |
| `outcome` | Discharged / Readmitted within 30d / Transferred / Deceased |
| `satisfaction_score` | Patient rating, 1.0–5.0 |

📁 Full file: [`data/patient_admissions.csv`](data/patient_admissions.csv)

---

## 🛠️ Tools Used

| Tool | What it was used for |
|---|---|
| **SQL (PostgreSQL)** | Aggregations, CTEs, and window functions (`RANK()`, `LAG()`) to answer business questions directly against the data |
| **Python (pandas, matplotlib, seaborn)** | Data cleaning, exploratory analysis, and visualization |
| **Excel** | Interactive pivot table dashboard with slicers for non-technical stakeholders |

---

## 🔍 Key Findings

1. **Uninsured patients have the highest readmission rate (27.2%)** — nearly double Blue Cross patients (14.8%). This suggests cost-related barriers to follow-up care may be driving repeat hospitalizations.

2. **Readmission risk is U-shaped by age** — the 76–90 group readmits at 24.0%, well above the 61–75 group (14.2%), pointing to elderly patients as a priority group for discharge planning.

3. **Orthopedics has the highest cost per day of care ($3,229)** — higher than Oncology ($2,551), despite Oncology typically being assumed as the costliest department. Cost-per-day reveals efficiency issues that total cost alone hides.

4. **City General has the lowest overall readmission rate (13.5%)** among all 5 hospitals, but a deeper look shows even its best-performing hospital has at least one department with elevated risk — visible only through within-hospital ranking, not simple averages.

5. **Shorter hospital stays correlate with higher patient satisfaction** — average satisfaction for stays of 1–3 days is meaningfully higher than for stays of 8+ days, suggesting stay length itself may affect the patient experience independent of clinical outcome.

> Overall readmission rate across all 750 admissions: **19.1%**

---

## 📈 Visuals

**Readmission rate by insurance type**
![Readmission by Insurance](python/readmission_by_insurance.png)

**Readmission rate by age group**
![Readmission by Age](python/readmission_by_age.png)

**Cost per day by department**
![Cost per Day by Department](python/cost_per_day_by_department.png)

**Length of stay vs. satisfaction**
![LOS vs Satisfaction](python/los_vs_satisfaction.png)

**Excel dashboard**
*(screenshot to be added — see `excel/dashboard.xlsx`)*

---

## 📁 Repository Structure

```
hospital-readmissions-analysis/
├── README.md
├── data/
│   └── patient_admissions.csv
├── sql/
│   └── analysis.sql          # 9 queries incl. CTEs and window functions
├── python/
│   ├── analysis.py           # Full cleaning + EDA + chart generation
│   ├── hospital_summary.csv  # Exported KPI summary
│   └── *.png                 # Generated charts
└── excel/
    └── dashboard.xlsx        # Pivot table dashboard with slicers
```

---

## ▶️ How to Run This Project

**Python**
```bash
pip install pandas matplotlib seaborn
python python/analysis.py
```

**SQL (PostgreSQL)**
```bash
psql -U your_username -d your_database
\copy admissions FROM 'data/patient_admissions.csv' WITH (FORMAT csv, HEADER true);
-- then run queries from sql/analysis.sql
```

**Excel**
Open `excel/dashboard.xlsx` — pivot tables and slicers are pre-built and interactive.

---

## 🙋 About This Project

Built to demonstrate practical data analytics skills across the three tools most commonly used in analyst roles: SQL for querying production-style data, Python for deeper exploratory analysis and visualization, and Excel for stakeholder-facing reporting.

**Connect with me:** [LinkedIn](#) · [Portfolio](#)
