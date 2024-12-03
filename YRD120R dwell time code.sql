/* YRD120R code */
SELECT ctr_nbr,
       in_date,
       out_date,
       DECODE(SIGN(TO_NUMBER(TO_CHAR(start_date, 'YYYYMMDD') ) - TO_NUMBER(TO_CHAR(in_date, 'YYYYMMDD'))), 
                      1, ROUND(TRUNC(out_date)-TRUNC(start_date)), ROUND(TRUNC(out_date)-TRUNC(in_date))) days_in,
       in_loc_type,
       out_loc_type,
       category,
       sub_category,
       transship,
       status,
       line_id,
       eqsz_id
  FROM
  (  
  SELECT ctr_nbr,
         start_date,
         end_date,
         DECODE(inventory_change, 'IN', posted) in_date,
         DECODE(inventory_change, 'IN', DECODE(next_posted, NULL, TO_DATE(TO_CHAR(end_date, 'MM/DD/RR')||' 23:59:59', 'MM/DD/RR HH24:MI:SS'), next_posted)) out_date,
         loc_type in_loc_type,
         next_loc_type out_loc_type,
         
         DECODE(status, 'F',
                   DECODE(category, 'I', DECODE(loc_type, 'V', DECODE((SELECT MAX('X') FROM train_assigned_equipment WHERE equse_gkey = eqhist_gkey AND eq_nbr = ctr_nbr), 'X', 'RAIL', 'LOCAL'), 'LOCAL'),
                                    'E', DECODE(transship, NULL, 'EXPORT', 'TRANSSHIP')),
                   'STORAGE' -- All empties are categorized as "STORAGE".                               
                                    ) sub_category,
         DECODE(status, 'F', (SELECT UPPER(rv_meaning) FROM cg_ref_codes WHERE rv_domain = 'CATEGORY' AND rv_low_value = category), 'EMPTY') category,
         category_code,
         status,
         transship,
         line_id,
         eqsz_id,
         DECODE(inventory_change, previous_inventory_change, '*') illogical_move
    FROM
    (  
    SELECT 
           eh.eq_nbr ctr_nbr,
           eh.equse_gkey eqhist_gkey,
           TO_DATE(:p_start_date||' 00:00:00', 'MM/DD/RR HH24:MI:SS') start_date,
           TO_DATE(:p_end_date||' 23:59:59', 'MM/DD/RR HH24:MI:SS') end_date,
           lag(eh.posted) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) previous_posted,
           lead(eh.posted) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) next_posted,
           lag(te.inventory_change) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) previous_inventory_change,
           lead(te.inventory_change) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) next_inventory_change,
           lag(eh.loc_type) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) previous_loc_type,
           lead(eh.loc_type) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) next_loc_type,
           eh.posted,
           SUBSTR(eh.sztp_id,1, 2) eqsz_id,
           te.inventory_change,
           eh.wtask_id,
           eh.loc_type,
           eh.line_id,
           eh.sztp_id,
           eh.term_id,
           eh.exp_so_nbr,
           eh.exp_so_subtype,
           eh.vsl_id,
           eh.voy_nbr,
           eh.fmc_free_days,
           eh.imp_so_subtype,
           eh.imp_so_nbr,
           eh.eq_class,
           eh.category,
           DECODE(eh.equse_gkey, NULL, 'E', eh.category) category_code,
           eh.status,
           eh.transship,
           eh.removed,
           eh.ROWID
      FROM equipment_history eh,
           terminal_events te
     WHERE (eh.posted < TO_DATE(:p_end_date||' 23:59:59', 'MM/DD/RR HH24:MI:SS') AND
            eh.posted > TO_DATE(:p_start_date||' 00:00:00', 'MM/DD/RR HH24:MI:SS') )
       AND eh.eq_class = 'CTR'
       AND eh.removed IS NULL
       AND te.event_group IN( 'GATE', 'VSL', 'RAIL')
       AND te.id = eh.wtask_id
       AND ((:p_live_reefer_only IS NULL) OR (:p_live_reefer_only IS NOT NULL AND eh.temp_required IS NOT NULL))
       
    )
   WHERE (inventory_change = 'IN' AND (next_inventory_change IS NOT NULL AND NOT EXISTS (SELECT 'X' FROM equipment eq WHERE eq.nbr = ctr_nbr AND eq.loc_type = 'O')))
  )
WHERE (TRUNC(in_date) BETWEEN TRUNC(start_date) AND TRUNC(end_date)  OR
       TRUNC(out_date) BETWEEN TRUNC(start_date) AND TRUNC(end_date) )
  AND illogical_move IS NULL
  AND in_date < out_date
  AND line_id NOT IN ('SSA', 'TID')


&p_parsed_lines
&p_category_criteria

