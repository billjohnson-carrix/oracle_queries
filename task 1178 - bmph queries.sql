--Query for STS productivty, the number of moves should be the same
--Only the worktime changes from the sum of the cranes' worktimes to the time from first to last move
WITH vessel_visits_of_interest AS (
    SELECT
        vv.vsl_id
        , vv.in_voy_nbr
        , vv.out_voy_nbr
        , vv.eta
        , vv.ata
        , vv.etd
        , vv.atd
        , vv.gross_hours
        , vv.net_hours
    FROM vessel_visits vv
    WHERE 
        /* GK: filtering by atd? BILL TODO, change to ACTUAL OR ESTIMATED departure */
        EXTRACT (YEAR FROM COALESCE(vv.atd,vv.etd)) IN ('2023','2024') --This CHANGE made NO difference TO the list OF vessel visits
    	--vv.atd IS NULL AND EXTRACT (YEAR FROM vv.etd) IN ('2023','2024')
        /* GK: this looks like the same logic for berth occupancy, is that accurate? YES, galen to add BO logic */
        AND (vv.atd IS NOT NULL OR 
                (vv.atd IS NULL AND vv.berth IS NOT NULL)) 
        AND COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) < 10
        AND COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) > 0
--    ORDER BY vv.atd, vv.vsl_id, vv.in_voy_nbr
), vvoi_and_moves AS (
    /* GK: The order of operations might be messing things up, we calculate crane events before filtering of vessel visits */
    SELECT
        vvoi.*
        , eh.crane_no
        , eh.posted AS move_start
        , lead (eh.posted) OVER (PARTITION BY eh.crane_no ORDER BY eh.posted ASC) AS move_end
        , CASE
        	WHEN lead (eh.posted) OVER (PARTITION BY eh.crane_no ORDER BY eh.posted ASC) > coalesce(vvoi.atd,vvoi.etd) THEN 0
        	WHEN eh.posted < COALESCE(vvoi.ata,vvoi.eta) THEN 0
        	WHEN eh.posted > lead (eh.posted) OVER (PARTITION BY eh.crane_no ORDER BY eh.posted ASC) THEN 0
        	ELSE (lead (eh.posted) OVER (PARTITION BY eh.crane_no ORDER BY eh.posted ASC) - eh.posted) * 24
          END AS move_hours
        --, greatest(0,(least (lead (eh.posted) OVER (PARTITION BY eh.crane_no ORDER BY eh.posted ASC), coalesce(vvoi.atd,vvoi.etd))
        --  - greatest(eh.posted,COALESCE(vvoi.ata,vvoi.eta)))) * 24 AS move_hours
    FROM vessel_visits_of_interest vvoi
    JOIN equipment_history eh ON
        vvoi.vsl_id = eh.vsl_id
        AND (vvoi.in_voy_nbr = eh.voy_nbr OR vvoi.out_voy_nbr = eh.voy_nbr)
        --AND eh.posted BETWEEN coalesce(vvoi.ata,vvoi.eta) AND coalesce(vvoi.atd, vvoi.etd)
        /* GK: these are the other filters that are applied to ours BILL TODOs 1) remove test 2) only include CTR 3) crane events must be between coalesced events:
            (upper(crane_number) not like 'TEST%' or crane_number is null)
            and equipment_class = 'CTR' /* Only include container equipment 

            -- then later on
            and crane_container_move_events.crane_event_started_at between --Only match events to moves during time 
            vessel_visits.actual_or_estimated_arrival_at
            and vessel_visits.actual_or_estimated_departure_at
         */
        AND eh.wtask_id IN ('LOAD','UNLOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
        AND (upper(eh.crane_no) NOT LIKE 'TEST%' OR eh.crane_no IS NULL) -- We want TO include NULL crane_no IN the move counts
        AND eh.eq_class = 'CTR' 
        AND eh.posted BETWEEN COALESCE (vvoi.ata, vvoi.eta) AND COALESCE (vvoi.atd, vvoi.etd)
    --ORDER BY COALESCE(vvoi.atd,vvoi.etd), eh.crane_no, eh.posted
), wt_by_crane AS (
    SELECT 
        vm.vsl_id
        , vm.in_voy_nbr
        , vm.out_voy_nbr
        , vm.eta
        , vm.ata
        , vm.etd
        , vm.atd
        , vm.gross_hours
        , vm.net_hours
        , vm.crane_no
        , count(*) AS moves
        , sum(vm.move_hours) AS worktimes
    FROM vvoi_and_moves vm
    GROUP BY 
        vm.vsl_id
        , vm.in_voy_nbr
        , vm.out_voy_nbr
        , vm.eta
        , vm.ata
        , vm.etd
        , vm.atd
        , vm.gross_hours
        , vm.net_hours
        , vm.crane_no
/*    ORDER BY
        coalesce(vm.atd,vm.etd)
        , vm.vsl_id
        , vm.crane_no
*/), gmph_components AS (
SELECT
    wt.vsl_id
    , wt.in_voy_nbr
    , wt.out_voy_nbr
    , wt.eta
    , wt.ata
    , wt.etd
    , wt.atd
    , wt.gross_hours
    , wt.net_hours
    , sum(wt.moves) AS moves
    , sum (CASE WHEN wt.crane_no IS NOT NULL THEN wt.worktimes ELSE 0 END) AS total_crane_working_hours --we don't want NULL crane_no IN the worktimes
FROM wt_by_crane wt
GROUP BY 
        wt.vsl_id
        , wt.in_voy_nbr
        , wt.out_voy_nbr
        , wt.eta
        , wt.ata
        , wt.etd
        , wt.atd
        , wt.gross_hours
        , wt.net_hours
/*    ORDER BY
        coalesce(wt.atd,wt.etd)
        , wt.vsl_id
*/)
SELECT
    to_char(trunc(COALESCE (gc.atd,gc.etd), 'MM'),'MM/DD/YYYY') AS analysis_month
    , 'ZLO' AS terminal_key
    , sum(gc.moves) AS total_moves
    , sum(gc.total_crane_working_hours) AS s2s_total_crane_working_hours
    , CASE WHEN sum(gc.total_crane_working_hours) = 0 THEN NULL ELSE sum(gc.moves) / sum(gc.total_crane_working_hours) END AS gmph
    --, CASE WHEN sum(gc.gross_hours) = 0 THEN NULL ELSE sum(gc.moves) / sum(gc.gross_hours) END AS GROSS
    --, CASE WHEN sum(gc.net_hours) = 0 THEN NULL ELSE sum(gc.moves) / sum(gc.net_hours) END AS NET
    , 'Oracle' AS platform
FROM gmph_components gc
GROUP BY 
    EXTRACT (YEAR FROM COALESCE (gc.atd,gc.etd))
    , EXTRACT (MONTH FROM COALESCE (gc.atd,gc.etd))
    , to_char(trunc(COALESCE (gc.atd,gc.etd), 'MM'),'MM/DD/YYYY')
ORDER BY 
    EXTRACT (YEAR FROM COALESCE (gc.atd,gc.etd))
    , EXTRACT (MONTH FROM COALESCE (gc.atd,gc.etd))
;

--Building the query for validation
WITH vessel_visits_of_interest AS (
    SELECT
        vv.vsl_id
        , vv.in_voy_nbr
        , vv.out_voy_nbr
        , vv.eta
        , vv.ata
        , vv.etd
        , vv.atd
        , vv.gross_hours
        , vv.net_hours
    FROM vessel_visits vv
    WHERE 
        /* GK: filtering by atd? BILL TODO, change to ACTUAL OR ESTIMATED departure */
        EXTRACT (YEAR FROM COALESCE(vv.atd,vv.etd)) IN ('2023','2024') --This CHANGE made NO difference TO the list OF vessel visits
    	--vv.atd IS NULL AND EXTRACT (YEAR FROM vv.etd) IN ('2023','2024')
        /* GK: this looks like the same logic for berth occupancy, is that accurate? YES, galen to add BO logic */
        AND (vv.atd IS NOT NULL OR 
                (vv.atd IS NULL AND vv.berth IS NOT NULL)) 
        AND COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) < 10
        AND COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) > 0
