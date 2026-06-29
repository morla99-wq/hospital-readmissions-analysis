"""Hospital Readmissions Analysiss
-------------------------
Business question: Which patient and operational factors most predict a 30-day readmission, and what should hospitals act on?
Author: Gerinardo Morla
Dataset: patient_admissions.csv (750 synthetic patient records, 2022-2023)"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_theme(style="whitegrid")
pd.set_option("display.max_columns", None)

# ---------------
# 1.LOAD AND CLEAN
#----------------

df = pd.read_csv("patient_admissions.csv", parse_dates =["admit_date", "discharge_date"])
print("Shape.", df.shape)
print(df.info())

# Satisfaction_score is blank for deceased patients ->keep as NaN, not 0
df["satisfaction_score"] = pd.to_numeric(df["satisfaction_score"], errors="coerce")

# Flag the outcome we care about most
df["is_readmitted"] = df["outcome"].eq("Readmitted within 30d")

# Age buckets make the age-vs-readmission story easier to read
df["age_group"] = pd.cut(
    df["age"],
    bins=[17, 30, 45, 60, 75, 90],
    labels=["18-30", "30-45", "46-60", "61-75", "76-90"]
)

# Quick sanity checks every analyst should run
print("\nMissing values:\n", df.isna().sum())
print("\nDuplicate patient_ids:", df["patient_id"].duplicated().sum())

#------------------------------------
# 2.READMISSION RATE BY INSURANCE TYPE
#------------------------------------

readmit_by_insurance = (
    df.groupby("insurance_type")["is_readmitted"]
    .mean()
    .mul(100)
    .round(1)
    .sort_values(ascending=False)
)            
print("\nReadmission rate(%) by insurance type:\n", readmit_by_insurance)

plt.figure(figsize=(8,5))
sns.barplot(
    x=readmit_by_insurance.values,
    y=readmit_by_insurance.index,
    hue=readmit_by_insurance.index,
    palette="rocket",
    legend=False,
)

plt.xlabel("Readmission Rate (%)")
plt.ylabel("insurance Type")
plt.title("30-Day Readmission Rate ny insurance Type")
plt.tight_layout()
plt.savefig("readmission_by_insurance.png", dpi=150)
plt.close

#-------------------------
# 3.READMISSION BY AGE GROUP
#-------------------------

readmit_by_age = df.groupby("age_group")["is_readmitted"].mean().mul(100).round(1)
print("\nReadmission rate (%) by age group:\n", readmit_by_age)

plt.figure(figsize=(8,5))
sns.barplot(
    x=readmit_by_age.index,
    y=readmit_by_age.values,
    hue=readmit_by_age.index,
    palette='mako',
    legend=False,
)
plt.ylabel("Readmission Rate(%)")
plt.xlabel("Age Group")
plt.title("30-Day Readmission Rate by Age Group")
plt.tight_layout
plt.savefig("readmission_by_age.png", dpi=150)
plt.close()

#--------------------------------------------------
# 4.COST EFFICIENCY: AVG COST PER DAY BY DEPARTMENT
#--------------------------------------------------

df["cost_per_day"] = df["total_cost_usd"]/df["length_of_stay_days"]

cost_by_dept = (
    df.groupby("department")["cost_per_day"]
    .mean()
    .round(0)
    .sort_values(ascending=False)
)
print("\nAvg cost per day ($) by department:\n", cost_by_dept)

plt.figure(figsize=(8,5))
sns.barplot(
    x=cost_by_dept.values,
    y=cost_by_dept.index,
    hue=cost_by_dept.index,
    palette="crest",
    legend=False,
)
plt.xlabel("Avg Cost per Day (USD)")
plt.ylabel("Department")
plt.title("Cost Efficiency by Department")
plt.tight_layout()
plt.savefig("cost_per_day_by_department.png", dpi=150)
plt.close()

#------------------------------------------------------------------------
# 5.LENGTH OF STAY vs SATISFATION (does a longer stay hurt satisfaction?)
#------------------------------------------------------------------------
plt.figure(figsize=(8,5))
sns.scatterplot(
    data=df.dropna(subset=["satisfaction_score"]),
    x="length_of_stay_days",
    y="satisfaction_score",
    hue="is_readmitted",
    alpha=0.6,
)
plt.title("Length of Stay vs Patient Satisfaction")
plt.xlabel("Length of Stay (days)")
plt.ylabel("Satisfaction Score (1-9)")
plt.tight_layout()
plt.savefig("los_vs_satisfaction.png", dpi=150)

corr = df["length_of_stay_days"].corr(df["satisfaction_score"])
print(f"\nCorrelation between length of stay and satisfaction:{corr:.2f}")

#-------------------------------------
# 6.SUMMARY TABLE: hospital-level KPIs 
#-------------------------------------
hospital_summary = df.groupby("hospital").agg(
    avg_cost=("total_cost_usd", "mean"),
    avg_los=("length_of_stay_days", "mean"),
    readmission_rate_pct=("is_readmitted", lambda x: round(x.mean() * 100, 1)),
    avg_satisfaction=("satisfaction_score", "mean"),
).round(2).sort_values("readmission_rate_pct", ascending=False)

print("\nHospital-level summary:\n", hospital_summary)
hospital_summary.to_csv("hospital_summary.csv")

print("\nDone. Charts saved as PNGs, summary saved as hospital_summary.csv")