/* Modified to run as a query */
SELECT ctr_nbr,
       in_date,
       out_date,
       /* For some reason the report cuts off dwell time that occurs before the period, but this can never happen due to the WHERE clause below that requires the container to arrive during the period. */
       /* It's further in error because the computation uses dates instead of times. The ROUND is completely unnecessary. */
       DECODE(SIGN(TO_NUMBER(TO_CHAR(start_date, 'YYYYMMDD') ) - TO_NUMBER(TO_CHAR(in_date, 'YYYYMMDD'))), 
                      1, ROUND(TRUNC(out_date)-TRUNC(start_date)), ROUND(TRUNC(out_date)-TRUNC(in_date))) days_in,
       in_loc_type,
       out_loc_type,
       category,
       sub_category,
       transship,
       status,
       line_id,
       eqsz_id
  FROM
  (  
  SELECT ctr_nbr,
         start_date,
         end_date,
         DECODE(inventory_change, 'IN', posted) in_date,
         DECODE(inventory_change, 'IN', DECODE(next_posted, NULL, TO_DATE(TO_CHAR(end_date, 'MM/DD/RR')||' 23:59:59', 'MM/DD/RR HH24:MI:SS'), next_posted)) out_date,
         loc_type in_loc_type,
         next_loc_type out_loc_type,
         DECODE(status, 'F',
                   DECODE(category, 'I', DECODE(loc_type, 'V', DECODE((SELECT MAX('X') FROM train_assigned_equipment WHERE equse_gkey = eqhist_gkey AND eq_nbr = ctr_nbr), 'X', 'RAIL', 'LOCAL'), 'LOCAL'),
                                    'E', DECODE(transship, NULL, 'EXPORT', 'TRANSSHIP')),
                   'STORAGE' -- All empties are categorized as "STORAGE".                               
                                    ) sub_category,
         DECODE(status, 'F', (SELECT UPPER(rv_meaning) FROM cg_ref_codes WHERE rv_domain = 'CATEGORY' AND rv_low_value = category), 'EMPTY') category,
         category_code,
         status,
         transship,
         line_id,
         eqsz_id,
         DECODE(inventory_change, previous_inventory_change, '*') illogical_move
    FROM
    (  
    SELECT 
           eh.eq_nbr ctr_nbr,
           eh.equse_gkey eqhist_gkey,
           /* Set the start date */
           --TO_DATE(:p_start_date||' 00:00:00', 'MM/DD/RR HH24:MI:SS') start_date, --original line from script
           TO_DATE('09/29/24'||' 00:00:00', 'MM/DD/RR HH24:MI:SS') start_date,
           /* Set the end date */
           --TO_DATE(:p_end_date||' 23:59:59', 'MM/DD/RR HH24:MI:SS') end_date, --original line from script
           TO_DATE('11/09/24'||' 23:59:59', 'MM/DD/RR HH24:MI:SS') end_date,
           lag(eh.posted) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) previous_posted,
           lead(eh.posted) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) next_posted,
           lag(te.inventory_change) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) previous_inventory_change,
           lead(te.inventory_change) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) next_inventory_change,
           lag(eh.loc_type) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) previous_loc_type,
           lead(eh.loc_type) over(PARTITION BY eh.eq_nbr ORDER BY eh.posted) next_loc_type,
           eh.posted,
           SUBSTR(eh.sztp_id,1, 2) eqsz_id,
           te.inventory_change,
           eh.wtask_id,
           eh.loc_type,
           eh.line_id,
           eh.sztp_id,
           eh.term_id,
           eh.exp_so_nbr,
           eh.exp_so_subtype,
           eh.vsl_id,
           eh.voy_nbr,
           eh.fmc_free_days,
           eh.imp_so_subtype,
           eh.imp_so_nbr,
           eh.eq_class,
           eh.category,
           DECODE(eh.equse_gkey, NULL, 'E', eh.category) category_code,
           eh.status,
           eh.transship,
           eh.removed,
           eh.ROWID
      /* Cross joins to the equipment history records all the terminal events records. This isn't serious. It's an incomplete join. */
      FROM equipment_history eh,
           terminal_events te
     /* Original lines from script */
     --WHERE (eh.posted < TO_DATE(:p_end_date||' 23:59:59', 'MM/DD/RR HH24:MI:SS') AND
            --eh.posted > TO_DATE(:p_start_date||' 00:00:00', 'MM/DD/RR HH24:MI:SS') )
     WHERE (eh.posted < TO_DATE('11/09/24'||' 23:59:59', 'MM/DD/RR HH24:MI:SS') AND
            eh.posted > TO_DATE('09/29/24'||' 00:00:00', 'MM/DD/RR HH24:MI:SS') )
       AND eh.eq_class = 'CTR'
       AND eh.removed IS NULL
       /* These next two lines complete the join. We're selecting for wtask_id values that belong to the GATE, VSL, or RAIL groups. */
       AND te.event_group IN( 'GATE', 'VSL', 'RAIL')
       AND te.id = eh.wtask_id
       /* Decide whether or not to look only at live reefers. */
       --AND ((:p_live_reefer_only IS NULL) OR (:p_live_reefer_only IS NOT NULL AND eh.temp_required IS NOT NULL)) --original line from script
       --AND eh.temp_required IS NOT NULL --uncomment IF you want live reefers only       
    )
   /* Selecting for paired in and out events. The next inventory change must be real and can't be to an offdock location. */
   WHERE (inventory_change = 'IN' AND (next_inventory_change IS NOT NULL AND NOT EXISTS (SELECT 'X' FROM equipment eq WHERE eq.nbr = ctr_nbr AND eq.loc_type = 'O')))
  )
/* The in_yard_at must be during the period and the out_yard_at must be too. */
WHERE (TRUNC(in_date) BETWEEN TRUNC(start_date) AND TRUNC(end_date)  OR
       TRUNC(out_date) BETWEEN TRUNC(start_date) AND TRUNC(end_date) )
  /* As defined, I believe this requirement on illogical_move misses transships that come in via VSL and leave via VSL. */
  AND illogical_move IS NULL
  AND in_date < out_date
  AND line_id NOT IN ('SSA', 'TID')
;
