--Working with T18 UAT first. Let's profile the equipment_jn entries
SELECT
	*
FROM equipment_jn ej
FETCH FIRST 10 ROWS ONLY;

SELECT
	EXTRACT (YEAR FROM ej.jn_datetime) AS year
	, EXTRACT (MONTH FROM ej.jn_datetime) AS MONTH
	, count(*)
FROM equipment_jn ej
GROUP BY 
	EXTRACT (YEAR FROM ej.jn_datetime)
	, EXTRACT (MONTH FROM ej.jn_datetime)
ORDER BY
	EXTRACT (YEAR FROM ej.jn_datetime)
	, EXTRACT (MONTH FROM ej.jn_datetime)
;

--Switched to T18 PROD
SELECT
	EXTRACT (YEAR FROM ej.jn_datetime) AS year
	, EXTRACT (MONTH FROM ej.jn_datetime) AS MONTH
	, count(*)
FROM equipment_jn ej
GROUP BY 
	EXTRACT (YEAR FROM ej.jn_datetime)
	, EXTRACT (MONTH FROM ej.jn_datetime)
ORDER BY
	EXTRACT (YEAR FROM ej.jn_datetime)
	, EXTRACT (MONTH FROM ej.jn_datetime)
;

/*
 * 
 * The initial strategy here is to 
 * 		- compile a table of equipment_jn transactions, 
 * 		- label yard entries and exits and when the container is in the yard, 
 * 		- count the number of times that the container moves around within the yard.
 * I don't think I need to filter by the main yard. Any move represents a cost no matter where it is. 
 * If it's done by terminal equipment, then it's a cost to the terminal, and I'm going to assume that 
 * if it's in the TOS it's because the container is managed by terminal equipment.
 *
 */

--I think I can reuse some code to label yard entries and exits.
-- Query from prototyping yard occupancye
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

-- Modifying
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
*/	), accum_snap AS (
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
	), aggregation AS (
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
	)
SELECT
	*
FROM labeled_entries
;

