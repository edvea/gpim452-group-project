# 02_lm_audit.R
# What:   Audit of the union annual-report (LM) panel before it is used for predictors.
#         Three figures and three tables; changes no data.
# Reads:  data_raw/LM_data_2026_teaching.csv
# Writes: output/figures/fig1_members_vs_receipts.png
#         output/figures/fig2_year_on_year_change.png
#         output/figures/fig3_unions_by_year.png
#         output/tables/member_spikes.csv
#         output/tables/unions_by_year.csv
#         output/tables/problem_rows_by_form.csv
# Who:    Ed Vea with the coding agent, 26 Oct 2026

library(tidyverse)
library(here)
library(scales)

dir.create(here("output", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output", "tables"),  recursive = TRUE, showWarnings = FALSE)

# Chart colours: muted grey for context, blue and orange for the series that matter
grey   <- "#898781"
ink2   <- "#52514e"
blue   <- "#2a78d6"
orange <- "#eb6834"
theme_set(theme_minimal(base_size = 11) +
            theme(panel.grid.minor = element_blank(),
                  panel.grid.major = element_line(colour = "#e1e0d9", linewidth = 0.3),
                  axis.text = element_text(colour = ink2),
                  plot.caption = element_text(colour = grey, hjust = 0),
                  plot.title.position = "plot",
                  plot.background = element_rect(fill = "#fcfcfb", colour = NA)))

# ---- Load: every column as text first, then convert the numeric columns ----
num_vars <- c("members", "TTL_ASSETS", "TTL_LIABILITIES", "TTL_RECEIPTS", "TTL_DISBURSEMENTS")

lmd <- read_csv(here("data_raw", "LM_data_2026_teaching.csv"),
                col_types = cols(.default = col_character()),
                na = c("", "NA"), show_col_types = FALSE) |>
  mutate(across(all_of(num_vars), as.numeric),
         year = as.integer(year)) |>
  arrange(id, year)

cat("rows:", nrow(lmd), "| unions:", n_distinct(lmd$id),
    "| years:", min(lmd$year), "-", max(lmd$year),
    "| duplicate union-years:", sum(duplicated(lmd[c("id", "year")])), "\n\n")

# Neighbouring years within a union. A neighbour only counts if it is the
# adjacent calendar year, so a union with a gap in its filings has no neighbour there.
change_vars <- c("members", "TTL_RECEIPTS", "TTL_ASSETS", "TTL_DISBURSEMENTS")
lmd <- lmd |>
  group_by(id) |>
  mutate(gap_prev = year - lag(year),
         gap_next = lead(year) - year,
         across(all_of(change_vars),
                list(prev = ~ if_else(gap_prev == 1, lag(.x),  NA_real_),
                     nxt  = ~ if_else(gap_next == 1, lead(.x), NA_real_)),
                .names = "{.col}_{.fn}")) |>
  ungroup()

# ---- (1) Members vs receipts, highlighting one-year member spikes ----
# Spike: members more than 10x the same union's count in every neighbouring year
# that is usable (an adjacent-year report with members > 0). With two usable
# neighbours both must be exceeded; with one (panel edges, filing gaps) that one
# must be; with none the row is not flagged. See decisions.md, 2026-10-26.
lmd <- lmd |>
  mutate(prev_ok = coalesce(members_prev > 0, FALSE),
         nxt_ok  = coalesce(members_nxt > 0, FALSE),
         neighbours_used = prev_ok + nxt_ok,
         member_spike = neighbours_used > 0 & coalesce(members > 0, FALSE) &
           (!prev_ok | members > 10 * members_prev) &
           (!nxt_ok  | members > 10 * members_nxt))

spikes <- lmd |>
  filter(member_spike) |>
  select(id, UNION_NAME, UNIT_NAME, state, fipstate_cd119, year, FORM,
         members_prev, members, members_nxt, neighbours_used, TTL_RECEIPTS) |>
  arrange(desc(members))
write_csv(spikes, here("output", "tables", "member_spikes.csv"))

plottable <- lmd |> filter(members > 0, TTL_RECEIPTS > 0)
cat("Fig 1: union-years plotted (members > 0 and receipts > 0):", nrow(plottable),
    "| left out (zero, negative or missing on either):", nrow(lmd) - nrow(plottable), "\n")
cat("Member spikes (>10x every usable neighbouring year):", nrow(spikes),
    "in", n_distinct(spikes$id), "unions\n")
print(count(spikes, neighbours_used))
print(head(spikes, 10), width = Inf)

fig1 <- ggplot(plottable, aes(TTL_RECEIPTS, members)) +
  geom_point(data = filter(plottable, !member_spike),
             colour = grey, alpha = 0.06, size = 0.3, stroke = 0) +
  geom_point(data = filter(plottable, member_spike),
             colour = "#fcfcfb", fill = orange, shape = 21, size = 1.8, stroke = 0.4) +
  scale_x_log10(labels = label_dollar(scale_cut = cut_short_scale())) +
  scale_y_log10(labels = label_number(scale_cut = cut_short_scale())) +
  labs(title = "Reported members against reported receipts, every union-year",
       subtitle = sprintf("Orange: %s union-years with members more than 10x the same union's count in each neighbouring year on file",
                          comma(sum(plottable$member_spike))),
       x = "Total receipts (log scale)", y = "Members (log scale)",
       caption = sprintf("%s union-years with zero, negative or missing members or receipts cannot be shown on log scales and are left out.",
                         comma(nrow(lmd) - nrow(plottable))))
ggsave(here("output", "figures", "fig1_members_vs_receipts.png"), fig1,
       width = 9, height = 6.5, dpi = 200)

# ---- (2) Year-on-year change within each union ----
# Change = log10(this year / previous year), adjacent years only, both values positive.
# 1 means a tenfold rise, -1 a fall to a tenth.
changes <- lmd |>
  select(id, year, all_of(change_vars), all_of(paste0(change_vars, "_prev"))) |>
  rename_with(~ paste0(.x, "_now"), all_of(change_vars)) |>
  pivot_longer(-c(id, year), names_to = c("variable", ".value"),
               names_pattern = "^(.*)_(now|prev)$") |>
  filter(!is.na(prev)) |>
  mutate(change = log10(if_else(now > 0 & prev > 0, now / prev, NA_real_)),
         variable = factor(variable, levels = change_vars,
                           labels = c("Members", "Receipts", "Assets", "Disbursements")))

change_summary <- changes |>
  group_by(variable) |>
  summarise(pairs = n(),
            not_computable = sum(is.na(change)),
            median = median(change, na.rm = TRUE),
            share_over_10x_up   = mean(change > 1,  na.rm = TRUE),
            share_over_10x_down = mean(change < -1, na.rm = TRUE),
            beyond_plot = sum(abs(change) > 3, na.rm = TRUE))
cat("\nFig 2: year-on-year change (log10 ratio) by variable\n")
print(change_summary, width = Inf)

fig2 <- changes |>
  filter(!is.na(change)) |>
  mutate(change = pmin(pmax(change, -3), 3)) |>
  ggplot(aes(change)) +
  geom_histogram(binwidth = 0.05, boundary = 0, fill = blue, colour = NA) +
  geom_vline(xintercept = c(-1, 1), colour = orange, linewidth = 0.4, linetype = "dashed") +
  facet_wrap(~ variable, ncol = 2) +
  scale_x_continuous(breaks = -3:3,
                     labels = c("≤1/1000", "1/100", "1/10", "same", "10x", "100x", "≥1000x")) +
  scale_y_sqrt(labels = comma) +
  labs(title = "Year-on-year change within each union",
       subtitle = "This year's value divided by the same union's value the year before; dashed lines mark a tenfold change",
       x = "Ratio to previous year (log scale)", y = "Union-years (square-root scale)",
       caption = "Adjacent years only, both values positive. Changes beyond 1000x either way are piled into the end bins.") +
  theme(strip.text = element_text(face = "bold", hjust = 0),
        panel.spacing.x = unit(2, "lines"))
ggsave(here("output", "figures", "fig2_year_on_year_change.png"), fig2,
       width = 9, height = 6.5, dpi = 200)

# ---- (3) Unions reporting each year, and first and last reports ----
spans <- lmd |> group_by(id) |> summarise(first = min(year), last = max(year))
by_year <- lmd |>
  count(year, name = "unions_reporting") |>
  left_join(count(spans, year = first, name = "first_report"), by = "year") |>
  left_join(count(spans, year = last,  name = "last_report"),  by = "year") |>
  mutate(across(c(first_report, last_report), ~ replace_na(.x, 0L)))
write_csv(by_year, here("output", "tables", "unions_by_year.csv"))
cat("\nTable: unions by year (first report in 2000 and last report in 2024 are the panel edges, not real entries or exits)\n")
print(by_year, n = Inf)

# The panel edges are dropped from the plot: every union already filing in 2000
# looks like a "first report", every union still filing in 2024 like a "last report".
fig3_data <- bind_rows(
  by_year |> transmute(year, panel = "Unions filing a report", series = "Filing", n = unions_reporting),
  by_year |> filter(year > min(year)) |>
    transmute(year, panel = "Entries and exits", series = "First report", n = first_report),
  by_year |> filter(year < max(year)) |>
    transmute(year, panel = "Entries and exits", series = "Last report", n = last_report)) |>
  mutate(panel = factor(panel, levels = c("Unions filing a report", "Entries and exits")))

fig3 <- ggplot(fig3_data, aes(year, n, colour = series)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.4) +
  geom_text(data = fig3_data |> group_by(series) |> slice_max(year, n = 1) |> ungroup(),
            aes(label = series), hjust = 0, nudge_x = 0.4, size = 3.3, colour = ink2) +
  facet_wrap(~ panel, ncol = 1, scales = "free_y") +
  scale_colour_manual(values = c("Filing" = ink2, "First report" = blue, "Last report" = orange)) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  scale_x_continuous(breaks = seq(2000, 2024, 4), expand = expansion(add = c(0.5, 3))) +
  labs(title = "Unions filing each year, and how many file for the first or last time",
       x = NULL, y = "Unions", colour = NULL,
       caption = "First reports in 2000 and last reports in 2024 are not shown: they mark the edges of the panel, not entries or exits.") +
  theme(legend.position = "top", legend.justification = "left",
        strip.text = element_text(face = "bold", hjust = 0))
ggsave(here("output", "figures", "fig3_unions_by_year.png"), fig3,
       width = 9, height = 6.5, dpi = 200)

# ---- (4) Zero, missing and contradictory values, by FORM ----
flags <- lmd |>
  transmute(FORM,
            zero_members_positive_receipts = members == 0 & TTL_RECEIPTS > 0,
            positive_members_zero_receipts = members > 0 & TTL_RECEIPTS == 0,
            missing_members  = is.na(members),
            missing_receipts = is.na(TTL_RECEIPTS),
            negative_assets_or_liabilities = coalesce(TTL_ASSETS < 0, FALSE) |
              coalesce(TTL_LIABILITIES < 0, FALSE)) |>
  mutate(across(-FORM, ~ coalesce(.x, FALSE)))

problem_table <- flags |>
  group_by(FORM) |>
  summarise(rows = n(), across(everything(), sum)) |>
  bind_rows(summarise(flags, FORM = "All", rows = n(), across(-FORM, sum)))
write_csv(problem_table, here("output", "tables", "problem_rows_by_form.csv"))
cat("\nTable: union-years with zero, missing or contradictory values, by FORM\n")
print(problem_table, width = Inf)

cat("\nDone. Figures in output/figures, tables in output/tables.\n")
