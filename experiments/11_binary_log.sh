#!/bin/sh
# Experiment 11: installing the functions on a server with binary logging.
# Replication and point-in-time backups need the binary log. With it on,
# MariaDB only creates a stored function that is declared DETERMINISTIC,
# NO SQL or READS SQL DATA, and only for a user with SUPER, unless
# log_bin_trust_function_creators is on.
#
# Starts a throwaway MariaDB with --log-bin, runs four cases, then removes it:
#   1. median_agg without DETERMINISTIC (as it was before), as root
#   2. the four functions from sql/, as root
#   3. the four functions, as a user without SUPER
#   4. case 3 again with log_bin_trust_function_creators = 1
# The passwords are random and stay inside the container.
#
# Run: experiments/11_binary_log.sh > results/11_binary_log.txt
set -e
cd "$(dirname "$0")/.."
NAME=mariadb-binlog-test
VERSION="${MARIADB_VERSION:-12.3.3}"

trap 'docker rm -f "$NAME" > /dev/null 2>&1' EXIT
docker rm -f "$NAME" > /dev/null 2>&1 || true
docker run -d --name "$NAME" \
  -e MARIADB_ROOT_PASSWORD="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')" \
  -e MARIADB_DATABASE=agg -e MARIADB_USER=app \
  -e MARIADB_PASSWORD="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')" \
  "mariadb:$VERSION" --log-bin=mysql-bin > /dev/null
until docker exec "$NAME" healthcheck.sh --connect --innodb_initialized > /dev/null 2>&1; do
  sleep 1
done

as_root() {  # as_root <client options>
  docker exec -i "$NAME" sh -c 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot --skip-print-query-on-error agg "$@"' sh "$@" 2>&1 || true
}
as_app() {
  docker exec -i "$NAME" sh -c 'MYSQL_PWD="$MARIADB_PASSWORD" exec mariadb -uapp --skip-print-query-on-error agg "$@"' sh "$@" 2>&1 || true
}
functions() {
  cat sql/02_median_agg.sql sql/03_gini.sql sql/04_mode_agg.sql sql/05_wpercentile.sql
}
use_them() {
  cat <<'SQL'
CREATE OR REPLACE TABLE t (g INT, x DOUBLE, s VARCHAR(5));
INSERT INTO t VALUES (1, 1, 'a'), (1, 2, 'a'), (1, 10, 'b'), (2, 3, 'c');
SELECT g, median_agg(x), gini(x), mode_agg(s), wpercentile(x, 1, 0.5) FROM t GROUP BY g;
SQL
}
drop_them() {
  echo 'DROP FUNCTION median_agg; DROP FUNCTION gini; DROP FUNCTION mode_agg; DROP FUNCTION wpercentile;'
}

echo "== Server"
echo 'SELECT VERSION() AS version, @@log_bin AS log_bin, @@binlog_format AS binlog_format, @@log_bin_trust_function_creators AS trust_function_creators;' | as_root -t

echo
echo "== 1. median_agg without DETERMINISTIC, as root"
sed 's/ DETERMINISTIC$//' sql/02_median_agg.sql | as_root

echo
echo "== 2. The four functions from sql/, as root"
functions | as_root
use_them | as_root -t
echo "SELECT name, aggregate, is_deterministic FROM mysql.proc WHERE db = 'agg' ORDER BY name;" | as_root -t
drop_them | as_root

echo
echo "== 3. The four functions, as a user without SUPER"
echo "SELECT CURRENT_USER() AS user, (SELECT COUNT(*) FROM information_schema.USER_PRIVILEGES WHERE PRIVILEGE_TYPE = 'SUPER') AS has_super;" | as_app -t
functions | as_app

echo
echo "== 4. Case 3 with log_bin_trust_function_creators = 1"
echo 'SET GLOBAL log_bin_trust_function_creators = 1;' | as_root
functions | as_app
use_them | as_app -t
