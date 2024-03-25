SELECT 
	* 
FROM truck_visits_jn jn
WHERE 
	(jn.jn_operation = 'INS' OR jn.JN_OPERATION = 'UPD') AND 
	jn.entered IS NOT NULL AND jn.exited IS NOT NULL
	AND jn.exited BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-12-31','YYYY-MM-DD')
	--AND jn.trk_id = '679128PA'
ORDER BY 
	jn.trk_id
	, jn.JN_DATETIME 
FETCH FIRST 20 ROWS ONLY 
;

SELECT jn.jn_operation, count(*) FROM truck_visits_jn jn GROUP BY jn.jn_operation;

SELECT * FROM truck_visits_jn WHERE gkey = '8816364' ORDER BY jn_datetime;

SELECT creator, count(*) FROM truck_visits_jn WHERE NOT(jn_operation='DEL') GROUP BY creator ORDER BY 2 desc;
SELECT jn_appln, count(*) FROM truck_visits_jn WHERE NOT(jn_operation='DEL') GROUP BY jn_appln ORDER BY 2 DESC;

SELECT * FROM jn_appln FETCH FIRST 20 ROWS ONLY ;

SELECT jn_oracle_user, jn_appln, count(*)
  FROM truck_visits_jn
 WHERE NOT (jn_operation = 'DEL')
 GROUP BY jn_oracle_user, jn_appln
 ORDER BY 1,2 DESC;

--Processes responsible for populating the entered datetime
WITH 
	ordered_rows AS (
	SELECT tvjn.gkey,
	       tvjn.jn_datetime,
	       tvjn.JN_ORACLE_USER,
	       tvjn.JN_APPLN,
	       tvjn.entered,
	       ROW_NUMBER() OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS rn
	FROM truck_visits_jn tvjn
	WHERE 
		tvjn.entered IS NOT NULL AND 
		NOT (tvjn.JN_OPERATION = 'DEL')
	)
SELECT
	orows.jn_oracle_user
	, orows.jn_appln
	, count(*)
FROM ordered_rows orows
WHERE rn = 1
GROUP BY 
	orows.jn_oracle_user
	, orows.jn_appln
ORDER BY 
	orows.jn_oracle_user
	, orows.jn_appln
;

SELECT 
	*
FROM truck_visits_jn tvjn
WHERE
	NOT (tvjn.JN_OPERATION = 'DEL')
ORDER BY 
	tvjn.gkey
	, tvjn.JN_DATETIME 
FETCH FIRST 200 ROWS ONLY 
;

--Processes responsible for populating the exited datetime
WITH 
	ordered_rows AS (
	SELECT tvjn.gkey,
	       tvjn.jn_datetime,
	       tvjn.JN_ORACLE_USER,
	       tvjn.JN_APPLN,
	       tvjn.guard_verified,
	       ROW_NUMBER() OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS rn
	FROM truck_visits_jn tvjn
	WHERE 
		tvjn.guard_verified IS NOT NULL AND 
		NOT (tvjn.JN_OPERATION = 'DEL')
	)
SELECT
	orows.jn_oracle_user
	, orows.jn_appln
	, count(*)
FROM ordered_rows orows
WHERE rn = 1
GROUP BY 
	orows.jn_oracle_user
	, orows.jn_appln
ORDER BY 
	orows.jn_oracle_user
	, orows.jn_appln
;

SELECT count(*) FROM truck_visits_jn WHERE NOT (jn_operation = 'DEL');

