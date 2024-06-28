SELECT
	avg(tv.exited - tv.entered) * 24 * 60 AS avg_turn_time
	--tv.entered
	--, tv.exited
FROM truck_visits tv
WHERE
	tv.entered IS NOT NULL 
	AND tv.exited IS NOT NULL 
	AND EXTRACT (YEAR FROM tv.entered) = 2024
	AND EXTRACT (MONTH from tv.entered) = 1
	AND (tv.exited - tv.entered) * 24 * 60 >= 15
	AND (tv.exited - tv.entered) * 24 * 60 <= 120
;

SELECT
	avg(tv.exited - tv.entered) * 24 * 60 AS avg_turn_time
	--tv.entered
	--, tv.exited
FROM truck_visits_arc tv
WHERE
	tv.entered IS NOT NULL 
	AND tv.exited IS NOT NULL 
	AND EXTRACT (YEAR FROM tv.entered) = 2024
	AND EXTRACT (MONTH from tv.entered) = 1
	--AND (tv.exited - tv.entered) * 24 * 60 >= 15
	--AND (tv.exited - tv.entered) * 24 * 60 <= 120
;