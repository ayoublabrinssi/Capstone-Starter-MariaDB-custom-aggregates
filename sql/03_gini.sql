-- gini(x): how unevenly x is spread in each group, from 0 to 1.
--   0 = all values equal. Close to 1 = one row holds almost everything.
--   NULLs are skipped. Returns NULL for an empty group or when the total is 0.
--   Meant for values >= 0 (counts, sizes, amounts).
--
-- Formula, with the n values sorted and ranked 1..n:
--   G = 2 * SUM(rank * x) / (n * total) - (n + 1) / n
--
-- Same pattern as median_agg: collect the values in a text list, compute at the end.
--
-- DETERMINISTIC: the same values always give the same answer. A server with
-- binary logging refuses a function without it (experiments/11_binary_log.sh).

DELIMITER //

CREATE OR REPLACE AGGREGATE FUNCTION gini(x DOUBLE) RETURNS DOUBLE DETERMINISTIC
BEGIN
  DECLARE vals LONGTEXT DEFAULT '';  -- the group's values, comma-separated
  DECLARE n INT DEFAULT 0;           -- how many values so far
  DECLARE total DOUBLE DEFAULT 0;    -- their sum

  -- Runs once, when the group has no more rows.
  DECLARE CONTINUE HANDLER FOR NOT FOUND
  BEGIN
    IF total <= 0 THEN
      RETURN NULL;
    END IF;
    -- CAST to DOUBLE: INT / INT gives a DECIMAL rounded to 4 places.
    RETURN (
      SELECT 2 * SUM(ranked.rn * ranked.v) / (n * total) - (n + 1) / CAST(n AS DOUBLE)
      FROM (
        SELECT jt.v, ROW_NUMBER() OVER (ORDER BY jt.v) AS rn
        FROM JSON_TABLE(CONCAT('[', vals, ']'), '$[*]' COLUMNS (v DOUBLE PATH '$')) AS jt
      ) AS ranked
    );
  END;

  -- Runs once per row.
  LOOP
    FETCH GROUP NEXT ROW;
    IF x IS NOT NULL THEN
      SET vals = CONCAT(vals, IF(n = 0, '', ','), x);
      SET n = n + 1;
      SET total = total + x;
    END IF;
  END LOOP;
END //

DELIMITER ;
