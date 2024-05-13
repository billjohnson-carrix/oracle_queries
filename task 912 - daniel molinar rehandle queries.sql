select vv_vsl_id, VV_IN_VOY_NBR, wtask_id, size_type, line_id, qty, status, transship, tax_code_tdr, sort_code_tdr

, case when wtask_id = 'UNLOAD' and size_type = '20' and status = 'F' and transship is null then 'DISCHARGE FULL LOCAL 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'F' and transship is null then 'DISCHARGE FULL LOCAL 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'F' and transship is null then 'DISCHARGE FULL LOCAL 45'
       when wtask_id = 'UNLOAD' and size_type = '20' and status = 'E' and transship is null then 'DISCHARGE EMPTY LOCAL 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'E' and transship is null then 'DISCHARGE EMPTY LOCAL 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'E' and transship is null then 'DISCHARGE EMPTY LOCAL 45'
       
       when wtask_id = 'UNLOAD' and size_type = '20' and status = 'F' and transship = 'X' then 'DISCHARGE FULL TRANSSHIP 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'F' and transship = 'X' then 'DISCHARGE FULL TRANSSHIP 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'F' and transship = 'X' then 'DISCHARGE FULL TRANSSHIP 45'
       when wtask_id = 'UNLOAD' and size_type = '20' and status = 'E' and transship = 'X' then 'DISCHARGE EMPTY TRANSSHIP 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'E' and transship = 'X' then 'DISCHARGE EMPTY TRANSSHIP 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'E' and transship = 'X' then 'DISCHARGE EMPTY TRANSSHIP 45'
       
       when wtask_id = 'UNLOAD' and size_type = '20' and status = 'F' and transship = 'G' and tax_code_tdr = 'PAC' then 'DISCHARGE FULL T/S BALBOA 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'F' and transship = 'G' and tax_code_tdr = 'PAC' then 'DISCHARGE FULL T/S BALBOA 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'F' and transship = 'G' and tax_code_tdr = 'PAC' then 'DISCHARGE FULL T/S BALBOA 45'
       when wtask_id = 'UNLOAD' and size_type = '20' and status = 'E' and transship = 'G' and tax_code_tdr = 'PAC' then 'DISCHARGE EMPTY T/S BALBOA 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'E' and transship = 'G' and tax_code_tdr = 'PAC' then 'DISCHARGE EMPTY T/S BALBOA 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'E' and transship = 'G' and tax_code_tdr = 'PAC' then 'DISCHARGE EMPTY T/S BALBOA 45'
	   
	   when wtask_id = 'UNLOAD' and size_type = '20' and status = 'F' and transship = 'G' and tax_code_tdr is null then 'DISCHARGE FULL T/S BALBOA 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'F' and transship = 'G' and tax_code_tdr is null then 'DISCHARGE FULL T/S BALBOA 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'F' and transship = 'G' and tax_code_tdr is null then 'DISCHARGE FULL T/S BALBOA 45'
       when wtask_id = 'UNLOAD' and size_type = '20' and status = 'E' and transship = 'G' and tax_code_tdr is null then 'DISCHARGE EMPTY T/S BALBOA 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'E' and transship = 'G' and tax_code_tdr is null then 'DISCHARGE EMPTY T/S BALBOA 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'E' and transship = 'G' and tax_code_tdr is null then 'DISCHARGE EMPTY T/S BALBOA 45'
       
       when wtask_id = 'UNLOAD' and size_type = '20' and status = 'F' and transship = 'G' and tax_code_tdr = 'ATL' then 'DISCHARGE FULL T/S ATLANTIC 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'F' and transship = 'G' and tax_code_tdr = 'ATL' then 'DISCHARGE FULL T/S ATLANTIC 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'F' and transship = 'G' and tax_code_tdr = 'ATL' then 'DISCHARGE FULL T/S ATLANTIC 45'
       when wtask_id = 'UNLOAD' and size_type = '20' and status = 'E' and transship = 'G' and tax_code_tdr = 'ATL' then 'DISCHARGE EMPTY T/S ATLANTIC 20'
       when wtask_id = 'UNLOAD' and size_type = '40' and status = 'E' and transship = 'G' and tax_code_tdr = 'ATL' then 'DISCHARGE EMPTY T/S ATLANTIC 40'
       when wtask_id = 'UNLOAD' and size_type = '45' and status = 'E' and transship = 'G' and tax_code_tdr = 'ATL' then 'DISCHARGE EMPTY T/S ATLANTIC 45'
       
       ---------------------------------
       
       when wtask_id = 'LOAD' and size_type = '20' and status = 'F' and transship is null then 'LOAD FULL LOCAL 20'
       when wtask_id = 'LOAD' and size_type = '40' and status = 'F' and transship is null then 'LOAD FULL LOCAL 40'
       when wtask_id = 'LOAD' and size_type = '45' and status = 'F' and transship is null then 'LOAD FULL LOCAL 45'
       when wtask_id = 'LOAD' and size_type = '20' and status = 'E' and transship is null then 'LOAD EMPTY LOCAL 20'
       when wtask_id = 'LOAD' and size_type = '40' and status = 'E' and transship is null then 'LOAD EMPTY LOCAL 40'
       when wtask_id = 'LOAD' and size_type = '45' and status = 'E' and transship is null then 'LOAD EMPTY LOCAL 45'
       
       when wtask_id = 'LOAD' and size_type = '20' and status = 'F' and transship = 'X' then 'LOAD FULL TRANSSHIP 20'
       when wtask_id = 'LOAD' and size_type = '40' and status = 'F' and transship = 'X' then 'LOAD FULL TRANSSHIP 40'
       when wtask_id = 'LOAD' and size_type = '45' and status = 'F' and transship = 'X' then 'LOAD FULL TRANSSHIP 45'
       when wtask_id = 'LOAD' and size_type = '20' and status = 'E' and transship = 'X' then 'LOAD EMPTY TRANSSHIP 20'
       when wtask_id = 'LOAD' and size_type = '40' and status = 'E' and transship = 'X' then 'LOAD EMPTY TRANSSHIP 40'
       when wtask_id = 'LOAD' and size_type = '45' and status = 'E' and transship = 'X' then 'LOAD EMPTY TRANSSHIP 45'
       
       when wtask_id = 'LOAD' and size_type = '20' and status = 'F' and transship = 'G' and tax_code_tdr = 'PAC' then 'LOAD FULL T/S BALBOA 20'
       when wtask_id = 'LOAD' and size_type = '40' and status = 'F' and transship = 'G' and tax_code_tdr = 'PAC' then 'LOAD FULL T/S BALBOA 40'
       when wtask_id = 'LOAD' and size_type = '45' and status = 'F' and transship = 'G' and tax_code_tdr = 'PAC' then 'LOAD FULL T/S BALBOA 45'
       when wtask_id = 'LOAD' and size_type = '20' and status = 'E' and transship = 'G' and tax_code_tdr = 'PAC' then 'LOAD EMPTY T/S BALBOA 20'
       when wtask_id = 'LOAD' and size_type = '40' and status = 'E' and transship = 'G' and tax_code_tdr = 'PAC' then 'LOAD EMPTY T/S BALBOA 40'
       when wtask_id = 'LOAD' and size_type = '45' and status = 'E' and transship = 'G' and tax_code_tdr = 'PAC' then 'LOAD EMPTY T/S BALBOA 45'
	   
	   when wtask_id = 'LOAD' and size_type = '20' and status = 'F' and transship = 'G' and tax_code_tdr is null then 'LOAD FULL T/S BALBOA 20'
	   when wtask_id = 'LOAD' and size_type = '40' and status = 'F' and transship = 'G' and tax_code_tdr is null then 'LOAD FULL T/S BALBOA 40'
	   when wtask_id = 'LOAD' and size_type = '45' and status = 'F' and transship = 'G' and tax_code_tdr is null then 'LOAD FULL T/S BALBOA 45'
	   when wtask_id = 'LOAD' and size_type = '20' and status = 'E' and transship = 'G' and tax_code_tdr is null then 'LOAD EMPTY T/S BALBOA 20'
	   when wtask_id = 'LOAD' and size_type = '40' and status = 'E' and transship = 'G' and tax_code_tdr is null then 'LOAD EMPTY T/S BALBOA 40'
	   when wtask_id = 'LOAD' and size_type = '45' and status = 'E' and transship = 'G' and tax_code_tdr is null then 'LOAD EMPTY T/S BALBOA 45'
       
       when wtask_id = 'LOAD' and size_type = '20' and status = 'F' and transship = 'G' and tax_code_tdr = 'ATL' then 'LOAD FULL T/S ATLANTIC 20'
       when wtask_id = 'LOAD' and size_type = '40' and status = 'F' and transship = 'G' and tax_code_tdr = 'ATL' then 'LOAD FULL T/S ATLANTIC 40'
       when wtask_id = 'LOAD' and size_type = '45' and status = 'F' and transship = 'G' and tax_code_tdr = 'ATL' then 'LOAD FULL T/S ATLANTIC 45'
       when wtask_id = 'LOAD' and size_type = '20' and status = 'E' and transship = 'G' and tax_code_tdr = 'ATL' then 'LOAD EMPTY T/S ATLANTIC 20'
       when wtask_id = 'LOAD' and size_type = '40' and status = 'E' and transship = 'G' and tax_code_tdr = 'ATL' then 'LOAD EMPTY T/S ATLANTIC 40'
       when wtask_id = 'LOAD' and size_type = '45' and status = 'E' and transship = 'G' and tax_code_tdr = 'ATL' then 'LOAD EMPTY T/S ATLANTIC 45'
       
       when (wtask_id = 'REHDC' or wtask_id = 'REHCD') and size_type = '20' then 'REHANDLES C/D/C 20'
       when (wtask_id = 'REHDC' or wtask_id = 'REHCD') and size_type = '40' then 'REHANDLES C/D/C 40'
       when (wtask_id = 'REHDC' or wtask_id = 'REHCD') and size_type = '45' then 'REHANDLES C/D/C 45'
       
       when wtask_id = 'REHCC'  and size_type = '20' then 'REHANDLES C/C 20'
       when wtask_id = 'REHCC'  and size_type = '40' then 'REHANDLES C/C 40'
       when wtask_id = 'REHCC'  and size_type = '45' then 'REHANDLES C/C 45'
       
       else (case when wtask_id = 'UNLOAD' and size_type = '20' and status = 'F' then 'DISCHARGE FULL LOCAL 20' 
	              when wtask_id = 'UNLOAD' and size_type = '40' and status = 'F' then 'DISCHARGE FULL LOCAL 40' 
				  when wtask_id = 'UNLOAD' and size_type = '45' and status = 'F' then 'DISCHARGE FULL LOCAL 45'
				  when wtask_id = 'UNLOAD' and size_type = '20' and status = 'E' then 'DISCHARGE EMPTY LOCAL 20'
				  when wtask_id = 'UNLOAD' and size_type = '40' and status = 'E' then 'DISCHARGE EMPTY LOCAL 40'
				  when wtask_id = 'UNLOAD' and size_type = '45' and status = 'E' then 'DISCHARGE EMPTY LOCAL 45'
				  
				  when wtask_id = 'LOAD' and size_type = '20' and status = 'F' then 'LOAD FULL LOCAL 20'
				  when wtask_id = 'LOAD' and size_type = '40' and status = 'F' then 'LOAD FULL LOCAL 40'
				  when wtask_id = 'LOAD' and size_type = '45' and status = 'F' then 'LOAD FULL LOCAL 45'
				  when wtask_id = 'LOAD' and size_type = '20' and status = 'E' then 'LOAD EMPTY LOCAL 20'
				  when wtask_id = 'LOAD' and size_type = '40' and status = 'E' then 'LOAD EMPTY LOCAL 40'
				  when wtask_id = 'LOAD' and size_type = '45' and status = 'E' then 'LOAD EMPTY LOCAL 45'
				  
			 end)
       
  end tdr_category
