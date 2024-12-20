--Query from Daniel Molinar at MIT
SELECT EQUIPMENT_HISTORY.EQ_NBR as container_number
    , EQUIPMENT_HISTORY.status as container_status
    , EQUIPMENT_HISTORY.LOC_TYPE as container_location_type
    , EQUIPMENT_HISTORY.LINE_ID as roll_line_id
    , lroll.name as roll_line_name
    , EQUIPMENT_HISTORY.VOY_NBR
    , EQUIPMENT_HISTORY.EXP_SO_NBR as export_booking_number
    , EQUIPMENT_HISTORY.CREATED
    , EQUIPMENT_HISTORY.CREATOR
    , EQUIPMENT_HISTORY.WTASK_ID
    , EQUIPMENT_HISTORY.SZTP_ID
    , EQUIPMENT_HISTORY.VSL_ID as new_vessel_id
    , v.name as new_vessel_name
    , v.line_id as new_vessel_line_id
    , l.name as new_vessel_line_name
    , VESSEL_VISITS.IN_VOY_NBR as new_vv_in_voy_nbr
    , VESSEL_VISITS.OUT_VOY_NBR as new_vv_out_voy_nbr
    , VESSEL_VISITS.ATA as vv_ata
    , VESSEL_VISITS.ATD as vv_atd
    , case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
           when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
           else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
      end PRE_CARRIER
    , ( select x.ori_load_vsl_voy from (
        select h1.vsl_id || ' / ' || h1.voy_nbr as ori_load_vsl_voy
        , row_number() over (order by h1.posted desc, h1.wtask_id) as ordernum1
        from mtms.equipment_history h1
        where h1.equse_gkey = equipment_history.equse_gkey
        and h1.posted < equipment_history.posted
        and h1.removed is null
        and h1.vsl_id != 'CRFROLL'
        order by ordernum1
      ) x where rownum <= 1 ) as ORIGINAL_LOADING_VESSEL_VOYAGE
    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
    , ( select x.ori_dis_port from (
        select p2.name || ' (' || h2.discharge_port_id1 || ')' as ori_dis_port
        , row_number() over (order by h2.posted desc, h2.wtask_id) as ordernum2
        from mtms.equipment_history h2
        INNER JOIN mtms.handling_points p2 on h2.discharge_port_id1 = p2.id
        where h2.equse_gkey = equipment_history.equse_gkey
        and h2.posted < equipment_history.posted
        and h2.removed is null
        and h2.vsl_id != 'CRFROLL'
        order by ordernum2
        ) x where rownum <= 1) as ORIGINAL_DISCHARGE_PORT
    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
    , VESSEL_VISITS.OUT_SRVC_ID as vv_out_service_id
    , vserv.name as vv_out_service_name
FROM MTMS.VESSEL_VISITS VESSEL_VISITS
INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
INNER JOIN MTMS.line_operators l on v.line_id = l.id
INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
INNER JOIN mtms.services vserv on VESSEL_VISITS.OUT_SRVC_ID = vserv.id and v.line_id = vserv.line_id
INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
    -- Search by vessel visit ATD
    AND VESSEL_VISITS.ATD >= to_date('2024-01-01','YYYY-MM-DD')
    AND VESSEL_VISITS.ATD < to_date('2024-07-31','YYYY-MM-DD') + interval '1' DAY
    ---- Search by rolling event creation date
    --AND EQUIPMENT_HISTORY.CREATED >= to_date('2024-05-01','YYYY-MM-DD')
    --AND EQUIPMENT_HISTORY.CREATED < to_date('2024-05-05','YYYY-MM-DD') + interval '1' day
;

--Investigating how Daniel's query works.
SELECT EQUIPMENT_HISTORY.EQ_NBR as container_number
    , EQUIPMENT_HISTORY.status as container_status
    , EQUIPMENT_HISTORY.LOC_TYPE as container_location_type
    , EQUIPMENT_HISTORY.LINE_ID as roll_line_id
    --, lroll.name as roll_line_name
    , EQUIPMENT_HISTORY.VOY_NBR
    , EQUIPMENT_HISTORY.EXP_SO_NBR as export_booking_number
    , EQUIPMENT_HISTORY.CREATED
    , EQUIPMENT_HISTORY.CREATOR
    , EQUIPMENT_HISTORY.WTASK_ID
    , EQUIPMENT_HISTORY.SZTP_ID
    , EQUIPMENT_HISTORY.VSL_ID as new_vessel_id
    --, v.name as new_vessel_name
    --, v.line_id as new_vessel_line_id
    --, l.name as new_vessel_line_name
    , VESSEL_VISITS.IN_VOY_NBR as new_vv_in_voy_nbr
    , VESSEL_VISITS.OUT_VOY_NBR as new_vv_out_voy_nbr
    , VESSEL_VISITS.ATA as vv_ata
    , VESSEL_VISITS.ATD as vv_atd
    /*, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
           when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
           else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
      end PRE_CARRIER
    , ( select x.ori_load_vsl_voy from (
        select h1.vsl_id || ' / ' || h1.voy_nbr as ori_load_vsl_voy
        , row_number() over (order by h1.posted desc, h1.wtask_id) as ordernum1
        from mtms.equipment_history h1
        where h1.equse_gkey = equipment_history.equse_gkey
        and h1.posted < equipment_history.posted
        and h1.removed is null
        and h1.vsl_id != 'CRFROLL'
        order by ordernum1
      ) x where rownum <= 1 ) as ORIGINAL_LOADING_VESSEL_VOYAGE*/
    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
    /*, ( select x.ori_dis_port from (
        select p2.name || ' (' || h2.discharge_port_id1 || ')' as ori_dis_port
        , row_number() over (order by h2.posted desc, h2.wtask_id) as ordernum2
        from mtms.equipment_history h2
        INNER JOIN mtms.handling_points p2 on h2.discharge_port_id1 = p2.id
        where h2.equse_gkey = equipment_history.equse_gkey
        and h2.posted < equipment_history.posted
        and h2.removed is null
        and h2.vsl_id != 'CRFROLL'
        order by ordernum2
        ) x where rownum <= 1) as ORIGINAL_DISCHARGE_PORT
    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
    , VESSEL_VISITS.OUT_SRVC_ID as vv_out_service_id
    , vserv.name as vv_out_service_name*/
FROM MTMS.VESSEL_VISITS VESSEL_VISITS
INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
/*INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
INNER JOIN MTMS.line_operators l on v.line_id = l.id
INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
INNER JOIN mtms.services vserv on VESSEL_VISITS.OUT_SRVC_ID = vserv.id and v.line_id = vserv.line_id
INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id*/
WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
    -- Search by vessel visit ATD
    --trunc(VESSEL_VISITS.ATD) between to_date('2024-05-01','YYYY-MM-DD') AND to_date('2024-05-31','YYYY-MM-DD')
    ---- Search by rolling event creation date
    AND EQUIPMENT_HISTORY.CREATED >= to_date('2023-01-01','YYYY-MM-DD')
    AND EQUIPMENT_HISTORY.CREATED < to_date('2023-01-31','YYYY-MM-DD') + interval '1' day
