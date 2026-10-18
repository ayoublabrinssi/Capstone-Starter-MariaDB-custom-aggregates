# Team IV weekly self-assessment

Capstone Project I. Starter: custom aggregate functions in MariaDB (area 2).
Repo: https://github.com/ayoublabrinssi/Capstone-Starter-MariaDB-custom-aggregates
Team: Ayoub Labrinssi, Shreyash Hadiya, Mohamed Saad Kchaou

Newest week first. Each contributor fills in their own hours, plan and AI tools.

## Week of 12 to 18 October 2026

### Ayoub Labrinssi
- **Work done:** merged Shreyash's PR #4, "Add wpercentile", into main. Prepared the starter presentation for the supervisor meeting.
- **Hours:** 5
- **Evidence:** Shreyash's [PR #4 Add wpercentile](https://github.com/ayoublabrinssi/Capstone-Starter-MariaDB-custom-aggregates/pull/4), merge commit 24d809c
- **Plan for next week:** open GitHub issues for the starter. Fix the README line "A built-in is always faster", which experiment 8 does not support. Report the `HAVING` error to MariaDB JIRA. Pick the main dish area with the team.
- **AI tools:** Claude (Anthropic), to check PR #4, prepare the meeting and draft this self-assessment. AI log entry 12.
- **Notes, blockers:** none.

### Shreyash Hadiya
### Shreyash Hadiya
- **Work done:** added `wpercentile(x, w, p)`, a weighted percentile, with before/after/check queries, 14 tests, changes to `install.sh` and `test.sh`, timing experiments 7 and 8, a README section and AI log entry 11. Set up Docker Desktop and the openflights database on Windows, and ran all tests and timings on my laptop (41 tests and 4 checks pass on MariaDB 12.3.3). Prepared a slide deck about my part for the supervisor meeting.
- **Hours:** 4
- **Evidence:** [PR #4 Add wpercentile](https://github.com/ayoublabrinssi/Capstone-Starter-MariaDB-custom-aggregates/pull/4), commits c5535d1, 7621e7c, 8ffc288, 20e1476, b8291f9, 0cd7874
- **Plan for next week:** choose the main dish area with the team. Time `wpercentile` across group sizes (100 to 20,000 rows), like experiment 4. Attend the weekly progress meeting.
- **AI tools:** Claude (Anthropic). It wrote the first versions of the function, queries, tests, experiments and README text, and helped with the Docker setup. I added every file myself, ran all tests and timings on my laptop and used my own numbers. Recorded in AI log entry 11.
- **Notes, blockers:** the Windows setup took time. The openflights loading script failed because Git changed the line endings, which I fixed by cloning with `core.autocrlf=false`. I had no write access to the repository, so I worked through a fork and PR #4.

### Mohamed Saad Kchaou
- **Work done:** no commits in the repo. Has not replied to the team and has not shown up.
- **Hours, plan, AI tools:** not known.

## Week of 5 to 11 October 2026

### Ayoub Labrinssi
- **Work done:**
  - Chose the starter (area 2) and set up openflights on MariaDB 12.3.3 with Colima.
  - `median_agg` with before/after/check queries, and the README with findings and charts (7 Oct).
  - `gini` with a hand-written comparison. Found the `INT / INT` DECIMAL rounding trap (10 Oct).
  - Experiments past the docs: the docs' median example (wrong with NULLs and decimals, fails when called twice), limits with `OVER`, `DISTINCT`, `HAVING` and views, 10-run timings, storage made 17 times faster, 27 tests, `install.sh` and `test.sh`.
  - `mode_agg` for text values, MIT license, contributing guide.
  - Cleaner code, code of conduct, issue and PR templates, new README.
  - AI log entries 1 to 10.
- **Hours:** 5
- **Evidence:** first commits 1f63450, 8f45508, fddfecf (7 Oct). [PR #1](https://github.com/ayoublabrinssi/Capstone-Starter-MariaDB-custom-aggregates/pull/1) (gini), [PR #3](https://github.com/ayoublabrinssi/Capstone-Starter-MariaDB-custom-aggregates/pull/3) (limits, speed, tests, mode_agg), [PR #2](https://github.com/ayoublabrinssi/Capstone-Starter-MariaDB-custom-aggregates/pull/2) (clean code, README), all merged 11 Oct.
- **Plan for next week:** start on the main dish, and make any changes the supervisor asks for on the starter.
- **AI tools:** Claude (Anthropic). AI log entries 1 to 10.
- **Notes, blockers:** the database runs in Colima (light Docker). The supervisor said the work was not enough, so this week went into depth: experiments, limits and speed.

### Shreyash Hadiya
- **Work done:** no commits in the repo this week.
- **Hours, plan, AI tools, notes:** no work on the starter this week. I did not attend the progress meetings in weeks 4 and 5 and did not contact the supervisor in time. I joined the starter on 12 October.

### Mohamed Saad Kchaou
- **Work done:** no commits in the repo. Has not replied to the team and has not shown up.
- **Hours, plan, AI tools:** not known.
