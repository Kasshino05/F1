USE f1;

-- 1. Gennemsnitlig tid i pitlanen per hold (stop over 40 sek. er fjernet)
SELECT t.name AS team,
       COUNT(*) AS stops,
       ROUND(AVG(p.duration_ms) / 1000, 2) AS avg_seconds
FROM pit_stops p
JOIN sessions s ON s.session_id = p.session_id
JOIN entries e ON e.race_id = s.race_id AND e.driver_id = p.driver_id
JOIN teams t ON t.team_id = e.team_id
WHERE p.duration_ms IS NOT NULL
  AND p.duration_ms < 40000
GROUP BY t.name
ORDER BY avg_seconds;

-- 2. Omgangstid i forhold til løbets hurtigste omgang, efter dækkets alder (uden benzinkorrektion)
SELECT l.compound,
       FLOOR((l.tyre_age - 1) / 5) * 5 + 1 AS age_from,
       COUNT(*) AS laps,
       ROUND(AVG(l.lap_time_ms / b.best_ms), 4) AS relative_pace
FROM laps l
JOIN (SELECT session_id, MIN(lap_time_ms) AS best_ms
      FROM laps GROUP BY session_id) b ON b.session_id = l.session_id
WHERE l.compound IN ('SOFT','MEDIUM','HARD')
  AND l.lap_time_ms IS NOT NULL
  AND l.lap_time_ms < b.best_ms * 1.07
  AND l.tyre_age BETWEEN 1 AND 30
GROUP BY l.compound, age_from
HAVING COUNT(*) >= 50
ORDER BY l.compound, age_from;

-- 3. Samme som 2, men med et skøn på 0,035 sek. per omgang for benzinforbrug
SELECT l.compound,
       FLOOR((l.tyre_age - 1) / 5) * 5 + 1 AS age_from,
       COUNT(*) AS laps,
       ROUND(AVG((l.lap_time_ms + 35 * l.lap_number) / b.best_ms), 4) AS fuel_corrected_pace
FROM laps l
JOIN (SELECT session_id, MIN(lap_time_ms) AS best_ms
      FROM laps GROUP BY session_id) b ON b.session_id = l.session_id
WHERE l.compound IN ('SOFT','MEDIUM','HARD')
  AND l.lap_time_ms IS NOT NULL
  AND l.lap_time_ms < b.best_ms * 1.07
  AND l.tyre_age BETWEEN 1 AND 30
GROUP BY l.compound, age_from
HAVING COUNT(*) >= 50
ORDER BY l.compound, age_from;