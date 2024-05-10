--Starting with ZLO UAT 2
--Essential throughput query
select  
	EXTRACT(MONTH FROM posted) AS MONTH 
	, COUNT(CASE WHEN wtask_id = 'LOAD' AND transship IS NULL THEN wtask_id END) AS exports 
	, COUNT(CASE WHEN wtask_id = 'UNLOAD' AND transship IS NULL THEN wtask_id END) AS imports 
	, COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD') AND transship IS NOT NULL THEN wtask_id END) AS transships 
	, COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')THEN wtask_id END) AS total  
FROM equipment_history  
WHERE 
	EXTRACT(YEAR FROM posted) = 2023
GROUP BY EXTRACT(MONTH FROM posted)  
ORDER BY EXTRACT(MONTH FROM posted); 

--Switching to PCT Mar '22 - Dec '23
select  
	EXTRACT (YEAR FROM posted) AS year
	, EXTRACT(MONTH FROM posted) AS MONTH 
	, COUNT(CASE WHEN wtask_id = 'LOAD' AND transship IS NULL THEN wtask_id END) AS exports 
	, COUNT(CASE WHEN wtask_id = 'UNLOAD' AND transship IS NULL THEN wtask_id END) AS imports 
	, COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD') AND transship IS NOT NULL THEN wtask_id END) AS transships 
	, COUNT(CASE WHEN (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')THEN wtask_id END) AS total  
FROM equipment_history  
WHERE 
	((EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) >= 3)
	OR EXTRACT(YEAR FROM posted) = 2023)
GROUP BY
	EXTRACT (YEAR FROM posted)
	, EXTRACT(MONTH FROM posted)  
ORDER BY 
	EXTRACT (YEAR FROM posted)
	, EXTRACT(MONTH FROM posted)  
;

--Adapting to group by status
select  
	EXTRACT (YEAR FROM posted) AS year
	, EXTRACT(MONTH FROM posted) AS MONTH 
	, status
	, count(*)
FROM equipment_history  
WHERE 
	((EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) >= 3)
	OR EXTRACT(YEAR FROM posted) = 2023)
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY
	EXTRACT (YEAR FROM posted)
	, EXTRACT(MONTH FROM posted)  
	, status
ORDER BY 
	EXTRACT (YEAR FROM posted)
	, EXTRACT(MONTH FROM posted)
	, status
;

--Applying the fiscal calendar
WITH  date_series AS ( 
	SELECT 
		TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series 
	FROM dual 
	CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD') 
), fiscal_calendar AS ( 
	SELECT 
		date_in_series 
		, CASE  
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
		END AS fiscal_month
		, CASE  
			WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018 
			WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019 
			WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020 
			WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021 
			WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022 
			WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023 
		END AS fiscal_year 
	FROM date_series 
), FINAL AS (
	select  
		fc.fiscal_year
		, fc.fiscal_month
		, eh.status
		, count(*)
	FROM equipment_history  eh
	LEFT JOIN fiscal_calendar fc ON trunc(eh.posted) = fc.date_in_series
	WHERE 
		((fc.fiscal_year = 2022 AND fc.fiscal_month >= 3)
		OR fc.fiscal_year = 2023)
		AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
	GROUP BY
		fc.fiscal_year
		, fc.fiscal_month
		, eh.status
	ORDER BY 
		fc.fiscal_year
		, fc.fiscal_month
		, eh.status
)
SELECT * FROM FINAL;

