--Rebuilding the equipment table from equipment_jn
--Enhancing it with position data
--Identifying the block
WITH 
	jn_entries AS (
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_id
			, loc_type
			, pos_id
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
			--AND loc_type = 'Y'
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
		ORDER BY 
			nbr
			, jn_entryid
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

SELECT
	loc_id
	, count(*)
FROM equipment_jn
WHERE loc_type = 'Y'
GROUP BY loc_id
ORDER BY 2 desc
;

SELECT
	b.name AS block_name
	, b.TYPE AS block_type
	, e.enum_name AS block_type_desc
	, r.name AS row_name_20
	, r.name40 AS row_name_40
FROM td_row r
JOIN td_block b ON
	r.block_id = b.id
JOIN enums_for_external_use e ON
	e.enum_value = b.TYPE
WHERE e.enum_type = 'BLOCKTYPEDEFINES'
ORDER BY b.name, r.name
;

SELECT
	--DISTINCT enum_type
	*
FROM enums_for_external_use
WHERE enum_type = 'BLOCKTYPEDEFINES'
ORDER BY 1
;

SELECT unique_block_flag FROM spinnaker.td_terminal;

SELECT count(*) FROM positions; --129783
SELECT * FROM positions;
SELECT count(*) FROM spinnaker.td_row; --3383
SELECT * FROM spinnaker.td_row;
SELECT count(*) FROM spinnaker.td_block; --9664
SELECT * FROM spinnaker.td_block;

-- This works for TAM UAT, TAM PROD,
WITH journal_entries AS (
	SELECT 
		--count(*)
		--ej.jn_datetime
		ej.jn_entryid
		/*, ej.nbr
		, ej.sztp_id
		, ej.loc_type*/
		, ej.pos_id
		--, p.pos_block AS jn_block_name
		--, p.pos_row
		--, p.pos_block || p.pos_row AS pos_block_row
		, ROWNUM r
	FROM equipment_jn ej
	--LEFT JOIN positions p ON
		--p.id = ej.pos_id
	WHERE 
		ej.sztp_class = 'CTR'
		AND ej.loc_type = 'Y'
		--AND pos_block IS NOT NULL 
/*	ORDER BY 
		ej.nbr
		, ej.jn_entryid*/
), journal_slice AS (
	SELECT * FROM journal_entries WHERE r > 0 AND r <= 100000
), journal_join AS (
	SELECT 
		js.*
		, p.pos_block AS jn_block_name
		--, p.pos_row
		, p.pos_block || p.pos_row AS pos_block_row
	FROM journal_slice js
	LEFT JOIN positions p ON
		p.id = js.pos_id
	WHERE p.pos_block IS NOT null
), rows_with_blocks AS (
	SELECT
		r.id AS row_id
		, r.name
		, r.name40
		, b.name AS r_block_name
		, b.id AS block_id
	FROM spinnaker.td_row r
	JOIN spinnaker.td_block b ON -- deliberate INNER JOIN TO avoid fanning OUT due TO deleted blocks - apparently NOT ALL ROWS GET deleted
		b.id = r.block_id
), results AS (
	SELECT
		j.*
		, r.name as row_name
		, r.name40
		, COALESCE (br.name,bj.name) AS block_name
		--, br.name AS block_name
	FROM journal_join j
	LEFT JOIN rows_with_blocks r ON
		(r.name = j.pos_block_row OR r.name40 = j.pos_block_row)
	LEFT JOIN spinnaker.td_block br ON br.name = r.r_block_name -- sometimes the concatenation doesn't produce a block name
	LEFT JOIN spinnaker.td_block bj ON bj.name = j.jn_block_name -- but the pos_block might still be a block name
	-- Joining on block IDs isn't durable enough. Blocks are deleted and then recreated with the same name. 
	/*ORDER BY 
		j.nbr
		, j.jn_entryid*/
), dups AS (
	SELECT
		res.jn_entryid AS jn_entryid
		--, count(*)
	FROM results res
	GROUP BY res.jn_entryid HAVING count(*) > 1
)
SELECT
	res.*
FROM results res
JOIN dups ON res.jn_entryid = dups.jn_entryid
UNION
SELECT 
	res.*
FROM results res
WHERE res.block_name IS NULL 
ORDER BY 2
;

--J100
--E400
--P400

SELECT
	r.id
	, b.id
FROM spinnaker.td_row r
JOIN spinnaker.td_block b ON -- deliberate INNER JOIN TO avoid fanning OUT due TO deleted blocks - apparently NOT ALL ROWS GET deleted
	b.id = r.block_id
WHERE r.name = '305' OR r.name40 = '305'
;

SELECT *
FROM equipment_jn
WHERE jn_entryid IN ('11755148','11755155','11755161')

SELECT DISTINCT id FROM positions ORDER BY id;

SELECT pos_mode, count(*) FROM containers GROUP BY pos_mode ORDER BY pos_mode;
SELECT * FROM enums_for_external_use WHERE enum_value = 'Y';
SELECT DISTINCT enumb_name FROM enumb_string;

SELECT
	eq.*
	, p.*
FROM equipment eq
LEFT JOIN positions p ON p.id = eq.pos_id
WHERE eq.loc_type = 'Y'
;

SELECT
	eq.nbr AS eq_nbr
	, eq.loc_type
	, eq.pos_id
	, con.block_or_carrier
	, b.name
FROM equipment eq
LEFT JOIN spinnaker.containers con ON
	eq.nbr = con.container_number
LEFT JOIN spinnaker.td_block b ON
	con.block_or_carrier = b.name
WHERE eq.loc_type = 'Y'
	AND sztp_class = 'CTR'
;

SELECT
	b.name
	, count(*)
FROM equipment eq
LEFT JOIN spinnaker.containers con ON
	eq.nbr = con.container_number
LEFT JOIN spinnaker.td_block b ON
	con.block_or_carrier = b.name
WHERE eq.loc_type = 'Y'
	AND sztp_class = 'CTR'
GROUP BY b.name
ORDER BY 2 desc
;

--This seems to be a good way to get the block name for the current state.
--This could be used with a capture of the spinnaker.containers table where the rows 
--had an effective and expiration date. We could search for containers present 
--during a day by looking for rows that were effective before the start of the next day
--and expired after the start of the desired day.
SELECT
	--sum (CASE WHEN b.name IS NOT NULL THEN 1 ELSE 0 END ) AS nonnulls_names
	sum (CASE WHEN b.name IS NULL THEN 1 ELSE 0 END ) AS NULLS_names
	, count(*) AS total
	, sum (CASE WHEN b.name IS NULL THEN 1 ELSE 0 END ) / count(*) * 100 AS null_percent
	, sum (CASE WHEN con.block_or_carrier IS NULL THEN 1 ELSE 0 END ) AS missing_containers
	, sum (CASE WHEN con.block_or_carrier IS NOT NULL AND b.name IS NULL THEN 1 ELSE 0 END ) AS missing_blocks
FROM equipment eq
LEFT JOIN spinnaker.containers con ON
	eq.nbr = con.container_number
LEFT JOIN spinnaker.td_block b ON
	con.block_or_carrier = b.name
WHERE eq.loc_type = 'Y'
	AND sztp_class = 'CTR'
;

--For investigating the NULL names
SELECT
	eq.nbr AS eq_nbr
	, eq.loc_type
	, eq.pos_id
	, con.block_or_carrier
	, b.name
FROM equipment eq
LEFT JOIN spinnaker.containers con ON
	eq.nbr = con.container_number
LEFT JOIN spinnaker.td_block b ON
	con.block_or_carrier = b.name
WHERE eq.loc_type = 'Y'
	AND sztp_class = 'CTR'
	AND b.name IS NULL 
; --Someone deleted the C101 block recently AT T5S

--Looking at some T30 data
SELECT * FROM positions WHERE id = 'D274';
SELECT * FROM spinnaker.td_row WHERE name = 'D274' OR name40 = 'D274';
SELECT * FROM spinnaker.td_row WHERE name = 'D200274' OR name40 = 'D200274';
SELECT * FROM spinnaker.td_block WHERE name = 'D200';

select distinct pos_id from equipment_jn
where loc_type = 'Y'
and jn_datetime > trunc(sysdate-120)
and loc_id = 'T30'
and pos_id not in (select id from positions)

