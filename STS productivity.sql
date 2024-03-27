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

--Let's simplify the query and see if we can find out what's wrong with the shipping delays.
--This query still gives the incorrect values.
SELECT
	--count(*)
	v.name 
	, vv.VSL_ID  
	, vv.in_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.atd
	, eh.crane_no
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
FROM EQUIPMENT_HISTORY eh  
LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON vsd.VSL_ID = vv.VSL_ID AND vsd.VOY_IN_NBR = vv.IN_VOY_NBR AND vsd.voy_out_nbr = vv.OUT_VOY_NBR 
LEFT JOIN vessel_summary_delays	vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = eh.crane_no
LEFT JOIN delay_reasons dr ON vsy.DELAY_CODE = dr.CODE 
WHERE  
	trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
	AND eh.vsl_id IS NOT NULL 
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
	AND vv.vsl_id = 'HUSUM' AND vv.IN_VOY_NBR = '152W' AND vv.out_voy_nbr = '152E'
GROUP BY 
	v.name 
	, vv.VSL_ID  
	, vv.in_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.atd
	, eh.crane_no
ORDER BY vv.atd, eh.CRANE_NO 
;

--This gives incorrect values
SELECT
	vsd.gkey
	, vsy.CRANE_ID 
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
FROM EQUIPMENT_HISTORY eh  
LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON vsd.VSL_ID = vv.VSL_ID AND vsd.VOY_IN_NBR = vv.IN_VOY_NBR AND vsd.voy_out_nbr = vv.OUT_VOY_NBR 
LEFT JOIN vessel_summary_delays	vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = eh.crane_no
LEFT JOIN delay_reasons dr ON vsy.DELAY_CODE = dr.CODE 
WHERE  
	trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
	AND eh.vsl_id IS NOT NULL 
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
	AND vv.vsl_id = 'HUSUM' AND vv.IN_VOY_NBR = '152W' AND vv.out_voy_nbr = '152E'
GROUP BY vsd.gkey, vsy.crane_id
;

--Yep, here's the problem. The delay time is getting multiplied by the number of completed moves. Oops.
--I need to group by crane for the moves before I group by crane again for the delays.
SELECT
	vsd.gkey
	, vsy.CRANE_ID 
	, vsy.delay_time
/*	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
*/FROM EQUIPMENT_HISTORY eh  
LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON vsd.VSL_ID = vv.VSL_ID AND vsd.VOY_IN_NBR = vv.IN_VOY_NBR AND vsd.voy_out_nbr = vv.OUT_VOY_NBR 
LEFT JOIN vessel_summary_delays	vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = eh.crane_no
LEFT JOIN delay_reasons dr ON vsy.DELAY_CODE = dr.CODE 
WHERE  
	trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
	AND eh.vsl_id IS NOT NULL 
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
	AND vv.vsl_id = 'HUSUM' AND vv.IN_VOY_NBR = '152W' AND vv.out_voy_nbr = '152E'
ORDER BY vsd.gkey, vsy.crane_id
;

--This gives correct values
SELECT
	vsd.gkey
	, vsy.CRANE_ID 
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
FROM VESSEL_VISITS vv  
LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON vsd.VSL_ID = vv.VSL_ID AND vsd.VOY_IN_NBR = vv.IN_VOY_NBR AND vsd.voy_out_nbr = vv.OUT_VOY_NBR 
LEFT JOIN vessel_summary_delays	vsy ON vsy.VSD_GKEY = vsd.GKEY
LEFT JOIN DELAY_REASONS dr ON dr.code = vsy.DELAY_CODE 
WHERE vv.vsl_id = 'HUSUM' AND vv.in_voy_nbr = '152W' AND vv.out_voy_nbr = '152E'
GROUP BY vsd.gkey, vsy.crane_id
;

--This query gives the correct values.
SELECT
	vsy.CRANE_ID 
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
FROM vessel_summary_delays vsy 
JOIN DELAY_REASONS dr ON dr.code = vsy.DELAY_CODE 
WHERE vsy.VSD_GKEY = '47548'
GROUP BY vsy.crane_id
;

--Delays for the HUSUM 152W
SELECT * FROM vessel_summary_delays vsy WHERE vsy.VSD_GKEY = '47548';

--Grouping by crane twice
-- This gives the correct values
WITH 
	group_by_crane_for_moves AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.atd
			, eh.CRANE_no 
			, count(*) AS moves
		FROM EQUIPMENT_HISTORY eh  
		LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
		WHERE  
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
			AND eh.vsl_id IS NOT NULL 
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') 
			AND vv.vsl_id = 'HUSUM' AND vv.IN_VOY_NBR = '152W' AND vv.out_voy_nbr = '152E'
		GROUP BY 
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.atd
			, eh.CRANE_no		
	)
SELECT
	gbcfm.name
	, gbcfm.vsl_id
	, gbcfm.in_voy_nbr
	, gbcfm.out_voy_nbr
	, gbcfm.atd
	, gbcfm.crane_no
	, gbcfm.moves
	, vsd.GKEY 
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
FROM group_by_crane_for_moves gbcfm
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON vsd.VSL_ID = gbcfm.VSL_ID AND vsd.VOY_IN_NBR = gbcfm.IN_VOY_NBR AND vsd.voy_out_nbr = gbcfm.OUT_VOY_NBR 
LEFT JOIN vessel_summary_delays	vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = gbcfm.crane_no
LEFT JOIN delay_reasons dr ON vsy.DELAY_CODE = dr.CODE 
GROUP BY 
	gbcfm.name
	, gbcfm.vsl_id
	, gbcfm.in_voy_nbr
	, gbcfm.out_voy_nbr
	, gbcfm.atd
	, gbcfm.crane_no
	, gbcfm.moves
	, vsd.GKEY 
;

--Now let's implement the triple grouping in the full query
--This query has the problem with grouping by crane fixed.
WITH 
	vsc_time_moves AS (
		SELECT 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
			, sum(vsc.completed - vsc.commenced) * 24 AS crane_work_time
			, sum(vsc.total_moves) AS total_moves
			, CASE 
				WHEN sum(vsc.completed - vsc.commenced) * 24 = 0 THEN NULL 
				ELSE sum(vsc.total_moves) / sum(vsc.completed - vsc.commenced) / 24
			  END AS raw_productivity
		FROM vessel_summary_cranes vsc
		GROUP BY 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
	), eh_time_moves AS (
		SELECT
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, vv.ATA 
			, vv.atd
			, eh.crane_no
			, count(*) AS eh_moves
			, (max(eh.posted) - min(eh.posted)) * 24 AS eh_crane_work_time
			, CASE 
				WHEN (max(eh.posted) - min(eh.posted)) * 24 = 0 THEN NULL 
				ELSE count(*) / (max(eh.posted) - min(eh.posted)) / 24
			  END AS eh_raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
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
		ORDER BY 
			vv.atd, eh.crane_no
	), delays AS (
		SELECT 
			vsy.vsd_gkey
			, vsy.crane_id
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
		FROM VESSEL_SUMMARY_DELAYS vsy 
		JOIN delay_reasons dr ON dr.code = vsy.delay_code
		GROUP BY vsy.VSD_GKEY, vsy.CRANE_ID 
	)
SELECT
	etm.name 
	, etm.VSL_ID  
	, etm.in_VOY_NBR 
	, etm.OUT_VOY_NBR  
	, etm.ATA 
	, etm.atd
	, etm.crane_no
	, etm.eh_moves
	, etm.eh_crane_work_time
	, etm.eh_raw_productivity
	, vsd.gkey
	, vsd.FIRST_MOVE 
	, vsd.LAST_MOVE 
	, vtm.CRANE_ID 
	, vtm.TOTAL_MOVES AS vsc_moves
	, vtm.crane_work_time AS vsc_crane_work_time
	, vtm.raw_productivity AS vtm_raw_productivity
	, del.shipping_delays
	, CASE 
		WHEN (vtm.crane_work_time - del.shipping_delays) = 0 THEN NULL
		ELSE 
			vtm.total_moves / (vtm.crane_work_time - del.shipping_delays)
	  END AS vsd_gross_productivity
	, CASE 
		WHEN (etm.eh_crane_work_time - del.shipping_delays) = 0 THEN NULL
		ELSE 
			etm.eh_moves / (etm.eh_crane_work_time - del.shipping_delays)
	  END AS eh_gross_productivity
	, del.terminal_delays
	, CASE 
		WHEN (vtm.crane_work_time - del.shipping_delays - del.terminal_delays) = 0 THEN NULL 
		ELSE vtm.total_moves / (vtm.crane_work_time - del.shipping_delays - del.terminal_delays)
	  END AS vsd_net_productivity
	, CASE 
		WHEN (etm.eh_crane_work_time - del.shipping_delays - del.terminal_delays) = 0 THEN NULL 
		ELSE etm.eh_moves / (etm.eh_crane_work_time - del.shipping_delays - del.terminal_delays)
	  END AS eh_net_productivity
FROM eh_time_moves etm  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON 
	vsd.VSL_ID = etm.VSL_ID AND 
	vsd.VOY_IN_NBR = etm.IN_VOY_NBR AND 
	vsd.voy_out_nbr = etm.OUT_VOY_NBR 
LEFT JOIN vsc_time_moves vtm ON vtm.VSD_GKEY = vsd.GKEY AND etm.crane_no = vtm.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = etm.crane_no
LEFT JOIN delays del ON del.VSD_GKEY = vsd.GKEY AND del.crane_id = etm.crane_no
ORDER BY etm.atd, etm.CRANE_NO 
;

--Now let's update how the etm.eh_crane_work_time is computed to give priority to ata and atd when present.
WITH 
	vsc_time_moves AS (
		SELECT 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
			, sum(vsc.completed - vsc.commenced) * 24 AS crane_work_time
			, sum(vsc.total_moves) AS total_moves
			, CASE 
				WHEN sum(vsc.completed - vsc.commenced) * 24 = 0 THEN NULL 
				ELSE sum(vsc.total_moves) / sum(vsc.completed - vsc.commenced) / 24
			  END AS raw_productivity
		FROM vessel_summary_cranes vsc
		GROUP BY 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
	), eh_time_moves AS (
		SELECT
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, vv.ATA 
			, vv.atd
			, eh.crane_no
			, min(eh.posted) AS eh_first_move
			, max(eh.posted) AS eh_last_move
			, count(*) AS eh_moves
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 < 0
					THEN 0
					ELSE (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24
			  END AS eh_crane_work_time
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 <= 0
					THEN NULL 
					ELSE  count(*) / (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) / 24
			  END AS eh_raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
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
		ORDER BY 
			vv.atd, eh.crane_no
	), delays AS (
		SELECT 
			vsy.vsd_gkey
			, vsy.crane_id
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
		FROM VESSEL_SUMMARY_DELAYS vsy 
		JOIN delay_reasons dr ON dr.code = vsy.delay_code
		GROUP BY vsy.VSD_GKEY, vsy.CRANE_ID 
	)
SELECT
	etm.name 
	, etm.VSL_ID  
	, etm.in_VOY_NBR 
	, etm.OUT_VOY_NBR  
	, etm.ATA 
	, etm.atd
	, etm.crane_no
	, etm.eh_first_move
	, etm.eh_last_move
	, etm.eh_moves
	, etm.eh_crane_work_time
	, etm.eh_raw_productivity
	, vsd.gkey
	, vsd.FIRST_MOVE 
	, vsd.LAST_MOVE 
	, vtm.CRANE_ID 
	, vtm.TOTAL_MOVES AS vsc_moves
	, vtm.crane_work_time AS vsc_crane_work_time
	, vtm.raw_productivity AS vtm_raw_productivity
	, del.shipping_delays
	, CASE 
		WHEN (vtm.crane_work_time - del.shipping_delays) = 0 THEN NULL
		ELSE 
			vtm.total_moves / (vtm.crane_work_time - del.shipping_delays)
	  END AS vsd_gross_productivity
	, CASE 
		WHEN (etm.eh_crane_work_time - del.shipping_delays) = 0 THEN NULL
		ELSE 
			etm.eh_moves / (etm.eh_crane_work_time - del.shipping_delays)
	  END AS eh_gross_productivity
	, del.terminal_delays
	, CASE 
		WHEN (vtm.crane_work_time - del.shipping_delays - del.terminal_delays) = 0 THEN NULL 
		ELSE vtm.total_moves / (vtm.crane_work_time - del.shipping_delays - del.terminal_delays)
	  END AS vsd_net_productivity
	, CASE 
		WHEN (etm.eh_crane_work_time - del.shipping_delays - del.terminal_delays) = 0 THEN NULL 
		ELSE etm.eh_moves / (etm.eh_crane_work_time - del.shipping_delays - del.terminal_delays)
	  END AS eh_net_productivity
FROM eh_time_moves etm  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON 
	vsd.VSL_ID = etm.VSL_ID AND 
	vsd.VOY_IN_NBR = etm.IN_VOY_NBR AND 
	vsd.voy_out_nbr = etm.OUT_VOY_NBR 
LEFT JOIN vsc_time_moves vtm ON vtm.VSD_GKEY = vsd.GKEY AND etm.crane_no = vtm.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = etm.crane_no
LEFT JOIN delays del ON del.VSD_GKEY = vsd.GKEY AND del.crane_id = etm.crane_no
WHERE trunc(etm.atd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
ORDER BY etm.atd, etm.CRANE_NO 
;

--Need to study to see if giving ata and atd priority made agreement with vsd worse or better.
--Just using eh.posted here
--The error over the entire time period doubles when using only eh.posted. It's much better to prioritize ata and atd.
--That is, assuming that the vessel summary approach is authoritative, which I think it probably is.
--I'll learn more tomorrow after meeting with Emir.
WITH 
	vsc_time_moves AS (
		SELECT 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
			, sum(vsc.completed - vsc.commenced) * 24 AS crane_work_time
			, sum(vsc.total_moves) AS total_moves
			, CASE 
				WHEN sum(vsc.completed - vsc.commenced) * 24 = 0 THEN NULL 
				ELSE sum(vsc.total_moves) / sum(vsc.completed - vsc.commenced) / 24
			  END AS raw_productivity
		FROM vessel_summary_cranes vsc
		GROUP BY 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
	), eh_time_moves AS (
		SELECT
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, vv.ATA 
			, vv.atd
			, eh.crane_no
			, min(eh.posted) AS eh_first_move
			, max(eh.posted) AS eh_last_move
			, count(*) AS eh_moves
			, (max(eh.posted) - min(eh.posted)) * 24 AS eh_crane_work_time
			, CASE 
				WHEN (max(eh.posted) - min(eh.posted)) = 0 THEN NULL 
				ELSE  count(*) / (max(eh.posted) - min(eh.posted)) / 24
			  END AS eh_raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
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
		ORDER BY 
			vv.atd, eh.crane_no
	), delays AS (
		SELECT 
			vsy.vsd_gkey
			, vsy.crane_id
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
		FROM VESSEL_SUMMARY_DELAYS vsy 
		JOIN delay_reasons dr ON dr.code = vsy.delay_code
		GROUP BY vsy.VSD_GKEY, vsy.CRANE_ID 
	)
SELECT
	etm.name 
	, etm.VSL_ID  
	, etm.in_VOY_NBR 
	, etm.OUT_VOY_NBR  
	, etm.ATA 
	, etm.atd
	, etm.crane_no
	, etm.eh_first_move
	, etm.eh_last_move
	, etm.eh_moves
	, etm.eh_crane_work_time
	, etm.eh_raw_productivity
	, vsd.gkey
	, vsd.FIRST_MOVE 
	, vsd.LAST_MOVE 
	, vtm.CRANE_ID 
	, vtm.TOTAL_MOVES AS vsc_moves
	, vtm.crane_work_time AS vsc_crane_work_time
	, vtm.raw_productivity AS vtm_raw_productivity
	, del.shipping_delays
	, CASE 
		WHEN (vtm.crane_work_time - del.shipping_delays) = 0 THEN NULL
		ELSE 
			vtm.total_moves / (vtm.crane_work_time - del.shipping_delays)
	  END AS vsd_gross_productivity
	, CASE 
		WHEN (etm.eh_crane_work_time - del.shipping_delays) = 0 THEN NULL
		ELSE 
			etm.eh_moves / (etm.eh_crane_work_time - del.shipping_delays)
	  END AS eh_gross_productivity
	, del.terminal_delays
	, CASE 
		WHEN (vtm.crane_work_time - del.shipping_delays - del.terminal_delays) = 0 THEN NULL 
		ELSE vtm.total_moves / (vtm.crane_work_time - del.shipping_delays - del.terminal_delays)
	  END AS vsd_net_productivity
	, CASE 
		WHEN (etm.eh_crane_work_time - del.shipping_delays - del.terminal_delays) = 0 THEN NULL 
		ELSE etm.eh_moves / (etm.eh_crane_work_time - del.shipping_delays - del.terminal_delays)
	  END AS eh_net_productivity
FROM eh_time_moves etm  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON 
	vsd.VSL_ID = etm.VSL_ID AND 
	vsd.VOY_IN_NBR = etm.IN_VOY_NBR AND 
	vsd.voy_out_nbr = etm.OUT_VOY_NBR 
LEFT JOIN vsc_time_moves vtm ON vtm.VSD_GKEY = vsd.GKEY AND etm.crane_no = vtm.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = etm.crane_no
LEFT JOIN delays del ON del.VSD_GKEY = vsd.GKEY AND del.crane_id = etm.crane_no
WHERE trunc(etm.atd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
ORDER BY etm.atd, etm.CRANE_NO 
;

--So this is the query to run on ZLO UAT 2. It takes 27 seconds to run on MIT UAT.
--ZLO UAT 2 did not return after 30 minutes.
WITH 
	vsc_time_moves AS (
		SELECT 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
			, sum(vsc.completed - vsc.commenced) * 24 AS crane_work_time
			, sum(vsc.total_moves) AS total_moves
			, CASE 
				WHEN sum(vsc.completed - vsc.commenced) * 24 = 0 THEN NULL 
				ELSE sum(vsc.total_moves) / sum(vsc.completed - vsc.commenced) / 24
			  END AS raw_productivity
		FROM vessel_summary_cranes vsc
		GROUP BY 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
	), eh_time_moves AS (
		SELECT
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, vv.ATA 
			, vv.atd
			, eh.crane_no
			, min(eh.posted) AS eh_first_move
			, max(eh.posted) AS eh_last_move
			, count(*) AS eh_moves
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 < 0
					THEN 0
					ELSE (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24
			  END AS eh_crane_work_time
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 <= 0
					THEN NULL 
					ELSE  count(*) / (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) / 24
			  END AS eh_raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
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
		ORDER BY 
			vv.atd, eh.crane_no
	), delays AS (
		SELECT 
			vsy.vsd_gkey
			, vsy.crane_id
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
		FROM VESSEL_SUMMARY_DELAYS vsy 
		JOIN delay_reasons dr ON dr.code = vsy.delay_code
		GROUP BY vsy.VSD_GKEY, vsy.CRANE_ID 
	)
SELECT
	etm.name 
	, etm.VSL_ID  
	, etm.in_VOY_NBR 
	, etm.OUT_VOY_NBR  
	, etm.ATA 
	, etm.atd
	, etm.crane_no
	, etm.eh_first_move
	, etm.eh_last_move
	, etm.eh_moves
	, etm.eh_crane_work_time
	, etm.eh_raw_productivity
	, vsd.gkey
	, vsd.FIRST_MOVE 
	, vsd.LAST_MOVE 
	, vtm.CRANE_ID 
	, vtm.TOTAL_MOVES AS vsc_moves
	, vtm.crane_work_time AS vsc_crane_work_time
	, vtm.raw_productivity AS vtm_raw_productivity
	, del.shipping_delays
	, CASE 
		WHEN (vtm.crane_work_time - del.shipping_delays) = 0 THEN NULL
		ELSE 
			vtm.total_moves / (vtm.crane_work_time - del.shipping_delays)
	  END AS vsd_gross_productivity
	, CASE 
		WHEN (etm.eh_crane_work_time - del.shipping_delays) = 0 THEN NULL
		ELSE 
			etm.eh_moves / (etm.eh_crane_work_time - del.shipping_delays)
	  END AS eh_gross_productivity
	, del.terminal_delays
	, CASE 
		WHEN (vtm.crane_work_time - del.shipping_delays - del.terminal_delays) = 0 THEN NULL 
		ELSE vtm.total_moves / (vtm.crane_work_time - del.shipping_delays - del.terminal_delays)
	  END AS vsd_net_productivity
	, CASE 
		WHEN (etm.eh_crane_work_time - del.shipping_delays - del.terminal_delays) = 0 THEN NULL 
		ELSE etm.eh_moves / (etm.eh_crane_work_time - del.shipping_delays - del.terminal_delays)
	  END AS eh_net_productivity
FROM eh_time_moves etm  
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON 
	vsd.VSL_ID = etm.VSL_ID AND 
	vsd.VOY_IN_NBR = etm.IN_VOY_NBR AND 
	vsd.voy_out_nbr = etm.OUT_VOY_NBR 
LEFT JOIN vsc_time_moves vtm ON vtm.VSD_GKEY = vsd.GKEY AND etm.crane_no = vtm.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = etm.crane_no
LEFT JOIN delays del ON del.VSD_GKEY = vsd.GKEY AND del.crane_id = etm.crane_no
WHERE trunc(etm.atd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD') 
ORDER BY etm.atd, etm.CRANE_NO 
;

--Let's skip the by crane statistics and move to by month
--I don't know why this isn't producing entries for every month.
WITH 
	vsc_time_moves AS (
		SELECT 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
			, sum(vsc.completed - vsc.commenced) * 24 AS crane_work_time
			, sum(vsc.total_moves) AS total_moves
			, CASE 
				WHEN sum(vsc.completed - vsc.commenced) * 24 = 0 THEN NULL 
				ELSE sum(vsc.total_moves) / sum(vsc.completed - vsc.commenced) / 24
			  END AS raw_productivity
		FROM vessel_summary_cranes vsc
		GROUP BY 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
	), eh_time_moves AS (
		SELECT
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, vv.ATA 
			, vv.atd
			, eh.crane_no
			, min(eh.posted) AS eh_first_move
			, max(eh.posted) AS eh_last_move
			, count(*) AS eh_moves
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 < 0
					THEN 0
					ELSE (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24
			  END AS eh_crane_work_time
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 <= 0
					THEN NULL 
					ELSE  count(*) / (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) / 24
			  END AS eh_raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
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
		ORDER BY 
			vv.atd, eh.crane_no
	), delays AS (
		SELECT 
			vsy.vsd_gkey
			, vsy.crane_id
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
		FROM VESSEL_SUMMARY_DELAYS vsy 
		JOIN delay_reasons dr ON dr.code = vsy.delay_code
		GROUP BY vsy.VSD_GKEY, vsy.CRANE_ID 
	), date_series AS (
		  SELECT
		    TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	), calendar AS (
		SELECT 
			EXTRACT (YEAR FROM DATE_in_series) AS year
			, EXTRACT (MONTH FROM date_in_series) AS month
		FROM date_series
		GROUP BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
		ORDER BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
	)
SELECT
	cal.YEAR AS YEAR
	, cal.MONTH AS month
	, sum(etm.eh_moves) AS eh_moves
	, sum(etm.eh_crane_work_time) AS eh_crane_work_time
	, sum(etm.eh_moves) / sum(etm.eh_crane_work_time) AS eh_raw_productivity
	, sum(vtm.TOTAL_MOVES) AS vsc_moves
	, sum(vtm.crane_work_time) AS vsc_crane_work_time
	, sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time) AS vtm_raw_productivity
	, sum(del.shipping_delays) AS shipping_delays
	, sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays)) AS vsd_gross_productivity
	, sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.shipping_delays)) AS eh_gross_productivity
	, sum(del.terminal_delays) AS terminal_delays
	, sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays)) AS vsd_net_productivity
	, sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays)) AS eh_net_productivity
