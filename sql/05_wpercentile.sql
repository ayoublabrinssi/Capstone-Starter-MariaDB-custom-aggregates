-- wpercentile(x, w, p): the weighted p-th percentile of x in each group.
--   Each row counts w times. p is a fraction from 0 to 1 (0.5 = weighted median).
--   Result: the smallest x where the running total of w, in order of x,
--   reaches p * (total of w). It is always one of the x values (no interpolation).
--   Rows where x or w is NULL, or w <= 0, are skipped.
--   Returns NULL for an empty group, when p is NULL, or when p is outside 0..1.
--   p is read from the first row of the group, so pass a constant.
--
-- With all weights = 1 it gives the "lower" percentile: for p = 0.5 and an even
-- count it returns the lower of the two middle values, not their mean.
--
-- Same pattern as median_agg: collect [x,w] pairs in a text list, compute at the end.
--
-- DETERMINISTIC: the same values always give the same answer. A server with
-- binary logging refuses a function without it (experiments/11_binary_log.sh).

DELIMITER //

CREATE OR REPLACE AGGREGATE FUNCTION wpercentile(x DOUBLE, w DOUBLE, p DOUBLE) RETURNS DOUBLE DETERMINISTIC
BEGIN
  DECLARE vals LONGTEXT DEFAULT '';  -- the group's pairs, '[x,w],[x,w],...'
  DECLARE n INT DEFAULT 0;           -- how many pairs so far
  DECLARE total DOUBLE DEFAULT 0;    -- sum of the weights
  DECLARE pp DOUBLE DEFAULT NULL;    -- p, taken from the first row

  -- Runs once, when the group has no more rows.
  DECLARE CONTINUE HANDLER FOR NOT FOUND
  BEGIN
    IF n = 0 OR pp IS NULL OR pp < 0 OR pp > 1 THEN
      RETURN NULL;
    END IF;
    RETURN (
      SELECT ranked.v
      FROM (
        SELECT jt.v,
               SUM(jt.w) OVER (ORDER BY jt.v ROWS UNBOUNDED PRECEDING) AS running
        FROM JSON_TABLE(CONCAT('[', vals, ']'), '$[*]'
               COLUMNS (v DOUBLE PATH '$[0]', w DOUBLE PATH '$[1]')) AS jt
      ) AS ranked
      -- 1e-12 slack: the window SUM and the loop SUM can differ in the last digit.
      WHERE ranked.running >= pp * total * (1 - 1e-12)
      ORDER BY ranked.v
      LIMIT 1
    );
  END;

  -- Runs once per row.
  LOOP
    FETCH GROUP NEXT ROW;
    IF n = 0 AND pp IS NULL THEN
      SET pp = p;
    END IF;
    IF x IS NOT NULL AND w IS NOT NULL AND w > 0 THEN
      SET vals = CONCAT(vals, IF(n = 0, '', ','), '[', x, ',', w, ']');
      SET n = n + 1;
      SET total = total + w;
    END IF;
  END LOOP;
END //

DELIMITER ;