-- Experiment 12: mode_agg against a mode written the docs' way.
-- The MariaDB docs' median example (medi_int, experiment 1) keeps the group
-- in a TEMPORARY TABLE tt. mode_tmp below does the same for the mode:
-- one INSERT per row, then GROUP BY on tt in the NOT FOUND handler.
-- Unlike medi_int it skips NULLs and uses ties = smallest value, like mode_agg.
-- Same query as experiment 6 (top airline per country, 67,663 routes),
-- 10 runs each.
-- Run (--force: 12b and 12c are expected to fail):
--   scripts/db.sh --force -t -v < experiments/12_docs_mode.sql

DELIMITER //
CREATE OR REPLACE AGGREGATE FUNCTION mode_tmp(x VARCHAR(255)) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
      DECLARE res VARCHAR(255);
      SET res = (SELECT a FROM tt GROUP BY a ORDER BY COUNT(*) DESC, a LIMIT 1);
      DROP TEMPORARY TABLE tt;
      RETURN res;
    END;
  CREATE TEMPORARY TABLE tt (a VARCHAR(255));
  LOOP
    FETCH GROUP NEXT ROW;
    IF x IS NOT NULL THEN
      INSERT INTO tt VALUES (x);
    END IF;
  END LOOP;
END //
DELIMITER ;

-- 12a. Same answer as mode_agg for every country? Expect 0.
SELECT COUNT(*) AS countries_that_differ
FROM (SELECT ap.country, mode_agg(al.name) AS a, mode_tmp(al.name) AS b
      FROM routes r JOIN airports ap ON ap.apid = r.src_apid
      JOIN airlines al ON al.alid = r.alid
      GROUP BY ap.country) AS x
WHERE NOT (a <=> b);

-- 12b. Two calls in one SELECT: the same clash as medi_int (MDEV-17246).
SELECT ap.country, mode_tmp(al.name) AS top_airline, mode_tmp(r.equipment) AS top_plane
FROM routes r JOIN airports ap ON ap.apid = r.src_apid
JOIN airlines al ON al.alid = r.alid
WHERE ap.country = 'Morocco'
GROUP BY ap.country;

-- 12c. Does dropping tt at the start fix it? mode_tmp2 = mode_tmp plus
-- DROP TEMPORARY TABLE IF EXISTS tt before the CREATE.
DELIMITER //
CREATE OR REPLACE AGGREGATE FUNCTION mode_tmp2(x VARCHAR(255)) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
      DECLARE res VARCHAR(255);
      SET res = (SELECT a FROM tt GROUP BY a ORDER BY COUNT(*) DESC, a LIMIT 1);
      DROP TEMPORARY TABLE tt;
      RETURN res;
    END;
  DROP TEMPORARY TABLE IF EXISTS tt;
  CREATE TEMPORARY TABLE tt (a VARCHAR(255));
  LOOP
    FETCH GROUP NEXT ROW;
    IF x IS NOT NULL THEN
      INSERT INTO tt VALUES (x);
    END IF;
  END LOOP;
END //
DELIMITER ;

SELECT ap.country, mode_tmp2(al.name) AS top_airline, mode_tmp2(r.equipment) AS top_plane
FROM routes r JOIN airports ap ON ap.apid = r.src_apid
JOIN airlines al ON al.alid = r.alid
WHERE ap.country = 'Morocco'
GROUP BY ap.country;

-- mode_agg has no table, so two calls work.
SELECT ap.country, mode_agg(al.name) AS top_airline, mode_agg(r.equipment) AS top_plane
FROM routes r JOIN airports ap ON ap.apid = r.src_apid
JOIN airlines al ON al.alid = r.alid
WHERE ap.country = 'Morocco'
GROUP BY ap.country;

-- Clean up anything left behind, so the timing can run.
DROP TEMPORARY TABLE IF EXISTS tt;

-- 12d. Timing: the experiment 6 query with mode_agg, mode_tmp and ROW_NUMBER() by hand.
CREATE TABLE IF NOT EXISTS docs_mode_bench (method VARCHAR(30), run INT, ms DOUBLE);
TRUNCATE docs_mode_bench;

DELIMITER //
CREATE OR REPLACE PROCEDURE run_docs_mode_bench(p_runs INT)
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
    INSERT INTO docs_mode_bench VALUES ('mode_agg (text list)', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT ap.country, mode_tmp(al.name) AS top_airline
      FROM routes r JOIN airports ap ON ap.apid = r.src_apid
      JOIN airlines al ON al.alid = r.alid
      GROUP BY ap.country) AS x;
    INSERT INTO docs_mode_bench VALUES ('mode_tmp (temp table)', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT COUNT(*) INTO c FROM (
      SELECT country, airline FROM (
        SELECT ap.country, al.name AS airline,
               ROW_NUMBER() OVER (PARTITION BY ap.country ORDER BY COUNT(*) DESC, al.name) AS rn
        FROM routes r JOIN airports ap ON ap.apid = r.src_apid
        JOIN airlines al ON al.alid = r.alid
        GROUP BY ap.country, al.name) AS ranked
      WHERE rn = 1) AS x;
    INSERT INTO docs_mode_bench VALUES ('ROW_NUMBER() by hand', i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);
    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

CALL run_docs_mode_bench(10);

SELECT method, COUNT(*) AS runs, ROUND(median_agg(ms), 1) AS median_ms,
       ROUND(MIN(ms), 1) AS min_ms, ROUND(MAX(ms), 1) AS max_ms
FROM docs_mode_bench GROUP BY method ORDER BY median_ms;
