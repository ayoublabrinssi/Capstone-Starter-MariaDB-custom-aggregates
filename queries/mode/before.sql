-- Airline with the most departing routes in each country, WITHOUT a custom aggregate.
-- Count routes per country and airline, rank them per country, keep rank 1.
-- Ties: the airline name that comes first alphabetically wins.
SELECT country, airline, routes
FROM (
  SELECT a.country, al.name AS airline, COUNT(*) AS routes,
         ROW_NUMBER() OVER (PARTITION BY a.country ORDER BY COUNT(*) DESC, al.name) AS rn
  FROM routes r
  JOIN airports a ON a.apid = r.src_apid
  JOIN airlines al ON al.alid = r.alid
  GROUP BY a.country, al.name
) AS ranked
WHERE rn = 1
ORDER BY routes DESC
LIMIT 15;
