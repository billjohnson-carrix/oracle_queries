SELECT * FROM terminal_events ORDER BY id;

WITH periods AS (
	SELECT 
		2022 + trunc((LEVEL - 1)/12) AS YEAR
		, mod(LEVEL - 1,12)+1 AS MONTH
	FROM dual
	CONNECT BY 
		LEVEL <= 24
),
eh_summary AS (
	SELECT 
		EXTRACT (YEAR FROM eh.posted) AS year
		, EXTRACT (MONTH FROM eh.posted) AS month
		, sum (CASE WHEN eh.wtask_id IN ('REHCC') AND eh.removed IS NULL THEN 1 ELSE 0 END) AS required_c2c
		, sum (CASE WHEN eh.wtask_id IN ('REHCCT') AND eh.removed IS NULL THEN 1 ELSE 0 END) AS convenience_c2c
		, sum (CASE WHEN eh.wtask_id IN ('REHCC','REHCCT') AND eh.removed IS NULL THEN 1 ELSE 0 END) AS total_c2c
		, sum (CASE WHEN eh.wtask_id IN ('REHCD','REHDC') AND eh.removed IS NULL THEN 1 ELSE 0 END) AS required_cdc
		, sum (CASE WHEN eh.wtask_id IN ('REHCDT','REHDCT') AND eh.removed IS NULL THEN 1 ELSE 0 END) AS convenience_cdc
		, sum (CASE WHEN eh.wtask_id IN ('REHCD','REHCDT','REHDC','REHDCT') AND eh.removed IS NULL THEN 1 ELSE 0 END) AS total_cdc
		, sum (CASE WHEN eh.wtask_id IN ('REHCC','REHCD','REHDC') AND eh.removed IS NULL THEN 1 ELSE 0 END) AS total_required
		, sum (CASE WHEN eh.wtask_id IN ('REHCCT','REHCDT','REHDCT') AND eh.removed IS NULL THEN 1 ELSE 0 END) AS total_convenience
		, sum (CASE WHEN eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT') AND eh.removed IS NULL THEN 1 ELSE 0 END) AS TOTAL	
	FROM equipment_history eh 
	WHERE 
		eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
		AND (	(EXTRACT (YEAR FROM eh.posted) = 2021 AND EXTRACT (MONTH FROM eh.posted) >= 3)
				OR EXTRACT (YEAR FROM eh.posted) = 2022
				OR (EXTRACT (YEAR FROM eh.posted) = 2023 AND EXTRACT (MONTH FROM eh.posted) <= 4))
	GROUP BY 
		EXTRACT (YEAR FROM eh.posted)
		, EXTRACT (MONTH FROM eh.posted)
	ORDER BY 
		EXTRACT (YEAR FROM eh.posted)
		, EXTRACT (MONTH FROM eh.posted)
)
SELECT 
	per.YEAR
	, per.MONTH
	, nvl(eh.required_c2c,0) AS required_c2c
	, nvl(eh.convenience_c2c,0) AS convenience_c2c 
	, nvl(eh.total_c2c,0) AS total_c2c
	, nvl(eh.required_cdc,0) AS required_cdc
	, nvl(eh.convenience_cdc,0) AS convenience_cdc
	, nvl(eh.total_cdc,0) AS total_cdc 
	, nvl(eh.total_required,0) AS total_required
	, nvl(eh.total_convenience,0) AS total_convenience
	, nvl(eh.total,0) AS total
FROM periods per
LEFT JOIN eh_summary eh ON 
	per.YEAR = eh.YEAR
	and per.MONTH = eh.month
ORDER BY 
	per.YEAR
	, per.month
;

SELECT 
	eh.eq_nbr
	, count(*)
FROM equipment_history eh
WHERE
	eh.wtask_id IN ('REHCD','REHDC')
	AND EXTRACT (YEAR FROM eh.posted) = 2022
	AND EXTRACT (MONTH FROM eh.posted) = 1
GROUP BY eh.eq_nbr
ORDER BY 2 DESC 
;

SELECT 
	count (DISTINCT eh.eq_nbr)
FROM equipment_history eh
WHERE
	eh.wtask_id IN ('REHCD','REHDC')
	AND EXTRACT (YEAR FROM eh.posted) = 2022
	AND EXTRACT (MONTH FROM eh.posted) = 1
;

SELECT
	EXTRACT (YEAR FROM eh.posted) AS YEAR
	, EXTRACT (MONTH FROM eh.posted) AS MONTH
	, count(*) AS moves
FROM equipment_history eh
WHERE
	eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
	AND (EXTRACT (YEAR FROM eh.posted) = 2022 OR EXTRACT (YEAR FROM eh.posted) = 2023)
GROUP BY
	EXTRACT (YEAR FROM eh.posted)
	, EXTRACT (MONTH FROM eh.posted)
ORDER BY 
	EXTRACT (YEAR FROM eh.posted)
	, EXTRACT (MONTH FROM eh.posted)
;