-- Experiment 9: each function against the query you would write without it,
-- 10 runs each, all on the same machine and the same data.
-- The queries are the ones in queries/*/before.sql and after.sql, without
-- the ORDER BY and LIMIT 15 that are only there for display. Every country is
-- computed, so both sides do the full job.
-- Query length (lines and words) is counted by scripts/run_experiments.sh.
-- Run:
--   scripts/db.sh -t < experiments/09_before_after.sql

CREATE TABLE IF NOT EXISTS before_after_bench (fn VARCHAR(12), version VARCHAR(30), run INT, ms DOUBLE);
TRUNCATE before_after_bench;

DELIMITER //
CREATE OR REPLACE PROCEDURE run_before_after_bench(p_runs INT)
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE t0 DATETIME(6);
  DECLARE c INT;
  WHILE i <= p_runs DO
    -- median
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT DISTINCT country,
             COUNT(*)       OVER (PARTITION BY country) AS airports,
             MEDIAN(routes) OVER (PARTITION BY country) AS median_routes
      FROM served_airports) AS x;
    INSERT INTO before_after_bench VALUES ('median', 'before: MEDIAN() OVER', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, COUNT(*) AS airports, median_agg(routes) AS median_routes
      FROM served_airports GROUP BY country) AS x;
    INSERT INTO before_after_bench VALUES ('median', 'after: median_agg', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    -- gini
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, COUNT(*) AS airports,
             2 * SUM(rn * routes) / CAST(COUNT(*) * SUM(routes) AS DOUBLE)
               - (COUNT(*) + 1) / CAST(COUNT(*) AS DOUBLE) AS gini
      FROM (SELECT country, routes,
                   ROW_NUMBER() OVER (PARTITION BY country ORDER BY routes) AS rn
            FROM served_airports) AS ranked
      GROUP BY country) AS x;
    INSERT INTO before_after_bench VALUES ('gini', 'before: formula by hand', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, COUNT(*) AS airports, gini(routes) AS gini
      FROM served_airports GROUP BY country) AS x;
    INSERT INTO before_after_bench VALUES ('gini', 'after: gini', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    -- mode
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, airline, routes
      FROM (SELECT a.country, al.name AS airline, COUNT(*) AS routes,
                   ROW_NUMBER() OVER (PARTITION BY a.country ORDER BY COUNT(*) DESC, al.name) AS rn
            FROM routes r
            JOIN airports a ON a.apid = r.src_apid
            JOIN airlines al ON al.alid = r.alid
            GROUP BY a.country, al.name) AS ranked
      WHERE rn = 1) AS x;
    INSERT INTO before_after_bench VALUES ('mode', 'before: ROW_NUMBER()', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT a.country, mode_agg(al.name) AS top_airline, COUNT(*) AS all_routes
      FROM routes r
      JOIN airports a ON a.apid = r.src_apid
      JOIN airlines al ON al.alid = r.alid
      GROUP BY a.country) AS x;
    INSERT INTO before_after_bench VALUES ('mode', 'after: mode_agg', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    -- weighted median
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, MAX(airports) AS airports, MIN(routes) AS median_route_airport
      FROM (SELECT country, routes,
                   COUNT(*)    OVER (PARTITION BY country) AS airports,
                   SUM(routes) OVER (PARTITION BY country ORDER BY routes ROWS UNBOUNDED PRECEDING) AS running,
                   SUM(routes) OVER (PARTITION BY country) AS total
            FROM served_airports) AS t
      WHERE running >= 0.5 * total
      GROUP BY country) AS x;
    INSERT INTO before_after_bench VALUES ('wpercentile', 'before: window sums', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, COUNT(*) AS airports, wpercentile(routes, routes, 0.5) AS median_route_airport
      FROM served_airports GROUP BY country) AS x;
    INSERT INTO before_after_bench VALUES ('wpercentile', 'after: wpercentile', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

CALL run_before_after_bench(10);

-- Median time of the 10 runs, with the fastest and slowest run.
SELECT fn, version, COUNT(*) AS runs, ROUND(median_agg(ms), 1) AS median_ms,
       ROUND(MIN(ms), 1) AS min_ms, ROUND(MAX(ms), 1) AS max_ms
FROM before_after_bench
GROUP BY fn, version
ORDER BY FIELD(fn, 'median', 'gini', 'mode', 'wpercentile'), version DESC;
