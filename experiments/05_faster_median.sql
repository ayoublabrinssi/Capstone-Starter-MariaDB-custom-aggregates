-- Experiment 5: why the first median_agg was slow on big groups.
-- The first version stored the group with JSON_ARRAY_APPEND. Each call parses
-- and copies the whole array again, so n rows cost about n*n work.
-- It is kept here as median_json so it can be timed against the current
-- median_agg (sql/02_median_agg.sql), which keeps a plain text list and parses
-- it as JSON only once, at the end of the group.
-- Run:
--   ./db.sh -t -v < experiments/05_faster_median.sql

DELIMITER //
CREATE OR REPLACE AGGREGATE FUNCTION median_json(x DOUBLE) RETURNS DOUBLE
BEGIN
  DECLARE vals JSON DEFAULT '[]';
  DECLARE n INT DEFAULT 0;
  DECLARE result DOUBLE DEFAULT NULL;
  DECLARE take INT;
  DECLARE skip INT;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
  BEGIN
    IF n > 0 THEN
      SET take = 2 - n % 2;
      SET skip = (n - 1) DIV 2;
      SELECT AVG(v) INTO result FROM (
        SELECT jt.v
        FROM JSON_TABLE(vals, '$[*]' COLUMNS (v DOUBLE PATH '$')) AS jt
        ORDER BY jt.v
        LIMIT take OFFSET skip
      ) AS middle;
    END IF;
    RETURN result;
  END;
  LOOP
    FETCH GROUP NEXT ROW;
    IF x IS NOT NULL THEN
      SET vals = JSON_ARRAY_APPEND(vals, '$', x);
      SET n = n + 1;
    END IF;
  END LOOP;
END //
DELIMITER ;

-- 5a. Same answers on every country (expect 0)
SELECT COUNT(*) AS differences
FROM (SELECT country, median_agg(routes) AS a, median_json(routes) AS b
      FROM served_airports GROUP BY country) t
WHERE NOT (a <=> b);

-- 5b. The text list must keep all digits of a DOUBLE (expect same = 1)
SELECT median_agg(v) = median_json(v) AS same,
       median_agg(v) AS text_version, median_json(v) AS json_version
FROM (SELECT CAST(0.1 AS DOUBLE) + CAST(0.2 AS DOUBLE) AS v
      UNION ALL SELECT CAST(1 AS DOUBLE) / 3
      UNION ALL SELECT PI() * 1e10) t;

-- 5c. Same check on 2,000 random doubles (expect same = 1)
SELECT median_agg(v) = median_json(v) AS same
FROM (SELECT RAND(seq) * 1e6 AS v FROM seq_1_to_2000) t;