--All timestamp population events, categorized and counted
WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL')
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
*/	), timestamp_actions AS (
		SELECT
			pv.gkey
			, pv.jn_datetime
			, pv.jn_oracle_user
			, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
			, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
			, pv.queued
			, pv.previous_queued
			, pv.entered
			, pv.previous_entered
			, pv.exited
			, pv.previous_exited
			, pv.guard_verified
			, pv.previous_g_verified
			, CASE 
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 			 	THEN 'All' 
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'All but guard_verified'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL				THEN 'All but exited'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but entered'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but queued'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and entered'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and exited'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Queued and guard_verified'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Entered and exited'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Entered and guard_verified'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Exited and guard_verified' 
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'Entered'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Exited'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Guard_verified' 
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL				THEN 'Exited and guard_verified destroyed'
			  END AS timestamps_populated
		FROM previous_values pv
		WHERE 
			(pv.queued IS NOT NULL AND pv.previous_queued IS null) OR 
			(pv.entered IS NOT NULL AND pv.previous_entered IS null) OR 
			(pv.exited IS NOT NULL AND pv.previous_exited IS null) OR 
			(pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS null)
/*		ORDER BY 
			13
			, pv.gkey
			, pv.jn_datetime
*/	)
SELECT 
	ta.timestamps_populated
	, ta.jn_oracle_user_type
	, ta.jn_appln_type
	, count(*)	
FROM timestamp_actions ta
GROUP BY 
	ta.timestamps_populated
	, ta.jn_oracle_user_type
	, ta.jn_appln_type
ORDER BY 4 DESC 
;

SELECT 
	*
FROM truck_visits_jn tvjn
WHERE 
	tvjn.gkey = '19638650'
ORDER BY 
	tvjn.JN_DATETIME 
;

--Now looking at ZLO production
SELECT * FROM truck_visits_jn FETCH FIRST 20 ROWS ONLY ;

SELECT 
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
	, tvjn.jn_oracle_user
	, tvjn.jn_appln
	, tvjn.queued
	, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
	, tvjn.entered
	, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
	, tvjn.exited
	, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
	, tvjn.guard_verified
	, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
FROM truck_visits_jn tvjn
WHERE 
	NOT (tvjn.jn_operation = 'DEL')
ORDER BY 
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
--FETCH FIRST 20 ROWS ONLY 
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL') AND
			EXTRACT (YEAR FROM COALESCE (tvjn.exited, tvjn.guard_verified, tvjn.entered, tvjn.queued)) = 2023 AND 
			EXTRACT (MONTH FROM COALESCE (tvjn.exited, tvjn.guard_verified, tvjn.entered, tvjn.queued)) >= 7
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
*/	)
SELECT
	pv.gkey
	, pv.jn_datetime
	, pv.jn_oracle_user
	, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
	, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
	, pv.queued
	, pv.previous_queued
	, pv.entered
	, pv.previous_entered
	, pv.exited
	, pv.previous_exited
	, pv.guard_verified
	, pv.previous_g_verified
	, CASE 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 			 	THEN 'All' 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'All but guard_verified'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL				THEN 'All but exited'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but entered'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but queued'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and entered'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and exited'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Queued and guard_verified'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Entered and exited'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Entered and guard_verified'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Exited and guard_verified' 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'Entered'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Exited'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Guard_verified' 
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL				THEN 'Exited and guard_verified destroyed'
	  END AS timestamps_populated
FROM previous_values pv
WHERE 
	(pv.queued IS NOT NULL AND pv.previous_queued IS null) OR 
	(pv.entered IS NOT NULL AND pv.previous_entered IS null) OR 
	(pv.exited IS NOT NULL AND pv.previous_exited IS null) OR 
	(pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS null)
ORDER BY 
	13
	, pv.gkey
	, pv.jn_datetime
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL') AND
			EXTRACT (YEAR FROM COALESCE (tvjn.exited, tvjn.guard_verified, tvjn.entered, tvjn.queued)) = 2023 AND 
			EXTRACT (MONTH FROM COALESCE (tvjn.exited, tvjn.guard_verified, tvjn.entered, tvjn.queued)) = 12
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
*/	)
SELECT
	pv.gkey
	, pv.jn_datetime
	, pv.jn_oracle_user
	, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
	, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
	, pv.queued
	, pv.previous_queued
	, pv.entered
	, pv.previous_entered
	, pv.exited
	, pv.previous_exited
	, pv.guard_verified
	, pv.previous_g_verified
	, CASE 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 			 	THEN 'All' 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'All but guard_verified'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL				THEN 'All but exited'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but entered'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but queued'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and entered'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and exited'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Queued and guard_verified'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Entered and exited'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Entered and guard_verified'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Exited and guard_verified' 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'Entered'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Exited'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Guard_verified' 
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL				THEN 'Exited and guard_verified destroyed'
		WHEN pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND 
				pv.exited > pv.previous_exited 												THEN 'Updated exited timestamp'
	  END AS timestamps_populated