;

SELECT * FROM vessel_visits WHERE trunc(atd) BETWEEN to_date('2024-05-01','YYYY-MM-DD') AND to_date('2024-05-31','YYYY-MM-DD');
SELECT * FROM equipment_history WHERE vsl_id = 'TOLEDO' AND voy_nbr = '402F';

--4816 records for May 1 through May 5 2024
SELECT count(*) FROM equipment_history 
WHERE (wtask_id = 'ROLL' OR wtask_id = 'SPLIT')
    AND EQUIPMENT_HISTORY.CREATED >= to_date('2024-01-01','YYYY-MM-DD')
    AND EQUIPMENT_HISTORY.CREATED < to_date('2024-08-01','YYYY-MM-DD') + interval '1' day
;

SELECT wtask_id, count(*) FROM equipment_history 
WHERE (wtask_id = 'ROLL' OR wtask_id = 'SPLIT')
    AND EQUIPMENT_HISTORY.CREATED >= to_date('2024-05-01','YYYY-MM-DD')
    AND EQUIPMENT_HISTORY.CREATED < to_date('2024-05-05','YYYY-MM-DD') + interval '1' day
GROUP BY wtask_id
;--split = 125 & roll = 4691 takes 2 seconds

SELECT wtask_id, count(*) FROM equipment_history 
WHERE (wtask_id = 'ROLL' OR wtask_id = 'SPLIT')
    AND trunc(EQUIPMENT_HISTORY.CREATED) between to_date('2024-05-01','YYYY-MM-DD') AND to_date('2024-05-05','YYYY-MM-DD')
GROUP BY wtask_id
;-- same tallies, but took 200 seconds

SELECT count(*) FROM equipment_history WHERE wtask_id = 'ROLL' OR wtask_id = 'SPLIT';

SELECT * FROM equipment_history 
WHERE (wtask_id = 'ROLL' OR wtask_id = 'SPLIT')
	AND created >= to_date('2024-05-01','YYYY-MM-DD')
	AND created < to_date('2024-06-01','YYYY-MM-DD')
	AND	eq_nbr = 'OOLU1795172'
;

SELECT * FROM equipment_history
WHERE eq_nbr = 'OOLU1795172'
ORDER BY created, gkey;

SELECT
	wtask_id, eq_class, status, loc_type, count(*)
FROM equipment_history eh
WHERE 
	(wtask_id = 'ROLL' OR wtask_id = 'SPLIT')
GROUP BY wtask_id, eq_class, status, loc_type
ORDER BY wtask_id, eq_class, status, loc_type
;

SELECT * FROM cg_ref_codes WHERE rv_domain = 'LOCATION TYPE';
SELECT DISTINCT RV_DOMAIN FROM CG_REF_CODES;

SELECT * FROM positions WHERE id = 'ITR';

SELECT DISTINCT rv_domain FROM cg_ref_codes;

