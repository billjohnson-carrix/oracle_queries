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

SELECT count(*) FROM VESSEL_CLASSES WHERE "LENGTH" IS NOT null;

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
	WHERE EXTRACT (YEAR FROM vv.atd)=2023 AND EXTRACT (MONTH FROM vv.atd)=1
	GROUP BY vv.berth
	ORDER BY 1) t1
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
WHERE 
	-- NOT (b.NAME='MUELLE 8' OR b.name='MUELLE 9') -- gives total berth length
	-- b.NAME='BERTH 1' OR b.NAME='BERTH 2' OR b.name='BERTH 3' OR b.name='BERTH 4' -- gives the continuous berth length
	-- b.name='BERTH 5'
	b.name='BERTH 9'
;

--The period of interest is 31 days.
SELECT 
  TO_DATE('2023-02-01', 'YYYY-MM-DD') - TO_DATE('2023-01-01', 'YYYY-MM-DD') AS days
FROM dual;

-- Total berth capacity is the product of 2705500 mm and 31 days = 83870500 mm-days
-- Continuous berth capacity is 1228000 * 31 = 38068000
-- 								1228000 * 30 = 36840000
-- 								1228000 * 28 = 34384000
-- Berth 5 capacity is 404000 * 31 = 12524000
--					   404000 * 30 = 12120000
--					   404000 * 28 = 11312000
-- Berth 8 capacity is 479000 * 31 = 14849000
--					   479000 * 30 = 14370000
--					   479000 * 28 = 13412000
-- Berth 6 capacity is 392000 * 31 = 12152000
--					   392000 * 30 = 11760000
--					   392000 * 28 = 10976000
-- Berth 7 capacity is 202500 * 31 = 6277500
--					   202500 * 30 = 6075000
--					   202500 * 28 = 5670000
-- Yeah, I'll come back to doing this simple thing in SQL sometime later.

-- Adding the berth utilization to each vessel vist in the period of interest
-- The 50K added to vc.load is a 25 m safety margin off the bow and the stern
-- MIT breaks berth utilization down by Berths 1-4, then 5 and 8 for container terminals and 6 and 7 for RORO

SELECT 
	sum(t1.BerthUtil )/5670000*100 AS "Berth Util Cont. (%)"
	, sum(t1.Berth8Util)/5670000*100 AS "Berth 8 Util Disc. (%)"
	, sum(t1.Berth8Bin)/5670000*100 AS "Berth 8 Util Bin. (%)"
	, sum(t1.Berth5Util)/5670000*100 AS "Berth 5 Util Disc. (%)"
	, sum(t1.Berth5Bin)/5670000*100 AS "Berth 5 Util Bin. (%)"
	, sum(t1.Berth6Bin)/5670000*100 AS "Berth 6 Util Bin. (%)"
	, sum(t1.Berth7Bin)/5670000*100 AS "Berth 7 Util Bin. (%)"
FROM
	(
	SELECT
		msv.name, vv.ata, vv.atd, vv.berth, vc.loa,
		vv.atd-vv.ata AS StayInDays,
		(vc.loa+50000)*(vv.atd-vv.ata) AS BerthUtil,
		(CASE WHEN (vc.loa+50000)>=282800 AND (vc.loa+50000)<404000 THEN 404000 ELSE (vc.loa+50000) END)*(vv.atd-vv.ata) AS Berth5Util,
		(CASE WHEN (vc.loa+50000)>=335300 AND (vc.loa+50000)<479000 THEN 479000 ELSE (vc.loa+50000) END)*(vv.atd-vv.ata) AS Berth8Util,
		404000 *(vv.atd-vv.ata) AS Berth5Bin,
		479000 *(vv.atd-vv.ata) AS Berth8Bin,		
		392000 *(vv.atd-vv.ata) AS Berth6Bin,
		202500 *(vv.atd-vv.ata) AS Berth7Bin,
		atd-ata AS days
	FROM 
		mtms.vessels msv
	JOIN spinnaker.vessel spv ON spv.code=msv.id
	JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
	JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
	WHERE EXTRACT (YEAR FROM vv.atd)=2023
	-- AND (vv.berth='1' OR vv.berth='2' OR vv.berth='3' OR vv.berth='4')
	-- AND (vv.berth='5')
	-- AND (vv.berth='8')
	AND (vv.berth='6')
	-- AND (vv.berth='7')
	AND atd-ata<10
	-- AND EXTRACT (MONTH FROM atd)=1
	-- ORDER BY ata
	) t1
	GROUP BY EXTRACT (MONTH FROM t1.atd)
	ORDER BY EXTRACT (MONTH FROM t1.atd)
;


-- Lengths: Berths 1 through 4: 1228000; Berth 5: 404000; Berth 6: 392000; Berth 7: 202500; Berth 8: 479000
SELECT
	sum(t1.Berths1t4UtilContAuto)*100 AS "Berth 1-4 Util Cont. Auto."
	, sum(t1.Berth5UtilContAuto)*100 AS "Berth 5 Util Cont. Auto. (%)"
	, sum(t1.Berth5UtilDiscAuto)*100 AS "Berth 5 Util Disc. Auto. (%)"
	, sum(t1.Berth5UtilBinAuto)*100 AS "Berth 5 Util Bin. Auto. (%)"
	, sum(t1.Berth8UtilContAuto)*100 AS "Berth 8 Util Cont. Auto. (%)"
	, sum(t1.Berth8UtilDiscAuto)*100 AS "Berth 8 Util Disc. Auto. (%)"
	, sum(t1.Berth8UtilBinAuto)*100 AS "Berth 8 Util Bin. Auto. (%)"
	, sum(t1.Berth6UtilBinAuto)*100 AS "Berth 6 Util Bin. Auto. (%)"
	, sum(t1.Berth7UtilBinAuto)*100 AS "Berth 7 Util Bin. Auto. (%)"