FROM previous_values pv
WHERE 
	(pv.queued IS NOT NULL AND pv.previous_queued IS null) OR 
	(pv.entered IS NOT NULL AND pv.previous_entered IS null) OR 
	(pv.exited IS NOT NULL AND pv.previous_exited IS null) OR 
	(pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS null)
ORDER BY 
	13
	, pv.gkey
	, pv.jn_datetime
;

--Now looking at T18
SELECT * FROM truck_visits_jn FETCH FIRST 20 ROWS ONLY ;

SELECT 
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
	, tvjn.jn_oracle_user
	, tvjn.jn_appln
	, tvjn.queued
	, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
	, tvjn.entered
	, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
	, tvjn.exited
	, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
	, tvjn.guard_verified
	, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
FROM truck_visits_jn tvjn
WHERE 
	NOT (tvjn.jn_operation = 'DEL')
ORDER BY 
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
--FETCH FIRST 20 ROWS ONLY 
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL') AND
			EXTRACT (YEAR FROM COALESCE (tvjn.exited, tvjn.guard_verified, tvjn.entered, tvjn.queued)) = 2023 AND 
			EXTRACT (MONTH FROM COALESCE (tvjn.exited, tvjn.guard_verified, tvjn.entered, tvjn.queued)) >= 7
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
*/	)
SELECT
	pv.gkey
	, pv.jn_datetime
	, pv.jn_oracle_user
	, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
	, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
	, pv.queued
	, pv.previous_queued
	, pv.entered
	, pv.previous_entered
	, pv.exited
	, pv.previous_exited
	, pv.guard_verified
	, pv.previous_g_verified
	, CASE 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 			 	THEN 'All' 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'All but guard_verified'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL				THEN 'All but exited'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but entered'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but queued'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and entered'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and exited'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Queued and guard_verified'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Entered and exited'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Entered and guard_verified'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Exited and guard_verified' 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'Entered'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Exited'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Guard_verified' 
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL				THEN 'Exited and guard_verified destroyed'
	  END AS timestamps_populated
FROM previous_values pv
WHERE 
	(pv.queued IS NOT NULL AND pv.previous_queued IS null) OR 
	(pv.entered IS NOT NULL AND pv.previous_entered IS null) OR 
	(pv.exited IS NOT NULL AND pv.previous_exited IS null) OR 
	(pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS null)
ORDER BY 
	13
	, pv.gkey
	, pv.jn_datetime
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL')
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
*/	), timestamp_actions AS (
		SELECT
			pv.gkey
			, pv.jn_datetime
			, pv.jn_oracle_user
			, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
			, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
			, pv.queued
			, pv.previous_queued
			, pv.entered
			, pv.previous_entered
			, pv.exited
			, pv.previous_exited
			, pv.guard_verified
			, pv.previous_g_verified
			, CASE 
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 			 	THEN 'All' 
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'All but guard_verified'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL				THEN 'All but exited'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but entered'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but queued'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and entered'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and exited'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Queued and guard_verified'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Entered and exited'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Entered and guard_verified'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Exited and guard_verified' 
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'Entered'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Exited'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Guard_verified' 
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL				THEN 'Exited and guard_verified destroyed'
			  END AS timestamps_populated
		FROM previous_values pv
		WHERE 
			(pv.queued IS NOT NULL AND pv.previous_queued IS null) OR 
			(pv.entered IS NOT NULL AND pv.previous_entered IS null) OR 
			(pv.exited IS NOT NULL AND pv.previous_exited IS null) OR 
			(pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS null)
/*		ORDER BY 
			13
			, pv.gkey
			, pv.jn_datetime
*/	)
SELECT 
	ta.timestamps_populated
	, ta.jn_oracle_user_type
	, ta.jn_appln_type
	, count(*)	
FROM timestamp_actions ta
GROUP BY 
	ta.timestamps_populated
	, ta.jn_oracle_user_type
	, ta.jn_appln_type
