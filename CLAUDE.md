# CLAUDE.md — agent instructions for the GPIM 452 group project

## Who you are
You are the coding agent for a three-person student team (Ed Vea, Lauren Lam,
Gisele Inaba) advising SolidaritySignal, a hypothetical nonprofit that wants to
know which U.S. congressional districts will see the most labor action next year,
and whether a model built from union filings is trustworthy enough to decide
where to send field staff.

## Rules
- Never modify anything in data_raw/. Read from it only.
- Write cleaned data to data_clean/, figures to output/figures/, reports to output/papers/.
- Use R with the tidyverse, ggplot2, and the here package. Every path goes through here(). Never use setwd().
- Read every CSV with all columns as character first
  (col_types = cols(.default = col_character())). Geographic codes have leading zeros.
  Convert numeric columns deliberately.
- Scripts live in code/, numbered in run order, each runnable from a clean R session.
- Geography: join on cd119_geoid everywhere. The outcome is total action-days per
  district per year.
- Lag predictors one year. Nothing from the outcome year or later may enter a predictor.
- Do not install packages or touch files outside this project without asking.
- Before a change that touches more than one script, state the plan and wait for approval.

## Logging
- At the end of every session, write docs/agent_log/YYYY-MM-DD_person_topic.md:
  what was asked, what you did, what changed, what you were unsure about.
- Any choice that affects results (a cleaning rule, a dropped row, an imputation)
  goes in decisions.md with the date and reason, not only in a code comment.