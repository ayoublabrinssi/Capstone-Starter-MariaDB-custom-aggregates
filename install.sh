#!/bin/sh
# Installs the served_airports view and the median_agg, gini, mode_agg and
# wpercentile functions into the openflights database (flightdb2).
# Uses db.sh, so no password is needed here.
set -e
cd "$(dirname "$0")"
cat sql/*.sql | ./db.sh
echo "Installed: served_airports, median_agg, gini, mode_agg, wpercentile"
