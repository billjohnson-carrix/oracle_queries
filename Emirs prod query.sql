SELECT * FROM (
select SUBSTR (v.name, 0, 29) as name, vv.vsl_id, vv.in_voy_nbr||'/'||vv.out_voy_nbr voyage, vv.inbound_sailing_direction, vv.outbound_sailing_direction, vv.vsl_line_id, vv.out_srvc_id service, v.category, vv.berth, vv.file_ref, vv.ata, vv.atd, vv.work_started, vv.loaded, vv.discharged,
       sum(vs.quantity) moves, ((sum(vs.quantity)) - (nvl(y.rehandle_full_total,0) + nvl(y.rehandle_full_total,0))) as moves_reh, vv.gangs, vv.gross_hours, vv.paid_hours, vv.net_hours, round(((vv.atd - vv.ata) * 24),2) berth_hours, 
       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / vv.gross_hours),2) end as gross_production,
       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / vv.paid_hours),2) end as mit_gross_production,
       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / vv.net_hours),2) end as net_production,
       case when v.category = 'RORO' then 0 else round((sum(vs.quantity) / round(((vv.atd - vv.ata) * 24),2)),2) end as berth_production,
       case when v.category = 'RORO' then 0 else round(round((sum(vs.quantity) / vv.gross_hours),2) * vv.gangs, 2) end as vsl_moves_hour,
       nvl(y.load_full_total,0) as load_full_total,
