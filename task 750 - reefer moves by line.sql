--Live reefers
SELECT
	temp_required
	, count(*)
	, CASE 
		WHEN temp_required <= 20 THEN NULL 
		ELSE 'Too hot'
	  END AS temp_comment
FROM equipment_history eh
WHERE eh.temp_required IS NOT NULL 
GROUP BY temp_required
ORDER BY 2 DESC 
;

/*		SELECT 
			2022 + trunc((LEVEL-1)/12) AS YEAR
			, mod(LEVEL-1,12) + 1 AS MONTH
		FROM dual
		CONNECT BY LEVEL <= 24
*/

/*	, sum(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 END) AS exports 
	, sum(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 END) AS imports 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')THEN 1 ELSE 0 END) AS total  
*/

--Reefer throughput by line
WITH 
	year_and_month AS (
		SELECT 
			2022 + trunc((LEVEL-1)/12) AS YEAR
			, mod(LEVEL-1,12) + 1 AS MONTH
		FROM dual
		CONNECT BY LEVEL <= 24
	)
SELECT
	yam.YEAR
	, yam.MONTH
	, lo.name AS name
	, eh.line_id AS line
	, sum(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS exports 
	, sum(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS imports 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS transships 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS total  
FROM year_and_month yam
LEFT JOIN equipment_history eh ON 
	EXTRACT (YEAR FROM eh.posted) = yam.YEAR
	AND EXTRACT (MONTH FROM eh.posted) = yam.MONTH
LEFT JOIN line_operators lo ON 
	eh.line_id = lo.id
GROUP BY
	yam.YEAR
	, yam.MONTH
	, lo.name
	, eh.line_id
ORDER BY 
	yam.YEAR
	, yam.MONTH
	, lo.name
	, eh.line_id
; 

--Adding the line that owns the arrival or departure vessel
SELECT 
	*
FROM equipment_history eh
WHERE 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
	AND (eh.transship = 'X' OR eh.transship = 'G')
	AND EXTRACT (YEAR FROM eh.posted) = 2023
;

SELECT 
	eu.gkey
	, eu.eq_nbr
	, vvin.vsl_id
	, vvin.in_voy_nbr
	, vvin.vsl_line_id
	, vvout.vsl_id
	, vvout.out_voy_nbr
	, vvout.vsl_line_id
FROM equipment_uses eu
LEFT JOIN vessel_visits vvin ON
	vvin.vsl_id = eu.in_loc_id AND vvin.in_voy_nbr = eu.in_visit_id
LEFT JOIN vessel_visits vvout ON
	vvout.vsl_id = eu.out_loc_id AND vvout.out_voy_nbr = eu.out_visit_id
WHERE 
	eu.gkey = '24404250'
;

--Reefer throughput by line by line for arriving vessels
WITH 
	year_and_month AS (
		SELECT 
			2022 + trunc((LEVEL-1)/12) AS YEAR
			, mod(LEVEL-1,12) + 1 AS MONTH
		FROM dual
		CONNECT BY LEVEL <= 24
	)
SELECT
	yam.YEAR
	, yam.MONTH
	, lo.name AS name
	, vv.vsl_line_id AS line
	, sum(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS exports 
	, sum(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS imports 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS transships 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS total  
FROM year_and_month yam
LEFT JOIN equipment_history eh ON 
	EXTRACT (YEAR FROM eh.posted) = yam.YEAR
	AND EXTRACT (MONTH FROM eh.posted) = yam.MONTH
LEFT JOIN equipment_uses eu ON 
	eu.gkey = eh.equse_gkey
LEFT JOIN vessel_visits vv ON 
	vv.vsl_id = eu.in_loc_id AND vv.in_voy_nbr = eu.in_visit_id
LEFT JOIN line_operators lo ON 
	vv.vsl_line_id = lo.id
GROUP BY
	yam.YEAR
	, yam.MONTH
	, lo.name
	, vv.vsl_line_id
ORDER BY 
	yam.YEAR
	, yam.MONTH
	, lo.name
; 

--Reefer throughput by line by line for departing vessels
WITH 
	year_and_month AS (
		SELECT 
			2022 + trunc((LEVEL-1)/12) AS YEAR
			, mod(LEVEL-1,12) + 1 AS MONTH
		FROM dual
		CONNECT BY LEVEL <= 24
	)
SELECT
	yam.YEAR
	, yam.MONTH
	, lo.name AS name
	, vv.vsl_line_id AS line
	, sum(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS exports 
	, sum(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS imports 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS transships 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS total  
FROM year_and_month yam
LEFT JOIN equipment_history eh ON 
	EXTRACT (YEAR FROM eh.posted) = yam.YEAR
	AND EXTRACT (MONTH FROM eh.posted) = yam.MONTH
LEFT JOIN equipment_uses eu ON 
	eu.gkey = eh.equse_gkey
LEFT JOIN vessel_visits vv ON 
	vv.vsl_id = eu.out_loc_id AND vv.out_voy_nbr = eu.out_visit_id
LEFT JOIN line_operators lo ON 
	vv.vsl_line_id = lo.id
GROUP BY
	yam.YEAR
	, yam.MONTH
	, lo.name
	, vv.vsl_line_id
ORDER BY 
	yam.YEAR
	, yam.MONTH
	, lo.name
; 

--Unaggregated reefer data including lines
SELECT
	EXTRACT (YEAR FROM eh.posted) AS YEAR
	, EXTRACT (MONTH FROM eh.posted) AS MONTH
	, eh.eq_nbr
	, lo_cont.name AS container_line
	, eh.line_id AS container_line_abbrev
	, lo_in.name AS inbound_vessel_line
	, vvin.vsl_line_id AS inbound_line_abbrev
	, lo_out.name AS outbount_vessel_line
	, vvout.vsl_line_id AS outbound_line_abbrev
FROM equipment_history eh
LEFT JOIN line_operators lo_cont ON 
	eh.line_id = lo_cont.id
LEFT JOIN equipment_uses eu ON 
	eu.gkey = eh.equse_gkey
LEFT JOIN vessel_visits vvin ON 
	vvin.vsl_id = eu.in_loc_id AND vvin.in_voy_nbr = eu.in_visit_id
LEFT JOIN line_operators lo_in ON
	lo_in.id = vvin.vsl_line_id
LEFT JOIN vessel_visits vvout ON 
	vvout.vsl_id = eu.out_loc_id AND vvout.out_voy_nbr = eu.out_visit_id
LEFT JOIN line_operators lo_out ON 
	lo_out.id = vvout.vsl_line_id
WHERE 
	(EXTRACT (YEAR FROM eh.posted) = 2022
	OR EXTRACT (YEAR FROM eh.posted) = 2023)
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
	AND eh.temp_required IS NOT NULL 
ORDER BY 
	1, 2, 4, 3
;

--query for Galen's spreadsheet
SELECT 
	to_char(trunc(eh.posted, 'MM'),'MM/DD/YYYY') AS analysis_month
	, 'DRS' AS terminal_key
	, eh.line_id
	, sum (CASE WHEN eh.temp_required IS NOT NULL AND eh.temp_required <= 30 THEN 1 ELSE 0 END) AS ntt_total_reefers
	, 'Oracle' AS platform
FROM equipment_history eh
WHERE 
	(EXTRACT (YEAR FROM eh.posted) = 2023
	 OR EXTRACT (YEAR FROM eh.posted) = 2024)
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
GROUP BY trunc(eh.posted, 'MM'), eh.line_id
ORDER BY trunc(eh.posted, 'MM'), eh.line_id
;