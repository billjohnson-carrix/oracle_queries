SELECT
	avg(tv.exited - tv.entered) * 24 * 60 AS avg_turn_time
	--tv.entered
	--, tv.exited
FROM truck_visits tv
WHERE
	tv.entered IS NOT NULL 
	AND tv.exited IS NOT NULL 
	AND EXTRACT (YEAR FROM tv.entered) = 2024
	AND EXTRACT (MONTH from tv.entered) = 5
--FETCH FIRST 100 ROWS ONLY
;