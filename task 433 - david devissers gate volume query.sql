--David's query
SELECT
	'GATE'
	, count(*)
from (
	select *
	from equipment_history eh
	where 
		posted BETWEEN to_date('01/01/23 00:00:00', 'MM/DD/RR HH24:MI:SS') AND to_date('12/31/23 23:59:59', 'MM/DD/RR HH24:MI:SS')
		and removed is null
		and wtask_id in (
			select id
			from terminal_events
			where 
				event_group in ( 'GATE')
				and required is not null)
		and eq_class = 'CTR'
	union
	select 
		*
	from equipment_history_arc eh
	where 
		posted BETWEEN to_date('01/01/23 00:00:00', 'MM/DD/RR HH24:MI:SS') AND to_date('12/31/23 23:59:59', 'MM/DD/RR HH24:MI:SS')
		and removed is null
		and wtask_id in (
			select id
			from terminal_events
			where 
				event_group in ('GATE')
				and required is not null)
		and eq_class = 'CTR'
);

WITH 
	year_and_month AS (
		SELECT 
			2022 + trunc((LEVEL-1)/12) AS YEAR
			, mod(LEVEL-1,12)+1 AS MONTH
		FROM dual
		CONNECT BY LEVEL <= 24
	), records AS (
		select 
			*
		FROM year_and_month yam
		LEFT JOIN equipment_history eh ON 
			EXTRACT (YEAR FROM eh.posted) = yam.YEAR
			AND EXTRACT (MONTH FROM eh.posted) = yam.month
		where 
			removed is null
			and wtask_id in (
				select id
				from terminal_events
				where 
					event_group in ( 'GATE')
					and required is not null)
			and eq_class = 'CTR'
		union
		select 
			*
		FROM year_and_month yam
		LEFT JOIN equipment_history_arc eh ON 
			EXTRACT (YEAR FROM eh.posted) = yam.YEAR
			AND EXTRACT (MONTH FROM eh.posted) = yam.month
		where 
			removed is null
			and wtask_id in (
				select id
				from terminal_events
				where 
					event_group in ('GATE')
					and required is not null)
			and eq_class = 'CTR'
	)
SELECT 
	r.YEAR 
	, r.MONTH 
	, count(*)
FROM records r
GROUP BY 
	r.YEAR 
	, r.MONTH
ORDER BY 
	r.YEAR
	, r.MONTH 