FROM
	(
	SELECT
		msv.name, vv.ata, vv.atd, vv.berth, vc.loa,
		vv.atd-vv.ata AS StayInDays,
		CASE 
			WHEN 	(vv.berth='1' OR vv.berth='2' OR vv.berth='3' OR vv.berth='4')
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					THEN (vc.loa+50000)*(vv.atd-vv.ata)/1228000/31
			WHEN	(vv.berth='1' OR vv.berth='2' OR vv.berth='3' OR vv.berth='4')
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					THEN (vc.loa+50000)*(vv.atd-vv.ata)/1228000/30
			WHEN	(vv.berth='1' OR vv.berth='2' OR vv.berth='3' OR vv.berth='4')
					AND	(EXTRACT (MONTH FROM vv.atd)=2)
					THEN (vc.loa+50000)*(vv.atd-vv.ata)/1228000/28
		END AS Berths1t4UtilContAuto,
		CASE 
			WHEN	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					THEN (vc.loa+50000)*(vv.atd-vv.ata)/404000/31
			WHEN	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					THEN (vc.loa+50000)*(vv.atd-vv.ata)/404000/30
			WHEN	vv.berth='5' AND	(EXTRACT (MONTH FROM vv.atd)=2)
					THEN (vc.loa+50000)*(vv.atd-vv.ata)/404000/28
			END AS Berth5UtilContAuto,
		CASE
			WHEN 	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					AND (vc.loa+50000)>=0.7*404000 AND (vc.loa+50000)<404000 THEN (vv.atd-vv.ata)/31
			WHEN 
				 	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					AND NOT ((vc.loa+50000)>=0.7*404000 AND (vc.loa+50000)<404000) THEN (vc.loa+50000)*(vv.atd-vv.ata)/404000/31
			WHEN 	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					AND (vc.loa+50000)>=0.7*404000 AND (vc.loa+50000)<404000 THEN (vv.atd-vv.ata)/30
			WHEN 
				 	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					AND NOT ((vc.loa+50000)>=0.7*404000 AND (vc.loa+50000)<404000) THEN (vc.loa+50000)*(vv.atd-vv.ata)/404000/30
			WHEN 
				 	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=2)
					AND (vc.loa+50000)>=0.7*404000 AND (vc.loa+50000)<404000 THEN (vv.atd-vv.ata)/28
			WHEN 
				 	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=2)
					AND NOT((vc.loa+50000)>=0.7*404000 AND (vc.loa+50000)<404000) THEN (vc.loa+50000)*(vv.atd-vv.ata)/404000/28
		END AS Berth5UtilDiscAuto,
		CASE
			WHEN 	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					 THEN (vv.atd-vv.ata)/31
			WHEN 	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					 THEN (vv.atd-vv.ata)/30
			WHEN 	vv.berth='5'
					AND	(EXTRACT (MONTH FROM vv.atd)=2)
					 THEN (vv.atd-vv.ata)/28
		END AS Berth5UtilBinAuto,
		CASE 
			WHEN	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					THEN (vc.loa+50000)*(vv.atd-vv.ata)/479000/31
			WHEN	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					THEN (vc.loa+50000)*(vv.atd-vv.ata)/479000/30
			WHEN	vv.berth='8' AND	(EXTRACT (MONTH FROM vv.atd)=2)
					THEN (vc.loa+50000)*(vv.atd-vv.ata)/479000/28
			END AS Berth8UtilContAuto,
		CASE
			WHEN 	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					AND (vc.loa+50000)>=0.7*479000 AND (vc.loa+50000)<479000 THEN (vv.atd-vv.ata)/31
			WHEN 
				 	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					AND NOT ((vc.loa+50000)>=0.7*479000 AND (vc.loa+50000)<479000) THEN (vc.loa+50000)*(vv.atd-vv.ata)/479000/31
			WHEN 	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					AND (vc.loa+50000)>=0.7*479000 AND (vc.loa+50000)<479000 THEN (vv.atd-vv.ata)/30
			WHEN 
				 	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					AND NOT ((vc.loa+50000)>=0.7*479000 AND (vc.loa+50000)<479000) THEN (vc.loa+50000)*(vv.atd-vv.ata)/479000/30
			WHEN 
				 	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=2)
					AND (vc.loa+50000)>=0.7*479000 AND (vc.loa+50000)<479000 THEN (vv.atd-vv.ata)/28
			WHEN 
				 	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=2)
					AND NOT((vc.loa+50000)>=0.7*479000 AND (vc.loa+50000)<479000) THEN (vc.loa+50000)*(vv.atd-vv.ata)/479000/28
		END AS Berth8UtilDiscAuto,
		CASE
			WHEN 	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					 THEN (vv.atd-vv.ata)/31
			WHEN 	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					 THEN (vv.atd-vv.ata)/30
			WHEN 	vv.berth='8'
					AND	(EXTRACT (MONTH FROM vv.atd)=2)
					 THEN (vv.atd-vv.ata)/28
		END AS Berth8UtilBinAuto,
		CASE
			WHEN 	vv.berth='6'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					 THEN (vv.atd-vv.ata)/31
			WHEN 	vv.berth='6'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					 THEN (vv.atd-vv.ata)/30
			WHEN 	vv.berth='6'
					AND	(EXTRACT (MONTH FROM vv.atd)=2)
					 THEN (vv.atd-vv.ata)/28
		END AS Berth6UtilBinAuto,
		CASE
			WHEN 	vv.berth='7'
					AND	(EXTRACT (MONTH FROM vv.atd)=1 OR EXTRACT (MONTH FROM vv.atd)=3 OR EXTRACT (MONTH FROM vv.atd)=5 OR EXTRACT (MONTH FROM vv.atd)=7
					 	 OR EXTRACT (MONTH FROM vv.atd)=8 OR EXTRACT (MONTH FROM vv.atd)=10 OR EXTRACT (MONTH FROM vv.atd)=12)
					 THEN (vv.atd-vv.ata)/31
			WHEN 	vv.berth='7'
					AND	(EXTRACT (MONTH FROM vv.atd)=4 OR EXTRACT (MONTH FROM vv.atd)=6 OR EXTRACT (MONTH FROM vv.atd)=9 OR EXTRACT (MONTH FROM vv.atd)=11)
					 THEN (vv.atd-vv.ata)/30
			WHEN 	vv.berth='7'
					AND	(EXTRACT (MONTH FROM vv.atd)=2)
					 THEN (vv.atd-vv.ata)/28
		END AS Berth7UtilBinAuto,
		atd-ata AS days
	FROM 
		mtms.vessels msv
	JOIN spinnaker.vessel spv ON spv.code=msv.id
	JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
	JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
	WHERE EXTRACT (YEAR FROM vv.atd)=2023
	AND atd-ata<10
	) t1
	GROUP BY EXTRACT (MONTH FROM t1.atd)
	ORDER BY EXTRACT (MONTH FROM t1.atd)
