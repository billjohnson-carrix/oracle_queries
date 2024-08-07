--Starting with MIT UAT
SELECT
	line_id
	, count(*)
FROM equipment_history 
WHERE 
	EXTRACT(YEAR FROM posted) = 2023
	AND EXTRACT(MONTH FROM posted) < 10
	AND NOT EXTRACT (MONTH FROM posted) = 3
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY line_id
ORDER BY 2 DESC;
	
SELECT
	EXTRACT(YEAR FROM posted) AS YEAR
	, EXTRACT(MONTH FROM posted) AS MONTH
	, sum (
		CASE 
			WHEN line_id = 'CHQ' THEN 1
			ELSE 0
		END) AS chiquita
	, sum (
		CASE 
			WHEN line_id = 'CMD' THEN 1
			ELSE 0
		END) AS cmacgm
	, sum (
		CASE 
			WHEN line_id = 'COS' THEN 1
			WHEN line_id = 'OOL' THEN 1
			ELSE 0
		END) AS cosco
	, sum (
		CASE
			WHEN line_id = 'HLC' THEN 1
			ELSE 0
		END) AS Hapag_Lloyd
	, sum 
		(CASE 
			WHEN line_id = 'MAE' THEN 1
			WHEN line_id = 'SEA' THEN 1
			WHEN line_id = 'SUD' THEN 1
			ELSE 0
		END) AS maersk_group
	, sum (
		CASE 
			WHEN line_id = 'MSC' THEN 1
			ELSE 0
		END) AS MSC
	, sum (
		CASE 
			WHEN line_id = 'ONE' THEN 1
			WHEN line_id = 'NYK' THEN 1
			WHEN line_id = 'MOL' THEN 1
			ELSE 0
		END) AS ONE
	, sum (
		CASE 
			WHEN NOT (line_id IN ('CHQ','CMD','COS','OOL','HLC','MAE','SEA','SUD','MSC','ONE','SEB','NYK','MOL')) THEN 1
			ELSE 0
		END) AS OTHERS
	, sum (
		CASE 
			WHEN line_id = 'SEB' THEN 1
			ELSE 0
		END) AS Seaboard
FROM equipment_history eh  
WHERE 
	EXTRACT(YEAR FROM posted) = 2023
	AND EXTRACT(MONTH FROM posted) < 10
	AND NOT EXTRACT (MONTH FROM posted) = 3
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY 
	EXTRACT(YEAR FROM posted)
	, EXTRACT(MONTH FROM posted)
ORDER BY
	EXTRACT(YEAR FROM posted)
	, EXTRACT(MONTH FROM posted)
; 

-- Switching to ZLO UAT 2
SELECT
	line_id
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 1 THEN 1 ELSE 0 END) AS Jan_23
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 2 THEN 1 ELSE 0 END) AS Feb_23
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 3 THEN 1 ELSE 0 END) AS Mar_23
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 4 THEN 1 ELSE 0 END) AS Apr_23
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 5 THEN 1 ELSE 0 END) AS May_23
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 6 THEN 1 ELSE 0 END) AS Jun_23
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 7 THEN 1 ELSE 0 END) AS Jul_23
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 8 THEN 1 ELSE 0 END) AS Aug_23
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) <= 8 THEN 1 ELSE 0 END) AS total
FROM equipment_history 
WHERE 
	EXTRACT(YEAR FROM posted) = 2023
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY line_id
ORDER BY 10 DESC;

SELECT
	line_id
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 1 THEN 1 ELSE 0 END) AS Jan_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 2 THEN 1 ELSE 0 END) AS Feb_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 3 THEN 1 ELSE 0 END) AS Mar_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 4 THEN 1 ELSE 0 END) AS Apr_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 5 THEN 1 ELSE 0 END) AS May_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 6 THEN 1 ELSE 0 END) AS Jun_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 7 THEN 1 ELSE 0 END) AS Jul_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 8 THEN 1 ELSE 0 END) AS Aug_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 9 THEN 1 ELSE 0 END) AS Sep_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 10 THEN 1 ELSE 0 END) AS Oct_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 11 THEN 1 ELSE 0 END) AS Nov_22
	, sum (CASE WHEN EXTRACT (MONTH FROM posted) = 12 THEN 1 ELSE 0 END) AS Dec_22
	, count(*) AS total