--    ORDER BY vv.atd, vv.vsl_id, vv.in_voy_nbr
), vvoi_and_moves AS (
    /* GK: The order of operations might be messing things up, we calculate crane events before filtering of vessel visits */
    SELECT
        vvoi.*
        , eh.crane_no
        , eh.posted AS move_start
        , lead (eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr ORDER BY eh.posted ASC) AS move_end
        , CASE
        	WHEN lead (eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr ORDER BY eh.posted ASC) > coalesce(vvoi.atd,vvoi.etd) THEN 0
        	WHEN eh.posted < COALESCE(vvoi.ata,vvoi.eta) THEN 0
        	WHEN eh.posted > lead (eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr ORDER BY eh.posted ASC) THEN 0
        	ELSE (lead (eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr ORDER BY eh.posted ASC) - eh.posted) * 24
          END AS move_hours
        --, greatest(0,(least (lead (eh.posted) OVER (PARTITION BY eh.crane_no ORDER BY eh.posted ASC), coalesce(vvoi.atd,vvoi.etd))
        --  - greatest(eh.posted,COALESCE(vvoi.ata,vvoi.eta)))) * 24 AS move_hours
    FROM vessel_visits_of_interest vvoi
    JOIN equipment_history eh ON
        vvoi.vsl_id = eh.vsl_id
        AND (vvoi.in_voy_nbr = eh.voy_nbr OR vvoi.out_voy_nbr = eh.voy_nbr)
        --AND eh.posted BETWEEN coalesce(vvoi.ata,vvoi.eta) AND coalesce(vvoi.atd, vvoi.etd)
        /* GK: these are the other filters that are applied to ours BILL TODOs 1) remove test 2) only include CTR 3) crane events must be between coalesced events:
            (upper(crane_number) not like 'TEST%' or crane_number is null)
            and equipment_class = 'CTR' /* Only include container equipment 

            -- then later on
            and crane_container_move_events.crane_event_started_at between --Only match events to moves during time 
            vessel_visits.actual_or_estimated_arrival_at
            and vessel_visits.actual_or_estimated_departure_at
         */
        AND eh.wtask_id IN ('LOAD','UNLOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
        AND (upper(eh.crane_no) NOT LIKE 'TEST%' OR eh.crane_no IS NULL) -- We want TO include NULL crane_no IN the move counts
        AND eh.eq_class = 'CTR' 
        AND eh.posted BETWEEN COALESCE (vvoi.ata, vvoi.eta) AND COALESCE (vvoi.atd, vvoi.etd)
    --ORDER BY COALESCE(vvoi.atd,vvoi.etd), eh.posted
), bmph_components AS (
    SELECT 
        vm.vsl_id
        , vm.in_voy_nbr
        , vm.out_voy_nbr
        , vm.eta
        , vm.ata
        , vm.etd
        , vm.atd
        , vm.gross_hours
        , vm.net_hours
        , count(*) AS moves
        , sum(vm.move_hours) AS worktimes --This time we do want TO include NULL WORK cranes IN the worktimes.
    FROM vvoi_and_moves vm
    GROUP BY 
        vm.vsl_id
        , vm.in_voy_nbr
        , vm.out_voy_nbr
        , vm.eta
        , vm.ata
        , vm.etd
        , vm.atd
        , vm.gross_hours
        , vm.net_hours
/*    ORDER BY
        coalesce(vm.atd,vm.etd)
        , vm.vsl_id
*/)
SELECT
    to_char(trunc(COALESCE (bc.atd,bc.etd), 'MM'),'MM/DD/YYYY') AS analysis_month
    , 'TPT' AS terminal_key
    , sum(bc.moves) AS bmph_total_container_moves
    , sum(bc.worktimes) AS bmph_total_worktime
    , CASE WHEN sum(bc.worktimes) = 0 THEN NULL ELSE sum(bc.moves) / sum(bc.worktimes) END AS berth_moves_per_hour
    --, CASE WHEN sum(gc.gross_hours) = 0 THEN NULL ELSE sum(gc.moves) / sum(gc.gross_hours) END AS GROSS
    --, CASE WHEN sum(gc.net_hours) = 0 THEN NULL ELSE sum(gc.moves) / sum(gc.net_hours) END AS NET
    , 'Oracle' AS platform
FROM bmph_components bc
GROUP BY 
    EXTRACT (YEAR FROM COALESCE (bc.atd,bc.etd))
    , EXTRACT (MONTH FROM COALESCE (bc.atd,bc.etd))
    , to_char(trunc(COALESCE (bc.atd,bc.etd), 'MM'),'MM/DD/YYYY')
ORDER BY 
    EXTRACT (YEAR FROM COALESCE (bc.atd,bc.etd))
    , EXTRACT (MONTH FROM COALESCE (bc.atd,bc.etd))
;

--Investigating TAM
--Building the query for validation
WITH vessel_visits_of_interest AS (
    SELECT
        vv.vsl_id
        , vv.in_voy_nbr
        , vv.out_voy_nbr
        , vv.eta
        , vv.ata
        , vv.etd
        , vv.atd
        , vv.gross_hours
        , vv.net_hours
    FROM vessel_visits vv
    WHERE 
        /* GK: filtering by atd? BILL TODO, change to ACTUAL OR ESTIMATED departure */
        EXTRACT (YEAR FROM COALESCE(vv.atd,vv.etd)) IN ('2023','2024') --This CHANGE made NO difference TO the list OF vessel visits
    	--vv.atd IS NULL AND EXTRACT (YEAR FROM vv.etd) IN ('2023','2024')
        /* GK: this looks like the same logic for berth occupancy, is that accurate? YES, galen to add BO logic */
        AND (vv.atd IS NOT NULL OR 
                (vv.atd IS NULL AND vv.berth IS NOT NULL)) 
        AND COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) < 10
        AND COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) > 0
