-- Check: both versions must name the same airline for every country. Expect 0 rows.
SELECT a.country, a.top_airline AS custom, b.airline AS by_hand
FROM (SELECT ap.country, mode_agg(al.name) AS top_airline
      FROM routes r
      JOIN airports ap ON ap.apid = r.src_apid
      JOIN airlines al ON al.alid = r.alid
      GROUP BY ap.country) AS a
JOIN (SELECT country, airline
      FROM (SELECT ap.country, al.name AS airline,
                   ROW_NUMBER() OVER (PARTITION BY ap.country ORDER BY COUNT(*) DESC, al.name) AS rn
            FROM routes r
            JOIN airports ap ON ap.apid = r.src_apid
            JOIN airlines al ON al.alid = r.alid
            GROUP BY ap.country, al.name) AS ranked
      WHERE rn = 1) AS b USING (country)
WHERE NOT (a.top_airline <=> b.airline);