FROM equipment_history 
WHERE 
	EXTRACT(YEAR FROM posted) = 2022
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY line_id
ORDER BY 14 DESC
;

--Switching to PAM UAT
--Good data from Mar 2021 through Mar 2023
 SELECT
	line_id
	, count(*)
FROM equipment_history 
WHERE 
	(	(EXTRACT(YEAR FROM posted) = 2021 AND EXTRACT (MONTH FROM posted) >= 3)
	 OR (EXTRACT (YEAR FROM posted) = 2022)
	 OR (EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) <=3))
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY line_id
ORDER BY 2 DESC;

--Switching to PCT UAT
--Good data from Mar '22 through Dec '23
--Net throughput by month and line
SELECT
 	EXTRACT (YEAR FROM posted) AS year
 	, EXTRACT (MONTH FROM posted) AS month
	, line_id AS line
	, count(*) AS volume
FROM equipment_history 
WHERE 
	((EXTRACT(YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) >= 3)
	 OR (EXTRACT (YEAR FROM posted) = 2023))
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY
 	EXTRACT (YEAR FROM posted)
 	, EXTRACT (MONTH FROM posted)
	, line_id
ORDER BY 1, 2, 3
;

--Net throughput by line over months Mar '22 through Dec '23
SELECT 
	line_id
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 3 THEN 1 ELSE 0 END) AS Mar_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 4 THEN 1 ELSE 0 END) AS Apr_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 5 THEN 1 ELSE 0 END) AS May_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 6 THEN 1 ELSE 0 END) AS Jun_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 7 THEN 1 ELSE 0 END) AS Jul_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 8 THEN 1 ELSE 0 END) AS Aug_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 9 THEN 1 ELSE 0 END) AS Sep_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 10 THEN 1 ELSE 0 END) AS Oct_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 11 THEN 1 ELSE 0 END) AS Nov_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 12 THEN 1 ELSE 0 END) AS Dec_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 1 THEN 1 ELSE 0 END) AS Jan_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 2 THEN 1 ELSE 0 END) AS Feb_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 3 THEN 1 ELSE 0 END) AS Mar_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 4 THEN 1 ELSE 0 END) AS Apr_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 5 THEN 1 ELSE 0 END) AS May_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 6 THEN 1 ELSE 0 END) AS Jun_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 7 THEN 1 ELSE 0 END) AS Jul_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 8 THEN 1 ELSE 0 END) AS Aug_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 9 THEN 1 ELSE 0 END) AS Sep_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 10 THEN 1 ELSE 0 END) AS Oct_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 11 THEN 1 ELSE 0 END) AS Nov_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 12 THEN 1 ELSE 0 END) AS Dec_2023
	, count(*) AS Total
FROM equipment_history
WHERE 
	((EXTRACT(YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) >= 3)
	 OR (EXTRACT (YEAR FROM posted) = 2023))
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY line_id
ORDER BY 24 DESC 
;

--Switching to T5S UAT
--Good data from Feb '22 - Dec '22
--Net throughput by month and line
SELECT
 	EXTRACT (YEAR FROM posted) AS year
 	, EXTRACT (MONTH FROM posted) AS month
	, line_id AS line
	, count(*) AS volume
FROM equipment_history 
WHERE 
	EXTRACT(YEAR FROM posted) = 2022 
	AND EXTRACT (MONTH FROM posted) >= 2
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY
 	EXTRACT (YEAR FROM posted)
 	, EXTRACT (MONTH FROM posted)
	, line_id
ORDER BY 1, 2, 3
;

