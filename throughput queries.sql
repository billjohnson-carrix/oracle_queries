-- total throughput
SELECT EXTRACT (MONTH FROM posted) AS month, COUNT(wtask_id) AS task_count
FROM equipment_history
WHERE EXTRACT(YEAR FROM posted) = 2023
  AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY EXTRACT (MONTH FROM posted)
ORDER BY EXTRACT (MONTH FROM posted);

-- exports
select EXTRACT (MONTH FROM posted) AS MONTH, count(wtask_id) AS exports
from equipment_history
where extract (YEAR FROM posted)=2023
	and transship is null and wtask_id='LOAD'
GROUP BY EXTRACT (MONTH FROM posted)
ORDER BY extract(MONTH FROM posted);

-- imports
select EXTRACT (MONTH FROM posted) AS MONTH, count(wtask_id) AS imports
from equipment_history
where EXTRACT (YEAR FROM posted)=2023
	and transship is null and wtask_id='UNLOAD'
GROUP BY EXTRACT (MONTH FROM posted)
ORDER BY extract(MONTH FROM posted);

-- transships
select EXTRACT (MONTH FROM posted) AS MONTH, count(wtask_id) AS transships
from equipment_history
where extract (YEAR FROM posted)=2023
	and transship is not null and (wtask_id='LOAD' or wtask_id='UNLOAD')
GROUP BY EXTRACT (MONTH FROM posted)
ORDER BY extract(MONTH FROM posted);

-- exports, imports, and transships combined in a single result set
SELECT
  EXTRACT(MONTH FROM posted) AS MONTH,
  COUNT(CASE WHEN wtask_id = 'LOAD' AND transship IS NULL THEN wtask_id END) AS exports,
  COUNT(CASE WHEN wtask_id = 'UNLOAD' AND transship IS NULL THEN wtask_id END) AS imports,
  COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD') AND transship IS NOT NULL THEN wtask_id END) AS transships,
  COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')THEN wtask_id END) AS total
FROM equipment_history
WHERE EXTRACT(YEAR FROM posted) = 2023
GROUP BY EXTRACT(MONTH FROM posted)
ORDER BY EXTRACT(MONTH FROM posted);

-- for PCT results
SELECT
  --EXTRACT (YEAR FROM posted) AS YEAR
  --, EXTRACT(MONTH FROM posted) AS MONTH
  COUNT(CASE WHEN wtask_id = 'LOAD' AND transship IS NULL THEN wtask_id END) AS exports
  , COUNT(CASE WHEN wtask_id = 'UNLOAD' AND transship IS NULL THEN wtask_id END) AS imports
  , COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD') AND transship IS NOT NULL THEN wtask_id END) AS transships
  , COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')THEN wtask_id END) AS total
FROM equipment_history
WHERE posted BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
--GROUP BY EXTRACT (YEAR FROM posted), EXTRACT(MONTH FROM posted)
--ORDER BY EXTRACT (YEAR FROM posted), EXTRACT(MONTH FROM posted)
;

