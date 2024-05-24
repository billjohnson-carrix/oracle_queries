SELECT
	sum (CASE WHEN eh.vsl_id IS NULL THEN 1 ELSE 0 END) AS NULL_values
	, sum (CASE WHEN eh.vsl_id IS NOT NULL THEN 1 ELSE 0 END) AS non_NULL_values
FROM equipment_history eh
WHERE 
	EXTRACT (YEAR FROM eh.posted) = 2023
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
;

SELECT
	EXTRACT (MONTH FROM eh.posted) AS month
	, sum (CASE WHEN eh.vsl_id IS NULL THEN 1 ELSE 0 END) AS eh_null_ids
	, sum (CASE WHEN eh.vsl_id IS NOT NULL THEN 1 ELSE 0 END) AS eh_non_null_ids
	, sum (CASE WHEN vv.vsl_id IS NULL THEN 1 ELSE 0 END) AS vv_null_ids
	, sum (CASE WHEN vv.vsl_id IS NOT NULL THEN 1 ELSE 0 END) AS vv_non_null_ids
	, sum (CASE WHEN v.id IS NULL THEN 1 ELSE 0 END) AS ves_null_ids
	, sum (CASE WHEN v.id IS NOT NULL THEN 1 ELSE 0 END) AS ves_non_null_ids
FROM equipment_history eh
LEFT JOIN vessel_visits vv ON 
	vv.vsl_id = eh.vsl_id
	AND (vv.in_voy_nbr = eh.voy_nbr OR vv.out_voy_nbr = eh.voy_nbr)
LEFT JOIN vessels v ON
	eh.vsl_id = v.id
WHERE 
	EXTRACT (YEAR FROM eh.posted) = 2022
	AND EXTRACT (MONTH FROM eh.posted) >= 2
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
GROUP BY EXTRACT (MONTH FROM eh.posted)
ORDER BY EXTRACT (MONTH FROM eh.posted)
;

SELECT 
	*
FROM vessel_visits vv
WHERE vv.vsl_id = 'MSCVIRG' AND (vv.in_voy_nbr = '233R' OR vv.out_voy_nbr = '233R')
;