--Aggregating by vessel and then applying the fiscal calendar
WITH  date_series AS ( 
	SELECT 
		TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series 
	FROM dual 
	CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD') 
), fiscal_calendar AS ( 
	SELECT 
		date_in_series 
		, CASE  
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
		END AS fiscal_month
		, CASE  
			WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018 
			WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019 
			WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020 
			WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021 
			WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022 
			WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023 
		END AS fiscal_year 
	FROM date_series 
), aggregating_by_vessel AS (
	SELECT
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, least (COALESCE (vv.atd,vv.etd),max(eh.posted)) AS dt
		, eh.status
		, count(*) AS moves
	FROM equipment_history  eh
	LEFT JOIN vessel_visits vv ON 
		vv.vsl_id = eh.vsl_id
		AND (vv.in_voy_nbr = eh.voy_nbr OR vv.out_voy_nbr = eh.voy_nbr)
	WHERE --Giving an extra MONTH TO either side USING eh.posted
		((EXTRACT (YEAR FROM eh.posted) = 2022 AND EXTRACT (MONTH FROM eh.posted) >= 2)
			OR EXTRACT (YEAR FROM eh.posted) = 2023
			OR (EXTRACT (YEAR FROM eh.posted) = 2024 AND EXTRACT (MONTH FROM eh.posted) = 1))
		AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
	GROUP BY
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.atd
		, vv.etd
		, eh.status
	ORDER BY 
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.atd
		, vv.etd
		, eh.status
), assigned_to_fiscal_month AS (
	SELECT
		fc.fiscal_year AS YEAR
		, fc.fiscal_month AS MONTH
		, abv.status
		, count(*) AS calls
		, sum (abv.moves) AS moves
	FROM aggregating_by_vessel abv
	JOIN fiscal_calendar fc ON trunc(abv.dt) = fc.date_in_series
	WHERE 
		(fc.fiscal_year = 2022 AND fc.fiscal_month >=3)
		OR fc.fiscal_year = 2023
	GROUP BY 
		fc.fiscal_year
		, fc.fiscal_month
		, abv.status
	ORDER BY 
		fc.fiscal_year
		, fc.fiscal_month
		, abv.status
)
SELECT * FROM assigned_to_fiscal_month;

--Switching to T5S Feb '22 - Dec '22
WITH  date_series AS ( 
	SELECT 
		TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series 
	FROM dual 
	CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD') 
), fiscal_calendar AS ( 
	SELECT 
		date_in_series 
		, CASE  
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
		END AS fiscal_month
		, CASE  
			WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018 
			WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019 
			WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020 
			WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021 
			WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022 
			WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023 
		END AS fiscal_year 
	FROM date_series 
), FINAL AS (
	select  
		fc.fiscal_year
		, fc.fiscal_month
		, eh.status
		, count(*)
	FROM equipment_history  eh
	LEFT JOIN fiscal_calendar fc ON trunc(eh.posted) = fc.date_in_series
	WHERE 
		fc.fiscal_year = 2022 
		AND fc.fiscal_month >= 2
		AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
	GROUP BY
		fc.fiscal_year
		, fc.fiscal_month
		, eh.status
	ORDER BY 
		fc.fiscal_year
		, fc.fiscal_month
		, eh.status
)
SELECT * FROM FINAL;

--Aggregating by vessel, then by fiscal month
WITH  date_series AS ( 
	SELECT 
		TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series 
	FROM dual 
	CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD') 
), fiscal_calendar AS ( 
	SELECT 
		date_in_series 
		, CASE  
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
		END AS fiscal_month
		, CASE  
			WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018 
			WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019 
			WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020 
			WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021 
			WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022 
			WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023 
		END AS fiscal_year 
	FROM date_series 
), aggregating_by_vessel AS (
	SELECT
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, least (COALESCE (vv.atd,vv.etd),max(eh.posted)) AS dt
		, eh.status
		, count(*) AS moves
	FROM equipment_history  eh
	LEFT JOIN vessel_visits vv ON 
		vv.vsl_id = eh.vsl_id
		AND (vv.in_voy_nbr = eh.voy_nbr OR vv.out_voy_nbr = eh.voy_nbr)
	WHERE --Giving an extra MONTH TO either side USING eh.posted
		((EXTRACT (YEAR FROM eh.posted) = 2022 AND EXTRACT (MONTH FROM eh.posted) >= 1)
			OR (EXTRACT (YEAR FROM eh.posted) = 2023 AND EXTRACT (MONTH FROM eh.posted) = 1))
		AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
	GROUP BY
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.atd
		, vv.etd
		, eh.status
	ORDER BY 
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.atd
		, vv.etd
		, eh.status
), assigned_to_fiscal_month AS (
	SELECT
		fc.fiscal_year AS YEAR
		, fc.fiscal_month AS MONTH
		, abv.status
		, count(*) AS calls
		, sum (abv.moves) AS moves
	FROM aggregating_by_vessel abv
	JOIN fiscal_calendar fc ON trunc(abv.dt) = fc.date_in_series
	WHERE 
		fc.fiscal_year = 2022 AND fc.fiscal_month >=2
	GROUP BY 
		fc.fiscal_year
		, fc.fiscal_month
		, abv.status
	ORDER BY 
		fc.fiscal_year
		, fc.fiscal_month
		, abv.status
)
SELECT * FROM assigned_to_fiscal_month;