-- New query from Daniel Molinar 13-Aug-2024
select x.vessel_id
, x.vessel_name
, x.vessel_line_id
, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
, x.out_voyage_number
, x.service_id
, x.service_name
, x.ATA
, x.ATD
, x.roll_line_id
, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
, count(container_number) as roll_quantity
from
(
select EQ_NBR as container_number
, EXP_SO_NBR as booking_number
, VSL_ID as vessel_id
, vessel_name
, vessel_line_id
, vessel_line_name
, VOY_NBR as out_voyage_number
, OUT_SRVC_ID as service_id
, service_name
, ATA
, ATD
, LINE_ID as roll_line_id
, roll_line_name
, CREATED
, CREATOR
, WTASK_ID
, SZTP_ID
--, PRE_CARRIER
, ORIGINAL_LOADING_VESSEL_VOYAGE
, NEW_LOADING_VESSEL_VOYAGE
, ORIGINAL_DISCHARGE_PORT
, NEW_DISCHARGE_PORT
from (
    SELECT EQUIPMENT_HISTORY.EQ_NBR
    , EQUIPMENT_HISTORY.LINE_ID
    , lroll.name as roll_line_name
    , EQUIPMENT_HISTORY.VOY_NBR
    , EQUIPMENT_HISTORY.EXP_SO_NBR
    , EQUIPMENT_HISTORY.CREATED
    , EQUIPMENT_HISTORY.CREATOR
    , EQUIPMENT_HISTORY.WTASK_ID
    , EQUIPMENT_HISTORY.SZTP_ID
    , EQUIPMENT_HISTORY.VSL_ID
    , v.name as vessel_name
    , v.line_id as vessel_line_id
    , l.name as vessel_line_name
    , VESSEL_VISITS.IN_VOY_NBR
    , VESSEL_VISITS.OUT_VOY_NBR
    , VESSEL_VISITS.ATA
    , VESSEL_VISITS.ATD
    ---- Requested by Maersk Line - RQS0113345
    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
    --  end PRE_CARRIER*/
    , ( select x.ori_load_vsl_voy from (
        select h1.vsl_id || ' / ' || h1.voy_nbr as ori_load_vsl_voy
        , row_number() over (order by h1.posted desc, h1.wtask_id) as ordernum1
        from mtms.equipment_history h1
        where h1.equse_gkey = equipment_history.equse_gkey
        and h1.posted < equipment_history.posted
        and h1.removed is null
        and h1.vsl_id != 'CRFROLL'
        order by ordernum1
      ) x where rownum <= 1 ) as ORIGINAL_LOADING_VESSEL_VOYAGE
    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
    , ( select x.ori_dis_port from (
        select p2.name || ' (' || h2.discharge_port_id1 || ')' as ori_dis_port
        , row_number() over (order by h2.posted desc, h2.wtask_id) as ordernum2
        from mtms.equipment_history h2
        INNER JOIN mtms.handling_points p2 on h2.discharge_port_id1 = p2.id
        where h2.equse_gkey = equipment_history.equse_gkey
        and h2.posted < equipment_history.posted
        and h2.removed is null
        and h2.vsl_id != 'CRFROLL'
        order by ordernum2
        ) x where rownum <= 1) as ORIGINAL_DISCHARGE_PORT
    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
    , VESSEL_VISITS.OUT_SRVC_ID
    , vserv.name as service_name
    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
    INNER JOIN MTMS.line_operators l on v.line_id = l.id
    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
    INNER JOIN mtms.services vserv on VESSEL_VISITS.OUT_SRVC_ID = vserv.id and v.line_id = vserv.line_id
    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
    AND EQUIPMENT_HISTORY.status = 'F'
    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
    AND v.line_id not in ('WIL')
    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
    AND VESSEL_VISITS.ATD >= to_date('2023-08-01' ,'YYYY-MM-DD')
    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' day
)
WHERE (ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
ORDER BY WTASK_ID, ORIGINAL_LOADING_VESSEL_VOYAGE, NEW_LOADING_VESSEL_VOYAGE
         , ORIGINAL_DISCHARGE_PORT, NEW_DISCHARGE_PORT, EQ_NBR
) x
group by x.vessel_id, x.vessel_name, x.vessel_line_id, x.vessel_line_name, x.out_voyage_number
, x.service_id, x.service_name, x.ATA, x.ATD, x.roll_line_id, x.roll_line_name
order by x.ATD, x.roll_line_id;

--Refactoring to simplify into just the Crow's Nest needs
select 
	x.vessel_id
	, x.vessel_name
	, x.vessel_line_id
	, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
	, x.out_voyage_number
	, x.service_id
	, x.service_name
	, x.ATA
	, x.ATD
	, x.roll_line_id
	, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
	, count(container_number) as roll_quantity
from
(
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from (
		SELECT 
			EQUIPMENT_HISTORY.EQ_NBR
		    , EQUIPMENT_HISTORY.LINE_ID
		    , lroll.name as roll_line_name
		    , EQUIPMENT_HISTORY.VOY_NBR
		    , EQUIPMENT_HISTORY.EXP_SO_NBR
		    , EQUIPMENT_HISTORY.CREATED
		    , EQUIPMENT_HISTORY.CREATOR
		    , EQUIPMENT_HISTORY.WTASK_ID
		    , EQUIPMENT_HISTORY.SZTP_ID
		    , EQUIPMENT_HISTORY.VSL_ID
		    , v.name as vessel_name
		    , v.line_id as vessel_line_id
		    , l.name as vessel_line_name
		    , VESSEL_VISITS.IN_VOY_NBR
		    , VESSEL_VISITS.OUT_VOY_NBR
		    , VESSEL_VISITS.ATA
		    , VESSEL_VISITS.ATD
		    ---- Requested by Maersk Line - RQS0113345
		    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
		    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
		    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
		    --  end PRE_CARRIER*/
		    , (select x.ori_load_vsl_voy 
		    	from (
			        select 
			        	h1.vsl_id || ' / ' || h1.voy_nbr as ori_load_vsl_voy
			        	, row_number() over (order by h1.posted desc, h1.wtask_id) as ordernum1
			        from mtms.equipment_history h1
			        where 
			        	h1.equse_gkey = equipment_history.equse_gkey
				        and h1.posted < equipment_history.posted
				        and h1.removed is null
				        and h1.vsl_id != 'CRFROLL'
			        order by ordernum1
			      ) x 
				where rownum <= 1) as ORIGINAL_LOADING_VESSEL_VOYAGE
		    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
		    , (select x.ori_dis_port 
		    	from (
		        	select 
		        		p2.name || ' (' || h2.discharge_port_id1 || ')' as ori_dis_port
		        		, row_number() over (order by h2.posted desc, h2.wtask_id) as ordernum2
		        	from mtms.equipment_history h2
		        	INNER JOIN mtms.handling_points p2 on h2.discharge_port_id1 = p2.id
		        where 
		        	h2.equse_gkey = equipment_history.equse_gkey
		        	and h2.posted < equipment_history.posted
		        	and h2.removed is null
		        	and h2.vsl_id != 'CRFROLL'
		        order by ordernum2
		        ) x where rownum <= 1) as ORIGINAL_DISCHARGE_PORT
		    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
		    , VESSEL_VISITS.OUT_SRVC_ID
		    , vserv.name as service_name
		    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
		    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
		    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
		    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
		    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
		    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
		    INNER JOIN MTMS.line_operators l on v.line_id = l.id
		    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
		    INNER JOIN mtms.services vserv on 
		    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
		    	and v.line_id = vserv.line_id
		    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
		    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2024-07-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' day
	)
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
) x
group by 
	x.vessel_id
	, x.vessel_name
	, x.vessel_line_id
	, x.vessel_line_name
	, x.out_voyage_number
	, x.service_id
	, x.service_name
	, x.ATA
	, x.ATD
	, x.roll_line_id
	, x.roll_line_name
order by 
	x.ATD
	, x.roll_line_id
;

--step 1
WITH x AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from (
		SELECT 
			EQUIPMENT_HISTORY.EQ_NBR
		    , EQUIPMENT_HISTORY.LINE_ID
		    , lroll.name as roll_line_name
		    , EQUIPMENT_HISTORY.VOY_NBR
		    , EQUIPMENT_HISTORY.EXP_SO_NBR
		    , EQUIPMENT_HISTORY.CREATED
		    , EQUIPMENT_HISTORY.CREATOR
		    , EQUIPMENT_HISTORY.WTASK_ID
		    , EQUIPMENT_HISTORY.SZTP_ID
		    , EQUIPMENT_HISTORY.VSL_ID
		    , v.name as vessel_name
		    , v.line_id as vessel_line_id
		    , l.name as vessel_line_name
		    , VESSEL_VISITS.IN_VOY_NBR
		    , VESSEL_VISITS.OUT_VOY_NBR
		    , VESSEL_VISITS.ATA
		    , VESSEL_VISITS.ATD
		    ---- Requested by Maersk Line - RQS0113345
		    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
		    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
		    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
		    --  end PRE_CARRIER*/
		    , (select x.ori_load_vsl_voy 
		    	from (
			        select 
			        	h1.vsl_id || ' / ' || h1.voy_nbr as ori_load_vsl_voy
			        	, row_number() over (order by h1.posted desc, h1.wtask_id) as ordernum1
			        from mtms.equipment_history h1
			        where 
			        	h1.equse_gkey = equipment_history.equse_gkey
				        and h1.posted < equipment_history.posted
				        and h1.removed is null
				        and h1.vsl_id != 'CRFROLL'
			        order by ordernum1
			      ) x 
				where rownum <= 1) as ORIGINAL_LOADING_VESSEL_VOYAGE
		    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
		    , (select x.ori_dis_port 
		    	from (
		        	select 
		        		p2.name || ' (' || h2.discharge_port_id1 || ')' as ori_dis_port
		        		, row_number() over (order by h2.posted desc, h2.wtask_id) as ordernum2
		        	from mtms.equipment_history h2
		        	INNER JOIN mtms.handling_points p2 on h2.discharge_port_id1 = p2.id
		        where 
		        	h2.equse_gkey = equipment_history.equse_gkey
		        	and h2.posted < equipment_history.posted
		        	and h2.removed is null
		        	and h2.vsl_id != 'CRFROLL'
		        order by ordernum2
		        ) x where rownum <= 1) as ORIGINAL_DISCHARGE_PORT
		    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
		    , VESSEL_VISITS.OUT_SRVC_ID
		    , vserv.name as service_name
		    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
		    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
		    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
		    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
		    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
		    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
		    INNER JOIN MTMS.line_operators l on v.line_id = l.id
		    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
		    INNER JOIN mtms.services vserv on 
		    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
		    	and v.line_id = vserv.line_id
		    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
		    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2024-07-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' day
	)
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
)
select 
	x.vessel_id
	, x.vessel_name
	, x.vessel_line_id
	, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
	, x.out_voyage_number
	, x.service_id
	, x.service_name
	, x.ATA
	, x.ATD
	, x.roll_line_id
	, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
	, count(container_number) as roll_quantity