from (
SELECT x.VV_VSL_ID, x.VV_IN_VOY_NBR, x.WTASK_ID, x.SIZE_TYPE, x.LINE_ID, sum(x.qty) as QTY, x.STATUS, x.TRANSSHIP
, x.TAX_CODE_TDR, x.SORT_CODE_TDR  
FROM ( 

       SELECT distinct(h.eq_nbr), h.VSL_ID VV_VSL_ID, h.VOY_NBR VV_IN_VOY_NBR, h.WTASK_ID, substr(h.SZTP_ID,1,2) SIZE_TYPE, h.LINE_ID, 1 qty, h.STATUS
	   , h.TRANSSHIP
	   , case when gt.TAX_CODE_ID in ('BLB','BAL','PSA') then 'PAC' 
			  when gt.TAX_CODE_ID not in ('BLB','BAL','PSA') and (gt.TAX_CODE_ID like '%BLB%' or  gt.TAX_CODE_ID like '%BAL%' or gt.TAX_CODE_ID like '%PSA%') then 'PAC' 
			  when gt.TAX_CODE_ID in ('CRI','CCT','EVE') then 'ATL' 
			  when gt.TAX_CODE_ID not in ('CRI','CCT','EVE') and (gt.TAX_CODE_ID like '%CRI%' or  gt.TAX_CODE_ID like '%CCT%' or gt.TAX_CODE_ID like '%EVE%') then 'ATL' 
			  when gt.wtask_id = 'RFULLOUT' and u.GROUP_ID in ('RX1','RX2') then 'PAC' 
			  when u.GROUP_ID = '1' then 'PAC' 
			  When u.GROUP_ID = '4' then 'ATL' 
			  when u.GROUP_ID = '2' then 'PAC' 
			  when h.status = 'E' and h.transship = 'G' then 'PAC' 
              else '' 
         end TAX_CODE_TDR
	   , case when u.GROUP_ID in ('TIF','TIE','RIF','RIE') then 'ITT' 
			  when u.GROUP_ID in ('RX1','RX2','2') then 'ITT' 
			  when u.GROUP_ID in ('1','4') then 'ITT' 
			  when h.status = 'E' and h.transship = 'G' then 'ITT' 
			  else '' 
         end SORT_CODE_TDR
	   FROM MTMS.EQUIPMENT_HISTORY h 
	   left join MTMS.EQUIPMENT_USES u on h.EQUSE_GKEY = u.GKEY 
	   left join MTMS.GATE_TRANSACTIONS gt on u.GKEY = gt.EQUSE_GKEY and gt.TRAN_STATUS not in ('CNCL','ERR','PICK','PRE') and gt.direction = 'O'  
	   where h.REMOVED is null 
	   and h.VSL_ID = upper('POLECU') 
	   and (h.VOY_NBR = upper('342S') OR h.VOY_NBR = upper('342N')) 
	   and h.wtask_id in ('UNLOAD') 
       and h.transship = 'G'
	   and (gt.TRAN_STATUS in ('EIR') 
	   and gt.DIRECTION = 'O') 
	   
	   UNION ALL 
	   
	   SELECT distinct(h.eq_nbr), h.VSL_ID VV_VSL_ID, h.VOY_NBR VV_IN_VOY_NBR, h.WTASK_ID, substr(h.SZTP_ID,1,2) SIZE_TYPE, h.LINE_ID, 1 qty, h.STATUS
       , case when h.transship = 'G' and u.transship = 'G' then 
                   case when u.GROUP_ID in ('2','1','4','RX1','RX2') then 'G' 
                        else h.TRANSSHIP 
                   end 
              else h.transship
         end TRANSSHIP
	   , case when h.transship = 'G' and u.transship = 'G' then 
                   case when gt.TAX_CODE_ID in ('BLB','BAL','PSA') then 'PAC' 
                        when gt.TAX_CODE_ID not in ('BLB','BAL','PSA') and (gt.TAX_CODE_ID like '%BLB%' or  gt.TAX_CODE_ID like '%BAL%' or gt.TAX_CODE_ID like '%PSA%') then 'PAC' 
                        when gt.TAX_CODE_ID in ('CRI','CCT','EVE') then 'ATL' 
                        when gt.TAX_CODE_ID not in ('CRI','CCT','EVE') and (gt.TAX_CODE_ID like '%CRI%' or  gt.TAX_CODE_ID like '%CCT%' or gt.TAX_CODE_ID like '%EVE%') then 'ATL' 
                        when gt.wtask_id = 'RFULLOUT' and u.GROUP_ID in ('RX1','RX2') then 'PAC' 
                        when u.GROUP_ID = '1' then 'PAC' 
                        When u.GROUP_ID = '4' then 'ATL' 
                        when u.GROUP_ID = '2' then 'PAC' 
                        when h.status = 'E' and h.transship = 'G' then 'PAC' 
                        else '' 
                   end 
              when h.transship = 'G' and u.transship != 'G' then 'PAC' 
              else ''
         end TAX_CODE_TDR
	   , case when h.transship = 'G' and u.transship = 'G' then 
                   case when u.GROUP_ID in ('TIF','TIE','RIF','RIE') then 'ITT' 
                        when u.GROUP_ID in ('RX1','RX2','2') then 'ITT' 
                        when u.GROUP_ID in ('1','4') then 'ITT' 
                        when h.status = 'E' and h.transship = 'G' then 'ITT' 
                        else '' 
                   end
              when h.transship = 'G' and u.transship != 'G' then 'ITT' 
              else ''
         end SORT_CODE_TDR
       FROM MTMS.EQUIPMENT_HISTORY h
	   left join MTMS.EQUIPMENT_USES u on h.EQUSE_GKEY = u.GKEY 
	   left join MTMS.GATE_TRANSACTIONS gt on u.GKEY = gt.EQUSE_GKEY and gt.TRAN_STATUS not in ('CNCL','ERR','PICK','PRE') and gt.direction = 'O' 
	   where h.REMOVED is null 
	   and h.VSL_ID = upper('POLECU') 
	   and (h.VOY_NBR = upper('342S') OR h.VOY_NBR = upper('342N')) 
	   and h.wtask_id in ('UNLOAD')
       and (   (h.transship != 'G' or h.transship is null)
            or (gt.TRAN_STATUS IS NULL and h.transship = 'G'))
	   
	   UNION ALL 
	   
	   SELECT distinct(h.eq_nbr), h.VSL_ID VV_VSL_ID, h.VOY_NBR VV_IN_VOY_NBR, h.WTASK_ID, substr(h.SZTP_ID,1,2) SIZE_TYPE, h.LINE_ID, 1 qty, h.STATUS
	   , h.TRANSSHIP 
       , case when h.TRANSSHIP = 'G' and gt.TAX_CODE_ID in ('BLB','BAL','PSA') then 'PAC' 
	          when h.TRANSSHIP = 'G' and gt.TAX_CODE_ID not in ('BLB','BAL','PSA') and (gt.TAX_CODE_ID like '%BLB%' or  gt.TAX_CODE_ID like '%BAL%' or gt.TAX_CODE_ID like '%PSA%') then 'PAC' 
			  when h.TRANSSHIP = 'G' and gt.TAX_CODE_ID in ('CRI','CCT','EVE') then 'ATL' 
			  when h.TRANSSHIP = 'G' and gt.TAX_CODE_ID not in ('CRI','CCT','EVE') and (gt.TAX_CODE_ID like '%CRI%' or  gt.TAX_CODE_ID like '%CCT%' or gt.TAX_CODE_ID like '%EVE%') then 'ATL' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id = 'RFULLIN' and gt.TAX_CODE_ID is null then 'PAC' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id is not null and gt_storage.tax_code_id in ('BLB','BAL','PSA') then 'PAC' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id is not null and gt_storage.tax_code_id not in ('BLB','BAL','PSA') and (gt_storage.TAX_CODE_ID like '%BLB%' or gt_storage.TAX_CODE_ID like '%BAL%' or gt_storage.TAX_CODE_ID like '%PSA%') then 'PAC' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id is not null and gt_storage.tax_code_id in ('CRI','CCT','EVE') then 'ATL' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id is not null and gt_storage.tax_code_id not in ('CRI','CCT','EVE') and (gt_storage.TAX_CODE_ID like '%CRI%' or  gt_storage.TAX_CODE_ID like '%CCT%' or gt_storage.TAX_CODE_ID like '%EVE%') then 'ATL' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id = 'RFULLIN' and gt_storage.TAX_CODE_ID is null then 'PAC' 
			  when h.transship = 'G' and u.group_id in ('RIF','RIE') then 'PAC' 
              when h.transship = 'G' and u.group_id is null then 'PAC' 
              else '' 
         end TAX_CODE_TDR
	   , case when h.TRANSSHIP = 'G' and u.GROUP_ID in ('TIF','TIE','RIF','RIE') then 'ITT' 
	          when h.TRANSSHIP = 'G' and u.GROUP_ID in ('RX1','RX2','2') then 'ITT' 
			  when h.TRANSSHIP = 'G' and u.GROUP_ID in ('1','4') then 'ITT' 
			  when h.TRANSSHIP = 'G' and u.status = 'E' and gt.wtask_id is null and gt_storage.wtask_id is not null and u.in_loc_type = 'T' and gt_storage.TAX_CODE_ID in ('BAL','PSA','CRI','EVE')  then 'ITT' 
			  when h.transship = 'G' and gt_storage.TAX_CODE_ID is null then 'ITT'
              else '' 
         end SORT_CODE_TDR 
	   FROM MTMS.EQUIPMENT_HISTORY h 
	   left join MTMS.EQUIPMENT_USES u on h.EQUSE_GKEY = u.GKEY 
	   left join MTMS.GATE_TRANSACTIONS gt on u.GKEY = gt.EQUSE_GKEY and gt.TRAN_STATUS not in ('CNCL','ERR') and gt.direction = 'I' 
	   left join ( select gt2.wtask_id, gt2.tax_code_id, gt2.ctr_nbr, gt2.tran_status, gt2.direction, rank() over (partition by ctr_nbr order by created desc) rnk from MTMS.GATE_TRANSACTIONS gt2 )  gt_storage on gt_storage.rnk = 1 and u.status = 'E' and gt_storage.ctr_nbr = h.eq_nbr and (gt_storage.tran_status in ('EIR','PICK','PRE') and gt_storage.direction = 'I') and u.in_loc_type = 'T' 
	   where h.REMOVED is null 
	   and h.VSL_ID = upper('POLECU') 
	   and (h.VOY_NBR = upper('342S') OR h.VOY_NBR = upper('342N')) 
	   and h.wtask_id in ('LOAD') 
	   and (gt.TRAN_STATUS = 'EIR' 
	   and gt.DIRECTION = 'I') 

	   UNION ALL 
	   
	   SELECT distinct(h.eq_nbr), h.VSL_ID VV_VSL_ID, h.VOY_NBR VV_IN_VOY_NBR, h.WTASK_ID, substr(h.SZTP_ID,1,2) SIZE_TYPE, h.LINE_ID, 1 qty, h.STATUS
	   , h.TRANSSHIP 
       , case when h.TRANSSHIP = 'G' and gt.TAX_CODE_ID in ('BLB','BAL','PSA') then 'PAC' 
	          when h.TRANSSHIP = 'G' and gt.TAX_CODE_ID not in ('BLB','BAL','PSA') and (gt.TAX_CODE_ID like '%BLB%' or  gt.TAX_CODE_ID like '%BAL%' or gt.TAX_CODE_ID like '%PSA%') then 'PAC' 
			  when h.TRANSSHIP = 'G' and gt.TAX_CODE_ID in ('CRI','CCT','EVE') then 'ATL' 
			  when h.TRANSSHIP = 'G' and gt.TAX_CODE_ID not in ('CRI','CCT','EVE') and (gt.TAX_CODE_ID like '%CRI%' or  gt.TAX_CODE_ID like '%CCT%' or gt.TAX_CODE_ID like '%EVE%') then 'ATL' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id = 'RFULLIN' and gt.TAX_CODE_ID is null then 'PAC' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id is not null and gt_storage.tax_code_id in ('BLB','BAL','PSA') then 'PAC' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id is not null and gt_storage.tax_code_id not in ('BLB','BAL','PSA') and (gt_storage.TAX_CODE_ID like '%BLB%' or gt_storage.TAX_CODE_ID like '%BAL%' or gt_storage.TAX_CODE_ID like '%PSA%') then 'PAC' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id is not null and gt_storage.tax_code_id in ('CRI','CCT','EVE') then 'ATL' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id is not null and gt_storage.tax_code_id not in ('CRI','CCT','EVE') and (gt_storage.TAX_CODE_ID like '%CRI%' or  gt_storage.TAX_CODE_ID like '%CCT%' or gt_storage.TAX_CODE_ID like '%EVE%') then 'ATL' 
			  when h.TRANSSHIP = 'G' and gt.wtask_id is null and gt_storage.wtask_id = 'RFULLIN' and gt_storage.TAX_CODE_ID is null then 'PAC' 
			  when h.transship = 'G' and u.group_id in ('RIF','RIE') then 'PAC' 
              when h.transship = 'G' and u.group_id is null then 'PAC' 
              else '' 
         end TAX_CODE_TDR
	   , case when h.TRANSSHIP = 'G' and u.GROUP_ID in ('TIF','TIE','RIF','RIE') then 'ITT' 
	          when h.TRANSSHIP = 'G' and u.GROUP_ID in ('RX1','RX2','2') then 'ITT' 
			  when h.TRANSSHIP = 'G' and u.GROUP_ID in ('1','4') then 'ITT' 
			  when h.TRANSSHIP = 'G' and u.status = 'E' and gt.wtask_id is null and gt_storage.wtask_id is not null and u.in_loc_type = 'T' and gt_storage.TAX_CODE_ID in ('BAL','PSA','CRI','EVE')  then 'ITT' 
			  when h.transship = 'G' and gt_storage.TAX_CODE_ID is null then 'ITT'
              else '' 
         end SORT_CODE_TDR 
	   FROM MTMS.EQUIPMENT_HISTORY h 
	   left join MTMS.EQUIPMENT_USES u on h.EQUSE_GKEY = u.GKEY 
	   left join MTMS.GATE_TRANSACTIONS gt on u.GKEY = gt.EQUSE_GKEY and gt.TRAN_STATUS not in ('CNCL','ERR') and gt.direction = 'I' 
	   left join (select gt2.wtask_id, gt2.tax_code_id, gt2.ctr_nbr, gt2.tran_status, gt2.direction, rank() over (partition by ctr_nbr order by created desc) rnk from MTMS.GATE_TRANSACTIONS gt2 ) gt_storage on gt_storage.rnk = 1 and u.status = 'E' and gt_storage.ctr_nbr = h.eq_nbr and (gt_storage.tran_status in ('EIR','PICK','PRE') and gt_storage.direction = 'I') and u.in_loc_type = 'T'
	   where h.REMOVED is null 
	   and h.VSL_ID = upper('POLECU') 
	   and (h.VOY_NBR = upper('342S') OR h.VOY_NBR = upper('342N')) 
	   and h.wtask_id in ('LOAD') 
	   and (gt.TRAN_STATUS is null) 
       
       UNION ALL 
       
       SELECT distinct(h.eq_nbr), h.VSL_ID VV_VSL_ID, h.VOY_NBR VV_IN_VOY_NBR, h.WTASK_ID, substr(h.SZTP_ID,1,2) SIZE_TYPE, h.LINE_ID, 1 qty, h.STATUS
	   , '' TRANSSHIP
	   , '' TAX_CODE_TDR
	   , '' SORT_CODE_TDR
	   FROM MTMS.EQUIPMENT_HISTORY h 
	   left join MTMS.EQUIPMENT_USES u on h.EQUSE_GKEY = u.GKEY 
	   where h.REMOVED is null 
	   and h.VSL_ID = upper('POLECU') 
	   and (h.VOY_NBR = upper('342S') OR h.VOY_NBR = upper('342N')) 
	   and h.wtask_id in ('REHDC','REHCD','REHCC') 
       
) x 
group by x.VV_VSL_ID, x.VV_IN_VOY_NBR, x.SIZE_TYPE, x.LINE_ID, x.STATUS, x.TRANSSHIP, x.WTASK_ID, x.TAX_CODE_TDR, x.SORT_CODE_TDR 
order by case when x.wtask_id = 'UNLOAD' then 1 
              when x.wtask_id = 'LOAD' then 2 
			  else 3 end
		 , x.SIZE_TYPE, x.LINE_ID
         
) y
ORDER BY y.wtask_id desc
;

