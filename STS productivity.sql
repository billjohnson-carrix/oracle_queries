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

/*
 *  There are surprisingly large differences between the first and last move times from equipment_history and vessel_summary_details.
 *  The first issue is that vsd has first and last move for the vessel instead of by crane. That doesn't seem right to me. I'll ask Kevin about it tomorrow.
 *  I think I need to use ATA or ATD from vessel visits, unless those are null, in which case I'll use min(posted) and max(posted) from equipment_history
 *  Sometimes the vsd table has first or last moves before or after the ata or atd.
 *  I want to add the move count column to the above query to so that I can see if the vessels with problem time data have a small number of moves.
 *  First, though, I think I should probably build the metric using the expected tables so that I have that work as a reference
 *  for building the metric with equipment_history.
 */

--In MIT UAT, the most recent record with a 'Final' status is from May of 2019.
SELECT 
	* 
FROM VESSEL_SUMMARY_DETAIL vsd 
WHERE 
	vsd.STATUS = 'Final' 
	--AND trunc(vsd.LAST_MOVE) BETWEEN TO_DATE('2022-01-01','YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')
;

--It looks to me like the VSD table is missing around 25% of the vessel visits.
SELECT 
	EXTRACT (YEAR FROM vsd.LAST_MOVE)
	, EXTRACT (MONTH FROM vsd.LAST_MOVE)
	, count(*)
FROM VESSEL_SUMMARY_DETAIL vsd 
WHERE trunc(vsd.LAST_MOVE) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
GROUP BY EXTRACT (YEAR FROM vsd.LAST_MOVE), EXTRACT (MONTH FROM vsd.LAST_MOVE)
ORDER BY EXTRACT (YEAR FROM vsd.LAST_MOVE), EXTRACT (MONTH FROM vsd.LAST_MOVE)
;

--Here's the count of vessel visits using the throughput query
WITH 
	by_vessel AS (
		SELECT
			v.name
			, vv.VSL_ID 
			, vv.in_VOY_NBR
			, vv.OUT_VOY_NBR 
			, COALESCE (trunc(vv.atd), max(trunc(eh.posted))) AS dt
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
		--ORDER BY COALESCE (trunc(vv.atd), max(trunc(eh.posted)))
	) 
SELECT
	EXTRACT (YEAR FROM bv.dt) AS Year
	, EXTRACT (MONTH FROM bv.dt) AS month
	, count(*)
FROM by_vessel bv
GROUP BY EXTRACT (YEAR FROM bv.dt), EXTRACT (MONTH FROM bv.dt)
ORDER BY EXTRACT (YEAR FROM bv.dt), EXTRACT (MONTH FROM bv.dt)
;

/*
 *  So even AT MIT the vessel_summary_detail approach won't WORK. 'Final' status isn't used IN UAT AND the NUMBER OF vessel visits IS too few.
 *  Before abandoning vsd, let's take a look at the only other terminal in the set of 5 pilot terminals that use it, ZLO.
 */

--Now for ZLO
SELECT 
	EXTRACT (YEAR FROM vsd.LAST_MOVE)
	, EXTRACT (MONTH FROM vsd.LAST_MOVE)
	, count(*)
FROM VESSEL_SUMMARY_DETAIL vsd 
WHERE trunc(vsd.LAST_MOVE) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
GROUP BY EXTRACT (YEAR FROM vsd.LAST_MOVE), EXTRACT (MONTH FROM vsd.LAST_MOVE)
ORDER BY EXTRACT (YEAR FROM vsd.LAST_MOVE), EXTRACT (MONTH FROM vsd.LAST_MOVE)
;

WITH 
	by_vessel AS (
		SELECT
			v.name
			, vv.VSL_ID 
			, vv.in_VOY_NBR
			, vv.OUT_VOY_NBR 
			, COALESCE (trunc(vv.atd), max(trunc(eh.posted))) AS dt
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
		--ORDER BY COALESCE (trunc(vv.atd), max(trunc(eh.posted)))
	) 
SELECT
	EXTRACT (YEAR FROM bv.dt) AS Year
	, EXTRACT (MONTH FROM bv.dt) AS month
	, count(*)
