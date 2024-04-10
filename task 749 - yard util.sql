--Initial look-see scratch
WITH 
	inorout AS (
		SELECT 
		    CASE 
		        WHEN equ.IN_YARD_DATE IS NULL AND equ.OUT_YARD_DATE IS NULL THEN 'BothNull'
		        WHEN equ.in_Yard_date IS NOT NULL AND equ.OUT_yard_date IS NULL THEN 'Yard'
		        WHEN equ.IN_yard_date IS NULL AND equ.out_yard_date IS NOT NULL THEN 'OutButNeverIn?'
		        WHEN equ.in_yard_date IS NOT NULL AND equ.out_yard_date IS NOT NULL AND
		            equ.OUT_yard_date - equ.in_yard_date > 0 THEN 'Valid'
		        WHEN equ.in_yard_date IS NOT NULL AND equ.out_yard_date IS NOT NULL AND 
		            NOT (equ.out_yard_date - equ.in_yard_date > 0) THEN 'Invalid'
		        ELSE 'MissedSomeCases'
		    END AS inorout
		    , equ.*
		FROM equipment_uses equ
	)
SELECT
	ioo.inorout
	, count(*)
FROM inorout ioo
GROUP BY 
	ioo.inorout
;

SELECT count(*) FROM equipment eq WHERE eq.loc_type = 'Y';
SELECT count(*) FROM equipment_history eh WHERE eh.loc_type = 'Y';

SELECT 
    eh.loc_type,
    MAX(CASE WHEN rn = 1 THEN third_fiel END) AS last_row_third_field_value
FROM (
    SELECT 
        group_field,
        third_field,
        ROW_NUMBER() OVER (PARTITION BY group_field ORDER BY sort_field DESC) AS rn
    FROM your_table
) subquery
WHERE rn = 1
GROUP BY group_field;

SELECT * FROM cg_ref_codes;

--Alpha metrics query 23475
WITH
	containers_in_inventory AS (
		SELECT
			eq.nbr 
			, eq.OWNER_ID 
			, eq.sztp_id
			, eq.SZTP_EQSZ_ID 
			, eq.SZTP_EQTP_ID 
			, eq.damage
			, eq.LOC_TYPE 
			, eq.POS_ID 
			, equ.category
			, equ.status
			, equ.destination
			, equ.load_port_id
			, equ.gross_weight
			, equ.required_temp
			, equ.customs_status
			, equ.line_release_status
			, equ.in_yard_date
			, equ.out_yard_date
			, equ.transship
			, equ.placard
			, equ.vgm_weight
		FROM equipment eq 
		JOIN equipment_uses equ ON equ.gkey = eq.equse_gkey
		WHERE 
			eq.loc_type = 'Y' AND 
			eq.sztp_class = 'CTR'
	)
SELECT 
	count(*) AS containers_count
FROM containers_in_inventory
;

--With the above results as the goal, find an alternative source

--First attempt uses in_yard_date and out_yard_date from equipment_uses
--and insists that there is an entry in the equipment table for the container
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

--Switching to ZLO UAT 2
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

--The last months for ZLO are really high, seems like.
--But the standard quey gives 24140 so I don't know.
SELECT 
	count(*)
FROM equipment eq
WHERE 
	eq.loc_type = 'Y'
;

--Quick look at ZLO Prod
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

SELECT 
	count(*)
FROM equipment eq
WHERE 
	eq.loc_type = 'Y'
;

--Swtiching to PCT
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

SELECT 
	count(*)
FROM equipment eq
WHERE 
	eq.loc_type = 'Y'
;

--Swtiching to T18
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

SELECT 
	count(*)
FROM equipment eq
WHERE 
	eq.loc_type = 'Y'
;

--Swtiching to TAM
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

SELECT 
	count(*)
FROM equipment eq
WHERE 
	eq.loc_type = 'Y'
;

--Abandoning equipment_uses. Looking at equipment_jn now and switching to MIT UAT
SELECT 
	*
