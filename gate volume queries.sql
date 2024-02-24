-- Starting off looking at MIT
-- List of gate transactions and selected attributes for a time period
SELECT 
	gt.WTASK_ID 
	, count(*)
FROM 
	GATE_TRANSACTIONS gt 
WHERE 
	gt.created BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-02-01','YYYY-MM-DD')
	--OR gt.OUTGATED  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
GROUP BY gt.WTASK_ID 
ORDER BY gt.WTASK_ID 
;

-- Let's try dynamic SQL with the help of Copilot.
DECLARE
	maingate_tasks varchar2(100) := '1FULLOUT,DRAYIN,DRAYOFF,FULLIN,FULLOUT,MTIN,MTINB,MTOUT,MTOUTB';
	railgate_tasks varchar2(100) := 'RDRAYIN,RFULLIN,RFULLOUT,RMTIN,RMTOUT';
	maingate_volume NUMBER;
	railgate_volume NUMBER;
BEGIN
	SELECT 
		count(*)
	INTO
		maingate_volume
	FROM
		GATE_TRANSACTIONS gt 
	WHERE 
		trunc(gt.created) BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
		--OR gt.OUTGATED  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
		AND gt.ctr_nbr IS NOT NULL
		AND gt.tran_status = 'EIR'
		AND gt.WTASK_ID IN (SELECT TRIM(REGEXP_SUBSTR(maingate_tasks, '[^,]+', 1, LEVEL))
                         	FROM dual
                         	CONNECT BY LEVEL <= REGEXP_COUNT(maingate_tasks, ',') + 1);
	SELECT 
		count(*)
	INTO
		railgate_volume
	FROM
		GATE_TRANSACTIONS gt 
	WHERE 
		trunc(gt.created) BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
		--OR gt.OUTGATED  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
		AND gt.ctr_nbr IS NOT NULL
		AND gt.tran_status = 'EIR'
		AND gt.WTASK_ID IN (SELECT TRIM(REGEXP_SUBSTR(railgate_tasks, '[^,]+', 1, LEVEL))
                         	FROM dual
                         	CONNECT BY LEVEL <= REGEXP_COUNT(railgate_tasks, ',') + 1);
    DBMS_OUTPUT.PUT_LINE('Maingate volume: ' || maingate_volume);
	DBMS_OUTPUT.PUT_LINE('Railgate volume: ' || railgate_volume);
END;

--Let's just use a normal style, although the dynamic SQL seemed pretty quick
--Maingate volume
SELECT 
	EXTRACT (YEAR FROM gt.created)
	, EXTRACT (MONTH FROM gt.created)
	, count(*)
FROM
	GATE_TRANSACTIONS gt 
WHERE 
	(EXTRACT (YEAR FROM gt.created) = 2023 OR EXTRACT (YEAR FROM gt.created) = 2022)
	--trunc(gt.created)  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = '1FULLOUT' OR gt.WTASK_ID = 'DRAYIN' OR gt.WTASK_ID = 'DRAYOFF' OR gt.WTASK_ID = 'FULLIN'  OR gt.WTASK_ID = 'FULLOUT'
		 OR gt.WTASK_ID = 'MTIN' OR gt.WTASK_ID = 'MTINB' OR gt.WTASK_ID = 'MTOUT' OR gt.WTASK_ID = 'MTOUTB')
GROUP BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
;
--Railgate volume
SELECT 
	EXTRACT (YEAR FROM gt.created)
	, EXTRACT (MONTH FROM gt.created)
	, count(*)
FROM
	GATE_TRANSACTIONS gt 
WHERE 
	(EXTRACT (YEAR FROM gt.created) = 2023 OR EXTRACT (YEAR FROM gt.created) = 2022)
	--trunc(gt.created)  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = 'RDRAYIN' OR gt.WTASK_ID = 'RFULLIN' OR gt.WTASK_ID = 'RFULLOUT' OR gt.WTASK_ID = 'RMTIN'  OR gt.WTASK_ID = 'RMTOUT')
GROUP BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
;
--We're systematically overcounting. Let's drop the dray tasks. Kevin tells me that those aren't throughput.
--Maingate volume
SELECT 
	EXTRACT (YEAR FROM gt.created)
	, EXTRACT (MONTH FROM gt.created)
	, count(*)
FROM
	GATE_TRANSACTIONS gt 
