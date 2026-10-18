-- Gini of routes per served airport, per country, WITH the custom aggregate.
SELECT country,
       COUNT(*)     AS airports,
       gini(routes) AS gini
FROM served_airports
GROUP BY country
ORDER BY airports DESC, country
LIMIT 15;
