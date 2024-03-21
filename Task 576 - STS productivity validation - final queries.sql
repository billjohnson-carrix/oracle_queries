--MIT queries
--Productivities by vessel
--I will only compute three productivities. They will all use EH. Raw will use the work_hours computed from EH. Gross and Net will use
--gross_hours and net_hours from vessel_visits.
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, vv.gross_hours
			, vv.net_hours
			, eh.CRANE_NO 
			, count(eh.posted) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, vv.gross_hours
			, vv.net_hours
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
	)
SELECT 
	cwt.vsl_id
	, cwt.in_voy_nbr
	, cwt.out_voy_nbr
	, sum(cwt.moves) AS moves
	, sum(cwt.crane_work_hours) AS work_hours
	, cwt.gross_hours
	, cwt.net_hours
	, CASE WHEN sum(cwt.crane_work_hours) = 0 THEN NULL ELSE sum(cwt.moves) / sum(cwt.crane_work_hours) END AS "RAW"
	, CASE WHEN cwt.gross_hours = 0 THEN NULL ELSE sum(cwt.moves) / cwt.gross_hours END AS gross
	, CASE WHEN cwt.net_hours = 0 THEN NULL ELSE sum(cwt.moves) / cwt.net_hours END AS net
FROM crane_work_times cwt 
GROUP BY 
	cwt.vsl_id
	, cwt.in_voy_nbr
	, cwt.out_voy_nbr
	, cwt.atd
	, cwt.gross_hours
	, cwt.net_hours
ORDER BY cwt.atd, cwt.vsl_id
;

--Productivities by month
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, vv.gross_hours
			, vv.net_hours
			, eh.CRANE_NO 
			, count(eh.posted) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, vv.gross_hours
			, vv.net_hours
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
	), group_by_vessel AS (
		SELECT 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
			, sum(cwt.moves) AS moves
			, sum(cwt.crane_work_hours) AS work_hours
			, cwt.gross_hours
			, cwt.net_hours
			, CASE WHEN sum(cwt.crane_work_hours) = 0 THEN NULL ELSE sum(cwt.moves) / sum(cwt.crane_work_hours) END AS "RAW"
			, CASE WHEN cwt.gross_hours = 0 THEN NULL ELSE sum(cwt.moves) / cwt.gross_hours END AS gross
			, CASE WHEN cwt.net_hours = 0 THEN NULL ELSE sum(cwt.moves) / cwt.net_hours END AS net
		FROM crane_work_times cwt 
		GROUP BY 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
			, cwt.gross_hours
			, cwt.net_hours
		--ORDER BY cwt.atd, cwt.vsl_id
	)
SELECT 
	EXTRACT (YEAR FROM gbv.atd) AS year
	, EXTRACT (MONTH FROM gbv.atd) AS month
	, sum(gbv.moves) AS moves
	, sum(gbv.work_hours) AS work_hours
	, sum(gbv.gross_hours) AS gross_hours
	, sum(gbv.net_hours) AS net_hours
	, CASE WHEN sum(gbv.work_hours) = 0 THEN NULL ELSE sum(gbv.moves) / sum(gbv.work_hours) END AS "RAW"
	, CASE WHEN sum(gbv.gross_hours) = 0 THEN NULL ELSE sum(gbv.moves) / sum(gbv.gross_hours) END AS gross
	, CASE WHEN sum(gbv.net_hours) = 0 THEN NULL ELSE sum(gbv.moves) / sum(gbv.net_hours) END AS net
FROM group_by_vessel gbv
GROUP BY
	EXTRACT (YEAR FROM gbv.atd)
	, EXTRACT (MONTH FROM gbv.atd)
ORDER BY 
	EXTRACT (YEAR FROM gbv.atd)
	, EXTRACT (MONTH FROM gbv.atd)
;

