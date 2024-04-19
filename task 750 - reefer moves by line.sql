--Live reefers
SELECT
	temp_required
	, count(*)
	, CASE 
		WHEN temp_required <= 20 THEN NULL 
		ELSE 'Too hot'
	  END AS temp_comment
FROM equipment_history eh
WHERE eh.temp_required IS NOT NULL 
GROUP BY temp_required
ORDER BY 2 DESC 
;

/*		SELECT 
			2022 + trunc((LEVEL-1)/12) AS YEAR
			, mod(LEVEL-1,12) + 1 AS MONTH
		FROM dual
		CONNECT BY LEVEL <= 24
*/

/*	, sum(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 END) AS exports 
	, sum(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 END) AS imports 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')THEN 1 ELSE 0 END) AS total  
*/

--Reefer throughput
WITH 
	year_and_month AS (
		SELECT 
			2022 + trunc((LEVEL-1)/12) AS YEAR
			, mod(LEVEL-1,12) + 1 AS MONTH
		FROM dual
		CONNECT BY LEVEL <= 24
	)
SELECT
	yam.YEAR
	, yam.MONTH
	, sum(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS exports 
	, sum(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS imports 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS transships 
	, sum(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.temp_required IS NOT NULL THEN 1 ELSE 0 END) AS total  
FROM year_and_month yam
LEFT JOIN equipment_history eh ON 
	EXTRACT (YEAR FROM eh.posted) = yam.YEAR
	AND EXTRACT (MONTH FROM eh.posted) = yam.MONTH
GROUP BY
	yam.YEAR
	, yam.MONTH
ORDER BY 
	yam.YEAR
	, yam.month
; 