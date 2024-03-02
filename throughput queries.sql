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
  EXTRACT (YEAR FROM posted) AS YEAR,
  EXTRACT(MONTH FROM posted) AS MONTH,
  COUNT(CASE WHEN wtask_id = 'LOAD' AND transship IS NULL THEN wtask_id END) AS exports,
  COUNT(CASE WHEN wtask_id = 'UNLOAD' AND transship IS NULL THEN wtask_id END) AS imports,
  COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD') AND transship IS NOT NULL THEN wtask_id END) AS transships,
  COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')THEN wtask_id END) AS total
FROM equipment_history
WHERE EXTRACT(YEAR FROM posted) = 2023 OR EXTRACT (YEAR FROM posted) = 2022
GROUP BY EXTRACT (YEAR FROM posted), EXTRACT(MONTH FROM posted)
ORDER BY EXTRACT (YEAR FROM posted), EXTRACT(MONTH FROM posted);

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

SELECT DISTINCT eh.eq_class FROM EQUIPMENT_HISTORY eh ;
SELECT DISTINCT eq.sztp_class FROM equipment eq;
SELECT * from
(SELECT 
	DISTINCT to_number(eq.sztp_eqsz_id) AS len
	, count(*) 
FROM equipment eq 
WHERE 
	eq.SZTP_CLASS = 'CTR' 
	AND REGEXP_LIKE(eq.SZTP_EQSZ_ID, '^[0-9]+$')
GROUP BY eq.SZTP_EQSZ_ID 
ORDER BY eq.SZTP_EQSZ_ID) t1
WHERE to_number(t1.len) > 53
;


-- Good size types for throughput with their quasi-numerical lengths
SELECT 
	sztp_id, len
FROM 
	(SELECT 
		t2.sztp_id
		, t2.len
		, t2.cnt
		, ROW_NUMBER() OVER	(PARTITION BY t2.sztp_id ORDER BY t2.cnt DESC) AS rn
	FROM 
		(SELECT t1.*, et.name, est.name
		FROM (
		    SELECT
		    	to_number(eq.sztp_eqsz_id) AS len
		    	, eq.sztp_class
		    	, eq.sztp_id
		    	, eq.sztp_eqtp_id
		    	, count(*) AS cnt
		    FROM equipment eq
		    WHERE eq.sztp_class = 'CTR' AND REGEXP_LIKE(eq.SZTP_EQSZ_ID, '^[0-9]+$')
		    GROUP BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
		    ORDER BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
		) t1 
	JOIN equipment_types et ON t1.sztp_eqtp_id = et.id
	JOIN EQUIPMENT_SIZE_TYPES est ON t1.sztp_id = est.id
	WHERE NOT t1.sztp_eqtp_id = 'RT' AND NOT t1.sztp_eqtp_id = 'PP'
	ORDER BY t1.sztp_id) t2 )
WHERE rn = 1
;

-- query to report moves and TEUs
WITH sztp_to_len AS
	(SELECT 
		sztp_id, len
	FROM 
		(SELECT 
			t2.sztp_id
			, t2.len
			, t2.cnt
			, ROW_NUMBER() OVER	(PARTITION BY t2.sztp_id ORDER BY t2.cnt DESC) AS rn
		FROM 
			(SELECT t1.*, et.name, est.name
			FROM (
			    SELECT
			    	to_number(eq.sztp_eqsz_id) AS len
			    	, eq.sztp_class
			    	, eq.sztp_id
			    	, eq.sztp_eqtp_id
			    	, count(*) AS cnt
			    FROM equipment eq
			    WHERE eq.sztp_class = 'CTR' AND REGEXP_LIKE(eq.SZTP_EQSZ_ID, '^[0-9]+$')
			    GROUP BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			    --ORDER BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			) t1 
		JOIN equipment_types et ON t1.sztp_eqtp_id = et.id
		JOIN EQUIPMENT_SIZE_TYPES est ON t1.sztp_id = est.id
		WHERE NOT t1.sztp_eqtp_id = 'RT' AND NOT t1.sztp_eqtp_id = 'PP'
		--ORDER BY t1.sztp_id
		) t2 )
	WHERE rn = 1)