--Switching to TAM Mar '21 - Apr '23
WITH  date_series AS ( 
	SELECT 
		TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series 
	FROM dual 
	CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD') 
), fiscal_calendar AS ( 
	SELECT 
		date_in_series 
		, CASE  
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
		END AS fiscal_month
		, CASE  
			WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018 
			WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019 
			WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020 
			WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021 
			WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022 
			WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023 
		END AS fiscal_year 
	FROM date_series 
), aggregating_by_vessel AS (
	SELECT
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, least (COALESCE (vv.atd,vv.etd),max(eh.posted)) AS dt
		, eh.status
		, count(*) AS moves
	FROM equipment_history  eh
	LEFT JOIN vessel_visits vv ON 
		vv.vsl_id = eh.vsl_id
		AND (vv.in_voy_nbr = eh.voy_nbr OR vv.out_voy_nbr = eh.voy_nbr)
	WHERE --Giving an extra MONTH TO either side USING eh.posted
		((EXTRACT (YEAR FROM eh.posted) = 2021 AND EXTRACT (MONTH FROM eh.posted) >= 3)
			OR EXTRACT (YEAR FROM eh.posted) = 2022
			OR (EXTRACT (YEAR FROM eh.posted) = 2023 AND EXTRACT (MONTH FROM eh.posted) <= 5))
		AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
	GROUP BY
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.atd
		, vv.etd
		, eh.status
	ORDER BY 
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.atd
		, vv.etd
		, eh.status
), assigned_to_fiscal_month AS (
	SELECT
		fc.fiscal_year AS YEAR
		, fc.fiscal_month AS MONTH
		, abv.status
		, count(*) AS calls
		, sum (abv.moves) AS moves
	FROM aggregating_by_vessel abv
	JOIN fiscal_calendar fc ON trunc(abv.dt) = fc.date_in_series
	WHERE 
		(fc.fiscal_year = 2021 AND fc.fiscal_month >= 4)
		OR fc.fiscal_year = 2022
		OR (fc.fiscal_year = 2023 AND fc.fiscal_month <= 4)
	GROUP BY 
		fc.fiscal_year
		, fc.fiscal_month
		, abv.status
	ORDER BY 
		fc.fiscal_year
		, fc.fiscal_month
		, abv.status
)
SELECT * FROM assigned_to_fiscal_month;

--Switching to MIT
WITH aggregating_by_vessel AS (
	SELECT
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, least (COALESCE (vv.atd,vv.etd),max(eh.posted)) AS dt
		, eh.status
		, count(*) AS moves
	FROM equipment_history  eh
	LEFT JOIN vessel_visits vv ON 
		vv.vsl_id = eh.vsl_id
		AND (vv.in_voy_nbr = eh.voy_nbr OR vv.out_voy_nbr = eh.voy_nbr)
	WHERE --Giving an extra MONTH TO either side USING eh.posted
		((EXTRACT (YEAR FROM eh.posted) = 2021 AND EXTRACT (MONTH FROM eh.posted) >= 3)
			OR EXTRACT (YEAR FROM eh.posted) = 2022
			OR (EXTRACT (YEAR FROM eh.posted) = 2023 AND EXTRACT (MONTH FROM eh.posted) <= 5))
		AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
	GROUP BY
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.atd
		, vv.etd
		, eh.status
	ORDER BY 
		vv.vsl_id
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, vv.atd
		, vv.etd
		, eh.status
), assigned_to_fiscal_month AS (
	SELECT
		EXTRACT (YEAR FROM abv.dt) AS YEAR
		, EXTRACT (MONTH FROM abv.dt) AS MONTH 
		, abv.status
		, count(*) AS calls
		, sum (abv.moves) AS moves
	FROM aggregating_by_vessel abv
	WHERE 
		EXTRACT (YEAR FROM abv.dt) = 2022
		OR EXTRACT (YEAR FROM abv.dt) = 2023
	GROUP BY 
		EXTRACT (YEAR FROM abv.dt)
		, EXTRACT (MONTH FROM abv.dt)
		, abv.status
	ORDER BY 
		EXTRACT (YEAR FROM abv.dt)
		, EXTRACT (MONTH FROM abv.dt) 
)
SELECT * FROM assigned_to_fiscal_month;