FROM calendar cal
LEFT JOIN eh_time_moves etm 
	ON EXTRACT (YEAR FROM etm.atd) = cal.YEAR 
	AND EXTRACT (MONTH FROM etm.atd) = cal.MONTH
	AND trunc(etm.atd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON 
	vsd.VSL_ID = etm.VSL_ID AND 
	vsd.VOY_IN_NBR = etm.IN_VOY_NBR AND 
	vsd.voy_out_nbr = etm.OUT_VOY_NBR 
LEFT JOIN vsc_time_moves vtm ON vtm.VSD_GKEY = vsd.GKEY AND etm.crane_no = vtm.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = etm.crane_no
LEFT JOIN delays del ON del.VSD_GKEY = vsd.GKEY AND del.crane_id = etm.crane_no
GROUP BY cal.YEAR, cal.MONTH 
ORDER BY cal.YEAR, cal.MONTH
;

--This query is working well for monthly summaries at MIT, but does not work for ZLO.
--ZLO uses the completed and commenced columns from the vessel_summary_crane_prod table whereas
--MIT uses the completed and commenced columns from the vessel_summary_crane table.
WITH 
	vsc_time_moves AS (
		SELECT 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
			, sum(vsc.completed - vsc.commenced) * 24 AS crane_work_time
			, sum(vsc.total_moves) AS total_moves
			, CASE 
				WHEN sum(vsc.completed - vsc.commenced) * 24 = 0 THEN NULL 
				ELSE sum(vsc.total_moves) / sum(vsc.completed - vsc.commenced) / 24
			  END AS raw_productivity
		FROM vessel_summary_cranes vsc
		--JOIN vessel_summary_crane_prod vscp ON vsc.vsd_gkey = vscp.vsd_gkey
		GROUP BY 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
	), eh_time_moves AS (
		SELECT
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, vv.ATA 
			, vv.atd
			, eh.crane_no
			, min(eh.posted) AS eh_first_move
			, max(eh.posted) AS eh_last_move
			, count(*) AS eh_moves
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 < 0
					THEN 0
					ELSE (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24
			  END AS eh_crane_work_time
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 <= 0
					THEN NULL 
					ELSE  count(*) / (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) / 24
			  END AS eh_raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
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
		ORDER BY 
			vv.atd, eh.crane_no
	), delays AS (
		SELECT 
			vsy.vsd_gkey
			, vsy.crane_id
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
		FROM VESSEL_SUMMARY_DELAYS vsy 
		JOIN delay_reasons dr ON dr.code = vsy.delay_code
		GROUP BY vsy.VSD_GKEY, vsy.CRANE_ID 
	), date_series AS (
		  SELECT
		    TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	), calendar AS (
		SELECT 
			EXTRACT (YEAR FROM DATE_in_series) AS year
			, EXTRACT (MONTH FROM date_in_series) AS month
		FROM date_series
		GROUP BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
		ORDER BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
	)
SELECT
	cal.YEAR AS YEAR
	, cal.MONTH AS month
	, nvl(sum(etm.eh_moves),0) AS eh_moves
	, nvl(sum(etm.eh_crane_work_time),0) AS eh_crane_work_time
	, CASE 
		WHEN sum(etm.eh_moves) IS NULL THEN 0
		WHEN sum(etm.eh_crane_work_time) IS NULL OR sum(etm.eh_crane_work_time) <= 0 THEN NULL
		ELSE sum(etm.eh_moves) / sum(etm.eh_crane_work_time) 
	  END AS eh_raw_productivity
	, nvl(sum(vtm.TOTAL_MOVES),0) AS vsc_moves
	, nvl(sum(vtm.crane_work_time),0) AS vsc_crane_work_time
	, CASE 
		WHEN sum(vtm.TOTAL_MOVES) IS NULL THEN 0
		WHEN sum(vtm.crane_work_time) IS NULL OR sum(vtm.crane_work_time) <= 0 THEN NULL 
		ELSE sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time)
	  END AS vtm_raw_productivity
	, nvl(sum(del.shipping_delays),0) AS shipping_delays
	, CASE 
		WHEN sum(etm.eh_moves) IS NULL THEN 0
		WHEN sum(etm.eh_crane_work_time) IS NULL OR sum(etm.eh_crane_work_time) <= 0 THEN NULL
		WHEN sum(del.shipping_delays) IS NULL THEN sum(etm.eh_moves) / sum(etm.eh_crane_work_time)
		WHEN (sum(etm.eh_crane_work_time) - sum(del.shipping_delays)) <= 0 THEN NULL
		ELSE sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.shipping_delays))
	  END AS eh_gross_productivity
	, CASE 
		WHEN sum(vtm.TOTAL_MOVES) IS NULL THEN 0
		WHEN sum(vtm.crane_work_time) IS NULL OR sum(vtm.crane_work_time) <= 0 THEN NULL
		WHEN sum(del.shipping_delays) IS NULL THEN sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time)
		WHEN (sum(vtm.crane_work_time) - sum(del.shipping_delays)) <= 0 THEN NULL
		ELSE sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays))
	  END AS vsd_gross_productivity
	, nvl(sum(del.terminal_delays),0) AS terminal_delays
	, CASE 
		WHEN sum(etm.eh_moves) IS NULL THEN 0
		WHEN sum(etm.eh_crane_work_time) IS NULL OR sum(etm.eh_crane_work_time) <= 0 THEN NULL
		WHEN
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NULL
			THEN sum(etm.eh_moves) / sum(etm.eh_crane_work_time)
		WHEN 
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NOT NULL AND 
			(sum(etm.eh_crane_work_time) - sum(del.terminal_delays)) >= 0
			THEN sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.terminal_delays))
		WHEN 
			sum(del.terminal_delays) IS NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND 
			(sum(etm.eh_crane_work_time) - sum(del.shipping_delays)) >= 0
			THEN sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.shipping_delays))
		WHEN 
			sum(del.terminal_delays) IS NOT NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND
			(sum(etm.eh_crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays)) >= 0
			THEN sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays))
	  END AS eh_net_productivity
	, CASE 
		WHEN sum(vtm.TOTAL_MOVES) IS NULL THEN 0
		WHEN sum(vtm.crane_work_time) IS NULL OR sum(vtm.crane_work_time) <= 0 THEN NULL
		WHEN
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NULL
			THEN sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time)
		WHEN 
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NOT NULL AND 
			(sum(vtm.crane_work_time) - sum(del.terminal_delays)) >= 0
			THEN sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.terminal_delays))
		WHEN 
			sum(del.terminal_delays) IS NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND 
			(sum(vtm.crane_work_time) - sum(del.shipping_delays)) >= 0
			THEN sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays))
		WHEN 
			sum(del.terminal_delays) IS NOT NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND
			(sum(vtm.crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays)) >= 0
			THEN sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays))
	  END AS vsd_net_productivity
FROM calendar cal
LEFT JOIN eh_time_moves etm 
	ON EXTRACT (YEAR FROM etm.atd) = cal.YEAR 
	AND EXTRACT (MONTH FROM etm.atd) = cal.MONTH
	AND trunc(etm.atd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON 
	vsd.VSL_ID = etm.VSL_ID AND 
	vsd.VOY_IN_NBR = etm.IN_VOY_NBR AND 
	vsd.voy_out_nbr = etm.OUT_VOY_NBR 
LEFT JOIN vsc_time_moves vtm ON vtm.VSD_GKEY = vsd.GKEY AND etm.crane_no = vtm.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = etm.crane_no
LEFT JOIN delays del ON del.VSD_GKEY = vsd.GKEY AND del.crane_id = etm.crane_no
GROUP BY cal.YEAR, cal.MONTH 
ORDER BY cal.YEAR, cal.MONTH
;

--This query is working well for monthly summaries at ZLO, but does not work for MIT.
--ZLO uses the completed and commenced columns from the vessel_summary_crane_prod table whereas
--MIT uses the completed and commenced columns from the vessel_summary_crane table.
--This query does not produce the same results as the initial VS approach for ZLO (which is copied below).
WITH 
	vsc_time_moves AS (
		SELECT 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
			, sum(vscp.completed - vscp.commenced) * 24 AS crane_work_time
			, sum(vsc.total_moves) AS total_moves
			, CASE 
				WHEN sum(vsc.completed - vsc.commenced) * 24 = 0 THEN NULL 
				ELSE sum(vsc.total_moves) / sum(vsc.completed - vsc.commenced) / 24
			  END AS raw_productivity
		FROM vessel_summary_cranes vsc
		JOIN vessel_summary_crane_prod vscp ON vsc.vsd_gkey = vscp.vsd_gkey
		GROUP BY 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
	), eh_time_moves AS (
		SELECT
			v.name 
			, vv.VSL_ID  
			, vv.in_VOY_NBR 
			, vv.OUT_VOY_NBR  
			, vv.ATA 
			, vv.atd
			, eh.crane_no
			, min(eh.posted) AS eh_first_move
			, max(eh.posted) AS eh_last_move
			, count(*) AS eh_moves
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 < 0
					THEN 0
					ELSE (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24
			  END AS eh_crane_work_time
			, CASE 
				WHEN (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
						- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) * 24 <= 0
					THEN NULL 
					ELSE  count(*) / (least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))) 
							- greatest(min(eh.posted),COALESCE(vv.ata,min(eh.posted)))) / 24
			  END AS eh_raw_productivity
		FROM EQUIPMENT_HISTORY eh  
		LEFT JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR) 
		LEFT JOIN VESSELS v ON vv.VSL_ID = v.ID  
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
		ORDER BY 
			vv.atd, eh.crane_no
	), delays AS (
		SELECT 
			vsy.vsd_gkey
			, vsy.crane_id
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
		FROM VESSEL_SUMMARY_DELAYS vsy 
		JOIN delay_reasons dr ON dr.code = vsy.delay_code
		GROUP BY vsy.VSD_GKEY, vsy.CRANE_ID 
	), date_series AS (
		  SELECT
		    TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	), calendar AS (
		SELECT 
			EXTRACT (YEAR FROM DATE_in_series) AS year
			, EXTRACT (MONTH FROM date_in_series) AS month
		FROM date_series
		GROUP BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
		ORDER BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
	)
