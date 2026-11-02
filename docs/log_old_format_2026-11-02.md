# Lab notebook

## 2026-10-26 · coding agent (no role file; session predates prompts/) · Audit of the union (LM) file

**Task.** Ed asked for a first look at `data_raw/LM_data_2026_teaching.csv`, then an audit script with
four parts. Part 1: members against receipts, highlighting one-year member spikes. Part 2: year-on-year
change within each union. Part 3: unions filing each year, with first and last reports. Part 4: zero,
missing and contradictory values by FORM. Ed then made three follow-up decisions.

**Choices made and why.**
- Read every column as text, then converted `members`, `TTL_ASSETS`, `TTL_LIABILITIES`, `TTL_RECEIPTS`
  and `TTL_DISBURSEMENTS` to numbers. District codes keep their leading zeros. No value failed to convert
  beyond those already blank.
- A "neighbouring year" counts only if it is the adjacent calendar year. A union with a filing gap has no
  neighbour across the gap.
- Spike rule (Ed's decision, final version): flag a union-year whose member count is more than 10 times
  every usable neighbour, meaning an adjacent-year report with more than 0 members. If there are two
  neighbours, it must exceed both. If there is one (panel edge or filing gap), it must exceed that one.
  With none, it is not flagged. The first version required both neighbours, so it could never flag 2000
  or 2024. It missed the 4,081,862-member Montana row (544-355, 2024) and the 3,619,429-member Delaware
  row (503-290, 2024).
- Year-on-year change is measured as log10(this year / last year), using adjacent years where both
  values are positive. Values beyond 1000x either way are piled into the end bins of fig 2.
- Fig 3 leaves out first reports in 2000 and last reports in 2024. They mark the edges of the panel,
  not entries or exits.
- The audit only flags and counts. It drops or changes no rows.

**Actions taken.**
- Basic facts: 547,299 rows, 32,233 unions, 2000–2024. No union-year appears twice. Every row has
  a `fipstate_cd119` (440 distinct codes). 9,433 rows are in DC, Puerto Rico and the territories (codes ending `98`).
- Wrote, ran and fixed the audit script. The first run failed on a reshape step. Later fixes covered
  a NaN warning, a missing label and overlapping tick labels.
- Following Ed's decisions: renamed the script from `01_lm_audit.R` to `02_lm_audit.R` to match
  `code/README.md`, added `output/tables/` to the folder rules, changed the spike rule as above, and re-ran.
- Final results: 321 flagged union-years in 317 unions (174 with two neighbours, 147 with one).
  74,523 union-years have zero, negative or missing members or receipts, so they can't appear on the
  log-scale fig 1. Problem rows across all forms: 6,355 with zero members but positive receipts, 25,795
  with positive members but zero receipts, 35,519 missing members, 16,830 missing receipts, and 349 with
  negative assets or liabilities.

**Files written.**
- `code/02_lm_audit.R`
- `output/figures/fig1_members_vs_receipts.png`, `output/figures/fig2_year_on_year_change.png`,
  `output/figures/fig3_unions_by_year.png`
- `output/tables/member_spikes.csv` (includes a `neighbours_used` column), `output/tables/unions_by_year.csv`,
  `output/tables/problem_rows_by_form.csv`
- The session log, now at `logs/2026-10-26_ed_lm_audit.md`
- Edited at the time: CLAUDE.md (the `output/tables/` line) and `decisions.md` (three rows dated 2026-10-26).
  Under the old instructions the agent wrote those rows. AGENTS.md now reserves `decisions.md` for the humans.

**Still open.**
- The 147 one-neighbour flags look different from the two-neighbour ones. Median receipts per member is
  about $53, against about $2. In 69 of them the neighbouring year has fewer than 10 members. Many look
  like a real local next to a tiny start-up or wind-down filing, so treat them as rows to review, not
  rows to drop. Whether to add a receipts-per-member check is undecided.
- Some spikes look like numbers glued together (for example, 747,498 members against receipts of 7,498;
  589,313 against 9,313).
- Missing values follow the form type. FORM 5 has 31,448 of the 35,519 missing member counts and
  16,020 of the 16,830 missing receipts. FORM 4 has 23,476 of the 25,795 rows with positive members
  and zero receipts. Don't impute as if missingness were random.
- First reports jump to 1,389 in 2001, probably partly a start-up artifact of the panel.
- In the first row, `ZIP5` has lost its leading zero (`2914`) while `zip` kept it (`02914`), the reverse
  of what the codebook says. This doesn't matter as long as joins use the district code.
- `docs/audit_findings.md`, which AGENTS.md cites for the known problems in the union file, does not
  exist in the project, and neither does `docs/`. This entry was written from the session log and the
  output files only.
- 2026-10-26 entries in `decisions.md` were written by the agent. A human should confirm them.
