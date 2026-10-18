#!/bin/sh
# Opens the mariadb client inside the openflights container, on flightdb2.
# The root password is read inside the container from MARIADB_ROOT_PASSWORD,
# which the openflights compose file sets, so it is not stored in this repo.
#
#   scripts/db.sh                                 interactive prompt
#   scripts/db.sh < queries/median/after.sql      run one file
#   scripts/db.sh -t < experiments/06_mode_timing.sql    with extra client options
#
# Other container or database: CONTAINER=name DB=name scripts/db.sh
CONTAINER="${CONTAINER:-openflights-mariadb}"
DB="${DB:-flightdb2}"

if [ -t 0 ]; then tty="-it"; else tty="-i"; fi
exec docker exec $tty "$CONTAINER" \
  sh -c 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot "$@"' sh "$DB" "$@"
