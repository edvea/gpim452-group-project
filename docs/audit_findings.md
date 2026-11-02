# Union (LM) data audit — first pass, 26 Oct 2026

Produced by Ed's coding agent from `LM_data_2026_teaching.csv`. Figures and tables are in this folder; the code that made them is in `code_python/`, and `01_lm_audit.R` is the repo version. Numbers below are the ones to quote.

## What is in the file

- 547,299 reports from 32,233 local unions, 2000–2024. One row per union per year; no duplicate or amended rows to resolve.
- Every row has a current-map district code (`fipstate_cd119`). All 435 voting districts have at least one union in every one of the 25 years.
- 9,433 rows (1,021 locals) sit outside the 50 states: DC (6,591), Puerto Rico (2,227), Virgin Islands (407), Guam (185), American Samoa (23). We drop them for the 435-district ranking and say so.
- Four report types: LM-2 for unions with receipts above $250K (106,551 rows), LM-3 for $10K–$250K (228,213), LM-4 for under $10K (176,854), and 35,681 "simplified reports" (code 5). A simplified report is what a national union files for a local that has no assets, liabilities, receipts or disbursements of its own (29 CFR 403.4(b)); it lists only the local's name, file number, address and officers. In our file 88% of those rows have no member count and 99% have missing or zero receipts.
- The file is locals only. There are no national-headquarters rows, so no 2-million-member record sits in a single district.
- Median receipts per member per year: $321. The largest real local is 1199SEIU in New York, about 370,000 members on $250M of receipts, and it looks right.

## Problem 1 — impossible member counts (Figure 1, `flagged_member_rows.csv`)

- 276 union-years report a member count more than 10 times the union's own count in both the year before and the year after. 94% snap back the next year. These are entry errors, not real growth.
- The digits show how they happened: 22 are the true count with that year's assets figure glued on (53 members, $28,403 assets, recorded as 5,328,403); 4 glued to receipts; 2 are the union's own OLMS file number typed in the members box (511,402 for file 511-402); 11 are doubled digits (573 recorded as 559,559); 42 are extra zeros (10x, 100x, 1000x the neighbouring years); 12 are the neighbouring year's count with extra digits; 183 have the same shape but no obvious source.
- They occur in every period (111 in 2000–08, 54 in 2009–16, 111 in 2017–24) and on every form (148 LM-4, 103 LM-3, 25 LM-2).
- Why it matters: they are 0.05% of rows, but they land on top. The 12 largest member counts in the whole file are all errors. Summing members by district, 17 district-years enter the national top 20 only because of one bad row. In 2020, Illinois-15 would rank first in the country with 5.3 million union members, almost all of them a 53-member steelworkers local in Ridge Farm.

## Problem 2 — zeros that mean three different things (Table 1)

- 6,355 union-years (1.2%) report 0 members but positive receipts, spread over 5,206 unions; only 173 unions do it every year. Median receipts of those rows is $6,070 and a tenth are above $260,000. These are real unions with real members; the member box was left blank and stored as zero.
- 25,795 union-years (4.7%) report members but zero receipts; 23,476 of them are LM-4 filers, the smallest unions. 18,720 report zero receipts, zero disbursements and zero assets at once; 95% LM-4. Most of these are real: the local exists but its money runs through the parent.
- 35,519 union-years (6.5%) have no member count at all; 31,448 are simplified reports. 16,830 have no receipts figure; 16,020 are simplified reports.
- So a zero can be a true zero, "handled elsewhere", or "not reported", and the file does not say which. A district full of simplified-report locals looks like it has no union members. This is the same no-action-versus-no-data distinction Assignment 3 asks for, showing up on the predictor side.
- Smaller items: 349 rows have negative assets or liabilities; liabilities are zero in 66% of rows and are not worth using as a predictor; 936 reports are dated after the union's recorded termination year.

## Problem 3 — coverage changes over time (Figure 3)

- Unions in the file fall from 26,673 in 2000 to 17,740 in 2024 (down 33%). That is mostly real decline and consolidation, so a district's union count trend mixes real change with reporting attrition.
- 632 unions filed for 2023 but have no 2024 report, against roughly 400 in a normal year. The newest year is the least complete, and it is the one we would use to predict next year. Late filers are the likely cause (reports for calendar 2024 were due in spring 2025).
- 10% of unions skip at least one year between their first and last report: 4,940 missing union-years, under 1% of the panel, mostly single years.

## Problem 4 — year-on-year swings are rare (Figure 2)

- Jumps of more than 10x between consecutive reports: 0.13% for members, 0.4% for assets, 0.5% for receipts, 1.1% for disbursements. About a third of the member jumps return to the old level the next year (errors); most of the rest persist (mergers, reorganisations). Keep this as a backup figure; Figure 1 and the flagged-row list make the point more sharply.

## Proposed fix rules (for the fix plan; each is a few lines of code)

1. Member spikes: where a count is more than 10x both neighbouring years (or the one neighbour at the edge of the panel), replace it with the average of the neighbouring years. Changes 276 rows. Cost: a genuine one-year surge would be flattened; no local gains 100x members for one year, so acceptable.
2. Zero members with positive receipts: treat as missing and carry the previous year's count forward (next year's if it is the first report). Changes 6,355 rows. Cost: assumes membership was flat that year.
3. Simplified reports and all-zero LM-4 reports: keep the union in the count of locals per district, set members and money to missing rather than zero, and add "locals with no financial data" as its own district column. Cost: understates members in districts with many such locals, by an amount we cannot know.
4. Negative money values become missing. Liabilities are not used.
5. Drop DC and the territories from the ranking; one sentence about DC in the limits.
6. Latest year: for a union that filed in both of the two prior years but not the latest, carry its last report forward one year and flag it. Cost: keeps a few dead unions alive for a year.

## Evidence the fix worked (part 4, to do after the rules are agreed)

- Redraw Figure 1 on the cleaned file: no orange points off the band.
- Before/after table of the top 20 districts by union members in 2020 and 2024: the error-driven districts disappear and the ranking is stable from year to year.

## Recommended submission

Figure 1, Table 1 and Figure 3, with `flagged_member_rows.csv` as an appendix. Figure 2 is a backup.

## Agent log entry (paste into docs/agent_log)

26 Oct 2026, Ed. Asked the agent to load `LM_data_2026_teaching.csv`, check structure (rows, duplicates, district codes, form types), run the four audit directions in the assignment, and draw the three figures. Agent ran four Python scripts (saved in `LM_audit/code_python/`), I reviewed every figure and the numbers above, and the agent wrote `01_lm_audit.R` for the repo. Open items: confirm what form code 5 is with the professor; run the R script once and check it reproduces the Python numbers; agree the six fix rules at Wednesday's meeting.