;

-- Debugging leaky vessel to vessels join for MIT, ZLO, PCT, and T5S.
-- Counts of vessel calls for each month
SELECT
	EXTRACT (YEAR FROM vv.atd)
	, EXTRACT (MONTH FROM vv.atd)
	, count(*)
FROM mtms.vessels msv
JOIN spinnaker.vessel spv ON spv.code=msv.id
JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
WHERE EXTRACT (YEAR FROM vv.atd)=2023 OR EXTRACT (year FROM vv.atd) = 2022
GROUP BY EXTRACT (YEAR FROM vv.atd), EXTRACT (MONTH FROM vv.atd)
ORDER BY EXTRACT (YEAR FROM vv.atd), EXTRACT (MONTH FROM vv.atd)
;

-- The leaky list of vessel visits
SELECT
	msv.name
	, vv.VSL_ID 
	, vv.IN_VOY_NBR 
	, vv.OUT_VOY_NBR 
	, vv.ATD 
FROM mtms.vessels msv
JOIN spinnaker.vessel spv ON spv.code=msv.id
JOIN spinnaker.VC_CLASS vc ON spv.CLASS_ID=vc.id
JOIN mtms.VESSEL_VISITS vv ON vv.VSL_ID=msv.ID 
WHERE EXTRACT (YEAR FROM vv.atd)=2023 OR EXTRACT (year FROM vv.atd) = 2022
ORDER BY vv.ATD
;

-- Count of vessel visits by month from mtms.vessel_visits
SELECT 
	EXTRACT (YEAR FROM msvv.atd) AS Year
	, EXTRACT (MONTH FROM msvv.atd) AS Month
	, count(*) AS Count
FROM mtms.vessel_visits msvv
--LEFT JOIN mtms.vessels msv ON msv.id = msvv.vsl_id
--LEFT JOIN spinnaker.vessel spv ON spv.code = msvv.vsl_id
--LEFT JOIN spinnaker.vc_class vc ON vc.id = spv.CLASS_ID 
WHERE EXTRACT (YEAR FROM msvv.atd) = 2022 OR EXTRACT (YEAR FROM msvv.atd) = 2023
	--OR EXTRACT (YEAR FROM msvv.atd) = 2021
GROUP BY EXTRACT (YEAR FROM msvv.atd), EXTRACT (MONTH FROM msvv.atd)
ORDER BY EXTRACT (YEAR FROM msvv.atd), EXTRACT (MONTH FROM msvv.atd)
;

-- Leaks fixed 
SELECT 
	EXTRACT (YEAR FROM msvv.atd) AS Year
	, EXTRACT (MONTH FROM msvv.atd) AS Month
	, count(*) AS Count 
FROM mtms.vessel_visits msvv
LEFT JOIN mtms.vessels msv ON msv.id = msvv.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = msvv.vsl_id
LEFT JOIN spinnaker.vc_class vc ON vc.id = spv.CLASS_ID 
WHERE EXTRACT (YEAR FROM msvv.atd) = 2022 OR EXTRACT (YEAR FROM msvv.atd) = 2023
	--OR EXTRACT (YEAR FROM msvv.atd) = 2021
GROUP BY EXTRACT (YEAR FROM msvv.atd), EXTRACT (MONTH FROM msvv.atd)
ORDER BY EXTRACT (YEAR FROM msvv.atd), EXTRACT (MONTH FROM msvv.atd)
;

-- List of vessels without leaks
SELECT 
	msv.name AS Name
	, msvv.IN_VOY_NBR AS "In"
	, msvv.OUT_VOY_NBR AS Out
	, msvv.atd AS ATD
