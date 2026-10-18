-- Gini of routes per served airport, per country, WITHOUT a custom aggregate.
-- The rows must be ranked inside each country first (window function in a
-- subquery), then the formula is written out by hand in the outer GROUP BY.
-- The CASTs matter: integer / integer is DECIMAL in MariaDB and is cut to
-- 4 decimals (div_precision_increment), which silently rounds the result.
SELECT country,
       COUNT(*) AS airports,
       2 * SUM(rn * routes) / CAST(COUNT(*) * SUM(routes) AS DOUBLE)
         - (COUNT(*) + 1) / CAST(COUNT(*) AS DOUBLE) AS gini
FROM (
  SELECT country, routes,
         ROW_NUMBER() OVER (PARTITION BY country ORDER BY routes) AS rn
  FROM served_airports
) AS ranked
GROUP BY country
ORDER BY airports DESC, country
LIMIT 15;
