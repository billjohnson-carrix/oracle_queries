--MIT berth utilization all months
--Berth occupancy, all months
WITH 
	days_in_month AS (
	  SELECT 1 AS mnth, 31 AS days FROM dual UNION ALL
	  SELECT 2, 28 FROM dual UNION ALL
	  SELECT 3, 31 FROM dual UNION ALL 
	  SELECT 4, 30 FROM dual UNION ALL 
	  SELECT 5, 31 FROM dual UNION ALL 
	  SELECT 6, 30 FROM dual UNION ALL 
	  SELECT 7, 31 FROM dual UNION ALL 
	  SELECT 8, 31 FROM dual UNION ALL 
	  SELECT 9, 30 FROM dual UNION ALL 
	  SELECT 10, 31 FROM dual UNION ALL 
	  SELECT 11, 30 FROM dual UNION ALL 
	  SELECT 12, 31 FROM dual
	), first_columns AS (
		SELECT
			vv.eta
			, vv.ATA 
			, vv.etd
			, vv.ATD
			, vv.VSL_ID 
			, vv.BERTH 
			, vv.IN_VOY_NBR 
			, vv.OUT_VOY_NBR 
			, (COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata,vv.eta)) * 24 AS StayHours
			, vc.LOA / 1000 AS loa
			, CASE 
				WHEN vv.berth = '1' OR vv.berth = '2' OR vv.berth = '3' OR vv.berth = '4' THEN vc.loa / 1000 + 30
				WHEN vv.berth = '6' THEN 300
				WHEN vv.berth = '7' THEN 250
				WHEN (vv.berth = '5' OR vv.berth = '8') AND vc.loa / 1000 < 150 THEN vc.loa / 1000 + 30
				ELSE 400
			  END AS berth_space_used
		FROM vessel_visits vv
		LEFT JOIN spinnaker.vessel spv ON spv.code = vv.vsl_id
		LEFT JOIN spinnaker.vc_class vc ON spv.CLASS_ID = vc.ID 
		WHERE 
			( 	(EXTRACT (YEAR FROM COALESCE (vv.atd, vv.etd)) = 2023 OR  
				 EXTRACT (YEAR FROM COALESCE (vv.atd, vv.etd)) = 2022) AND 
				(	vv.atd IS NOT NULL OR 
					vv.atd IS NULL AND vv.berth IS NOT null) AND 
				COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) < 10 AND 
				COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) > 0
			)
--		ORDER BY 
--			vv.ATD 
	), berth_used AS (
		SELECT 
			fc.*
			, fc.stayhours * fc.berth_space_used AS berth_used
		FROM first_columns fc
--		ORDER BY 
--			fc.vsl_id
--			, 11 desc
	)
SELECT 
	EXTRACT (YEAR FROM COALESCE (bu.atd, bu.etd)) AS year
	, dim.mnth
	, count(*) AS Calls
	, sum(bu.berth_used) AS berth_used
	, (1246 + 400 + 250 + 300 + 400) * dim.days * 20.5 AS available_berth_hours
	, sum(bu.berth_used) / (1246 + 400 + 250 + 300 + 400) / dim.days / 20.5 * 100 AS berth_util
FROM berth_used bu
JOIN days_in_month dim ON EXTRACT (MONTH FROM COALESCE (bu.atd, bu.etd)) = dim.mnth
GROUP BY 
	EXTRACT (YEAR FROM COALESCE (bu.atd, bu.etd))
	, dim.mnth
	, dim.days
ORDER BY 
	EXTRACT (YEAR FROM COALESCE (bu.atd, bu.etd))
	, dim.mnth
;

--Cutting query down for validating berth occupancy
SELECT
	vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, COALESCE (vv.ata, vv.eta) AS at
	, COALESCE (vv.atd, vv.etd) AS dt
	, (COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata,vv.eta)) * 24 AS StayHours
FROM vessel_visits vv
WHERE 
	( 	(EXTRACT (YEAR FROM COALESCE (vv.atd, vv.etd)) = 2023 OR  
		 EXTRACT (YEAR FROM COALESCE (vv.atd, vv.etd)) = 2022)
		 --AND vv.vsl_id = 'MADRID'
		 --AND 
/*		(	vv.atd IS NOT NULL OR 
			(vv.atd IS NULL AND vv.berth IS NOT NULL)) AND 
		COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) < 10 AND 
		COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) > 0
*/	)
		ORDER BY 
			5
;

SELECT * FROM vessel_visits vv WHERE vv.vsl_id = 'MADRID' AND vv.in_voy_nbr = '09E' AND 	( 	(EXTRACT (YEAR FROM COALESCE (vv.atd, vv.etd)) = 2023 OR  
		 EXTRACT (YEAR FROM COALESCE (vv.atd, vv.etd)) = 2022) --AND 
/*		(	vv.atd IS NOT NULL OR 
			(vv.atd IS NULL AND vv.berth IS NOT NULL)) AND 
		COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) < 10 AND 
		COALESCE (vv.atd, vv.etd) - COALESCE (vv.ata, vv.eta) > 0
*/	);
SELECT count(*), min(eh.posted) FROM equipment_history eh WHERE eh.vsl_id = 'MADRID' AND (eh.voy_nbr = '09E' OR eh.voy_nbr = '09E');