FROM by_vessel bv
GROUP BY EXTRACT (YEAR FROM bv.dt), EXTRACT (MONTH FROM bv.dt)
ORDER BY EXTRACT (YEAR FROM bv.dt), EXTRACT (MONTH FROM bv.dt)
;

/*
 *  The vsd approach may work for ZLO. The number of vessel visits is correct.
 */ 

--Starting VSD approach for ZLO. 'S' is a delay attributed to the shipping line. 'T' is a delay attributed to the terminal.
--This looks like a good dataset for computation.
SELECT 
	vsd.GKEY 
	, vsd.VSL_ID 
	, vsd.VOY_IN_NBR 
	, vsd.VOY_OUT_NBR 
	, vsd.FIRST_MOVE AS vsl_1st_move
	, vsd.LAST_MOVE AS vsl_last_move
	, vsc.CRANE_ID 
	, vsc.TOTAL_MOVES 
	, vscp.COMMENCED AS crane_start
	, vscp.COMPLETED AS crane_finish
	, vsy.DELAY_CODE 
	, vsy.DELAY_TIME 
	, dr.delay_level
FROM vessel_summary_detail vsd
LEFT JOIN VESSEL_SUMMARY_CRANES vsc ON vsd.gkey = vsc.VSD_GKEY
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vsd.gkey = vscp.vsd_gkey AND vsc.crane_id = vscp.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_DELAYS vsy ON vsd.gkey = vsy.VSD_GKEY AND vsc.CRANE_ID = vsy.CRANE_ID 
LEFT JOIN delay_reasons dr ON vsy.DELAY_CODE = dr.CODE 
WHERE 
	vsd.status = 'Final'
	AND trunc(vsd.last_move) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
ORDER BY vsd.LAST_MOVE, vsc.CRANE_ID, vscp.completed, dr.DELAY_LEVEL 
;

