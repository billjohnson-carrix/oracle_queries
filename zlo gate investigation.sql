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