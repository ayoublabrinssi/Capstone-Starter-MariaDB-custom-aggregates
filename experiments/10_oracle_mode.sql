-- Experiment 10: stored aggregates and sql_mode, and how the server lists them.
-- The docs page also shows the Oracle-style (SQL/PL) syntax: RETURN instead of
-- RETURNS, and EXCEPTION WHEN NO_DATA_FOUND instead of a NOT FOUND handler.
-- Run (after scripts/install.sh):
--   scripts/db.sh -t -v < experiments/10_oracle_mode.sql

CREATE OR REPLACE TABLE marks (stud_id INT, grade_count INT);
INSERT INTO marks VALUES (1, 6), (2, 4), (3, 7), (4, 5), (5, 8);

-- 10a. The docs' SQL/PL example, created in ORACLE mode.
SET sql_mode = ORACLE;
DELIMITER //
CREATE OR REPLACE AGGREGATE FUNCTION aggregate_count(x INT) RETURN INT AS count_students INT DEFAULT 0;
BEGIN
  LOOP
    FETCH GROUP NEXT ROW;
    IF x THEN
      SET count_students := count_students + 1;
    END IF;
  END LOOP;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN count_students;
END aggregate_count //
DELIMITER ;
SELECT aggregate_count(stud_id) AS oracle_style_count FROM marks;

-- 10b. Our functions were created in the default mode. Called from a session
-- in ORACLE mode, they still give the same answers (expected: 6, 0.1333, 3).
SELECT median_agg(grade_count) AS median, gini(grade_count) AS gini FROM marks;
SELECT median_agg(v) AS median_with_null FROM (SELECT 5 AS v UNION ALL SELECT NULL UNION ALL SELECT 1) t;

-- 10c. And the ORACLE-mode function works when called in the default mode.
SET sql_mode = DEFAULT;
SELECT aggregate_count(stud_id) AS oracle_style_count FROM marks;

-- 10d. Each routine keeps the sql_mode it was created in. Only mysql.proc
-- says which functions are aggregates (aggregate = GROUP).
-- information_schema.ROUTINES has no such column.
SELECT name, aggregate, IF(FIND_IN_SET('ORACLE', sql_mode), 'ORACLE', 'default') AS created_in_mode
FROM mysql.proc
WHERE db = DATABASE() AND name IN ('median_agg', 'gini', 'mode_agg', 'wpercentile', 'aggregate_count')
ORDER BY name;
SELECT COUNT(*) AS columns_about_aggregates
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'information_schema' AND TABLE_NAME = 'ROUTINES'
  AND COLUMN_NAME LIKE '%AGGREGATE%';

DROP FUNCTION aggregate_count;
DROP TABLE marks;