SELECT 
  EXTRACT (YEAR FROM t3.posted) AS YEAR,
  EXTRACT(MONTH FROM t3.posted) AS MONTH,
  COUNT(CASE WHEN t3.wtask_id = 'LOAD' AND t3.transship IS NULL THEN t3.wtask_id END) AS exports,
  SUM(CASE WHEN t3.wtask_id = 'LOAD' AND t3.transship IS NULL THEN t3.TEU END) AS exports_TEUS,
  COUNT(CASE WHEN t3.wtask_id = 'UNLOAD' AND t3.transship IS NULL THEN t3.wtask_id END) AS imports,
  SUM(CASE WHEN t3.wtask_id = 'UNLOAD' AND t3.transship IS NULL THEN t3.TEU END) AS imports_TEUS,
  COUNT(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD') AND t3.transship IS NOT NULL THEN t3.wtask_id END) AS transships,
  SUM(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD') AND t3.transship IS NOT NULL THEN t3.TEU END) AS transships_TEUS,
  COUNT(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD')THEN t3.wtask_id END) AS total,
  SUM(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD')THEN t3.TEU END) AS total_TEU
FROM 
  (SELECT
		sztp_to_len.len
		, sztp_to_len.len / 20 AS TEU
		, eh.sztp_id
		, eh.*
	FROM equipment_history eh
	JOIN sztp_to_len ON eh.sztp_id = sztp_to_len.sztp_id
	WHERE posted BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31', 'YYYY-MM-DD')
	) t3
GROUP BY EXTRACT (YEAR FROM t3.posted), EXTRACT (MONTH FROM t3.posted)
ORDER BY EXTRACT (YEAR FROM t3.posted), EXTRACT (MONTH FROM t3.posted)
;

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

WITH sztp_to_len AS
	(SELECT 
		sztp_id, len
	FROM 
		(SELECT 
			t2.sztp_id
			, t2.len
			, t2.cnt
			, ROW_NUMBER() OVER	(PARTITION BY t2.sztp_id ORDER BY t2.cnt DESC) AS rn
		FROM 
			(SELECT t1.*, et.name, est.name
			FROM (
			    SELECT
			    	to_number(eq.sztp_eqsz_id) AS len
			    	, eq.sztp_class
			    	, eq.sztp_id
			    	, eq.sztp_eqtp_id
			    	, count(*) AS cnt
			    FROM equipment eq
			    WHERE eq.sztp_class = 'CTR' AND REGEXP_LIKE(eq.SZTP_EQSZ_ID, '^[0-9]+$')
			    GROUP BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			    --ORDER BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			) t1 
		JOIN equipment_types et ON t1.sztp_eqtp_id = et.id
		JOIN EQUIPMENT_SIZE_TYPES est ON t1.sztp_id = est.id
		WHERE NOT t1.sztp_eqtp_id = 'RT' AND NOT t1.sztp_eqtp_id = 'PP'
		--ORDER BY t1.sztp_id
		) t2 )
	WHERE rn = 1)
SELECT
		sztp_to_len.len
		, sztp_to_len.len / 20 AS TEU
		, eh.sztp_id
		, eh.*
	FROM equipment_history eh
	JOIN sztp_to_len ON eh.sztp_id = sztp_to_len.sztp_id
	WHERE EXTRACT(YEAR FROM posted) = 2024
;

--Starting to compile throughput by the vessel
SELECT 
	v.NAME, vv.IN_VOY_NBR, vv.OUT_VOY_NBR, vv.eta, vv.ata, vv.etd, vv.atd, vv.*
FROM VESSEL_VISITS vv 
JOIN VESSELS v ON vv.vsl_id = v.ID 
WHERE (trunc(vv.atd) BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		OR (vv.atd IS NULL AND trunc(vv.etd) BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
		AND vv.WORK_STARTED IS NOT NULL
ORDER BY trunc(vv.atd), trunc(vv.ATa) 
;

-- Had to make a special inclusion for the AGORYU 2202E/2202W
-- Required actual time of arrival or departure and place in period by atd or etd if ata is null
-- For PCT:
-- Jul-2023 through Dec-2023 33 records
-- Nov-2022 through Aug-2023 69 records
-- May-2022 through Dec-2022 83 records
-- Feb-2022 through Apr-2022 34 records
-- Feb-2022 through Dec-2023 (everything in the good run of data) 
-- The following query replicates the list of vessel visits from the SLC reports from Feb-22 through Dec-23. (189 total records)
SELECT 
	v.NAME, vv.IN_VOY_NBR, vv.OUT_VOY_NBR, vv.eta, vv.ata, vv.etd, vv.atd, vv.*
FROM VESSEL_VISITS vv 
JOIN VESSELS v ON vv.vsl_id = v.ID 
WHERE (trunc(vv.atd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
		AND (vv.WORK_STARTED IS NOT NULL OR vv.vsl_id='AGORYU' OR vv.vsl_id='WAN508' OR VV.VSL_ID = 'SHEFFIE')
--ORDER BY trunc(vv.atd), trunc(vv.ATa) 
ORDER BY vv.VSL_ID, vv.IN_VOY_NBR, vv.OUT_VOY_NBR 
;

--The vessel_summary and vessel_statistics tables are crap for PCT. I'll have to compile moves from equipment history.
--Imports
SELECT
	v.name, vv.VSL_ID, vv.IN_VOY_NBR, vv.atd, COALESCE (count(eh.vsl_id), 0) AS imports
FROM VESSEL_VISITS vv 
LEFT JOIN EQUIPMENT_HISTORY eh ON vv.vsl_id = eh.vsl_id AND vv.IN_VOY_NBR = eh.VISIT_ID 
JOIN VESSELS v ON v.id = vv.VSL_ID 
WHERE (trunc(vv.atd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
		AND (vv.WORK_STARTED IS NOT NULL OR vv.vsl_id='AGORYU' OR vv.vsl_id='WAN508' OR VV.VSL_ID = 'SHEFFIE')
GROUP BY v.name, vv.vsl_id, vv.IN_VOY_NBR, vv.atd
ORDER BY vv.atd
;

--Exports
SELECT
	v.name, vv.VSL_ID, vv.OUT_VOY_NBR , vv.atd, COALESCE (count(eh.vsl_id), 0) AS exports
FROM VESSEL_VISITS vv 
LEFT JOIN EQUIPMENT_HISTORY eh ON vv.vsl_id = eh.vsl_id AND vv.OUT_VOY_NBR  = eh.VISIT_ID 
JOIN VESSELS v ON v.id = vv.VSL_ID 
WHERE (trunc(vv.atd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
		AND (vv.WORK_STARTED IS NOT NULL OR vv.vsl_id='AGORYU' OR vv.vsl_id='WAN508' OR VV.VSL_ID = 'SHEFFIE')
GROUP BY v.name, vv.vsl_id, vv.OUT_VOY_NBR, vv.atd
ORDER BY vv.atd
;
--Scratch work
SELECT * FROM VESSEL_VISITS vv WHERE 
	(vv.VSL_ID = 'AGORYU' OR vv.vsl_id = 'COSJASM' OR VV.VSL_ID = 'CHETCO' OR VV.VSL_ID = 'MAUNA' OR VV.VSL_ID = 'ZHENH27')
	AND trunc(vv.atd) BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
ORDER BY VV.VSL_iD, vv.eta;
SELECT * FROM VESSEL_VISITS vv WHERE vv.VSL_ID = 'SHEFFIE';
SELECT * FROM EQUIPMENT_HISTORY eh
WHERE 
	(eh.vsl_id = 'COSJASM' OR eh.VSL_ID = 'CHETCO' OR eh.VSL_ID = 'MAUNA' OR eh.VSL_ID = 'ZHENH27')
	AND trunc(eh.posted) BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
--GROUP BY eh.vsl_id
ORDER BY eh.VSL_iD;
SELECT * FROM VESSELS v WHERE v.LINE_ID = 'TFL';
SELECT count(*) FROM VESSEL_SUMMARY vs ;
SELECT * FROM VESSEL_SUMMARY vs ;
SELECT
	vv_vsl_id
	, created
FROM VESSEL_STATISTICS vs 
--WHERE trunc(vs.CREATED) BETWEEN  to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
GROUP by vv_vsl_id, created
ORDER BY trunc(vs.CREATED);
SELECT 
	v.NAME, vv.IN_VOY_NBR, vv.OUT_VOY_NBR, vv.eta, vv.ata, vv.etd, vv.atd, vv.*
FROM VESSEL_VISITS vv 
JOIN VESSELS v ON vv.vsl_id = v.ID 
WHERE trunc(vv.atd) BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
ORDER BY trunc(vv.atd), trunc(vv.ATa) 
;

--Trying to overcome manual entry of vessel visits
SELECT 
	v.name, eh.VSL_ID, eh.VOY_NBR 
FROM EQUIPMENT_HISTORY eh 
JOIN VESSELS v ON v.id = eh.VSL_ID 
WHERE 
	eh.VSL_ID IS NOT NULL 
	AND eh.VOY_NBR IS NOT NULL 
	AND (trunc(eh.posted) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD'))
	AND (eh.WTASK_ID = 'LOAD' OR eh.WTASK_ID = 'UNLOAD')
GROUP BY v.name, eh.vsl_id, eh.VOY_NBR 
ORDER BY v.NAME
;
SELECT 
	*
FROM 
	(SELECT
		v.name, vv.VSL_ID, vv.IN_VOY_NBR AS voy_nbr
	FROM VESSEL_VISITS vv 
	JOIN VESSELS v ON v.id = vv.VSL_ID 
	WHERE (trunc(vv.atd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
			OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
			AND (vv.WORK_STARTED IS NOT NULL OR vv.vsl_id='AGORYU' OR vv.vsl_id='WAN508' OR VV.VSL_ID = 'SHEFFIE')
	GROUP BY v.name, vv.vsl_id, vv.IN_VOY_NBR
	UNION
	SELECT
		v.name, vv.VSL_ID, vv.OUT_VOY_NBR AS voy_nbr
	FROM VESSEL_VISITS vv 
	JOIN VESSELS v ON v.id = vv.VSL_ID 
	WHERE (trunc(vv.atd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
			OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
			AND (vv.WORK_STARTED IS NOT NULL OR vv.vsl_id='AGORYU' OR vv.vsl_id='WAN508' OR VV.VSL_ID = 'SHEFFIE')
	GROUP BY v.name, vv.vsl_id, vv.OUT_VOY_NBR) t1
ORDER BY t1.name, t1.voy_nbr
;
WITH 
	ves_vis AS (
		SELECT 
			*
		FROM 
			(SELECT
				v.name, vv.VSL_ID, vv.IN_VOY_NBR AS voy_nbr
			FROM VESSEL_VISITS vv 
			JOIN VESSELS v ON v.id = vv.VSL_ID 
			WHERE (trunc(vv.atd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
					OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
					AND (vv.WORK_STARTED IS NOT NULL OR vv.vsl_id='AGORYU' OR vv.vsl_id='WAN508' OR VV.VSL_ID = 'SHEFFIE')
			GROUP BY v.name, vv.vsl_id, vv.IN_VOY_NBR
			UNION
			SELECT
				v.name, vv.VSL_ID, vv.OUT_VOY_NBR AS voy_nbr
			FROM VESSEL_VISITS vv 
			JOIN VESSELS v ON v.id = vv.VSL_ID 
			WHERE (trunc(vv.atd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
					OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
					AND (vv.WORK_STARTED IS NOT NULL OR vv.vsl_id='AGORYU' OR vv.vsl_id='WAN508' OR VV.VSL_ID = 'SHEFFIE')
			GROUP BY v.name, vv.vsl_id, vv.OUT_VOY_NBR) t1
	)
	, equip_his AS (
		SELECT 
			v.name, eh.VSL_ID, eh.VOY_NBR 
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSELS v ON v.id = eh.VSL_ID 
		WHERE 
			eh.VSL_ID IS NOT NULL 
			AND eh.VOY_NBR IS NOT NULL 
			AND (trunc(eh.posted) BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD'))
			AND (eh.WTASK_ID = 'LOAD' OR eh.WTASK_ID = 'UNLOAD')
		GROUP BY v.name, eh.vsl_id, eh.VOY_NBR 
	)
SELECT
	vv.name, vv.vsl_id, vv.voy_nbr, eh.name, eh.vsl_id, eh.voy_nbr
FROM ves_vis vv
FULL OUTER JOIN equip_his eh ON vv.vsl_id = eh.vsl_id AND vv.voy_nbr = eh.voy_nbr
ORDER BY vv.name, vv.voy_nbr, eh.name, eh.voy_nbr
;
-- Looking up outliers
SELECT 
	count(*)
FROM EQUIPMENT_HISTORY eh 
WHERE 
	eh.VSL_ID = 'COSJASM' AND eh.VOY_NBR = '024W'
	AND (eh.WTASK_ID = 'LOAD' OR eh.WTASK_ID = 'UNLOAD')
;
SELECT 
	*
--	vv.VSL_ID, vv.IN_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
FROM VESSEL_VISITS vv 
WHERE 
	vv.VSL_ID = 'WAN355' AND (vv.IN_VOY_NBR = '014E' OR vv.OUT_VOY_NBR = '014E')
;
--A hopefully better attempt at creating the vessel visit list that shouldn't need manual inclusion of vessels
/*
 * It works with two errors for PCT. The BALPEAC 2206E is a correction to the in_voy_nbr of the BAL PEACE. The wrong number in the vessel_visits table is '2152E'.
 * Actually, I don't know which voyage is correct, but the equipment_history table has broken referential integrity by attributing moves to a vessel visit
 * that doesn't exist. Also, the COSCO SHIPPING JASMINE, COSJASM, 024E 024W, looks like someone might have invented it. I can't explain why its present. It has moves too.
 * But this query looks transerrable to other terminals. Yay!
 */
SELECT 
	v.name, t1.vsl_id, t1.in_voy_nbr, t1.out_voy_nbr, COALESCE (count(t1.wtask_id), 0) AS move_count
FROM 
	(SELECT 
		vv.*, eh.wtask_id
	FROM VESSEL_VISITS vv 
	JOIN EQUIPMENT_HISTORY eh ON vv.VSL_ID = eh.VSL_ID AND (vv.IN_VOY_NBR = eh.voy_nbr OR vv.OUT_VOY_NBR = eh.VOY_NBR)
	WHERE 
		(trunc(vv.atd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
			OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
		 AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')) t1
JOIN VESSELS v ON v.id = t1.vsl_id
GROUP BY v.name, t1.vsl_id, t1.in_voy_nbr, t1.out_voy_nbr
ORDER BY t1.vsl_id, t1.in_voy_nbr, t1.out_voy_nbr
;
-- I'd like the above broken down by imports, exports, and total.
WITH imports AS (
	SELECT 
		v.name
		, t1.vsl_id
		, t1.in_voy_nbr
		, t1.out_voy_nbr
		, t1.nnatd
		, t1.wtask_id
		, COALESCE (count(t1.wtask_id), 0) AS imports
	FROM 
		(SELECT 
			vv.*, eh.wtask_id, COALESCE (vv.atd, vv.etd, vv.ata, vv.eta) AS nnatd
		FROM VESSEL_VISITS vv 
		JOIN EQUIPMENT_HISTORY eh ON vv.VSL_ID = eh.VSL_ID AND (vv.IN_VOY_NBR = eh.voy_nbr OR vv.OUT_VOY_NBR = eh.VOY_NBR)
		WHERE 
			(trunc(vv.atd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
				OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
			 AND (eh.wtask_id = 'UNLOAD')) t1
	JOIN VESSELS v ON v.id = t1.vsl_id
	GROUP BY v.name, t1.vsl_id, t1.in_voy_nbr, t1.out_voy_nbr, t1.nnatd, t1.wtask_id
)
SELECT 
	COALESCE (imports.name, exports.name) AS name
	, COALESCE (imports.vsl_id, exports.vsl_id) AS vsl_id
	, COALESCE (imports.in_voy_nbr, exports.in_voy_nbr) AS in_voy_nbr
	, COALESCE (imports.out_voy_nbr, exports.out_voy_nbr) AS out_voy_nbr
	, COALESCE (imports.nnatd, exports.nnatd) AS atd
	, COALESCE (imports.imports, 0) AS imports
	, COALESCE (exports.exports, 0) AS exports
	, COALESCE (imports.imports, 0) + COALESCE (exports.exports, 0) AS total
FROM 
	(SELECT 
		v.name
		, t1.vsl_id
		, t1.in_voy_nbr
		, t1.out_voy_nbr
		, t1.nnatd
		, t1.wtask_id
		, COALESCE (count(*), 0) AS exports
	FROM 
		(SELECT 
			vv.*, eh.wtask_id, COALESCE (vv.atd, vv.etd, vv.ata, vv.eta) AS nnatd
		FROM VESSEL_VISITS vv 
		JOIN EQUIPMENT_HISTORY eh ON vv.VSL_ID = eh.VSL_ID AND (vv.IN_VOY_NBR = eh.voy_nbr OR vv.OUT_VOY_NBR = eh.VOY_NBR)
		WHERE 
			(trunc(vv.atd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
				OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
			 AND (eh.wtask_id = 'LOAD')) t1
	JOIN VESSELS v ON v.id = t1.vsl_id
	GROUP BY v.name, t1.vsl_id, t1.in_voy_nbr, t1.out_voy_nbr, t1.nnatd, t1.wtask_id) exports
FULL OUTER JOIN 
	imports ON imports.vsl_id = exports.vsl_id 
	AND imports.in_voy_nbr = exports.in_voy_nbr 
	AND imports.out_voy_nbr = exports.out_voy_nbr 
	AND NOT imports.wtask_id = exports.wtask_id
ORDER BY COALESCE (imports.nnatd, exports.nnatd)
;
-- And now to aggregate by fiscal month
WITH 
	imports AS (
		SELECT 
			v.name
			, t1.vsl_id
			, t1.in_voy_nbr
			, t1.out_voy_nbr
			, t1.nnatd
			, t1.wtask_id
			, COALESCE (count(t1.wtask_id), 0) AS imports
		FROM 
			(SELECT 
				vv.*, eh.wtask_id, COALESCE (vv.atd, vv.etd, vv.ata, vv.eta) AS nnatd
			FROM VESSEL_VISITS vv 
			JOIN EQUIPMENT_HISTORY eh ON vv.VSL_ID = eh.VSL_ID AND (vv.IN_VOY_NBR = eh.voy_nbr OR vv.OUT_VOY_NBR = eh.VOY_NBR)
			WHERE 
				(trunc(vv.atd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
					OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
				 AND (eh.wtask_id = 'UNLOAD')) t1
		JOIN VESSELS v ON v.id = t1.vsl_id
		GROUP BY v.name, t1.vsl_id, t1.in_voy_nbr, t1.out_voy_nbr, t1.nnatd, t1.wtask_id
	), by_vessel AS ( 
		SELECT 
			COALESCE (imports.name, exports.name) AS name
			, COALESCE (imports.vsl_id, exports.vsl_id) AS vsl_id
			, COALESCE (imports.in_voy_nbr, exports.in_voy_nbr) AS in_voy_nbr
			, COALESCE (imports.out_voy_nbr, exports.out_voy_nbr) AS out_voy_nbr
			, COALESCE (imports.nnatd, exports.nnatd) AS atd
			, COALESCE (imports.imports, 0) AS imports
			, COALESCE (exports.exports, 0) AS exports
			, COALESCE (imports.imports, 0) + COALESCE (exports.exports, 0) AS total
		FROM 
			(SELECT 
				v.name
				, t1.vsl_id
				, t1.in_voy_nbr
				, t1.out_voy_nbr
				, t1.nnatd
				, t1.wtask_id
				, COALESCE (count(*), 0) AS exports
			FROM 
				(SELECT 
					vv.*, eh.wtask_id, COALESCE (vv.atd, vv.etd, vv.ata, vv.eta) AS nnatd
				FROM VESSEL_VISITS vv 
				JOIN EQUIPMENT_HISTORY eh ON vv.VSL_ID = eh.VSL_ID AND (vv.IN_VOY_NBR = eh.voy_nbr OR vv.OUT_VOY_NBR = eh.VOY_NBR)
				WHERE 
					(trunc(vv.atd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
						OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')))
					 AND (eh.wtask_id = 'LOAD')) t1
			JOIN VESSELS v ON v.id = t1.vsl_id
			GROUP BY v.name, t1.vsl_id, t1.in_voy_nbr, t1.out_voy_nbr, t1.nnatd, t1.wtask_id) exports
		FULL OUTER JOIN 
			imports ON imports.vsl_id = exports.vsl_id 
			AND imports.in_voy_nbr = exports.in_voy_nbr 
			AND imports.out_voy_nbr = exports.out_voy_nbr 
			AND NOT imports.wtask_id = exports.wtask_id
		)
	, date_series AS (
		  SELECT
		    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2018-01-01', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-31', 'YYYY-MM-DD')
	)
	, fiscal_calendar AS (
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
		FROM date_series
	)
SELECT
	fc.fiscal_year AS year
	, fc.fiscal_month AS MONTH
	, bv.*
	--, sum(bv.imports) AS imports
	--, sum(bv.exports) AS exports
	--, sum(bv.total) AS total
FROM fiscal_calendar fc
JOIN by_vessel bv ON trunc(bv.atd) = fc.date_in_series
--GROUP BY fc.fiscal_year, fc.fiscal_month
ORDER BY fc.fiscal_year, fc.fiscal_month, bv.atd
;
SELECT trunc(vv.atd) FROM VESSEL_VISITS vv WHERE vv.vsl_id = 'CSCLYEL' AND vv.IN_VOY_NBR = '047E';

-- Looking at T5S now
WITH imports AS (
	SELECT 
		v.name
		, t1.vsl_id
		, t1.in_voy_nbr
		, t1.out_voy_nbr
		, t1.nnatd
		, t1.wtask_id
		, COALESCE (count(t1.wtask_id), 0) AS imports
	FROM 
		(SELECT 
			vv.*, eh.wtask_id, COALESCE (vv.atd, vv.etd, vv.ata, vv.eta) AS nnatd
		FROM VESSEL_VISITS vv 
		JOIN EQUIPMENT_HISTORY eh ON vv.VSL_ID = eh.VSL_ID AND (vv.IN_VOY_NBR = eh.voy_nbr OR vv.OUT_VOY_NBR = eh.VOY_NBR)
		WHERE 
			(trunc(vv.atd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-02-14', 'YYYY-MM-DD')
				OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-02-14', 'YYYY-MM-DD')))
			 AND (eh.wtask_id = 'UNLOAD')) t1
	JOIN VESSELS v ON v.id = t1.vsl_id
	GROUP BY v.name, t1.vsl_id, t1.in_voy_nbr, t1.out_voy_nbr, t1.nnatd, t1.wtask_id
)
SELECT 
	COALESCE (imports.name, exports.name) AS name
	, COALESCE (imports.vsl_id, exports.vsl_id) AS vsl_id
	, COALESCE (imports.in_voy_nbr, exports.in_voy_nbr) AS in_voy_nbr
	, COALESCE (imports.out_voy_nbr, exports.out_voy_nbr) AS out_voy_nbr
	, COALESCE (imports.nnatd, exports.nnatd) AS atd
	, COALESCE (imports.imports, 0) AS imports
	, COALESCE (exports.exports, 0) AS exports
	, COALESCE (imports.imports, 0) + COALESCE (exports.exports, 0) AS total
FROM 
	(SELECT 
		v.name
		, t1.vsl_id
		, t1.in_voy_nbr
		, t1.out_voy_nbr
		, t1.nnatd
		, t1.wtask_id
		, COALESCE (count(*), 0) AS exports
	FROM 
		(SELECT 
			vv.*, eh.wtask_id, COALESCE (vv.atd, vv.etd, vv.ata, vv.eta) AS nnatd
		FROM VESSEL_VISITS vv 
		JOIN EQUIPMENT_HISTORY eh ON vv.VSL_ID = eh.VSL_ID AND (vv.IN_VOY_NBR = eh.voy_nbr OR vv.OUT_VOY_NBR = eh.VOY_NBR)
		WHERE 
			(trunc(vv.atd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-02-14', 'YYYY-MM-DD')
				OR (vv.atd IS NULL AND vv.ata IS NOT NULL AND trunc(vv.etd) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-02-14', 'YYYY-MM-DD')))
			 AND (eh.wtask_id = 'LOAD')) t1
	JOIN VESSELS v ON v.id = t1.vsl_id
	GROUP BY v.name, t1.vsl_id, t1.in_voy_nbr, t1.out_voy_nbr, t1.nnatd, t1.wtask_id) exports
FULL OUTER JOIN 
	imports ON imports.vsl_id = exports.vsl_id 
	AND imports.in_voy_nbr = exports.in_voy_nbr 
	AND imports.out_voy_nbr = exports.out_voy_nbr 
	AND NOT imports.wtask_id = exports.wtask_id
ORDER BY atd
;

-- The Northern Volition 015E/015W is missing from the UAT data
SELECT * 
FROM VESSEL_VISITS vv 
WHERE vv.vsl_id = 'NORVOL' --AND vv.IN_VOY_NBR = '015E' AND vv.OUT_VOY_NBR = '015W'
;
SELECT count(*)
FROM EQUIPMENT_HISTORY eh 
WHERE eh.vsl_id = 'NORVOL' AND eh.VOY_NBR = '015W'
;
/*
 * Selecting based on atd isn't reliable. I'm going to switch to selecting based on a LOAD or UNLOAD task in equipment_history within the period of interest,
 * then join to the vessel_visits table using the equipment_history vsl_id and voy_nbr.
 */
-- This works well. We miss no voyages. We get four extras that have only 1 move.
SELECT
	v.name
	, vv.VSL_ID 
	, vv.in_VOY_NBR
	, vv.OUT_VOY_NBR 
	, max(trunc(eh.posted)) AS dt
	, count(*)
FROM EQUIPMENT_HISTORY eh 
JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
JOIN VESSELS v ON vv.VSL_ID = v.ID 
WHERE 
	trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-02-14', 'YYYY-MM-DD')
	AND eh.vsl_id IS NOT NULL
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR
ORDER BY dt
;
-- Now let's break the total down by imports and exports
-- This works well for T5
SELECT
	v.name
	, vv.VSL_ID 
	, vv.in_VOY_NBR
	, vv.OUT_VOY_NBR 
	, COALESCE (vv.atd, max(trunc(eh.posted))) AS dt
	, sum (CASE WHEN eh.wtask_id = 'UNLOAD' THEN 1 ELSE 0 end) AS imports
	, sum (CASE WHEN eh.wtask_id = 'LOAD' THEN 1 ELSE 0 end) AS exports
	, count(*) AS moves
FROM EQUIPMENT_HISTORY eh 
JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
JOIN VESSELS v ON vv.VSL_ID = v.ID 
WHERE 
	trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-02-14', 'YYYY-MM-DD')
	AND eh.vsl_id IS NOT NULL
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
ORDER BY dt
;
-- Let's see if the aggregation by vesel works well for PCT
-- It does
SELECT
	v.name
	, vv.VSL_ID 
	, vv.in_VOY_NBR
	, vv.OUT_VOY_NBR 
	, COALESCE (vv.atd, max(trunc(eh.posted))) AS dt
	, sum (CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS imports
	, sum (CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS exports
	, sum (CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships
	, count(*) AS moves
FROM EQUIPMENT_HISTORY eh 
JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
JOIN VESSELS v ON vv.VSL_ID = v.ID 
WHERE 
	trunc(eh.posted) BETWEEN to_date('2022-02-01', 'YYYY-MM-DD') AND to_date('2024-01-31', 'YYYY-MM-DD')
	AND eh.vsl_id IS NOT NULL
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
ORDER BY dt
;
--Now to assign T5 vessel visits to the fiscal calendar
WITH 
	date_series AS (
		  SELECT
		    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD')
	)
	, fiscal_calendar AS (
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
		FROM date_series
	), by_vessel AS (
		SELECT
			v.name
			, vv.VSL_ID 
			, vv.in_VOY_NBR
			, vv.OUT_VOY_NBR 
			, COALESCE (trunc(vv.atd), max(trunc(eh.posted))) AS dt
			, sum (CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS imports
			, sum (CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS exports
			, sum (CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships
			, count(*) AS moves
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-02-14', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
		--ORDER BY COALESCE (trunc(vv.atd), max(trunc(eh.posted)))
	) 
SELECT
	bv.name
	, bv.vsl_id
	, bv.in_voy_nbr
	, bv.out_voy_nbr
	, bv.dt
	, fc.fiscal_year
	, fc.fiscal_month
	, bv.imports
	, bv.exports
	, bv.transships
	, bv.moves
FROM by_vessel bv
JOIN fiscal_calendar fc ON bv.dt = fc.date_in_series
ORDER BY dt
;
--Now to summarize by fiscal month
WITH 
	date_series AS (
		  SELECT
		    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD')
	)
	, fiscal_calendar AS (
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
		FROM date_series
	), by_vessel AS (
		SELECT
			v.name
			, vv.VSL_ID 
			, vv.in_VOY_NBR
			, vv.OUT_VOY_NBR 
			, COALESCE (trunc(vv.atd), max(trunc(eh.posted))) AS dt
			, sum (CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS imports
			, sum (CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS exports
			, sum (CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships
			, count(*) AS moves
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-02-14', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
		--ORDER BY COALESCE (trunc(vv.atd), max(trunc(eh.posted)))
	) 
SELECT
	fc.fiscal_year
	, fc.fiscal_month
	, sum (bv.imports) AS imports
	, sum (bv.exports) AS exports
	, sum (bv.transships) AS transships
	, sum (bv.moves) AS moves
FROM by_vessel bv
JOIN fiscal_calendar fc ON bv.dt = fc.date_in_series
GROUP BY fc.fiscal_year, fc.fiscal_month
ORDER BY fc.fiscal_year, fc.fiscal_month
;
-- Now to see if the fiscal month results still work for PCT with the new atd
-- It produces identical results.
WITH 
	date_series AS (
		  SELECT
		    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD')
	)
	, fiscal_calendar AS (
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
		FROM date_series
	), by_vessel AS (
		SELECT
			v.name
			, vv.VSL_ID 
			, vv.in_VOY_NBR
			, vv.OUT_VOY_NBR 
			, COALESCE (trunc(vv.atd), max(trunc(eh.posted))) AS dt
			, sum (CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS imports
			, sum (CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS exports
			, sum (CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships
			, count(*) AS moves
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-02-01', 'YYYY-MM-DD') AND to_date('2024-01-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
		--ORDER BY COALESCE (trunc(vv.atd), max(trunc(eh.posted)))
	) 
SELECT
	fc.fiscal_year
	, fc.fiscal_month
	, sum (bv.imports) AS imports
	, sum (bv.exports) AS exports
	, sum (bv.transships) AS transships
	, sum (bv.moves) AS moves
FROM by_vessel bv
JOIN fiscal_calendar fc ON bv.dt = fc.date_in_series
GROUP BY fc.fiscal_year, fc.fiscal_month
ORDER BY fc.fiscal_year, fc.fiscal_month
;
-- Now for TAM
WITH 
	date_series AS (
		  SELECT
		    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD')
	)
	, fiscal_calendar AS (
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
		FROM date_series
	), by_vessel AS (
		SELECT
			v.name
			, vv.VSL_ID 
			, vv.in_VOY_NBR
			, vv.OUT_VOY_NBR 
			, COALESCE (trunc(vv.atd), max(trunc(eh.posted))) AS dt
			, sum (CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS imports
			, sum (CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS exports
			, sum (CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships
			, count(*) AS moves
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2021-01-01', 'YYYY-MM-DD') AND to_date('2023-04-30', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
		--ORDER BY COALESCE (trunc(vv.atd), max(trunc(eh.posted)))
	) 
SELECT
	fc.fiscal_year
	, fc.fiscal_month
	, sum (bv.imports) AS imports
	, sum (bv.exports) AS exports
	, sum (bv.transships) AS transships
	, sum (bv.moves) AS moves
FROM by_vessel bv
JOIN fiscal_calendar fc ON bv.dt = fc.date_in_series
GROUP BY fc.fiscal_year, fc.fiscal_month
ORDER BY fc.fiscal_year, fc.fiscal_month
;
-- Now to aggegate MIT/ZLO/ZLO 2/ and ZLO AV moves by vessel for assignment to a calendar month
WITH 
	by_vessel AS (
		SELECT
			v.name
			, vv.VSL_ID 
			, vv.in_VOY_NBR
			, vv.OUT_VOY_NBR 
			, COALESCE (trunc(vv.atd), max(trunc(eh.posted))) AS dt
			, sum (CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS imports
			, sum (CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS exports
			, sum (CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships
			, count(*) AS moves
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2021-12-01', 'YYYY-MM-DD') AND to_date('2024-01-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
		--ORDER BY COALESCE (trunc(vv.atd), max(trunc(eh.posted)))
	) 
SELECT
	EXTRACT (YEAR FROM bv.dt) AS Year
	, EXTRACT (MONTH FROM bv.dt) AS month
	, sum (bv.imports) AS imports
	, sum (bv.exports) AS exports
	, sum (bv.transships) AS transships
	, sum (bv.moves) AS moves
FROM by_vessel bv
GROUP BY EXTRACT (YEAR FROM bv.dt), EXTRACT (MONTH FROM bv.dt)
ORDER BY EXTRACT (YEAR FROM bv.dt), EXTRACT (MONTH FROM bv.dt)
;