from x
group by 
	x.vessel_id
	, x.vessel_name
	, x.vessel_line_id
	, x.vessel_line_name
	, x.out_voyage_number
	, x.service_id
	, x.service_name
	, x.ATA
	, x.ATD
	, x.roll_line_id
	, x.roll_line_name
order by 
	x.ATD
	, x.roll_line_id
;

--step2
WITH a AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , (select x.ori_load_vsl_voy 
	    	from (
		        select 
		        	h1.vsl_id || ' / ' || h1.voy_nbr as ori_load_vsl_voy
		        	, row_number() over (order by h1.posted desc, h1.wtask_id) as ordernum1
		        from mtms.equipment_history h1
		        where 
		        	h1.equse_gkey = equipment_history.equse_gkey
			        and h1.posted < equipment_history.posted
			        and h1.removed is null
			        and h1.vsl_id != 'CRFROLL'
		        order by ordernum1
		      ) x 
			where rownum <= 1) as ORIGINAL_LOADING_VESSEL_VOYAGE
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , (select x.ori_dis_port 
	    	from (
	        	select 
	        		p2.name || ' (' || h2.discharge_port_id1 || ')' as ori_dis_port
	        		, row_number() over (order by h2.posted desc, h2.wtask_id) as ordernum2
	        	from mtms.equipment_history h2
	        	INNER JOIN mtms.handling_points p2 on h2.discharge_port_id1 = p2.id
	        where 
	        	h2.equse_gkey = equipment_history.equse_gkey
	        	and h2.posted < equipment_history.posted
	        	and h2.removed is null
	        	and h2.vsl_id != 'CRFROLL'
	        order by ordernum2
	        ) x where rownum <= 1) as ORIGINAL_DISCHARGE_PORT
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
	    AND EQUIPMENT_HISTORY.status = 'F'
	    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
	    AND v.line_id not in ('WIL')
	    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
	    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
	    AND VESSEL_VISITS.ATD >= to_date('2024-07-01' ,'YYYY-MM-DD')
	    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' day
), x AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from a
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
)
select 
	x.vessel_id
	, x.vessel_name
	, x.vessel_line_id
	, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
	, x.out_voyage_number
	, x.service_id
	, x.service_name
	, x.ATA
	, x.ATD
	, x.roll_line_id
	, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
	, count(container_number) as roll_quantity
from x
group by 
	x.vessel_id
	, x.vessel_name
	, x.vessel_line_id
	, x.vessel_line_name
	, x.out_voyage_number
	, x.service_id
	, x.service_name
	, x.ATA
	, x.ATD
	, x.roll_line_id
	, x.roll_line_name
order by 
	x.ATD
	, x.roll_line_id
;

--step3
WITH a AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , (select x.ori_load_vsl_voy 
	    	from (
		        select 
		        	h1.vsl_id || ' / ' || h1.voy_nbr as ori_load_vsl_voy
		        	, row_number() over (order by h1.posted desc, h1.wtask_id) as ordernum1
		        from mtms.equipment_history h1
		        where 
		        	h1.equse_gkey = equipment_history.equse_gkey
			        and h1.posted < equipment_history.posted
			        and h1.removed is null
			        and h1.vsl_id != 'CRFROLL'
		        order by ordernum1
		      ) x 
			where rownum <= 1) as ORIGINAL_LOADING_VESSEL_VOYAGE
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , (select x.ori_dis_port 
	    	from (
	        	select 
	        		p2.name || ' (' || h2.discharge_port_id1 || ')' as ori_dis_port
	        		, row_number() over (order by h2.posted desc, h2.wtask_id) as ordernum2
	        	from mtms.equipment_history h2
	        	INNER JOIN mtms.handling_points p2 on h2.discharge_port_id1 = p2.id
	        where 
	        	h2.equse_gkey = equipment_history.equse_gkey
	        	and h2.posted < equipment_history.posted
	        	and h2.removed is null
	        	and h2.vsl_id != 'CRFROLL'
	        order by ordernum2
	        ) x where rownum <= 1) as ORIGINAL_DISCHARGE_PORT
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    , equipment_history.equse_gkey
	    , equipment_history.posted
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2024-07-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), x AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from a
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
)
SELECT * FROM final
;

select x.ori_load_vsl_voy 
	    	from (
		        select 
		        	h1.vsl_id || ' / ' || h1.voy_nbr as ori_load_vsl_voy
		        	, row_number() over (order by h1.posted desc, h1.wtask_id) as ordernum1
		        from mtms.equipment_history h1
		        where 
		        	h1.equse_gkey = '25864274'
			        and h1.posted < to_timestamp('2024-06-29 13:47:47.000','YYYY-MM-DD HH24:MI:SS.FF3')
			        and h1.removed is null
			        and h1.vsl_id != 'CRFROLL'
		        order by ordernum1
		      ) x 
			where rownum <= 1;

		        select 
		        	h1.vsl_id || ' / ' || h1.voy_nbr as ori_load_vsl_voy
		        	, row_number() over (order by h1.posted desc, h1.wtask_id) as ordernum1
		        	, h1.posted AS eh_posted
		        	, to_timestamp('2024-06-29 13:47:47.000','YYYY-MM-DD HH24:MI:SS.FF3') AS a_posted
		        from mtms.equipment_history h1
		        where 
		        	h1.equse_gkey = '25864274'
			        and h1.posted < to_timestamp('2024-06-29 13:47:47.000','YYYY-MM-DD HH24:MI:SS.FF3')
			        and h1.removed is null
			        and h1.vsl_id != 'CRFROLL'
		        order by ordernum1

		
--Step 4
WITH a AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2024-07-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), b AS (
	SELECT
		a.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
      	, row_number() over (PARTITION BY eh.equse_gkey, a.posted order by eh.posted desc, eh.wtask_id) as ordernum1
	FROM a
	INNER JOIN equipment_history eh ON
		a.equse_gkey = eh.equse_gkey
		AND a.posted > eh.posted
	WHERE 
		eh.removed is null
        and eh.vsl_id != 'CRFROLL'
), c AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
	FROM b
	WHERE ordernum1 = 1
), d AS (
	SELECT 
		a.*
		, c.ORIGINAL_LOADING_VESSEL_VOYAGE
	FROM a
	INNER JOIN c ON 
		a.eq_nbr = c.eq_nbr
		AND a.equse_gkey = c.equse_gkey
		AND a.posted = c.posted
), e AS (
	select 
		d.*
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, row_number() over (PARTITION BY eh.equse_gkey, d.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from d
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = d.equse_gkey
		and eh.posted < d.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), f AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM e
	WHERE ordernum = 1
), g AS (
	SELECT 
		d.*
		, f.ORIGINAL_DISCHARGE_PORT
	FROM d
	INNER JOIN f ON 
		d.eq_nbr = f.eq_nbr
		AND d.equse_gkey = f.equse_gkey
		AND d.posted = f.posted
), x AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from g
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
)
SELECT * FROM final
;

