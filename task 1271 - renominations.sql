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

