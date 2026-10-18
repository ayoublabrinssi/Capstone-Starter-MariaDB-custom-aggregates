-- Edge-case tests for median_agg, gini, mode_agg and wpercentile.
-- Each row is one test: pass = 1 means the result is what we expect.
-- Run with scripts/test.sh (it fails if any row has pass = 0).
-- Numbers count as equal when they differ by less than 1e-12 of their size
-- (two correct DOUBLE averages can differ in the last digit).


SELECT test, got, expected,
       IF((got <=> expected) OR ABS(got - expected) <= 1e-12 * GREATEST(1, ABS(expected)), 1, 0) AS pass
FROM (
  SELECT 'median: odd count'       AS test, (SELECT median_agg(v) FROM (SELECT 1 AS v UNION ALL SELECT 3 UNION ALL SELECT 2) t) AS got, 2 AS expected
  UNION ALL SELECT 'median: even count',    (SELECT median_agg(v) FROM (SELECT 1 AS v UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) t), 2.5
  UNION ALL SELECT 'median: single value',  (SELECT median_agg(v) FROM (SELECT 7 AS v) t), 7
  UNION ALL SELECT 'median: negatives',     (SELECT median_agg(v) FROM (SELECT -5 AS v UNION ALL SELECT -1 UNION ALL SELECT -3) t), -3
  UNION ALL SELECT 'median: decimals',      (SELECT median_agg(v) FROM (SELECT 1.5 AS v UNION ALL SELECT 2.5) t), 2
  UNION ALL SELECT 'median: NULL ignored',  (SELECT median_agg(v) FROM (SELECT 5 AS v UNION ALL SELECT NULL UNION ALL SELECT 1) t), 3
  UNION ALL SELECT 'median: only NULLs',    (SELECT median_agg(v) FROM (SELECT NULL AS v UNION ALL SELECT NULL) t), NULL
  UNION ALL SELECT 'median: empty group',   (SELECT median_agg(v) FROM (SELECT 1 AS v FROM DUAL WHERE 0) t), NULL
  UNION ALL SELECT 'median: 2000 random doubles vs MEDIAN()',
            (SELECT median_agg(v) FROM (SELECT RAND(seq) * 1e6 AS v FROM seq_1_to_2000) t),
            (SELECT MEDIAN(v) OVER () FROM (SELECT RAND(seq) * 1e6 AS v FROM seq_1_to_2000) t LIMIT 1)
  UNION ALL SELECT 'median: ROLLUP total (Germany + Morocco)',
            (SELECT m FROM (SELECT country, median_agg(routes) AS m FROM served_airports
                            WHERE country IN ('Germany', 'Morocco') GROUP BY country WITH ROLLUP) r
             WHERE country IS NULL), 18
  UNION ALL SELECT 'gini: all equal',       (SELECT gini(v) FROM (SELECT 4 AS v UNION ALL SELECT 4 UNION ALL SELECT 4) t), 0
  UNION ALL SELECT 'gini: one holds all',   (SELECT gini(v) FROM (SELECT 0 AS v UNION ALL SELECT 0 UNION ALL SELECT 0 UNION ALL SELECT 10) t), 0.75
  UNION ALL SELECT 'gini: 1..5 = 4/15',     (SELECT gini(v) FROM (SELECT seq AS v FROM seq_1_to_5) t), 4 / CAST(15 AS DOUBLE)
  UNION ALL SELECT 'gini: all zero',        (SELECT gini(v) FROM (SELECT 0 AS v UNION ALL SELECT 0) t), NULL
  UNION ALL SELECT 'gini: NULL ignored',    (SELECT gini(v) FROM (SELECT 4 AS v UNION ALL SELECT NULL UNION ALL SELECT 4) t), 0
  UNION ALL SELECT 'gini: empty group',     (SELECT gini(v) FROM (SELECT 1 AS v FROM DUAL WHERE 0) t), NULL
  UNION ALL SELECT 'both in one SELECT (US)',
            (SELECT ROUND(median_agg(routes) + gini(routes), 6) FROM served_airports WHERE country = 'United States'),
            ROUND(3 + 0.8153623872310896, 6)
) AS cases;

