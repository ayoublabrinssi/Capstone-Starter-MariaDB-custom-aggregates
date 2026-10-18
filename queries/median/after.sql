-- Median routes per served airport, per country, WITH the custom aggregate.
SELECT country,
       COUNT(*)           AS airports,
       median_agg(routes) AS median_routes
FROM served_airports
GROUP BY country
ORDER BY airports DESC, country
LIMIT 15;
