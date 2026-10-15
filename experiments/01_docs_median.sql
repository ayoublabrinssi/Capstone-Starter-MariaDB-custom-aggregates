-- Experiment 1: the median example from the MariaDB documentation
-- (Stored Aggregate Functions page), copied as written, next to median_agg.
-- The docs version keeps the group in a TEMPORARY TABLE called tt.
-- Run (--force: 1e is expected to fail):
--   ./db.sh --force -t -v < experiments/01_docs_median.sql

DELIMITER //
CREATE OR REPLACE AGGREGATE FUNCTION medi_int(x INT) RETURNS DOUBLE
BEGIN
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
      DECLARE res DOUBLE;
      DECLARE cnt INT DEFAULT (SELECT COUNT(*) FROM tt);
      DECLARE lim INT DEFAULT (cnt-1) DIV 2;
      IF cnt % 2 = 0 THEN
        SET res = (SELECT AVG(a) FROM (SELECT a FROM tt ORDER BY a LIMIT lim,2) ttt);
      ELSE
        SET res = (SELECT a FROM tt ORDER BY a LIMIT lim,1);
      END IF;
      DROP TEMPORARY TABLE tt;
      RETURN res;
    END;
  CREATE TEMPORARY TABLE tt (a INT);
  LOOP
    FETCH GROUP NEXT ROW;
    INSERT INTO tt VALUES (x);
  END LOOP;
END //
DELIMITER ;

-- 1a. One call, grouped by country: do both agree?
SELECT COUNT(*) AS countries_that_differ
FROM (SELECT country, medi_int(routes) AS d, median_agg(routes) AS m
      FROM served_airports GROUP BY country) AS t
WHERE d <> m;

-- 1b. NULL handling: the true median of (5, NULL, 1) ignoring NULL is 3.
SELECT medi_int(v) AS docs_version, median_agg(v) AS median_agg
FROM (SELECT 5 AS v UNION ALL SELECT NULL UNION ALL SELECT 1) AS t;

-- 1c. Decimal input: median of (1.5, 2.5) is 2.
SELECT medi_int(v) AS docs_version, median_agg(v) AS median_agg
FROM (SELECT 1.5 AS v UNION ALL SELECT 2.5) AS t;

-- 1d. Two medians in the same SELECT (routes and apid).
SELECT country, medi_int(routes) AS med_routes, medi_int(apid) AS med_apid
FROM served_airports GROUP BY country LIMIT 3;

SELECT country, median_agg(routes) AS med_routes, median_agg(apid) AS med_apid
FROM served_airports GROUP BY country LIMIT 3;

-- 1e. Does a failed call leave tt behind and break the next one?
SELECT medi_int(routes) FROM served_airports;