SELECT
	cal.YEAR AS YEAR
	, cal.MONTH AS month
	, nvl(sum(etm.eh_moves),0) AS eh_moves
	, nvl(sum(etm.eh_crane_work_time),0) AS eh_crane_work_time
	, CASE 
		WHEN sum(etm.eh_moves) IS NULL THEN 0
		WHEN sum(etm.eh_crane_work_time) IS NULL OR sum(etm.eh_crane_work_time) <= 0 THEN NULL
		ELSE sum(etm.eh_moves) / sum(etm.eh_crane_work_time) 
	  END AS eh_raw_productivity
	, nvl(sum(vtm.TOTAL_MOVES),0) AS vsc_moves
	, nvl(sum(vtm.crane_work_time),0) AS vsc_crane_work_time
	, CASE 
		WHEN sum(vtm.TOTAL_MOVES) IS NULL THEN 0
		WHEN sum(vtm.crane_work_time) IS NULL OR sum(vtm.crane_work_time) <= 0 THEN NULL 
		ELSE sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time)
	  END AS vtm_raw_productivity
	, nvl(sum(del.shipping_delays),0) AS shipping_delays
	, CASE 
		WHEN sum(etm.eh_moves) IS NULL THEN 0
		WHEN sum(etm.eh_crane_work_time) IS NULL OR sum(etm.eh_crane_work_time) <= 0 THEN NULL
		WHEN sum(del.shipping_delays) IS NULL THEN sum(etm.eh_moves) / sum(etm.eh_crane_work_time)
		WHEN (sum(etm.eh_crane_work_time) - sum(del.shipping_delays)) <= 0 THEN NULL
		ELSE sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.shipping_delays))
	  END AS eh_gross_productivity
	, CASE 
		WHEN sum(vtm.TOTAL_MOVES) IS NULL THEN 0
		WHEN sum(vtm.crane_work_time) IS NULL OR sum(vtm.crane_work_time) <= 0 THEN NULL
		WHEN sum(del.shipping_delays) IS NULL THEN sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time)
		WHEN (sum(vtm.crane_work_time) - sum(del.shipping_delays)) <= 0 THEN NULL
		ELSE sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays))
	  END AS vsd_gross_productivity
	, nvl(sum(del.terminal_delays),0) AS terminal_delays
	, CASE 
		WHEN sum(etm.eh_moves) IS NULL THEN 0
		WHEN sum(etm.eh_crane_work_time) IS NULL OR sum(etm.eh_crane_work_time) <= 0 THEN NULL
		WHEN
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NULL
			THEN sum(etm.eh_moves) / sum(etm.eh_crane_work_time)
		WHEN 
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NOT NULL AND 
			(sum(etm.eh_crane_work_time) - sum(del.terminal_delays)) >= 0
			THEN sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.terminal_delays))
		WHEN 
			sum(del.terminal_delays) IS NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND 
			(sum(etm.eh_crane_work_time) - sum(del.shipping_delays)) >= 0
			THEN sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.shipping_delays))
		WHEN 
			sum(del.terminal_delays) IS NOT NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND
			(sum(etm.eh_crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays)) >= 0
			THEN sum(etm.eh_moves) / (sum(etm.eh_crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays))
	  END AS eh_net_productivity
	, CASE 
		WHEN sum(vtm.TOTAL_MOVES) IS NULL THEN 0
		WHEN sum(vtm.crane_work_time) IS NULL OR sum(vtm.crane_work_time) <= 0 THEN NULL
		WHEN
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NULL
			THEN sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time)
		WHEN 
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NOT NULL AND 
			(sum(vtm.crane_work_time) - sum(del.terminal_delays)) >= 0
			THEN sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.terminal_delays))
		WHEN 
			sum(del.terminal_delays) IS NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND 
			(sum(vtm.crane_work_time) - sum(del.shipping_delays)) >= 0
			THEN sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays))
		WHEN 
			sum(del.terminal_delays) IS NOT NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND
			(sum(vtm.crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays)) >= 0
			THEN sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays))
	  END AS vsd_net_productivity
FROM calendar cal
LEFT JOIN eh_time_moves etm 
	ON EXTRACT (YEAR FROM etm.atd) = cal.YEAR 
	AND EXTRACT (MONTH FROM etm.atd) = cal.MONTH
	AND trunc(etm.atd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON 
	vsd.VSL_ID = etm.VSL_ID AND 
	vsd.VOY_IN_NBR = etm.IN_VOY_NBR AND 
	vsd.voy_out_nbr = etm.OUT_VOY_NBR 
LEFT JOIN vsc_time_moves vtm ON vtm.VSD_GKEY = vsd.GKEY AND etm.crane_no = vtm.CRANE_ID 
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = etm.crane_no
LEFT JOIN delays del ON del.VSD_GKEY = vsd.GKEY AND del.crane_id = etm.crane_no
GROUP BY cal.YEAR, cal.MONTH 
ORDER BY cal.YEAR, cal.MONTH
;

--Debugging above query
WITH 
	vsc_time_moves AS (
		SELECT 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
			, sum(vscp.completed - vscp.commenced) * 24 AS crane_work_time
			, sum(vsc.total_moves) AS total_moves
			, CASE 
				WHEN sum(vsc.completed - vsc.commenced) * 24 = 0 THEN NULL 
				ELSE sum(vsc.total_moves) / sum(vsc.completed - vsc.commenced) / 24
			  END AS raw_productivity
		FROM vessel_summary_cranes vsc
		JOIN vessel_summary_crane_prod vscp ON vsc.vsd_gkey = vscp.vsd_gkey
		GROUP BY 
			vsc.VSD_GKEY 
			, vsc.CRANE_ID 
	), delays AS (
		SELECT 
			vsy.vsd_gkey
			, vsy.crane_id
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
		FROM VESSEL_SUMMARY_DELAYS vsy 
		JOIN delay_reasons dr ON dr.code = vsy.delay_code
		GROUP BY vsy.VSD_GKEY, vsy.CRANE_ID 
	), date_series AS (
		  SELECT
		    TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	), calendar AS (
		SELECT 
			EXTRACT (YEAR FROM DATE_in_series) AS year
			, EXTRACT (MONTH FROM date_in_series) AS month
		FROM date_series
		GROUP BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
		ORDER BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
	)
SELECT
	cal.YEAR AS YEAR
	, cal.MONTH AS month
	, nvl(sum(vtm.TOTAL_MOVES),0) AS vsc_moves
	, nvl(sum(vtm.crane_work_time),0) AS vsc_crane_work_time
	, CASE 
		WHEN sum(vtm.TOTAL_MOVES) IS NULL THEN 0
		WHEN sum(vtm.crane_work_time) IS NULL OR sum(vtm.crane_work_time) <= 0 THEN NULL 
		ELSE sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time)
	  END AS vtm_raw_productivity
	, nvl(sum(del.shipping_delays),0) AS shipping_delays
	, CASE 
		WHEN sum(vtm.TOTAL_MOVES) IS NULL THEN 0
		WHEN sum(vtm.crane_work_time) IS NULL OR sum(vtm.crane_work_time) <= 0 THEN NULL
		WHEN sum(del.shipping_delays) IS NULL THEN sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time)
		WHEN (sum(vtm.crane_work_time) - sum(del.shipping_delays)) <= 0 THEN NULL
		ELSE sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays))
	  END AS vsd_gross_productivity
	, nvl(sum(del.terminal_delays),0) AS terminal_delays
	, CASE 
		WHEN sum(vtm.TOTAL_MOVES) IS NULL THEN 0
		WHEN sum(vtm.crane_work_time) IS NULL OR sum(vtm.crane_work_time) <= 0 THEN NULL
		WHEN
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NULL
			THEN sum(vtm.TOTAL_MOVES) / sum(vtm.crane_work_time)
		WHEN 
			sum(del.shipping_delays) IS NULL AND 
			sum(del.terminal_delays) IS NOT NULL AND 
			(sum(vtm.crane_work_time) - sum(del.terminal_delays)) >= 0
			THEN sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.terminal_delays))
		WHEN 
			sum(del.terminal_delays) IS NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND 
			(sum(vtm.crane_work_time) - sum(del.shipping_delays)) >= 0
			THEN sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays))
		WHEN 
			sum(del.terminal_delays) IS NOT NULL AND 
			sum(del.shipping_delays) IS NOT NULL AND
			(sum(vtm.crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays)) >= 0
			THEN sum(vtm.TOTAL_MOVES) / (sum(vtm.crane_work_time) - sum(del.shipping_delays) - sum(del.terminal_delays))
	  END AS vsd_net_productivity
FROM calendar cal
LEFT JOIN VESSEL_SUMMARY_DETAIL vsd ON trunc(vsd.last_move) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
LEFT JOIN vsc_time_moves vtm ON vtm.VSD_GKEY = vsd.GKEY
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vscp.VSD_GKEY = vsd.GKEY AND vscp.CRANE_ID = vtm.crane_id
LEFT JOIN delays del ON del.VSD_GKEY = vsd.GKEY AND del.crane_id = vtm.crane_id
GROUP BY cal.YEAR, cal.MONTH 
ORDER BY cal.YEAR, cal.MONTH
;


