-- mode_agg(x): the most common value of x in each group. Works on text.
--   Ties: the smallest value wins, so the result is always the same.
--   NULLs are skipped. An empty group returns NULL.
--   Values are compared as text in the default collation (utf8mb4_uca1400_ai_ci
--   on openflights): case and accents are ignored, and on a tie '10' beats '9'.
--
-- Same pattern as median_agg. JSON_QUOTE keeps commas and quotes inside a
-- value from breaking the list.
--
-- DETERMINISTIC: the same values always give the same answer. A server with
-- binary logging refuses a function without it (experiments/11_binary_log.sh).

DELIMITER //

CREATE OR REPLACE AGGREGATE FUNCTION mode_agg(x VARCHAR(255)) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
  DECLARE vals LONGTEXT DEFAULT '';  -- the group's values, quoted and comma-separated
  DECLARE n INT DEFAULT 0;           -- how many values so far

  -- Runs once, when the group has no more rows.
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    RETURN (
      SELECT jt.v
      FROM JSON_TABLE(CONCAT('[', vals, ']'), '$[*]' COLUMNS (v VARCHAR(255) PATH '$')) AS jt
      GROUP BY jt.v
      ORDER BY COUNT(*) DESC, jt.v
      LIMIT 1
    );

  -- Runs once per row.
  LOOP
    FETCH GROUP NEXT ROW;
    IF x IS NOT NULL THEN
      SET vals = CONCAT(vals, IF(n = 0, '', ','), JSON_QUOTE(x));
      SET n = n + 1;
    END IF;
  END LOOP;
END //

DELIMITER ;
