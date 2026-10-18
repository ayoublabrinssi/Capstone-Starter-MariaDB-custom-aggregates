-- Experiment 3: stored aggregates inside a view and in a correlated subquery.
-- Linked JIRA issues: MDEV-28475 (views), MDEV-21161 (correlated subquery).
-- Run:
--   ./db.sh --force -t -v < experiments/03_view_subquery.sql

-- 3a. A view whose definition calls median_agg and gini
CREATE OR REPLACE VIEW country_stats AS
SELECT country, COUNT(*) AS airports, median_agg(routes) AS med, gini(routes) AS g
FROM served_airports
GROUP BY country;

SELECT * FROM country_stats WHERE country IN ('Germany', 'Morocco', 'United States');

-- 3b. Same numbers without the view (should match 3a)
SELECT country, COUNT(*) AS airports, median_agg(routes) AS med, gini(routes) AS g
FROM served_airports
WHERE country IN ('Germany', 'Morocco', 'United States')
GROUP BY country;

-- 3c. Whole view vs direct query: rows that differ (expect 0)
SELECT COUNT(*) AS differences
FROM country_stats v
JOIN (SELECT country, median_agg(routes) AS med, gini(routes) AS g
      FROM served_airports GROUP BY country) d USING (country)
WHERE NOT (v.med <=> d.med) OR ABS(v.g - d.g) > 1e-12;

-- 3d. Correlated subquery: median of each country, one row per country
SELECT c.name,
       (SELECT median_agg(s.routes) FROM served_airports s WHERE s.country = c.name) AS med_sub,
       (SELECT MEDIAN(s.routes) OVER () FROM served_airports s WHERE s.country = c.name LIMIT 1) AS med_builtin
FROM countries c
WHERE c.name IN ('Germany', 'Morocco', 'United States', 'France', 'Japan')
ORDER BY c.name;

-- 3e. Correlated subquery over every country: rows where it disagrees with GROUP BY (expect 0)
SELECT COUNT(*) AS differences
FROM (SELECT c.name,
             (SELECT median_agg(s.routes) FROM served_airports s WHERE s.country = c.name) AS med_sub
      FROM countries c) x
JOIN (SELECT country, median_agg(routes) AS med FROM served_airports GROUP BY country) g
  ON g.country = x.name
WHERE NOT (x.med_sub <=> g.med);

DROP VIEW country_stats;
