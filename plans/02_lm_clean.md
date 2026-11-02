Status: awaiting team approval, Mon Nov 2

# Plan: union file cleaning (Assignment 2, parts 3–4)

Counts below come from a read-only R run on 2026-11-02; nothing was written to the project.
`docs/audit_findings.md` gives 276 flagged member counts and `agent_log.md` gives 321. Both are right:
276 uses a 100-member floor and compares each year with the union's previous and next reports. Our
adjacent-year rule with the same floor gives **275**.

## Steps

**Step 1. `code/03_lm_clean.R` → `data_clean/lm_clean.csv`**
Reads `data_raw/LM_data_2026_teaching.csv`, all columns as text. Uses `id, year, FORM, fipstate_cd119,
state, UNION_NAME, members, TTL_ASSETS, TTL_RECEIPTS, TTL_DISBURSEMENTS`. Rules run in this order, and the
script prints the row count after each one:

| # | Rule | Rows affected |
|---|---|---|
| 5 | Drop DC and the territories (district codes ending `98`) | −9,433, leaving 537,866 rows |
| 4 | Negative money values become missing. Liabilities are dropped as a column | 349 |
| 3 | Simplified reports (FORM 5) and LM-4 reports with zero assets, receipts and disbursements: set the money columns to missing and add a flag, `no_fin_data` | 35,681 + 17,849 |
| 1 | Member spikes (adjacent years, more than 10x each usable neighbour, at least 100 members): replace with the average of the usable neighbours. Add a flag, `members_fixed` | 275 |
| 2 | Zero members with positive receipts: use the union's previous positive count, or the next one if there isn't a previous one. Otherwise leave it missing. Same flag | 6,355 (5,631 have an earlier count) |
| 6 | Unions that filed in 2022 and 2023 but not 2024: copy the 2023 row forward to 2024. Add a flag, `carried_forward` | +614 rows |

Rule 1 runs before rule 2 so that a zero is never treated as a neighbour. **Check:** the row counts above.
The script also re-runs the spike test on the cleaned members and should find 0 rows, and it prints the
range of member counts.

**Step 2. `code/04_lm_clean_check.R` → one figure and one table**
- `output/figures/fig4_members_vs_receipts_before_after.png`: fig 1 drawn twice, raw and cleaned, side by
  side on the same axes.
- `output/tables/top20_districts_before_after.csv`: for 2020 and 2024, the top 20 of the 435 districts by
  summed members, raw against cleaned, with each district's rank and member total.
- **Check:** no orange points left above the band. Illinois-15 drops from first place in 2020. Count how
  many districts leave the top 20 after cleaning.

**Step 3. Housekeeping**
- Renumber `code/README.md` to: `01_outcome`, `02_lm_audit`, `03_lm_clean`, `04_lm_clean_check`,
  `05_predictors`, `06_models`.
- At the end, write `docs/lm_clean_results.md`.

## Decisions for the team (recommended default in bold)

1. **The 100-member floor: yes.** It cuts the flags from 321 to 275. It removes 38 of the 147 cases with
   only one neighbour (mostly tiny locals growing from a handful of members) and 8 of the 174
   two-neighbour cases.
2. **What counts as a neighbour: the adjacent calendar year**, as in `02_lm_audit.R` and `decisions.md`.
   Using the previous and next reports gives 276 instead, one row more.
3. **Rule 3 for members:** the proposed rule sets members to missing too. But 16,159 of the all-zero LM-4
   rows and 991 of the FORM 5 rows report a positive member count. **Keep those counts and set only the
   money columns to missing.**
4. **Rule 6 (late filers): carry the 614 rows forward, with the flag.** In a normal year about 470 unions
   stop filing (2021–2022 filers missing in 2023). So most of these 614 have really stopped, and copying
   them forward keeps them alive for one year, about 3% of 2024 locals. The flag lets the model be run
   both with and without these rows.
5. **"Before" in the top-20 table means raw members summed over the 435 voting districts.** That way the
   only difference between the two columns is the member fixes.

## Out of scope
- The 936 reports dated after a union's termination.
- Filling in the 4,940 missing years in the middle of unions' filing histories.
- Building district-level predictors, the outcome, and anything from the Labor Action Tracker.
- Writing to `decisions.md` (humans only) or `agent_log.md` (only on "log this").