--Now to compute productivities. This seems to work.
SELECT 
	vsd.GKEY 
	, vsd.VSL_ID 
	, vsd.VOY_IN_NBR 
	, vsd.VOY_OUT_NBR 
	, vsd.FIRST_MOVE AS vsl_1st_move
	, vsd.LAST_MOVE AS vsl_last_move
	, vsc.CRANE_ID 
	, vsc.TOTAL_MOVES 
	, vscp.COMMENCED AS crane_start
	, vscp.COMPLETED AS crane_finish
	, (vscp.completed - vscp.commenced) * 24 AS crane_work_time
	, CASE 
		WHEN (vscp.completed - vscp.commenced) = 0 THEN NULL 
		ELSE vsc.total_moves / (vscp.completed - vscp.commenced) / 24
	  END AS raw_productivity
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
	, CASE 
		WHEN ((vscp.completed - vscp.commenced) * 24 - sum (
			CASE 
				WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END)) = 0 THEN NULL
		ELSE 
			vsc.total_moves / ((vscp.completed - vscp.commenced) * 24 - sum (
			CASE 
				WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END))
	  END AS gross_productivity
	, sum (
		CASE 
			WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS terminal_delays
	, CASE 
		WHEN ((vscp.completed - vscp.commenced) * 24 - sum (
			CASE 
				WHEN vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END)) = 0 THEN NULL 
		ELSE vsc.total_moves / ((vscp.completed - vscp.commenced) * 24 - sum (
			CASE 
				WHEN vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END))
	  END AS net_productivity
FROM vessel_summary_detail vsd
LEFT JOIN VESSEL_SUMMARY_CRANES vsc ON vsd.gkey = vsc.VSD_GKEY
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vsd.gkey = vscp.vsd_gkey AND vsc.crane_id = vscp.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_DELAYS vsy ON vsd.gkey = vsy.VSD_GKEY AND vsc.CRANE_ID = vsy.CRANE_ID 
LEFT JOIN delay_reasons dr ON vsy.DELAY_CODE = dr.CODE 
WHERE 
	vsd.status = 'Final'
	AND trunc(vsd.last_move) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
GROUP BY vsd.gkey, vsd.VSL_ID, vsd.VOY_IN_NBR, vsd.VOY_OUT_NBR, vsd.FIRST_MOVE, vsd.LAST_MOVE, vsc.CRANE_ID, vsc.TOTAL_MOVES, vscp.COMMENCED, vscp.COMPLETED 
ORDER BY vsd.LAST_MOVE, vsc.CRANE_ID, vscp.completed
;

--Now let's get monthly averages. This seems to work.
SELECT 
	EXTRACT (YEAR FROM vsd.last_move)
	, EXTRACT (MONTH FROM vsd.last_move)
	, sum(vsc.TOTAL_MOVES)
	, sum(vscp.completed - vscp.commenced) * 24 AS crane_work_time
	, CASE 
		WHEN sum(vscp.completed - vscp.commenced) = 0 THEN NULL 
		ELSE sum(vsc.total_moves) / sum(vscp.completed - vscp.commenced) / 24
	  END AS raw_productivity
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
	, CASE 
		WHEN sum ((vscp.completed - vscp.commenced) * 24 - 
			CASE 
				WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END) = 0 THEN NULL
		ELSE 
			sum(vsc.total_moves) / sum ((vscp.completed - vscp.commenced) * 24 - 
			CASE 
				WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END)
	  END AS gross_productivity
	, sum (
		CASE 
			WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS terminal_delays
	, CASE 
		WHEN sum ((vscp.completed - vscp.commenced) * 24 -
			CASE 
				WHEN vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END) = 0 THEN NULL 
		ELSE sum (vsc.total_moves) / sum ((vscp.completed - vscp.commenced) * 24 - 
			CASE 
				WHEN vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END)
	  END AS net_productivity
FROM vessel_summary_detail vsd
LEFT JOIN VESSEL_SUMMARY_CRANES vsc ON vsd.gkey = vsc.VSD_GKEY
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vsd.gkey = vscp.vsd_gkey AND vsc.crane_id = vscp.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_DELAYS vsy ON vsd.gkey = vsy.VSD_GKEY AND vsc.CRANE_ID = vsy.CRANE_ID 
LEFT JOIN delay_reasons dr ON vsy.DELAY_CODE = dr.CODE 
WHERE 
	vsd.status = 'Final'
	AND trunc(vsd.last_move) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
GROUP BY EXTRACT (YEAR FROM vsd.last_move), EXTRACT (MONTH FROM vsd.last_move) 
ORDER BY EXTRACT (YEAR FROM vsd.last_move), EXTRACT (MONTH FROM vsd.last_move)
;

--Now to build the equipment_history approach. I think I'll build it on MIT UAT and then transfer the queries to ZLO UAT 2 because
--MIT UAT is much more responsive.

--Vessel visits with large time differences between the eh start/end times and the vsd start/end times do not correlate 
--with visits that have low move counts on the MIT UAT server.
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
	, sum(vsc.TOTAL_MOVES)
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
LEFT JOIN VESSEL_SUMMARY_CRANES vsc ON vsd.gkey = vsc.VSD_GKEY 
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

--Now to join with the various vessel summary tables to get the delays.
--2,211,386 transactions from eh and after all left joins.

--The vessel_summary_cranes table does not have unique rows indexed by vsd_gkey and crane_no. I'll have to fix up my own.

--This query allocates the vsd, vsc, and vscp tables to eh transactions. There can be multipled delays per crane, so delays would multiply the
--count of transactions. This can be grouped by vsl_id, voy nbrs, and crane and ordered by eh.posted to produce crane letters. :-)
WITH pkd_vsc AS (
	SELECT 
		vsc.VSD_GKEY 
		, vsc.CRANE_ID 
		, sum(vsc.completed - vsc.commenced) AS crane_work_time
		, sum(vsc.total_moves) AS total_moves
	FROM vessel_summary_cranes vsc
	GROUP BY 
		vsc.VSD_GKEY 
		, vsc.CRANE_ID 
)
SELECT
	--count(*)
	v.name 
	, vv.VSL_ID  
	, vv.in_VOY_NBR 
	, vv.OUT_VOY_NBR  
	, vv.ATA 
	, vv.atd
	, eh.crane_no
	, vsd.FIRST_MOVE 
	, vsd.LAST_MOVE 
	, vsc.CRANE_ID 
	, vsc.TOTAL_MOVES 
	, vsc.crane_work_time
	, vscp.COMMENCED AS vscp_commenced
	, vscp.COMPLETED AS vscp_completed
	, eh.*
FROM EQUIPMENT_HISTORY eh  
LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON vsd.VSL_ID = vv.VSL_ID AND vsd.VOY_IN_NBR = vv.IN_VOY_NBR AND vsd.voy_out_nbr = vv.OUT_VOY_NBR 
LEFT JOIN pkd_vsc vsc ON vsc.VSD_GKEY = vsd.GKEY AND eh.crane_no = vsc.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = eh.crane_no
WHERE  
	trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
	AND eh.vsl_id IS NOT NULL 
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
ORDER BY vv.atd, eh.CRANE_NO, eh.posted
;

--Crane letters as performed and recorded in the TOS.
WITH pkd_vsc AS (
	SELECT 
		vsc.VSD_GKEY 
		, vsc.CRANE_ID 
		, sum(vsc.completed - vsc.commenced) AS crane_work_time
		, sum(vsc.total_moves) AS total_moves
	FROM vessel_summary_cranes vsc
	GROUP BY 
		vsc.VSD_GKEY 
		, vsc.CRANE_ID 
)
SELECT
	--count(*)
	v.name 
	, vv.VSL_ID  
	, vv.in_VOY_NBR 
	, vv.OUT_VOY_NBR  
	, vv.atd
	, eh.crane_no
	, vsc.TOTAL_MOVES 
	, vsc.crane_work_time
	, eh.*
FROM EQUIPMENT_HISTORY eh  
LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON vsd.VSL_ID = vv.VSL_ID AND vsd.VOY_IN_NBR = vv.IN_VOY_NBR AND vsd.voy_out_nbr = vv.OUT_VOY_NBR 
LEFT JOIN pkd_vsc vsc ON vsc.VSD_GKEY = vsd.GKEY AND eh.crane_no = vsc.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = eh.crane_no
WHERE  
	trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
	AND eh.vsl_id IS NOT NULL 
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
ORDER BY
	v.name 
	, vv.VSL_ID  
	, vv.in_VOY_NBR 
	, vv.OUT_VOY_NBR  
	, vv.atd
	, eh.crane_no
	, vsc.TOTAL_MOVES 
	, vsc.crane_work_time
	, eh.posted
;

--Comparing the total_moves in the vessel summary to the count of transactions in eh.
--There are 12% more transactions in eh than are counted in total_moves.
--That might be enough to bring the ZLO numbers into better agreement with what's reported.
--Many vessels are in exact agreement too. Almost all of the additional counts come from vessel
--visits that are missing from vessel summary data. It might not help ZLO afterall.
WITH pkd_vsc AS (
	SELECT 
		vsc.VSD_GKEY 
		, vsc.CRANE_ID 
		, sum(vsc.completed - vsc.commenced) AS crane_work_time
		, sum(vsc.total_moves) AS total_moves
	FROM vessel_summary_cranes vsc
	GROUP BY 
		vsc.VSD_GKEY 
		, vsc.CRANE_ID 
)
SELECT
	--count(*)
	v.name 
	, vv.VSL_ID  
	, vv.in_VOY_NBR 
	, vv.OUT_VOY_NBR  
	, vv.atd
	, eh.crane_no
	, vsc.TOTAL_MOVES 
	, count(*)
FROM EQUIPMENT_HISTORY eh  
LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON vsd.VSL_ID = vv.VSL_ID AND vsd.VOY_IN_NBR = vv.IN_VOY_NBR AND vsd.voy_out_nbr = vv.OUT_VOY_NBR 
LEFT JOIN pkd_vsc vsc ON vsc.VSD_GKEY = vsd.GKEY AND eh.crane_no = vsc.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = eh.crane_no
WHERE  
	trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
	AND eh.vsl_id IS NOT NULL 
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
GROUP BY 
	v.name 
	, vv.VSL_ID  
	, vv.in_VOY_NBR 
	, vv.OUT_VOY_NBR  
	, vv.atd
	, eh.crane_no
	, vsc.TOTAL_MOVES 
;

--Now to join the delays and compute productivities
--Shipping delays is producing wrong numbers. So is Terminal delays. I suspect the group by.
--Eh worktime is wrong too. It should use ata and atd unless null and then use min/max eh.posted only in that case.
WITH pkd_vsc AS (
	SELECT 
		vsc.VSD_GKEY 
		, vsc.CRANE_ID 
		, sum(vsc.completed - vsc.commenced) AS crane_work_time
		, sum(vsc.total_moves) AS total_moves
	FROM vessel_summary_cranes vsc
	GROUP BY 
		vsc.VSD_GKEY 
		, vsc.CRANE_ID 
)
SELECT
	--count(*)
	v.name 
	, vv.VSL_ID  
	, vv.in_VOY_NBR 
	, vv.OUT_VOY_NBR  
	, vv.ATA 
	, vv.atd
	, eh.crane_no
	, vsd.gkey
	, vsd.FIRST_MOVE 
	, vsd.LAST_MOVE 
	, vsc.CRANE_ID 
	, vsc.TOTAL_MOVES AS vsd_moves
	, vsc.crane_work_time AS vsd_crane_work_time
	, CASE 
		WHEN vsc.crane_work_time = 0 THEN NULL 
		ELSE vsc.total_moves / vsc.crane_work_time / 24
	  END AS vsd_raw_productivity
	, count(*) AS eh_moves
	, max(eh.posted) - min(eh.posted) AS eh_crane_work_time
	, CASE 
		WHEN max(eh.posted) - min(eh.posted) = 0 THEN NULL 
		ELSE count(*) / (max(eh.posted) - min(eh.posted)) / 24
	  END AS eh_raw_productivity
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
	, CASE 
		WHEN (vsc.crane_work_time * 24 - sum (
			CASE 
				WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END)) = 0 THEN NULL
		ELSE 
			vsc.total_moves / (vsc.crane_work_time * 24 - sum (
			CASE 
				WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END))
	  END AS vsd_gross_productivity
	, CASE 
		WHEN ((max(eh.posted) - min(eh.posted)) * 24 - sum (
			CASE 
				WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END)) = 0 THEN NULL
		ELSE 
			count(*) / ((max(eh.posted) - min(eh.posted)) * 24 - sum (
			CASE 
				WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END))
	  END AS eh_gross_productivity
	, sum (
		CASE 
			WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS terminal_delays
	, CASE 
		WHEN (vsc.crane_work_time * 24 - sum (
			CASE 
				WHEN vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END)) = 0 THEN NULL 
		ELSE vsc.total_moves / (vsc.crane_work_time * 24 - sum (
			CASE 
				WHEN vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END))
	  END AS vsd_net_productivity
	, CASE 
		WHEN ((max(eh.posted) - min(eh.posted)) * 24 - sum (
			CASE 
				WHEN vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END)) = 0 THEN NULL 
		ELSE count(*) / ((max(eh.posted) - min(eh.posted)) * 24 - sum (
			CASE 
				WHEN vsy.delay_time IS NOT NULL THEN
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
				ELSE 0
			END))
	  END AS eh_net_productivity
FROM EQUIPMENT_HISTORY eh  
LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON vsd.VSL_ID = vv.VSL_ID AND vsd.VOY_IN_NBR = vv.IN_VOY_NBR AND vsd.voy_out_nbr = vv.OUT_VOY_NBR 
LEFT JOIN pkd_vsc vsc ON vsc.VSD_GKEY = vsd.GKEY AND eh.crane_no = vsc.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = eh.crane_no
LEFT JOIN vessel_summary_delays	vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = eh.crane_no
LEFT JOIN delay_reasons dr ON vsy.DELAY_CODE = dr.CODE 
WHERE  
	trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
	AND eh.vsl_id IS NOT NULL 
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
GROUP BY 
	v.name 
	, vv.VSL_ID  
	, vv.in_VOY_NBR 
	, vv.OUT_VOY_NBR  
	, vv.ATA 
	, vv.atd
	, eh.crane_no
	, vsd.gkey
	, vsd.FIRST_MOVE 
	, vsd.LAST_MOVE 
	, vsc.CRANE_ID 
	, vsc.TOTAL_MOVES 
	, vsc.crane_work_time
	, vscp.COMMENCEd
	, vscp.COMPLETED
ORDER BY vv.atd, eh.CRANE_NO 
;