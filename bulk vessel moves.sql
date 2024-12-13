/* many moves at the same time
  all have null crane_numbers */
/*select
    posted_at
    , count(*)
from silver.mainsail.silver_equipment_events
where terminal_key = 'T30'
    and vessel_id = 'COSPIRA'
    and posted_at between '2024-10-25' and '2024-10-27'
group by 1
order by 1
;*/

SELECT posted, count(*) AS cnt
FROM equipment_history
WHERE vsl_id = 'COSPIRA'
	AND posted BETWEEN to_timestamp('2024-10-25 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
		AND to_timestamp('2024-10-27 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
GROUP BY posted
ORDER BY posted
;

SELECT *
FROM equipment_history
WHERE vsl_id = 'COSPIRA'
	AND posted BETWEEN to_timestamp('2024-10-25 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
		AND to_timestamp('2024-10-27 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
ORDER BY posted
;

SELECT *
FROM equipment_history
WHERE crane_no IN ('RO1', 'RO2', 'RORO')
;