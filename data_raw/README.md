# data_raw

Raw data exactly as received. **Never edit, rename, or overwrite anything in this folder.**
Scripts in `code/` read from here and write their results to `data_clean/`.

Git does not track these files (see `.gitignore`), so they are not in the GitHub repo.
Download them from the team Google Drive folder and drop them in here:

https://drive.google.com/open?id=1uvQNQAWg7KcdpQxqadwHXggVU2CjV9ww&usp=drive_fs

## Files

| File | What it is | Source |
| --- | --- | --- |
| `LAT_2026_train.csv` | Labor Action Tracker: one row per labor action, Sept 2021 to Sept 2025, with dates, duration, location, and district. Builds the outcome. | Course project data (Cornell ILR / Illinois LER) |
| `LAT_codebook_simple.md` | Column definitions for the tracker file | Course project data |
| `LAT data extra information.docx` | Tracker authors' notes on coverage, duration, and multi-site actions | Course project data |
| `<LM file name once posted>` | Union annual reports, 2000–2024: one row per union per year, with membership, finances, and address | Course project data (U.S. Department of Labor) |
| `LM_codebook_simple.md` | Column definitions for the union file | Course project data |
| `county_data.csv`, `acs_lab_5vars.csv` | County-level demographics from the course homework | Census Bureau via course |
| `rtw.csv`, `governor_partisanship.csv` | State-level right-to-work status and governor party | Course homework |

## Rules

- Read every file with all columns as character first; FIPS and district codes have leading zeros.
- If a file is updated on Drive (the instructor said the tracker gets a newer year later),
  download the new version, keep the old one with a date suffix, and note the change in `decisions.md`.
- Anything you derive from these files goes in `data_clean/`, produced by a script, never by hand.