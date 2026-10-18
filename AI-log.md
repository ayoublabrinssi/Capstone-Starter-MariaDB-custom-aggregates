# AI log

I used Claude (Anthropic) as a helper on this starter. This file lists every use: what I asked for, what the AI made, and what I decided or checked myself. Prompts are copied with spelling and grammar fixed. The meaning is the same, and long ones are shortened with "...".

When the code changes, this log is updated so it still matches. New entries go at the bottom.

## My part

- I chose the topic and the plan: option A of the three starters (median and Gini aggregates on openflights).
- I set up the database on my Mac with Colima, because my Mac no longer supports Docker Desktop.
- I decided what to work on at each step, based on the supervisor's feedback and the MariaDB evaluation criteria.
- I approved each new piece before it was added: Gini, the depth experiments, `mode_agg` and the MIT license.
- I chose opensource.guide as the standard for how the repo is organized.
- Every change goes through a branch and a pull request, which I merge on GitHub.
- I prepared the meeting presentation with the material from entry 7.

## What the AI did

- Wrote first versions of the SQL functions, queries, tests, scripts and README text.
- Ran the experiments and timings on my local database and saved the results in `results/`.
- Searched MariaDB JIRA for the known bugs behind each limit.
- Cleaned up the code and added the open source files (entry 9).

## Summary

| # | Date | I asked for | AI made | What I decided or checked |
|---|---|---|---|---|
| 1 | 7 Oct | A starter I can do alone, based on the course files | 3 starter options and a step plan | Picked option A: median and Gini on openflights |
| 2 | 7 Oct | The first working piece, using Colima | `served_airports` view, `median_agg`, before/after/check queries, first README | Chose Colima for the database. The check query gives the same median as MariaDB's `MEDIAN()` for every country |
| 3 | 7 Oct | Charts in the README that explain the results | Chart query, 3 Mermaid charts, findings text | Kept the charts. Merged in PR #1 |
| 4 | 10 Oct | More depth, after the supervisor said the work was not enough | `gini` aggregate, hand-written version, check query. Found the INT/INT DECIMAL rounding trap | Added Gini, the second half of my plan. Merged in PR #1 |
| 5 | 10-11 Oct | Fix the gaps the MariaDB evaluation criteria showed | Experiments against the docs example and SQL features, 10-run timings, faster storage (about 17x at 10,000 rows), tests, `install.sh`, `test.sh` | Merged PR #1 first, then chose to work on depth. Branch `feat/limits` |
| 6 | 11 Oct | What was still missing before the meeting | `mode_agg` for text, 10 tests, timing, `LICENSE`, `CONTRIBUTING.md` | Approved `mode_agg` and the MIT license. Branch `feat/mode-agg` |
| 7 | 11 Oct | Animated material to present the work at the meeting | An animated page in English, an Arabic version for my own study and meeting notes (all outside the repo) | Used them to prepare and rehearse the talk |
| 8 | 11 Oct | A cleaner AI log in one file | This file, with my decisions in their own column | Checked that every line is true |
| 9 | 11 Oct | Clean, easy-to-read code, and a repo that follows opensource.guide | Shorter functions and comments, clearer `test.sh` output, tidier experiment headers, code of conduct, issue and PR templates, fuller CONTRIBUTING | Chose opensource.guide as the standard. Same results: 27 tests and 3 checks pass, same speed. Branch `refactor/clean-code` |
| 10 | 11 Oct | A more professional README that is easy to follow and shows the new code | New README layout: badges, contents, quick start, "How it works" with the current `median_agg` and a flow diagram, tests section, project tree, contributing and credits | Asked for it to be open source friendly. All numbers and findings unchanged. Branch `refactor/clean-code` |
| 11 | 12-14 Oct | A new aggregate I could add to this repo as my part of the project | `wpercentile` (weighted percentile), before/after/check queries, 14 tests, timing experiment 7, README text, and step-by-step instructions to add each file by hand | Chose the weighted percentile because the README's Contributing section asks for "a percentile or a weighted average". Added every file myself in VS Code. Ran `test.sh` on my laptop (MariaDB 12.3.3): 41 tests and 4 checks pass. Checked the US result myself (3 vs 196). Ran the timing on my own machine and used my numbers in the README. Branch `feat/wpercentile` |
| 12 | 15 Oct | Check my teammate's PR, prepare the meeting and write the weekly self-assessment | Notes on PR #4, a draft email to the supervisor and an updated meeting talk (both outside the repo), and a draft of `SELF-ASSESSMENT.md` | Merged PR #4 myself. Gave my hours, my real plan and the notes, and corrected the draft. Branch `docs/self-assessment` |

## Prompts

### 1. Starter choice

- Date: 2026-10-07, 13:45 (Morocco)
- Input files: Team Guide.pdf, Week 02 To-do.pdf, MariaDB project areas 2026-09.pdf, MariaDB Q&A 2026-09.pdf, mariadb.org/bachelor_hackathon_2026-09, github.com/mariadb/openflights

> We're going to work on the Capstone project. Read the course files and the MariaDB project areas, and suggest a starter I can do on my own. I'm working alone for now, so leave out the team instructions. Give me the steps and keep an AI log, as the to-do file asks.

