-- Experiment 7: wpercentile vs the hand-written window-function query, 10 runs each.
--   small: route-weighted median per country on served_airports
--          (3,211 rows, 225 groups, biggest group 550 rows)
--   large: the same weighted median, but one input row per route
--          (67,663 rows, 225 groups, biggest group 13,056 rows), each row weight 1
-- Run:
--   scripts/db.sh -t < experiments/07_wpercentile_timing.sql

CREATE TABLE IF NOT EXISTS wpct_bench (workload VARCHAR(10), method VARCHAR(30), run INT, ms DOUBLE);
TRUNCATE wpct_bench;

DELIMITER //
CREATE OR REPLACE PROCEDURE run_wpct_bench(p_runs INT)
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE t0 DATETIME(6);
  DECLARE c INT;
  WHILE i <= p_runs DO
    -- small, custom aggregate
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, wpercentile(routes, routes, 0.5) AS wm
      FROM served_airports GROUP BY country) AS x;
    INSERT INTO wpct_bench VALUES ('small', 'wpercentile', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    -- small, window functions
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, MIN(routes) AS wm FROM (
        SELECT country, routes,
               SUM(routes) OVER (PARTITION BY country ORDER BY routes ROWS UNBOUNDED PRECEDING) AS running,
               SUM(routes) OVER (PARTITION BY country) AS total
        FROM served_airports) AS t
      WHERE running >= 0.5 * total GROUP BY country) AS x;
    INSERT INTO wpct_bench VALUES ('small', 'window functions by hand', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    -- large, custom aggregate
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT s.country, wpercentile(s.routes, 1, 0.5) AS wm
      FROM routes r JOIN served_airports s ON s.apid = r.src_apid
      GROUP BY s.country) AS x;
    INSERT INTO wpct_bench VALUES ('large', 'wpercentile', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    -- large, window functions
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, MIN(routes) AS wm FROM (
        SELECT s.country, s.routes,
               COUNT(*) OVER (PARTITION BY s.country ORDER BY s.routes ROWS UNBOUNDED PRECEDING) AS running,
               COUNT(*) OVER (PARTITION BY s.country) AS total
        FROM routes r JOIN served_airports s ON s.apid = r.src_apid) AS t
      WHERE running >= 0.5 * total GROUP BY country) AS x;
    INSERT INTO wpct_bench VALUES ('large', 'window functions by hand', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

CALL run_wpct_bench(10);

SELECT workload, method, COUNT(*) AS runs, ROUND(median_agg(ms), 1) AS median_ms,
       ROUND(MIN(ms), 1) AS min_ms, ROUND(MAX(ms), 1) AS max_ms
FROM wpct_bench GROUP BY workload, method ORDER BY workload DESC, method DESC;

-- Sanity check: the two large versions give the same answer (expect 0).
SELECT COUNT(*) AS large_mismatches FROM
  (SELECT s.country, wpercentile(s.routes, 1, 0.5) AS wm
   FROM routes r JOIN served_airports s ON s.apid = r.src_apid GROUP BY s.country) AS a
JOIN
  (SELECT country, MIN(routes) AS wm FROM (
     SELECT s.country, s.routes,
            COUNT(*) OVER (PARTITION BY s.country ORDER BY s.routes ROWS UNBOUNDED PRECEDING) AS running,
            COUNT(*) OVER (PARTITION BY s.country) AS total
     FROM routes r JOIN served_airports s ON s.apid = r.src_apid) AS t
   WHERE running >= 0.5 * total GROUP BY country) AS b USING (country)
WHERE NOT (a.wm <=> b.wm);