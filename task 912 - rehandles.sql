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
	wtask_id
	, count(*)
FROM equipment_History eh
WHERE 
	eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
	AND eh.vsl_id = 'POLMEX' AND (eh.voy_nbr = '301S' OR eh.voy_nbr = '301N')
GROUP BY eh.wtask_id
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

--Odd numbers shouldn't be possible. I want to just group by the wtask_id and see what's going on.
SELECT 
	EXTRACT (YEAR FROM eh.posted) AS YEAR
	, EXTRACT (MONTH FROM eh.posted) AS MONTH 
	, eh.wtask_id
	, count(*)
FROM equipment_history eh
WHERE
	eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
	AND (EXTRACT (YEAR FROM eh.posted) = 2022 OR EXTRACT (YEAR FROM eh.posted) = 2023)
GROUP BY 
	EXTRACT (YEAR FROM eh.posted)
	, EXTRACT (MONTH FROM eh.posted) 
	, eh.wtask_id
ORDER BY 
	EXTRACT (YEAR FROM eh.posted)
	, EXTRACT (MONTH FROM eh.posted) 
	, eh.wtask_id
;

--There are unequal counts of cell-dock and dock-cell moves in every month. 
--They're rare enought that I doubt there can be that many that span midnight on the first or last day of the month.
SELECT
	eh.eq_nbr
	, eh.wtask_id
	, eh.posted
	, eh.*
FROM equipment_history eh
WHERE
	eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
	AND EXTRACT (YEAR FROM eh.posted) = 2022
	AND EXTRACT (MONTH FROM eh.posted) = 1
ORDER BY 
	eh.eq_nbr
	, eh.posted
;

--There some data cleaning that needs to occur here.
--For some reason, it's pretty common to have both portions of a move posted at the same time and then another pair are posted with differing times.
--Also there are some singles. Some just had a bad container numbers.
--I'm going to take an extra month at the start and the end then insiste that every rehandle in 2022 and 2023 be paired and occur at different times and see what we get.
--The rehandles with both moves posted at the same time may be real so this may not give good results.
WITH paired_cdcs_with_garbage AS (
	SELECT
		eh.eq_nbr
		, eh.wtask_id
		, eh.posted
		, CASE WHEN eh.wtask_id IN ('REHCD','REHCDT') THEN eh.wtask_id ELSE NULL END AS reh_start
		, CASE WHEN eh.wtask_id IN ('REHCD','REHCDT') THEN eh.posted ELSE NULL END AS reh_start_time
		, CASE WHEN eh.wtask_id IN ('REHCD','REHCDT') THEN 
			lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) ELSE NULL END AS reh_end
		, CASE WHEN eh.wtask_id IN ('REHCD','REHCDT') THEN 
			lead (eh.posted) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) ELSE NULL END AS reh_end_time
	FROM equipment_history eh
	WHERE 
		eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
		AND trunc(eh.posted) BETWEEN to_date('2021-12-01','YYYY-MM-DD') AND to_date('2024-01-31','YYYY-MM-DD')
	ORDER BY 
		eh.eq_nbr
		, eh.posted
), paired_cdcs AS (
	SELECT
		*
	FROM paired_cdcs_with_garbage p
	WHERE
		p.reh_start IS NOT NULL 
)
SELECT 
	reh_start
	, reh_end
	, count(*)
FROM paired_cdcs pc
GROUP BY 
	reh_start
	, reh_end
;

--More data cleaning exploration
SELECT 
	eh.eq_nbr
	, count(*)
FROM equipment_history eh
WHERE 
	eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
	AND trunc(eh.posted) BETWEEN to_date('2021-12-01','YYYY-MM-DD') AND to_date('2024-01-31','YYYY-MM-DD')
GROUP BY 
	eh.eq_nbr
ORDER BY 2 DESC
;

SELECT 
	eh.eq_nbr
	, eh.wtask_id
	, eh.posted
	, eh.*
FROM equipment_history eh
WHERE 
	eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
	AND trunc(eh.posted) BETWEEN to_date('2021-12-01','YYYY-MM-DD') AND to_date('2024-01-31','YYYY-MM-DD')
	AND eh.eq_nbr = 'MSKU9373612'
ORDER BY eh.posted
;

