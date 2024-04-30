--Starting with MIT UAT
--Basic throughput query, still needs to be broken down by line
--Query to count moves by exports, imports, and transships 
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
			ELSE 0
		END) AS ONE
	, sum (
		CASE 
			WHEN NOT (line_id IN ('CHQ','CMD','COS','OOL','HLC','MAE','SEA','SUD','MSC','ONE','SEB')) THEN 1
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