--David's query
SELECT
	'GATE'
	, count(*)
from (
	select *
	from equipment_history eh
	where 
		posted BETWEEN to_date('01/01/23 00:00:00', 'MM/DD/RR HH24:MI:SS') AND to_date('12/31/23 23:59:59', 'MM/DD/RR HH24:MI:SS')
		and removed is null
		and wtask_id in (
			select id
			from terminal_events
			where 
				event_group in ( 'GATE')
				and required is not null)
		and eq_class = 'CTR'
);

--Used for MIT UAT, ZLO UAT 2, and TAM
WITH 
	results AS (
		SELECT
			EXTRACT (YEAR FROM eh.posted) AS YEAR 
			, EXTRACT (MONTH FROM eh.posted) AS month
			, count(eh.posted) AS records
		FROM equipment_history eh 
		where 
			removed is null
			and eq_class = 'CTR'
			AND wtask_id IN (select id
				from terminal_events
				where 
					event_group in ('GATE')
					and required is not null	
				)
		GROUP BY 
			EXTRACT (YEAR FROM eh.posted)
			, EXTRACT (MONTH FROM eh.posted)
		ORDER BY 
			EXTRACT (YEAR FROM eh.posted)
			, EXTRACT (MONTH FROM eh.posted)
	), YEAR_and_month AS (
		SELECT 
			2022 + trunc((LEVEL - 1)/12) AS YEAR
			, mod(LEVEL-1,12) + 1 AS MONTH
		FROM dual
		CONNECT BY LEVEL <= 24
	)
SELECT
	yam.YEAR
	, yam.MONTH
	, nvl(r.records,0) AS records
FROM year_and_month yam
LEFT JOIN results r ON 
	r.YEAR = yam.YEAR
	AND r.MONTH = yam.MONTH
ORDER BY 
	yam.YEAR
	, yam.month
;

--Used for PCT UAT
WITH 
	results AS (
		SELECT
			sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-05-27','YYYY-MM-DD') AND to_date('2023-06-02','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week1_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-06-03','YYYY-MM-DD') AND to_date('2023-06-09','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week2_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-06-10','YYYY-MM-DD') AND to_date('2023-06-16','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week3_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-06-17','YYYY-MM-DD') AND to_date('2023-06-23','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week4_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-06-24','YYYY-MM-DD') AND to_date('2023-06-30','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week5_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-07-01','YYYY-MM-DD') AND to_date('2023-07-07','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week6_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-07-08','YYYY-MM-DD') AND to_date('2023-07-14','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week7_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-07-15','YYYY-MM-DD') AND to_date('2023-07-21','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week8_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-07-22','YYYY-MM-DD') AND to_date('2023-07-28','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week9_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-07-29','YYYY-MM-DD') AND to_date('2023-08-04','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week10_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-08-05','YYYY-MM-DD') AND to_date('2023-08-11','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week11_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-08-12','YYYY-MM-DD') AND to_date('2023-08-18','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week12_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-08-19','YYYY-MM-DD') AND to_date('2023-08-25','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week13_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-08-26','YYYY-MM-DD') AND to_date('2023-09-01','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week14_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-09-02','YYYY-MM-DD') AND to_date('2023-09-08','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week15_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-09-09','YYYY-MM-DD') AND to_date('2023-09-15','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week16_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-09-16','YYYY-MM-DD') AND to_date('2023-09-22','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week17_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-09-23','YYYY-MM-DD') AND to_date('2023-09-29','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week18_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-09-30','YYYY-MM-DD') AND to_date('2023-10-06','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week19_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-10-07','YYYY-MM-DD') AND to_date('2023-10-13','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week20_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-10-14','YYYY-MM-DD') AND to_date('2023-10-20','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week21_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-10-21','YYYY-MM-DD') AND to_date('2023-10-27','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week22_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-10-28','YYYY-MM-DD') AND to_date('2023-11-03','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week23_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-11-04','YYYY-MM-DD') AND to_date('2023-11-10','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week24_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-11-11','YYYY-MM-DD') AND to_date('2023-11-17','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week25_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-11-18','YYYY-MM-DD') AND to_date('2023-11-24','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week26_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-11-25','YYYY-MM-DD') AND to_date('2023-12-01','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week27_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-12-02','YYYY-MM-DD') AND to_date('2023-12-08','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week28_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-12-09','YYYY-MM-DD') AND to_date('2023-12-15','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week29_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-12-16','YYYY-MM-DD') AND to_date('2023-12-22','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week30_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-12-23','YYYY-MM-DD') AND to_date('2023-12-29','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week31_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-12-30','YYYY-MM-DD') AND to_date('2024-01-05','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week32_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2024-01-06','YYYY-MM-DD') AND to_date('2024-01-12','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week33_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2024-01-13','YYYY-MM-DD') AND to_date('2024-01-19','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week34_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2024-01-20','YYYY-MM-DD') AND to_date('2024-01-26','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week35_count
		FROM equipment_history eh 
		where 
			removed is null
			and eq_class = 'CTR'
			AND wtask_id IN 
				(select id
					from terminal_events
					where 
						event_group in ('GATE')
						and required is not null	
					AND eh.posted BETWEEN to_date('2023-05-27','YYYY-MM-DD') AND to_date('2024-01-23','YYYY-MM-DD')
				)
/*		GROUP BY 
			EXTRACT (YEAR FROM eh.posted)
			, EXTRACT (MONTH FROM eh.posted)
		ORDER BY 
			EXTRACT (YEAR FROM eh.posted)
			, EXTRACT (MONTH FROM eh.posted)
*/	)
SELECT 23 AS week_no, r.week1_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 24 AS week_no, r.week2_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 25 AS week_no, r.week3_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 26 AS week_no, r.week4_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 27 AS week_no, r.week5_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 28 AS week_no, r.week6_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 29 AS week_no, r.week7_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 30 AS week_no, r.week8_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 31 AS week_no, r.week9_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 32 AS week_no, r.week10_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 33 AS week_no, r.week11_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 34 AS week_no, r.week12_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 35 AS week_no, r.week13_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 36 AS week_no, r.week14_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 37 AS week_no, r.week15_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 38 AS week_no, r.week16_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 39 AS week_no, r.week17_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 40 AS week_no, r.week18_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 41 AS week_no, r.week19_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 42 AS week_no, r.week20_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 43 AS week_no, r.week21_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 44 AS week_no, r.week22_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 45 AS week_no, r.week23_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 46 AS week_no, r.week24_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 47 AS week_no, r.week25_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 48 AS week_no, r.week26_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 49 AS week_no, r.week27_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 50 AS week_no, r.week28_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 51 AS week_no, r.week29_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 52 AS week_no, r.week30_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 53 AS week_no, r.week31_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 54 AS week_no, r.week32_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 55 AS week_no, r.week33_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 56 AS week_no, r.week34_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 57 AS week_no, r.week35_count AS volume FROM dual CROSS JOIN results r
ORDER BY 
	week_no
