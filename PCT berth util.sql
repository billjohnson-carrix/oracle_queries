-- Emir's query (Spinnaker)
select ve.code as vsl_id
  ,vv.arr_voyage as voyage
  ,vc.loa
  ,vp.berthing_length
  ,vp.bow
  ,vp.stern
  ,bcl.location bow_cleat
  ,scl.location stern_cleat
from vv_vessel_visit vv
left join vesselpositions vp on vv.id = vp.vesselvisit_id
left join vessel ve on vv.vessel_id = ve.i_d
left join vc_class vc on ve.class_id = vc.id
left join cleats bcl on vp.bowcleat_id = bcl.id
left join cleats scl on vp.sterncleat_id = scl.id
WHERE EXTRACT (MONTH FROM vv.atd)=1 AND EXTRACT (YEAR FROM vv.atd)=2024
order by 1,2;

-- counts of Spinnaker source tables
SELECT count(*) FROM VV_VESSEL_VISIT vvv;
SELECT count(*) FROM VESSELPOSITIONS v;
SELECT count(*) FROM VESSEL v;
SELECT count(*) FROM VC_CLASS vc;
SELECT count(*) FROM CLEATS c;

SELECT count(*) FROM vc_class vc WHERE vc.loa IS NOT null;

-- Spinnaker vessel visit dates
SELECT
  EXTRACT(YEAR FROM vvv.atd) AS year,
  EXTRACT(MONTH FROM vvv.atd) AS month,
  COUNT(*) AS visit_count
FROM VV_VESSEL_VISIT vvv
GROUP BY EXTRACT(YEAR FROM vvv.atd), EXTRACT(MONTH FROM vvv.atd)
ORDER BY EXTRACT(YEAR FROM vvv.atd), EXTRACT(MONTH FROM vvv.atd);

-- Rebuilding Emir's query for Mainsail and limiting it to just the vessel lengths
SELECT  EXTRACT (MONTH FROM vv.atd) AS MONTH, v.NAME , vc."LENGTH", vv.BERTH
FROM VESSEL_VISITS vv 
LEFT JOIN VESSELS v ON v.ID = vv.VSL_ID 
LEFT JOIN VESSEL_CLASSES vc ON v.VCLASS_ID = vc.ID 
WHERE EXTRACT (YEAR FROM vv.atd)=2023
ORDER BY EXTRACT (MONTH FROM vv.atd)

SELECT count(*) FROM VC_CLASS vc WHERE not vc.loa=0;

-- Counts of Mainsail source tables
SELECT count(*) FROM VESSEL_VISITS vv;
SELECT count(*) FROM VESSELS v;
SELECT count(*) FROM VESSEL_CLASSES vc;
SELECT count(*) FROM VESSEL_CLASSES vc 
WHERE vc."LENGTH" IS NOT NULL;

-- Mainsail vessel visit dates
SELECT
  EXTRACT(YEAR FROM vv.atd) AS year,
  EXTRACT(MONTH FROM vv.atd) AS month,
  COUNT(*) AS visit_count
FROM VESSEL_VISITS vv 
GROUP BY EXTRACT(YEAR FROM vv.atd), EXTRACT(MONTH FROM vv.atd)
ORDER BY EXTRACT(YEAR FROM vv.atd), EXTRACT(MONTH FROM vv.atd);


-- Can I join the Mainsail and Spinnaker vessel tables?

-- This works well - joining on Spinny's CODE and Mainsail's ID
SELECT
	count(*) AS count
	-- CASE WHEN spv.name IS NOT NULL AND spv.name = msv.name THEN 1 ELSE 0 END AS "JoinName",
    -- CASE WHEN spv.CALL_SIGN IS NOT NULL AND spv.CALL_SIGN = msv.RADIO_CALL_SIGN THEN 1 ELSE 0 END AS "JoinSign",
	-- CASE WHEN spv.LLOYDS IS NOT NULL AND spv.LLOYDS = msv.LLOYDS_ID THEN 1 ELSE 0 END AS "JoinLloyds",
	-- spv.CODE AS "SpinnCode", msv.ID AS "MSID", spv.NAME AS "SpinnName", msv.NAME AS "MSName", spv.*, msv.*
FROM mtms.vessels msv 
JOIN spinnaker.vessel spv ON 
	spv.CODE = msv.ID 
    -- (spv.name IS NOT NULL AND spv.name = msv.name)
    -- (spv.CALL_SIGN IS NOT NULL AND spv.CALL_SIGN = msv.RADIO_CALL_SIGN) OR 
    -- (spv.LLOYDS IS NOT NULL AND spv.LLOYDS = msv.LLOYDS_ID)
-- group BY 
	-- spv.CODE, msv.ID 
	-- CASE WHEN spv.name IS NOT NULL AND spv.name = msv.name THEN 1 ELSE 0 END
	-- CASE WHEN spv.CALL_SIGN IS NOT NULL AND spv.CALL_SIGN = msv.RADIO_CALL_SIGN THEN 1 ELSE 0 END,
	-- CASE WHEN spv.LLOYDS IS NOT NULL AND spv.LLOYDS = msv.LLOYDS_ID THEN 1 ELSE 0 END