WHERE 
	(EXTRACT (YEAR FROM gt.created) = 2023 OR EXTRACT (YEAR FROM gt.created) = 2022)
	--trunc(gt.created)  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = '1FULLOUT' OR gt.WTASK_ID = 'FULLIN'  OR gt.WTASK_ID = 'FULLOUT'
		 OR gt.WTASK_ID = 'MTIN' OR gt.WTASK_ID = 'MTINB' OR gt.WTASK_ID = 'MTOUT' OR gt.WTASK_ID = 'MTOUTB')
GROUP BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
;

--Railgate volume
SELECT 
	EXTRACT (YEAR FROM gt.created)
	, EXTRACT (MONTH FROM gt.created)
	, count(*)
FROM
	GATE_TRANSACTIONS gt 
WHERE 
	(EXTRACT (YEAR FROM gt.created) = 2023 OR EXTRACT (YEAR FROM gt.created) = 2022)
	--trunc(gt.created)  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = 'RFULLIN' OR gt.WTASK_ID = 'RFULLOUT' OR gt.WTASK_ID = 'RMTIN'  OR gt.WTASK_ID = 'RMTOUT')
GROUP BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
;

--Strangeness on date selection
--It was because I wasn't truncated gt.created.
WITH 
	result_set_1 AS 
		(SELECT 
			gt.created
		FROM
			GATE_TRANSACTIONS gt 
		WHERE 
			--EXTRACT (YEAR FROM gt.created) = 2023 AND EXTRACT (MONTH FROM gt.created) = 1
			gt.created  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-02-01','YYYY-MM-DD')
			AND gt.ctr_nbr IS NOT NULL
			AND gt.tran_status = 'EIR'
			AND (gt.WTASK_ID = '1FULLOUT' OR gt.WTASK_ID = 'DRAYIN' OR gt.WTASK_ID = 'DRAYOFF' OR gt.WTASK_ID = 'FULLIN'  OR gt.WTASK_ID = 'FULLOUT'
				 OR gt.WTASK_ID = 'MTIN' OR gt.WTASK_ID = 'MTINB' OR gt.WTASK_ID = 'MTOUT' OR gt.WTASK_ID = 'MTOUTB')),
	result_set_2 AS 
		(SELECT 
			gt.created
		FROM
			GATE_TRANSACTIONS gt 
		WHERE 
			EXTRACT (YEAR FROM gt.created) = 2023 AND EXTRACT (MONTH FROM gt.created) = 1
			--gt.created  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
			AND gt.ctr_nbr IS NOT NULL
			AND gt.tran_status = 'EIR'
			AND (gt.WTASK_ID = '1FULLOUT' OR gt.WTASK_ID = 'DRAYIN' OR gt.WTASK_ID = 'DRAYOFF' OR gt.WTASK_ID = 'FULLIN'  OR gt.WTASK_ID = 'FULLOUT'
				 OR gt.WTASK_ID = 'MTIN' OR gt.WTASK_ID = 'MTINB' OR gt.WTASK_ID = 'MTOUT' OR gt.WTASK_ID = 'MTOUTB'))
SELECT 
	result_set_1.created
	, result_set_2.created
FROM
	result_set_1
FULL OUTER JOIN result_set_2 ON result_set_1.created = result_set_2.created
WHERE
	result_set_1.created IS NULL OR result_set_2.created IS NULL 
;

SELECT 
	gt.created
FROM
	GATE_TRANSACTIONS gt 
WHERE 
	--EXTRACT (YEAR FROM gt.created) = 2023 AND EXTRACT (MONTH FROM gt.created) = 1
	gt.created  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = '1FULLOUT' OR gt.WTASK_ID = 'DRAYIN' OR gt.WTASK_ID = 'DRAYOFF' OR gt.WTASK_ID = 'FULLIN'  OR gt.WTASK_ID = 'FULLOUT'
		 OR gt.WTASK_ID = 'MTIN' OR gt.WTASK_ID = 'MTINB' OR gt.WTASK_ID = 'MTOUT' OR gt.WTASK_ID = 'MTOUTB')
ORDER BY EXTRACT (DAY FROM gt.created) DESC 
;
	
--Railgate volume
SELECT 
	EXTRACT (MONTH FROM gt.created)
	, count(*)
FROM
	GATE_TRANSACTIONS gt 
WHERE 
	EXTRACT (YEAR FROM gt.created) = 2023
	--OR gt.OUTGATED  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = 'RDRAYIN' OR gt.WTASK_ID = 'RFULLIN' OR gt.WTASK_ID = 'RFULLOUT' OR gt.WTASK_ID = 'RMTIN'  OR gt.WTASK_ID = 'RMTOUT')
