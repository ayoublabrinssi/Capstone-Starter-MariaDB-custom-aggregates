-- Airline with the most departing routes in each country, WITH mode_agg.
-- One aggregate call replaces the count, rank and filter steps.
SELECT a.country,
       mode_agg(al.name) AS top_airline,
       COUNT(*)          AS all_routes
FROM routes r
JOIN airports a ON a.apid = r.src_apid
JOIN airlines al ON al.alid = r.alid
GROUP BY a.country
ORDER BY all_routes DESC
LIMIT 15;