-- ORDER 
	-- CASE WHEN spv.name IS NOT NULL AND spv.name = msv.name THEN 1 ELSE 0 END
	-- CASE WHEN spv.CALL_SIGN IS NOT NULL AND spv.CALL_SIGN = msv.RADIO_CALL_SIGN THEN 1 ELSE 0 END,
	-- CASE WHEN spv.LLOYDS IS NOT NULL AND spv.LLOYDS = msv.LLOYDS_ID THEN 1 ELSE 0 END
	-- BY 1 DESC
;

SELECT msv.*, spv.*
FROM mtms.vessels msv
JOIN spinnaker.vessel spv ON
	spv.code=msv.id;

SELECT count(*) AS count, CASE WHEN count(DISTINCT spv.code)=count(spv.code) THEN 1 ELSE 0 END AS "Unique?"
FROM mtms.vessels msv
JOIN spinnaker.vessel spv ON
	spv.code=msv.id;

-- missing Spinnaker vessels
SELECT  
    count(*) AS "Missing Spinnaker vessels"
FROM 
    mtms.vessels t1
RIGHT JOIN 
    spinnaker.vessel t2 ON t1.id = t2.code
WHERE 
    t1.id IS NULL; 
   
-- missing Mainsail vessels
SELECT  
    count(*) AS "Missing Mainsail vessels"
FROM 
    mtms.vessels t1
LEFT JOIN 
    spinnaker.vessel t2 ON t1.id = t2.code
WHERE 
    t2.code IS NULL;    

SELECT count(*) FROM spinnaker.vessel v;
SELECT count(*) FROM mtms.vessels v;

-- Now to join Spinny's vessel classes to Mainsail's vessel visits
SELECT
	EXTRACT (MONTH FROM vv.atd) AS month, count(*) AS count -- msv.*, spv.*, vc.*
FROM 
	mtms.vessels msv
JOIN spinnaker.vessel spv ON spv.code=msv.id
JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
WHERE EXTRACT (YEAR FROM vv.atd)=2023 AND vv
GROUP BY EXTRACT (MONTH FROM vv.atd)
ORDER BY EXTRACT (MONTH FROM vv.atd)
;

-- Inspecting the berth assignment data in Mainsail
-- Here are all the vessel visits, including those with null berths
SELECT sum("count") FROM (SELECT berth, count(berth) AS "count" FROM mtms.VESSEL_VISITS vv GROUP BY berth 
	UNION SELECT berth, count(*) AS "count" FROM mtms.vessel_visits vv WHERE vv.berth IS NULL GROUP BY vv.berth ORDER BY "count" DESC);
SELECT count(*) FROM mtms.vessel_visits;

-- Here are the vessel visits where berth is not null.
SELECT sum(t1."count") FROM (SELECT berth, count(berth) AS "count" FROM mtms.VESSEL_VISITS vv GROUP BY berth ORDER BY count(berth)) t1;

-- The non-null berths are partitioned by whether the berth data is clean or not
SELECT t1."Quality", COUNT(t1.berth) AS berth_count
FROM 
    (SELECT 
        vv.berth,
        CASE WHEN vv.berth='1' OR vv.berth='2' OR vv.berth='3' OR vv.berth='4'
             OR vv.berth='5' OR vv.berth='6' OR vv.berth='7' OR vv.berth='8' THEN 'Clean' ELSE 'Mixed' END AS "Quality"
    FROM mtms.vessel_visits vv) t1
GROUP BY t1."Quality";

-- My conclusion is that I can reasonably limit the berth values to the ones listed in the case statemenet as 'Clean'.

-- Here's the first join across the four tables in Mainsail and Spinny to get the data needed for berth utilization.
SELECT
	msv.name, vv.ata, vv.atd, vv.berth, vc.loa -- spv.CALL_SIGN 
	-- vv.berth, spv.CALL_SIGN, count(*) -- Berths 6 AND 7 ARE RORO
FROM 
	mtms.vessels msv
JOIN spinnaker.vessel spv ON spv.code=msv.id
JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
WHERE EXTRACT (YEAR FROM vv.atd)=2023 AND EXTRACT (MONTH FROM vv.atd)=1
-- GROUP BY vv.berth, spv.CALL_SIGN
-- ORDER BY 1
;

-- 1 through 4 are continuous. 5 and 8 are discrete. 6 and 7 are roro.

-- Here's how often each berth was used in a month
SELECT sum(t1."count") from
	(SELECT
		vv.berth, count(*) AS "count"
	FROM 
		mtms.vessels msv
	JOIN spinnaker.vessel spv ON spv.code=msv.id
	JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
	JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
	--WHERE EXTRACT (YEAR FROM vv.atd)=2023 AND EXTRACT (MONTH FROM vv.atd)=1
	GROUP BY vv.berth
	ORDER BY 2 desc) t1
;

SELECT count(*)
FROM 
	mtms.vessels msv