--Step 5
WITH rolls_current_attributes AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2024-07-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), prior_eq_hist_events AS (
	select 
		rolls_current_attributes.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, row_number() over (PARTITION BY eh.equse_gkey, rolls_current_attributes.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from rolls_current_attributes
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = rolls_current_attributes.equse_gkey
		and eh.posted < rolls_current_attributes.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), first_eq_hist_events AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM prior_eq_hist_events
	WHERE ordernum = 1
), orig_attributes_joined AS (
	SELECT 
		rolls_current_attributes.*
		, first_eq_hist_events.ORIGINAL_LOADING_VESSEL_VOYAGE
		, first_eq_hist_events.ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_attributes
	INNER JOIN first_eq_hist_events ON 
		rolls_current_attributes.eq_nbr = first_eq_hist_events.eq_nbr
		AND rolls_current_attributes.equse_gkey = first_eq_hist_events.equse_gkey
		AND rolls_current_attributes.posted = first_eq_hist_events.posted
), rolls_current_and_orig_atts AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from orig_attributes_joined
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from rolls_current_and_orig_atts x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
)
SELECT * FROM final
;

--Aggregating nearly a year's worth of data to prototype
WITH rolls_current_attributes AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2023-09-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2024-08-01' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), prior_eq_hist_events AS (
	select 
		rolls_current_attributes.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, row_number() over (PARTITION BY eh.equse_gkey, rolls_current_attributes.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from rolls_current_attributes
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = rolls_current_attributes.equse_gkey
		and eh.posted < rolls_current_attributes.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), first_eq_hist_events AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM prior_eq_hist_events
	WHERE ordernum = 1
), orig_attributes_joined AS (
	SELECT 
		rolls_current_attributes.*
		, first_eq_hist_events.ORIGINAL_LOADING_VESSEL_VOYAGE
		, first_eq_hist_events.ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_attributes
	INNER JOIN first_eq_hist_events ON 
		rolls_current_attributes.eq_nbr = first_eq_hist_events.eq_nbr
		AND rolls_current_attributes.equse_gkey = first_eq_hist_events.equse_gkey
		AND rolls_current_attributes.posted = first_eq_hist_events.posted
), rolls_current_and_orig_atts AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from orig_attributes_joined
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from rolls_current_and_orig_atts x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
)
SELECT * FROM final
;

/*Investigating Sean's questions
 * Wouldn't we want to order by eh.posted asc to get the first event, and true "original"? 
 */
WITH rolls_current_attributes AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2023-08-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), prior_eq_hist_events AS (
	select 
		rolls_current_attributes.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, eh.posted AS eq_hist_posted
		, row_number() over (PARTITION BY eh.equse_gkey, rolls_current_attributes.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from rolls_current_attributes
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = rolls_current_attributes.equse_gkey
		and eh.posted < rolls_current_attributes.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), first_eq_hist_events AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM prior_eq_hist_events
	WHERE ordernum = 1
), orig_attributes_joined AS (
	SELECT 
		rolls_current_attributes.*
		, first_eq_hist_events.ORIGINAL_LOADING_VESSEL_VOYAGE
		, first_eq_hist_events.ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_attributes
	INNER JOIN first_eq_hist_events ON 
		rolls_current_attributes.eq_nbr = first_eq_hist_events.eq_nbr
		AND rolls_current_attributes.equse_gkey = first_eq_hist_events.equse_gkey
		AND rolls_current_attributes.posted = first_eq_hist_events.posted
), rolls_current_and_orig_atts AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from orig_attributes_joined
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from rolls_current_and_orig_atts x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
), prior_events AS (
	SELECT 
		eq_nbr
		, new_loading_vessel_voyage
		, ori_load_vsl_voy
		, new_discharge_port
		, ori_dis_port
		, ordernum 
		, eq_hist_posted
	FROM prior_eq_hist_events 
	WHERE equse_gkey = '24450729' 
	ORDER BY 
		equse_gkey
		, posted
		, ordernum
), rolled_containers AS (
	SELECT
		container_number
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_DISCHARGE_PORT
		, ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_and_orig_atts rolls
	WHERE vessel_id = 'ROBIN5'
)
SELECT * FROM prior_events;

--Redo using equipment_uses_jn
WITH mit_uses AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, eq_class
		, category
		, status
		, discharge_port_id1 AS disch_port
		, so_line_id
		, out_loc_type
		, out_loc_id
		, out_visit_id
		, in_yard_date AS IN_yard_at
		, out_yard_date AS out_yard_at
		, ROW_NUMBER() OVER (PARTITION BY gkey ORDER BY jn_entryid) AS jn_version
		, row_number() OVER (PARTITION BY gkey ORDER BY jn_entryid desc) AS rev_jn_version 
	FROM equipment_uses_jn
), renomination_history AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, so_line_id
		, out_loc_id
		, out_visit_id
		, CASE
			WHEN
				(
					disch_port != lag(disch_port) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR out_loc_id != lag(out_loc_id) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR out_visit_id != lag(out_visit_id) OVER (PARTITION BY gkey ORDER BY jn_entryid)
				)
				AND out_loc_type = 'V'
				AND lag(out_loc_type) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'V'
				AND status = 'F'
				AND lag(status) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'F'
				AND eq_class = 'CTR'
			THEN 'Renomination event'
			ELSE 'Not renomination event'
		END AS renomination_label
	FROM mit_uses
	ORDER BY 
		gkey
		, jn_entryid
), renom_data AS (
	SELECT *
	FROM renomination_history
	WHERE renomination_label = 'Renomination event'
)
SELECT * FROM renom_data --FETCH FIRST 10000 ROWS ONLY 
;

--de-aggregating for comparison to prototype
WITH rolls_current_attributes AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2023-08-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), prior_eq_hist_events AS (
	select 
		rolls_current_attributes.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, row_number() over (PARTITION BY eh.equse_gkey, rolls_current_attributes.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from rolls_current_attributes
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = rolls_current_attributes.equse_gkey
		and eh.posted < rolls_current_attributes.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), first_eq_hist_events AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM prior_eq_hist_events
	WHERE ordernum = 1
), orig_attributes_joined AS (
	SELECT 
		rolls_current_attributes.*
		, first_eq_hist_events.ORIGINAL_LOADING_VESSEL_VOYAGE
		, first_eq_hist_events.ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_attributes
	INNER JOIN first_eq_hist_events ON 
		rolls_current_attributes.eq_nbr = first_eq_hist_events.eq_nbr
		AND rolls_current_attributes.equse_gkey = first_eq_hist_events.equse_gkey
		AND rolls_current_attributes.posted = first_eq_hist_events.posted
), rolls_current_and_orig_atts AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from orig_attributes_joined
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from rolls_current_and_orig_atts x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
)
SELECT * FROM rolls_current_and_orig_atts
;

SELECT *
FROM equipment_uses_jn
WHERE eq_nbr = 'APZU3640720'
ORDER BY
	gkey
	, jn_entryid
;

SELECT *
FROM equipment_history
WHERE eq_nbr = 'AIRU4557974'
ORDER BY
	gkey