GROUP BY EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (MONTH FROM gt.created)
;

-- Looking at joining the gate_transactions and truck_visits tables
SELECT * FROM terminal_events ORDER BY Id;

-- List of gate transactions and selected attributes for a time period
SELECT 
	gt.WTASK_ID
	, gt.CATEGORY
	, gt.STATUS 
	, gt.DIRECTION 
	, gt.CARRIER_ID 
	, gt.VCL_ID 
	, gt.VCL_VISIT_ID 
	, gt.TV_GKEY 
	, gt.CTR_NBR 
	, gt.CTR_LINE_ID 
	, gt.CTR_SZTP_ID 
	, gt.CTR_TARE_WEIGHT 
	, gt.CTR_GROSS_WEIGHT 
	, gt.CHS_NBR 
	, gt.CHS_LINE_ID 
	, gt.CHS_SZTP_ID 
	--, gt.HAZARDOUS 
	--, gt.HAZ_IMDG_CLASS 
	--, gt.DRIVER_ID 
	--, gt.DRV_LIC_NBR 
	--, gt.DRIVER_NAME 
FROM 
	GATE_TRANSACTIONS gt 
WHERE 
	gt.DECKED BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	OR  gt.OUTGATED  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
;

--Gate volume in move counts
SELECT 
	count(*) AS moves
FROM 
	GATE_TRANSACTIONS gt 
WHERE 
	gt.DECKED BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	OR  gt.OUTGATED  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
;

-- Move counts per something like a truck visit
SELECT 
	gt.TV_GKEY 
	, gt.VCL_ID 
	, gt.VCL_VISIT_ID 
	, count(*)
FROM 
	GATE_TRANSACTIONS gt 
WHERE 
	(gt.DECKED BETWEEN to_date('2022-02-01', 'YYYY-MM-DD') AND to_date('2022-02-28','YYYY-MM-DD')
	OR  gt.OUTGATED  BETWEEN to_date('2022-02-01', 'YYYY-MM-DD') AND to_date('2022-02-28','YYYY-MM-DD'))
	AND tv_gkey IS NOT null
GROUP BY gt.tv_gkey, gt.vcl_id, gt.vcl_visit_id
order BY 4 desc, gt.vcl_id
;

-- vcl_id and vcl_visit_id combinations per tv_gkey
WITH g as
	(SELECT 
		gt.tv_gkey AS gkey
	FROM
		GATE_TRANSACTIONS gt 
	WHERE 
		(gt.DECKED BETWEEN to_date('2022-02-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
		OR  gt.OUTGATED  BETWEEN to_date('2022-02-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD'))
		AND gt.tv_gkey IS NOT NULL)
	, gg as
		(SELECT 
			gt.tv_gkey
			, gt.vcl_id
			, gt.VCL_VISIT_ID 
		FROM
			GATE_TRANSACTIONS gt 
		JOIN g ON gt.tv_gkey = g.gkey
		WHERE 
			(gt.DECKED BETWEEN to_date('2022-02-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
			OR  gt.OUTGATED  BETWEEN to_date('2022-02-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD'))
			AND gt.tv_gkey IS NOT NULL)
SELECT 
	gg.tv_gkey
	, count(*)
FROM
	gg
GROUP BY gg.tv_gkey
ORDER BY 2 DESC 
;

--Looking at some gkeys that get repeated a lot
SELECT * FROM GATE_TRANSACTIONS gt WHERE gt.TV_GKEY = 11354515; -- vcl_id = ADJ123WA. This IS SOME sort OF adjustment.
SELECT * FROM GATE_TRANSACTIONS gt WHERE gt.TV_GKEY = 11354480; -- same here
SELECT * FROM GATE_TRANSACTIONS gt WHERE gt.TV_GKEY = 11276720; -- same here
-- There are a lot thousands of adjustment transactions. They might not matter. I don't need to be trying to join gate transactions to truck visits now anyway
-- I'm moving on to just looking at gate volume at the granularity of the container.

-- Looking at ZLO UAT now
--Let's just use a normal style, although the dynamic SQL seemed pretty quick
--Maingate volume
SELECT 
	EXTRACT (YEAR FROM gt.created)
	, EXTRACT (MONTH FROM gt.created)
	, count(*)
FROM
	GATE_TRANSACTIONS gt 
WHERE 
	(EXTRACT (YEAR FROM gt.created) = 2023 OR EXTRACT (YEAR FROM gt.created) = 2022)
	--trunc(gt.created)  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = '1FULLOUT' OR gt.WTASK_ID = 'DRAYIN' OR gt.WTASK_ID = 'DRAYOFF' OR gt.WTASK_ID = 'FULLIN'  OR gt.WTASK_ID = 'FULLOUT'
		 OR gt.WTASK_ID = 'MTIN' OR gt.WTASK_ID = 'MTINB' OR gt.WTASK_ID = 'MTOUT' OR gt.WTASK_ID = 'MTOUTB')
GROUP BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
;
--We're systematically overcounting. Let's drop the dray tasks. Kevin tells me that those aren't throughput.
--Maingate volume
SELECT 
	EXTRACT (YEAR FROM gt.created)
	, EXTRACT (MONTH FROM gt.created)
	, count(*)
FROM
	GATE_TRANSACTIONS gt 
WHERE 
	(EXTRACT (YEAR FROM gt.created) = 2023 OR EXTRACT (YEAR FROM gt.created) = 2022)
	--trunc(gt.created)  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = '1FULLOUT' OR gt.WTASK_ID = 'FULLIN'  OR gt.WTASK_ID = 'FULLOUT'
		 OR gt.WTASK_ID = 'MTIN' OR gt.WTASK_ID = 'MTINB' OR gt.WTASK_ID = 'MTOUT' OR gt.WTASK_ID = 'MTOUTB')