JOIN spinnaker.vessel spv ON spv.code=msv.id
JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
WHERE EXTRACT (YEAR FROM vv.atd)=2023 AND EXTRACT (MONTH FROM vv.atd)=1;

-- Total lengths of berths if they were all continuous
SELECT * FROM spinnaker.berths ORDER BY name, dock_id;

-- Total length of the continuous dock
SELECT 
	sum(ENDLOCATION)-sum(STARTLOCATION) AS "total berth length" 
FROM spinnaker.berths b
WHERE b.name = 'BERTH 1' OR b.name = 'BERTH 2' OR b.NAME = 'BERTH 3' OR b.name = 'BERTH 4';

-- Working toward detecting continuous verses discrete berths
SELECT 
	t2.dock_id, CASE WHEN count(t2.dock_id)=1 THEN 'Discrete' ELSE 'Continuous' END AS "DockType"
FROM 
	(SELECT 
		t1.*, bb.name 
	FROM 
		(SELECT b.dock_id, sum(b.ENDLOCATION)-sum(b.STARTLOCATION) AS "DockLength"
		 FROM spinnaker.berths b
		 GROUP BY b.DOCK_ID) t1
	JOIN spinnaker.BERTHS bb ON bb.DOCK_ID =t1.dock_id
	ORDER BY bb.name) t2
GROUP BY t2.dock_id;

-- Computing berth utilization based on joining the vessel and vessels table in Spinny and Mainsail, respectively, may not work for all UAT servers.
-- I'm prioritizing the simplest computation so that the risk from the data quality in other servers can be determined as quickly as possible.
-- Refinement to use dicrete and continuous docks can come later.
-- That means that all I need are the vessel lengths and stay durations for each vessel visit so that I can compute a berth utilization for each vessel visit.
-- I then sum the individual berth utilizations and divide by the total berth length and the period of interest.

SELECT * FROM spinnaker.BERTHS b ORDER BY b.name;

-- The total berth length at MIT is 2705500 mm.
-- Continuous berth length at MIT is 1228000 mm.
-- Berth 5 is 404000 mm.
-- Berth 8 is 479000 mm.
SELECT 
	sum(b.endlocation) - sum(b.STARTLOCATION) AS TotalBerthLength
FROM
	spinnaker.berths b
;

--The period of interest is 31 days.
SELECT 
  TO_DATE('2023-02-01', 'YYYY-MM-DD') - TO_DATE('2023-01-01', 'YYYY-MM-DD') AS days
FROM dual;

-- PCT's total berth length from the web is 1799m
-- 1799000 * 31 = 55769000
-- 1799000 * 30 = 53970000
-- 1799000 * 28 = 50372000
-- There is one berth and it is 30 m long.
-- I deleted the division by the total berth length so that the query reports the absolute berth utilization instead of a percentage

-- Adding the berth utilization to each vessel vist in the period of interest
-- The 50K added to vc.load is a 25 m safety margin off the bow and the stern
-- MIT breaks berth utilization down by Berths 1-4, then 5 and 8 for container terminals and 6 and 7 for RORO

SELECT 
	sum(t1.BerthUtilContAuto )*100 AS "Berth Util Cont. (%)"
FROM
	(
	SELECT
		msv.name, vv.ata, vv.atd, vv.berth, vc.loa,
		vv.atd-vv.ata AS StayInDays,
		CASE 
			WHEN 	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
				THEN (vc.loa+50000)*(vv.atd-vv.ata)/1799000/31
			WHEN	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
				THEN (vc.loa+50000)*(vv.atd-vv.ata)/1799000/30
			WHEN	(EXTRACT (MONTH FROM vv.atd)=2)
				THEN (vc.loa+50000)*(vv.atd-vv.ata)/1799000/28
		END AS BerthUtilContAuto
	FROM 
		mtms.vessels msv
	JOIN spinnaker.vessel spv ON spv.code=msv.id
	JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
	JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
	WHERE EXTRACT (YEAR FROM vv.atd)=2023
	AND atd-ata<10
	-- AND EXTRACT (MONTH FROM atd)=1
	ORDER BY berth, atd
	) t1
	GROUP BY EXTRACT (MONTH FROM t1.atd)
	ORDER BY EXTRACT (MONTH FROM t1.atd)
;

SELECT
	extract(YEAR FROM vv.atd) AS YEAR
	, EXTRACT (MONTH FROM vv.atd) AS MONTH
	, count(*)
FROM 
	mtms.vessels msv
JOIN spinnaker.vessel spv ON spv.code=msv.id
JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
AND atd-ata<10
WHERE EXTRACT (YEAR FROM vv.atd)=2023 --and EXTRACT (YEAR FROM vv.atd)>=2018
		AND extract(MONTH FROM vv.atd)=1
GROUP BY EXTRACT(YEAR FROM vv.atd), EXTRACT(MONTH FROM vv.atd)
ORDER BY EXTRACT(YEAR FROM vv.atd), EXTRACT(MONTH FROM vv.atd);
