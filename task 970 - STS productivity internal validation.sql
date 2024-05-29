SELECT
	vv.vsl_id
	, vv.in_voy_nbr
	, vv.out_voy_nbr
	, vv.atd
	, vv.gross_hours
	, vv.net_hours
FROM vessel_visits vv
WHERE EXTRACT (YEAR FROM vv.atd) IN ('2022','2023')
ORDER BY vv.atd, vv.vsl_id, vv.in_voy_nbr
--FETCH FIRST 20 ROWS ONLY 
;

WITH vessel_visits_of_interest AS (
	SELECT
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.ata
		, vv.atd
		, vv.gross_hours
		, vv.net_hours
	FROM vessel_visits vv
	WHERE EXTRACT (YEAR FROM vv.atd) IN ('2022','2023')
--	ORDER BY vv.atd, vv.vsl_id, vv.in_voy_nbr
), crane_work_times AS (
	SELECT
		vvoi.VSL_ID 
		, vvoi.IN_VOY_NBR 
		, vvoi.OUT_VOY_NBR 
		, vvoi.atd
		, vvoi.gross_hours
		, vvoi.net_hours
		, eh.CRANE_NO 
		, sum(CASE WHEN eh.wtask_id IN ('LOAD','UNLOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT') THEN 1 ELSE 0 END) AS moves
		, GREATEST(MIN(eh.posted),COALESCE(vvoi.ata,MIN(eh.posted))) AS start_time
		, LEAST(MAX(eh.POSTED),COALESCE(vvoi.atd,MAX(eh.posted))) AS end_time 
		, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vvoi.atd,MAX(eh.posted))) - 
			GREATEST(MIN(eh.posted),COALESCE(vvoi.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
	FROM vessel_visits_of_interest vvoi
	LEFT JOIN equipment_history eh ON
		eh.vsl_id = vvoi.vsl_id
		AND (eh.voy_nbr = vvoi.in_voy_nbr OR eh.voy_nbr = vvoi.out_voy_nbr)
	GROUP BY 
		vvoi.VSL_ID 
		, vvoi.IN_VOY_NBR 
		, vvoi.OUT_VOY_NBR 
		, vvoi.ATA
		, vvoi.ATD 
		, vvoi.gross_hours
		, vvoi.net_hours
		, eh.CRANE_NO 	
)
SELECT 
	cwt.vsl_id
	, cwt.in_voy_nbr
	, cwt.out_voy_nbr
	, sum(cwt.moves) AS moves
	, sum(cwt.crane_work_hours) AS work_hours
	, cwt.gross_hours
	, cwt.net_hours
	, CASE WHEN sum(cwt.crane_work_hours) = 0 THEN NULL ELSE sum(cwt.moves) / sum(cwt.crane_work_hours) END AS "RAW"
	, CASE WHEN cwt.gross_hours = 0 THEN NULL ELSE sum(cwt.moves) / cwt.gross_hours END AS gross
	, CASE WHEN cwt.net_hours = 0 THEN NULL ELSE sum(cwt.moves) / cwt.net_hours END AS net
FROM crane_work_times cwt 
GROUP BY 
	cwt.vsl_id
	, cwt.in_voy_nbr
	, cwt.out_voy_nbr
	, cwt.atd
	, cwt.gross_hours
	, cwt.net_hours
ORDER BY cwt.atd, cwt.vsl_id, cwt.atd
;