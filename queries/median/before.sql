-- Median routes per served airport, per country, WITHOUT a custom aggregate.
-- MEDIAN() exists only as a window function, so it gives one row per airport.
-- DISTINCT folds it back to one row per country.
SELECT DISTINCT
       country,
       COUNT(*)      OVER (PARTITION BY country) AS airports,
       MEDIAN(routes) OVER (PARTITION BY country) AS median_routes
FROM served_airports
ORDER BY airports DESC, country
LIMIT 15;