--Now let's get monthly averages. This seems to work.
--Original ZLO VS approach, but it produces a total moves of around 11M moves per year. Way too high.
--I'm rewriting the original ZLO VS approach so that the total moves agrees with the query by vessel and crane.
--The query below reproduces the original by_vessel move counts and eliminates the group by error.
--ZLO reports gross productivities so this by vessel and crane query when aggregated by month agrees pretty well with their reports
WITH 
	moves_by_vessel_and_crane AS (
		SELECT 
			vsd.GKEY AS vsd_gkey
			, vsc.crane_id
			, vsc.total_moves
		FROM vessel_summary_detail vsd
		JOIN vessel_summary_cranes vsc ON vsc.vsd_gkey = vsd.GKEY
	), delays_by_vessel_and_crane AS (
		SELECT 
			vsd.gkey AS vsd_gkey
			, vsc.crane_id
			, sum (CASE WHEN dr.delay_level = 'S' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS shipping_delays
			, sum (CASE WHEN dr.delay_level = 'T' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS terminal_delays
			, sum (
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 ) AS total_delays
		FROM vessel_summary_detail vsd
		JOIN vessel_summary_cranes vsc ON vsc.VSD_GKEY = vsd.GKEY 
		JOIN vessel_summary_delays vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = vsc.crane_id
		JOIN delay_reasons dr ON vsy.delay_code = dr.CODE 
		GROUP BY vsd.gkey, vsc.crane_id
	)
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
	, vsy.shipping_delays AS shipping_delays
	, CASE 
		WHEN ((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays) = 0 THEN NULL
		ELSE 
			vsc.total_moves / ((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays)
	  END AS gross_productivity
	, vsy.terminal_delays AS terminal_delays
	, CASE 
		WHEN ((vscp.completed - vscp.commenced) * 24 - vsy.terminal_delays) = 0 THEN NULL 
		ELSE vsc.total_moves / ((vscp.completed - vscp.commenced) * 24 - vsy.terminal_delays)
	  END AS net_productivity
FROM vessel_summary_detail vsd
LEFT JOIN moves_by_vessel_and_crane vsc ON vsd.gkey = vsc.VSD_GKEY
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vsd.gkey = vscp.vsd_gkey AND vsc.crane_id = vscp.CRANE_ID 
LEFT JOIN delays_by_vessel_and_crane vsy ON vsd.gkey = vsy.VSD_GKEY AND vsc.CRANE_ID = vsy.CRANE_ID 
WHERE 
	vsd.status = 'Final'
	AND trunc(vsd.last_move) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
ORDER BY vsd.LAST_MOVE, vsc.CRANE_ID
;

--Now to aggregate the above by year and month
--Yay! The total moves agree between the by vessel query above and the by month query below.
--ZLO reports gross productivities. This query agrees pretty well with the reports.
--Next steps - verify that this query works for ZLO and MIT or needs adjustments and document adjustments.
--Validate total move counts for VS approach at MIT.
--Build EH approach at MIT.
--Bring EH approach back to ZLO.
--Take EH approach to USWC.
WITH 
	moves_by_vessel_and_crane AS (
		SELECT 
			vsd.GKEY AS vsd_gkey
			, vsc.crane_id
			, vsc.total_moves
		FROM vessel_summary_detail vsd
		JOIN vessel_summary_cranes vsc ON vsc.vsd_gkey = vsd.GKEY
	), delays_by_vessel_and_crane AS (
		SELECT 
			vsd.gkey AS vsd_gkey
			, vsc.crane_id
			, sum (CASE WHEN dr.delay_level = 'S' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS shipping_delays
			, sum (CASE WHEN dr.delay_level = 'T' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS terminal_delays
			, sum (
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 ) AS total_delays
		FROM vessel_summary_detail vsd
		LEFT JOIN vessel_summary_cranes vsc ON vsc.VSD_GKEY = vsd.GKEY 
		LEFT JOIN vessel_summary_delays vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = vsc.crane_id
		LEFT JOIN delay_reasons dr ON vsy.delay_code = dr.CODE 
		GROUP BY vsd.gkey, vsc.crane_id
	)
SELECT 
	EXTRACT (YEAR FROM vsd.last_move)
	, EXTRACT (MONTH FROM vsd.last_move)
	, sum(vsc.TOTAL_MOVES)
	, sum((vscp.completed - vscp.commenced)) * 24 AS crane_work_time
	, CASE 
		WHEN sum((vscp.completed - vscp.commenced)) = 0 THEN NULL 
		ELSE sum(vsc.total_moves) / sum((vscp.completed - vscp.commenced)) / 24
	  END AS raw_productivity
	, sum(vsy.shipping_delays) AS shipping_delays
	, CASE 
		WHEN sum(((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays)) = 0 THEN NULL
		ELSE 
			sum(vsc.total_moves) / sum(((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays))
	  END AS gross_productivity
	, sum(vsy.terminal_delays) AS terminal_delays
	, sum(vsy.total_delays) AS total_delays
	, CASE 
		WHEN sum(((vscp.completed - vscp.commenced) * 24 - vsy.total_delays)) = 0 THEN NULL 
		ELSE sum(vsc.total_moves) / sum(((vscp.completed - vscp.commenced) * 24 - vsy.total_delays))
	  END AS net_productivity
FROM vessel_summary_detail vsd
LEFT JOIN moves_by_vessel_and_crane vsc ON vsd.gkey = vsc.VSD_GKEY
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vsd.gkey = vscp.vsd_gkey AND vsc.crane_id = vscp.CRANE_ID 
LEFT JOIN delays_by_vessel_and_crane vsy ON vsd.gkey = vsy.VSD_GKEY AND vsc.CRANE_ID = vsy.CRANE_ID 
WHERE 
	--vsd.status = 'Final' AND 
	trunc(vsd.last_move) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
GROUP BY EXTRACT (YEAR FROM vsd.last_move), EXTRACT (MONTH FROM vsd.last_move)
ORDER BY EXTRACT (YEAR FROM vsd.last_move), EXTRACT (MONTH FROM vsd.last_move)
;

--Modifying the ZLO VSD query to work for MIT
--This seems to be working for the VSD approach as described in Alpha metrics.
--It doesn't have great agreement, around -25% error.
WITH 
	moves_by_vessel_and_crane AS (
		SELECT 
			vsd.GKEY AS vsd_gkey
			, vsc.crane_id
			, vsc.total_moves
			, vsc.commenced
			, vsc.completed
		FROM vessel_summary_detail vsd
		JOIN vessel_summary_cranes vsc ON vsc.vsd_gkey = vsd.GKEY
	), delays_by_vessel_and_crane AS (
		SELECT 
			vsd.gkey AS vsd_gkey
			, vsc.crane_id
			, sum (CASE WHEN dr.delay_level = 'S' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS shipping_delays
			, sum (CASE WHEN dr.delay_level = 'T' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS terminal_delays
			, sum (
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 ) AS total_delays
		FROM vessel_summary_detail vsd
		LEFT JOIN vessel_summary_cranes vsc ON vsc.VSD_GKEY = vsd.GKEY 
		LEFT JOIN vessel_summary_delays vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = vsc.crane_id
		LEFT JOIN delay_reasons dr ON vsy.delay_code = dr.CODE 
		GROUP BY vsd.gkey, vsc.crane_id
	), date_series AS (
		  SELECT
		    TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2022-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	), calendar AS (
		SELECT 
			EXTRACT (YEAR FROM DATE_in_series) AS year
			, EXTRACT (MONTH FROM date_in_series) AS month
		FROM date_series
		GROUP BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
		ORDER BY 
			EXTRACT (YEAR FROM DATE_in_series)
			, EXTRACT (MONTH FROM date_in_series)
	)
SELECT 
	cal.YEAR
	, cal.MONTH 
	, sum(nvl(vsc.TOTAL_MOVES,0)) AS moves
	, sum(nvl(vsc.completed - vsc.commenced,0)) * 24 AS crane_work_time
	, CASE 
		WHEN sum(nvl(vsc.completed - vsc.commenced,0)) = 0 THEN NULL 
		ELSE sum(vsc.total_moves) / sum((vsc.completed - vsc.commenced)) / 24
	  END AS raw_productivity
	, sum(nvl(vsy.shipping_delays,0)) AS shipping_delays
	, CASE 
		WHEN sum((nvl(vsc.completed - vsc.commenced,0) * 24 - nvl(vsy.shipping_delays,0))) = 0 THEN NULL
		ELSE 
			sum(nvl(vsc.total_moves,0)) / (sum(nvl(vsc.completed - vsc.commenced,0) * 24) - sum(nvl(vsy.shipping_delays,0)))
	  END AS gross_productivity
	, sum(nvl(vsy.terminal_delays,0)) AS terminal_delays
	, nvl(sum(vsy.total_delays),0) AS total_delays
	, CASE 
		WHEN sum((nvl(vsc.completed - vsc.commenced,0) * 24 - nvl(vsy.total_delays,0))) = 0 THEN NULL 
		ELSE sum(nvl(vsc.total_moves,0)) / (sum(nvl(vsc.completed - vsc.commenced,0)) * 24 - sum(nvl(vsy.total_delays,0)))
	  END AS net_productivity
FROM calendar cal
LEFT JOIN vessel_summary_detail vsd ON 
	EXTRACT (YEAR FROM vsd.last_move) = cal.YEAR AND
	EXTRACT (MONTH FROM vsd.last_move) = cal.MONTH AND 
	trunc(vsd.last_move) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
LEFT JOIN moves_by_vessel_and_crane vsc ON vsd.gkey = vsc.VSD_GKEY
LEFT JOIN delays_by_vessel_and_crane vsy ON vsd.gkey = vsy.VSD_GKEY AND vsc.CRANE_ID = vsy.CRANE_ID 
GROUP BY cal.YEAR, cal.month
ORDER BY cal.YEAR, cal.month
;

--Now to rebuild the EH approach and see if it agrees with the above VSD approach.
WITH 
	last_move_by_vessel AS (
		SELECT 
			vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, least(greatest(min(eh.posted),COALESCE (vv.ata,min(eh.posted))),COALESCE(vv.atd,min(eh.posted))) AS vessel_start
			, greatest(least(max(eh.posted),COALESCE (vv.atd,max(eh.posted))),COALESCE(vv.ata,max(eh.posted))) AS vessel_stop
		FROM equipment_history eh
		LEFT JOIN vessel_visits vv ON 
			eh.vsl_id = vv.vsl_id AND 
			(eh.voy_nbr = vv.in_voy_nbr OR eh.voy_nbr = vv.out_voy_nbr)
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-12-31','YYYY-MM-DD') AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
--			AND vv.vsl_id IS null
		GROUP BY vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.ata, vv.atd
--		ORDER BY vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr
	)--, moves_by_vessel_and_crane AS (
		SELECT 
			lmbv.vsl_id
			, lmbv.in_voy_nbr
			, lmbv.out_voy_nbr
			, lmbv.vessel_start
			, lmbv.vessel_stop
			, eh.crane_no
			, CASE WHEN count(*) > 10000 THEN 0 ELSE count(*) END AS moves
			, least(greatest(lmbv.vessel_start, min(eh.posted)),lmbv.vessel_stop) AS commenced
			, greatest(least(lmbv.vessel_stop, max(eh.posted)),lmbv.vessel_start) AS completed
			, CASE 
				WHEN greatest(least(lmbv.vessel_stop, max(eh.posted)),lmbv.vessel_start) -
						least(greatest(lmbv.vessel_start, min(eh.posted)),lmbv.vessel_stop) > 5
				THEN 9.0
				ELSE greatest(least(lmbv.vessel_stop, max(eh.posted)),lmbv.vessel_start) -
						least(greatest(lmbv.vessel_start, min(eh.posted)),lmbv.vessel_stop)
			  END AS crane_work_time
		FROM last_move_by_vessel lmbv
		LEFT JOIN equipment_history eh ON 
			eh.vsl_id = lmbv.vsl_id AND 
			(eh.voy_nbr = lmbv.in_voy_nbr OR eh.voy_nbr = lmbv.out_voy_nbr) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		--WHERE eh.vsl_id IS null
		GROUP BY lmbv.vsl_id, lmbv.in_voy_nbr, lmbv.out_voy_nbr, lmbv.vessel_start, lmbv.vessel_stop, eh.crane_no
		--ORDER BY lmbv.vsl_id, lmbv.in_voy_nbr, lmbv.out_voy_nbr, lmbv.vessel_start, lmbv.vessel_stop, eh.crane_no
	)
SELECT 
	EXTRACT (YEAR FROM mbvc.vessel_stop) AS year
	, EXTRACT (MONTH FROM mbvc.vessel_stop) AS month
	, sum(nvl(mbvc.MOVES,0)) AS moves
	, sum(nvl((mbvc.completed - mbvc.commenced),0)) * 24 AS crane_work_time
	, CASE 
		WHEN sum(nvl((mbvc.completed - mbvc.commenced),0)) = 0 THEN NULL 
		ELSE sum(nvl(mbvc.MOVES,0)) / sum(nvl((mbvc.completed - mbvc.commenced),0)) / 24
	  END AS raw_productivity
FROM moves_by_vessel_and_crane mbvc
GROUP BY EXTRACT (YEAR FROM mbvc.vessel_stop), EXTRACT (MONTH FROM mbvc.vessel_stop)
ORDER BY EXTRACT (YEAR FROM mbvc.vessel_stop), EXTRACT (MONTH FROM mbvc.vessel_stop)
;

SELECT 
	count(*) 
FROM equipment_history eh 
WHERE 
	trunc(eh.posted) BETWEEN to_date('2023-01-01','YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD') AND 
	(wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
;

--Emir's query for STS productivity
select SUBSTR (v.name, 0, 29) as name, vv.vsl_id, vv.in_voy_nbr||'/'||vv.out_voy_nbr voyage, vv.inbound_sailing_direction, vv.outbound_sailing_direction, vv.vsl_line_id, vv.out_srvc_id service, v.category, vv.berth, vv.file_ref, vv.ata, vv.atd, vv.work_started, vv.loaded, vv.discharged,
       sum(vs.quantity) moves, ((sum(vs.quantity)) - (nvl(y.rehandle_full_total,0) + nvl(y.rehandle_full_total,0))) as moves_reh, vv.gangs, vv.gross_hours, vv.paid_hours, vv.net_hours, round(((vv.atd - vv.ata) * 24),2) berth_hours, 
       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / vv.gross_hours),2) end as gross_production,
       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / vv.paid_hours),2) end as mit_gross_production,
       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / vv.net_hours),2) end as net_production,
       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / round(((vv.atd - vv.ata) * 24),2)),2) end as berth_production,
       case when v.category = 'RORO' then 0 else round(round((sum(vs.quantity) / vv.gross_hours),2) * vv.gangs, 2) end as vsl_moves_hour,
       nvl(y.load_full_total,0) as load_full_total,
nvl(y.load_Empty_total,0) as load_Empty_total,
nvl(y.unload_full_total,0) as unload_full_total,
nvl(y.unload_Empty_total,0) as unload_Empty_total,
nvl(y.rehandle_empty_total,0) as rehandle_empty_total,
nvl(y.rehandle_full_total,0) as rehandle_full_total,
nvl(y.unload_chassis_total,0) as unload_chassis_total,
nvl(y.load_chassis_total,0) as load_chassis_total,
nvl(y.unload_cont_total,0) as unload_cont_total,
nvl(y.load_cont_total,0) as load_cont_total,
nvl(y.unload_reefer_full_total,0) as unload_reefer_full_total,
nvl(y.load_reefer_full_total,0) as load_reefer_full_total
from vessel_statistics vs, vessel_visits vv, vessels v, (select x.vv_vsl_id, x.vv_in_voy_nbr, x.vv_out_voy_nbr, 
                                                                sum(x.load_full_total) as load_full_total,
                                                                sum(x.load_Empty_total) as load_Empty_total,
                                                                sum(x.unload_full_total) as unload_full_total,
                                                                sum(x.unload_Empty_total) as unload_Empty_total,
                                                                sum(x.rehandle_empty_total) as rehandle_empty_total,
                                                                sum(x.rehandle_full_total) as rehandle_full_total,
                                                                sum(x.unload_chassis_total) as unload_chassis_total,
                                                                sum(x.load_chassis_total) as load_chassis_total,
                                                                sum(x.unload_cont_total)as unload_cont_total,
                                                                sum(x.load_cont_total) as load_cont_total,
                                                                sum(x.unload_reefer_full_total) as unload_reefer_full_total,
                                                                sum(x.load_reefer_full_total) as load_reefer_full_total
                                                          from (select vv.vsl_id as vv_vsl_id, vv.in_voy_nbr as vv_in_voy_nbr, vv.out_voy_nbr as vv_out_voy_nbr,
                                                                case
                                                                when wtask_id ='LOAD' and status ='F' then sum(vs.quantity) 
                                                                end as load_full_total,
                                                                case
                                                                when wtask_id ='LOAD' and status ='E' then sum(vs.quantity) 
                                                                end as load_Empty_total,
                                                                case
                                                                when wtask_id ='UNLOAD' and status ='F' then sum(vs.quantity) 
                                                                end as unload_full_total,
                                                                case
                                                                when wtask_id ='UNLOAD' and status ='E' then sum(vs.quantity) 
                                                                end as unload_Empty_total,
                                                                case
                                                                when substr(wtask_id,1,2) ='RE' and status ='F' then sum(vs.quantity) 
                                                                end as rehandle_full_total,
                                                                case
                                                                when substr(wtask_id,1,2) ='RE' and status ='E' then sum(vs.quantity) 
                                                                end as rehandle_empty_total,
                                                                case 
                                                                when wtask_id ='UNLOAD' and substr(sztp_id,3,2) in ('CH','EX','FB') then sum(vs.quantity) 
                                                                end as unload_chassis_total,
                                                                case 
                                                                when wtask_id ='LOAD' and substr(sztp_id,3,2) in ('CH','EX','FB') then sum(vs.quantity) 
                                                                end as load_chassis_total,
                                                                case 
                                                                when wtask_id ='UNLOAD' and substr(sztp_id,3,2) not in ('CH','EX','FB','BL','RT') then sum(vs.quantity) 
                                                              end as unload_cont_total,
                                                              case 
                                                              when wtask_id ='LOAD' and substr(sztp_id,3,2) not in ('CH','EX','FB','BL','RT') then sum(vs.quantity) 
                                                              end as load_cont_total,
                                                               --TOTAL REEFERS
                                                                             case
                                                                            when wtask_id ='UNLOAD' and substr(sztp_id,3,2) in ('RF','RH','RV','MU') and status ='F' then sum(vs.quantity) 
                                                                            end as unload_reefer_full_total,
                                                                            case
                                                                             when wtask_id ='LOAD' and substr(sztp_id,3,2) in ('RF','RH','RV','MU') and status ='F' then sum(vs.quantity)  
                                                                            end as load_reefer_full_total
                                                              from vessel_statistics vs, vessel_visits vv
                                                              --where atd between ? and ?
                                                              WHERE --to_char(atd,'MM/YY') = to_char(sysdate,'MM/YY') and
															  to_char(ata, 'YYYY') > '2009'
															  and to_char(atd, 'YYYY') < '2040'
                                                              and vs.vv_vsl_id(+) = vv.vsl_id
                                                              and vs.vv_in_voy_nbr(+) = vv.in_voy_nbr
                                                              and vs.vv_out_voy_nbr(+) = vv.out_voy_nbr
                                                              group by vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vs.wtask_id, vs.status,  substr(sztp_id,3,2)) x
                                                              group by x.vv_vsl_id, x.vv_in_voy_nbr, x.vv_out_voy_nbr) y
where vs.vv_vsl_id(+) = vv.vsl_id
and vs.vv_in_voy_nbr(+) = vv.in_voy_nbr
and vs.vv_out_voy_nbr(+) = vv.out_voy_nbr
and vv.vsl_id = v.id
and vv.vsl_id = y.vv_vsl_id
and vv.in_voy_nbr = y.vv_in_voy_nbr
and vv.out_voy_nbr = y.vv_out_voy_nbr
and vv.work_started is not null
group by v.name, vv.vsl_id, vv.in_voy_nbr||'/'||vv.out_voy_nbr, vv.inbound_sailing_direction, vv.outbound_sailing_direction, vv.vsl_line_id, vv.out_srvc_id, v.category, vv.berth, vv.file_ref, vv.loaded, vv.discharged, 
vv.gangs, vv.gross_hours, vv.paid_hours, vv.net_hours,  y.load_full_total, y.load_Empty_total, y.unload_full_total, y.unload_Empty_total, y.rehandle_empty_total, y.rehandle_full_total, 
y.unload_chassis_total, y.load_chassis_total, y.unload_cont_total, y.load_cont_total, y.unload_reefer_full_total, y.load_reefer_full_total, vv.ata, vv.atd, vv.work_started
order by 2

--Replicating the quantity column in the vessel_statistics table.
--The vs table is keyed by vessel visit, line, task, size/type, and mt/full.
--The fact is the quantity.
--Let's get the vessel visits that departed in 2022 or 2023
--1514986 joined records (without where clause selecting years 2022 and 2023). 1514986 without join. No null vv records. Join is 1:1.
--109568 with selection of 2022 and 2023 in place.
--This query produced the vessel_statistics target.
SELECT
	vs.VV_VSL_ID 
	, vs.VV_IN_VOY_NBR 
	, vs.VV_OUT_VOY_NBR 
	, vs.LINE_ID 
	, vs.WTASK_ID 
	, vs.SZTP_ID 
	, vs.STATUS 
	, sum(vs.QUANTITY )
	, vv.atd
FROM vessel_statistics vs
LEFT JOIN vessel_visits vv ON 
	vs.VV_VSL_ID = vv.VSL_ID AND 
	vs.VV_IN_VOY_NBR = vv.IN_VOY_NBR AND 
	vs.VV_OUT_VOY_NBR = vv.OUT_VOY_NBR 
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	EXTRACT (YEAR FROM vv.atd) = 2023)
GROUP BY 
	vs.VV_VSL_ID 
	, vs.VV_IN_VOY_NBR 
	, vs.VV_OUT_VOY_NBR 
	, vs.LINE_ID 
	, vs.WTASK_ID 
	, vs.SZTP_ID 
	, vs.STATUS 
	, vv.atd
ORDER BY vv.ATD, vs.LINE_ID, vs.WTASK_ID, vs.SZTP_ID, vs.STATUS  
;

--Summary by vessel
SELECT
	vs.VV_VSL_ID 
	, sum(vs.QUANTITY )
	, vv.atd
FROM vessel_statistics vs
LEFT JOIN vessel_visits vv ON 
	vs.VV_VSL_ID = vv.VSL_ID AND 
	vs.VV_IN_VOY_NBR = vv.IN_VOY_NBR AND 
	vs.VV_OUT_VOY_NBR = vv.OUT_VOY_NBR 
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	EXTRACT (YEAR FROM vv.atd) = 2023)
GROUP BY 
	vs.VV_VSL_ID 
	, vv.atd
ORDER BY vv.ATD, vs.vv_VSL_ID 
;

--Now to replicated the above result set using the equipment_history table.
--No nulls in the left join for 2022 and 2023.
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.VSL_LINE_ID 
	, eh.WTASK_ID 
	, eh.SZTP_ID 
	, eh.STATUS 
	, count(*) AS quantity
	, vv.atd
FROM equipment_history eh
LEFT JOIN VESSEL_VISITS vv ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.VSL_LINE_ID 
	, eh.WTASK_ID 
	, eh.SZTP_ID 
	, eh.STATUS 
	, vv.atd
ORDER BY vv.ATD, vv.VSL_LINE_ID, eh.WTASK_ID, eh.SZTP_ID, eh.STATUS  
;

--Summarized by vessel
SELECT 
	vv.VSL_ID 
	, count(*) AS quantity
	, vv.atd
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.atd
ORDER BY vv.ATD, vv.VSL_ID 
;

--Now to attempt to replicate the net hours in vessel_visits using the equipment_history table.
--I'm going to specify an interval and when the interval between two successive transaction for the same vessel visit is greater than that interval,
--it's a delay.
--The below captures the vessel visits for use with gathering the delays.
--Do a selection on the equipment_history table before joining it to itself.

--Produces reasonable results. Need to go back and check errors on delay times. Execution time: 42 s.
WITH 
	VESSEL_VISITS_Of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
--		ORDER BY vv.ATD, vv.VSL_ID 
	), intervals AS (
		SELECT
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.ata
			, vvoi.atd
			, eh.crane_no
			, eh.wtask_id
			, eh.posted
			, (eh.posted - LAG(eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr, vvoi.out_voy_nbr, eh.crane_no ORDER BY eh.posted))*24*60 AS time_interval 
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN EQUIPMENT_HISTORY eh ON
			eh.vsl_id = vvoi.vsl_id AND 
			(eh.voy_nbr = vvoi.in_voy_nbr OR
			 eh.voy_nbr = vvoi.out_voy_nbr)
		WHERE 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
			, eh.crane_no
			, eh.posted
*/	), aggregates AS (
		SELECT
			EXTRACT (YEAR FROM inv.atd) AS year
			, extract(MONTH FROM inv.atd) AS month
			, count(*) AS moves
			, sum (
				CASE 
					WHEN time_interval > 720 THEN 0
					ELSE time_interval
			  	END
			  ) AS raw_time
			, sum (
				CASE 
					WHEN time_interval > 5.5 THEN 0
					ELSE time_interval
			  	END
			  ) AS net_time
		FROM intervals inv
		GROUP BY EXTRACT (YEAR FROM inv.atd), extract(MONTH FROM inv.atd)
--		ORDER BY EXTRACT (YEAR FROM inv.atd), extract(MONTH FROM inv.atd)
	)