nvl(y.load_Empty_total,0) as load_Empty_total,
nvl(y.unload_full_total,0) as unload_full_total,
nvl(y.unload_Empty_total,0) as unload_Empty_total,
nvl(y.rehandle_empty_total,0) as rehandle_empty_total,
nvl(y.rehandle_full_total,0) as rehandle_full_total,
nvl(y.unload_chassis_total,0) as unload_chassis_total,
nvl(y.load_chassis_total,0) as load_chassis_total,
nvl(y.unload_cont_total,0) as unload_cont_total,
nvl(y.load_cont_total,0) as load_cont_total,
nvl(y.unload_reefer_full_total,0) as unload_reefer_full_total,
nvl(y.load_reefer_full_total,0) as load_reefer_full_total
from vessel_statistics vs, vessel_visits vv, vessels v, (select x.vv_vsl_id, x.vv_in_voy_nbr, x.vv_out_voy_nbr, 
                                                                sum(x.load_full_total) as load_full_total,
                                                                sum(x.load_Empty_total) as load_Empty_total,
                                                                sum(x.unload_full_total) as unload_full_total,
                                                                sum(x.unload_Empty_total) as unload_Empty_total,
                                                                sum(x.rehandle_empty_total) as rehandle_empty_total,
                                                                sum(x.rehandle_full_total) as rehandle_full_total,
                                                                sum(x.unload_chassis_total) as unload_chassis_total,
                                                                sum(x.load_chassis_total) as load_chassis_total,
                                                                sum(x.unload_cont_total)as unload_cont_total,
                                                                sum(x.load_cont_total) as load_cont_total,
                                                                sum(x.unload_reefer_full_total) as unload_reefer_full_total,
                                                                sum(x.load_reefer_full_total) as load_reefer_full_total
                                                          from (select vv.vsl_id as vv_vsl_id, vv.in_voy_nbr as vv_in_voy_nbr, vv.out_voy_nbr as vv_out_voy_nbr,
                                                                case
                                                                when wtask_id ='LOAD' and status ='F' then sum(vs.quantity) 
                                                                end as load_full_total,
                                                                case
                                                                when wtask_id ='LOAD' and status ='E' then sum(vs.quantity) 
                                                                end as load_Empty_total,
                                                                case
                                                                when wtask_id ='UNLOAD' and status ='F' then sum(vs.quantity) 
                                                                end as unload_full_total,
                                                                case
                                                                when wtask_id ='UNLOAD' and status ='E' then sum(vs.quantity) 
                                                                end as unload_Empty_total,
                                                                case
                                                                when substr(wtask_id,1,2) ='RE' and status ='F' then sum(vs.quantity) 
                                                                end as rehandle_full_total,
                                                                case
                                                                when substr(wtask_id,1,2) ='RE' and status ='E' then sum(vs.quantity) 
                                                                end as rehandle_empty_total,
                                                                case 
                                                                when wtask_id ='UNLOAD' and substr(sztp_id,3,2) in ('CH','EX','FB') then sum(vs.quantity) 
                                                                end as unload_chassis_total,
                                                                case 
                                                                when wtask_id ='LOAD' and substr(sztp_id,3,2) in ('CH','EX','FB') then sum(vs.quantity) 
                                                                end as load_chassis_total,
                                                                case 
                                                                when wtask_id ='UNLOAD' and substr(sztp_id,3,2) not in ('CH','EX','FB','BL','RT') then sum(vs.quantity) 
                                                              end as unload_cont_total,
                                                              case 
                                                              when wtask_id ='LOAD' and substr(sztp_id,3,2) not in ('CH','EX','FB','BL','RT') then sum(vs.quantity) 
                                                              end as load_cont_total,
                                                               --TOTAL REEFERS
                                                                             case
                                                                            when wtask_id ='UNLOAD' and substr(sztp_id,3,2) in ('RF','RH','RV','MU') and status ='F' then sum(vs.quantity) 
                                                                            end as unload_reefer_full_total,
                                                                            case
                                                                             when wtask_id ='LOAD' and substr(sztp_id,3,2) in ('RF','RH','RV','MU') and status ='F' then sum(vs.quantity)  
                                                                            end as load_reefer_full_total
                                                              from vessel_statistics vs, vessel_visits vv
                                                              --where atd between ? and ?
                                                              WHERE --to_char(atd,'MM/YY') = to_char(sysdate,'MM/YY') and
															  to_char(ata, 'YYYY') > '2009'
															  and to_char(atd, 'YYYY') < '2040'
                                                              and vs.vv_vsl_id(+) = vv.vsl_id
                                                              and vs.vv_in_voy_nbr(+) = vv.in_voy_nbr
                                                              and vs.vv_out_voy_nbr(+) = vv.out_voy_nbr
                                                              group by vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vs.wtask_id, vs.status,  substr(sztp_id,3,2)) x
                                                              group by x.vv_vsl_id, x.vv_in_voy_nbr, x.vv_out_voy_nbr) y
where vs.vv_vsl_id(+) = vv.vsl_id
and vs.vv_in_voy_nbr(+) = vv.in_voy_nbr
and vs.vv_out_voy_nbr(+) = vv.out_voy_nbr
and vv.vsl_id = v.id
and vv.vsl_id = y.vv_vsl_id
and vv.in_voy_nbr = y.vv_in_voy_nbr
and vv.out_voy_nbr = y.vv_out_voy_nbr
and vv.work_started is not null
group by v.name, vv.vsl_id, vv.in_voy_nbr||'/'||vv.out_voy_nbr, vv.inbound_sailing_direction, vv.outbound_sailing_direction, vv.vsl_line_id, vv.out_srvc_id, v.category, vv.berth, vv.file_ref, vv.loaded, vv.discharged, 
vv.gangs, vv.gross_hours, vv.paid_hours, vv.net_hours,  y.load_full_total, y.load_Empty_total, y.unload_full_total, y.unload_Empty_total, y.rehandle_empty_total, y.rehandle_full_total, 
y.unload_chassis_total, y.load_chassis_total, y.unload_cont_total, y.load_cont_total, y.unload_reefer_full_total, y.load_reefer_full_total, vv.ata, vv.atd, vv.work_started
order by 2)
WHERE EXTRACT (MONTH FROM atd)=1 AND EXTRACT (YEAR FROM atd)=2023;