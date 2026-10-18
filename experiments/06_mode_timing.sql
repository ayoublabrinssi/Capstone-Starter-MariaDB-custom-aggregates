-- Experiment 6: top airline per country (67,663 routes, 225 countries),
-- mode_agg vs the hand-written ROW_NUMBER() query, 10 runs each.
-- Run:
--   scripts/db.sh -t < experiments/06_mode_timing.sql

CREATE TABLE IF NOT EXISTS mode_bench (method VARCHAR(20), run INT, ms DOUBLE);
TRUNCATE mode_bench;

DELIMITER //
CREATE OR REPLACE PROCEDURE run_mode_bench(p_runs INT)
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE t0 DATETIME(6);
  DECLARE c INT;
  WHILE i <= p_runs DO
    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT ap.country, mode_agg(al.name) AS top_airline
      FROM routes r JOIN airports ap ON ap.apid = r.src_apid
      JOIN airlines al ON al.alid = r.alid
      GROUP BY ap.country) AS x;
    INSERT INTO mode_bench VALUES ('mode_agg', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, airline FROM (
        SELECT ap.country, al.name AS airline,
               ROW_NUMBER() OVER (PARTITION BY ap.country ORDER BY COUNT(*) DESC, al.name) AS rn
        FROM routes r JOIN airports ap ON ap.apid = r.src_apid
        JOIN airlines al ON al.alid = r.alid
        GROUP BY ap.country, al.name) AS ranked
      WHERE rn = 1) AS x;
    INSERT INTO mode_bench VALUES ('ROW_NUMBER() by hand', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);
    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

CALL run_mode_bench(10);

SELECT method, COUNT(*) AS runs, ROUND(median_agg(ms), 1) AS median_ms,
       ROUND(MIN(ms), 1) AS min_ms, ROUND(MAX(ms), 1) AS max_ms
FROM mode_bench GROUP BY method;