SELECT 
	agg.YEAR
	, agg.MONTH
	, agg.moves / agg.raw_time * 60 AS "RAW"
	, agg.moves / agg.net_time * 60 AS net
FROM aggregates agg
ORDER BY agg.YEAR, agg.month
;

--Need the target on delay times from vessel_visits
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.ata
	, vv.atd
	, vv.NET_HOURS 
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ata
	, vv.atd
	, vv.NET_HOURS 
ORDER BY vv.ATD, vv.VSL_ID 

--Checking errors on net_hours
--Have to do this a year at a time or the query doesn't return.
WITH 
	VESSEL_VISITS_Of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			EXTRACT (YEAR FROM vv.atd) = 2023 and
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID 
	), intervals AS (
		SELECT
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.ata
			, vvoi.atd
			, eh.crane_no
			, eh.wtask_id
			, eh.posted
			, (eh.posted - LAG(eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr, vvoi.out_voy_nbr, eh.crane_no ORDER BY eh.posted))*24*60 AS time_interval 
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN EQUIPMENT_HISTORY eh ON
			eh.vsl_id = vvoi.vsl_id AND 
			(eh.voy_nbr = vvoi.in_voy_nbr OR
			 eh.voy_nbr = vvoi.out_voy_nbr)
		WHERE 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
			, eh.crane_no
			, eh.posted
*/	)
SELECT 
	inv.vsl_id
	, inv.in_voy_nbr
	, inv.out_voy_nbr
	, count(*) AS moves
	, sum(time_interval) / 60 AS raw_hours
	, sum (
		CASE 
			WHEN time_interval > 5.5 THEN 0
			ELSE time_interval
	  	END
	  ) / 60 AS net_hours
FROM intervals inv
GROUP BY
	inv.vsl_id
	, inv.in_voy_nbr
	, inv.out_voy_nbr
	, inv.atd
ORDER BY inv.atd, inv.vsl_id
;

-- Now for ZLO
-- Equipment history move counts
SELECT 
	vv.VSL_ID 
	, count(*) AS quantity
	, vv.atd
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR EXTRACT (year FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.atd
ORDER BY vv.ATD, vv.VSL_ID 
;

-- Vessel statistics move counts
--Summary by vessel
--There are no vessel_statistics records for the period of interest
SELECT
	vv.VSL_ID 
	, sum(vs.QUANTITY )
	, vv.atd
FROM vessel_visits vv
LEFT JOIN vessel_statistics vs ON 
	vs.VV_VSL_ID = vv.VSL_ID AND 
	vs.VV_IN_VOY_NBR = vv.IN_VOY_NBR AND 
	vs.VV_OUT_VOY_NBR = vv.OUT_VOY_NBR 
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	EXTRACT (YEAR FROM vv.atd) = 2023)
GROUP BY 
	vv.VSL_ID 
	, vv.atd
ORDER BY vv.ATD, vv.VSL_ID 
;
SELECT max(created) FROM vessel_statistics vs;

SELECT max(atd) FROM vessel_visits vv;

