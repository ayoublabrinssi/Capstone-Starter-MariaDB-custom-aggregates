#!/bin/sh
# Runs the edge-case tests and the 4 check queries. Run ./install.sh first.
# Prints one line per test. A failing test shows what it got and expected.
# Exits with 1 if anything fails.
cd "$(dirname "$0")"
db() { ./db.sh -N; }

# 1. Edge cases: one row per test, columns: test, got, expected, pass (1 or 0).
results=$(db < tests/tests.sql) || exit 1
echo "$results" | awk -F'\t' '{ if ($NF == 1) print "ok    " $1; else print "FAIL  " $1 "  got: " $2 "  expected: " $3 }'
failed=$(echo "$results" | awk -F'\t' '$NF != 1 { n++ } END { print n + 0 }')

# 2. Whole-data checks: each query lists the countries where the two versions differ.
for check in queries/median_check.sql queries/gini_check.sql queries/mode_check.sql queries/wpercentile_check.sql; do
  diff=$(db < "$check") || exit 1
  if [ -z "$diff" ]; then
    echo "ok    $check"
  else
    echo "FAIL  $check, countries that differ:"
    echo "$diff"
    failed=$((failed + 1))
  fi
done

if [ "$failed" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$failed test(s) failed."
  exit 1
fi