ORDER BY 1, 4 DESC 
;

--Now looking at Tacoma production
SELECT * FROM truck_visits_jn FETCH FIRST 20 ROWS ONLY ;

SELECT 
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
	, tvjn.jn_oracle_user
	, tvjn.jn_appln
	, tvjn.queued
	, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
	, tvjn.entered
	, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
	, tvjn.exited
	, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
	, tvjn.guard_verified
	, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
FROM truck_visits_jn tvjn
WHERE 
	NOT (tvjn.jn_operation = 'DEL')
ORDER BY 
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
--FETCH FIRST 20 ROWS ONLY 
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL') AND
			EXTRACT (YEAR FROM COALESCE (tvjn.exited, tvjn.guard_verified, tvjn.entered, tvjn.queued)) = 2023 AND 
			EXTRACT (MONTH FROM COALESCE (tvjn.exited, tvjn.guard_verified, tvjn.entered, tvjn.queued)) >= 7
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
*/	)
SELECT
	pv.gkey
	, pv.jn_datetime
	, pv.jn_oracle_user
	, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
	, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
	, pv.queued
	, pv.previous_queued
	, pv.entered
	, pv.previous_entered
	, pv.exited
	, pv.previous_exited
	, pv.guard_verified
	, pv.previous_g_verified
	, CASE 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 			 	THEN 'All' 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'All but guard_verified'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL				THEN 'All but exited'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but entered'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but queued'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and entered'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and exited'
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Queued and guard_verified'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Entered and exited'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Entered and guard_verified'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Exited and guard_verified' 
		WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'Entered'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
			 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Exited'
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
			 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
			 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Guard_verified' 
		WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
				OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
			 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
			 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
			 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
			 pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL				THEN 'Exited and guard_verified destroyed'
	  END AS timestamps_populated
FROM previous_values pv
WHERE 
	(pv.queued IS NOT NULL AND pv.previous_queued IS null) OR 
	(pv.entered IS NOT NULL AND pv.previous_entered IS null) OR 
	(pv.exited IS NOT NULL AND pv.previous_exited IS null) OR 
	(pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS null)
ORDER BY 
	13
	, pv.gkey
	, pv.jn_datetime
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL')
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
*/	), timestamp_actions AS (
		SELECT
			pv.gkey
			, pv.jn_datetime
			, pv.jn_oracle_user
			, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
			, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
			, pv.queued
			, pv.previous_queued
			, pv.entered
			, pv.previous_entered
			, pv.exited
			, pv.previous_exited
			, pv.guard_verified
			, pv.previous_g_verified
			, CASE 
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 			 	THEN 'All' 
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'All but guard_verified'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL				THEN 'All but exited'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but entered'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'All but queued'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and entered'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued and exited'
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Queued and guard_verified'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Entered and exited'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Entered and guard_verified'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Exited and guard_verified' 
				WHEN pv.queued IS NOT NULL AND pv.previous_queued IS NULL AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Queued'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 pv.entered IS NOT NULL AND pv.previous_entered IS NULL AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))	THEN 'Entered'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 ((pv.guard_verified IS NULL AND pv.previous_g_verified IS NULL) 
					 	OR (pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL))  THEN 'Exited'
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 ((pv.exited IS NULL AND pv.previous_exited IS NULL) 
					 	OR (pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL)) AND 
					 pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NULL 				THEN 'Guard_verified' 
				WHEN ((pv.queued IS NULL AND pv.previous_queued IS NULL) 
						OR (pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL)) AND 
					 ((pv.entered IS NULL AND pv.previous_entered IS NULL) 
					 	OR (pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL)) AND 
					 pv.exited IS NOT NULL AND pv.previous_exited IS NULL AND 
					 pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL				THEN 'Exited and guard_verified destroyed'
			  END AS timestamps_populated
		FROM previous_values pv
		WHERE 
			(pv.queued IS NOT NULL AND pv.previous_queued IS null) OR 
			(pv.entered IS NOT NULL AND pv.previous_entered IS null) OR 
			(pv.exited IS NOT NULL AND pv.previous_exited IS null) OR 
			(pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS null)
