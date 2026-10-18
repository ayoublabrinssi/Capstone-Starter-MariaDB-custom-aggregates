-- Check: both versions must agree for every country. Expect 0 rows.
SELECT a.country, a.median_routes AS custom, b.median_routes AS builtin
FROM (SELECT country, median_agg(routes) AS median_routes
      FROM served_airports GROUP BY country) AS a
JOIN (SELECT DISTINCT country, MEDIAN(routes) OVER (PARTITION BY country) AS median_routes
      FROM served_airports) AS b USING (country)
WHERE ABS(a.median_routes - b.median_routes) > 1e-9;
