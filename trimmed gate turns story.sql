--Query on turntimes for Galen's spreadsheet
WITH all_results AS (
	SELECT
		trunc(tv.entered, 'MM') AS analysis_month
		, 'ZLO' AS terminal_key
		, count(*) AS gate_turns_total_turns
		, avg (tv.exited - tv.entered) * 24 * 60 AS gate_turns_average_minutes
		, 'Oracle' AS platform
	FROM truck_visits tv
	WHERE 
		EXTRACT (YEAR FROM tv.entered) >= 2023
		AND tv.exited IS NOT NULL 
		AND tv.entered IS NOT NULL 
	GROUP BY trunc(tv.entered, 'MM')
	--ORDER BY trunc(tv.created, 'MM')
), trimmed_results AS (
	SELECT
		trunc(tv.entered, 'MM') AS analysis_month
		, 'ZLO' AS terminal_key
		, count(*) AS gate_turns_total_turns_trimmed
		, avg (tv.exited - tv.entered) * 24 * 60 AS gate_turns_avg_minutes_trimmed
		, 'Oracle' AS platform
	FROM truck_visits tv
	WHERE 
		EXTRACT (YEAR FROM tv.entered) >= 2023
		AND tv.exited IS NOT NULL 
		AND tv.entered IS NOT NULL
		AND (tv.exited - tv.entered) * 24 * 60 > 15
		AND (tv.exited - tv.entered) * 24 * 60 < 120
	GROUP BY trunc(tv.entered, 'MM') 
	--ORDER BY trunc(tv.created, 'MM')
), joined_results AS (
	SELECT 
		trunc(COALESCE (ar.analysis_month,tr.analysis_month),'MM') AS ORDERING_month
		, to_char(trunc(COALESCE (ar.analysis_month,tr.analysis_month),'MM'),'MM/DD/YYYY') AS analysis_month
		, COALESCE (ar.terminal_key, tr.terminal_key) AS terminal_key
		, ar.gate_turns_total_turns AS gate_turns_total_turns
		, ar.gate_turns_average_minutes AS gate_turns_average_minutes
		, tr.gate_turns_total_turns_trimmed AS gate_turns_total_turns_trimmed
		, tr.gate_turns_avg_minutes_trimmed AS gate_turns_avg_minutes_trimmed
		, COALESCE (ar.platform,tr.platform) AS platform
	FROM all_results ar
	FULL OUTER JOIN trimmed_results tr ON ar.analysis_month = tr.analysis_month
	--ORDER BY 1
)
SELECT
	jr.analysis_month
	, jr.terminal_key
	, jr.gate_turns_total_turns
	, jr.gate_turns_average_minutes
	, jr.gate_turns_total_turns_trimmed
	, jr.gate_turns_avg_minutes_trimmed
	, jr.platform
FROM joined_results jr
ORDER BY jr.ordering_month
;

SELECT
	trunc(tv.entered, 'MM') AS analysis_month
	, sum (CASE WHEN (tv.exited - tv.entered) * 24 * 60 < 15 THEN 1 ELSE 0 END) AS too_short
	, sum (CASE WHEN (tv.exited - tv.entered) * 24 * 60 >120 THEN 1 ELSE 0 END) AS too_long
FROM truck_visits tv
WHERE 
	EXTRACT (YEAR FROM tv.entered) >= 2023
	AND tv.exited IS NOT NULL 
	AND tv.entered IS NOT NULL
	AND (((tv.exited - tv.entered) * 24 * 60 < 15) OR ((tv.exited - tv.entered) * 24 * 60 > 120))
GROUP BY trunc(tv.entered, 'MM') 
ORDER BY trunc(tv.entered, 'MM')

SELECT * FROM truck_visits;