;

--Redo using equipment_uses_jn
WITH mit_uses AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, eq_class
		, category
		, status
		, discharge_port_id1 AS disch_port
		, so_line_id
		, so_vsl_id
		, so_voy_nbr
		, in_yard_date AS IN_yard_at
		, out_yard_date AS out_yard_at
		, ROW_NUMBER() OVER (PARTITION BY gkey ORDER BY jn_entryid) AS jn_version
		, row_number() OVER (PARTITION BY gkey ORDER BY jn_entryid desc) AS rev_jn_version 
	FROM equipment_uses_jn
), renomination_history AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, so_line_id
		, so_vsl_id
		, so_voy_nbr
		, CASE
			WHEN
				(
					disch_port != lag(disch_port) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR so_vsl_id != lag(so_vsl_id) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR so_voy_nbr != lag(so_voy_nbr) OVER (PARTITION BY gkey ORDER BY jn_entryid)
				)
				AND category = 'E'
				AND lag(category) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'E'
				AND status = 'F'
				AND lag(status) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'F'
				AND eq_class = 'CTR'
			THEN 'Renomination event'
			ELSE 'Not renomination event'
		END AS renomination_label
	FROM mit_uses
	ORDER BY 
		gkey
		, jn_entryid
), renom_data AS (
	SELECT *
	FROM renomination_history
	WHERE renomination_label = 'Renomination event'
)
SELECT * FROM renom_data --FETCH FIRST 10 ROWS ONLY 
;

--Redo using equipment_uses_jn for ZLO
WITH mit_uses AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, eq_class
		, category
		, status
		, discharge_port_id1 AS disch_port
		, so_line_id
		, so_vsl_id
		, so_voy_nbr
		, in_yard_date AS IN_yard_at
		, out_yard_date AS out_yard_at
		, ROW_NUMBER() OVER (PARTITION BY gkey ORDER BY jn_entryid) AS jn_version
		, row_number() OVER (PARTITION BY gkey ORDER BY jn_entryid desc) AS rev_jn_version 
	FROM equipment_uses_jn
), renomination_history AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, so_line_id
		, so_vsl_id
		, so_voy_nbr
		, CASE
			WHEN
				(
					disch_port != lag(disch_port) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR so_vsl_id != lag(so_vsl_id) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR so_voy_nbr != lag(so_voy_nbr) OVER (PARTITION BY gkey ORDER BY jn_entryid)
				)
				AND category = 'E'
				AND lag(category) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'E'
				AND status = 'F'
				AND lag(status) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'F'
				AND eq_class = 'CTR'
			THEN 'Renomination event'
			ELSE 'Not renomination event'
		END AS renomination_label
	FROM mit_uses
	ORDER BY 
		gkey
		, jn_entryid
), renom_data AS (
	SELECT *
	FROM renomination_history
	WHERE renomination_label = 'Renomination event'
)
SELECT * FROM renom_data --FETCH FIRST 10000 ROWS ONLY 
;

--Running the MIT query refactor for ZLO
WITH rolls_current_attributes AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2022-09-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2023-08-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), prior_eq_hist_events AS (
	select 
		rolls_current_attributes.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, row_number() over (PARTITION BY eh.equse_gkey, rolls_current_attributes.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from rolls_current_attributes
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = rolls_current_attributes.equse_gkey
		and eh.posted < rolls_current_attributes.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), first_eq_hist_events AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM prior_eq_hist_events
	WHERE ordernum = 1
), orig_attributes_joined AS (
	SELECT 
		rolls_current_attributes.*
		, first_eq_hist_events.ORIGINAL_LOADING_VESSEL_VOYAGE
		, first_eq_hist_events.ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_attributes
	INNER JOIN first_eq_hist_events ON 
		rolls_current_attributes.eq_nbr = first_eq_hist_events.eq_nbr
		AND rolls_current_attributes.equse_gkey = first_eq_hist_events.equse_gkey
		AND rolls_current_attributes.posted = first_eq_hist_events.posted
), rolls_current_and_orig_atts AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from orig_attributes_joined
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from rolls_current_and_orig_atts x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
)
SELECT * FROM final
;

/* 
 * The MIT query and the prototype are consistently high. I wonder if ZLO permits only one renomination per container.
 * I'll modify the MIT query to produce one renomination per gkey only. I'll pick the most recent roll to catalog.
 */
WITH rolls_current_attributes AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2022-09-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2023-08-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), prior_eq_hist_events AS (
	select 
		rolls_current_attributes.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, row_number() over (PARTITION BY eh.equse_gkey, rolls_current_attributes.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from rolls_current_attributes
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = rolls_current_attributes.equse_gkey
		and eh.posted < rolls_current_attributes.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), first_eq_hist_events AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM prior_eq_hist_events
	WHERE ordernum = 1
), orig_attributes_joined AS (
	SELECT 
		rolls_current_attributes.*
		, first_eq_hist_events.ORIGINAL_LOADING_VESSEL_VOYAGE
		, first_eq_hist_events.ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_attributes
	INNER JOIN first_eq_hist_events ON 
		rolls_current_attributes.eq_nbr = first_eq_hist_events.eq_nbr
		AND rolls_current_attributes.equse_gkey = first_eq_hist_events.equse_gkey
		AND rolls_current_attributes.posted = first_eq_hist_events.posted
), rolls_current_and_orig_atts AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
		, row_number() OVER (PARTITION BY equse_gkey ORDER BY atd desc) AS rn
	from orig_attributes_joined
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), most_recent_roll AS (
	SELECT * 
	FROM rolls_current_and_orig_atts
	WHERE rn = 1
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from most_recent_roll x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
)
SELECT * FROM final
;

--PCT
--10,214,981 - I can't extract that and I don't want to split it to bring into Snowflake.
SELECT count(*) FROM equipment_uses_jn;

--Redo using equipment_uses_jn for PCT
WITH mit_uses AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, eq_class
		, category
		, status
		, discharge_port_id1 AS disch_port
		, so_line_id
		, so_vsl_id
		, so_voy_nbr
		, in_yard_date AS IN_yard_at
		, out_yard_date AS out_yard_at
		, ROW_NUMBER() OVER (PARTITION BY gkey ORDER BY jn_entryid) AS jn_version
		, row_number() OVER (PARTITION BY gkey ORDER BY jn_entryid desc) AS rev_jn_version 
	FROM equipment_uses_jn
), renomination_history AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, so_line_id
		, so_vsl_id
		, so_voy_nbr
		, CASE
			WHEN
				(
					disch_port != lag(disch_port) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR so_vsl_id != lag(so_vsl_id) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR so_voy_nbr != lag(so_voy_nbr) OVER (PARTITION BY gkey ORDER BY jn_entryid)
				)
				AND category = 'E'
				AND lag(category) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'E'
				AND status = 'F'
				AND lag(status) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'F'
				AND eq_class = 'CTR'
			THEN 'Renomination event'
			ELSE 'Not renomination event'
		END AS renomination_label
	FROM mit_uses
	ORDER BY 
		gkey
		, jn_entryid
), renom_data AS (
	SELECT *
	FROM renomination_history
	WHERE renomination_label = 'Renomination event'
)
SELECT * FROM renom_data --FETCH FIRST 1000 ROWS ONLY 
;

