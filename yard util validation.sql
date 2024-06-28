SELECT * FROM equipment_jn_arc;

SELECT * FROM equipment_jn WHERE nbr = '100111NZ';

--Rebuilding the equipment table from equipment_jn
WITH 
	jn_entries AS (
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_id
			, loc_type
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
			--AND EXTRACT (YEAR FROM jn_datetime) = 2024
			--AND EXTRACT (MONTH FROM jn_datetime) = 2
	/*	UNION ALL 
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_class
			, loc_type
			, to_number (sztp_eqsz_id) / 20 AS teu_precise
			, CASE WHEN TO_number (sztp_eqsz_id) < 30 THEN 1 ELSE 2 END AS teu_whole
		FROM equipment_jn_arc
		WHERE 
			sztp_class = 'CTR'
			AND jn_entryid >= 229820141*/
/*		ORDER BY 
			nbr
			, jn_entryid*/
--		FETCH FIRST 100000 ROWS ONLY 
	), labeled_entries AS (
		SELECT
			jn_entries.*
			, jn_datetime AS effective
			, LEAD(jn_datetime,1,NULL) over (PARTITION BY nbr ORDER BY jn_entryid) AS expired
			, CASE 
				WHEN loc_type = 'Y' AND (LAG(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) IS NULL 
					OR NOT (LAG(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y')) THEN 'Enters'
				WHEN NOT (loc_type = 'Y') OR LAG(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y' THEN 'No entry'
			  END AS entry_label
			, CASE 
				WHEN loc_type = 'Y' AND LEAD(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) IS NULL THEN 'Current'
				WHEN NOT (loc_type = 'Y') AND lag(loc_type,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y' THEN 'Exits'
				WHEN loc_type = 'Y' OR lag(loc_type,1,null) OVER (PARTITION BY nbr order BY jn_entryid) IS NULL 
					OR NOT (lag(loc_type,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y') THEN 'No exit'
			  END AS exit_label
		FROM jn_entries
		/*ORDER BY 
			nbr
			, jn_entryid*/
	), inv_events AS (
		SELECT 
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_id
			, loc_type
			, effective
			, expired
			, entry_label
			, exit_label
		FROM 
			labeled_entries
		WHERE 
			entry_label = 'Enters'
			OR exit_label = 'Exits'
			OR exit_label = 'Current'
		/*ORDER BY 
			nbr
			, jn_entryid*/
), yard_durations AS (
		SELECT 
			nbr
			, sztp_id
			, CASE 
				WHEN entry_label = 'Enters' AND exit_label = 'Current' THEN jn_datetime
				WHEN nbr = LEAD(nbr,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) AND entry_label = 'Enters' THEN jn_datetime
				ELSE NULL 
			  END AS in_yard_datetime
			, CASE 
				WHEN entry_label = 'Enters' AND exit_label = 'Current' THEN trunc(sysdate) 
				WHEN nbr = lead(nbr,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) 
					AND lead(exit_label,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Exits' THEN lead(jn_datetime,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid)
				WHEN nbr = lead(nbr,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) 
					AND lead(exit_label,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Current' THEN  trunc(SYSDATE) 
				ELSE null
			  END AS out_yard_datetime
		FROM inv_events
		/*ORDER BY 
			nbr
			, jn_entryid*/
	), accum_snap AS (
		SELECT 
			*
		FROM yard_durations
		WHERE 
			in_yard_datetime IS NOT NULL
		/*ORDER BY 
			nbr
			, in_yard_datetime*/
	), DateSeries (date_col) AS (
	    SELECT TO_date('2023-01-01', 'YYYY-MM-DD') AS date_col
		    FROM dual
	    UNION ALL
	    SELECT date_col + INTERVAL '1' DAY 
		    FROM dateseries
	    WHERE date_col < to_date('2024-06-30','YYYY-MM-DD')
	), dates_of_interest AS (
		SELECT 
			trunc(date_col) AS date_col
		FROM 
			DateSeries	
	), container_lists AS (
		SELECT 
			trunc(doi.date_col) AS date_actual
			, acc.nbr AS containers
			, acc.sztp_id AS sztp
		FROM dates_of_interest doi
		JOIN accum_snap acc ON 
			trunc(doi.date_col) BETWEEN trunc(in_yard_datetime) AND trunc(out_yard_datetime)
			OR (trunc(doi.date_col) >= trunc(in_yard_datetime) AND out_yard_datetime IS NULL)
			OR (trunc(doi.date_col) < trunc(out_yard_datetime) AND in_yard_datetime IS null)
		GROUP BY trunc(doi.date_col), acc.nbr, acc.sztp_id
		--ORDER BY trunc(doi.date_col)
)--, daily_stats 
SELECT
	cl.date_actual
	, count(cl.containers) AS container_count
	, sum(to_number (substr(cl.sztp,1,2)) / 20) AS teu_precise
	, sum(CASE WHEN to_number(substr(cl.sztp,1,2)) < 30 THEN 1 ELSE 2 END) AS teu_whole
FROM container_lists cl
GROUP BY cl.date_actual
ORDER BY cl.date_actual
;

--			, to_number (sztp_eqsz_id) / 20 AS teu_precise
--			, CASE WHEN TO_number (sztp_eqsz_id) < 30 THEN 1 ELSE 2 END AS teu_whole

SELECT to_number(substr('40DR',1,2)) FROM dual;

SELECT 
	*
FROM equipment_jn jn
WHERE jn.nbr = 'AMFU3051495'
ORDER BY jn.jn_entryid
;

SELECT * FROM equipment_jn_arc FETCH FIRST 20 ROWS ONLY ;
SELECT * FROM equipment_jn FETCH FIRST 20 ROWS ONLY ;
SELECT * FROM equipment FETCH FIRST 20 ROWS ONLY ;