--Now let's get monthly averages. This seems to work.
--Original ZLO VS approach, but it produces a total moves of around 11M moves per year. Way too high.
--I'm rewriting the original ZLO VS approach so that the total moves agrees with the query by vessel and crane.
--The query below reproduces the original by_vessel move counts and eliminates the group by error.
--ZLO reports gross productivities so this by vessel and crane query when aggregated by month agrees pretty well with their reports
WITH 
	moves_by_vessel_and_crane AS (
		SELECT 
			vsd.GKEY AS vsd_gkey
			, vsc.crane_id
			, vsc.total_moves
		FROM vessel_summary_detail vsd
		JOIN vessel_summary_cranes vsc ON vsc.vsd_gkey = vsd.GKEY
	), delays_by_vessel_and_crane AS (
		SELECT 
			vsd.gkey AS vsd_gkey
			, vsc.crane_id
			, sum (CASE WHEN dr.delay_level = 'S' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS shipping_delays
			, sum (CASE WHEN dr.delay_level = 'T' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS terminal_delays
			, sum (
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 ) AS total_delays
		FROM vessel_summary_detail vsd
		JOIN vessel_summary_cranes vsc ON vsc.VSD_GKEY = vsd.GKEY 
		JOIN vessel_summary_delays vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = vsc.crane_id
		JOIN delay_reasons dr ON vsy.delay_code = dr.CODE 
		GROUP BY vsd.gkey, vsc.crane_id
	)
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
	, vsy.shipping_delays AS shipping_delays
	, CASE 
		WHEN ((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays) = 0 THEN NULL
		ELSE 
			vsc.total_moves / ((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays)
	  END AS gross_productivity
	, vsy.terminal_delays AS terminal_delays
	, CASE 
		WHEN ((vscp.completed - vscp.commenced) * 24 - vsy.terminal_delays) = 0 THEN NULL 
		ELSE vsc.total_moves / ((vscp.completed - vscp.commenced) * 24 - vsy.terminal_delays)
	  END AS net_productivity
FROM vessel_summary_detail vsd
LEFT JOIN moves_by_vessel_and_crane vsc ON vsd.gkey = vsc.VSD_GKEY
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vsd.gkey = vscp.vsd_gkey AND vsc.crane_id = vscp.CRANE_ID 
LEFT JOIN delays_by_vessel_and_crane vsy ON vsd.gkey = vsy.VSD_GKEY AND vsc.CRANE_ID = vsy.CRANE_ID 
WHERE 
	vsd.status = 'Final'
	AND trunc(vsd.last_move) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
ORDER BY vsd.LAST_MOVE, vsc.CRANE_ID
;

--Now to aggregate the above by year and month
--Yay! The total moves agree between the by vessel query above and the by month query below.
--ZLO reports gross productivities. This query agrees pretty well with the reports.
--Next steps - verify that this query works for ZLO and MIT or needs adjustments and document adjustments.
--Validate total move counts for VS approach at MIT.
--Build EH approach at MIT.
--Bring EH approach back to ZLO.
--Take EH approach to USWC.
WITH 
	moves_by_vessel_and_crane AS (
		SELECT 
			vsd.GKEY AS vsd_gkey
			, vsc.crane_id
			, vsc.total_moves
		FROM vessel_summary_detail vsd
		JOIN vessel_summary_cranes vsc ON vsc.vsd_gkey = vsd.GKEY
	), delays_by_vessel_and_crane AS (
		SELECT 
			vsd.gkey AS vsd_gkey
			, vsc.crane_id
			, sum (CASE WHEN dr.delay_level = 'S' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS shipping_delays
			, sum (CASE WHEN dr.delay_level = 'T' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS terminal_delays
			, sum (
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 ) AS total_delays
		FROM vessel_summary_detail vsd
		LEFT JOIN vessel_summary_cranes vsc ON vsc.VSD_GKEY = vsd.GKEY 
		LEFT JOIN vessel_summary_delays vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = vsc.crane_id
		LEFT JOIN delay_reasons dr ON vsy.delay_code = dr.CODE 
		GROUP BY vsd.gkey, vsc.crane_id
	)
SELECT 
	EXTRACT (YEAR FROM vsd.last_move)
	, EXTRACT (MONTH FROM vsd.last_move)
	, sum(vsc.TOTAL_MOVES)
	, sum((vscp.completed - vscp.commenced)) * 24 AS crane_work_time
	, CASE 
		WHEN sum((vscp.completed - vscp.commenced)) = 0 THEN NULL 
		ELSE sum(vsc.total_moves) / sum((vscp.completed - vscp.commenced)) / 24
	  END AS raw_productivity
	, sum(vsy.shipping_delays) AS shipping_delays
	, CASE 
		WHEN sum(((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays)) = 0 THEN NULL
		ELSE 
			sum(vsc.total_moves) / sum(((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays))
	  END AS gross_productivity
	, sum(vsy.terminal_delays) AS terminal_delays
	, sum(vsy.total_delays) AS total_delays
	, CASE 
		WHEN sum(((vscp.completed - vscp.commenced) * 24 - vsy.total_delays)) = 0 THEN NULL 
		ELSE sum(vsc.total_moves) / sum(((vscp.completed - vscp.commenced) * 24 - vsy.total_delays))
	  END AS net_productivity
FROM vessel_summary_detail vsd
LEFT JOIN moves_by_vessel_and_crane vsc ON vsd.gkey = vsc.VSD_GKEY
LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vsd.gkey = vscp.vsd_gkey AND vsc.crane_id = vscp.CRANE_ID 
LEFT JOIN delays_by_vessel_and_crane vsy ON vsd.gkey = vsy.VSD_GKEY AND vsc.CRANE_ID = vsy.CRANE_ID 
WHERE 
	--vsd.status = 'Final' AND 
	trunc(vsd.last_move) BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')  
GROUP BY EXTRACT (YEAR FROM vsd.last_move), EXTRACT (MONTH FROM vsd.last_move)
ORDER BY EXTRACT (YEAR FROM vsd.last_move), EXTRACT (MONTH FROM vsd.last_move)
;

--Statistics summarized by vessel
WITH 
	moves_by_vessel_and_crane AS (
		SELECT 
			vsd.GKEY AS vsd_gkey
			, vsc.crane_id
			, vsc.total_moves
		FROM vessel_summary_detail vsd
		JOIN vessel_summary_cranes vsc ON vsc.vsd_gkey = vsd.GKEY
	), delays_by_vessel_and_crane AS (
		SELECT 
			vsd.gkey AS vsd_gkey
			, vsc.crane_id
			, sum (CASE WHEN dr.delay_level = 'S' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS shipping_delays
			, sum (CASE WHEN dr.delay_level = 'T' THEN 
					TO_number (to_char(vsy.delay_time, 'HH24')) +
					to_number (to_char(vsy.delay_time, 'MI')) /60 +
					to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 
				ELSE 0 END) AS terminal_delays
			, sum (
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60 ) AS total_delays
		FROM vessel_summary_detail vsd
		JOIN vessel_summary_cranes vsc ON vsc.VSD_GKEY = vsd.GKEY 
		JOIN vessel_summary_delays vsy ON vsy.VSD_GKEY = vsd.GKEY AND vsy.crane_id = vsc.crane_id
		JOIN delay_reasons dr ON vsy.delay_code = dr.CODE 
		GROUP BY vsd.gkey, vsc.crane_id
	), statistics_by_vessel_and_crane AS (
		SELECT 
			vsd.GKEY 
			, vsd.VSL_ID 
			, vsd.VOY_IN_NBR 
			, vsd.VOY_OUT_NBR 
			, vsd.FIRST_MOVE AS vsl_1st_move
			, vsd.LAST_MOVE AS vsl_last_move
			, vv.atd
			, vsc.CRANE_ID 
			, vsc.TOTAL_MOVES 
			, vscp.COMMENCED AS crane_start
			, vscp.COMPLETED AS crane_finish
			, (vscp.completed - vscp.commenced) * 24 AS crane_work_time
			, CASE 
				WHEN (vscp.completed - vscp.commenced) = 0 THEN NULL 
				ELSE vsc.total_moves / (vscp.completed - vscp.commenced) / 24
			  END AS raw_productivity
			, vsy.shipping_delays AS shipping_delays
			, CASE 
				WHEN ((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays) = 0 THEN NULL
				ELSE 
					vsc.total_moves / ((vscp.completed - vscp.commenced) * 24 - vsy.shipping_delays)
			  END AS gross_productivity
			, vsy.terminal_delays AS terminal_delays
			, CASE 
				WHEN ((vscp.completed - vscp.commenced) * 24 - vsy.terminal_delays) = 0 THEN NULL 
				ELSE vsc.total_moves / ((vscp.completed - vscp.commenced) * 24 - vsy.terminal_delays)
			  END AS net_productivity
		FROM vessel_summary_detail vsd
		LEFT JOIN moves_by_vessel_and_crane vsc ON vsd.gkey = vsc.VSD_GKEY
		LEFT JOIN VESSEL_SUMMARY_CRANE_PROD vscp ON vsd.gkey = vscp.vsd_gkey AND vsc.crane_id = vscp.CRANE_ID 
		LEFT JOIN delays_by_vessel_and_crane vsy ON vsd.gkey = vsy.VSD_GKEY AND vsc.CRANE_ID = vsy.CRANE_ID 
		LEFT JOIN vessel_visits vv ON vv.vsl_id = vsd.vsl_id AND vv.in_voy_nbr = vsd.voy_in_nbr AND vv.out_voy_nbr = vsd.voy_out_nbr
		WHERE 
			vsd.status = 'Final'
			AND (EXTRACT (YEAR FROM vv.atd) = 2022 OR EXTRACT (YEAR FROM vv.atd) = 2023)  
		ORDER BY vv.atd, vsc.CRANE_ID
	)
SELECT
	stats.vsl_id
	, vv.atd
	, sum (stats.total_moves) AS moves
	, sum (stats.crane_work_time - stats.shipping_delays - stats.terminal_delays) AS net_hours
FROM statistics_by_vessel_and_crane stats
LEFT JOIN vessel_visits vv ON 
	vv.vsl_id = stats.vsl_id AND 
	vv.in_voy_nbr = stats.voy_in_nbr AND 
	vv.out_voy_nbr = stats.voy_out_nbr
GROUP BY stats.vsl_id, vv.atd
ORDER BY vv.atd, stats.vsl_id
;

--Checking errors on net_hours
--At ZLO UAT 2 I can't even download a month of data at a time. I won't be viewing the distribution of intervals here.

WITH 
	VESSEL_VISITS_Of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			EXTRACT (YEAR FROM vv.atd) = 2022 AND EXTRACT (MONTH FROM vv.atd) = 1 AND --EXTRACT (Day FROM vv.atd) = 1 and
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID 
	)
SELECT
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.ata
	, vvoi.atd
	, eh.crane_no
	, eh.wtask_id
	, eh.posted
	, (eh.posted - LAG(eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr, vvoi.out_voy_nbr, eh.crane_no ORDER BY eh.posted))*24*60 AS time_interval 
FROM vessel_visits_of_interest vvoi
LEFT JOIN EQUIPMENT_HISTORY eh ON
	eh.vsl_id = vvoi.vsl_id AND 
	(eh.voy_nbr = vvoi.in_voy_nbr OR
	 eh.voy_nbr = vvoi.out_voy_nbr)
WHERE 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
ORDER BY 
	vvoi.atd
	, vvoi.vsl_id
	, eh.crane_no
	, eh.posted

--Results by vessel
WITH 
	VESSEL_VISITS_Of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			EXTRACT (YEAR FROM vv.atd) = 2023 AND EXTRACT (MONTH FROM vv.atd) > 9 AND EXTRACT (MONTH FROM vv.atd) <= 12 and
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID 
	), intervals AS (
		SELECT
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.ata
			, vvoi.atd
			, eh.crane_no
			, eh.wtask_id
			, eh.posted
			, (eh.posted - LAG(eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr, vvoi.out_voy_nbr, eh.crane_no ORDER BY eh.posted))*24*60 AS time_interval 
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN EQUIPMENT_HISTORY eh ON
			eh.vsl_id = vvoi.vsl_id AND 
			(eh.voy_nbr = vvoi.in_voy_nbr OR
			 eh.voy_nbr = vvoi.out_voy_nbr)
		WHERE 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
			, eh.crane_no
			, eh.posted
*/	)
SELECT 
	inv.vsl_id
	, inv.in_voy_nbr
	, inv.out_voy_nbr
	, count(*) AS moves
	, sum (
		CASE 
			WHEN time_interval > 720 THEN 0
			ELSE time_interval
	  	END
	  ) / 60 AS raw_hours
	, sum (
		CASE 
			WHEN time_interval > 5.5 THEN 0
			ELSE time_interval
	  	END
	  ) / 60 AS net_hours
FROM intervals inv
GROUP BY
	inv.vsl_id
	, inv.in_voy_nbr
	, inv.out_voy_nbr
	, inv.atd
ORDER BY inv.atd, inv.vsl_id
;

--ZLO EH results
WITH 
	VESSEL_VISITS_Of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			EXTRACT (YEAR FROM vv.atd) = 2023 AND EXTRACT (MONTH FROM vv.atd) > 5 AND EXTRACT (MONTH FROM vv.atd) <= 8 and
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
--		ORDER BY vv.ATD, vv.VSL_ID 
	), intervals AS (
		SELECT
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.ata
			, vvoi.atd
			, eh.crane_no
			, eh.wtask_id
			, eh.posted
			, (eh.posted - LAG(eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr, vvoi.out_voy_nbr, eh.crane_no ORDER BY eh.posted))*24*60 AS time_interval 
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN EQUIPMENT_HISTORY eh ON
			eh.vsl_id = vvoi.vsl_id AND 
			(eh.voy_nbr = vvoi.in_voy_nbr OR
			 eh.voy_nbr = vvoi.out_voy_nbr)
		WHERE 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
			, eh.crane_no
			, eh.posted
*/	), aggregates AS (
		SELECT
			EXTRACT (YEAR FROM inv.atd) AS year
			, extract(MONTH FROM inv.atd) AS month
			, count(*) AS moves
			, sum (
				CASE 
					WHEN time_interval > 720 THEN 0
					ELSE time_interval
			  	END
			  ) AS raw_time
			, sum (
				CASE 
					WHEN time_interval > 5.5 THEN 0
					ELSE time_interval
			  	END
			  ) AS net_time
		FROM intervals inv
		GROUP BY EXTRACT (YEAR FROM inv.atd), extract(MONTH FROM inv.atd)
--		ORDER BY EXTRACT (YEAR FROM inv.atd), extract(MONTH FROM inv.atd)
	)
SELECT 
	agg.YEAR
	, agg.MONTH
	, agg.moves / agg.raw_time * 60 AS "RAW"
	, agg.moves / agg.net_time * 60 AS net
FROM aggregates agg
ORDER BY agg.YEAR, agg.month
;

--Looking at PCT now
--Productivities by vessel
WITH 
	VESSEL_VISITS_Of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(trunc(vv.atd) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2022-12-31','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID 
	), intervals AS (
		SELECT
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.ata
			, vvoi.atd
			, eh.crane_no
			, eh.wtask_id
			, eh.posted
			, (eh.posted - LAG(eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr, vvoi.out_voy_nbr, eh.crane_no ORDER BY eh.posted))*24*60 AS time_interval 
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN EQUIPMENT_HISTORY eh ON
			eh.vsl_id = vvoi.vsl_id AND 
			(eh.voy_nbr = vvoi.in_voy_nbr OR
			 eh.voy_nbr = vvoi.out_voy_nbr)
		WHERE 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
			, eh.crane_no
			, eh.posted
*/	)
SELECT 
	inv.vsl_id
	, inv.in_voy_nbr
	, inv.out_voy_nbr
	, inv.ata
	, inv.atd
	, count(*) AS moves
	, sum (
		CASE 
			WHEN time_interval > 720 THEN 0
			ELSE time_interval
	  	END
	  ) AS raw_time
	, sum (
		CASE 
			WHEN time_interval > 60 THEN 0
			ELSE time_interval
	  	END
	  ) AS net_time
FROM intervals inv
GROUP BY inv.vsl_id, inv.in_voy_nbr, inv.out_voy_nbr, inv.ata, inv.atd
ORDER BY inv.atd, inv.vsl_id
;


--Productivities by month
WITH 
	VESSEL_VISITS_Of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(trunc(vv.atd) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2022-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID 
	), intervals AS (
		SELECT
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.ata
			, vvoi.atd
			, eh.crane_no
			, eh.wtask_id
			, eh.posted
			, (eh.posted - LAG(eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr, vvoi.out_voy_nbr, eh.crane_no ORDER BY eh.posted))*24*60 AS time_interval 
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN EQUIPMENT_HISTORY eh ON
			eh.vsl_id = vvoi.vsl_id AND 
			(eh.voy_nbr = vvoi.in_voy_nbr OR
			 eh.voy_nbr = vvoi.out_voy_nbr)
		WHERE 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
			, eh.crane_no
			, eh.posted
*/	), aggregates AS (
		SELECT
			EXTRACT (YEAR FROM inv.atd) AS year
			, extract(MONTH FROM inv.atd) AS month
			, count(*) AS moves
			, sum (
				CASE 
					WHEN time_interval > 720 THEN 0
					ELSE time_interval
			  	END
			  ) AS raw_time
			, sum (
				CASE 
					WHEN time_interval > 5.5 THEN 0
					ELSE time_interval
			  	END
			  ) AS net_time
		FROM intervals inv
		GROUP BY EXTRACT (YEAR FROM inv.atd), extract(MONTH FROM inv.atd)
		--ORDER BY EXTRACT (YEAR FROM inv.atd), extract(MONTH FROM inv.atd)
	)
SELECT 
	agg.YEAR
	, agg.MONTH
	, agg.moves / agg.raw_time * 60 AS "RAW"
	, agg.moves / agg.net_time * 60 AS net
FROM aggregates agg
ORDER BY agg.YEAR, agg.month
;

/*
 * At this point I'm abandoning the attempt to derive delays from the equipment_history table.
 * The threshold that determined a delay for matching the net delays at MIT and ZLO was 5.5 minutes.
 * For PCT, it is around an hour. I don't want to present that difference, nor do I think that I can 
 * support its extraordinary claim that at PCT a move that takes less than an hour to complete has
 * not been delayed. Henceforth, delays will be taken from a source, like the vessel_summary_delays
 * table or the AS400, and not derived. 
 * 
 * I'm switching back to MIT and ZLO to recompute the raw, gross, and net productivities and compare
 * them to what is reported.
 */

--Vessel Statistics - Summary by vessel
SELECT
	vs.VV_VSL_ID 
	, sum(vs.QUANTITY )
	, vv.atd
FROM vessel_statistics vs
LEFT JOIN vessel_visits vv ON 
	vs.VV_VSL_ID = vv.VSL_ID AND 
	vs.VV_IN_VOY_NBR = vv.IN_VOY_NBR AND 
	vs.VV_OUT_VOY_NBR = vv.OUT_VOY_NBR 
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	EXTRACT (YEAR FROM vv.atd) = 2023)
GROUP BY 
	vs.VV_VSL_ID 
	, vv.atd
ORDER BY vv.ATD, vs.vv_VSL_ID 
;

--EH - Summarized by vessel
SELECT 
	vv.VSL_ID 
	, count(*) AS quantity
	, vv.atd
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.atd
ORDER BY vv.ATD, vv.VSL_ID 
;

--Vessel visits of interest
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ata
	, vv.atd
ORDER BY vv.ATD, vv.VSL_ID 
;

--Delays from vessel_visits
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.PAID_HOURS 
	, vv.GROSS_HOURS 
	, vv.NET_HOURS 
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ata
	, vv.atd
	, vv.PAID_HOURS 
	, vv.GROSS_HOURS 
	, vv.NET_HOURS 
ORDER BY vv.ATD, vv.VSL_ID 
;

--Delays from vessel_summary_delays
WITH 
	vessel_visits_of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID 
	)
SELECT 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
	, sum (
		CASE 
			WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS terminal_delays
	, sum (
		CASE 
			WHEN vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS total_delays
FROM vessel_visits_of_interest vvoi
LEFT JOIN vessel_summary_detail vsd ON
	vsd.vsl_id = vvoi.vsl_id AND 
	vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
	vsd.voy_out_nbr = vvoi.out_voy_nbr
LEFT JOIN vessel_summary_delays vsy ON
	vsy.vsd_gkey = vsd.gkey
LEFT JOIN delay_reasons dr ON
	dr.code = vsy.delay_code
GROUP BY 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.atd
ORDER BY 
	vvoi.atd
	, vvoi.vsl_id
;

--Raw times from EH
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, eh.CRANE_NO 
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
	)
SELECT 
	cwt.vsl_id
	, cwt.in_voy_nbr
	, cwt.out_voy_nbr
	, sum(cwt.crane_work_hours) AS work_hours
FROM crane_work_times cwt 
GROUP BY 
	cwt.vsl_id
	, cwt.in_voy_nbr
	, cwt.out_voy_nbr
	, cwt.atd
ORDER BY cwt.atd, cwt.vsl_id
;

--Productivities by vessel
--I will only compute three productivities. They will all use EH. Raw will use the work_hours computed from EH. Gross and Net will use
--gross_hours and net_hours from vessel_visits.
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, vv.gross_hours
			, vv.net_hours
			, eh.CRANE_NO 
			, count(eh.posted) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, vv.gross_hours
			, vv.net_hours
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
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
ORDER BY cwt.atd, cwt.vsl_id
;

--Productivities by month
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, vv.gross_hours
			, vv.net_hours
			, eh.CRANE_NO 
			, count(eh.posted) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, vv.gross_hours
			, vv.net_hours
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
	), group_by_vessel AS (
		SELECT 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
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
		--ORDER BY cwt.atd, cwt.vsl_id
	)
SELECT 
	EXTRACT (YEAR FROM gbv.atd) AS year
	, EXTRACT (MONTH FROM gbv.atd) AS month
	, sum(gbv.moves) AS moves
	, sum(gbv.work_hours) AS work_hours
	, sum(gbv.gross_hours) AS gross_hours
	, sum(gbv.net_hours) AS net_hours
	, CASE WHEN sum(gbv.work_hours) = 0 THEN NULL ELSE sum(gbv.moves) / sum(gbv.work_hours) END AS "RAW"
	, CASE WHEN sum(gbv.gross_hours) = 0 THEN NULL ELSE sum(gbv.moves) / sum(gbv.gross_hours) END AS gross
	, CASE WHEN sum(gbv.net_hours) = 0 THEN NULL ELSE sum(gbv.moves) / sum(gbv.net_hours) END AS net
FROM group_by_vessel gbv
GROUP BY
	EXTRACT (YEAR FROM gbv.atd)
	, EXTRACT (MONTH FROM gbv.atd)
ORDER BY 
	EXTRACT (YEAR FROM gbv.atd)
	, EXTRACT (MONTH FROM gbv.atd)
;

--Emir's query
WITH 
	emir_query AS (
		select SUBSTR (v.name, 0, 29) as name, vv.vsl_id, vv.in_voy_nbr||'/'||vv.out_voy_nbr voyage, vv.inbound_sailing_direction, vv.outbound_sailing_direction, vv.vsl_line_id, vv.out_srvc_id service, v.category, vv.berth, vv.file_ref, vv.ata, vv.atd, vv.work_started, vv.loaded, vv.discharged,
		       sum(vs.quantity) moves, ((sum(vs.quantity)) - (nvl(y.rehandle_full_total,0) + nvl(y.rehandle_full_total,0))) as moves_reh, vv.gangs, vv.gross_hours, vv.paid_hours, vv.net_hours, round(((vv.atd - vv.ata) * 24),2) berth_hours, 
		       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / vv.gross_hours),2) end as gross_production,
		       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / vv.paid_hours),2) end as mit_gross_production,
		       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / vv.net_hours),2) end as net_production,
		       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / round(((vv.atd - vv.ata) * 24),2)),2) end as berth_production,
		       case when v.category = 'RORO' then 0 else round(round((sum(vs.quantity) / vv.gross_hours),2) * vv.gangs, 2) end as vsl_moves_hour,
		       nvl(y.load_full_total,0) as load_full_total,
		nvl(y.load_Empty_total,0) as load_Empty_total,
		nvl(y.unload_full_total,0) as unload_full_total,
		nvl(y.unload_Empty_total,0) as unload_Empty_total,
		nvl(y.rehandle_empty_total,0) as rehandle_empty_total,
		nvl(y.rehandle_full_total,0) as rehandle_full_total,
		nvl(y.unload_chassis_total,0) as unload_chassis_total,
		nvl(y.load_chassis_total,0) as load_chassis_total,
		nvl(y.unload_cont_total,0) as unload_cont_total,
		nvl(y.load_cont_total,0) as load_cont_total,
		nvl(y.unload_reefer_full_total,0) as unload_reefer_full_total,
		nvl(y.load_reefer_full_total,0) as load_reefer_full_total
		from vessel_statistics vs, vessel_visits vv, vessels v, (select x.vv_vsl_id, x.vv_in_voy_nbr, x.vv_out_voy_nbr, 
		                                                                sum(x.load_full_total) as load_full_total,
		                                                                sum(x.load_Empty_total) as load_Empty_total,
		                                                                sum(x.unload_full_total) as unload_full_total,
		                                                                sum(x.unload_Empty_total) as unload_Empty_total,
		                                                                sum(x.rehandle_empty_total) as rehandle_empty_total,
		                                                                sum(x.rehandle_full_total) as rehandle_full_total,
		                                                                sum(x.unload_chassis_total) as unload_chassis_total,
		                                                                sum(x.load_chassis_total) as load_chassis_total,
		                                                                sum(x.unload_cont_total)as unload_cont_total,
		                                                                sum(x.load_cont_total) as load_cont_total,
		                                                                sum(x.unload_reefer_full_total) as unload_reefer_full_total,
		                                                                sum(x.load_reefer_full_total) as load_reefer_full_total
		                                                          from (select vv.vsl_id as vv_vsl_id, vv.in_voy_nbr as vv_in_voy_nbr, vv.out_voy_nbr as vv_out_voy_nbr,
		                                                                case
		                                                                when wtask_id ='LOAD' and status ='F' then sum(vs.quantity) 
		                                                                end as load_full_total,
		                                                                case
		                                                                when wtask_id ='LOAD' and status ='E' then sum(vs.quantity) 
		                                                                end as load_Empty_total,
		                                                                case
		                                                                when wtask_id ='UNLOAD' and status ='F' then sum(vs.quantity) 
		                                                                end as unload_full_total,
		                                                                case
		                                                                when wtask_id ='UNLOAD' and status ='E' then sum(vs.quantity) 
		                                                                end as unload_Empty_total,
		                                                                case
		                                                                when substr(wtask_id,1,2) ='RE' and status ='F' then sum(vs.quantity) 
		                                                                end as rehandle_full_total,
		                                                                case
		                                                                when substr(wtask_id,1,2) ='RE' and status ='E' then sum(vs.quantity) 
		                                                                end as rehandle_empty_total,
		                                                                case 
		                                                                when wtask_id ='UNLOAD' and substr(sztp_id,3,2) in ('CH','EX','FB') then sum(vs.quantity) 
		                                                                end as unload_chassis_total,
		                                                                case 
		                                                                when wtask_id ='LOAD' and substr(sztp_id,3,2) in ('CH','EX','FB') then sum(vs.quantity) 
		                                                                end as load_chassis_total,
		                                                                case 
		                                                                when wtask_id ='UNLOAD' and substr(sztp_id,3,2) not in ('CH','EX','FB','BL','RT') then sum(vs.quantity) 
		                                                              end as unload_cont_total,
		                                                              case 
		                                                              when wtask_id ='LOAD' and substr(sztp_id,3,2) not in ('CH','EX','FB','BL','RT') then sum(vs.quantity) 
		                                                              end as load_cont_total,
		                                                               --TOTAL REEFERS
		                                                                             case
		                                                                            when wtask_id ='UNLOAD' and substr(sztp_id,3,2) in ('RF','RH','RV','MU') and status ='F' then sum(vs.quantity) 
		                                                                            end as unload_reefer_full_total,
		                                                                            case
		                                                                             when wtask_id ='LOAD' and substr(sztp_id,3,2) in ('RF','RH','RV','MU') and status ='F' then sum(vs.quantity)  
		                                                                            end as load_reefer_full_total
		                                                              from vessel_statistics vs, vessel_visits vv
		                                                              --where atd between ? and ?
		                                                              WHERE --to_char(atd,'MM/YY') = to_char(sysdate,'MM/YY') and
																	  to_char(ata, 'YYYY') > '2009'
																	  and to_char(atd, 'YYYY') < '2040'
		                                                              and vs.vv_vsl_id(+) = vv.vsl_id
		                                                              and vs.vv_in_voy_nbr(+) = vv.in_voy_nbr
		                                                              and vs.vv_out_voy_nbr(+) = vv.out_voy_nbr
		                                                              group by vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vs.wtask_id, vs.status,  substr(sztp_id,3,2)) x
		                                                              group by x.vv_vsl_id, x.vv_in_voy_nbr, x.vv_out_voy_nbr) y
		where vs.vv_vsl_id(+) = vv.vsl_id
		and vs.vv_in_voy_nbr(+) = vv.in_voy_nbr
		and vs.vv_out_voy_nbr(+) = vv.out_voy_nbr
		and vv.vsl_id = v.id
		and vv.vsl_id = y.vv_vsl_id
		and vv.in_voy_nbr = y.vv_in_voy_nbr
		and vv.out_voy_nbr = y.vv_out_voy_nbr
		and vv.work_started is not null
		group by v.name, vv.vsl_id, vv.in_voy_nbr||'/'||vv.out_voy_nbr, vv.inbound_sailing_direction, vv.outbound_sailing_direction, vv.vsl_line_id, vv.out_srvc_id, v.category, vv.berth, vv.file_ref, vv.loaded, vv.discharged, 
		vv.gangs, vv.gross_hours, vv.paid_hours, vv.net_hours,  y.load_full_total, y.load_Empty_total, y.unload_full_total, y.unload_Empty_total, y.rehandle_empty_total, y.rehandle_full_total, 
		y.unload_chassis_total, y.load_chassis_total, y.unload_cont_total, y.load_cont_total, y.unload_reefer_full_total, y.load_reefer_full_total, vv.ata, vv.atd, vv.work_started
		--order by 2
	)
SELECT 
	EXTRACT (YEAR FROM eq.ATd) AS year
	, EXTRACT (MONTH FROM eq.atd) AS month
	, sum(eq.moves) AS moves
	, sum(eq.paid_hours) AS paid_hours
	, sum(eq.gross_hours) AS gross_hours
	, sum(eq.net_hours) AS net_hours
	, CASE WHEN sum(eq.paid_hours) = 0 THEN NULL ELSE sum(eq.moves) / sum(eq.paid_hours) END AS paid
	, CASE WHEN sum(eq.gross_hours) = 0 THEN NULL ELSE sum(eq.moves) / sum(eq.gross_hours) END AS gross 
	, CASE WHEN sum(eq.net_hours) = 0 THEN NULL ELSE sum(eq.moves) / sum(eq.net_hours) END AS net 	
