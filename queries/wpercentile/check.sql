-- Check: both versions must agree for every country, at several percentiles.
-- Expect 0 rows.
SELECT a.country, a.p, a.wp AS custom, b.wp AS window_version
FROM (SELECT s.country, ps.p, wpercentile(s.routes, s.routes, ps.p) AS wp
      FROM served_airports s
      CROSS JOIN (SELECT 0.1 AS p UNION ALL SELECT 0.5 UNION ALL SELECT 0.9) AS ps
      GROUP BY s.country, ps.p) AS a
JOIN (SELECT country, p, MIN(routes) AS wp
      FROM (SELECT s.country, ps.p, s.routes,
                   SUM(s.routes) OVER (PARTITION BY s.country, ps.p ORDER BY s.routes
                                       ROWS UNBOUNDED PRECEDING) AS running,
                   SUM(s.routes) OVER (PARTITION BY s.country, ps.p) AS total
            FROM served_airports s
            CROSS JOIN (SELECT 0.1 AS p UNION ALL SELECT 0.5 UNION ALL SELECT 0.9) AS ps) AS t
      WHERE running >= p * total
      GROUP BY country, p) AS b
  ON a.country = b.country AND a.p = b.p
WHERE NOT (a.wp <=> b.wp);