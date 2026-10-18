#!/bin/sh
# Runs every experiment again and saves its output, so the results can be
# checked on another machine. Run ./install.sh first.
# Takes about 10 minutes: experiment 4 at 10,000 rows is the slow part.
#
#   ./run_experiments.sh            writes to results/
#   ./run_experiments.sh my-run     writes to my-run/ and leaves results/ alone
#
# Timings depend on the machine. Compare the ratios, not the milliseconds.
set -e
cd "$(dirname "$0")"
OUT="${1:-results}"
mkdir -p "$OUT"

run() {  # run <experiment> <client options>
  name="$1"; shift
  echo "experiment $name"
  ./db.sh "$@" < "experiments/$name.sql" > "$OUT/$name.txt" 2>&1 || true
}

run 01_docs_median --force -t -v
run 02_limits --force -t -v
run 03_view_subquery --force -t -v
run 05_faster_median -t -v

# Experiment 4 needs medi_int (experiment 1) and median_json (experiment 5).
# Load it, time each size, then load it again to print the summary.
echo "experiment 04_scale"
./db.sh < experiments/04_scale.sql > /dev/null
for n in 100 1000 5000 10000; do echo "CALL run_bench($n, 10, TRUE);"; done | ./db.sh
echo "CALL run_bench(20000, 10, FALSE);" | ./db.sh
./db.sh -t < experiments/04_scale.sql > "$OUT/04_scale.txt"

run 06_mode_timing -t
run 07_wpercentile_timing -t
run 08_wpercentile_vs_builtin -t
run 09_before_after -t
run 10_oracle_mode -t -v

# Experiment 11 starts its own server, with binary logging on.
echo "experiment 11_binary_log"
./experiments/11_binary_log.sh > "$OUT/11_binary_log.txt" 2>&1 || true

# Query length, before and after: SQL lines and words, comments and blank lines left out.
echo "query length"
{
  printf '%-12s %-7s %5s %5s\n' function version lines words
  for f in median gini mode wpercentile; do
    for v in before after; do
      body=$(grep -v '^ *--' "queries/${f}_$v.sql" | grep -v '^ *$')
      printf '%-12s %-7s %5s %5s\n' "$f" "$v" "$(echo "$body" | wc -l | tr -d ' ')" "$(echo "$body" | wc -w | tr -d ' ')"
    done
  done
} > "$OUT/09_query_length.txt"

echo "Done. Output in $OUT/"
