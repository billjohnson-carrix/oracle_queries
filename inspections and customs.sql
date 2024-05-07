SELECT 
	eqc.cstp_id
	, cst.message
	, count(*)
FROM equipment_constraints eqc
JOIN constraint_types cst ON cst.id = eqc.cstp_id
GROUP BY eqc.cstp_id, cst.message
ORDER BY 3 DESC
;

SELECT count(*) FROM equipment_constraints; --112777 purges after 90 days
SELECT count(*) FROM equipment_constraints_jn; --71880 purges after 365 days, apparently records ARE deleted
SELECT count(*) FROM equipment_constraints_arc; --70581
SELECT count(*) FROM equipment_constraints_jn_arc; --0
SELECT count(*) FROM equipment_constraint_history; --8218926

WITH 
	overrides AS (
		SELECT 
			pts.parm_id PARAMETER
			, pts.Line_id
			, pts.option_id "OPTION"
		FROM parameter_task_settings pts
		WHERE 
			pts.parm_id like 'PURG%'
	)
SELECT 
	o.*
FROM overrides o
UNION 
SELECT 
	id parameter, 
	'ALL' line_id, --DEFAULT OPTIONS apply TO ALL line_id
	default_option_id "OPTION"
FROM parameters p
WHERE
	p.id like 'PURG%'
	AND p.id not in (SELECT parameter FROM overrides)
;

SELECT * FROM equipment_constraint_history WHERE cnstr_gkey = '60737';

SELECT count(*) FROM equipment_constraints WHERE EXTRACT (YEAR FROM created) = '2023'; --5598

SELECT 
	eqc.* 
FROM equipment_constraints eqc 
WHERE EXTRACT (YEAR FROM created) = '2023'
ORDER BY eqc.created DESC 
;

SELECT
	*
FROM equipment_constraint_history ech
WHERE ech.cnstr_gkey = '5260394'
;