Output:
- `Starter plan.md` (outside the repo): 3 options, option A recommended (median and Gini custom aggregates on openflights), 8 steps.
- The first entry of this log.

### 2. First working piece (median)

- Date: 2026-10-07, 13:49 (Morocco)

> Go with option A. Use Colima, it's already installed. My MacBook doesn't support Homebrew or Docker Desktop anymore.

Output:
- `sql/01_served_airports.sql`: view with routes per served airport.
- `sql/02_median_agg.sql`: `median_agg` with `CREATE AGGREGATE FUNCTION`.
- `queries/median_before.sql`, `queries/median_after.sql`, `queries/median_check.sql`.
- First draft of `README.md`.
- Test run: `median_check.sql` returned 0 rows (custom = built-in for all countries). Edge cases: (1, 3, 2, 10) gives 2.5, (5, NULL, 1) gives 3, (NULL) gives NULL.

### 3. README charts

- Date: 2026-10-07, 14:02 (Morocco)

> Okay, good. Make sure the README has some graphs that explain the data results.

Output:
- `queries/chart_data.sql`: the queries behind every chart.
- README: "Findings so far" and 3 Mermaid charts (median per country, mean vs median, airports by route count).

### 4. Gini aggregate

- Date: 2026-10-10, 23:43 (Morocco)

> The starter has to be complete by Thursday the 15th. The teacher says what we did is not enough. ... We have to finish the starter properly.

Output:
- `sql/03_gini.sql`: `gini` with `CREATE AGGREGATE FUNCTION`.
- `queries/gini_before.sql`, `queries/gini_after.sql`, `queries/gini_check.sql`.
- README: Gini finding, chart 4, before/after row, "A trap found on the way".
- Tests: `gini_check.sql` returned 0 rows. Edge cases: (1, 1, 1) gives 0, (0, 0, 0, 10) gives 0.75, (NULL) gives NULL, (0) gives NULL, (5) gives 0.

### 5. Limits, scale test, tests

- Date: 2026-10-10 and 2026-10-11 (Morocco)

> (Pasted the MariaDB project evaluation prompt.)
>
> Merged. Start on them now.

"Them" means the depth items from the evaluation: compare with the median example in the docs, test OVER, DISTINCT and large groups, timings with spread, a "when not to use" section, a tests file, an install script, the password in one variable.

Output:
- `experiments/01_docs_median.sql`: the docs' temp-table median next to ours.
- `experiments/02_limits.sql`: OVER, DISTINCT, HAVING, ROLLUP, empty set, text input.
- `experiments/03_view_subquery.sql`: aggregates in a view and in a correlated subquery.
- `experiments/04_scale.sql`: 10-run timing on groups of 100 to 20,000 rows.
- `experiments/05_faster_median.sql`: the first JSON version kept as `median_json`.
- `results/`: the output of each experiment.
- `sql/02_median_agg.sql`, `sql/03_gini.sql`: a text list instead of `JSON_ARRAY_APPEND` (same results, faster).
- `tests/tests.sql`, `test.sh`, `install.sh`.
- README: "Limits found", "Speed", "When not to use a custom aggregate".
- JIRA issues found by searching jira.mariadb.org for each limit.

### 6. mode_agg, license, contributing

- Date: 2026-10-11 (Morocco)

> What should I add to the starter, what is still missing, and what am I going to present at the next meeting?

(Claude listed what was missing and suggested `mode_agg` and an MIT license.)

> Yes, add what's needed and prepare what to present.

Output:
- `sql/04_mode_agg.sql`: `mode_agg`, the most common value, works on text. Ties go to the smallest value.
- `queries/mode_before.sql`, `queries/mode_after.sql`, `queries/mode_check.sql` (0 rows: same airline for all 225 countries).
- `tests/tests.sql`: 10 mode tests (ties, commas and quotes, Arabic text, case, NULL, empty).
- `experiments/06_mode_timing.sql` and `results/06_mode_timing.txt`: 5.2 s vs 0.44 s for the hand-written query.
- README: mode finding, before/after row, "Try it on your own table", license section.
- `LICENSE` (MIT), `CONTRIBUTING.md`.
- Meeting notes (outside the repo).

### 7. Presentation material

- Date: 2026-10-11 (Morocco)

> For the meeting, make me an animated page that shows what we have done, with the data and the technical side as easy animations that explain what the code does.

(Then asked for the same in Arabic, to go through the code in my own language.)

Output:
- An animated page in English: mean vs median, how `median_agg` runs row by row, Gini, mode, limits, speed, tests.
- An Arabic version for my own study, with a step-by-step run on the Moroccan airports.
- Both are outside the repo. They are presentation and study material, not part of the product.

### 8. AI log in one file

- Date: 2026-10-11 (Morocco)

Summary of the request: check the AI log, make it cleaner and easier to read, and keep all past and future prompts in one file.

Output:
- This file. It replaces `ai-log/AI-use log.md` and the 6 files in `ai-log/prompts/` (still in the git history).
- README and CONTRIBUTING now point here.