--ZLO queries
--Productivities by vessel
--I will only compute three productivities. They will all use EH. Raw will use the work_hours computed from EH. Gross and Net will use
--gross_hours and net_hours from vessel_summary_delays.
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, eh.CRANE_NO 
			, count(eh.posted) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
	), vessel_visits_of_interest AS (
		SELECT 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
			, sum(cwt.moves) AS moves
			, sum(cwt.crane_work_hours) AS work_hours
		FROM crane_work_times cwt 
		GROUP BY 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
		--ORDER BY cwt.atd, cwt.vsl_id
	), vsd_moves_by_vessel_and_crane AS (
		SELECT 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vsc.crane_id
			, sum(vsc.total_moves) AS vsd_moves
			, vsd.gkey
			, vvoi.atd
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN vessel_summary_detail vsd ON
			vsd.vsl_id = vvoi.vsl_id AND 
			vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
			vsd.voy_out_nbr = vvoi.out_voy_nbr
		LEFT JOIN vessel_summary_cranes vsc ON 
			vsd.gkey = vsc.vsd_gkey
		GROUP BY 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.atd
			, vsd.gkey
			, vsc.crane_id
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
*/	), vsd_mvs_time_by_crane AS (
		SELECT 
			mbvc.vsl_id
			, mbvc.in_voy_nbr
			, mbvc.out_voy_nbr
			, mbvc.crane_id
			, mbvc.vsd_moves
			, sum(vscp.completed - vscp.commenced) * 24 AS vsd_work_days
			, mbvc.atd
		FROM vsd_moves_by_vessel_and_crane mbvc 
		LEFT JOIN vessel_summary_crane_prod vscp ON
			vscp.vsd_gkey = mbvc.gkey AND 
			vscp.crane_id = mbvc.crane_id
		GROUP BY 
			mbvc.vsl_id
			, mbvc.in_voy_nbr
			, mbvc.out_voy_nbr
			, mbvc.crane_id
			, mbvc.vsd_moves
			, mbvc.atd
/*		ORDER BY 
			mbvc.atd
			, mbvc.vsl_id
*/	), vsd_mvs_time_by_vessel AS (
		SELECT 
			mtbc.vsl_id
			, mtbc.in_voy_nbr
			, mtbc.out_voy_nbr
			, mtbc.atd
			, sum(mtbc.vsd_moves) AS vsd_moves
			, sum(mtbc.vsd_work_days) AS vsd_work_days
		FROM vsd_mvs_time_by_crane mtbc
		GROUP BY 
			mtbc.vsl_id
			, mtbc.in_voy_nbr
			, mtbc.out_voy_nbr
			, mtbc.atd
		ORDER BY 
			mtbc.atd
			, mtbc.vsl_id
	)
