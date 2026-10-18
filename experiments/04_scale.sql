-- Experiment 4: how the aggregates scale with group size, timed 10 times each.
-- Data: one group of n rows, values MOD(seq * 7919, 100003), made with the
-- Sequence engine (the first n rows of seq_1_to_100000), so every run uses
-- the same numbers.
--
-- Run:
--   1. Load sql/*.sql, experiments/01_docs_median.sql (medi_int) and
--      experiments/05_faster_median.sql (median_json).
--   2. Load this file:
--      scripts/db.sh -t < experiments/04_scale.sql
--   3. For each size, e.g.: CALL run_bench(1000, 10, TRUE);
--      TRUE also times median_json, which takes minutes past 10,000 rows.
--   4. Run the summary query at the end of this file again.
-- NOW(6) follows the VM clock: if a time comes out negative, run that size again.

CREATE TABLE IF NOT EXISTS bench_results (
  method VARCHAR(20), n INT, run INT, ms DOUBLE
);

DELIMITER //
CREATE OR REPLACE PROCEDURE run_bench(p_n INT, p_runs INT, p_with_json BOOLEAN)
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE t0 DATETIME(6);
  DECLARE r DOUBLE;

  DROP TABLE IF EXISTS bench_data;
  CREATE TABLE bench_data ENGINE=InnoDB AS
    SELECT seq AS id, MOD(seq * 7919, 100003) AS v FROM seq_1_to_100000 WHERE seq <= p_n;
  DELETE FROM bench_results WHERE n = p_n;

  WHILE i <= p_runs DO
    SET t0 = NOW(6);
    SELECT AVG(v) INTO r FROM bench_data;
    INSERT INTO bench_results VALUES ('AVG (baseline)', p_n, i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT MEDIAN(v) OVER () INTO r FROM bench_data LIMIT 1;
    INSERT INTO bench_results VALUES ('MEDIAN() OVER', p_n, i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT median_agg(v) INTO r FROM bench_data;
    INSERT INTO bench_results VALUES ('median_agg', p_n, i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET t0 = NOW(6);
    SELECT gini(v) INTO r FROM bench_data;
    INSERT INTO bench_results VALUES ('gini', p_n, i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    -- the old JSON version takes minutes past 10,000 rows, so it is optional
    IF p_with_json THEN
      SET t0 = NOW(6);
      SELECT median_json(v) INTO r FROM bench_data;
      INSERT INTO bench_results VALUES ('median_json (old)', p_n, i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);
    END IF;

    SET t0 = NOW(6);
    SELECT medi_int(v) INTO r FROM bench_data;
    INSERT INTO bench_results VALUES ('medi_int (docs)', p_n, i, TIMESTAMPDIFF(MICROSECOND, t0, NOW(6)) / 1000);

    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

-- Summary: median time of the runs, plus fastest and slowest (spread).
-- median_agg is used here on its own timings.
SELECT method, n, COUNT(*) AS runs, ROUND(median_agg(ms), 1) AS median_ms,
       ROUND(MIN(ms), 1) AS min_ms, ROUND(MAX(ms), 1) AS max_ms
FROM bench_results GROUP BY method, n ORDER BY method, n;
