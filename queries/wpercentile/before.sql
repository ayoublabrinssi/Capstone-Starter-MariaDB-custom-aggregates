-- Weighted median of routes per airport, per country, WITHOUT a custom aggregate.
-- MariaDB has no weighted percentile, so it takes two window sums
-- (a running total and the group total) in a subquery, then an outer
-- GROUP BY to pick the first airport where the running total reaches half.
SELECT country,
       MAX(airports)  AS airports,
       MIN(routes)    AS median_route_airport
FROM (
  SELECT country,
         routes,
         COUNT(*)    OVER (PARTITION BY country)                                         AS airports,
         SUM(routes) OVER (PARTITION BY country ORDER BY routes ROWS UNBOUNDED PRECEDING) AS running,
         SUM(routes) OVER (PARTITION BY country)                                         AS total
  FROM served_airports
) AS t
WHERE running >= 0.5 * total
GROUP BY country
ORDER BY airports DESC, country
LIMIT 15;