--This was built in Snowflake and needs to be translated to Oracle
/*
WITH 
	jn_entries AS (
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_class
			, loc_type
            , pos_id
		FROM silver.sources.source_mainsail_t18__mtms_equipment_jn 
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
                --An entry event occurs when the record's loc_type is Y and there is either no previous record or the previous record's loc_type is not Y
				WHEN loc_type = 'Y' AND (LAG(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) IS NULL 
					OR NOT (LAG(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y')) THEN 'Enters'
                --All other cases should be covered by either the current record's loc_type not being Y or the previous record's loc_type being Y.
				WHEN NOT (loc_type = 'Y') OR LAG(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y' THEN 'No entry'
                --No else as a test on the logic.
			  END AS entry_label
			, CASE 
                --The current record's indicates a container in inventory if loc_type is Y and there are no further records.
				WHEN loc_type = 'Y' AND LEAD(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) IS NULL THEN 'Current'
                --An exit event occurs when the current record's loc_type is not Y and the previous record's loc_type is Y.
				WHEN NOT (loc_type = 'Y') AND lag(loc_type,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y' THEN 'Exits'
                --All other cases should be covered by either 1) the current record's loc_type is Y, 2) there is no previous record, 3) the previous record's loc_type is not Y
				WHEN loc_type = 'Y' OR lag(loc_type,1,null) OVER (PARTITION BY nbr order BY jn_entryid) IS NULL 
					OR NOT (lag(loc_type,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y') THEN 'No exit'
                --No else as a test on the logic.
			  END AS exit_label
            , case
                --An unproductive move occurs when the current record's loc_type is Y and the previous record's loc_type is Y and the pos_id changes.
                when loc_type = 'Y' and lag(loc_type,1,null) over (partition by nbr order by jn_entryid) = 'Y' 
                    -- Gotta look out for nulls
                    and not (equal_null(pos_id,lag(pos_id,1,null) over (partition by nbr order by jn_entryid))) then 'Unproductive'
                --All other cases should be covered by either 1) the current record's loc_type is not Y, 2) there are no previous records, 3) the previous record's loc_type is not Y, 4) pos_id doesn't change
                when not (loc_type = 'Y') 
                    or lag(loc_type,1,null) over (partition by nbr order by jn_entryid) is null 
                    or not (lag(loc_type,1,null) over (partition by nbr order by jn_entryid) = 'Y') 
                    or equal_null(pos_id,lag(pos_id,1,null) over (partition by nbr order by jn_entryid))
                        then 'Not unproductive'
                --No else to test the logic. Note that the Unproductive flag and the Current flag may occur for the same record.
              end as unproductive_label
		FROM jn_entries
		ORDER BY 
			nbr
			, jn_entryid
	), inv_events AS (
		SELECT 
--			count(*)
			jn_datetime
			, jn_entryid
			, nbr
			, loc_type
			, effective
			, expired
			, entry_label
            , unproductive_label
			, exit_label
            , row_number() over (partition by nbr order by jn_datetime asc, jn_entryid asc) as rn_asc
            , row_number() over (partition by nbr order by jn_datetime desc, jn_entryid desc) as rn_desc
		FROM 
			labeled_entries
		WHERE 
			entry_label = 'Enters'
			OR exit_label = 'Exits'
			OR exit_label = 'Current'
            or unproductive_label = 'Unproductive'
		ORDER BY 
			nbr
			, jn_entryid
	), accum_snap AS (
		SELECT 
			nbr
			, max (case when rn_asc = 1 then jn_datetime else null end) as in_yard_datetime
            , max (case when rn_desc = 1 then jn_datetime else null end) as out_yard_datetime
            , sum (case when unproductive_label = 'Unproductive' then 1 else 0 end) as unproductive_move_count
        FROM inv_events
        group by nbr
		ORDER BY 
			nbr
            , in_yard_datetime
	), DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2023-04-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(current_timestamp, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	), aggregation1 as (
        SELECT 
        	doi.monthstart
        	, count(*) as container_inventory
        FROM dates_of_interest doi
        JOIN accum_snap ON 
            doi.monthstart between accum_snap.in_yard_datetime::date and accum_snap.out_yard_datetime::date
        GROUP BY monthstart
        ORDER BY monthstart
    ), aggregation2 as (
        select
            year(agg.monthstart), month(agg.monthstart), agg.container_inventory
            , count(*) as unproductive_move_count
        from aggregation1 agg
        join inv_events ie on
            month(agg.monthstart) = month(ie.jn_datetime)
        where unproductive_label = 'Unproductive'
        group by year(agg.monthstart), month(agg.monthstart), agg.container_inventory
        order by year(agg.monthstart), month(agg.monthstart), agg.container_inventory
    )
select * from aggregation2;
*/

