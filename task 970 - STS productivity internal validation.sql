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
	ORDER BY vv.atd, vv.vsl_id, vv.in_voy_nbr
), crane_work_times AS (
	SELECT
		vvoi.VSL_ID 
		, vvoi.IN_VOY_NBR 
		, vvoi.OUT_VOY_NBR 
		, vvoi.atd
		, vvoi.gross_hours
		, vvoi.net_hours
		, eh.CRANE_NO 
		, sum(CASE WHEN eh.wtask_id IN ('LOAD','UNLOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT') THEN 1 ELSE 0 END) AS all_moves
		, sum(CASE WHEN eh.wtask_id IN ('LOAD','UNLOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT') AND eh.crane_no IS NOT NULL THEN 1 ELSE 0 END) AS sf_moves
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
	ORDER BY vvoi.atd, vvoi.vsl_id, vvoi.in_voy_nbr
)
SELECT 
	cwt.vsl_id
	, cwt.in_voy_nbr
	, cwt.out_voy_nbr
	, sum(cwt.all_moves) AS all_moves
	, sum(cwt.sf_moves) AS sf_moves
	, sum(cwt.crane_work_hours) AS work_hours
	, cwt.gross_hours
	, cwt.net_hours
	, CASE WHEN sum(cwt.crane_work_hours) = 0 THEN NULL ELSE sum(cwt.all_moves) / sum(cwt.crane_work_hours) END AS "RAW_all"
	, CASE WHEN cwt.gross_hours = 0 THEN NULL ELSE sum(cwt.all_moves) / cwt.gross_hours END AS gross_all
	, CASE WHEN cwt.net_hours = 0 THEN NULL ELSE sum(cwt.all_moves) / cwt.net_hours END AS net_all
	, CASE WHEN sum(cwt.crane_work_hours) = 0 THEN NULL ELSE sum(cwt.sf_moves) / sum(cwt.crane_work_hours) END AS "RAW_sf"
	, CASE WHEN cwt.gross_hours = 0 THEN NULL ELSE sum(cwt.sf_moves) / cwt.gross_hours END AS gross_sf
	, CASE WHEN cwt.net_hours = 0 THEN NULL ELSE sum(cwt.sf_moves) / cwt.net_hours END AS net_sf
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

--Applying Joseph's raw crane work time computation
WITH vessel_visits_of_interest AS (
	SELECT
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, coalesce(vv.ata, vv.eta) AS arrival_time
		, coalesce(vv.atd, vv.etd) AS departure_time
		, vv.gross_hours
		, vv.net_hours
	FROM vessel_visits vv
	WHERE EXTRACT (YEAR FROM vv.atd) IN ('2022','2023')
	--ORDER BY vv.atd, vv.vsl_id, vv.in_voy_nbr
), noisy_components_by_move AS (
	SELECT
		vvoi.vsl_id
		, vvoi.in_voy_nbr
		, vvoi.out_voy_nbr
		, vvoi.arrival_time
		, vvoi.departure_time
		, vvoi.gross_hours
		, vvoi.net_hours
		, eh.crane_no
		, eh.posted AS move_start_time
		, lead (eh.posted) OVER (PARTITION BY eh.crane_no ORDER BY eh.posted ASC) AS move_end_time 
	FROM vessel_visits_of_interest vvoi
	LEFT JOIN equipment_history eh ON
		eh.vsl_id = vvoi.vsl_id
		AND (eh.voy_nbr = vvoi.in_voy_nbr OR eh.voy_nbr = vvoi.out_voy_nbr)
	--ORDER BY vvoi.departure_time, vvoi.vsl_id, vvoi.in_voy_nbr, eh.crane_no, eh.posted
), components_by_move AS (
	SELECT 
		noise.vsl_id
		, noise.in_voy_nbr
		, noise.out_voy_nbr
		, noise.arrival_time
		, noise.departure_time
		, noise.gross_hours
		, noise.net_hours
		, noise.crane_no
		, greatest (noise.move_start_time,COALESCE (noise.arrival_time,noise.move_start_time)) AS move_start_time
		, least (noise.move_end_time, COALESCE (noise.departure_time, noise.move_end_time)) AS move_end_time
	FROM noisy_components_by_move noise
	WHERE noise.move_start_time BETWEEN noise.arrival_time AND noise.departure_time
)
SELECT 
	cbm.vsl_id
	, cbm.in_voy_nbr
	, cbm.out_voy_nbr
	, cbm.arrival_time
	, cbm.departure_time
	, cbm.gross_hours
	, cbm.net_hours
	, count(*) AS moves
	, sum (CASE WHEN cbm.crane_no IS NOT NULL THEN 1 ELSE 0 END) AS sf_moves
	, sum (cbm.move_end_time - cbm.move_start_time) AS worktime
