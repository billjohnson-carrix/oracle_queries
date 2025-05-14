SELECT count(*)
FROM mtms.equipment_uses
; --4,602,804 in UAT -- 5,749,124 IN PROD

SELECT *
FROM mtms.equipment_uses
FETCH FIRST 10 ROWS ONLY
;

SELECT count(DISTINCT gkey)
FROM mtms.equipment_uses
; --6,602,804 -- 5,756,247 IN PROD

SELECT count(DISTINCT gkey)
FROM mtms.equipment_uses_jn
; -- 2,892,935 IN PROD

SELECT count(*)
FROM mtms.equipment_uses_jn_arc
; -- 0

SELECT gkey
FROM mtms.equipment_uses
;

SELECT count(*)
FROM mtms.equipment_uses_jn
; -- 17,565,639 IN PROD

SELECT *
FROM mtms.equipment_uses_jn
FETCH FIRST 10 ROWS ONLY
;

SELECT *
FROM mtms.equipment_uses_jn
WHERE gkey in --(27071207, 27071206, 27071205, 27071204, 27071203, 27071202, 27071201, 27071200, 27071199)
	--(4030, 4211, 4676, 6270, 6588, 6968, 7489, 15294, 15473, 16218)
	(20000364, 20000895, 20000896, 20000897, 20000898, 20000899, 20000928, 20000954, 20001043, 20001281)
ORDER BY gkey
;

SELECT gkey FROM mtms.equipment_uses WHERE gkey > 20000000 ORDER BY gkey FETCH FIRST 10 ROWS ONLY;

/*
 * Checking to see if how many records are "stale," that is, past their expiration data but not purged.
 * Then I'm going to check and see how many of those have an outbound vessel visit that lacks an ATD.
 * */

SELECT *
FROM equipment_uses
ORDER BY gkey
FETCH FIRST 10 ROWS ONLY;

SELECT count(DISTINCT so_vsl_id || ' ' || so_voy_nbr)
FROM equipment_uses;

SELECT *
FROM vessel_visits
FETCH FIRST 10 ROWS ONLY;

SELECT count(DISTINCT vsl_id || ' ' || in_voy_nbr || ' ' || out_voy_nbr)
FROM vessel_visits;

SELECT DISTINCT
	uses.so_vsl_id
	, uses.so_voy_nbr
	, vv.vsl_id
	, vv.in_voy_nbr
	, vv.out_voy_nbr
FROM equipment_uses uses
LEFT JOIN vessel_visits vv ON
	uses.so_vsl_id = vv.vsl_id
	AND (
		uses.so_voy_nbr = vv.in_voy_nbr
		OR uses.so_voy_nbr = vv.out_voy_nbr
	)
;

SELECT * FROM vessel_visits;
SELECT count(*) FROM vessel_visits;
SELECT * FROM equipment_uses;
SELECT count(*) FROM equipment_uses;
SELECT systimestamp, uses.* FROM equipment_uses uses;

SELECT note FROM equipment_uses WHERE gkey = 8597722;

SELECT * FROM equipment_uses FETCH FIRST 10 ROWS ONLY;
SELECT * FROM equipment_uses_jn FETCH FIRST 10 ROWS ONLY;

SELECT *
FROM equipment_uses_jn
WHERE gkey = 25822809 --25368210
ORDER BY jn_entryid
;

SELECT systimestamp AS extraction_time, vv.* FROM vessel_visits vv;
SELECT count(*) FROM vessel_visits;

SELECT * FROM vessel_visits_jn;
SELECT count(*) FROM vessel_visits_jn;

-- Examining archiving process now
SELECT count(*) FROM equipment_uses_arc; -- 1,131,304 records
SELECT count(*) FROM equipment_uses_jn_arc; -- 0 records
SELECT * FROM equipment_uses_arc FETCH FIRST 10 ROWS ONLY;

SELECT * FROM equipment_uses_arc;

WITH overrides AS (
	SELECT 
		pts.parm_id PARAMETER
		, pts.Line_id
		, pts.option_id "OPTION"
	FROM parameter_task_settings pts
	WHERE 
		pts.parm_id like 'PURG%'
)
SELECT o.*
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

SELECT count(*) FROM equipment_uses;
SELECT sysdate FROM dual;