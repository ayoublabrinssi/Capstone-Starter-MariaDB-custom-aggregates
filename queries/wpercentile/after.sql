-- Weighted median of routes per airport, per country, WITH the custom aggregate.
-- Each airport is weighted by its own routes, so the answer is the size of the
-- airport a typical departing route leaves from (not the typical airport).
SELECT country,
       COUNT(*)                         AS airports,
       median_agg(routes)               AS median_airport,
       wpercentile(routes, routes, 0.5) AS median_route_airport
FROM served_airports
GROUP BY country
ORDER BY airports DESC, country
LIMIT 15;