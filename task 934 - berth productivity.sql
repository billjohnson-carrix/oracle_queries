--Starting with MIT - computing moves per vessel
SELECT
	vv.vsl_id
	, vv.in_voy_nbr
	, vv.out_voy_nbr
	, COALESCE (vv.atd, vv.etd, vv.ata, vv.eta) AS dt
	, count(*) AS moves
	, min(eh.posted) AS start_time
	, max(eh.posted) AS finish_time
	, (max(eh.posted) - min(eh.posted)) * 24 AS work_hours
	, CASE 
		WHEN max(eh.posted) = min(eh.posted) THEN count(*) / 0.25 --defaulting to a quarter of an hour of work_time
		ELSE count(*) / (max(eh.posted) - min(eh.posted)) / 24  
	END AS berth_prod
FROM equipment_history eh
JOIN vessel_visits vv ON 
	eh.vsl_id = vv.vsl_id
	AND (eh.voy_nbr = vv.in_voy_nbr OR eh.voy_nbr = vv.out_voy_nbr)
WHERE 
	eh.wtask_id IN ('LOAD','UNLOAD')
	AND EXTRACT (YEAR FROM COALESCE (vv.atd, vv.etd, vv.ata, vv.eta)) IN ('2022','2023')
	AND vv.vsl_id = 'CLIBRA' 
	AND vv.in_voy_nbr = '06A'
	AND vv.out_voy_nbr = '06B'
GROUP BY 
	vv.vsl_id
	, vv.in_voy_nbr
	, vv.out_voy_nbr
	, vv.atd
	, vv.etd
	, vv.ata
	, vv.eta
ORDER BY 
	COALESCE (vv.atd, vv.etd, vv.ata, vv.eta)
;

SELECT * FROM vessel_visits WHERE vsl_id = 'CLIBRA' AND in_voy_nbr = '06A' AND out_voy_nbr = '06B';