--This seems to work for T18 PROD. I'll try it on 4 other terminals next.
--Rerunning at MIT PROD.
WITH 
	jn_entries AS (
		SELECT
			jn_datetime
			, jn_entryid
			, nbr
			, sztp_class
			, loc_type
			, pos_id
		FROM equipment_jn
		WHERE 
			sztp_class = 'CTR'
			AND pos_id IS NOT NULL 
			AND pos_id NOT IN ('YARD','UTR','TRUCK','GATE','INGATE','WHLS','TBD','GND')
		ORDER BY 
			nbr
			, jn_entryid
	), labeled_entries AS (
		SELECT
			jn_entries.*
			, jn_datetime AS effective
			, LEAD(jn_datetime,1,NULL) over (PARTITION BY nbr ORDER BY jn_entryid) AS expired
			, CASE 
                --An entry event occurs when the record's loc_type is Y and there is either no previous record or the previous record's loc_type is not Y
				WHEN loc_type = 'Y' AND (LAG(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) IS NULL 
					OR NOT (LAG(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y')) THEN 'Enters'
                --All other cases should be covered by either the current record's loc_type not being Y or the previous record's loc_type being Y.
				WHEN NOT (loc_type = 'Y') OR LAG(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y' THEN 'No entry'
                --No else as a test on the logic.
			  END AS entry_label
			, CASE 
                --The current record's indicates a container in inventory if loc_type is Y and there are no further records.
				WHEN loc_type = 'Y' AND LEAD(loc_type,1,NULL) OVER (PARTITION BY nbr ORDER BY jn_entryid) IS NULL THEN 'Current'
                --An exit event occurs when the current record's loc_type is not Y and the previous record's loc_type is Y.
				WHEN NOT (loc_type = 'Y') AND lag(loc_type,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y' THEN 'Exits'
                --All other cases should be covered by either 1) the current record's loc_type is Y, 2) there is no previous record, 3) the previous record's loc_type is not Y
				WHEN loc_type = 'Y' OR lag(loc_type,1,null) OVER (PARTITION BY nbr order BY jn_entryid) IS NULL 
					OR NOT (lag(loc_type,1,null) OVER (PARTITION BY nbr ORDER BY jn_entryid) = 'Y') THEN 'No exit'
                --No else as a test on the logic.
			  END AS exit_label
            , case
                --An unproductive move occurs when the current record's loc_type is Y and the previous record's loc_type is Y and the pos_id changes.
                when loc_type = 'Y' and lag(loc_type,1,null) over (partition by nbr order by jn_entryid) = 'Y' 
                    -- Gotta look out for nulls
                    and not (decode(pos_id,lag(pos_id,1,null) over (partition by nbr order by jn_entryid),1,0) = 1) then 'Unproductive'
                --All other cases should be covered by either 1) the current record's loc_type is not Y, 2) there are no previous records, 3) the previous record's loc_type is not Y, 4) pos_id doesn't change
                when not (loc_type = 'Y') 
                    or lag(loc_type,1,null) over (partition by nbr order by jn_entryid) is null 
                    or not (lag(loc_type,1,null) over (partition by nbr order by jn_entryid) = 'Y') 
                    or decode(pos_id,lag(pos_id,1,null) over (partition by nbr order by jn_entryid),1,0) = 1
                        then 'Not unproductive'
                --No else to test the logic. Note that the Unproductive flag and the Current flag may occur for the same record.
              end as unproductive_label
		FROM jn_entries
		ORDER BY 
			nbr
			, jn_entryid
	), inv_events AS (
		SELECT 
--			count(*)
			jn_datetime
			, jn_entryid
			, nbr
			, loc_type
			, effective
			, expired
			, entry_label
            , unproductive_label
			, exit_label
            , row_number() over (partition by nbr order by jn_datetime asc, jn_entryid asc) as rn_asc
            , row_number() over (partition by nbr order by jn_datetime desc, jn_entryid desc) as rn_desc
		FROM 
			labeled_entries
		WHERE 
			entry_label = 'Enters'
			OR exit_label = 'Exits'
			OR exit_label = 'Current'
            or unproductive_label = 'Unproductive'
		ORDER BY 
			nbr
			, jn_entryid
	), accum_snap AS (
		SELECT 
			nbr
			, max (case when rn_asc = 1 then jn_datetime else null end) as in_yard_datetime
            , max (case when rn_desc = 1 then jn_datetime else null end) as out_yard_datetime
            , sum (case when unproductive_label = 'Unproductive' then 1 else 0 end) as unproductive_move_count
        FROM inv_events
        group by nbr
		ORDER BY 
			nbr
            , in_yard_datetime
	), DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2023-04-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(current_timestamp, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	), aggregation1 as (
        SELECT 
        	doi.monthstart
        	, count(*) as container_inventory
        FROM dates_of_interest doi
        JOIN accum_snap ON 
            doi.monthstart between trunc(accum_snap.in_yard_datetime) and trunc(accum_snap.out_yard_datetime)
        GROUP BY monthstart
        ORDER BY monthstart
    ), aggregation2 as (
        select
            EXTRACT (YEAR FROM agg.monthstart), 
            EXTRACT (MONTH FROM agg.monthstart), 
            agg.container_inventory
            , count(*) as unproductive_move_count
        from aggregation1 agg
        join inv_events ie on
            EXTRACT (MONTH FROM agg.monthstart) = EXTRACT (MONTH FROM ie.jn_datetime)
        where unproductive_label = 'Unproductive'
        group by EXTRACT (YEAR FROM agg.monthstart), EXTRACT (MONTH FROM agg.monthstart), agg.container_inventory
        order by EXTRACT (YEAR FROM agg.monthstart), EXTRACT (MONTH FROM agg.monthstart), agg.container_inventory
    )
select * from aggregation2;

--For throughput numbers to compare to
WITH vessel_visits_of_interest AS (
	SELECT
		vv.vsl_id
		, v.category
		, vv.in_voy_nbr
		, vv.out_voy_nbr
		, COALESCE (vv.atd, vv.etd) AS dt
	FROM vessel_visits vv
	JOIN vessels v ON
		vv.vsl_id = v.id
	WHERE 
		COALESCE (vv.atd, vv.etd) > to_date('2023-08-01','YYYY-MM-DD')
		AND COALESCE (vv.atd, vv.etd) < sysdate
		AND (vv.atd IS NOT NULL OR (vv.atd IS NULL AND vv.berth IS NOT null))
		AND (v.category IS NULL OR NOT v.category = 'RORO')
	ORDER BY
		COALESCE (vv.atd, vv.etd)
), vessel_move_lists AS (
	SELECT
		vvoi.vsl_id
		, vvoi.category
		, vvoi.in_voy_nbr
		, vvoi.out_voy_nbr
		, vvoi.dt
		, eh.eq_nbr AS moves
		, eh.wtask_id AS task
		, eh.transship AS transship
		, eh.status
		, eh.line_id AS line
		, eh.temp_required
	FROM equipment_history eh
	JOIN vessel_visits_of_interest vvoi ON
		vvoi.vsl_id = eh.vsl_id
		AND (vvoi.in_voy_nbr = eh.voy_nbr OR vvoi.out_voy_nbr = eh.voy_nbr)
	WHERE 
		eh.wtask_id = 'LOAD' 
		OR eh.wtask_id = 'UNLOAD'
	ORDER BY 
		vvoi.dt
		, vvoi.vsl_id
		, eh.posted
), move_breakdown_by_vessel AS (
	SELECT
		vml.vsl_id
		, vml.category
		, vml.in_voy_nbr
		, vml.out_voy_nbr
		, vml.dt
		, count(vml.moves) AS total_moves
		, sum (CASE WHEN vml.task = 'UNLOAD' AND vml.transship IS NULL THEN 1 ELSE 0 end) AS imports
		, sum (CASE WHEN vml.task = 'LOAD' AND vml.transship IS NULL THEN 1 ELSE 0 end) AS exports
		, sum (CASE WHEN vml.transship IS NOT NULL THEN 1 ELSE 0 end) AS transships
		, sum (CASE WHEN vml.status = 'E' THEN 1 ELSE 0 end) AS empties
		, sum (CASE WHEN vml.status = 'F' THEN 1 ELSE 0 end) AS fulls
		, sum (CASE WHEN vml.temp_required IS NOT NULL THEN 1 ELSE 0 end) AS reefers
		, sum (CASE WHEN vml.temp_required IS NULL THEN 1 ELSE 0 end) AS not_live_reefers
	FROM vessel_move_lists vml
	GROUP BY 
		vml.vsl_id
		, vml.category
		, vml.in_voy_nbr
		, vml.out_voy_nbr
		, vml.dt
	ORDER BY 
		vml.dt
		, vml.vsl_id
), move_breakdown_for_period AS (
	SELECT
		EXTRACT (YEAR FROM dt) AS year
		, EXTRACT (MONTH FROM dt) AS MONTH
		, count (byv.vsl_id) AS total_calls
		, sum (byv.total_moves) AS total_moves
		, sum (byv.imports) AS imports
		, sum (byv.exports) AS exports
		, sum (byv.transships) AS transships
		, sum (byv.empties) AS empties
		, sum (byv.fulls) AS fulls
		, sum (byv.reefers) AS reefers
		, sum (byv.not_live_reefers) AS not_live_reefers
	FROM move_breakdown_by_vessel byv
	GROUP BY
		EXTRACT (YEAR FROM dt)
		, EXTRACT (MONTH FROM dt)
	ORDER BY
		EXTRACT (YEAR FROM dt)
		, EXTRACT (MONTH FROM dt)
), roro_contribution AS (
	SELECT
		EXTRACT (YEAR FROM byv.dt)
		, EXTRACT (MONTH FROM byv.dt)
		, byv.category
		, sum(total_moves) AS moves
	FROM move_breakdown_by_vessel byv
	GROUP BY 
		EXTRACT (YEAR FROM byv.dt)
		, EXTRACT (MONTH FROM byv.dt)
		, byv.category
	ORDER BY 
		EXTRACT (YEAR FROM byv.dt)
		, EXTRACT (MONTH FROM byv.dt)
), breakdown_by_vessel_and_line AS (
	SELECT
		vml.vsl_id
		, vml.category
		, vml.in_voy_nbr
		, vml.out_voy_nbr
		, vml.dt
		, vml.line 
		, count(vml.moves) AS total_moves
	FROM vessel_move_lists vml
	GROUP BY 
		vml.vsl_id
		, vml.category
		, vml.in_voy_nbr
		, vml.out_voy_nbr
		, vml.dt
		, vml.line 
	ORDER BY 
		vml.dt
		, vml.vsl_id
		, vml.line
), breakdown_by_line AS (
	SELECT 
		EXTRACT (YEAR FROM val.dt) AS YEAR
		, extract(MONTH FROM val.dt) AS MONTH
		, val.line AS line
		, sum(val.total_moves) AS total_moves
	FROM breakdown_by_vessel_and_line val
	GROUP BY 
		EXTRACT (YEAR FROM val.dt)
		, EXTRACT (MONTH FROM val.dt)
		, val.line
	ORDER BY 
		EXTRACT (YEAR FROM val.dt)
		, extract(MONTH FROM val.dt)
		, val.line
)
SELECT 
	*
FROM move_breakdown_for_period
--FROM breakdown_by_line
--FROM roro_contribution --COMMENT OUT the NO RORO clause
;

SELECT * FROM equipment_jn WHERE pos_id IS NULL AND loc_type = 'Y' AND sztp_class = 'CTR';

SELECT * FROM vessel_visits vv WHERE vv.vsl_id = 'ERVING' AND vv.in_voy_nbr = '0TND5';

SELECT
	jn_datetime
	, jn_entryid
	, nbr
	, sztp_class
	, loc_type
	, pos_id
FROM equipment_jn
WHERE 
	sztp_class = 'CTR'
ORDER BY 
	nbr
	, jn_entryid
;

SELECT * FROM equipment_history eh 
WHERE eh.vsl_id = 'ERVING' AND (eh.voy_nbr = '0TND5' OR eh.voy_nbr = '0TND6') AND (wtask_id = 'LOAD' OR wtask_id = 'UNLOAD')
ORDER BY eh.posted;

SELECT * FROM equipment_jn ej
WHERE ej.nbr = 'MSNU7165635'
ORDER BY ej.jn_entryid;

SELECT * FROM equipment_jn ej
WHERE ej.pos_id = 'UTL' AND ej.sztp_class = 'CTR' AND ej.loc_type = 'Y';