/*		ORDER BY 
			13
			, pv.gkey
			, pv.jn_datetime
*/	)
SELECT 
	ta.timestamps_populated
	, ta.jn_oracle_user_type
	, ta.jn_appln_type
	, count(*)	
FROM timestamp_actions ta
GROUP BY 
	ta.timestamps_populated
	, ta.jn_oracle_user_type
	, ta.jn_appln_type
ORDER BY 1, 4 DESC 
;

/*
 * I have recently realized that discovering what processes populate the timestamps is useful, but if the less-than-ideal practice of
 * allowing processes to update the timestamps is in effect, then Crow's Nest isn't interested so much in what process populates the
 * timestamps as what was the last process to update it.
 * 
 * ZLO commonly has a process called SPINNAKER populate the exited timestamp. This is a move completion event such as decking an export
 * container. I think it is likely that this is only the first and not the last update to the exited timestamp. I don't want to do exploratory
 * work in the ZLO production environment. Instead, I'll start with MIT, and then check ZLO, and then move on to PCT, T18, and TAM. 
*/

--MIT Prod, finding last updates to queued, entered, exited, and guard_verified.

SELECT 
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
	, tvjn.jn_oracle_user
	, tvjn.jn_appln
	, tvjn.queued
	, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
	, tvjn.entered
	, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
	, tvjn.exited
	, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
	, tvjn.guard_verified
	, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
FROM truck_visits_jn tvjn
WHERE 
	NOT (tvjn.jn_operation = 'DEL')
ORDER BY 
	tvjn.GKEY 
	, tvjn.JN_DATETIME
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL')
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME DESC 
*/	)
SELECT
	pv.gkey
	, pv.jn_datetime
	, pv.jn_oracle_user
	, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
	, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
	, pv.queued
	, pv.previous_queued
	, pv.entered
	, pv.previous_entered
	, pv.exited
	, pv.previous_exited
	, pv.guard_verified
	, pv.previous_g_verified
	, CASE 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'All but guard_verified'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but queued'
		WHEN 
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and entered'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Queued and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered and exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Entered and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Exited and guard_verified' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Guard_verified' 
	  END AS timestamps_updated
FROM previous_values pv
WHERE 
	(pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued))) OR 
	(pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered))) OR 
	(pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited))) OR 
	(pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified)))
ORDER BY 
	pv.gkey
	, pv.jn_datetime DESC 
	, 14
;

--Switching to ZLO prod

SELECT 
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
	, tvjn.jn_oracle_user
	, tvjn.jn_appln
	, tvjn.queued
	, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
	, tvjn.entered
	, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
	, tvjn.exited
	, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
	, tvjn.guard_verified
	, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
FROM truck_visits_jn tvjn
WHERE 
	NOT (tvjn.jn_operation = 'DEL')
	AND EXTRACT (YEAR FROM tvjn.jn_datetime) = 2023
	AND EXTRACT (MONTH FROM tvjn.jn_datetime) >= 7
ORDER BY 
	tvjn.GKEY 
	, tvjn.JN_DATETIME
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL')
			AND EXTRACT (YEAR FROM tvjn.jn_datetime) = 2023
			AND EXTRACT (MONTH FROM tvjn.jn_datetime) >= 7
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME DESC 
*/	)
SELECT
	pv.gkey
	, pv.jn_datetime
	, pv.jn_oracle_user
	, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
	, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
	, pv.queued
	, pv.previous_queued
	, pv.entered
	, pv.previous_entered
	, pv.exited
	, pv.previous_exited
	, pv.guard_verified
	, pv.previous_g_verified
	, CASE 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'All but guard_verified'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but queued'
		WHEN 
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and entered'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Queued and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered and exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Entered and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Exited and guard_verified' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NOT NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Guard_verified' 
	  END AS timestamps_updated
FROM previous_values pv
WHERE 
	(pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued))) OR 
	(pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered))) OR 
	(pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited))) OR 
	(pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified)))
ORDER BY 
	pv.gkey
	, pv.jn_datetime DESC 
	, 14
;

--Switching to PCT

