SELECT
	'GATE'
	, count(*)
from (
	select *
	from equipment_history eh
	where 
		eh.posted BETWEEN to_date('02/01/23 00:00:00', 'MM/DD/RR HH24:MI:SS') AND to_date('02/28/23 23:59:59', 'MM/DD/RR HH24:MI:SS')
		and eh.removed is null
		and eh.wtask_id in (
			select te.id
			from terminal_events te
			where 
				te.event_group in ( 'GATE')
				and te.required is not null)
		and eh.eq_class = 'CTR'
);

WITH gate_events AS (
	select te.id
	from terminal_events te
	where 
		te.event_group in ( 'GATE')
		and te.required is not null	
), gate_records AS (
	select *
	from equipment_history eh
	where 
		(eh.posted BETWEEN to_date('02/01/23 00:00:00', 'MM/DD/RR HH24:MI:SS') AND to_date('02/28/23 23:59:59', 'MM/DD/RR HH24:MI:SS')
			OR eh.posted BETWEEN to_date('05/01/23 00:00:00', 'MM/DD/RR HH24:MI:SS') AND to_date('05/31/23 23:59:59', 'MM/DD/RR HH24:MI:SS')
			OR eh.posted BETWEEN to_date('08/01/23 00:00:00', 'MM/DD/RR HH24:MI:SS') AND to_date('08/31/23 23:59:59', 'MM/DD/RR HH24:MI:SS'))
		and eh.removed is null
		and eh.wtask_id in (SELECT id FROM gate_events)
		and eh.eq_class = 'CTR'
)
SELECT EXTRACT (MONTH FROM posted) AS month, count(*) FROM gate_records GROUP BY EXTRACT (MONTH FROM posted);

--Switching to SMITCO
WITH gate_events AS (
	select te.id
	from terminal_events te
	where 
		te.event_group in ( 'GATE')
		and te.required is not null	
), gate_records AS (
	select *
	from equipment_history eh
	where 
		EXTRACT (YEAR FROM eh.posted) = 2023
		and eh.removed is null
		and eh.wtask_id in (SELECT id FROM gate_events)
		and eh.eq_class = 'CTR'
)
SELECT 
	EXTRACT (MONTH FROM posted) AS MONTH
	, count(*) 
FROM gate_records 
GROUP BY EXTRACT (MONTH FROM posted) 
ORDER BY EXTRACT (MONTH FROM posted);

--Query for Galen's spreadsheet
WITH gate_events AS (
	select te.id
	from terminal_events te
	where 
		te.event_group in ( 'GATE')
		and te.required is not null	
), gate_records AS (
	select 
		eh.posted
		, eh.eq_nbr
		, eh.sztp_id
		, est.eqsz_id / 20 AS LENGTH_teu
		, round (est.eqsz_id / 20) AS int_teu
	from equipment_history eh
	JOIN equipment_size_types est ON
		eh.sztp_id = est.id
	where 
		(EXTRACT (YEAR FROM eh.posted) = 2023
		 OR EXTRACT (YEAR FROM eh.posted) = 2024)
		and eh.removed is null
		and eh.wtask_id in (SELECT id FROM gate_events)
		and eh.eq_class = 'CTR'
)
SELECT 
	to_char(trunc(gr.posted, 'MM'),'MM/DD/YYYY') AS analysis_month
	, 'OICT' AS terminal_key
	, count(*) AS gate_volume_total_moves
	, sum (gr.length_teu) AS gate_volume_total_teu_precise
	, sum (gr.int_teu) AS gate_volumne_total_teu_whole
	, 'Oracle' AS Platform
FROM gate_records gr
GROUP BY trunc(gr.posted, 'MM') 
ORDER BY trunc(gr.posted, 'MM')
;

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