;

--T5
WITH 
	results AS (
		SELECT
			sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2022-01-07','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week1_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-01-08','YYYY-MM-DD') AND to_date('2022-01-14','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week2_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-01-15','YYYY-MM-DD') AND to_date('2022-01-21','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week3_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-01-22','YYYY-MM-DD') AND to_date('2022-01-28','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week4_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-01-29','YYYY-MM-DD') AND to_date('2022-02-04','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week5_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-02-05','YYYY-MM-DD') AND to_date('2022-02-11','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week6_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-02-12','YYYY-MM-DD') AND to_date('2022-02-18','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week7_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-02-19','YYYY-MM-DD') AND to_date('2022-02-25','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week8_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-02-26','YYYY-MM-DD') AND to_date('2022-03-04','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week9_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-03-05','YYYY-MM-DD') AND to_date('2022-03-11','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week10_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-03-12','YYYY-MM-DD') AND to_date('2022-03-18','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week11_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-03-19','YYYY-MM-DD') AND to_date('2022-03-25','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week12_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-03-26','YYYY-MM-DD') AND to_date('2022-04-01','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week13_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-04-02','YYYY-MM-DD') AND to_date('2022-04-08','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week14_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-04-09','YYYY-MM-DD') AND to_date('2022-04-15','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week15_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-04-16','YYYY-MM-DD') AND to_date('2022-04-22','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week16_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-04-23','YYYY-MM-DD') AND to_date('2022-04-29','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week17_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-04-30','YYYY-MM-DD') AND to_date('2022-05-06','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week18_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-05-07','YYYY-MM-DD') AND to_date('2022-05-13','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week19_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-05-14','YYYY-MM-DD') AND to_date('2022-05-20','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week20_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-05-21','YYYY-MM-DD') AND to_date('2022-05-27','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week21_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-05-28','YYYY-MM-DD') AND to_date('2022-06-03','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week22_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-06-04','YYYY-MM-DD') AND to_date('2022-06-10','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week23_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-06-11','YYYY-MM-DD') AND to_date('2022-06-17','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week24_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-06-18','YYYY-MM-DD') AND to_date('2022-06-24','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week25_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-06-25','YYYY-MM-DD') AND to_date('2022-07-01','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week26_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-07-02','YYYY-MM-DD') AND to_date('2022-07-08','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week27_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-07-09','YYYY-MM-DD') AND to_date('2022-07-15','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week28_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-07-16','YYYY-MM-DD') AND to_date('2022-07-22','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week29_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-07-23','YYYY-MM-DD') AND to_date('2022-07-29','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week30_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-07-30','YYYY-MM-DD') AND to_date('2022-08-05','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week31_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-08-06','YYYY-MM-DD') AND to_date('2022-08-12','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week32_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-08-13','YYYY-MM-DD') AND to_date('2022-08-19','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week33_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-08-20','YYYY-MM-DD') AND to_date('2022-08-26','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week34_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-08-27','YYYY-MM-DD') AND to_date('2022-09-02','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week35_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-09-03','YYYY-MM-DD') AND to_date('2022-09-09','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week36_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-09-10','YYYY-MM-DD') AND to_date('2022-09-16','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week37_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-09-17','YYYY-MM-DD') AND to_date('2022-09-23','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week38_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-09-24','YYYY-MM-DD') AND to_date('2022-09-30','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week39_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-10-01','YYYY-MM-DD') AND to_date('2022-10-07','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week40_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-10-08','YYYY-MM-DD') AND to_date('2022-10-14','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week41_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-10-15','YYYY-MM-DD') AND to_date('2022-10-21','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week42_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-10-22','YYYY-MM-DD') AND to_date('2022-10-28','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week43_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-10-29','YYYY-MM-DD') AND to_date('2022-11-04','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week44_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-11-05','YYYY-MM-DD') AND to_date('2022-11-11','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week45_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-11-12','YYYY-MM-DD') AND to_date('2022-11-18','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week46_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-11-19','YYYY-MM-DD') AND to_date('2022-11-25','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week47_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-11-26','YYYY-MM-DD') AND to_date('2022-12-02','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week48_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-12-03','YYYY-MM-DD') AND to_date('2022-12-09','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week49_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-12-10','YYYY-MM-DD') AND to_date('2022-12-16','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week50_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-12-17','YYYY-MM-DD') AND to_date('2022-12-23','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week51_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-12-24','YYYY-MM-DD') AND to_date('2022-12-30','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week52_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2022-12-31','YYYY-MM-DD') AND to_date('2023-01-06','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week53_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-01-07','YYYY-MM-DD') AND to_date('2023-01-13','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week54_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-01-14','YYYY-MM-DD') AND to_date('2023-01-20','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week55_count
			, sum(CASE 
				WHEN trunc(eh.posted) BETWEEN to_date('2023-01-21','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD') THEN 1 ELSE 0
			END) AS week56_count
		FROM equipment_history eh 
		where 
			removed is null
			and eq_class = 'CTR'
			AND wtask_id IN 
				(select id
					from terminal_events
					where 
						event_group in ('GATE')
						and required is not null	
					AND eh.posted BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-01-27','YYYY-MM-DD')
				)
/*		GROUP BY 
			EXTRACT (YEAR FROM eh.posted)
			, EXTRACT (MONTH FROM eh.posted)
		ORDER BY 
			EXTRACT (YEAR FROM eh.posted)
			, EXTRACT (MONTH FROM eh.posted)
*/	)
SELECT 1 AS week_no, r.week1_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 2 AS week_no, r.week2_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 3 AS week_no, r.week3_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 4 AS week_no, r.week4_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 5 AS week_no, r.week5_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 6 AS week_no, r.week6_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 7 AS week_no, r.week7_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 8 AS week_no, r.week8_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 9 AS week_no, r.week9_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 10 AS week_no, r.week10_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 11 AS week_no, r.week11_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 12 AS week_no, r.week12_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 13 AS week_no, r.week13_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 14 AS week_no, r.week14_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 15 AS week_no, r.week15_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 16 AS week_no, r.week16_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 17 AS week_no, r.week17_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 18 AS week_no, r.week18_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 19 AS week_no, r.week19_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 20 AS week_no, r.week20_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 21 AS week_no, r.week21_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 22 AS week_no, r.week22_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 23 AS week_no, r.week23_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 24 AS week_no, r.week24_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 25 AS week_no, r.week25_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 26 AS week_no, r.week26_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 27 AS week_no, r.week27_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 28 AS week_no, r.week28_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 29 AS week_no, r.week29_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 30 AS week_no, r.week30_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 31 AS week_no, r.week31_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 32 AS week_no, r.week32_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 33 AS week_no, r.week33_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 34 AS week_no, r.week34_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 35 AS week_no, r.week35_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 36 AS week_no, r.week36_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 37 AS week_no, r.week37_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 38 AS week_no, r.week38_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 39 AS week_no, r.week39_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 40 AS week_no, r.week40_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 41 AS week_no, r.week41_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 42 AS week_no, r.week42_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 43 AS week_no, r.week43_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 44 AS week_no, r.week44_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 45 AS week_no, r.week45_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 46 AS week_no, r.week46_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 47 AS week_no, r.week47_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 48 AS week_no, r.week48_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 49 AS week_no, r.week49_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 50 AS week_no, r.week50_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 51 AS week_no, r.week51_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 52 AS week_no, r.week52_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 53 AS week_no, r.week53_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 54 AS week_no, r.week54_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 55 AS week_no, r.week55_count AS volume FROM dual CROSS JOIN results r
UNION ALL
SELECT 56 AS week_no, r.week56_count AS volume FROM dual CROSS JOIN results r
ORDER BY 
	week_no
;