SELECT 
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
	, tvjn.jn_oracle_user
	, tvjn.jn_appln
	, tvjn.queued
	, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
	, tvjn.entered
	, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
	, tvjn.exited
	, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
	, tvjn.guard_verified
	, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
FROM truck_visits_jn tvjn
WHERE 
	NOT (tvjn.jn_operation = 'DEL')
	AND EXTRACT (YEAR FROM tvjn.jn_datetime) = 2023
	AND EXTRACT (MONTH FROM tvjn.jn_datetime) >= 7
ORDER BY 
	tvjn.GKEY 
	, tvjn.JN_DATETIME
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL')
			AND EXTRACT (YEAR FROM tvjn.jn_datetime) = 2023
			AND EXTRACT (MONTH FROM tvjn.jn_datetime) >= 7
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME DESC 
*/	)
SELECT
	pv.gkey
	, pv.jn_datetime
	, pv.jn_oracle_user
	, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
	, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
	, pv.queued
	, pv.previous_queued
	, pv.entered
	, pv.previous_entered
	, pv.exited
	, pv.previous_exited
	, pv.guard_verified
	, pv.previous_g_verified
	, CASE 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'All but guard_verified'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but queued'
		WHEN 
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and entered'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Queued and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered and exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Entered and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Exited and guard_verified' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Guard_verified' 
		WHEN 
			pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL 
				THEN 'GV_destroyed'
		WHEN 
			pv.exited IS NULL AND pv.previous_exited IS NOT NULL 
				THEN 'Exited_destroyed'
	  END AS timestamps_updated
FROM previous_values pv
WHERE 
	(pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued))) OR 
	(pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered))) OR 
	(pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited))) OR 
	(pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified)))
ORDER BY 
	pv.gkey
	, pv.jn_datetime DESC 
	, 14
;

--Switching to T18

SELECT
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
	, tvjn.jn_oracle_user
	, tvjn.jn_appln
	, tvjn.queued
	, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
	, tvjn.entered
	, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
	, tvjn.exited
	, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
	, tvjn.guard_verified
	, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
FROM truck_visits_jn tvjn
WHERE 
	NOT (tvjn.jn_operation = 'DEL')
	AND EXTRACT (YEAR FROM tvjn.jn_datetime) = 2023
	AND EXTRACT (MONTH FROM tvjn.jn_datetime) >= 7
ORDER BY 
	tvjn.GKEY 
	, tvjn.JN_DATETIME
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL')
			AND EXTRACT (YEAR FROM tvjn.jn_datetime) = 2023
			AND EXTRACT (MONTH FROM tvjn.jn_datetime) >= 7
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME DESC 
*/	)
SELECT
	pv.gkey
	, pv.jn_datetime
	, pv.jn_oracle_user
	, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
	, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
	, pv.queued
	, pv.previous_queued
	, pv.entered
	, pv.previous_entered
	, pv.exited
	, pv.previous_exited
	, pv.guard_verified
	, pv.previous_g_verified
	, CASE 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'All but guard_verified'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but queued'
		WHEN 
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and entered'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Queued and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered and exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Entered and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Exited and guard_verified' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Guard_verified' 
		WHEN 
			pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL 
				THEN 'GV_destroyed'
		WHEN 
			pv.exited IS NULL AND pv.previous_exited IS NOT NULL 
				THEN 'Exited_destroyed'
	  END AS timestamps_updated
FROM previous_values pv
WHERE 
	(pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued))) OR 
	(pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered))) OR 
	(pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited))) OR 
	(pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified)))
ORDER BY 
	pv.gkey
	, pv.jn_datetime DESC 
	, 14
;

--Switching to Tacoma

SELECT
	tvjn.GKEY 
	, tvjn.JN_DATETIME 
	, tvjn.jn_oracle_user
	, tvjn.jn_appln
	, tvjn.queued
	, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
	, tvjn.entered
	, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
	, tvjn.exited
	, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
	, tvjn.guard_verified
	, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
FROM truck_visits_jn tvjn
WHERE 
	NOT (tvjn.jn_operation = 'DEL')
	AND EXTRACT (YEAR FROM tvjn.jn_datetime) = 2023
	AND EXTRACT (MONTH FROM tvjn.jn_datetime) >= 7
