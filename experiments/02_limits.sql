-- Experiment 2: what the documentation does not say.
-- Run (--force: some of these are expected to fail):
--   scripts/db.sh --force -t -v < experiments/02_limits.sql

-- 2a. As a window function, like the built-in MEDIAN() OVER (...)
SELECT country, routes,
       median_agg(routes) OVER (PARTITION BY country) AS m
FROM served_airports LIMIT 3;

-- 2b. With DISTINCT, like COUNT(DISTINCT x)
SELECT median_agg(DISTINCT routes) AS m FROM served_airports;

-- 2c. Two different custom aggregates in one SELECT
SELECT country, median_agg(routes) AS m, gini(routes) AS g
FROM served_airports GROUP BY country ORDER BY COUNT(*) DESC LIMIT 3;

-- 2d. In HAVING and ORDER BY
SELECT country, COUNT(*) AS airports, ROUND(gini(routes), 3) AS g
FROM served_airports GROUP BY country
HAVING gini(routes) > 0.8 ORDER BY gini(routes) DESC;

-- 2e. GROUP BY ... WITH ROLLUP (super-aggregate row)
SELECT country, median_agg(routes) AS m
FROM served_airports WHERE country IN ('Morocco', 'Germany') GROUP BY country WITH ROLLUP;

-- 2f. No rows at all
SELECT median_agg(routes) AS m, gini(routes) AS g FROM served_airports WHERE 1 = 0;

-- 2g. Text input: median_agg takes DOUBLE, what happens with a string?
SELECT median_agg(name) AS m FROM served_airports WHERE country = 'Morocco';

-- 2h. Deterministic? Is it allowed in a generated column / CHECK? (aggregates should not be)
SELECT ROUTINE_NAME, IS_DETERMINISTIC, SQL_DATA_ACCESS, ROUTINE_TYPE
FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = 'flightdb2';

-- 2i. Follow-up to 2d: is the HAVING error specific to stored aggregates?
SELECT country, AVG(routes) AS a FROM served_airports GROUP BY country
HAVING AVG(routes) > 100;                                   -- built-in in HAVING
SELECT country, ROUND(gini(routes), 3) AS g FROM served_airports GROUP BY country
HAVING g > 0.8 ORDER BY g DESC;                             -- alias in HAVING
SELECT country, ROUND(gini(routes), 3) AS g FROM served_airports GROUP BY country
ORDER BY gini(routes) DESC LIMIT 3;                         -- stored aggregate in ORDER BY
SELECT * FROM (SELECT country, gini(routes) AS g FROM served_airports GROUP BY country) AS t
WHERE g > 0.8;                                              -- derived table workaround

-- 2j. Workaround for DISTINCT: deduplicate in a subquery first
SELECT median_agg(r) AS m FROM (SELECT DISTINCT routes AS r FROM served_airports) AS d;
