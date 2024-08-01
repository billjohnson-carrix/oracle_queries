--Vessel visit list
WITH vessel_visits_of_interest AS (
	SELECT
		vv.vsl_id
		, v.category
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, COALESCE (vv.atd, vv.etd) AS dt
	FROM vessel_visits vv
	JOIN vessels v ON
		vv.vsl_id = v.id
	WHERE 
		COALESCE (vv.atd, vv.etd) > to_date('2023-08-01','YYYY-MM-DD')
		AND COALESCE (vv.atd, vv.etd) < sysdate
		AND (vv.atd IS NOT NULL OR (vv.atd IS NULL AND vv.berth IS NOT null))
		AND (v.category IS NULL OR NOT v.category = 'RORO')
	ORDER BY
		COALESCE (vv.atd, vv.etd)
), vessel_move_lists AS (
	SELECT
		vvoi.vsl_id
		, vvoi.category
		, vvoi.in_voy_nbr
		, vvoi.out_voy_nbr
		, vvoi.dt
		, eh.eq_nbr AS moves
		, eh.wtask_id AS task
		, eh.transship AS transship
		, eh.status
		, eh.line_id AS line
		, eh.temp_required
	FROM equipment_history eh
	JOIN vessel_visits_of_interest vvoi ON
		vvoi.vsl_id = eh.vsl_id
		AND (vvoi.in_voy_nbr = eh.voy_nbr OR vvoi.out_voy_nbr = eh.voy_nbr)
	WHERE 
		eh.wtask_id = 'LOAD' 
		OR eh.wtask_id = 'UNLOAD'
	ORDER BY 
		vvoi.dt
		, vvoi.vsl_id
		, eh.posted
), move_breakdown_by_vessel AS (
	SELECT
		vml.vsl_id
		, vml.category
		, vml.in_voy_nbr
		, vml.out_voy_nbr
		, vml.dt
		, count(vml.moves) AS total_moves
		, sum (CASE WHEN vml.task = 'UNLOAD' AND vml.transship IS NULL THEN 1 ELSE 0 end) AS imports
		, sum (CASE WHEN vml.task = 'LOAD' AND vml.transship IS NULL THEN 1 ELSE 0 end) AS exports
		, sum (CASE WHEN vml.transship IS NOT NULL THEN 1 ELSE 0 end) AS transships
		, sum (CASE WHEN vml.status = 'E' THEN 1 ELSE 0 end) AS empties
		, sum (CASE WHEN vml.status = 'F' THEN 1 ELSE 0 end) AS fulls
		, sum (CASE WHEN vml.temp_required IS NOT NULL THEN 1 ELSE 0 end) AS reefers
		, sum (CASE WHEN vml.temp_required IS NULL THEN 1 ELSE 0 end) AS not_live_reefers
	FROM vessel_move_lists vml
	GROUP BY 
		vml.vsl_id
		, vml.category
		, vml.in_voy_nbr
		, vml.out_voy_nbr
		, vml.dt
	ORDER BY 
		vml.dt
		, vml.vsl_id
), move_breakdown_for_period AS (
	SELECT
		EXTRACT (YEAR FROM dt) AS year
		, EXTRACT (MONTH FROM dt) AS MONTH
		, count (byv.vsl_id) AS total_calls
		, sum (byv.total_moves) AS total_moves
		, sum (byv.imports) AS imports
		, sum (byv.exports) AS exports
		, sum (byv.transships) AS transships
		, sum (byv.empties) AS empties
		, sum (byv.fulls) AS fulls
		, sum (byv.reefers) AS reefers
		, sum (byv.not_live_reefers) AS not_live_reefers
	FROM move_breakdown_by_vessel byv
	GROUP BY
		EXTRACT (YEAR FROM dt)
		, EXTRACT (MONTH FROM dt)
	ORDER BY
		EXTRACT (YEAR FROM dt)
		, EXTRACT (MONTH FROM dt)
), roro_contribution AS (
	SELECT
		EXTRACT (YEAR FROM byv.dt)
		, EXTRACT (MONTH FROM byv.dt)
		, byv.category
		, sum(total_moves) AS moves
	FROM move_breakdown_by_vessel byv
	GROUP BY 
		EXTRACT (YEAR FROM byv.dt)
		, EXTRACT (MONTH FROM byv.dt)
		, byv.category
	ORDER BY 
		EXTRACT (YEAR FROM byv.dt)
		, EXTRACT (MONTH FROM byv.dt)
), breakdown_by_vessel_and_line AS (
	SELECT
		vml.vsl_id
		, vml.category
		, vml.in_voy_nbr
		, vml.out_voy_nbr
		, vml.dt
		, vml.line 
		, count(vml.moves) AS total_moves
	FROM vessel_move_lists vml
	GROUP BY 
		vml.vsl_id
		, vml.category
		, vml.in_voy_nbr
		, vml.out_voy_nbr
		, vml.dt
		, vml.line 
	ORDER BY 
		vml.dt
		, vml.vsl_id
		, vml.line
), breakdown_by_line AS (
	SELECT 
		EXTRACT (YEAR FROM val.dt) AS YEAR
		, extract(MONTH FROM val.dt) AS MONTH
		, val.line AS line
		, sum(val.total_moves) AS total_moves
	FROM breakdown_by_vessel_and_line val
	GROUP BY 
		EXTRACT (YEAR FROM val.dt)
		, EXTRACT (MONTH FROM val.dt)
		, val.line
	ORDER BY 
		EXTRACT (YEAR FROM val.dt)
		, extract(MONTH FROM val.dt)
		, val.line
)
SELECT 
	*
FROM move_breakdown_for_period
--FROM breakdown_by_line
--FROM roro_contribution --COMMENT OUT the NO RORO clause
;

