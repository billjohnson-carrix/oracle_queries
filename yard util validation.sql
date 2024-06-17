SELECT * FROM equipment_jn_arc;

--Rebuilding the equipment table from equipment_jn
WITH 
	jn_entries AS (
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_class
			, loc_type
			, to_number (sztp_eqsz_id) / 20 AS teu_precise
			, CASE WHEN TO_number (sztp_eqsz_id) < 30 THEN 1 ELSE 2 END AS teu_whole
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
		UNION ALL 
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
			AND jn_entryid >= 229820141
		ORDER BY 
			nbr
			, jn_entryid
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
	), inv_events AS (
		SELECT 
			jn_datetime
			, jn_entryid
			, nbr
			, loc_type
			, teu_precise
			, teu_whole
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
	), yard_durations AS (
		SELECT 
			nbr
			, teu_precise
			, teu_whole
			, CASE 
				WHEN entry_label = 'Enters' AND exit_label = 'Current' THEN jn_datetime
				WHEN nbr = LEAD(nbr,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) AND entry_label = 'Enters' THEN jn_datetime
				ELSE NULL 
			  END AS in_yard_datetime
			, CASE 
				WHEN entry_label = 'Enters' AND exit_label = 'Current' THEN sysdate 
				WHEN nbr = lead(nbr,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) 
					AND lead(exit_label,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Exits' THEN lead(jn_datetime,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid)
				WHEN nbr = lead(nbr,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) 
					AND lead(exit_label,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Current' THEN  SYSDATE 
				ELSE null
			  END AS out_yard_datetime
		FROM inv_events
	), accum_snap AS (
		SELECT 
			*
		FROM yard_durations
		WHERE 
			in_yard_datetime IS NOT NULL
	), DateSeries (timestamp_col) AS (
	    SELECT TO_TIMESTAMP('2023-04-21 00:35:00', 'YYYY-MM-DD HH24:MI:SS') AS timestamp_col
		    FROM dual
	    UNION ALL
	    SELECT timestamp_col + INTERVAL '1' DAY
		    FROM dateseries
	    WHERE timestamp_col < TRUNC(SYSDATE) + INTERVAL '00:35' HOUR TO MINUTE
	), dates_of_interest AS (
		SELECT 
			timestamp_col
		FROM 
			DateSeries	
	)
SELECT 
	doi.timestamp_col
	, count(*)
	, sum (acc.teu_precise) AS teu_precise
	, sum (acc.teu_whole) AS teu_whole
FROM dates_of_interest doi
JOIN accum_snap acc ON 
	doi.timestamp_col BETWEEN in_yard_datetime AND out_yard_datetime
	OR (doi.timestamp_col >= in_yard_datetime AND out_yard_datetime IS NULL)
	OR (doi.timestamp_col < out_yard_datetime AND in_yard_datetime IS null)
GROUP BY timestamp_col
ORDER BY timestamp_col
;