select h.vsl_id as vessel_id, h.voy_nbr as voyage_number, h.gkey as history_gkey, h.equse_gkey as use_gkey, h.posted as rehcd_posted, h.line_id
, 'REHCD-REHDC' as wtask_id, h.eq_nbr as container_number, sztp.eqsz_id as container_size, h.status as container_status, h.old_celltocell_pos_id as original_position
, (select h_next.pos_id 
   from mtms.equipment_history h_next 
   where h_next.wtask_id = 'REHDC' 
   and h_next.posted > h.posted 
   and h_next.eq_nbr = h.eq_nbr
   and h_next.removed is null
   
   -- Parameters 1/3
   and h_next.vsl_id = 'POLECU' 
   and h_next.voy_nbr in ('342S','342N') 
   
   order by h_next.posted desc 
   fetch first 1 rows only) as final_position
, ('REHANDLES C/D/C '|| sztp.eqsz_id) tdr_category

from mtms.equipment_history h
inner join MTMS.equipment_size_types sztp on h.sztp_id = sztp.id
where h.wtask_id in ('REHCD')
and h.removed is null

-- Parameters 2/3
and h.vsl_id = ('POLECU')
and h.voy_nbr in ('342S','342N')

union all 

select h.vsl_id as vessel_id, h.voy_nbr as voyage_number, h.gkey as history_gkey, h.equse_gkey as use_gkey, h.posted as rehcd_posted, h.line_id
, h.wtask_id, h.eq_nbr as container_number, sztp.eqsz_id as container_size, h.status as container_status, h.old_celltocell_pos_id as original_position, h.pos_id as final_position, ('REHANDLES C/C '|| sztp.eqsz_id) tdr_category 
from mtms.equipment_history h
inner join MTMS.equipment_size_types sztp on h.sztp_id = sztp.id
where h.wtask_id in ('REHCC')
and h.removed is null

-- Parameters 3/3
and h.vsl_id = ('POLECU')
and h.voy_nbr in ('342S','342N')
;