--Running the MIT query refactor for PCT
WITH rolls_current_attributes AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    --AND VESSEL_VISITS.ATD >= to_date('2022-09-01' ,'YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2023-08-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), prior_eq_hist_events AS (
	select 
		rolls_current_attributes.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, row_number() over (PARTITION BY eh.equse_gkey, rolls_current_attributes.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from rolls_current_attributes
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = rolls_current_attributes.equse_gkey
		and eh.posted < rolls_current_attributes.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), first_eq_hist_events AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM prior_eq_hist_events
	WHERE ordernum = 1
), orig_attributes_joined AS (
	SELECT 
		rolls_current_attributes.*
		, first_eq_hist_events.ORIGINAL_LOADING_VESSEL_VOYAGE
		, first_eq_hist_events.ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_attributes
	INNER JOIN first_eq_hist_events ON 
		rolls_current_attributes.eq_nbr = first_eq_hist_events.eq_nbr
		AND rolls_current_attributes.equse_gkey = first_eq_hist_events.equse_gkey
		AND rolls_current_attributes.posted = first_eq_hist_events.posted
), rolls_current_and_orig_atts AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from orig_attributes_joined
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from rolls_current_and_orig_atts x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
)
SELECT * FROM final
;


--TAM
--1,999,276 - I could extract this, bud I don't want to split it to bring into Snowflake.
SELECT count(*) FROM equipment_uses_jn;

--Redo using equipment_uses_jn for TAM
WITH mit_uses AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, eq_class
		, category
		, status
		, discharge_port_id1 AS disch_port
		, so_line_id
		, so_vsl_id
		, so_voy_nbr
		, in_yard_date AS IN_yard_at
		, out_yard_date AS out_yard_at
		, ROW_NUMBER() OVER (PARTITION BY gkey ORDER BY jn_entryid) AS jn_version
		, row_number() OVER (PARTITION BY gkey ORDER BY jn_entryid desc) AS rev_jn_version 
	FROM equipment_uses_jn
), renomination_history AS (
	SELECT
		gkey
		, jn_entryid
		, jn_datetime
		, eq_nbr
		, so_line_id
		, so_vsl_id
		, so_voy_nbr
		, CASE
			WHEN
				(
					disch_port != lag(disch_port) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR so_vsl_id != lag(so_vsl_id) OVER (PARTITION BY gkey ORDER BY jn_entryid)
					OR so_voy_nbr != lag(so_voy_nbr) OVER (PARTITION BY gkey ORDER BY jn_entryid)
				)
				AND category = 'E'
				AND lag(category) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'E'
				AND status = 'F'
				AND lag(status) OVER (PARTITION BY gkey ORDER BY jn_entryid) = 'F'
				AND eq_class = 'CTR'
			THEN 'Renomination event'
			ELSE 'Not renomination event'
		END AS renomination_label
	FROM mit_uses
	ORDER BY 
		gkey
		, jn_entryid
), renom_data AS (
	SELECT *
	FROM renomination_history
	WHERE renomination_label = 'Renomination event'
)
SELECT * FROM renom_data --FETCH FIRST 1000 ROWS ONLY 
;

--Running the MIT query refactor for TAM
WITH rolls_current_attributes AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    --AND VESSEL_VISITS.ATD >= to_date('2022-09-01' ,'YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2023-08-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), prior_eq_hist_events AS (
	select 
		rolls_current_attributes.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, row_number() over (PARTITION BY eh.equse_gkey, rolls_current_attributes.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from rolls_current_attributes
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = rolls_current_attributes.equse_gkey
		and eh.posted < rolls_current_attributes.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), first_eq_hist_events AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM prior_eq_hist_events
	WHERE ordernum = 1
), orig_attributes_joined AS (
	SELECT 
		rolls_current_attributes.*
		, first_eq_hist_events.ORIGINAL_LOADING_VESSEL_VOYAGE
		, first_eq_hist_events.ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_attributes
	INNER JOIN first_eq_hist_events ON 
		rolls_current_attributes.eq_nbr = first_eq_hist_events.eq_nbr
		AND rolls_current_attributes.equse_gkey = first_eq_hist_events.equse_gkey
		AND rolls_current_attributes.posted = first_eq_hist_events.posted
), rolls_current_and_orig_atts AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from orig_attributes_joined
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from rolls_current_and_orig_atts x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.ATD
		, x.roll_line_id
)
SELECT * FROM final
;

/* Work associated with int_renomination_events */
SELECT count(*)
FROM equipment_uses_jn
WHERE
	extract(YEAR FROM jn_datetime) = '2024'
	AND EXTRACT(MONTH FROM jn_datetime) = '7'
;