FROM mtms.vessel_visits msvv
LEFT JOIN mtms.vessels msv ON msv.id = msvv.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = msvv.vsl_id
LEFT JOIN spinnaker.vc_class vc ON vc.id = spv.CLASS_ID 
WHERE trunc(msvv.atd) BETWEEN to_date('2023-06-01', 'YYYY-MM-DD') AND to_date('2023-12-24', 'YYYY-MM-DD')
	AND msvv.BERTH IS NOT NULL 
ORDER BY msvv.atd
;

--This is how I got a good list of vessel visits for throughput
--The above query doesn't leak any visits from the vessel_visits table, but those visits aren't all necessarily valid if they didn't work any moves.
SELECT
	v.name
	, vv.VSL_ID 
	, vv.in_VOY_NBR
	, vv.OUT_VOY_NBR 
	, COALESCE (vv.atd, max(trunc(eh.posted))) AS dt
FROM EQUIPMENT_HISTORY eh 
JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
JOIN VESSELS v ON vv.VSL_ID = v.ID 
WHERE 
	trunc(eh.posted) BETWEEN to_date('2022-03-01', 'YYYY-MM-DD') AND to_date('2024-12-31', 'YYYY-MM-DD')
	AND eh.vsl_id IS NOT NULL
	AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
GROUP BY v.name, vv.VSL_ID, vv.in_VOY_NBR, vv.OUT_VOY_NBR, vv.atd
ORDER BY dt
;

--Now let's assign those counts of vessel calls to fiscal months.
-- Need to finish this query
/*
 * I fixed the leaks from bridging the MS vessel visits table to Spinny's vessel class table, but the vessel visits in MS vessel visits table aren't 
 * a great source of vessel visits. There are too many that don't show up on the report for PCT. I have a good list of vessel visit from the throughput validation.
 * I'll use that to get a list of vessel visits and then join that to the Spinny vessel class table.
 */

WITH 
	date_series AS (
		  SELECT
		    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD')
	)
	, fiscal_calendar AS (
		SELECT
		  date_in_series,
		  CASE 
		    WHEN 
		    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
			THEN 1
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
		    THEN 2
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
			THEN 3    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
		    THEN 4    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
		    THEN 5
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
		    THEN 6
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
		    THEN 7
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
		    THEN 8
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
		    THEN 9
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
		    THEN 10
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
		    THEN 11
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		    THEN 12
		  END AS fiscal_month,
		  CASE 
		    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
		    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
		    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
		    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
		    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
		    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
		  END AS fiscal_year
		FROM date_series
	), vessel_calls AS (
		SELECT
			v.name
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, trunc(COALESCE (vv.atd, max(eh.posted))) AS dt
			, count(*) AS calls
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.in_voy_nbr, vv.out_voy_nbr, vv.atd
	)
SELECT
	fc.fiscal_year AS Year
	, fc.fiscal_month AS Month
	, count(*) AS calls
FROM vessel_calls vc
JOIN fiscal_calendar fc ON vc.dt = fc.date_in_series
GROUP BY fc.fiscal_year, fc.fiscal_month
ORDER BY fc.fiscal_year, fc.fiscal_month
;

-- This list of vessel calls agrees well with the reported list of vessel calls.
-- The monthly summary is not quite reconciled with the list of vessel calls so I'm using the list of vessel calls.
-- This list has three extra vessels from Mar '22 through Dec '23: Bal Peace 9-Mar-2022,  Cosco Jasmine 8-Sep-2023, and Avessel 21-Dec-23.
-- Those are the only variances with the list of vessel calls
WITH 
	date_series AS (
		  SELECT
		    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD')
	)
	, fiscal_calendar AS (
		SELECT
		  date_in_series,
		  CASE 
		    WHEN 
		    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
			THEN 1
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
		    THEN 2
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
			THEN 3    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
		    THEN 4    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
		    THEN 5
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
		    THEN 6
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
		    THEN 7
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
		    THEN 8
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
		    THEN 9
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
		    THEN 10
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
		    THEN 11
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		    THEN 12
		  END AS fiscal_month,
		  CASE 
		    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
		    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
		    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
		    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
		    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
		    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
		  END AS fiscal_year
		FROM date_series
	), vessel_calls_almost AS (
		SELECT
			v.name
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, trunc(COALESCE (vv.atd, max(eh.posted))) AS dt
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.in_voy_nbr, vv.out_voy_nbr, vv.atd
	) 
SELECT *
FROM vessel_calls_almost vca
WHERE vca.dt BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
ORDER BY vca.dt
;

--Now to join the good list of vessel calls to Spinny's vessel_class table via the vessel and vessels tables
--Berth utilization at PCT by vessel. Working well.
WITH 
	date_series AS (
		  SELECT
		    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD')
	)
	, fiscal_calendar AS (
		SELECT
		  date_in_series,
		  CASE 
		    WHEN 
		    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
			THEN 1
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
		    THEN 2
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
			THEN 3    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
		    THEN 4    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
		    THEN 5
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
		    THEN 6
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
		    THEN 7
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
		    THEN 8
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
		    THEN 9
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
		    THEN 10
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
		    THEN 11
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		    THEN 12
		  END AS fiscal_month,
		  CASE 
		    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
		    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
		    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
		    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
		    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
		    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
		  END AS fiscal_year
		FROM date_series
	), vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		ORDER BY vca.departure
	)
