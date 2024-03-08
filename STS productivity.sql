-- Looking at MIT UAT for STS information that's relatable to the equipment_history table
SELECT 
	eh.WTASK_ID 
	, eh.TRANSSHIP 
	, eh.EQ_NBR 
	, eh.CRANE_NO 
FROM EQUIPMENT_HISTORY eh
WHERE 
	eh.WTASK_ID = 'LOAD'
	OR eh.WTASK_ID = 'UNLOAD'
;

--1732
SELECT count(*)
FROM EQUIPMENT_HISTORY eh 
WHERE 
	(eh.WTASK_ID = 'LOAD' OR eh.WTASK_ID = 'UNLOAD')
	AND eh.POSTED BETWEEN TO_DATE('2023-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
	AND eh.CRANE_NO IS NULL 
;

--681911  0.3% error is acceptable
SELECT count(*)
FROM EQUIPMENT_HISTORY eh 
WHERE 
	(eh.WTASK_ID = 'LOAD' OR eh.WTASK_ID = 'UNLOAD')
	AND eh.POSTED BETWEEN TO_DATE('2023-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
--	AND eh.CRANE_NO IS NULL 
;

--MIT and ZLO queries
SELECT 
	eh.CRANE_NO 
	, count(*)
FROM EQUIPMENT_HISTORY eh 
WHERE 
	(eh.WTASK_ID = 'LOAD' OR eh.WTASK_ID = 'UNLOAD')
	AND eh.POSTED BETWEEN TO_DATE('2023-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
GROUP BY eh.CRANE_NO 
ORDER BY eh.CRANE_NO 
;

--PCT query
SELECT 
	eh.CRANE_NO 
	, count(*)
FROM EQUIPMENT_HISTORY eh 
WHERE 
	(eh.WTASK_ID = 'LOAD' OR eh.WTASK_ID = 'UNLOAD')
	AND eh.POSTED BETWEEN TO_DATE('2022-03-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
GROUP BY eh.CRANE_NO 
ORDER BY eh.CRANE_NO 
;

--TAM query
SELECT 
	eh.CRANE_NO 
	, count(*)
FROM EQUIPMENT_HISTORY eh 
WHERE 
	(eh.WTASK_ID = 'LOAD' OR eh.WTASK_ID = 'UNLOAD')
	AND eh.POSTED BETWEEN TO_DATE('2021-03-01', 'YYYY-MM-DD') AND TO_DATE('2023-03-31', 'YYYY-MM-DD')  
GROUP BY eh.CRANE_NO 
ORDER BY eh.CRANE_NO 
;

--T5S query
SELECT 
	eh.CRANE_NO 
	, count(*)
FROM EQUIPMENT_HISTORY eh 
WHERE 
	(eh.WTASK_ID = 'LOAD' OR eh.WTASK_ID = 'UNLOAD')
	AND eh.POSTED BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2022-12-31', 'YYYY-MM-DD')  
GROUP BY eh.CRANE_NO 
ORDER BY eh.CRANE_NO 
;

--Equipment_history counts at C60
SELECT 
	EXTRACT (YEAR FROM posted)
	, EXTRACT (MONTH FROM posted)
	, count(*) 
FROM equipment_history
WHERE wtask_id = 'LOAD' OR wtask_id = 'UNLOAD'
GROUP BY EXTRACT (YEAR FROM posted), EXTRACT (MONTH FROM posted)
ORDER BY EXTRACT (YEAR FROM posted), EXTRACT (MONTH FROM posted)
;

--Using the crane_no column in equipment_history seems to work for the 4 SSA terminals in the set of 5 pilot terminals.
--TAM has null values for crane_no in over 98% of the equipment_history records between 2022-02-01 and 2022-12-31 which is a stretch of reasonably good data in UAT.

--The plan is to build a vessel visit list from equipment_history using work done previous for throughput.
--Then group by vessel and crane and compute the productivity from the count of moves and the time from first to last move.
--This computation lacks delays, but I don't see how that can be helped at the moment.

--Query from throughput work
--Date selection for MIT
WITH 
	by_vessel_almost AS (
		SELECT 
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, COALESCE (vv.atd, max(trunc(eh.posted))) AS dt 
			, sum (CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS imports 
			, sum (CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS exports 
			, sum (CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships 
			, count(*) AS moves 
		FROM EQUIPMENT_HISTORY eh  
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		JOIN VESSELS v ON vv.VSL_ID = v.ID  
		WHERE  
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
			AND eh.vsl_id IS NOT NULL 
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd 
	)
SELECT 
	*
FROM by_vessel_almost bva
WHERE bva.dt BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
ORDER BY bva.dt
;

--Modifying for STS productivity computation.
WITH 
	by_vessel_almost AS (
		SELECT 
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, COALESCE (vv.atd, max(trunc(eh.posted))) AS dt 
			, eh.crane_no
			, count(*)
			, min(eh.posted) AS first_move
			, max (eh.posted) AS last_move
			, max (eh.posted) - min (eh.posted) AS duration
			, 	CASE 
					WHEN max (eh.posted) - min (eh.posted) = 0 THEN NULL
					ELSE count(*) / (max (eh.posted) - min (eh.posted) ) / 24
				END AS raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		JOIN VESSELS v ON vv.VSL_ID = v.ID  
		WHERE  
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
			AND eh.vsl_id IS NOT NULL 
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd, eh.crane_no
	)
SELECT 
	*
FROM by_vessel_almost bva
WHERE bva.dt BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
ORDER BY bva.dt, bva.crane_no
;

--Now to collect the delays.
--10710 count
WITH 
	by_vessel_almost AS (
		SELECT 
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, COALESCE (vv.atd, max(trunc(eh.posted))) AS dt 
			, eh.crane_no
			, count(*)
			, min(eh.posted) AS first_move
			, max (eh.posted) AS last_move
			, max (eh.posted) - min (eh.posted) AS duration
			, 	CASE 
					WHEN max (eh.posted) - min (eh.posted) = 0 THEN NULL
					ELSE count(*) / (max (eh.posted) - min (eh.posted) ) / 24
				END AS raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		JOIN VESSELS v ON vv.VSL_ID = v.ID  
		WHERE  
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
			AND eh.vsl_id IS NOT NULL 
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd, eh.crane_no
	)
SELECT 
	count(*)
FROM by_vessel_almost bva
WHERE bva.dt BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
ORDER BY bva.dt, bva.crane_no
;

WITH 
	by_vessel_almost AS (
		SELECT 
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, COALESCE (vv.atd, max(trunc(eh.posted))) AS dt 
			, eh.crane_no
			, count(*) moves
			, min(eh.posted) AS first_move
			, max (eh.posted) AS last_move
			, max (eh.posted) - min (eh.posted) AS duration
			, 	CASE 
					WHEN max (eh.posted) - min (eh.posted) = 0 THEN NULL
					ELSE count(*) / (max (eh.posted) - min (eh.posted) ) / 24
				END AS raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		JOIN VESSELS v ON vv.VSL_ID = v.ID  
		WHERE  
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
			AND eh.vsl_id IS NOT NULL 
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd, eh.crane_no
	), by_vessel AS (
		SELECT 
			*
		FROM by_vessel_almost bva
		WHERE bva.dt BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY bva.dt, bva.crane_no
	)
SELECT 
	bv.name
	, bv.vsl_id
	, bv.in_voy_nbr
	, bv.out_voy_nbr
	, bv.dt
	, vsd.FIRST_MOVE AS vsd_first_move
	, vsd.LAST_MOVE AS vsd_last_move
	, vsd.LAST_MOVE - vsd.FIRST_MOVE AS vsd_duration
	, min (bv.first_move) AS eh_first_move
	, max (bv.last_move) AS eh_last_move
	, max (bv.last_move) - min (bv.first_move) AS eh_duration
	, min (bv.first_move) - vsd.FIRST_MOVE AS first_move_diff
	, max (bv.last_move) - vsd.LAST_MOVE AS last_move_diff
	, (max (bv.last_move) - min (bv.first_move)) - (vsd.LAST_MOVE - vsd.FIRST_MOVE) AS duration_diff
FROM by_vessel bv
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON 
	bv.vsl_id = vsd.vsl_id 
	AND bv.in_voy_nbr = vsd.voy_in_nbr 
	AND bv.out_voy_nbr = vsd.voy_out_nbr
GROUP BY
	bv.name
	, bv.vsl_id
	, bv.in_voy_nbr
	, bv.out_voy_nbr
	, bv.dt
	, vsd.FIRST_MOVE 
	, vsd.last_move 
ORDER BY bv.dt
;
--There are surprisingly large differences between the first and last move times from equipment_history and vessel_summary_details.
--The first issue is that vsd has first and last move for the vessel instead of by crane. That doesn't seem right to me. I'll ask Kevin about it tomorrow.
--I think I need to use ATA or ATD from vessel visits, unless those are null, in which case I'll use min(posted) and max(posted) from equipment_history
--Sometimes the vsd table has first or last moves before or after the ata or atd.
--I want to add the move count column to the above query to so that I can see if the vessels with problem time data have a small number of moves.