FROM components_by_move cbm
GROUP BY 
	cbm.vsl_id
	, cbm.in_voy_nbr
	, cbm.out_voy_nbr
	, cbm.arrival_time
	, cbm.departure_time
	, cbm.gross_hours
	, cbm.net_hours
ORDER BY
	cbm.departure_time
	, cbm.vsl_id
	, cbm.in_voy_nbr
;

--Replicating Joseph's crane worktime approach
WITH crane_move_batches AS (
	SELECT
		eh.vsl_id
		, eh.voy_nbr
		, eh.crane_no
		, eh.posted
		, count (DISTINCT eh.eq_nbr) AS moves
	FROM equipment_history eh
	WHERE
		eh.crane_no IS NOT NULL 
		AND upper(eh.crane_no) NOT LIKE 'TEST%'
		AND eh.eq_class = 'CTR'
		AND eh.wtask_id IN ('LOAD','UNLOAD','REHCD','REHCDT','REHDC','REHDCT','REHCC','REHCCT')
	GROUP BY 
		eh.vsl_id
		, eh.voy_nbr
		, eh.crane_no
		, eh.posted
), worktimes_1 AS (
	SELECT
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, coalesce(vv.ata, vv.eta) AS arrival_time
		, coalesce(vv.atd, vv.etd) AS departure_time
		, vv.gross_hours
		, vv.net_hours
		, cmb.crane_no
		, cmb.posted
		, cmb.moves
		, lead(cmb.posted) OVER (PARTITION BY cmb.crane_no ORDER BY cmb.posted ASC) AS next_posted
	FROM vessel_visits vv
	JOIN crane_move_batches cmb ON
		cmb.vsl_id = vv.vsl_id
		AND (cmb.voy_nbr = vv.in_voy_nbr OR cmb.voy_nbr = vv.out_voy_nbr)
		AND cmb.posted BETWEEN coalesce(vv.ata, vv.eta) AND coalesce(vv.atd, vv.etd)
	WHERE EXTRACT (YEAR FROM vv.atd) IN ('2022','2023')
), worktimes_2 AS (
	SELECT
		wt1.*
		, least(wt1.departure_time,COALESCE(wt1.next_posted,wt1.departure_time)) AS move_endtime
		, (least(wt1.departure_time,COALESCE(wt1.next_posted,wt1.departure_time)) - wt1.posted) * 24 AS worktime
	FROM worktimes_1 wt1
)
SELECT
	wt2.vsl_id
	, wt2.in_voy_nbr
	, wt2.out_voy_nbr
	, wt2.arrival_time
	, wt2.departure_time
	, wt2.gross_hours
	, wt2.net_hours
	, sum (wt2.moves)
	, sum (wt2.worktime)
FROM worktimes_2 wt2
GROUP BY 
	wt2.vsl_id
	, wt2.in_voy_nbr
	, wt2.out_voy_nbr
	, wt2.arrival_time
	, wt2.departure_time
	, wt2.gross_hours
	, wt2.net_hours
ORDER BY 
	wt2.departure_time
	, wt2.vsl_id
;

SELECT 
	eh.crane_no
	, eh.posted
FROM equipment_history eh 
WHERE 
	eh.vsl_id = 'MSCMONT' 
	AND (eh.voy_nbr = '148A' OR eh.voy_nbr = '152R') 
	AND eh.eq_class = 'CTR'
ORDER BY
	eh.crane_no
	, eh.posted
;

SELECT * FROM vessel_visits WHERE vsl_id = 'MSCMONT' AND in_voy_nbr = '148A';

SELECT
	eh.vsl_id
	, eh.voy_nbr
	, eh.crane_no
	, eh.posted
FROM equipment_history eh
WHERE
	eh.posted BETWEEN to_date('2022-01-07','YYYY-MM-DD') AND to_date('2022-01-12','YYYY-MM-DD')
	AND (eh.crane_no IS NULL OR eh.crane_no IN ('15','16','17','18')) 
	AND eh.wtask_id IN ('LOAD','UNLOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
	AND eh.eq_class = 'CTR'
ORDER BY 
	eh.crane_no
	, eh.posted
;