SELECT 
	msv.name AS Name
	, vc.vsl_id AS "ID"
	, vc.IN_VOY_NBR AS "In"
	, vc.OUT_VOY_NBR AS "Out"
	, vc.arrival
	, vc.departure
	, vc.berth
	, round(svc.loa/1000) AS LENGTH
	, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
	, round((
		CASE 
			WHEN svc.loa >= 250000 AND svc.loa < 360000 THEN 360000 + 50000
			WHEN svc.loa = 0 THEN 0
			ELSE svc.loa + 50000 
		END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
FROM vessel_calls vc
LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
ORDER BY vc.departure
;

--Now by fiscal month. This is working well for PCT.
WITH 
	date_series AS (
		  SELECT
		    TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 AS date_in_series
		  FROM dual
		  CONNECT BY TO_DATE('2017-12-30', 'YYYY-MM-DD') + LEVEL - 1 <= to_date('2023-12-29', 'YYYY-MM-DD')
	)
	, fiscal_calendar AS (
		SELECT
		  date_in_series,
		  CASE 
		    WHEN 
		    	date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-01-26', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-01-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2020-01-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-01-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-01-28', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-01-27', 'YYYY-MM-DD')
			THEN 1
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-01-27', 'YYYY-MM-DD') AND to_date('2018-02-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-01-26', 'YYYY-MM-DD') AND to_date('2019-02-22', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-02-01', 'YYYY-MM-DD') AND to_date('2020-02-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-01-30', 'YYYY-MM-DD') AND to_date('2021-02-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-01-29', 'YYYY-MM-DD') AND to_date('2022-02-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-01-28', 'YYYY-MM-DD') AND to_date('2023-02-24', 'YYYY-MM-DD')
		    THEN 2
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-02-24', 'YYYY-MM-DD') AND to_date('2018-03-30', 'YYYY-MM-DD')
				OR date_in_series BETWEEN to_date('2019-02-23', 'YYYY-MM-DD') AND to_date('2019-03-29', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2020-02-29', 'YYYY-MM-DD') AND to_date('2020-04-03', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2021-02-27', 'YYYY-MM-DD') AND to_date('2021-04-02', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2022-04-01', 'YYYY-MM-DD') 	
				OR date_in_series BETWEEN to_date('2023-02-25', 'YYYY-MM-DD') AND to_date('2023-03-31', 'YYYY-MM-DD')
			THEN 3    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-03-31', 'YYYY-MM-DD') AND to_date('2018-04-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-03-30', 'YYYY-MM-DD') AND to_date('2019-04-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-04-04', 'YYYY-MM-DD') AND to_date('2020-05-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-04-03', 'YYYY-MM-DD') AND to_date('2021-04-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-04-02', 'YYYY-MM-DD') AND to_date('2022-04-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-04-01', 'YYYY-MM-DD') AND to_date('2023-04-28', 'YYYY-MM-DD')
		    THEN 4    
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-04-28', 'YYYY-MM-DD') AND to_date('2018-05-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-04-27', 'YYYY-MM-DD') AND to_date('2019-05-24', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-05-02', 'YYYY-MM-DD') AND to_date('2020-05-29', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-05-01', 'YYYY-MM-DD') AND to_date('2021-05-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-04-30', 'YYYY-MM-DD') AND to_date('2022-05-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-04-29', 'YYYY-MM-DD') AND to_date('2023-05-26', 'YYYY-MM-DD')
		    THEN 5
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-05-26', 'YYYY-MM-DD') AND to_date('2018-06-29', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2019-05-25', 'YYYY-MM-DD') AND to_date('2019-06-28', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2020-05-30', 'YYYY-MM-DD') AND to_date('2020-07-03', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2021-05-29', 'YYYY-MM-DD') AND to_date('2021-07-02', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2022-05-28', 'YYYY-MM-DD') AND to_date('2022-07-01', 'YYYY-MM-DD') 
		    	OR date_in_series BETWEEN to_date('2023-05-27', 'YYYY-MM-DD') AND to_date('2023-06-30', 'YYYY-MM-DD')
		    THEN 6
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-06-30', 'YYYY-MM-DD') AND to_date('2018-07-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-06-29', 'YYYY-MM-DD') AND to_date('2019-07-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-07-04', 'YYYY-MM-DD') AND to_date('2020-07-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-07-03', 'YYYY-MM-DD') AND to_date('2021-07-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-07-02', 'YYYY-MM-DD') AND to_date('2022-07-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-07-01', 'YYYY-MM-DD') AND to_date('2023-07-28', 'YYYY-MM-DD')
		    THEN 7
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-07-28', 'YYYY-MM-DD') AND to_date('2018-08-24', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-07-27', 'YYYY-MM-DD') AND to_date('2019-08-23', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-08-01', 'YYYY-MM-DD') AND to_date('2020-08-28', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-07-31', 'YYYY-MM-DD') AND to_date('2021-08-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-07-30', 'YYYY-MM-DD') AND to_date('2022-08-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-07-29', 'YYYY-MM-DD') AND to_date('2023-08-25', 'YYYY-MM-DD')
		    THEN 8
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-08-25', 'YYYY-MM-DD') AND to_date('2018-09-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-08-24', 'YYYY-MM-DD') AND to_date('2019-09-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-08-29', 'YYYY-MM-DD') AND to_date('2020-10-02', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-08-28', 'YYYY-MM-DD') AND to_date('2021-10-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-08-27', 'YYYY-MM-DD') AND to_date('2022-09-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-08-26', 'YYYY-MM-DD') AND to_date('2023-09-29', 'YYYY-MM-DD')
		    THEN 9
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-09-29', 'YYYY-MM-DD') AND to_date('2018-10-26', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-09-28', 'YYYY-MM-DD') AND to_date('2019-10-25', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-10-03', 'YYYY-MM-DD') AND to_date('2020-10-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-10-02', 'YYYY-MM-DD') AND to_date('2021-10-29', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-10-01', 'YYYY-MM-DD') AND to_date('2022-10-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-09-30', 'YYYY-MM-DD') AND to_date('2023-10-27', 'YYYY-MM-DD')
		    THEN 10
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-10-27', 'YYYY-MM-DD') AND to_date('2018-11-23', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-10-26', 'YYYY-MM-DD') AND to_date('2019-11-22', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2020-10-31', 'YYYY-MM-DD') AND to_date('2020-11-27', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2021-10-30', 'YYYY-MM-DD') AND to_date('2021-11-26', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2022-10-29', 'YYYY-MM-DD') AND to_date('2022-11-25', 'YYYY-MM-DD')    	
		    	OR date_in_series BETWEEN to_date('2023-10-28', 'YYYY-MM-DD') AND to_date('2023-11-24', 'YYYY-MM-DD')
		    THEN 11
		    WHEN 
		    	date_in_series BETWEEN to_date('2018-11-24', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2019-11-23', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2020-11-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2021-11-27', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2022-11-26', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD')
		    	OR date_in_series BETWEEN to_date('2023-11-25', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		    THEN 12
		  END AS fiscal_month,
		  CASE 
		    WHEN date_in_series BETWEEN to_date('2017-12-30', 'YYYY-MM-DD') AND to_date('2018-12-28', 'YYYY-MM-DD') THEN 2018
		    WHEN date_in_series BETWEEN to_date('2018-12-29', 'YYYY-MM-DD') AND to_date('2019-12-27', 'YYYY-MM-DD') THEN 2019
		    WHEN date_in_series BETWEEN to_date('2019-12-28', 'YYYY-MM-DD') AND to_date('2021-01-01', 'YYYY-MM-DD') THEN 2020
		    WHEN date_in_series BETWEEN to_date('2021-01-02', 'YYYY-MM-DD') AND to_date('2021-12-31', 'YYYY-MM-DD') THEN 2021
		    WHEN date_in_series BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2022-12-30', 'YYYY-MM-DD') THEN 2022
		    WHEN date_in_series BETWEEN to_date('2022-12-31', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD') THEN 2023
		  END AS fiscal_year
		FROM date_series
	), vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-02-26', 'YYYY-MM-DD') AND to_date('2023-12-29', 'YYYY-MM-DD')
		ORDER BY vca.departure
	), util_by_vessel AS (
		SELECT 
			msv.name AS Name
			, vc.vsl_id AS "ID"
			, vc.IN_VOY_NBR AS "In"
			, vc.OUT_VOY_NBR AS "Out"
			, vc.arrival
			, vc.departure
			, vc.berth
			, round(svc.loa/1000) AS LENGTH
			, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
			, round((
				CASE 
					WHEN svc.loa >= 250000 AND svc.loa < 360000 THEN 360000 + 50000
					WHEN svc.loa = 0 THEN 0
					ELSE svc.loa + 50000 
				END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
		FROM vessel_calls vc
		LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
		LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
		LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
	)
SELECT
	fc.fiscal_year AS YEAR
	, fc.fiscal_month AS MONTH
	, sum (ubv."Util m-days") AS "Util m-days"
FROM util_by_vessel ubv
JOIN fiscal_calendar fc ON trunc(ubv.departure) = fc.date_in_series
GROUP BY fc.fiscal_year, fc.fiscal_month
ORDER BY fc.fiscal_year, fc.fiscal_month
;

-- Now let's apply the above queries to MIT. They use calendar months. We won't need the fiscal calendar.
-- First the utilization by vessel for container vessel berths 1-4.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	)
SELECT
	msv.name AS Name
	, vc.vsl_id AS "ID"
	, vc.IN_VOY_NBR AS "In"
	, vc.OUT_VOY_NBR AS "Out"
	, vc.arrival
	, vc.departure
	, vc.berth
	, COALESCE (round(svc.loa/1000),0) AS LENGTH
	, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
	, round((
		CASE 
			WHEN (vc.berth = 1 OR vc.berth = 2 OR vc.berth = 3 OR vc.berth = 4) AND svc.loa >= 0.7*300000 AND svc.loa < 300000  THEN 300000
--			WHEN (vc.berth = 5 OR vc.berth = 8) 
--					AND svc.loa >= 0.7*400000 AND svc.loa < 400000 THEN 400000 + 50000
			WHEN svc.loa = 0 THEN 0
			ELSE svc.loa + 50000 
		END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
FROM vessel_calls vc
LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
WHERE vc.berth=1 OR vc.berth = 2 OR vc.berth = 3 OR vc.berth = 4 OR vc.berth IS NULL
ORDER BY vc.departure
;

-- First the utilization by vessel for container vessel berths 5.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	)
SELECT
	msv.name AS Name
	, vc.vsl_id AS "ID"
	, vc.IN_VOY_NBR AS "In"
	, vc.OUT_VOY_NBR AS "Out"
	, vc.arrival
	, vc.departure
	, vc.berth
	, COALESCE (round(svc.loa/1000),0) AS LENGTH
	, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
	, round((
		CASE 
			WHEN svc.loa > 0 THEN 400000
			WHEN svc.loa = 0 THEN 0
			ELSE svc.loa + 50000 
		END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
FROM vessel_calls vc
LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
WHERE vc.berth = 5
ORDER BY vc.departure
;

-- First the utilization by vessel for container vessel berths 8.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	)
SELECT
	msv.name AS Name
	, vc.vsl_id AS "ID"
	, vc.IN_VOY_NBR AS "In"
	, vc.OUT_VOY_NBR AS "Out"
	, vc.arrival
	, vc.departure
	, vc.berth
	, COALESCE (round(svc.loa/1000),0) AS LENGTH
	, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
	, round((
		CASE 
			WHEN svc.loa > 0 THEN 400000
			ELSE 0 
		END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
FROM vessel_calls vc
LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
WHERE vc.berth = 8
ORDER BY vc.departure
;

--Utilization by vessel for RORO berth 6
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	)
SELECT
	msv.name AS Name
	, vc.vsl_id AS "ID"
	, vc.IN_VOY_NBR AS "In"
	, vc.OUT_VOY_NBR AS "Out"
	, vc.arrival
	, vc.departure
	, vc.berth
	, COALESCE (round(svc.loa/1000),0) AS LENGTH
	, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
	, round(MOD ((vc.departure - vc.arrival),365),1) AS "Util berth-days"
FROM vessel_calls vc
LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
WHERE vc.berth = 6
ORDER BY vc.departure
;

--Utilization by vessel for RORO berth 7
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	)
SELECT
	msv.name AS Name
	, vc.vsl_id AS "ID"
	, vc.IN_VOY_NBR AS "In"
	, vc.OUT_VOY_NBR AS "Out"
	, vc.arrival
	, vc.departure
	, vc.berth
	, COALESCE (round(svc.loa/1000),0) AS LENGTH
	, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
	, round(MOD ((vc.departure - vc.arrival),365),1) AS "Util berth-days"
FROM vessel_calls vc
LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
WHERE vc.berth = 7
ORDER BY vc.departure
;

-- Find missing RORO call
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	)
SELECT
	msv.name AS Name
	, vc.vsl_id AS "ID"
	, vc.IN_VOY_NBR AS "In"
	, vc.OUT_VOY_NBR AS "Out"
	, vc.arrival
	, vc.departure
	, vc.berth
	, COALESCE (round(svc.loa/1000),0) AS LENGTH
	, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
	, round(MOD ((vc.departure - vc.arrival),365),1) AS "Util berth-days"
FROM vessel_calls vc
LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
WHERE NOT (vc.berth=1 OR vc.berth = 2 OR vc.berth = 3 OR vc.berth = 4 OR vc.berth IS NULL) 
	AND NOT vc.berth = 5
	AND NOT vc.berth = 8
	AND NOT vc.berth = 6
	AND NOT vc.berth = 7
ORDER BY vc.departure
;

-- Now the utilization by month for container vessel berths 1-4.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	), by_vessel AS (
		SELECT
			msv.name AS Name
			, vc.vsl_id AS "ID"
			, vc.IN_VOY_NBR AS "In"
			, vc.OUT_VOY_NBR AS "Out"
			, vc.arrival
			, vc.departure
			, vc.berth
			, COALESCE (round(svc.loa/1000),0) AS LENGTH
			, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
			, round((
				CASE 
					WHEN svc.loa >= 0.7*300000 AND svc.loa < 300000  THEN 300000
					WHEN svc.loa = 0 THEN 0
					ELSE svc.loa
				END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
		FROM vessel_calls vc
		LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
		LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
		LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
		WHERE vc.berth=1 OR vc.berth = 2 OR vc.berth = 3 OR vc.berth = 4 OR vc.berth IS NULL
	)
SELECT 
	EXTRACT (YEAR FROM bv.departure) AS year
	, EXTRACT (MONTH FROM bv.departure) AS MONTH
	, sum (bv."Util m-days")
FROM by_vessel bv
GROUP BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
ORDER BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
;

-- Now the utilization by month for container vessel berth 5.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	), by_vessel AS (
		SELECT
			msv.name AS Name
			, vc.vsl_id AS "ID"
			, vc.IN_VOY_NBR AS "In"
			, vc.OUT_VOY_NBR AS "Out"
			, vc.arrival
			, vc.departure
			, vc.berth
			, COALESCE (round(svc.loa/1000),0) AS LENGTH
			, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
			, round((
				CASE 
					WHEN svc.loa > 0 THEN 400000
					else 0
				END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
		FROM vessel_calls vc
		LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
		LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
		LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
		WHERE vc.berth = 5
	)
SELECT 
	EXTRACT (YEAR FROM bv.departure) AS year
	, EXTRACT (MONTH FROM bv.departure) AS MONTH
	, sum (bv."Util m-days")
FROM by_vessel bv
GROUP BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
ORDER BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
;

-- Now the utilization by month for container vessel berth 8.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	), by_vessel AS (
		SELECT
			msv.name AS Name
			, vc.vsl_id AS "ID"
			, vc.IN_VOY_NBR AS "In"
			, vc.OUT_VOY_NBR AS "Out"
			, vc.arrival
			, vc.departure
			, vc.berth
			, COALESCE (round(svc.loa/1000),0) AS LENGTH
			, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
			, round((
				CASE 
					WHEN svc.loa > 0 THEN 400000
					ELSE 0
				END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
		FROM vessel_calls vc
		LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
		LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
		LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
		WHERE vc.berth = 8
	)
SELECT 
	EXTRACT (YEAR FROM bv.departure) AS year
	, EXTRACT (MONTH FROM bv.departure) AS MONTH
	, sum (bv."Util m-days")
FROM by_vessel bv
GROUP BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
ORDER BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
;

-- Now the utilization by month for RORO berth 6.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	), by_vessel AS (
		SELECT
			msv.name AS Name
			, vc.vsl_id AS "ID"
			, vc.IN_VOY_NBR AS "In"
			, vc.OUT_VOY_NBR AS "Out"
			, vc.arrival
			, vc.departure
			, vc.berth
			, COALESCE (round(svc.loa/1000),0) AS LENGTH
			, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
			, round(MOD ((vc.departure - vc.arrival),365),1) AS "Util berth-days"
		FROM vessel_calls vc
		LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
		LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
		LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
		WHERE vc.berth = 6
	)
SELECT 
	EXTRACT (YEAR FROM bv.departure) AS year
	, EXTRACT (MONTH FROM bv.departure) AS MONTH
	, sum (bv."Util berth-days")
FROM by_vessel bv
GROUP BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
ORDER BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
;

-- Now the utilization by month for RORO berth 7.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	), by_vessel AS (
		SELECT
			msv.name AS Name
			, vc.vsl_id AS "ID"
			, vc.IN_VOY_NBR AS "In"
			, vc.OUT_VOY_NBR AS "Out"
			, vc.arrival
			, vc.departure
			, vc.berth
			, COALESCE (round(svc.loa/1000),0) AS LENGTH
			, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
			, round(MOD ((vc.departure - vc.arrival),365),1) AS "Util berth-days"
		FROM vessel_calls vc
		LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
		LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
		LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
		WHERE vc.berth = 7
	)
SELECT 
	EXTRACT (YEAR FROM bv.departure) AS year
	, EXTRACT (MONTH FROM bv.departure) AS MONTH
	, sum (bv."Util berth-days")
FROM by_vessel bv
GROUP BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
ORDER BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
;

-- Now let's apply the above queries to ZLO. They use calendar months. We won't need the fiscal calendar.
-- First the utilization by vessel.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	)
SELECT
	msv.name AS Name
	, vc.vsl_id AS "ID"
	, vc.IN_VOY_NBR AS "In"
	, vc.OUT_VOY_NBR AS "Out"
	, vc.arrival
	, vc.departure
	, vc.berth
	, COALESCE (round(svc.loa/1000),0) AS LENGTH
	, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
	, round((
		CASE 
			WHEN svc.loa = 0 THEN 0
			ELSE svc.loa
		END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
FROM vessel_calls vc
LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
ORDER BY vc.departure
;

-- Now the utilization by month.
WITH 
	vessel_calls_almost AS (
		SELECT
			v.name
			, vv.vsl_id
			, vv.in_voy_nbr
			, vv.out_voy_nbr
			, vv.berth AS berth
			, COALESCE (vv.ata, min(eh.posted)) AS Arrival
			, COALESCE (vv.atd, max(eh.posted)) AS Departure
		FROM EQUIPMENT_HISTORY eh 
		JOIN VESSEL_VISITS vv ON eh.VSL_ID = vv.VSL_ID AND (eh.VOY_NBR = vv.IN_VOY_NBR OR eh.VOY_NBR = vv.OUT_VOY_NBR)
		JOIN VESSELS v ON vv.VSL_ID = v.ID 
		WHERE 
			trunc(eh.posted) BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
			AND eh.vsl_id IS NOT NULL
			AND (eh.wtask_id = 'LOAD' OR eh.wtask_id = 'UNLOAD')
		GROUP BY v.name, vv.vsl_id, vv.in_voy_nbr, vv.out_voy_nbr, vv.berth, vv.ata, vv.atd
	), vessel_calls AS (
		SELECT *
		FROM vessel_calls_almost vca
		WHERE vca.departure BETWEEN to_date('2022-01-01', 'YYYY-MM-DD') AND to_date('2023-12-31', 'YYYY-MM-DD')
		ORDER BY vca.departure
		FETCH FIRST 10000 ROWS ONLY --Needed to overcome cast defect 
	), by_vessel AS (
		SELECT
			msv.name AS Name
			, vc.vsl_id AS "ID"
			, vc.IN_VOY_NBR AS "In"
			, vc.OUT_VOY_NBR AS "Out"
			, vc.arrival
			, vc.departure
			, vc.berth
			, COALESCE (round(svc.loa/1000),0) AS LENGTH
			, round(MOD ((vc.departure - vc.arrival),365),1) AS duration
			, round((
				CASE 
					WHEN svc.loa = 0 THEN 0
					ELSE svc.loa
				END)/1000 * MOD ((vc.departure - vc.arrival),365)) AS "Util m-days"
		FROM vessel_calls vc
		LEFT JOIN mtms.vessels msv ON msv.id = vc.vsl_id
		LEFT JOIN spinnaker.vessel spv ON spv.code = vc.vsl_id
		LEFT JOIN spinnaker.vc_class svc ON svc.id = spv.CLASS_ID 
		ORDER BY vc.departure
	)
SELECT 
	EXTRACT (YEAR FROM bv.departure)
	, EXTRACT (MONTH FROM bv.departure)
	, sum (bv."Util m-days")
FROM by_vessel bv
GROUP BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
ORDER BY EXTRACT (YEAR FROM bv.departure), EXTRACT (MONTH FROM bv.departure)
;