FROM emir_query eq
WHERE EXTRACT (YEAR FROM eq.atd) = 2022 OR EXTRACT (YEAR FROM eq.atd) = 2023
GROUP BY 
	EXTRACT (YEAR FROM eq.atd)
	, EXTRACT (MONTH FROM eq.atd)
ORDER BY
	EXTRACT (YEAR FROM eq.atd)
	, EXTRACT (MONTH FROM eq.atd)
;

--Switching to ZLO again

--Vessel Statistics - Summary by vessel
SELECT
	vs.VV_VSL_ID 
	, sum(vs.QUANTITY )
	, vv.atd
FROM vessel_statistics vs
LEFT JOIN vessel_visits vv ON 
	vs.VV_VSL_ID = vv.VSL_ID AND 
	vs.VV_IN_VOY_NBR = vv.IN_VOY_NBR AND 
	vs.VV_OUT_VOY_NBR = vv.OUT_VOY_NBR 
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	EXTRACT (YEAR FROM vv.atd) = 2023)
GROUP BY 
	vs.VV_VSL_ID 
	, vv.atd
ORDER BY vv.ATD, vs.vv_VSL_ID 
;

SELECT * FROM vessel_statistics vstat;

--EH - Summarized by vessel
SELECT 
	vv.VSL_ID 
	, count(*) AS quantity
	, vv.atd
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.atd
ORDER BY vv.ATD, vv.VSL_ID 
;

--Vessel visits of interest
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ata
	, vv.atd
ORDER BY vv.ATD, vv.VSL_ID 
;

--VSD move counts
WITH 
	vessel_visits_of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID 
	)
SELECT 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, sum(vsc.total_moves) AS moves
FROM vessel_visits_of_interest vvoi
LEFT JOIN vessel_summary_detail vsd ON 
	vvoi.vsl_id = vsd.vsl_id AND 
	vvoi.in_voy_nbr = vsd.voy_in_nbr AND 
	vvoi.out_voy_nbr = vsd.voy_out_nbr
LEFT JOIN vessel_summary_cranes vsc ON
	vsd.gkey = vsc.vsd_gkey
GROUP BY 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.atd
ORDER BY 
	vvoi.atd
	, vvoi.vsl_id
;

--Delays from vessel_visits
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.PAID_HOURS 
	, vv.GROSS_HOURS 
	, vv.NET_HOURS 
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
	 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ata
	, vv.atd
	, vv.PAID_HOURS 
	, vv.GROSS_HOURS 
	, vv.NET_HOURS 
ORDER BY vv.ATD, vv.VSL_ID 
;

--Delays from vessel_summary_delays
WITH 
	vessel_visits_of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.atd
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID 
	)
SELECT 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
	, sum (
		CASE 
			WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS terminal_delays
	, sum (
		CASE 
			WHEN vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS total_delays
FROM vessel_visits_of_interest vvoi
LEFT JOIN vessel_summary_detail vsd ON
	vsd.vsl_id = vvoi.vsl_id AND 
	vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
	vsd.voy_out_nbr = vvoi.out_voy_nbr
LEFT JOIN vessel_summary_delays vsy ON
	vsy.vsd_gkey = vsd.gkey
LEFT JOIN delay_reasons dr ON
	dr.code = vsy.delay_code
GROUP BY 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.atd
ORDER BY 
	vvoi.atd
	, vvoi.vsl_id
;

--Raw times from EH
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, eh.CRANE_NO 
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
	)
SELECT 
	cwt.vsl_id
	, cwt.in_voy_nbr
	, cwt.out_voy_nbr
	, sum(cwt.crane_work_hours) AS work_hours
FROM crane_work_times cwt 
GROUP BY 
	cwt.vsl_id
	, cwt.in_voy_nbr
	, cwt.out_voy_nbr
	, cwt.atd
ORDER BY cwt.atd, cwt.vsl_id
;

--Productivities by vessel
--I will only compute three productivities. They will all use EH. Raw will use the work_hours computed from EH. Gross and Net will use
--gross_hours and net_hours from vessel_summary_delays.
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, eh.CRANE_NO 
			, count(eh.posted) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
	), vessel_visits_of_interest AS (
		SELECT 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
			, sum(cwt.moves) AS moves
			, sum(cwt.crane_work_hours) AS work_hours
		FROM crane_work_times cwt 
		GROUP BY 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
		--ORDER BY cwt.atd, cwt.vsl_id
	), vsd_moves_by_vessel_and_crane AS (
		SELECT 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vsc.crane_id
			, sum(vsc.total_moves) AS vsd_moves
			, vsd.gkey
			, vvoi.atd
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN vessel_summary_detail vsd ON
			vsd.vsl_id = vvoi.vsl_id AND 
			vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
			vsd.voy_out_nbr = vvoi.out_voy_nbr
		LEFT JOIN vessel_summary_cranes vsc ON 
			vsd.gkey = vsc.vsd_gkey
		GROUP BY 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.atd
			, vsd.gkey
			, vsc.crane_id
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
*/	), vsd_mvs_time_by_crane AS (
		SELECT 
			mbvc.vsl_id
			, mbvc.in_voy_nbr
			, mbvc.out_voy_nbr
			, mbvc.crane_id
			, mbvc.vsd_moves
			, sum(vscp.completed - vscp.commenced) * 24 AS vsd_work_days
			, mbvc.atd
		FROM vsd_moves_by_vessel_and_crane mbvc 
		LEFT JOIN vessel_summary_crane_prod vscp ON
			vscp.vsd_gkey = mbvc.gkey AND 
			vscp.crane_id = mbvc.crane_id
		GROUP BY 
			mbvc.vsl_id
			, mbvc.in_voy_nbr
			, mbvc.out_voy_nbr
			, mbvc.crane_id
			, mbvc.vsd_moves
			, mbvc.atd
/*		ORDER BY 
			mbvc.atd
			, mbvc.vsl_id
*/	), vsd_mvs_time_by_vessel AS (
		SELECT 
			mtbc.vsl_id
			, mtbc.in_voy_nbr
			, mtbc.out_voy_nbr
			, mtbc.atd
			, sum(mtbc.vsd_moves) AS vsd_moves
			, sum(mtbc.vsd_work_days) AS vsd_work_days
		FROM vsd_mvs_time_by_crane mtbc
		GROUP BY 
			mtbc.vsl_id
			, mtbc.in_voy_nbr
			, mtbc.out_voy_nbr
			, mtbc.atd
		ORDER BY 
			mtbc.atd
			, mtbc.vsl_id
	)