-- mode_agg returns text, so these compare strings.
SELECT test, got, expected, IF(got <=> expected, 1, 0) AS pass
FROM (
  SELECT 'mode: clear winner'        AS test, (SELECT mode_agg(v) FROM (SELECT 'b' AS v UNION ALL SELECT 'a' UNION ALL SELECT 'b') t) AS got, 'b' AS expected
  UNION ALL SELECT 'mode: tie, smallest wins', (SELECT mode_agg(v) FROM (SELECT 'b' AS v UNION ALL SELECT 'a' UNION ALL SELECT 'b' UNION ALL SELECT 'a') t), 'a'
  UNION ALL SELECT 'mode: single value',       (SELECT mode_agg(v) FROM (SELECT 'KLM' AS v) t), 'KLM'
  UNION ALL SELECT 'mode: commas and quotes',  (SELECT mode_agg(v) FROM (SELECT 'x, "y"' AS v UNION ALL SELECT 'x, "y"' UNION ALL SELECT 'z') t), 'x, "y"'
  UNION ALL SELECT 'mode: Arabic text',        (SELECT mode_agg(v) FROM (SELECT 'مرحبا' AS v UNION ALL SELECT 'مرحبا' UNION ALL SELECT 'e') t), 'مرحبا'
  UNION ALL SELECT 'mode: case ignored',       (SELECT mode_agg(v) FROM (SELECT 'Lufthansa' AS v UNION ALL SELECT 'LUFTHANSA' UNION ALL SELECT 'KLM') t), 'Lufthansa'
  UNION ALL SELECT 'mode: numbers tie as text', (SELECT mode_agg(v) FROM (SELECT 9 AS v UNION ALL SELECT 10) t), '10'
  UNION ALL SELECT 'mode: NULL ignored',       (SELECT mode_agg(v) FROM (SELECT NULL AS v UNION ALL SELECT NULL UNION ALL SELECT 'a') t), 'a'
  UNION ALL SELECT 'mode: empty group',        (SELECT mode_agg(v) FROM (SELECT 'a' AS v FROM DUAL WHERE 0) t), NULL
  UNION ALL SELECT 'mode: top airline, Morocco',
            (SELECT mode_agg(al.name) FROM routes r JOIN airports ap ON ap.apid = r.src_apid
             JOIN airlines al ON al.alid = r.alid WHERE ap.country = 'Morocco'), 'Royal Air Maroc'
) AS cases;
-- wpercentile(x, w, p): weighted percentile. Expected values worked out by hand.
SELECT test, got, expected,
       IF((got <=> expected) OR ABS(got - expected) <= 1e-12 * GREATEST(1, ABS(expected)), 1, 0) AS pass
FROM (
  SELECT 'wpercentile: weights 1 = lower median'  AS test, (SELECT wpercentile(v, 1, 0.5) FROM (SELECT 1 AS v UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) t) AS got, 2 AS expected
  UNION ALL SELECT 'wpercentile: weights 1, odd count',   (SELECT wpercentile(v, 1, 0.5) FROM (SELECT 3 AS v UNION ALL SELECT 1 UNION ALL SELECT 2) t), 2
  UNION ALL SELECT 'wpercentile: heavy row wins',         (SELECT wpercentile(v, w, 0.5) FROM (SELECT 1 AS v, 1 AS w UNION ALL SELECT 2, 1 UNION ALL SELECT 10, 5) t), 10
  UNION ALL SELECT 'wpercentile: p = 0 is the minimum',   (SELECT wpercentile(v, w, 0) FROM (SELECT 5 AS v, 2 AS w UNION ALL SELECT 3, 1 UNION ALL SELECT 9, 4) t), 3
  UNION ALL SELECT 'wpercentile: p = 1 is the maximum',   (SELECT wpercentile(v, w, 1) FROM (SELECT 5 AS v, 2 AS w UNION ALL SELECT 3, 1 UNION ALL SELECT 9, 4) t), 9
  UNION ALL SELECT 'wpercentile: p = 1, uneven decimals', (SELECT wpercentile(v, w, 1) FROM (SELECT seq AS v, 0.1 * seq AS w FROM seq_1_to_1000) t), 1000
  UNION ALL SELECT 'wpercentile: zero weight skipped',    (SELECT wpercentile(v, w, 0) FROM (SELECT 1 AS v, 0 AS w UNION ALL SELECT 4, 1) t), 4
  UNION ALL SELECT 'wpercentile: negative weight skipped',(SELECT wpercentile(v, w, 0) FROM (SELECT 1 AS v, -3 AS w UNION ALL SELECT 4, 1) t), 4
  UNION ALL SELECT 'wpercentile: NULL x or w skipped',    (SELECT wpercentile(v, w, 0.5) FROM (SELECT NULL AS v, 9 AS w UNION ALL SELECT 2, NULL UNION ALL SELECT 7, 1) t), 7
  UNION ALL SELECT 'wpercentile: p outside 0..1 = NULL',  (SELECT wpercentile(v, 1, 1.5) FROM (SELECT 1 AS v) t), NULL
  UNION ALL SELECT 'wpercentile: p NULL = NULL',          (SELECT wpercentile(v, 1, NULL) FROM (SELECT 1 AS v) t), NULL
  UNION ALL SELECT 'wpercentile: empty group',            (SELECT wpercentile(v, 1, 0.5) FROM (SELECT 1 AS v FROM DUAL WHERE 0) t), NULL
  UNION ALL SELECT 'wpercentile: 1999 random rows vs MEDIAN() (weights 1)',
            (SELECT wpercentile(v, 1, 0.5) FROM (SELECT RAND(seq) * 1e6 AS v FROM seq_1_to_1999) t),
            (SELECT MEDIAN(v) OVER () FROM (SELECT RAND(seq) * 1e6 AS v FROM seq_1_to_1999) t LIMIT 1)
  UNION ALL SELECT 'wpercentile: US route-weighted median',
            (SELECT wpercentile(routes, routes, 0.5) FROM served_airports WHERE country = 'United States'), 196
) AS cases;