--Stacy told me that berth productivity is the total move count including rehandles (C/D/C count as 2) divided by the work time excluding breaks.
--The work time is the time from first to last move for each shift and there's a half-hour of break time per shift.
--First to last move for a shift is the first move after 6 AM or 6 PM and the last move before the same.
WITH eh_records AS (
	SELECT
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.atd
		, vv.ata
		, COALESCE (vv.atd,vv.etd,vv.ata,vv.eta) AS dt
		, eh.wtask_id
		, eh.posted
	FROM vessel_visits vv
	LEFT JOIN equipment_history eh ON 
		eh.vsl_id = vv.vsl_id
		AND eh.voy_nbr IN (vv.in_voy_nbr,vv.out_voy_nbr)
	WHERE 
		EXTRACT (YEAR FROM COALESCE (vv.atd,vv.etd,vv.ata,vv.eta)) IN ('2022','2023')
		AND eh.wtask_id IN ('LOAD','UNLOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
/*	ORDER BY 
		4
		, eh.posted
*/), shift_end_points AS (
	SELECT 
		vsl_id
		, in_voy_nbr
		, out_voy_nbr
		, dt
		, ata
		, atd
		, min(posted) AS first_move
		, max(posted) AS last_move
		, count(*) AS moves
		, greatest (COALESCE(ata,min(posted)), min(posted)) AS start_time
		, to_number(to_char(greatest (COALESCE(ata,min(posted)), min(posted)), 'J')) + (greatest (COALESCE(ata,min(posted)), min(posted)) - trunc(greatest (COALESCE(ata,min(posted)), min(posted)))) AS Julian_start
		, trunc((to_number(to_char(greatest (COALESCE(ata,min(posted)), min(posted)), 'J')) + (greatest (COALESCE(ata,min(posted)), min(posted)) - trunc(greatest (COALESCE(ata,min(posted)), min(posted))))) * 2 + 0.5) / 2 - 0.25 AS Julian_first_shift_start
		, least (COALESCE(atd,max(posted)),max(posted)) AS finish_time
		, to_number(to_char(least (COALESCE(atd,max(posted)),max(posted)), 'J')) + least (COALESCE(atd,max(posted)),max(posted)) - trunc(least (COALESCE(atd,max(posted)),max(posted))) AS Julian_finish
		, trunc((to_number(to_char(least (COALESCE(atd,max(posted)),max(posted)), 'J')) + (least (COALESCE(atd,max(posted)),max(posted)) - trunc(least (COALESCE(atd,max(posted)),max(posted))))) * 2 + 0.5) / 2 + 0.25 AS Julian_final_shift_end
	FROM eh_records
	GROUP BY 
		vsl_id
		, in_voy_nbr
		, out_voy_nbr
		, dt
		, ata
		, atd
/*	ORDER BY 
		dt
		, vsl_id
		, in_voy_nbr
*/), shifts (vsl_id, in_voy_nbr, out_voy_nbr, dt, ata, atd, first_move, last_move, moves, start_time, Julian_start, Julian_first_shift_start, 
				finish_time, Julian_finish, Julian_final_shift_end, shift_start, shift_end) AS (
	SELECT sep.vsl_id, sep.in_voy_nbr, sep.out_voy_nbr, sep.dt, sep.ata, sep.atd, sep.first_move, sep.last_move, sep.moves, sep.start_time, sep.Julian_start, sep.Julian_first_shift_start, 
		sep.finish_time, sep.Julian_finish, sep.Julian_final_shift_end, 
		sep.Julian_first_shift_start AS shift_start, sep.Julian_first_shift_start + 0.5 AS shift_end 
	FROM shift_end_points sep
	UNION ALL 
	SELECT s.vsl_id, s.in_voy_nbr, s.out_voy_nbr, s.dt, s.ata, s.atd, s.first_move, s.last_move, s.moves, s.start_time, s.Julian_start, s.Julian_first_shift_start, 
		s.finish_time, s.Julian_finish, s.Julian_final_shift_end, 
		s.shift_start + 0.5 AS shift_start, s.shift_end + 0.5 AS shift_end 
	FROM shifts s
	WHERE s.shift_end + 0.5 <= s.Julian_final_shift_end
), shift_datetimes AS (
	SELECT 
		vsl_id, in_voy_nbr, out_voy_nbr, dt, ata, atd, first_move, last_move, moves, start_time, finish_time,
		to_date(trunc(shift_start),'J') + (shift_start - trunc(shift_start)) AS shift_start_datetime,
		to_date(trunc(shift_end),'J') + (shift_end - trunc(shift_end)) AS shift_end_datetime
	FROM shifts
--	ORDER BY dt, shift_start
), shift_movetimes AS (
	SELECT 
		sdt.vsl_id, sdt.in_voy_nbr, sdt.out_voy_nbr, sdt.dt, sdt.ata, sdt.atd, sdt.first_move, sdt.last_move, sdt.moves, sdt.start_time, sdt.finish_time, sdt.shift_start_datetime, sdt.shift_end_datetime,
		(	SELECT posted 
			FROM equipment_history eh 
			WHERE 
				eh.vsl_id = sdt.vsl_id 
				AND eh.voy_nbr IN (sdt.in_voy_nbr, sdt.out_voy_nbr) 
				AND eh.posted > sdt.shift_start_datetime
				AND eh.wtask_id IN ('UNLOAD','LOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
			ORDER BY eh.posted
			FETCH FIRST 1 ROW ONLY) AS first_shift_move,
		(	SELECT posted 
			FROM equipment_history eh 
			WHERE 
				eh.vsl_id = sdt.vsl_id 
				AND eh.voy_nbr IN (sdt.in_voy_nbr, sdt.out_voy_nbr) 
				AND eh.posted < sdt.shift_end_datetime
				AND eh.wtask_id IN ('UNLOAD','LOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
			ORDER BY eh.posted DESC 
			FETCH FIRST 1 ROW ONLY) AS last_shift_move
	FROM shift_datetimes sdt
), shift_timepoints AS (
	SELECT 
		vsl_id, in_voy_nbr, out_voy_nbr, dt, ata, atd, first_move, last_move, moves, start_time, finish_time,
		shift_start_datetime, shift_end_datetime, first_shift_move, last_shift_move,
		greatest (ata, first_shift_move) AS work_start,
		least (atd, last_shift_move) AS work_finish
	FROM shift_movetimes 
), shift_worktimes AS (
	SELECT
		vsl_id, in_voy_nbr, out_voy_nbr, dt, ata, atd, first_move, last_move, moves, start_time, finish_time,
		shift_start_datetime, shift_end_datetime, first_shift_move, last_shift_move, work_start, work_finish,
 		CASE
			WHEN work_finish - work_start < 15 / 60 / 24 THEN 0.25
			ELSE (work_finish - work_start) * 24
		END AS shift_gross_hours,
		CASE
			WHEN work_finish > work_start 
				AND ((to_number(to_char(work_finish,'HH24')) < 6 AND to_number(to_char(work_start,'HH24')) >= 18)
					OR (to_number(to_char(work_finish,'HH24')) >= 12 AND to_number(to_char(work_start,'HH24')) >= 6 AND to_number(to_char(work_start,'HH24')) < 12))
				AND NOT (work_finish - work_start < 1 / 24) THEN (work_finish - work_start) * 24 - 0.5
			WHEN work_finish - work_start < 15 / 60 / 24 THEN 0.25
			ELSE (work_finish - work_start) * 24
		END AS shift_net_hours
	FROM shift_timepoints
), agg_worktimes AS (
	SELECT 
		vsl_id
		, in_voy_nbr
		, out_voy_nbr
		, dt
		, start_time
		, finish_time
		, moves
		, count(*) AS shifts
		, sum(shift_gross_hours) AS gross_hours
		, sum(shift_net_hours) AS net_hours
		, moves / sum(shift_gross_hours) AS gross_productivity
		, moves / sum(shift_net_hours) AS net_productivity
	FROM shift_worktimes
	GROUP BY 
		vsl_id
		, in_voy_nbr
		, out_voy_nbr
		, dt
		, start_time
		, finish_time
		, moves
)
SELECT
	*
FROM agg_worktimes ORDER BY dt
;

/*
 * for later
 * 		, CASE
			WHEN shift_end_datetime - shift_start_datetime < 15 / 60 / 24 THEN 15 / 60 / 24
			ELSE shift_end_datetime - shift_start_datetime
		END AS shift_gross_time
		, CASE
			WHEN shift_end_datetime > shift_start_datetime 
				AND ((to_number(to_char(shift_end_datetime,'HH24')) < 6 AND to_number(to_char(shift_start_datetime,'HH24')) > 18)
					OR (to_number(to_char(shift_end_datetime,'HH24')) > 12 AND to_number(to_char(shift_start_datetime,'HH24')) > 6 AND to_number(to_char(shift_start_datetime,'HH24')) < 12))
				AND shift_end_datetime - shift_start_datetime < 1 / 24 THEN shift_end_datetime - shift_start_datetime - 0.5
		END AS shift_net_time

 */



--Looking at ZLO UAT 2
--paid, gross, and net hours are not populated as was discovered during STS productivity prototyping
SELECT
	*
FROM vessel_visits vv
WHERE
	vv.gross_hours IS NOT NULL 
	OR vv.net_hours IS NOT NULL 
	OR vv.paid_hours IS NOT NULL 
;

--I'm not sure this is correct because it adds up all the crane delays which might result in overcounting the delays for berth productivity
WITH fanned_out AS (
	SELECT 
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, COALESCE (vv.atd, vv.etd) AS dt
		, vsd.gkey
		, vsd.status
		, vsd.first_move
		, vsd.last_move
		, (vsd.last_move - vsd.first_move) * 24 AS work_hours
		, vsy.crane_id
		, vsy.delay_code
		, vsy.delay_time
		, to_number(to_char(vsy.delay_time, 'HH24')) AS delay_hour
		, to_number(to_char(vsy.delay_time, 'MI')) / 60 AS delay_minutes
		, to_number(to_char(vsy.delay_time, 'HH24')) + to_number(to_char(vsy.delay_time, 'MI')) / 60 AS delay_hours 
		, dr.delay_level
	FROM vessel_visits vv
	JOIN vessel_summary_detail vsd ON
		vsd.vsl_id = vv.vsl_id 
		AND vsd.voy_in_nbr = vv.in_voy_nbr
		AND vsd.voy_out_nbr = vv.out_voy_nbr
	JOIN vessel_summary_delays vsy ON 
		vsy.vsd_gkey = vsd.gkey
	JOIN delay_reasons dr ON 
		dr.code = vsy.delay_code
	WHERE 
		EXTRACT (YEAR FROM COALESCE (vv.atd, vv.etd)) IN ('2022','2023')
	ORDER BY 
		COALESCE (vv.atd, vv.etd)
)
SELECT 
	vsl_id
	, in_voy_nbr
	, out_voy_nbr
	, dt
	, gkey
	, status
	, first_move
	, last_move
	, (last_move - first_move) * 24 AS work_hours
	, sum (CASE
		WHEN delay_level = 'S' THEN delay_hours ELSE 0 
	END) AS delay_hours
	, (last_move - first_move) * 24 - sum (CASE WHEN delay_level = 'S' THEN delay_hours ELSE 0 END) AS gross_hours 
FROM fanned_out
GROUP BY 
	vsl_id
	, in_voy_nbr
	, out_voy_nbr
	, dt
	, gkey
	, status
	, first_move
	, last_move
ORDER BY 
	dt
;

SELECT * FROM vessel_summary_delays WHERE vsd_gkey = '104119';