SELECT 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.moves AS eh_moves
	, vvoi.work_hours AS eh_work_days
	, mtbv.vsd_moves AS vsd_moves
	, mtbv.vsd_work_days AS vsd_work_days
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
	, sum (
		CASE 
			WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS terminal_delays
	, sum (
		CASE 
			WHEN vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS total_delays
FROM vessel_visits_of_interest vvoi
LEFT JOIN vessel_summary_detail vsd ON
	vsd.vsl_id = vvoi.vsl_id AND 
	vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
	vsd.voy_out_nbr = vvoi.out_voy_nbr
LEFT JOIN vessel_summary_delays vsy ON
	vsy.vsd_gkey = vsd.gkey
LEFT JOIN delay_reasons dr ON
	dr.code = vsy.delay_code
LEFT JOIN vsd_mvs_time_by_vessel mtbv ON
	vvoi.vsl_id = mtbv.vsl_id AND
	vvoi.in_voy_nbr = mtbv.in_voy_nbr AND
	vvoi.out_voy_nbr = mtbv.out_voy_nbr
GROUP BY 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.moves
	, vvoi.work_hours
	, mtbv.vsd_moves
	, mtbv.vsd_work_days
	, vvoi.atd
ORDER BY 
	vvoi.atd
	, vvoi.vsl_id
;

--Productivity components by month
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, eh.CRANE_NO 
			, count(eh.posted) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
	), vessel_visits_of_interest AS (
		SELECT 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
			, sum(cwt.moves) AS moves
			, sum(cwt.crane_work_hours) AS work_hours
		FROM crane_work_times cwt 
		GROUP BY 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
		--ORDER BY cwt.atd, cwt.vsl_id
	), vsd_moves_by_vessel_and_crane AS (
		SELECT 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vsc.crane_id
			, sum(vsc.total_moves) AS vsd_moves
			, vsd.gkey
			, vvoi.atd
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN vessel_summary_detail vsd ON
			vsd.vsl_id = vvoi.vsl_id AND 
			vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
			vsd.voy_out_nbr = vvoi.out_voy_nbr
		LEFT JOIN vessel_summary_cranes vsc ON 
			vsd.gkey = vsc.vsd_gkey
		GROUP BY 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.atd
			, vsd.gkey
			, vsc.crane_id
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
*/	), vsd_mvs_time_by_crane AS (
		SELECT 
			mbvc.vsl_id
			, mbvc.in_voy_nbr
			, mbvc.out_voy_nbr
			, mbvc.crane_id
			, mbvc.vsd_moves
			, sum(vscp.completed - vscp.commenced) * 24 AS vsd_work_days
			, mbvc.atd
		FROM vsd_moves_by_vessel_and_crane mbvc 
		LEFT JOIN vessel_summary_crane_prod vscp ON
			vscp.vsd_gkey = mbvc.gkey AND 
			vscp.crane_id = mbvc.crane_id
		GROUP BY 
			mbvc.vsl_id
			, mbvc.in_voy_nbr
			, mbvc.out_voy_nbr
			, mbvc.crane_id
			, mbvc.vsd_moves
			, mbvc.atd
/*		ORDER BY 
			mbvc.atd
			, mbvc.vsl_id
*/	), vsd_mvs_time_by_vessel AS (
		SELECT 
			mtbc.vsl_id
			, mtbc.in_voy_nbr
			, mtbc.out_voy_nbr
			, mtbc.atd
			, sum(mtbc.vsd_moves) AS vsd_moves
			, sum(mtbc.vsd_work_days) AS vsd_work_days
		FROM vsd_mvs_time_by_crane mtbc
		GROUP BY 
			mtbc.vsl_id
			, mtbc.in_voy_nbr
			, mtbc.out_voy_nbr
			, mtbc.atd
/*		ORDER BY 
			mtbc.atd
			, mtbc.vsl_id
*/	), components_by_vessel AS (
		SELECT 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.moves AS eh_moves
			, vvoi.work_hours AS eh_work_days
			, mtbv.vsd_moves AS vsd_moves
			, mtbv.vsd_work_days AS vsd_work_days
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
			, sum (
				CASE 
					WHEN vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS total_delays
			, vvoi.atd
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN vessel_summary_detail vsd ON
			vsd.vsl_id = vvoi.vsl_id AND 
			vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
			vsd.voy_out_nbr = vvoi.out_voy_nbr
		LEFT JOIN vessel_summary_delays vsy ON
			vsy.vsd_gkey = vsd.gkey
		LEFT JOIN delay_reasons dr ON
			dr.code = vsy.delay_code
		LEFT JOIN vsd_mvs_time_by_vessel mtbv ON
			vvoi.vsl_id = mtbv.vsl_id AND
			vvoi.in_voy_nbr = mtbv.in_voy_nbr AND
			vvoi.out_voy_nbr = mtbv.out_voy_nbr
		GROUP BY 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.moves
			, vvoi.work_hours
			, mtbv.vsd_moves
			, mtbv.vsd_work_days
			, vvoi.atd
		/*ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
*/	)
SELECT  
	EXTRACT (YEAR FROM cbv.atd) AS year
	, EXTRACT (MONTH FROM cbv.atd) AS MONTH
	, sum(cbv.eh_moves) AS eh_moves
	, sum(cbv.eh_work_days) AS eh_work_days
	, sum(cbv.vsd_moves) AS vsd_moves
	, sum(cbv.vsd_work_days) AS vsd_work_days
	, sum(cbv.shipping_delays) AS shipping_delays
	, sum(cbv.terminal_delays) AS terminal_delays
	, sum(cbv.total_delays) AS total_delays
FROM components_by_vessel cbv
GROUP BY 
	EXTRACT (YEAR FROM cbv.atd)
	, EXTRACT (MONTH FROM cbv.atd)
ORDER BY 
	EXTRACT (YEAR FROM cbv.atd)
	, EXTRACT (MONTH FROM cbv.atd)
;

-- Switching to PCT
/*
 * Switching contexts back to STS. My tasks for each terminal are to find a way that makes sense for listing the vessel visits
 * that matches what's reported. Then compile moves for those vessel visits that matches what's reported, hopefully that can
 * be done with the equipment_history (EH) table. Then find a source of delays is possible from vessel_visits or from
 * vessel_summary_detail (VSD) since that's where MIT and ZLO, respectively, found their delays. Ideally, the move counts from 
 * vessel_statistics or VSD also match what's reported. Then I just need to compute and compare.
*/

--Vessel visits of interest
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.ata
	, vv.atd
FROM VESSEL_VISITS vv
WHERE 
	(trunc(vv.atd) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) --2022-02-25 2023-12-29
ORDER BY vv.ATD, vv.VSL_ID 
;

SELECT 
	*
FROM EQUIPMENT_HISTORY eh 
WHERE 
	eh.VSL_ID = 'BALPEAC'
	AND (eh.voy_nbr = '2206E' OR eh.VOY_NBR = '2206W' OR eh.voy_nbr = '2206')
	AND 	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 		eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
;

--Move counts by vessel
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.ata
	, vv.atd
	, count(*) AS moves
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(trunc(vv.atd) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ata
	, vv.atd
ORDER BY vv.ATD, vv.VSL_ID 
;

--There are insufficient delays in the TOS from the vessel visits table for the period that I have good UAT data.
SELECT 
	* 
FROM vessel_visits vv 
WHERE 
	(vv.GROSS_HOURS IS NOT NULL OR 
	vv.NET_HOURS IS NOT NULL) AND 
	trunc(vv.atd) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')
ORDER BY vv.atd;

--And there are not delays in VSD. So, there are no delays in the TOS. It'll be raw productivity only.
SELECT * FROM vessel_summary_delays;

--Next is to see if vessel_statistics of vessel_summary_detail matches the reported move counts. VStats fails.
WITH 
	vessel_visits_of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
			, count(*) AS moves
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(trunc(vv.atd) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID
	)
SELECT 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, sum(vstats.QUANTITY) AS moves
FROM vessel_visits_of_interest vvoi
LEFT JOIN vessel_statistics vstats ON
	vstats.VV_VSL_ID = vvoi.vsl_id AND 
	vstats.VV_IN_VOY_NBR = vvoi.in_voy_nbr AND 
	vstats.VV_OUT_VOY_NBR = vvoi.out_voy_nbr
GROUP BY 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.atd
ORDER BY 
	vvoi.atd
	, vvoi.vsl_id
;

--VSD fails too. It has 0 records.
SELECT * FROM vessel_summary_detail;

--Looking for missing vessel visits.
--The CSCL South China Sea is missing because it has a null ATD.
--We should correct for that.
SELECT 
	* 
FROM vessel_visits vv
WHERE 
	vv.vsl_id = 'CSCLSOU' AND 
	vv.IN_VOY_NBR = '062E'
;

SELECT 
	* 
FROM vessels ves
WHERE 
	ves.name LIKE '%SOUTH CHINA SEA%'
;

--The Ball Peace is missing because its out_voy_nbr in vessel visits is incorrectly entered as '2206' instead of '2206W'.
--I don't think we should correct for that.
SELECT 
	* 
FROM vessel_visits vv
WHERE 
	vv.vsl_id = 'BALPEAC' 
	-- AND vv.IN_VOY_NBR = ''
;

SELECT 
	* 
FROM vessels ves
WHERE 
	ves.name LIKE '%PEACE%'
;

--Vessel visits of interest
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.ata
	, COALESCE (vv.atd, vv.ata) AS atd
FROM VESSEL_VISITS vv
WHERE 
	(trunc(COALESCE (vv.atd, vv.ata)) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) --2022-02-25 2023-12-29
ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID 
;

SELECT * FROM EQUIPMENT_HISTORY eh 
WHERE 
	eh.VSL_ID = 'BALPEAC' AND 
	eh.voy_nbr = '2206E'
;

--Move counts by vessel
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.ata
	, COALESCE (vv.atd, vv.ata) AS atd
	, count(*) AS moves
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
WHERE 
	(trunc(COALESCE (vv.atd, vv.ata)) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ata
	, vv.atd
	, eh.vsl_id
ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID 
;

--Next is to see if vessel_statistics of vessel_summary_detail matches the reported move counts. VStats fails.
WITH 
	vessel_visits_of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, COALESCE (vv.atd, vv.ata) AS atd
			, count(*) AS moves
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
		WHERE 
			(trunc(COALESCE (vv.atd, vv.ata)) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, COALESCE (vv.atd, vv.ata)
			, eh.vsl_id
		--ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID 
	)
SELECT 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, sum(vstats.QUANTITY) AS moves
FROM vessel_visits_of_interest vvoi
LEFT JOIN vessel_statistics vstats ON
	vstats.VV_VSL_ID = vvoi.vsl_id AND 
	vstats.VV_IN_VOY_NBR = vvoi.in_voy_nbr AND 
	vstats.VV_OUT_VOY_NBR = vvoi.out_voy_nbr
GROUP BY 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.atd
ORDER BY 
	vvoi.atd
	, vvoi.vsl_id
;

--Computing the raw crane work times
--I will only compute three productivities. They will all use EH. Raw will use the work_hours computed from EH. 
--Raw crane work times by vessel and crane
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, COALESCE (vv.atd, vv.ata) AS atd
	, eh.CRANE_NO 
	, count(*) AS moves
	, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
	, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
	, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
		GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
WHERE 
	(trunc(COALESCE (vv.atd, vv.ata)) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ATA
	, vv.atd
	, eh.CRANE_NO 
ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID, eh.CRANE_NO
;

--Raw crane work times by vessel
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, COALESCE (vv.atd, vv.ata) AS atd
	, count(*) AS moves
	, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
	, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
	, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
		GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
WHERE 
	(trunc(COALESCE (vv.atd, vv.ata)) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ATA
	, vv.atd, vv.ata
ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID
;

--Moves, raw crane work times, and raw productivities by vessel
/*
 * These crane worktimes are wrong. Summing the crane work times listed by vessel and crane
 * does not product the crane worktimes listed by vessel.
 */
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, COALESCE (vv.atd, vv.ata) AS atd
	, count(*) AS moves
	, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
	, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
	, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
		GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
	, CASE 
		WHEN greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 = 0
			THEN NULL 
		ELSE count(*) / greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
		GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) / 24
	  END AS raw_productivity
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
WHERE 
	(trunc(COALESCE (vv.atd, vv.ata)) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ATA
	, vv.atd, vv.ata
ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID
;

--Correcting the raw crane work times summarized by vessel
WITH 
	by_crane AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, COALESCE (vv.atd, vv.ata) AS atd
			, eh.CRANE_NO 
			, count(*) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
		WHERE 
			(trunc(COALESCE (vv.atd, vv.ata)) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.atd
			, eh.CRANE_NO 
		--ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID, eh.CRANE_NO
	)
SELECT 
	bc.VSL_ID 
	, bc.IN_VOY_NBR 
	, bc.OUT_VOY_NBR 
	, bc.atd
	, nvl(sum(moves),0) AS moves
	, sum(crane_work_hours) AS raw_hours
	, CASE 
		WHEN sum(crane_work_hours) = 0 THEN NULL
		ELSE nvl(sum(moves),0) / sum(crane_work_hours)
	  END AS raw_productivity
FROM by_crane bc
GROUP BY 
	bc.VSL_ID 
	, bc.IN_VOY_NBR 
	, bc.OUT_VOY_NBR 
	, bc.atd
ORDER BY 
	bc.atd
	, bc.vsl_id
;

--Moves, raw crane work times, and raw productivities by fiscal month
WITH 
	date_series AS (
		SELECT
			TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		FROM dual
		CONNECT BY TO_DATE('2018-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	), fiscal_calendar AS (
		SELECT
		  date_in_series,
		  CASE 
		    WHEN 
		    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
			THEN 1
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
		    THEN 2
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
			THEN 3    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
		    THEN 4    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
		    THEN 5
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
		    THEN 6
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
		    THEN 7
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
		    THEN 8
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
		    THEN 9
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
		    THEN 10
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
		    THEN 11
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		    THEN 12
		  END AS fiscal_month,
		  CASE 
		    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
		    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
		    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
		    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
		    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
		    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
		  END AS fiscal_year
		FROM date_series
	), by_crane AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, COALESCE (vv.atd, vv.ata) AS atd
			, eh.CRANE_NO 
			, count(*) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
		WHERE 
			(trunc(COALESCE (vv.atd, vv.ata)) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) AND --2022-02-25 2023-12-29
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.atd
			, eh.CRANE_NO 
		--ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID, eh.CRANE_NO
	), by_vessel AS (
		SELECT 
			bc.VSL_ID 
			, bc.IN_VOY_NBR 
			, bc.OUT_VOY_NBR 
			, bc.atd
			, nvl(sum(moves),0) AS moves
			, sum(crane_work_hours) AS raw_hours
			, CASE 
				WHEN sum(crane_work_hours) = 0 THEN NULL
				ELSE nvl(sum(moves),0) / sum(crane_work_hours)
			  END AS raw_productivity
		FROM by_crane bc
		GROUP BY 
			bc.VSL_ID 
			, bc.IN_VOY_NBR 
			, bc.OUT_VOY_NBR 
			, bc.atd
/*		ORDER BY 
			bc.atd
			, bc.vsl_id
*/	)
SELECT 
	fc.fiscal_year
	, fc.fiscal_month
	, sum(moves) AS moves
	, sum(raw_hours) AS raw_hours
	, CASE 
		WHEN sum(raw_hours) = 0 THEN NULL 
		ELSE sum(moves) / sum(raw_hours)
	  END AS raw_productivity
FROM by_vessel bv
JOIN fiscal_calendar fc ON 
	trunc(bv.atd) = fc.date_in_series
GROUP BY 
	fc.fiscal_year
	, fc.fiscal_month
ORDER BY 
	fc.fiscal_year
	, fc.fiscal_month
;

--Switching to T5
/*
 * Switching contexts back to STS. My tasks for each terminal are to find a way that makes sense for listing the vessel visits
 * that matches what's reported. Then compile moves for those vessel visits that matches what's reported, hopefully that can
 * be done with the equipment_history (EH) table. Then find a source of delays is possible from vessel_visits or from
 * vessel_summary_detail (VSD) since that's where MIT and ZLO, respectively, found their delays. Ideally, the move counts from 
 * vessel_statistics or VSD also match what's reported. Then I just need to compute and compare.
*/

--Vessel visits of interest
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.ata
	, vv.atd
FROM VESSEL_VISITS vv
WHERE 
	(trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD')) --2022-01-01 2023-01-27
ORDER BY vv.ATD, vv.VSL_ID 
;

--Looking for a specific vessel
SELECT 
	*
FROM EQUIPMENT_HISTORY eh 
WHERE 
	eh.VSL_ID = 'BALPEAC'
	AND (eh.voy_nbr = '2206E' OR eh.VOY_NBR = '2206W' OR eh.voy_nbr = '2206')
	AND 	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 		eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
;

--Move counts by vessel
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.ata
	, vv.atd
	, count(*) AS moves
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
WHERE 
	(trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD')) AND --2022-01-01 2023-01-27
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ata
	, vv.atd
ORDER BY vv.ATD, vv.VSL_ID 
;

--There are sufficient delays in the TOS from the vessel visits table for the period that I have good UAT data.
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ATA 
	, vv.ATD 
	, vv.PAID_HOURS 
	, vv.GROSS_HOURS 
	, vv.NET_HOURS 
FROM vessel_visits vv 
WHERE 
	trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') --2022-01-01 2023-01-27
ORDER BY vv.atd;

SELECT * FROM vessel_visits vv WHERE vv.vsl_id = 'NAVARIN' AND VV.IN_VOY_NBR = '244A';

--And there are not delays in VSD. So, there are no delays in the TOS. It'll be raw productivity only.
SELECT * FROM vessel_summary_delays;

--Next is to see if vessel_statistics of vessel_summary_detail matches the reported move counts. VStats succeeds.
WITH 
	vessel_visits_of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
			, count(*) AS moves
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') AND --2022-01-01 2023-01-27
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID
	)
SELECT 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, sum(vstats.QUANTITY) AS moves
FROM vessel_visits_of_interest vvoi
LEFT JOIN vessel_statistics vstats ON
	vstats.VV_VSL_ID = vvoi.vsl_id AND 
	vstats.VV_IN_VOY_NBR = vvoi.in_voy_nbr AND 
	vstats.VV_OUT_VOY_NBR = vvoi.out_voy_nbr
GROUP BY 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.atd
ORDER BY 
	vvoi.atd
	, vvoi.vsl_id
;

--VSD fails too. It has 0 records.
SELECT * FROM vessel_summary_detail;

--Looking for missing vessel visits.
--The CSCL South China Sea is missing because it has a null ATD.
--We should correct for that.
SELECT 
	* 
FROM vessel_visits vv
WHERE 
	vv.vsl_id = 'CSCLSOU' AND 
	vv.IN_VOY_NBR = '062E'
;

SELECT 
	* 
FROM vessels ves
WHERE 
	ves.name LIKE '%SOUTH CHINA SEA%'
;

--The Ball Peace is missing because its out_voy_nbr in vessel visits is incorrectly entered as '2206' instead of '2206W'.
--I don't think we should correct for that.
SELECT 
	* 
FROM vessel_visits vv
WHERE 
	vv.vsl_id = 'BALPEAC' 
	-- AND vv.IN_VOY_NBR = ''
;

SELECT 
	* 
FROM vessels ves
WHERE 
	ves.name LIKE '%PEACE%'
;

--Vessel visits of interest
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.ata
	, COALESCE (vv.atd, vv.ata) AS atd
FROM VESSEL_VISITS vv
WHERE 
	(trunc(COALESCE (vv.atd, vv.ata)) BETWEEN to_date('2022-02-25','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')) --2022-02-25 2023-12-29
ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID 
;

SELECT * FROM EQUIPMENT_HISTORY eh 
WHERE 
	eh.VSL_ID = 'BALPEAC' AND 
	eh.voy_nbr = '2206E'
;

--Move counts by vessel
SELECT 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR
	, vv.ata
	, COALESCE (vv.atd, vv.ata) AS atd
	, count(*) AS moves
FROM VESSEL_VISITS vv
LEFT JOIN equipment_history eh ON 
	eh.VSL_ID = vv.VSL_ID AND 
	(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
WHERE 
	trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') AND --2022-01-01 2023-01-27
	(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
	 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
	 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
GROUP BY 
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ata
	, vv.atd
	, eh.vsl_id
ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID 
;

--Computing the raw crane work times
--Correct raw crane work times summarized by vessel
WITH 
	by_crane AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, COALESCE (vv.atd, vv.ata) AS atd
			, eh.CRANE_NO 
			, count(*) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
		WHERE 
			trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') AND --2022-01-01 2023-01-27
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.atd
			, eh.CRANE_NO 
		--ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID, eh.CRANE_NO
	)
SELECT 
	bc.VSL_ID 
	, bc.IN_VOY_NBR 
	, bc.OUT_VOY_NBR 
	, bc.atd
	, nvl(sum(moves),0) AS moves
	, sum(crane_work_hours) AS raw_hours
	, CASE 
		WHEN sum(crane_work_hours) = 0 THEN NULL
		ELSE nvl(sum(moves),0) / sum(crane_work_hours)
	  END AS raw_productivity
FROM by_crane bc
GROUP BY 
	bc.VSL_ID 
	, bc.IN_VOY_NBR 
	, bc.OUT_VOY_NBR 
	, bc.atd
ORDER BY 
	bc.atd
	, bc.vsl_id
;

--VStats-VV moves by fiscal month
WITH 
	date_series AS (
		SELECT
			TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		FROM dual
		CONNECT BY TO_DATE('2018-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	), fiscal_calendar AS (
		SELECT
		  date_in_series,
		  CASE 
		    WHEN 
		    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
			THEN 1
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
		    THEN 2
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
			THEN 3    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
		    THEN 4    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
		    THEN 5
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
		    THEN 6
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
		    THEN 7
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
		    THEN 8
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
		    THEN 9
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
		    THEN 10
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
		    THEN 11
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		    THEN 12
		  END AS fiscal_month,
		  CASE 
		    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
		    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
		    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
		    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
		    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
		    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
		  END AS fiscal_year
		FROM date_series
	), vessel_visits_of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
			, count(*) AS moves
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') AND --2022-01-01 2023-01-27
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID
	), by_vessel AS (
		SELECT 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.atd
			, sum(vstats.QUANTITY) AS moves
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN vessel_statistics vstats ON
			vstats.VV_VSL_ID = vvoi.vsl_id AND 
			vstats.VV_IN_VOY_NBR = vvoi.in_voy_nbr AND 
			vstats.VV_OUT_VOY_NBR = vvoi.out_voy_nbr
		GROUP BY 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.atd
		/*ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
		*/
	)
SELECT
	fc.fiscal_year
	, fc.fiscal_month
	, sum(bv.moves) AS moves
FROM by_vessel bv
JOIN fiscal_calendar fc ON
	trunc(bv.atd) = fc.date_in_series
GROUP BY 
	fc.fiscal_year
	, fc.fiscal_month
ORDER BY 
	fc.fiscal_year
	, fc.fiscal_month
;

--VStats-VV hours by fiscal month
WITH 
	date_series AS (
		SELECT
			TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		FROM dual
		CONNECT BY TO_DATE('2018-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	), fiscal_calendar AS (
		SELECT
		  date_in_series,
		  CASE 
		    WHEN 
		    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
			THEN 1
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
		    THEN 2
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
			THEN 3    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
		    THEN 4    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
		    THEN 5
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
		    THEN 6
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
		    THEN 7
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
		    THEN 8
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
		    THEN 9
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
		    THEN 10
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
		    THEN 11
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		    THEN 12
		  END AS fiscal_month,
		  CASE 
		    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
		    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
		    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
		    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
		    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
		    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
		  END AS fiscal_year
		FROM date_series
	), vessel_visits_of_interest AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR
			, vv.ata
			, vv.atd
			, count(*) AS moves
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') AND --2022-01-01 2023-01-27
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ata
			, vv.atd
		--ORDER BY vv.ATD, vv.VSL_ID
	), by_vessel AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA 
			, vv.ATD 
			, vv.PAID_HOURS 
			, vv.GROSS_HOURS 
			, vv.NET_HOURS 
		FROM vessel_visits vv 
		WHERE 
			trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') --2022-01-01 2023-01-27
--		ORDER BY vv.atd
	)
SELECT
	fc.fiscal_year
	, fc.fiscal_month
	, sum(bv.paid_hours) AS paid_hours
	, sum(bv.gross_hours) AS gross_hours
	, sum(bv.net_hours) AS net_hours
FROM by_vessel bv
JOIN fiscal_calendar fc ON
	trunc(bv.atd) = fc.date_in_series
GROUP BY 
	fc.fiscal_year
	, fc.fiscal_month
ORDER BY 
	fc.fiscal_year
	, fc.fiscal_month
;


--Moves, raw crane work times, and raw productivities by fiscal month
WITH 
	date_series AS (
		SELECT
			TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		FROM dual
		CONNECT BY TO_DATE('2018-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	), fiscal_calendar AS (
		SELECT
		  date_in_series,
		  CASE 
		    WHEN 
		    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
			THEN 1
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
		    THEN 2
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
			THEN 3    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
		    THEN 4    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
		    THEN 5
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
		    THEN 6
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
		    THEN 7
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
		    THEN 8
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
		    THEN 9
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
		    THEN 10
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
		    THEN 11
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		    THEN 12
		  END AS fiscal_month,
		  CASE 
		    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
		    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
		    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
		    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
		    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
		    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
		  END AS fiscal_year
		FROM date_series
	), by_crane AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, COALESCE (vv.atd, vv.ata) AS atd
			, eh.CRANE_NO 
			, count(*) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
		WHERE 
			trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') AND --2022-01-01 2023-01-27
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.atd
			, eh.CRANE_NO 
		--ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID, eh.CRANE_NO
	), by_crane AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, COALESCE (vv.atd, vv.ata) AS atd
			, eh.CRANE_NO 
			, count(*) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR LIKE '%' || vv.IN_VOY_NBR || '%' OR eh.VOY_NBR LIKE '%' || vv.OUT_VOY_NBR || '%')
		WHERE 
			trunc(vv.atd) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') AND --2022-01-01 2023-01-27
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.atd
			, eh.CRANE_NO 
		--ORDER BY COALESCE (vv.atd, vv.ata), vv.VSL_ID, eh.CRANE_NO
	), by_vessel AS (
		SELECT 
			bc.VSL_ID 
			, bc.IN_VOY_NBR 
			, bc.OUT_VOY_NBR 
			, bc.atd
			, nvl(sum(moves),0) AS moves
			, sum(crane_work_hours) AS raw_hours
			, CASE 
				WHEN sum(crane_work_hours) = 0 THEN NULL
				ELSE nvl(sum(moves),0) / sum(crane_work_hours)
			  END AS raw_productivity
		FROM by_crane bc
		GROUP BY 
			bc.VSL_ID 
			, bc.IN_VOY_NBR 
			, bc.OUT_VOY_NBR 
			, bc.atd
/*		ORDER BY 
			bc.atd
			, bc.vsl_id
*/	)
SELECT
	fc.fiscal_year
	, fc.fiscal_month
	, sum(bv.moves) AS moves
	, sum(bv.raw_hours) AS raw_hours
FROM by_vessel bv
JOIN fiscal_calendar fc ON
	trunc(bv.atd) = fc.date_in_series
GROUP BY 
	fc.fiscal_year
	, fc.fiscal_month
ORDER BY 
	fc.fiscal_year
	, fc.fiscal_month
;