GROUP BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
;
-- Now to add TEU computation and truck turns
WITH sztp_to_len AS
	(SELECT 
		sztp_id, len
	FROM 
		(SELECT 
			t2.sztp_id
			, t2.len
			, t2.cnt
			, ROW_NUMBER() OVER	(PARTITION BY t2.sztp_id ORDER BY t2.cnt DESC) AS rn
		FROM 
			(SELECT t1.*, et.name, est.name
			FROM (
			    SELECT
			    	to_number(eq.sztp_eqsz_id) AS len
			    	, eq.sztp_class
			    	, eq.sztp_id
			    	, eq.sztp_eqtp_id
			    	, count(*) AS cnt
			    FROM equipment eq
			    WHERE eq.sztp_class = 'CTR' AND REGEXP_LIKE(eq.SZTP_EQSZ_ID, '^[0-9]+$')
			    GROUP BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			    --ORDER BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			) t1 
		JOIN equipment_types et ON t1.sztp_eqtp_id = et.id
		JOIN EQUIPMENT_SIZE_TYPES est ON t1.sztp_id = est.id
		WHERE NOT t1.sztp_eqtp_id = 'RT' AND NOT t1.sztp_eqtp_id = 'PP'
		--ORDER BY t1.sztp_id
		) t2 )
	WHERE rn = 1)
SELECT 
	EXTRACT (YEAR FROM gt.created)
	, EXTRACT (MONTH FROM gt.created)
	, count(*) AS moves
	, sum(sztp_to_len.len)/20 AS TEUs
	, count(DISTINCT gt.tv_gkey) AS TruckTurns
FROM
	GATE_TRANSACTIONS gt 
JOIN sztp_to_len ON sztp_to_len.sztp_id = gt.ctr_sztp_id
WHERE 
	(EXTRACT (YEAR FROM gt.created) = 2023 OR EXTRACT (YEAR FROM gt.created) = 2022)
	--trunc(gt.created)  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = '1FULLOUT' OR gt.WTASK_ID = 'FULLIN'  OR gt.WTASK_ID = 'FULLOUT'
		 OR gt.WTASK_ID = 'MTIN' OR gt.WTASK_ID = 'MTINB' OR gt.WTASK_ID = 'MTOUT' OR gt.WTASK_ID = 'MTOUTB')
GROUP BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
;

