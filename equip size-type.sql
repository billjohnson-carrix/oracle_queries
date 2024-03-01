-- The query from task 432 which is unnecessarily complicated
-- The unnecssarily complicated bit that I want to remove is the sztp_to_len table.
-- The equipment_size_types table from Mainsail can be used instead.
WITH 
	sztp_to_len AS (
		SELECT 
			sztp_id, len
		FROM (
			SELECT 
				t2.sztp_id
				, t2.len
				, t2.cnt
				, ROW_NUMBER() OVER (PARTITION BY t2.sztp_id ORDER BY t2.cnt DESC) AS rn
			FROM (
				SELECT 
					t1.*
					, et.name
					, est.name
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
					) t1 
				JOIN equipment_types et ON t1.sztp_eqtp_id = et.id
				JOIN EQUIPMENT_SIZE_TYPES est ON t1.sztp_id = est.id
				WHERE NOT t1.sztp_eqtp_id = 'RT' AND NOT t1.sztp_eqtp_id = 'PP'
				) t2 
			)
		WHERE rn = 1
	)
SELECT 
  EXTRACT(MONTH FROM t3.posted) AS MONTH,
  COUNT(CASE WHEN t3.wtask_id = 'LOAD' AND t3.transship IS NULL THEN t3.wtask_id END) AS exports,
  SUM(CASE WHEN t3.wtask_id = 'LOAD' AND t3.transship IS NULL THEN t3.TEU END) AS exports_TEUS,
  COUNT(CASE WHEN t3.wtask_id = 'UNLOAD' AND t3.transship IS NULL THEN t3.wtask_id END) AS imports,
  SUM(CASE WHEN t3.wtask_id = 'UNLOAD' AND t3.transship IS NULL THEN t3.TEU END) AS imports_TEUS,
  COUNT(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD') AND t3.transship IS NOT NULL THEN t3.wtask_id END) AS transships,
  SUM(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD') AND t3.transship IS NOT NULL THEN t3.TEU END) AS transships_TEUS,
  COUNT(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD')THEN t3.wtask_id END) AS total,
  SUM(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD')THEN t3.TEU END) AS total_TEU
FROM ( 
	SELECT
		sztp_to_len.len
		, sztp_to_len.len / 20 AS TEU
		, eh.sztp_id
		, eh.*
	FROM equipment_history eh
	JOIN sztp_to_len ON eh.sztp_id = sztp_to_len.sztp_id
	WHERE EXTRACT(YEAR FROM posted) = 2023
	) t3
GROUP BY EXTRACT (MONTH FROM t3.posted)
ORDER BY EXTRACT (MONTH FROM t3.posted)
;

-- The simpler query
SELECT 
  EXTRACT(MONTH FROM t3.posted) AS MONTH,
  COUNT(CASE WHEN t3.wtask_id = 'LOAD' AND t3.transship IS NULL THEN t3.wtask_id END) AS exports,
  SUM(CASE WHEN t3.wtask_id = 'LOAD' AND t3.transship IS NULL THEN t3.TEU END) AS exports_TEUS,
  COUNT(CASE WHEN t3.wtask_id = 'UNLOAD' AND t3.transship IS NULL THEN t3.wtask_id END) AS imports,
  SUM(CASE WHEN t3.wtask_id = 'UNLOAD' AND t3.transship IS NULL THEN t3.TEU END) AS imports_TEUS,
  COUNT(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD') AND t3.transship IS NOT NULL THEN t3.wtask_id END) AS transships,
  SUM(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD') AND t3.transship IS NOT NULL THEN t3.TEU END) AS transships_TEUS,
  COUNT(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD')THEN t3.wtask_id END) AS total,
  SUM(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD')THEN t3.TEU END) AS total_TEU
FROM ( 
	SELECT
		est.eqsz_id
		, est.eqsz_id / 20 AS TEU
		, eh.sztp_id
		, eh.*
	FROM equipment_history eh
	JOIN equipment_size_types est ON eh.sztp_id = est.id
	WHERE EXTRACT(YEAR FROM posted) = 2023
		AND NOT est.eqtp_id = 'RT' AND NOT est.eqtp_id = 'PP'
	) t3
GROUP BY EXTRACT (MONTH FROM t3.posted)
ORDER BY EXTRACT (MONTH FROM t3.posted)
;

-- Attempt at even simpler query
SELECT 
  EXTRACT(MONTH FROM t3.posted) AS MONTH,
  COUNT(CASE WHEN t3.wtask_id = 'LOAD' AND t3.transship IS NULL THEN t3.wtask_id END) AS exports,
  SUM(CASE WHEN t3.wtask_id = 'LOAD' AND t3.transship IS NULL THEN t3.TEU END) AS exports_TEUS,
  COUNT(CASE WHEN t3.wtask_id = 'UNLOAD' AND t3.transship IS NULL THEN t3.wtask_id END) AS imports,
  SUM(CASE WHEN t3.wtask_id = 'UNLOAD' AND t3.transship IS NULL THEN t3.TEU END) AS imports_TEUS,
  COUNT(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD') AND t3.transship IS NOT NULL THEN t3.wtask_id END) AS transships,
  SUM(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD') AND t3.transship IS NOT NULL THEN t3.TEU END) AS transships_TEUS,
  COUNT(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD')THEN t3.wtask_id END) AS total,
  SUM(CASE WHEN (t3.wtask_id = 'LOAD' OR t3.wtask_id = 'UNLOAD')THEN t3.TEU END) AS total_TEU
FROM ( 
	SELECT
		est.eqsz_id
		, est.eqsz_id / 20 AS TEU
		, eh.sztp_id
		, eh.posted
		, eh.wtask_id
		, eh.transship
	FROM equipment_history eh
	JOIN equipment_size_types est ON eh.sztp_id = est.id
	WHERE EXTRACT(YEAR FROM posted) = 2023
		AND NOT est.eqtp_id = 'RT' AND NOT est.eqtp_id = 'PP'
	) t3
GROUP BY EXTRACT (MONTH FROM t3.posted)
ORDER BY EXTRACT (MONTH FROM t3.posted)
;

-- Further simplifications
SELECT
  EXTRACT(MONTH FROM eh.posted) AS MONTH,
  COUNT(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN eh.wtask_id END) AS exports,
  SUM(CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN est.eqsz_id / 20 END) AS exports_TEUS,
  COUNT(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN eh.wtask_id END) AS imports,
  SUM(CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN est.eqsz_id / 20 END) AS imports_TEUS,
  COUNT(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN eh.wtask_id END) AS transships,
  SUM(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN est.eqsz_id / 20 END) AS transships_TEUS,
  COUNT(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')THEN eh.wtask_id END) AS total,
  SUM(CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')THEN est.eqsz_id / 20 END) AS total_TEU
FROM equipment_history eh
JOIN equipment_size_types est ON eh.sztp_id = est.id
WHERE EXTRACT(YEAR FROM posted) = 2023
	AND NOT est.eqtp_id = 'RT' AND NOT est.eqtp_id = 'PP'
GROUP BY EXTRACT (MONTH FROM eh.posted)
ORDER BY EXTRACT (MONTH FROM eh.posted)
;