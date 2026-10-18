-- median_agg(x): the middle value of x in each group.
--   Even number of values: the mean of the two middle values.
--   NULLs are skipped. An empty group returns NULL.
-- Named median_agg because MEDIAN() already exists as a window function.
--
-- The values are kept in a text list ('28,1,18') and read once at the end.
-- An earlier version used JSON_ARRAY_APPEND per row and was about 17x slower
-- at 10,000 rows (experiments/05_faster_median.sql).
--
-- DETERMINISTIC: the same values always give the same answer. A server with
-- binary logging refuses a function without it (experiments/11_binary_log.sh).

DELIMITER //

CREATE OR REPLACE AGGREGATE FUNCTION median_agg(x DOUBLE) RETURNS DOUBLE DETERMINISTIC
BEGIN
  DECLARE vals LONGTEXT DEFAULT '';  -- the group's values, comma-separated
  DECLARE n INT DEFAULT 0;           -- how many values so far

  -- Runs once, when the group has no more rows.
  DECLARE CONTINUE HANDLER FOR NOT FOUND
  BEGIN
    DECLARE take INT DEFAULT 2 - n % 2;      -- odd n: 1 middle value, even n: 2
    DECLARE skip INT DEFAULT (n - 1) DIV 2;  -- values below the middle
    RETURN (
      SELECT AVG(v) FROM (
        SELECT jt.v
        FROM JSON_TABLE(CONCAT('[', vals, ']'), '$[*]' COLUMNS (v DOUBLE PATH '$')) AS jt
        ORDER BY jt.v
        LIMIT take OFFSET skip
      ) AS middle
    );
  END;

  -- Runs once per row.
  LOOP
    FETCH GROUP NEXT ROW;
    IF x IS NOT NULL THEN
      SET vals = CONCAT(vals, IF(n = 0, '', ','), x);
      SET n = n + 1;
    END IF;
  END LOOP;
END //

DELIMITER ;
