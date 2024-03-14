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