FROM equipment_jn ejn 
ORDER BY 
	ejn.nbr
	, ejn.jn_datetime
;

--It seems like the equipment_jn table holds the transactions that edit the equipment table.
--Let's build the accumulating snapshot from it and see what we get.
--Running in ZLO UAT 2 because it seems to have good data for a couple years or so.
--This query seems to work, but is difficult to validate. I'm going to re-write it so that
--every update has an effective and expired datetime, and then build a second summary table 
--for entering and exiting the yard.
WITH 
	jn_entries AS (
		SELECT
			ejn.nbr, ejn.JN_DATETIME, ejn.LOC_TYPE 
		FROM equipment_jn ejn
		WHERE 
			sztp_class = 'CTR'
			AND REGEXP_LIKE(NBR, '[[:alpha:]]{4}[[:digit:]]{7}')
--		ORDER BY 
--			ejn.NBR 
--			, ejn.JN_DATETIME 
	), jn_lags AS (
		SELECT
			nbr
			, jn_datetime
			, loc_type
			, LAG(loc_type,1,NULL) over (PARTITION BY nbr ORDER BY jn_datetime) AS other_loctype
		FROM jn_entries
	), starts AS (
		SELECT
			*
		FROM jn_lags
		WHERE 
			loc_type = 'Y'
			AND (other_loctype IS NULL OR NOT(other_loctype = 'Y'))
	), jn_leads AS (
		SELECT 
			nbr
			, LEAD(jn_datetime,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_datetime) AS jn_datetime
			, loc_type
			, LEAD(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_datetime) AS other_loctype
		FROM jn_entries
	), ends AS (
		SELECT 
			*
		FROM jn_leads
		WHERE 
			loc_type = 'Y'
			AND (other_loctype IS NULL OR NOT (other_loctype = 'Y'))
	), transitions AS (
		SELECT 
			starts.*
			, 'a_start' AS transition
		FROM starts 
		UNION 
		SELECT 
			ends.*
			, 'b_end' AS transition
		FROM ends
		ORDER BY 1, 2, 5
	), numbered_transitions AS (
		SELECT 
			transitions.*
			, ROW_NUMBER() OVER (ORDER BY NULL) AS rownumber
		FROM 
			transitions
	), ordered_transitions AS (
		SELECT 
			nbr
			, jn_datetime
			, loc_type
			, other_loctype
			, transition
			, lag(nbr,1,null) OVER (ORDER BY rownumber) AS prev_nbr
			, lag(jn_datetime,1,null) OVER (ORDER BY rownumber) AS prev_datetime
			, lag(transition,1,null) OVER (ORDER BY rownumber) AS prev_transition
			, lag(rownumber,1,null) OVER (ORDER BY rownumber) AS prev_rownumber
			, lead(nbr,1,null) OVER (ORDER BY rownumber) AS next_nbr
			, lead(jn_datetime,1,null) OVER (ORDER BY rownumber) AS next_datetime
			, lead(transition,1,null) OVER (ORDER BY rownumber) as next_transition
			, lead(rownumber, 1, null) OVER (ORDER BY rownumber) AS next_rownumber
			, rownumber
		FROM numbered_transitions
		ORDER BY 
			CASE 
				WHEN nbr = next_nbr AND jn_datetime = next_datetime AND transition = prev_transition THEN next_rownumber
				WHEN nbr = prev_nbr AND jn_datetime = prev_datetime AND transition = next_transition THEN prev_rownumber
				ELSE rownumber
			END
	), joinable_transitions AS (
		SELECT 
			nbr
			, jn_datetime
			, loc_type
			, transition
		FROM ordered_transitions
		WHERE 
			NOT (nbr = prev_nbr AND transition = prev_transition AND NOT (jn_datetime = prev_datetime)) OR rownumber = 1
	), joined_transitions AS (
		SELECT 
			nbr
			, jn_datetime AS in_yard_time
			, lead(jn_datetime,1,null) OVER (PARTITION BY nbr ORDER BY jn_datetime) AS out_yard_time
			, transition
		FROM joinable_transitions
	), accum_snap AS (
		SELECT 
			nbr
			, in_yard_time
			, out_yard_time
		FROM joined_transitions
		WHERE 
			transition = 'a_start'
	), DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN accum_snap ON 
	doi.monthstart BETWEEN in_yard_time AND out_yard_time
	OR (doi.monthstart >= in_yard_time AND OUT_yard_time IS NULL)
	OR (doi.monthstart < out_yard_time AND in_yard_time IS null)
