SELECT
	trunc(jn_datetime) AS day
	, count(*) AS count
FROM vessel_visits_jn
WHERE jn_operation = 'DEL'
	AND trunc(jn_datetime) BETWEEN to_date('2024-01-01','YYYY-MM-DD') AND to_date('2024-06-30','YYYY-MM-DD')
GROUP BY trunc(jn_datetime)
ORDER BY trunc(jn_datetime) desc
;

SELECT
	*
FROM vessel_visits_jn
WHERE jn_operation = 'DEL'
	AND trunc(jn_datetime) BETWEEN to_date('2024-01-01','YYYY-MM-DD') AND to_date('2024-06-30','YYYY-MM-DD')
ORDER BY trunc(jn_datetime) desc
;

SELECT
	trunc(created) AS day
	, count(*) AS count
FROM equipment_history
WHERE
	trunc(created) BETWEEN to_date('2024-01-01','YYYY-MM-DD') AND to_date('2024-06-30','YYYY-MM-DD')
GROUP BY trunc(created)
ORDER BY trunc(created) desc
;

SELECT
	*
FROM equipment_history
WHERE
	trunc(created) = to_date('2024-06-26','YYYY-MM-DD')
ORDER BY gkey desc
;