WITH date_series AS (
  SELECT
    TO_DATE('2018-01-01', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
  FROM dual
  CONNECT BY TO_DATE('2018-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= SYSDATE
)
SELECT
  --EXTRACT(YEAR FROM ds.date_in_series) AS YEAR,
  --EXTRACT(MONTH FROM ds.date_in_series) AS MONTH,
  COUNT(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN eh.wtask_id END) AS exports,
  COUNT(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN eh.wtask_id END) AS imports,
  COUNT(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN eh.wtask_id END) AS transships,
  COUNT(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') THEN eh.wtask_id END) AS total
FROM date_series ds
LEFT JOIN equipment_history eh ON ds.date_in_series = TRUNC(eh.posted)
WHERE EXTRACT(YEAR FROM ds.date_in_series) >= 2018
GROUP BY EXTRACT(YEAR FROM ds.date_in_series), EXTRACT(MONTH FROM ds.date_in_series)
ORDER BY EXTRACT(YEAR FROM ds.date_in_series), EXTRACT(MONTH FROM ds.date_in_series);

WITH date_series AS (
  SELECT
    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
  FROM dual
  CONNECT BY TO_DATE('2018-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
),
fiscal_calendar AS (
	SELECT
	  date_in_series,
	  CASE 
	    WHEN 
	    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
			OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
		THEN 1
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
	    THEN 2
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
			OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
			OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
			OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
			OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
			OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
		THEN 3    
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
	    THEN 4    
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
	    THEN 5
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
	    THEN 6
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
	    THEN 7
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
	    THEN 8
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
	    THEN 9
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
	    THEN 10
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
	    THEN 11
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
	    THEN 12
	  END AS fiscal_month,
	  CASE 
	    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
	    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
	    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
	    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
	    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
	    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
	  END AS fiscal_year
	FROM date_series)
SELECT
  fc.fiscal_year,
  fc.fiscal_month,
  COUNT(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN eh.wtask_id END) AS exports,
  COUNT(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN eh.wtask_id END) AS imports,
  COUNT(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN eh.wtask_id END) AS transships,
  COUNT(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') THEN eh.wtask_id END) AS total
FROM fiscal_calendar fc
LEFT JOIN equipment_history eh ON fc.date_in_series = TRUNC(eh.posted)
GROUP BY fc.fiscal_year, fc.fiscal_month
ORDER BY fc.fiscal_year, fc.fiscal_month;

SELECT 
	eh.vsl_id
	, eh.voy_nbr
	-- , eh.visit_id
	, EXTRACT (YEAR FROM eh.POSTED)
	, EXTRACT (MONTH FROM eh.posted)
	, EXTRACT (DAY from eh.posted)
	, count(*) 
FROM EQUIPMENT_HISTORY eh 
WHERE posted BETWEEN to_date('2021-01-01', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
GROUP BY eh.vsl_id, eh.voy_nbr, EXTRACT (YEAR FROM eh.posted), EXTRACT (MONTH FROM eh.posted), EXTRACT (DAY FROM eh.posted) 
ORDER BY eh.vsl_id, eh.voy_nbr, EXTRACT (YEAR FROM eh.posted), EXTRACT (MONTH FROM eh.posted), EXTRACT (DAY FROM eh.posted)
;

SELECT * FROM (
	SELECT
		eh.vsl_id
		, eh.voy_nbr
		, EXTRACT (YEAR FROM posted) AS year
		, EXTRACT(MONTH FROM posted) AS MONTH 
		, EXTRACT (DAY FROM posted) AS day
		, COUNT(CASE WHEN wtask_id = 'LOAD' AND transship IS NULL THEN wtask_id END) AS exports 
		, COUNT(CASE WHEN wtask_id = 'UNLOAD' AND transship IS NULL THEN wtask_id END) AS imports 
		, COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD') AND transship IS NOT NULL THEN wtask_id END) AS transships 
		, COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')THEN wtask_id END) AS total  
	FROM equipment_history eh 
	WHERE eh.posted BETWEEN to_date('2021-01-01', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD') 
	GROUP BY eh.vsl_id, eh.voy_nbr, EXTRACT (YEAR FROM eh.posted), EXTRACT (MONTH FROM eh.posted), EXTRACT (DAY FROM eh.posted) 
	ORDER BY eh.vsl_id, eh.voy_nbr, EXTRACT (YEAR FROM eh.posted), EXTRACT (MONTH FROM eh.posted), EXTRACT (DAY FROM eh.posted)
) t1
WHERE t1.total >0
;

WITH date_series AS (
  SELECT
    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
  FROM dual
  CONNECT BY TO_DATE('2018-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
),
fiscal_calendar AS (
	SELECT
	  date_in_series,
	  CASE 
	    WHEN 
	    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
			OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
		THEN 1
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
	    THEN 2
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
			OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
			OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
			OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
			OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
			OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
		THEN 3    
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
	    THEN 4    
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
	    THEN 5
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
	    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
	    THEN 6
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
	    THEN 7
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
	    THEN 8
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
	    THEN 9
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
	    THEN 10
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
	    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
	    THEN 11
	    WHEN 
	    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
	    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
	    THEN 12
	  END AS fiscal_month,
	  CASE 
	    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
	    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
	    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
	    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
	    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
	    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
	  END AS fiscal_year
	FROM date_series)	
SELECT
	fc.fiscal_year AS YEAR
	, fc.fiscal_month AS MONTH
	--, fc.date_in_series
	--, vv.*
	, count(*)
FROM fiscal_calendar fc
JOIN VESSEL_VISITS vv ON fc.date_in_series = TRUNC(vv.atd)
WHERE fc.date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD')
GROUP BY fc.fiscal_year, fc.fiscal_month
ORDER BY fc.fiscal_year, fc.fiscal_month
;

