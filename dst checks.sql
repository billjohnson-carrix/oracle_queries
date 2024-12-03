SELECT *
FROM equipment_history
WHERE
	trunc(posted) = to_date('2024-11-03', 'YYYY-MM-DD')
	AND to_char(posted, 'HH24') = '01'
FETCH FIRST 200 ROWS ONLY
;

SELECT count(*)
FROM equipment_jn
WHERE
	trunc(jn_datetime) = to_date('2024-11-03', 'YYYY-MM-DD')
	AND to_char(jn_datetime, 'HH24') = '01'
FETCH FIRST 20 ROWS ONLY
;

SELECT count(*)
FROM equipment_uses_jn
WHERE
	trunc(jn_datetime) = to_date('2024-11-03', 'YYYY-MM-DD')
	AND to_char(jn_datetime, 'HH24') = '01'
FETCH FIRST 20 ROWS ONLY
;

SELECT count(*)
FROM vessel_visits_jn
WHERE
	trunc(jn_datetime) = to_date('2024-11-03', 'YYYY-MM-DD')
	AND to_char(jn_datetime, 'HH24') = '01'
FETCH FIRST 20 ROWS ONLY
;