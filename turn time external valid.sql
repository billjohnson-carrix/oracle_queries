SELECT
	avg(tv.exited - tv.entered) * 24 * 60 AS avg_turn_time
	--tv.entered
	--, tv.exited
FROM truck_visits tv
WHERE
	tv.entered IS NOT NULL 
	AND tv.exited IS NOT NULL 
	AND EXTRACT (YEAR FROM tv.entered) = 2024
	AND EXTRACT (MONTH from tv.entered) = 1
	AND (tv.exited - tv.entered) * 24 * 60 >= 15
	AND (tv.exited - tv.entered) * 24 * 60 <= 120
;

SELECT
	avg(tv.exited - tv.entered) * 24 * 60 AS avg_turn_time
	--tv.entered
	--, tv.exited
FROM truck_visits tv
WHERE
	tv.entered IS NOT NULL 
	AND tv.exited IS NOT NULL 
	AND EXTRACT (YEAR FROM tv.entered) = 2024
	AND EXTRACT (MONTH from tv.entered) = 1
;

select 
    tv.gkey
    , tv.entered
    , tv.exited
    , (tv.exited - tv.entered) * 24 * 60 AS duration
from truck_visits tv
where
    tv.entered IS NOT NULL 
	AND tv.exited IS NOT NULL 
	AND extract(YEAR FROM tv.entered) = 2024
	AND extract(MONTH FROM tv.entered) = 1
order by
    4 DESC
;

select 
    sum (CASE WHEN (tv.exited - tv.entered) * 24 * 60 > 1000 THEN 1 ELSE 0 END ) AS very_long_count
    , count(*) AS count_all
from truck_visits tv
where
    tv.entered IS NOT NULL 
	AND tv.exited IS NOT NULL 
	AND extract(YEAR FROM tv.entered) = 2024
	AND extract(MONTH FROM tv.entered) = 1
;

SELECT * FROM truck_visits WHERE gkey = '9242496';
SELECT gt.ctr_nbr FROM gate_transactions gt where gt.tv_gkey = '9252517';

SELECT
	trunc(tv.entered) AS visit_DATE
	, tv.trk_id AS license
	, tv.entered AS in_time
	, tv.exited AS out_time
	, (tv.exited - tv.entered) * 24 * 60 AS duration
FROM truck_visits tv
WHERE 
	trunc(tv.entered) BETWEEN to_date('2024-03-16','YYYY-MM-DD') AND to_Date('2024-03-30','YYYY-MM-DD')
	AND tv.exited IS NOT NULL 
ORDER BY 
	tv.entered
;