--Net throughput by line over months Mar '22 through Dec '23
SELECT 
	line_id
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 3 THEN 1 ELSE 0 END) AS Mar_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 4 THEN 1 ELSE 0 END) AS Apr_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 5 THEN 1 ELSE 0 END) AS May_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 6 THEN 1 ELSE 0 END) AS Jun_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 7 THEN 1 ELSE 0 END) AS Jul_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 8 THEN 1 ELSE 0 END) AS Aug_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 9 THEN 1 ELSE 0 END) AS Sep_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 10 THEN 1 ELSE 0 END) AS Oct_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 11 THEN 1 ELSE 0 END) AS Nov_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 12 THEN 1 ELSE 0 END) AS Dec_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 1 THEN 1 ELSE 0 END) AS Jan_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 2 THEN 1 ELSE 0 END) AS Feb_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 3 THEN 1 ELSE 0 END) AS Mar_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 4 THEN 1 ELSE 0 END) AS Apr_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 5 THEN 1 ELSE 0 END) AS May_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 6 THEN 1 ELSE 0 END) AS Jun_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 7 THEN 1 ELSE 0 END) AS Jul_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 8 THEN 1 ELSE 0 END) AS Aug_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 9 THEN 1 ELSE 0 END) AS Sep_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 10 THEN 1 ELSE 0 END) AS Oct_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 11 THEN 1 ELSE 0 END) AS Nov_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 12 THEN 1 ELSE 0 END) AS Dec_2023
	, count(*) AS Total
FROM equipment_history
WHERE 
	((EXTRACT(YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) >= 3)
	 OR (EXTRACT (YEAR FROM posted) = 2023))
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY line_id
ORDER BY 24 DESC 
;

--Switching to T18 PROD
--Let's look at 2022 and 2023
--Net throughput by month and line
SELECT
 	EXTRACT (YEAR FROM posted) AS year
 	, EXTRACT (MONTH FROM posted) AS month
	, line_id AS line
	, count(*) AS volume
FROM equipment_history 
WHERE 
	(EXTRACT(YEAR FROM posted) = 2023
	 OR EXTRACT(YEAR FROM posted) = 2022)
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY
 	EXTRACT (YEAR FROM posted)
 	, EXTRACT (MONTH FROM posted)
	, line_id
ORDER BY 1, 2, 3
;

--Net throughput by line over months Mar '22 through Dec '23
SELECT 
	line_id
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 3 THEN 1 ELSE 0 END) AS Mar_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 4 THEN 1 ELSE 0 END) AS Apr_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 5 THEN 1 ELSE 0 END) AS May_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 6 THEN 1 ELSE 0 END) AS Jun_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 7 THEN 1 ELSE 0 END) AS Jul_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 8 THEN 1 ELSE 0 END) AS Aug_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 9 THEN 1 ELSE 0 END) AS Sep_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 10 THEN 1 ELSE 0 END) AS Oct_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 11 THEN 1 ELSE 0 END) AS Nov_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) = 12 THEN 1 ELSE 0 END) AS Dec_2022
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 1 THEN 1 ELSE 0 END) AS Jan_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 2 THEN 1 ELSE 0 END) AS Feb_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 3 THEN 1 ELSE 0 END) AS Mar_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 4 THEN 1 ELSE 0 END) AS Apr_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 5 THEN 1 ELSE 0 END) AS May_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 6 THEN 1 ELSE 0 END) AS Jun_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 7 THEN 1 ELSE 0 END) AS Jul_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 8 THEN 1 ELSE 0 END) AS Aug_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 9 THEN 1 ELSE 0 END) AS Sep_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 10 THEN 1 ELSE 0 END) AS Oct_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 11 THEN 1 ELSE 0 END) AS Nov_2023
	, sum(CASE WHEN EXTRACT (YEAR FROM posted) = 2023 AND EXTRACT (MONTH FROM posted) = 12 THEN 1 ELSE 0 END) AS Dec_2023
	, count(*) AS Total
FROM equipment_history
WHERE 
	((EXTRACT(YEAR FROM posted) = 2022 AND EXTRACT (MONTH FROM posted) >= 3)
	 OR (EXTRACT (YEAR FROM posted) = 2023))
	AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
GROUP BY line_id
ORDER BY 24 DESC 
;