### 9. Clean code and open source practices

- Date: 2026-10-11 (Morocco)

> Now clean the code of anything unneeded. Make it clean code that is easy to follow, read and debug, and to the point.
>
> Make sure that our code respects https://opensource.guide.

Output:
- `sql/02` to `sql/04`: shorter header comments, a comment on each variable, the handler returns its result directly, the comma rule written once (`IF(n = 0, '', ',')`). Same logic and results.
- `test.sh`: runs the tests once instead of twice, prints one line per test, and shows got and expected for a failing test.
- `experiments/`: the same Run line format in every file; the summary query in `04_scale.sql` is no longer commented out.
- From the opensource.guide checklist: `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), issue templates for bugs and features, a pull request template, a fuller `CONTRIBUTING.md` (what help is wanted, how to suggest a feature, how to run the tests, where to ask), and a status and help section in the README.
- Checked: `./test.sh` passes (27 tests, 3 checks), `experiments/05` checks give 0 differences, timing at 10,000 rows is the same (about 0.6 s).

### 10. README for open source

- Date: 2026-10-11 (Morocco)

> Update the README with the new code so it looks professional, is easy to follow, and is good for open source contributors.

Output:
- `README.md`: badges, a contents list, "The functions" table with links to the source, "Quick start", "How it works" (flow diagram and the current `median_agg` code), a "Tests" section with sample `test.sh` output, a short before/after example for `mode_agg`, a project tree, "Contributing" and "License and credits". Findings, charts and timings are the same numbers as before.
- `CONTRIBUTING.md`: the setup link now points to "Quick start".

### 11. wpercentile (by Shreyash Hadiya)

- Date: 2026-10-12, 23:00 to 2026-10-14 (Germany)
- Input: this repository, mariadb.org/bachelor_hackathon_2026-09

> I am working with my friend, so I have to add my own work. What do I have to add in his repo?
>
> Can you help me add this in VS Code manually, step by step, so I know what I am adding?

Output:
- `sql/05_wpercentile.sql`: `wpercentile(x, w, p)` with `CREATE AGGREGATE FUNCTION`. Collects `[value, weight]` pairs, then returns the first value where the running total of weights reaches `p` times the sum.
- `queries/wpercentile_before.sql`, `queries/wpercentile_after.sql`, `queries/wpercentile_check.sql` (checked at p = 0.1, 0.5 and 0.9).
- `tests/tests.sql`: 14 tests (weights of 1, a heavy row, p = 0 and 1, zero, negative and NULL weights, p out of range, empty group, 1,999 random rows against `MEDIAN()`, the US result).
- `experiments/07_wpercentile_timing.sql`: 10-run timing against the window-function query.
- `test.sh`, `install.sh`: the new check and function added.
- README: function row, "How it works" line, finding, before/after row, test counts, speed bullet, credits.
- Help setting up Docker Desktop on Windows, including a line-ending problem (`\r`) that stopped the openflights loading script. Fixed by cloning openflights with `core.autocrlf=false`.
- `experiments/08_wpercentile_vs_builtin.sql`: timing against the built-in `PERCENTILE_DISC` (same answers with weights = 1), added after my teammate asked for a comparison with a native function.

What I did and checked myself:
- Typed or pasted each file into VS Code and committed in steps on my own branch.
- `./test.sh`: all 41 tests and 4 checks pass on MariaDB 12.3.3 (Docker Desktop, Windows).
- Ran `wpercentile_after.sql`: the median US airport has 3 routes, but half of US routes leave from airports with 196 routes or more.
- Ran experiment 7 on my laptop (Ryzen 5 5500U, 8 GB RAM): 236 ms vs 192 ms on small groups, 1.7 s vs 0.82 s on large groups, 0 mismatches. Saved in `results/07_wpercentile_timing.txt`.
- Ran experiment 8 on my laptop: 211 vs 247 ms (small), 1.7 vs 1.8 s (large), 0 mismatches.

### 12. Teammate's PR, meeting and self-assessment

- Date: 2026-10-15 (Morocco)
- Input: this repository, `Team Guide.pdf` (the self-assessment fields)

> Go to the capstone project. My teammate said he did something. See if he created a PR, and should I prepare emails to the teacher or just wait for the meeting and present the work?
>
> What should I present to the teacher at the meeting?
>
> Let's write the weekly self-assessment.

Output:
- A summary of PR #4: what it adds, that it merges cleanly, and two small README fixes for later. The AI read the code but did not run the tests.
- A draft email to the supervisor (outside the repo).
- The meeting talk updated with `wpercentile`, Shreyash's part and a list of GitHub issues to open (outside the repo).
- `SELF-ASSESSMENT.md`: the fields from the Team Guide, filled from the git history for the weeks of 5 and 12 October.

What I did and checked myself:
- Merged PR #4 on GitHub.
- Gave my hours, my plan for next week and the notes, and corrected the draft where it was wrong.
- Chose to keep the self-assessment in the repo, next to this log.

## Adding a new entry

1. Add a row to the Summary table.
2. Add a section under Prompts with the date, the prompt and the output.
3. Commit it together with the change the AI helped with.