SELECT 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.moves AS eh_moves
	, vvoi.work_hours AS eh_work_days
	, mtbv.vsd_moves AS vsd_moves
	, mtbv.vsd_work_days AS vsd_work_days
	, sum (
		CASE 
			WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS shipping_delays
	, sum (
		CASE 
			WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS terminal_delays
	, sum (
		CASE 
			WHEN vsy.delay_time IS NOT NULL THEN
				TO_number (to_char(vsy.delay_time, 'HH24')) +
				to_number (to_char(vsy.delay_time, 'MI')) /60 +
				to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
			ELSE 0
		END) AS total_delays
FROM vessel_visits_of_interest vvoi
LEFT JOIN vessel_summary_detail vsd ON
	vsd.vsl_id = vvoi.vsl_id AND 
	vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
	vsd.voy_out_nbr = vvoi.out_voy_nbr
LEFT JOIN vessel_summary_delays vsy ON
	vsy.vsd_gkey = vsd.gkey
LEFT JOIN delay_reasons dr ON
	dr.code = vsy.delay_code
LEFT JOIN vsd_mvs_time_by_vessel mtbv ON
	vvoi.vsl_id = mtbv.vsl_id AND
	vvoi.in_voy_nbr = mtbv.in_voy_nbr AND
	vvoi.out_voy_nbr = mtbv.out_voy_nbr
GROUP BY 
	vvoi.vsl_id
	, vvoi.in_voy_nbr
	, vvoi.out_voy_nbr
	, vvoi.moves
	, vvoi.work_hours
	, mtbv.vsd_moves
	, mtbv.vsd_work_days
	, vvoi.atd
ORDER BY 
	vvoi.atd
	, vvoi.vsl_id
;

--Productivity components by month
WITH 
	crane_work_times AS (
		SELECT 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.atd
			, eh.CRANE_NO 
			, count(eh.posted) AS moves
			, GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))) AS start_time
			, LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) AS end_time 
			, greatest(0,(LEAST(MAX(eh.POSTED),COALESCE(vv.atd,MAX(eh.posted))) - 
				GREATEST(MIN(eh.posted),COALESCE(vv.ata,MIN(eh.posted))))) * 24 AS crane_work_hours
		FROM VESSEL_VISITS vv
		LEFT JOIN equipment_history eh ON 
			eh.VSL_ID = vv.VSL_ID AND 
			(eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		WHERE 
			(EXTRACT (YEAR FROM vv.atd) = 2022 OR 
			 EXTRACT (YEAR FROM vv.atd) = 2023) AND 
			(eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD' OR 
			 eh.wtask_id = 'REHCD' OR eh.wtask_id = 'REHCDT' OR 
			 eh.wtask_id = 'REHDC' OR eh.wtask_id = 'REHDCT')
		GROUP BY 
			vv.VSL_ID 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, vv.ATA
			, vv.ATD 
			, eh.CRANE_NO 
		--ORDER BY vv.ATD, vv.VSL_ID, eh.CRANE_NO
	), vessel_visits_of_interest AS (
		SELECT 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
			, sum(cwt.moves) AS moves
			, sum(cwt.crane_work_hours) AS work_hours
		FROM crane_work_times cwt 
		GROUP BY 
			cwt.vsl_id
			, cwt.in_voy_nbr
			, cwt.out_voy_nbr
			, cwt.atd
		--ORDER BY cwt.atd, cwt.vsl_id
	), vsd_moves_by_vessel_and_crane AS (
		SELECT 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vsc.crane_id
			, sum(vsc.total_moves) AS vsd_moves
			, vsd.gkey
			, vvoi.atd
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN vessel_summary_detail vsd ON
			vsd.vsl_id = vvoi.vsl_id AND 
			vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
			vsd.voy_out_nbr = vvoi.out_voy_nbr
		LEFT JOIN vessel_summary_cranes vsc ON 
			vsd.gkey = vsc.vsd_gkey
		GROUP BY 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.atd
			, vsd.gkey
			, vsc.crane_id
/*		ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
*/	), vsd_mvs_time_by_crane AS (
		SELECT 
			mbvc.vsl_id
			, mbvc.in_voy_nbr
			, mbvc.out_voy_nbr
			, mbvc.crane_id
			, mbvc.vsd_moves
			, sum(vscp.completed - vscp.commenced) * 24 AS vsd_work_days
			, mbvc.atd
		FROM vsd_moves_by_vessel_and_crane mbvc 
		LEFT JOIN vessel_summary_crane_prod vscp ON
			vscp.vsd_gkey = mbvc.gkey AND 
			vscp.crane_id = mbvc.crane_id
		GROUP BY 
			mbvc.vsl_id
			, mbvc.in_voy_nbr
			, mbvc.out_voy_nbr
			, mbvc.crane_id
			, mbvc.vsd_moves
			, mbvc.atd
/*		ORDER BY 
			mbvc.atd
			, mbvc.vsl_id
*/	), vsd_mvs_time_by_vessel AS (
		SELECT 
			mtbc.vsl_id
			, mtbc.in_voy_nbr
			, mtbc.out_voy_nbr
			, mtbc.atd
			, sum(mtbc.vsd_moves) AS vsd_moves
			, sum(mtbc.vsd_work_days) AS vsd_work_days
		FROM vsd_mvs_time_by_crane mtbc
		GROUP BY 
			mtbc.vsl_id
			, mtbc.in_voy_nbr
			, mtbc.out_voy_nbr
			, mtbc.atd
/*		ORDER BY 
			mtbc.atd
			, mtbc.vsl_id
*/	), components_by_vessel AS (
		SELECT 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.moves AS eh_moves
			, vvoi.work_hours AS eh_work_days
			, mtbv.vsd_moves AS vsd_moves
			, mtbv.vsd_work_days AS vsd_work_days
			, sum (
				CASE 
					WHEN dr.delay_level = 'S' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS shipping_delays
			, sum (
				CASE 
					WHEN dr.delay_level = 'T' AND vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS terminal_delays
			, sum (
				CASE 
					WHEN vsy.delay_time IS NOT NULL THEN
						TO_number (to_char(vsy.delay_time, 'HH24')) +
						to_number (to_char(vsy.delay_time, 'MI')) /60 +
						to_number (to_char(vsy.delay_time, 'SS')) / 60 / 60
					ELSE 0
				END) AS total_delays
			, vvoi.atd
		FROM vessel_visits_of_interest vvoi
		LEFT JOIN vessel_summary_detail vsd ON
			vsd.vsl_id = vvoi.vsl_id AND 
			vsd.voy_in_nbr = vvoi.in_voy_nbr AND 
			vsd.voy_out_nbr = vvoi.out_voy_nbr
		LEFT JOIN vessel_summary_delays vsy ON
			vsy.vsd_gkey = vsd.gkey
		LEFT JOIN delay_reasons dr ON
			dr.code = vsy.delay_code
		LEFT JOIN vsd_mvs_time_by_vessel mtbv ON
			vvoi.vsl_id = mtbv.vsl_id AND
			vvoi.in_voy_nbr = mtbv.in_voy_nbr AND
			vvoi.out_voy_nbr = mtbv.out_voy_nbr
		GROUP BY 
			vvoi.vsl_id
			, vvoi.in_voy_nbr
			, vvoi.out_voy_nbr
			, vvoi.moves
			, vvoi.work_hours
			, mtbv.vsd_moves
			, mtbv.vsd_work_days
			, vvoi.atd
		/*ORDER BY 
			vvoi.atd
			, vvoi.vsl_id
*/	)
SELECT  
	EXTRACT (YEAR FROM cbv.atd) AS year
	, EXTRACT (MONTH FROM cbv.atd) AS MONTH
	, sum(cbv.eh_moves) AS eh_moves
	, sum(cbv.eh_work_days) AS eh_work_days
	, sum(cbv.vsd_moves) AS vsd_moves
	, sum(cbv.vsd_work_days) AS vsd_work_days
	, sum(cbv.shipping_delays) AS shipping_delays
	, sum(cbv.terminal_delays) AS terminal_delays
	, sum(cbv.total_delays) AS total_delays
FROM components_by_vessel cbv
GROUP BY 
	EXTRACT (YEAR FROM cbv.atd)
	, EXTRACT (MONTH FROM cbv.atd)
ORDER BY 
	EXTRACT (YEAR FROM cbv.atd)
	, EXTRACT (MONTH FROM cbv.atd)
;