--Aggregating nearly a year's worth of data to prototype
WITH rolls_current_attributes AS (
	SELECT 
		EQUIPMENT_HISTORY.EQ_NBR
	    , EQUIPMENT_HISTORY.LINE_ID
	    , lroll.name as roll_line_name
	    , EQUIPMENT_HISTORY.VOY_NBR
	    , EQUIPMENT_HISTORY.EXP_SO_NBR
	    , EQUIPMENT_HISTORY.CREATED
	    , EQUIPMENT_HISTORY.CREATOR
	    , EQUIPMENT_HISTORY.WTASK_ID
	    , EQUIPMENT_HISTORY.SZTP_ID
	    , EQUIPMENT_HISTORY.VSL_ID
	    , EQUIPMENT_HISTORY.equse_gkey
	    , EQUIPMENT_HISTORY.posted
	    , equipment_history.gkey
	    , v.name as vessel_name
	    , v.line_id as vessel_line_id
	    , l.name as vessel_line_name
	    , VESSEL_VISITS.IN_VOY_NBR
	    , VESSEL_VISITS.OUT_VOY_NBR
	    , VESSEL_VISITS.ATA
	    , VESSEL_VISITS.ATD
	    ---- Requested by Maersk Line - RQS0113345
	    --, case when u.in_loc_type = 'V' then 'Vessel' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --       when u.in_loc_type = 'T' then 'Truck' || ' - ' || u.in_loc_id || ' (' || u.in_carrier_id || ')'
	    --       else u.in_loc_type || ' Unknown' || ' - ' || u.in_loc_id || ' / ' || u.in_visit_id || ' (' || u.in_carrier_id || ')'
	    --  end PRE_CARRIER*/
	    , EQUIPMENT_HISTORY.VSL_ID || ' / ' || EQUIPMENT_HISTORY.VOY_NBR AS NEW_LOADING_VESSEL_VOYAGE
	    , p1.name || ' (' || equipment_history.discharge_port_id1 || ')' as NEW_DISCHARGE_PORT
	    , VESSEL_VISITS.OUT_SRVC_ID
	    , vserv.name as service_name
	    FROM MTMS.VESSEL_VISITS VESSEL_VISITS
	    INNER JOIN MTMS.EQUIPMENT_HISTORY EQUIPMENT_HISTORY on 
	    	VESSEL_VISITS.VSL_ID = EQUIPMENT_HISTORY.VSL_ID 
	    	AND VESSEL_VISITS.OUT_VOY_NBR = EQUIPMENT_HISTORY.VOY_NBR
	    --INNER JOIN MTMS.equipment_uses u on equipment_history.equse_gkey = u.gkey
	    INNER JOIN MTMS.vessels v on EQUIPMENT_HISTORY.vsl_id = v.id
	    INNER JOIN MTMS.line_operators l on v.line_id = l.id
	    INNER JOIN mtms.handling_points p1 on EQUIPMENT_HISTORY.discharge_port_id1 = p1.id
	    INNER JOIN mtms.services vserv on 
	    	VESSEL_VISITS.OUT_SRVC_ID = vserv.id 
	    	and v.line_id = vserv.line_id
	    INNER JOIN MTMS.line_operators lroll on EQUIPMENT_HISTORY.line_id = lroll.id
	    WHERE (EQUIPMENT_HISTORY.WTASK_ID = 'ROLL' OR EQUIPMENT_HISTORY.WTASK_ID = 'SPLIT')
		    AND EQUIPMENT_HISTORY.status = 'F'
		    AND EQUIPMENT_HISTORY.LOC_TYPE = 'Y'
		    AND v.line_id not in ('WIL')
		    --AND VESSEL_VISITS.ATD >= to_date('2024-04-01','YYYY-MM-DD')
		    --AND VESSEL_VISITS.ATD < to_date('2024-04-05','YYYY-MM-DD') + interval '1' day
		    AND VESSEL_VISITS.ATD >= to_date('2024-07-01' ,'YYYY-MM-DD')
		    AND VESSEL_VISITS.ATD < to_date('2024-07-31' ,'YYYY-MM-DD') + interval '1' DAY
		    --AND equipment_history.vsl_id = 'SPIRMEL' AND equipment_history.voy_nbr = '422N'
		    --AND equipment_history.eq_nbr = 'TCKU1098947'
), prior_eq_hist_events AS (
	select 
		rolls_current_attributes.*
		, eh.vsl_id || ' / ' || eh.voy_nbr as ori_load_vsl_voy
		, p2.name || ' (' || eh.discharge_port_id1 || ')' as ori_dis_port
		, row_number() over (PARTITION BY eh.equse_gkey, rolls_current_attributes.posted order by eh.posted desc, eh.wtask_id) as ordernum
	from rolls_current_attributes
	INNER JOIN equipment_history eh ON 
		eh.equse_gkey = rolls_current_attributes.equse_gkey
		and eh.posted < rolls_current_attributes.posted
	INNER JOIN handling_points p2 on eh.discharge_port_id1 = p2.id
	where 
		eh.removed is null
		and eh.vsl_id != 'CRFROLL'
	order by ordernum
), first_eq_hist_events AS (
	SELECT 
		eq_nbr
		, equse_gkey
		, posted
		, ori_load_vsl_voy AS ORIGINAL_LOADING_VESSEL_VOYAGE
		, ori_dis_port AS ORIGINAL_DISCHARGE_PORT
	FROM prior_eq_hist_events
	WHERE ordernum = 1
), orig_attributes_joined AS (
	SELECT 
		rolls_current_attributes.*
		, first_eq_hist_events.ORIGINAL_LOADING_VESSEL_VOYAGE
		, first_eq_hist_events.ORIGINAL_DISCHARGE_PORT
	FROM rolls_current_attributes
	INNER JOIN first_eq_hist_events ON 
		rolls_current_attributes.eq_nbr = first_eq_hist_events.eq_nbr
		AND rolls_current_attributes.equse_gkey = first_eq_hist_events.equse_gkey
		AND rolls_current_attributes.posted = first_eq_hist_events.posted
), rolls_current_and_orig_atts AS (
	select 
		EQ_NBR as container_number
		, EXP_SO_NBR as booking_number
		, VSL_ID as vessel_id
		, vessel_name
		, vessel_line_id
		, vessel_line_name
		, VOY_NBR as out_voyage_number
		, OUT_SRVC_ID as service_id
		, service_name
		, ATA
		, ATD
		, LINE_ID as roll_line_id
		, roll_line_name
		, CREATED
		, CREATOR
		, WTASK_ID
		, SZTP_ID
		--, PRE_CARRIER
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
		, ORIGINAL_DISCHARGE_PORT
		, NEW_DISCHARGE_PORT
	from orig_attributes_joined
	WHERE 
		(ORIGINAL_LOADING_VESSEL_VOYAGE != NEW_LOADING_VESSEL_VOYAGE 
			OR ORIGINAL_DISCHARGE_PORT != NEW_DISCHARGE_PORT)
	ORDER BY 
		WTASK_ID
		, ORIGINAL_LOADING_VESSEL_VOYAGE
		, NEW_LOADING_VESSEL_VOYAGE
	    , ORIGINAL_DISCHARGE_PORT
	    , NEW_DISCHARGE_PORT
	    , EQ_NBR
), FINAL AS (
	select 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, case when x.vessel_line_id = 'MAE' then 'MAERSK' else x.vessel_line_name end as vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, case when x.roll_line_id = 'MAE' then 'MAERSK' else x.roll_line_name end as roll_line_name
		, count(container_number) as roll_quantity
	from rolls_current_and_orig_atts x
	group by 
		x.vessel_id
		, x.vessel_name
		, x.vessel_line_id
		, x.vessel_line_name
		, x.out_voyage_number
		, x.service_id
		, x.service_name
		, x.ATA
		, x.ATD
		, x.roll_line_id
		, x.roll_line_name
	order by 
		x.vessel_id
		, x.ATD
		, x.roll_line_id
)
SELECT * FROM final
--ORDER BY container_number, created
--SELECT container_number, count(*) AS cnt FROM rolls_current_and_orig_atts GROUP BY container_number ORDER BY 2 desc
;

SELECT *
FROM equipment_uses_jn
WHERE gkey = '25878094'
ORDER BY jn_entryid
;

SELECT *
FROM equipment_history
WHERE eq_nbr = 'BEAU5388832'
ORDER BY posted
; --CONTFOX 2427S

SELECT *
FROM vessel_visits
WHERE
	vsl_id = 'CONTFOX'
	AND out_voy_nbr = '2427S'
;

SELECT *
FROM vessels
WHERE id = 'CONTFOX'
;

SELECT *
FROM line_operators
WHERE id = 'ONE'
;

SELECT *
FROM handling_points
WHERE id = 'MAO'
;

SELECT *
FROM services
WHERE id = 'CX1' --AND line_id = 'CFS'
;

SELECT *
FROM equipment_history
WHERE equse_gkey = '25969091' AND posted < to_timestamp('2024-07-15  21:45:57', 'YYYY-MM-DD HH24:MI:SS')
;

SELECT *
FROM cg_ref_codes
WHERE rv_domain = 'DRAY STATUS'
;