GROUP BY monthstart
ORDER BY monthstart
;

SELECT count(*) FROM equipment WHERE loc_type = 'Y';
SELECT 
	LOC_TYPE 
	, count(*)
FROM equipment_jn
GROUP BY 
	LOC_TYPE 
;
SELECT count(*) FROM equipment_Jn;

		SELECT
			*
			--ejn.nbr, ejn.JN_DATETIME, ejn.LOC_TYPE 
		FROM equipment_jn ejn
		WHERE 
			NOT (
			sztp_class = 'CTR'
			AND REGEXP_LIKE(NBR, '[[:alpha:]]{4}[[:digit:]]{7}'))
			
--Re-write to provide effective and expired columns for every transaction
--This seems to be working but it gives me the same answer as I had with the first query.
--I like this one better anyhow. It's more compact and seem more straight-forward.
WITH 
	jn_entries AS (
		SELECT
			*
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
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
			, CASE 
				WHEN nbr = LEAD(nbr,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) AND entry_label = 'Enters' THEN jn_datetime
				ELSE NULL 
			  END AS in_yard_datetime
			, CASE 
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
	), DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN accum_snap ON 
	doi.monthstart BETWEEN in_yard_datetime AND out_yard_datetime
	OR (doi.monthstart >= in_yard_datetime AND out_yard_datetime IS NULL)
	OR (doi.monthstart < out_yard_datetime AND in_yard_datetime IS null)
GROUP BY monthstart
ORDER BY monthstart
;
			
--Switching to ZLO UAT 2
WITH 
	jn_entries AS (
		SELECT
			*
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
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
			, CASE 
				WHEN nbr = LEAD(nbr,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) AND entry_label = 'Enters' THEN jn_datetime
				ELSE NULL 
			  END AS in_yard_datetime
			, CASE 
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
	), DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN accum_snap ON 
	doi.monthstart BETWEEN in_yard_datetime AND out_yard_datetime
	OR (doi.monthstart >= in_yard_datetime AND out_yard_datetime IS NULL)
	OR (doi.monthstart < out_yard_datetime AND in_yard_datetime IS null)
GROUP BY monthstart
ORDER BY monthstart
;

SELECT count(*) FROM equipment WHERE loc_type = 'Y';

--Switching to MIT UAT
-- I want to remember why the data isn't good.
SELECT 
	sztp_class
	, count(*)
FROM equipment_jn 
GROUP BY 
	SZTP_CLASS 
;

WITH 
	jn_entries AS (
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_class
			, loc_type
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
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
	), DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN accum_snap ON 
	doi.monthstart BETWEEN in_yard_datetime AND out_yard_datetime
	OR (doi.monthstart >= in_yard_datetime AND out_yard_datetime IS NULL)
	OR (doi.monthstart < out_yard_datetime AND in_yard_datetime IS null)
GROUP BY monthstart
ORDER BY monthstart
;

--Switching back to TAM and ZLO UAT 2 with corrected query
WITH 
	jn_entries AS (
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_class
			, loc_type
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
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
	), DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN accum_snap ON 
	doi.monthstart BETWEEN in_yard_datetime AND out_yard_datetime
	OR (doi.monthstart >= in_yard_datetime AND out_yard_datetime IS NULL)
	OR (doi.monthstart < out_yard_datetime AND in_yard_datetime IS null)