ORDER BY 
	tvjn.GKEY 
	, tvjn.JN_DATETIME
;

WITH 
	previous_values AS (
		SELECT 
			tvjn.GKEY 
			, tvjn.JN_DATETIME 
			, tvjn.jn_oracle_user
			, tvjn.jn_appln
			, tvjn.queued
			, lag (tvjn.queued) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_queued
			, tvjn.entered
			, lag (tvjn.entered) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_entered
			, tvjn.exited
			, lag (tvjn.exited) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_exited
			, tvjn.guard_verified
			, lag (tvjn.guard_verified) OVER (PARTITION BY tvjn.gkey ORDER BY tvjn.jn_datetime) AS previous_g_verified
		FROM truck_visits_jn tvjn
		WHERE 
			NOT (tvjn.jn_operation = 'DEL')
			AND EXTRACT (YEAR FROM tvjn.jn_datetime) = 2023
			AND EXTRACT (MONTH FROM tvjn.jn_datetime) >= 7
/*		ORDER BY 
			tvjn.GKEY 
			, tvjn.JN_DATETIME DESC 
*/	)
SELECT
	pv.gkey
	, pv.jn_datetime
	, pv.jn_oracle_user
	, CASE WHEN pv.jn_oracle_user LIKE 'KIT%' THEN 'KIT**' ELSE pv.jn_oracle_user END AS jn_oracle_user_type
	, CASE WHEN pv.jn_appln LIKE 'GAT___FW' THEN 'GAT***FW' ELSE pv.jn_appln END AS jn_appln_type
	, pv.queued
	, pv.previous_queued
	, pv.entered
	, pv.previous_entered
	, pv.exited
	, pv.previous_exited
	, pv.guard_verified
	, pv.previous_g_verified
	, CASE 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'All but guard_verified'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'All but queued'
		WHEN 
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and entered'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued and exited'
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Queued and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered and exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Entered and guard_verified'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Exited and guard_verified' 
		WHEN
			pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Queued'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Entered'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited)) AND 
			((pv.guard_verified IS NOT NULL AND pv.previous_g_verified IS NOT NULL AND pv.guard_verified = pv.previous_g_verified) OR 
			 (pv.guard_verified IS NULL AND pv.previous_g_verified IS null))
				THEN 'Exited'
		WHEN
			((pv.queued IS NOT NULL AND pv.previous_queued IS NOT NULL AND pv.queued = pv.previous_queued) OR 
			 (pv.queued IS NULL AND pv.previous_queued IS null)) AND 
			((pv.entered IS NOT NULL AND pv.previous_entered IS NOT NULL AND pv.entered = pv.previous_entered) OR 
			 (pv.entered IS NULL AND pv.previous_entered IS null)) AND 
			((pv.exited IS NOT NULL AND pv.previous_exited IS NOT NULL AND pv.exited = pv.previous_exited) OR 
			 (pv.exited IS NULL AND pv.previous_exited IS null)) AND 
			pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified))
				THEN 'Guard_verified' 
		WHEN 
			pv.guard_verified IS NULL AND pv.previous_g_verified IS NOT NULL 
				THEN 'GV_destroyed'
		WHEN 
			pv.exited IS NULL AND pv.previous_exited IS NOT NULL 
				THEN 'Exited_destroyed'
	  END AS timestamps_updated
FROM previous_values pv
WHERE 
	(pv.queued IS NOT NULL AND (pv.previous_queued IS NULL OR NOT (pv.queued = pv.previous_queued))) OR 
	(pv.entered IS NOT NULL AND (pv.previous_entered IS NULL OR NOT (pv.entered = pv.previous_entered))) OR 
	(pv.exited IS NOT NULL AND (pv.previous_exited IS NULL OR NOT (pv.exited = pv.previous_exited))) OR 
	(pv.guard_verified IS NOT NULL AND (pv.previous_g_verified IS NULL OR NOT (pv.guard_verified = pv.previous_g_verified)))
ORDER BY 
	pv.gkey
	, pv.jn_datetime DESC 
	, 14
;