--    ORDER BY vv.atd, vv.vsl_id, vv.in_voy_nbr
), vvoi_and_moves AS (
    /* GK: The order of operations might be messing things up, we calculate crane events before filtering of vessel visits */
    SELECT
        vvoi.*
        , eh.crane_no
        , eh.posted AS move_start
        , lead (eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr ORDER BY eh.posted ASC) AS move_end
        , CASE
        	WHEN lead (eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr ORDER BY eh.posted ASC) > coalesce(vvoi.atd,vvoi.etd) THEN 0
        	WHEN eh.posted < COALESCE(vvoi.ata,vvoi.eta) THEN 0
        	WHEN eh.posted > lead (eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr ORDER BY eh.posted ASC) THEN 0
        	ELSE (lead (eh.posted) OVER (PARTITION BY vvoi.vsl_id, vvoi.in_voy_nbr ORDER BY eh.posted ASC) - eh.posted) * 24
          END AS move_hours
        --, greatest(0,(least (lead (eh.posted) OVER (PARTITION BY eh.crane_no ORDER BY eh.posted ASC), coalesce(vvoi.atd,vvoi.etd))
        --  - greatest(eh.posted,COALESCE(vvoi.ata,vvoi.eta)))) * 24 AS move_hours
    FROM vessel_visits_of_interest vvoi
    JOIN equipment_history eh ON
        vvoi.vsl_id = eh.vsl_id
        AND (vvoi.in_voy_nbr = eh.voy_nbr OR vvoi.out_voy_nbr = eh.voy_nbr)
        --AND eh.posted BETWEEN coalesce(vvoi.ata,vvoi.eta) AND coalesce(vvoi.atd, vvoi.etd)
        /* GK: these are the other filters that are applied to ours BILL TODOs 1) remove test 2) only include CTR 3) crane events must be between coalesced events:
            (upper(crane_number) not like 'TEST%' or crane_number is null)
            and equipment_class = 'CTR' /* Only include container equipment 

            -- then later on
            and crane_container_move_events.crane_event_started_at between --Only match events to moves during time 
            vessel_visits.actual_or_estimated_arrival_at
            and vessel_visits.actual_or_estimated_departure_at
         */
        AND eh.wtask_id IN ('LOAD','UNLOAD','REHCC','REHCCT','REHCD','REHCDT','REHDC','REHDCT')
        AND (upper(eh.crane_no) NOT LIKE 'TEST%' OR eh.crane_no IS NULL) -- We want TO include NULL crane_no IN the move counts
        AND eh.eq_class = 'CTR' 
        AND eh.posted BETWEEN COALESCE (vvoi.ata, vvoi.eta) AND COALESCE (vvoi.atd, vvoi.etd)
    --ORDER BY COALESCE(vvoi.atd,vvoi.etd), eh.posted
)
SELECT
--	vnm.vsl_id AS vessel
--	, vnm.in_voy_nbr AS in_voy
--	, COALESCE (vnm.atd,vnm.etd) AS departure
	 vnm.crane_no
	, count(*)
FROM vvoi_and_moves vnm
GROUP BY 
--	vnm.vsl_id
--	, vnm.in_voy_nbr
	 vnm.crane_no
	--, vnm.atd
	--, vnm.etd
ORDER by	
	--COALESCE (vnm.atd,vnm.etd)
	--, vnm.vsl_id
	 2 desc
;