GROUP BY monthstart
ORDER BY monthstart
;

--Looking at TAM prod - containers in the equipment table with loc_type = 'Y' that aren't in equipment_jn
WITH 
	equip_in_yard AS (
		SELECT 
			count(*)
		FROM equipment
		WHERE 
			sztp_class = 'CTR'
			AND loc_type = 'Y'
		ORDER BY 
			nbr
	)
SELECT
	*
FROM equip_in_yard eq
LEFT JOIN equipment_jn jn ON eq.nbr = jn.NBR 
WHERE 
	jn.nbr IS NULL 
--ORDER BY 
--	eq.nbr
;

--Let's see how MIT Prod responds
WITH 
	jn_entries AS (
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_class
			, loc_type
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
/*		ORDER BY 
			nbr
			, jn_entryid
		FETCH FIRST 500000 ROWS ONLY */
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
/*		ORDER BY 
			nbr
			, jn_entryid
		FETCH FIRST 500000 ROWS ONLY 
*/	), inv_events AS (
		SELECT 
--			count(*)
			jn_datetime
			, jn_entryid
			, nbr
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
	/*	ORDER BY 
			nbr
			, jn_entryid
		FETCH FIRST 500000 ROWS ONLY 
	*/), yard_durations AS (
		SELECT 
			nbr
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
/*		ORDER BY 
			nbr
			, jn_entryid
		FETCH FIRST 500000 ROWS ONLY 
*/	)--, accum_snap AS (
		SELECT 
			--count(*)
			*
		FROM yard_durations
		WHERE 
			in_yard_datetime IS NOT NULL
		ORDER BY 
			nbr
			, in_yard_datetime
--		FETCH FIRST 500000 ROWS ONLY 
	), DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN accum_snap ON 
	doi.monthstart BETWEEN in_yard_datetime AND out_yard_datetime
	OR (doi.monthstart >= in_yard_datetime AND out_yard_datetime IS NULL)
	OR (doi.monthstart < out_yard_datetime AND in_yard_datetime IS null)
GROUP BY monthstart
ORDER BY monthstart
;

SELECT count(*) FROM equipment WHERE sztp_class = 'CTR' AND loc_type = 'Y';
SELECT count(*) FROM equipment_jn;

--Switching to PCT production and T18 production
SELECT count(*) FROM equipment_jn;
SELECT count(*) FROM equipment WHERE sztp_class = 'CTR' AND loc_type = 'Y';


WITH 
	jn_entries AS (
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_class
			, loc_type
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
/*		ORDER BY 
			nbr
			, jn_entryid
		FETCH FIRST 500000 ROWS ONLY */
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
/*		ORDER BY 
			nbr
			, jn_entryid
		FETCH FIRST 500000 ROWS ONLY 
*/	), inv_events AS (
		SELECT 
--			count(*)
			jn_datetime
			, jn_entryid
			, nbr
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
	/*	ORDER BY 
			nbr
			, jn_entryid
		FETCH FIRST 500000 ROWS ONLY 
	*/), yard_durations AS (
		SELECT 
			nbr
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
/*		ORDER BY 
			nbr
			, jn_entryid
		FETCH FIRST 500000 ROWS ONLY 
*/	)--, accum_snap AS (
		SELECT 
			--count(*)
			*
		FROM yard_durations
		WHERE 
			in_yard_datetime IS NOT NULL
/*		ORDER BY 
			nbr
			, in_yard_datetime
		FETCH FIRST 500000 ROWS ONLY 
*/	), DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN accum_snap ON 
	doi.monthstart BETWEEN in_yard_datetime AND out_yard_datetime
	OR (doi.monthstart >= in_yard_datetime AND out_yard_datetime IS NULL)
	OR (doi.monthstart < out_yard_datetime AND in_yard_datetime IS null)
GROUP BY monthstart
ORDER BY monthstart
;