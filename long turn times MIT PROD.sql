WITH long_turn_time_visits as(
	SELECT
		*
	FROM truck_visits tv
	WHERE (tv.exited - tv.entered) * 24 * 60 > 600
		AND tv.entered > to_date ('2024-06-01','YYYY-MM-DD')
		AND tv.entered < to_date ('2024-07-01','YYYY-MM-DD')
)
SELECT
	gt.tv_gkey
	, gt.ctr_nbr
	, ltt.entered
	, ltt.exited
	, (ltt.exited - ltt.entered) * 24 * 60 AS minutes
	, gt.*
	, ltt.*
FROM gate_transactions gt
INNER JOIN long_turn_time_visits ltt ON
	ltt.gkey = gt.tv_gkey
ORDER BY gt.tv_gkey
;

-- Now to aggegate MIT/ZLO/ZLO 2/ and ZLO AV moves by vessel for assignment to a calendar month
WITH 
	by_vessel AS (
		SELECT
			v.name
			, vv.VSL_ID 
			, vv.in_VOY_NBR
			, vv.OUT_VOY_NBR 
			, COALESCE (trunc(vv.atd), max(trunc(eh.posted))) AS dt
			, sum (CASE WHEN eh.wtask_id = 'UNLOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS imports
			, sum (CASE WHEN eh.wtask_id = 'LOAD' AND eh.transship IS NULL THEN 1 ELSE 0 end) AS exports
			, sum (CASE WHEN (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD') AND eh.transship IS NOT NULL THEN 1 ELSE 0 END) AS transships
			, count(*) AS moves
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			eh.posted > to_date('2023-12-21', 'YYYY-MM-DD') 
			AND eh.posted < to_date('2024-07-11', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
		--ORDER BY COALESCE (trunc(vv.atd), max(trunc(eh.posted)))
	) 
SELECT
	*
FROM by_vessel bv
WHERE dt > to_date('2024-01-01','YYYY-MM-DD')
	AND dt < to_date('2024-07-01','YYYY-MM-DD')
;

select 
	gt.LANE_ID,
	gt.TRUCK_RFID_NBR, 
	gt.WTASK_ID, 
	gt.CTR_NBR, 
	gt.CTR_SZTP_ID, 
	gt.LINE_ID, 
	(t.LIC_NBR || t.lic_state) LIC_PLATE, 
	gt.POS_ID,
	gt.PRECHECKED, 
	gt.DECKED, 
	trunc(((gt.DECKED - gt.PRECHECKED) * 60) * 24) TURN_TIME
from gate_transactions gt 
left outer join trucks t on gt.TRUCK_RFID_NBR = t.RFID_NBR
where 
	gt.wtask_id =  'FULLIN'
	and trunc(gt.PRECHECKED) between to_date( '06/01/2024' ,'MM/DD/YYYY') and to_date( '06/02/2024' ,'MM/DD/YYYY')
	and gt.tran_status ='EIR'
	and gt.decked is not NULL
order by gt.PRECHECKED
;