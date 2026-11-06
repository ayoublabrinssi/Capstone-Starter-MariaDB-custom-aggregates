-- Experiment 13: a stored aggregate in HAVING (follow-up to experiment 2d).
-- The reproduction filed in the MariaDB Jira, on a 3-row table, in its own
-- database so it does not touch flightdb2.
-- Same results on MariaDB 10.3.39, 10.6.28, 10.11.19, 11.4.13, 11.8.9, 12.3.3 and 13.0.2.
-- Run (--force: 13c is expected to fail):
--   scripts/db.sh --force -t -v < experiments/13_having_bug.sql

CREATE DATABASE IF NOT EXISTS having_bug;
USE having_bug;
CREATE OR REPLACE TABLE t (g INT, v INT);
INSERT INTO t VALUES (1, 10), (1, 20), (2, 5);

DELIMITER //
CREATE OR REPLACE AGGREGATE FUNCTION my_sum(x INT) RETURNS INT
BEGIN
  DECLARE s INT DEFAULT 0;
  DECLARE CONTINUE HANDLER FOR NOT FOUND RETURN s;
  LOOP
    FETCH GROUP NEXT ROW;
    SET s = s + x;
  END LOOP;
END //
DELIMITER ;

-- 13a. In the select list: right (g 1 = 30, g 2 = 5).
SELECT g, my_sum(v) FROM t GROUP BY g;

-- 13b. Built-in SUM in HAVING: right (g 1).
SELECT g FROM t GROUP BY g HAVING SUM(v) > 25;

-- 13c. my_sum in HAVING: ERROR 1054 Unknown column 'v' in 'HAVING'.
SELECT g FROM t GROUP BY g HAVING my_sum(v) > 25;

-- 13d. Same, with v also in the select list: no error, but no rows.
-- Expected g 1, like 13b.
SELECT g, v FROM t GROUP BY g HAVING my_sum(v) > 25;

-- 13e. Why: in HAVING, my_sum(v) of group 1 is 20, not 30.
SELECT g, v FROM t GROUP BY g HAVING my_sum(v) = 20;

-- 13f. What the function sees: a copy of my_sum that writes each value
-- it fetches into @seen. In HAVING it fetches once per row, but gets the
-- first row's v (10) every time, so 10 + 10 = 20.
DELIMITER //
CREATE OR REPLACE AGGREGATE FUNCTION my_sum_trace(x INT) RETURNS INT
BEGIN
  DECLARE s INT DEFAULT 0;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
      SET @seen = CONCAT(@seen, '= ', s, '; ');
      RETURN s;
    END;
  LOOP
    FETCH GROUP NEXT ROW;
    SET @seen = CONCAT(@seen, x, ' ');
    SET s = s + x;
  END LOOP;
END //
DELIMITER ;

SET @seen = '';
SELECT g, my_sum_trace(v) FROM t GROUP BY g;
SELECT @seen AS in_select_list;

SET @seen = '';
SELECT g, v FROM t GROUP BY g HAVING my_sum_trace(v) > 25;
SELECT @seen AS in_having;

-- 13g. Workarounds: the alias, or a derived table. Both right (g 1).
SELECT g, my_sum(v) AS s FROM t GROUP BY g HAVING s > 25;
SELECT g FROM (SELECT g, my_sum(v) AS s FROM t GROUP BY g) AS d WHERE s > 25;

DROP DATABASE having_bug;
