-- Check: both versions must agree for every country. Expect 0 rows.
SELECT a.country, a.gini AS custom, b.gini AS by_hand
FROM (SELECT country, gini(routes) AS gini
      FROM served_airports GROUP BY country) AS a
JOIN (SELECT country,
             2 * SUM(rn * routes) / CAST(COUNT(*) * SUM(routes) AS DOUBLE)
               - (COUNT(*) + 1) / CAST(COUNT(*) AS DOUBLE) AS gini
      FROM (SELECT country, routes,
                   ROW_NUMBER() OVER (PARTITION BY country ORDER BY routes) AS rn
            FROM served_airports) AS ranked
      GROUP BY country) AS b USING (country)
WHERE ABS(a.gini - b.gini) > 1e-9;
