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

SELECT * FROM vessel_visits WHERE berth = '6';

SELECT 
	EXTRACT (YEAR FROM vv.etd) AS year
	, EXTRACT (MONTH FROM vv.etd) AS month
	, count(*) AS calls
FROM vessel_visits vv
GROUP BY
	EXTRACT (YEAR FROM vv.etd)
	, EXTRACT (MONTH FROM vv.etd)
ORDER BY 
	EXTRACT (YEAR FROM vv.etd)
	, EXTRACT (MONTH FROM vv.etd)
;

--Checking net throughput at PROD at the terminals
select 
	EXTRACT (YEAR FROM eh.posted) AS year
	, EXTRACT (MONTH FROM eh.posted) AS month
    , count(*) as moves
from equipment_history eh 
where  
    eh.wtask_id IN ('LOAD','UNLOAD')
    and EXTRACT (YEAR FROM eh.posted) in ('2022','2023')
group by 
	EXTRACT (YEAR FROM eh.posted)
	, EXTRACT (MONTH FROM eh.posted)
order by 
	year
	, month
;

--Union with the archive table
select 
    year,
    month,
    sum(moves) as moves
from (
    select 
        EXTRACT (YEAR FROM eh.posted) AS year,
        EXTRACT (MONTH FROM eh.posted) AS month,
        count(*) as moves
    from equipment_history eh 
    where  
        eh.wtask_id IN ('LOAD','UNLOAD')
        and EXTRACT (YEAR FROM eh.posted) in (2022, 2023)
    group by 
        EXTRACT (YEAR FROM eh.posted),
        EXTRACT (MONTH FROM eh.posted)
    UNION ALL 
    select 
        EXTRACT (YEAR FROM eha.posted) AS year,
        EXTRACT (MONTH FROM eha.posted) AS month,
        count(*) as moves
    from equipment_history_arc eha 
    where  
        eha.wtask_id IN ('LOAD','UNLOAD')
        and EXTRACT (YEAR FROM eha.posted) in (2022, 2023)
    group by 
        EXTRACT (YEAR FROM eha.posted),
        EXTRACT (MONTH FROM eha.posted)
)
group by 
    year,
    month
order by 
    year,
    month;
   
--Query for Galen's spreadsheet
SELECT
	to_char(trunc(eh.posted, 'MM'),'MM/DD/YYYY') AS analysis_month
	, 'ZLO' AS terminal_key
	, count(*) AS ntt_total_moves
	, sum (CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS ntt_total_imports
	, sum (CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 END) AS ntt_total_exports
	, sum (CASE WHEN eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS ntt_total_transships
	, sum (CASE WHEN to_number(substr(eh.sztp_id,1,2)) < 30 THEN 1 ELSE 2 END) AS ntt_total_teu_whole
	, sum (to_number(substr(eh.sztp_id,1,2)) / 20) AS ntt_total_teu_precise
	, sum (CASE WHEN eh.status = 'E' THEN 1 ELSE 0 END) AS ntt_total_empty_moves
	, sum (CASE WHEN eh.status = 'E' AND eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 END) AS ntt_total_empty_imports
	, sum (CASE WHEN eh.status = 'E' AND eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 END) AS ntt_total_empty_exports
	, sum (CASE WHEN eh.status = 'E' AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS nt_total_empty_trasnships
	, sum (CASE WHEN eh.status = 'F' THEN 1 ELSE 0 END) AS ntt_total_full_moves
	, sum (CASE WHEN eh.status = 'F' AND eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 END) AS ntt_total_full_imports
	, sum (CASE WHEN eh.status = 'F' AND eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 END) AS ntt_total_full_exports
	, sum (CASE WHEN eh.status = 'F' AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS ntt_total_full_transships
	, sum (CASE WHEN eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS ntt_total_reefers
	, 'Oracle' AS Platform
FROM equipment_history eh
WHERE 
	(EXTRACT (YEAR FROM eh.posted) = 2023
	 OR EXTRACT (YEAR FROM eh.posted) = 2024)
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
GROUP BY trunc(eh.posted, 'MM')
ORDER BY trunc(eh.posted, 'MM')
;
