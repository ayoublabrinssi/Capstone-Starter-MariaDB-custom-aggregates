-- Experiment 8: wpercentile vs the built-in PERCENTILE_DISC, 10 runs each.
-- MariaDB has no built-in WEIGHTED percentile. But with every weight = 1,
-- wpercentile(x, 1, p) gives the same answer as the built-in window function
-- PERCENTILE_DISC(p) WITHIN GROUP (ORDER BY x) OVER (PARTITION BY ...).
-- So this compares our stored aggregate with the native one on the same job.
--   small: 90th percentile of routes per airport, per country (3,211 rows, biggest group 550)
--   large: the same, one row per route (67,663 rows, biggest group 13,056)
-- Run:
--   scripts/db.sh -t < experiments/08_wpercentile_vs_builtin.sql

CREATE TABLE IF NOT EXISTS builtin_bench (workload VARCHAR(10), method VARCHAR(30), run INT, ms DOUBLE);
TRUNCATE builtin_bench;

DELIMITER //
CREATE OR REPLACE PROCEDURE run_builtin_bench(p_runs INT)
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE t0 DATETIME(6);
  DECLARE c INT;
  WHILE i <= p_runs DO
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, wpercentile(routes, 1, 0.9) AS p90
      FROM served_airports GROUP BY country) AS x;
    INSERT INTO builtin_bench VALUES ('small', 'wpercentile', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT DISTINCT country,
             PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY routes) OVER (PARTITION BY country) AS p90
      FROM served_airports) AS x;
    INSERT INTO builtin_bench VALUES ('small', 'built-in PERCENTILE_DISC', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT s.country, wpercentile(s.routes, 1, 0.9) AS p90
      FROM routes r JOIN served_airports s ON s.apid = r.src_apid
      GROUP BY s.country) AS x;
    INSERT INTO builtin_bench VALUES ('large', 'wpercentile', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT DISTINCT s.country,
             PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY s.routes) OVER (PARTITION BY s.country) AS p90
      FROM routes r JOIN served_airports s ON s.apid = r.src_apid) AS x;
    INSERT INTO builtin_bench VALUES ('large', 'built-in PERCENTILE_DISC', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

CALL run_builtin_bench(10);

SELECT workload, method, COUNT(*) AS runs, ROUND(median_agg(ms), 1) AS median_ms,
       ROUND(MIN(ms), 1) AS min_ms, ROUND(MAX(ms), 1) AS max_ms
FROM builtin_bench GROUP BY workload, method ORDER BY workload DESC, method DESC;

-- Same answers? (expect 0 for both)
SELECT
  (SELECT COUNT(*) FROM
     (SELECT country, wpercentile(routes, 1, 0.9) AS w FROM served_airports GROUP BY country) a
     JOIN (SELECT DISTINCT country, PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY routes)
                  OVER (PARTITION BY country) AS d FROM served_airports) b USING (country)
     WHERE NOT (a.w <=> b.d)) AS small_mismatches,
  (SELECT COUNT(*) FROM
     (SELECT s.country, wpercentile(s.routes, 1, 0.9) AS w
      FROM routes r JOIN served_airports s ON s.apid = r.src_apid GROUP BY s.country) a
     JOIN (SELECT DISTINCT s.country, PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY s.routes)
                  OVER (PARTITION BY s.country) AS d
           FROM routes r JOIN served_airports s ON s.apid = r.src_apid) b USING (country)
     WHERE NOT (a.w <=> b.d)) AS large_mismatches;

DROP TABLE builtin_bench;
DROP PROCEDURE run_builtin_bench;
