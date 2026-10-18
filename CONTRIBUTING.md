# Contributing

Thanks for taking a look. Small help is welcome: a bug report, a new test, a clearer sentence in the README.

Please follow the [code of conduct](CODE_OF_CONDUCT.md).

## What would help most
- New aggregates, for example a percentile or a weighted average.
- More edge-case tests in `tests/tests.sql`.
- Results on other MariaDB versions.
- Fixes to the docs and the README.

## Report a bug
Open an issue with:
- the query you ran,
- what you got and what you expected,
- your MariaDB version (`SELECT VERSION();`).

## Suggest a feature
Open an issue that says what you want to compute and show a query you would like to write.

## Set up and run the tests
Follow [Quick start](README.md#quick-start) in the README, then:

```sh
./install.sh
./test.sh
```

`test.sh` prints one line per test. A failing test shows what it got and what it expected.

## Change something
1. Open an issue first so we can agree on the change.
2. Make a branch from `main`, e.g. `feat/percentile-agg` or `fix/mode-ties`.
3. Run `./install.sh` and `./test.sh`. All tests must pass.
4. Open a pull request that links the issue.

## Add a new aggregate
- Put it in `sql/` with the next number, e.g. `sql/06_percentile_agg.sql`.
- Start the file with a comment: what it returns, how NULLs, empty groups and ties are handled.
- Follow the pattern of the existing functions: collect the values in the loop, compute in the NOT FOUND handler.
- Add a before/after/check query in `queries/` like the existing ones.
- Add edge cases to `tests/tests.sql`.
- Add a row to the function table in the README.

## Questions
Open an issue. For general MariaDB questions, the [MariaDB Zulip](https://mariadb.zulipchat.com/) is the best place.

## AI use
If you use an AI tool, add an entry to `AI-log.md` (see "Adding a new entry" at the end of it).