/*
 * New strategy for data cleaning. 
 * 		Partition by eq_nbr and order by posted and wtask_id. 
 * 		1) Any wtask_id that is CC is selected. 
 * 		2) A CD wtask_id that is followed by a CC is not selected.
 * 		3) A CD wtask_id that is followed by a CD wtask_id. The record with the earlier posted is selected. This requires a check afterard for sequential CDs in case there were 3 in a row
 * 		4) A CD wtask_id followed by a matching DC wtask_id is selected.
 * 		5) A CD wtask_id followed by a mismatched DC is selected. This requires a check afterward to see how common it is.
 * 		6) A DC wtask_id preceded by a CC is not selected.
 * 		7) A DC wtask_ID preceded by a matching CD is selected.
 * 		8) A DC wtask_id preceded by a mismatched CD is selected. This requires a check afterward to see how common it is.
 * 		9) A DC wtask_id preceded by a DC. The record with the later posted is selected. This requires a check afterard for sequential CDs in case there were 3 in a row.
 * 		10) Any parition that ends with a CD or or starts with a DC has that record dropped
 */
SELECT
	CASE 
		WHEN eh.wtask_id IN ('REHCC','REHCCT') THEN 'keep' -- 1)
		WHEN eh.wtask_id IN ('REHCD','REHCDT') 
			AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHCC','REHCCT')
				THEN 'drop' -- 2)
		WHEN eh.wtask_id IN ('REHDC','REHDCT')
			AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHCC','REHCCT')
				THEN 'drop' -- 6)
		WHEN eh.wtask_id IN ('REHCD','REHCDT')
			AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHCD','REHCDT')
				THEN 'keep'  -- 3a)
		WHEN eh.wtask_id IN ('REHCD','REHCDT')
			AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHCD','REHCDT')
				THEN 'drop' -- 3b)
		WHEN eh.wtask_id in ('REHCD','REHCDT')
			AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHDC','REHDCT')
				THEN 'keep'  -- 4a) 5a) 7a) 8a)
		WHEN eh.wtask_id IN ('REHDC','REHDCT')
			AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHCD','REHCDT')
				THEN 'keep' -- 4b) 5b) 7b) 8b)
		WHEN eh.wtask_id IN ('REHDC','REHDCT')
			AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHDC','REHDCT')
				THEN 'keep' -- 9a)
		WHEN eh.wtask_id IN ('REHDC','REHDCT')
			AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHDC','REHDCT')
				THEN 'drop' -- 9b)
		WHEN (eh.wtask_id IN ('REHCD','REHCDT') 
				AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IS NULL)
			OR (eh.wtask_id IN ('REHDC','REHDCT')
				AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IS NULL) 
					THEN 'drop' -- 10)
	END AS selector
	, CASE 
		WHEN eh.wtask_id IN ('REHCC','REHCCT') THEN '1'
		WHEN eh.wtask_id IN ('REHCD','REHCDT') 
			AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHCC','REHCCT')
				THEN '2'
		WHEN eh.wtask_id IN ('REHDC','REHDCT')
			AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHCC','REHCCT')
				THEN '6'
		WHEN eh.wtask_id IN ('REHCD','REHCDT')
			AND (lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHCD','REHCDT')
					OR lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHCD','REHCDT'))
				THEN '3'
		WHEN (eh.wtask_id = 'REHCD' AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) = 'REHDC')
				OR (eh.wtask_id = 'REHCDT' AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) = 'REHDCT')
					THEN '4'
		WHEN (eh.wtask_id = 'REHDC' AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) = 'REHCD')
				OR (eh.wtask_id = 'REHDCT' AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) = 'REHCDT')
					THEN '7'
		WHEN (eh.wtask_id = 'REHCD' AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) = 'REHDCT')
				OR (eh.wtask_id = 'REHCDT' AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) = 'REHDC')
					THEN '5'
		WHEN (eh.wtask_id = 'REHDC' AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) = 'REHCDT')
				OR (eh.wtask_id = 'REHDCT' AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) = 'REHCD')
					THEN '8'
		WHEN eh.wtask_id IN ('REHDC','REHDCT') 
			AND (lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHDC','REHDCT')
				 OR lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IN ('REHDC','REHDCT'))
					THEN '9'
		WHEN (eh.wtask_id IN ('REHCD','REHCDT') 
				AND lead (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IS NULL)
			OR (eh.wtask_id IN ('REHDC','REHDCT')
				AND lag (eh.wtask_id) OVER (PARTITION BY eh.eq_nbr ORDER BY eh.posted, eh.wtask_id) IS NULL) 
					THEN '10'
	END AS rule
	, eh.eq_nbr
	, eh.wtask_id
	, eh.posted
FROM equipment_history eh
WHERE 
	eh.wtask_id IN ('REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
	AND trunc(eh.posted) BETWEEN to_date('2021-12-01','YYYY-MM-DD') AND to_date('2024-01-31','YYYY-MM-DD')
ORDER BY 
	eh.eq_nbr
	, eh.posted
	, eh.wtask_id
;

--I think I misunderstood the result set. Recompiling results
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

--It validates. The data cleaning effort was unnecessary.