--Finally adding TEUs and truck turns to the MIT query
--First the maingate
WITH sztp_to_len AS
	(SELECT 
		sztp_id, len
	FROM 
		(SELECT 
			t2.sztp_id
			, t2.len
			, t2.cnt
			, ROW_NUMBER() OVER	(PARTITION BY t2.sztp_id ORDER BY t2.cnt DESC) AS rn
		FROM 
			(SELECT t1.*, et.name, est.name
			FROM (
			    SELECT
			    	to_number(eq.sztp_eqsz_id) AS len
			    	, eq.sztp_class
			    	, eq.sztp_id
			    	, eq.sztp_eqtp_id
			    	, count(*) AS cnt
			    FROM equipment eq
			    WHERE eq.sztp_class = 'CTR' AND REGEXP_LIKE(eq.SZTP_EQSZ_ID, '^[0-9]+$')
			    GROUP BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			    --ORDER BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			) t1 
		JOIN equipment_types et ON t1.sztp_eqtp_id = et.id
		JOIN EQUIPMENT_SIZE_TYPES est ON t1.sztp_id = est.id
		WHERE NOT t1.sztp_eqtp_id = 'RT' AND NOT t1.sztp_eqtp_id = 'PP'
		--ORDER BY t1.sztp_id
		) t2 )
	WHERE rn = 1)
SELECT 
	EXTRACT (YEAR FROM gt.created)
	, EXTRACT (MONTH FROM gt.created)
	, count(*) AS Moves
	, sum(sztp_to_len.len)/20 AS TEUs
	, count(DISTINCT gt.tv_gkey) AS TruckTurns
FROM
	GATE_TRANSACTIONS gt 
JOIN sztp_to_len ON sztp_to_len.sztp_id = gt.ctr_sztp_id
WHERE 
	(EXTRACT (YEAR FROM gt.created) = 2023 OR EXTRACT (YEAR FROM gt.created) = 2022)
	--trunc(gt.created)  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = '1FULLOUT' OR gt.WTASK_ID = 'FULLIN'  OR gt.WTASK_ID = 'FULLOUT'
		 OR gt.WTASK_ID = 'MTIN' OR gt.WTASK_ID = 'MTINB' OR gt.WTASK_ID = 'MTOUT' OR gt.WTASK_ID = 'MTOUTB')
GROUP BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
;

-- Now the railgate
WITH sztp_to_len AS
	(SELECT 
		sztp_id, len
	FROM 
		(SELECT 
			t2.sztp_id
			, t2.len
			, t2.cnt
			, ROW_NUMBER() OVER	(PARTITION BY t2.sztp_id ORDER BY t2.cnt DESC) AS rn
		FROM 
			(SELECT t1.*, et.name, est.name
			FROM (
			    SELECT
			    	to_number(eq.sztp_eqsz_id) AS len
			    	, eq.sztp_class
			    	, eq.sztp_id
			    	, eq.sztp_eqtp_id
			    	, count(*) AS cnt
			    FROM equipment eq
			    WHERE eq.sztp_class = 'CTR' AND REGEXP_LIKE(eq.SZTP_EQSZ_ID, '^[0-9]+$')
			    GROUP BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			    --ORDER BY to_number(eq.sztp_eqsz_id), eq.sztp_class, eq.sztp_id, eq.sztp_eqtp_id
			) t1 
		JOIN equipment_types et ON t1.sztp_eqtp_id = et.id
		JOIN EQUIPMENT_SIZE_TYPES est ON t1.sztp_id = est.id
		WHERE NOT t1.sztp_eqtp_id = 'RT' AND NOT t1.sztp_eqtp_id = 'PP'
		--ORDER BY t1.sztp_id
		) t2 )
	WHERE rn = 1)
SELECT 
	EXTRACT (YEAR FROM gt.created)
	, EXTRACT (MONTH FROM gt.created)
	, count(*) AS Moves
	, sum(sztp_to_len.len)/20 AS TEUs
	, count(DISTINCT gt.tv_gkey) AS TruckTurns
FROM
	GATE_TRANSACTIONS gt 
JOIN sztp_to_len ON sztp_to_len.sztp_id = gt.ctr_sztp_id
WHERE 
	(EXTRACT (YEAR FROM gt.created) = 2023 OR EXTRACT (YEAR FROM gt.created) = 2022)
	--trunc(gt.created)  BETWEEN to_date('2023-01-01', 'YYYY-MM-DD') AND to_date('2023-01-31','YYYY-MM-DD')
	AND gt.ctr_nbr IS NOT NULL
	AND gt.tran_status = 'EIR'
	AND (gt.WTASK_ID = 'RDRAYIN' OR gt.WTASK_ID = 'RFULLIN' OR gt.WTASK_ID = 'RFULLOUT' OR gt.WTASK_ID = 'RMTIN'  OR gt.WTASK_ID = 'RMTOUT')
GROUP BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
ORDER BY EXTRACT (YEAR FROM gt.created), EXTRACT (MONTH FROM gt.created)
;