--Initial look-see scratch
WITH 
	inorout AS (
		SELECT 
		    CASE 
		        WHEN equ.IN_YARD_DATE IS NULL AND equ.OUT_YARD_DATE IS NULL THEN 'BothNull'
		        WHEN equ.in_Yard_date IS NOT NULL AND equ.OUT_yard_date IS NULL THEN 'Yard'
		        WHEN equ.IN_yard_date IS NULL AND equ.out_yard_date IS NOT NULL THEN 'OutButNeverIn?'
		        WHEN equ.in_yard_date IS NOT NULL AND equ.out_yard_date IS NOT NULL AND
		            equ.OUT_yard_date - equ.in_yard_date > 0 THEN 'Valid'
		        WHEN equ.in_yard_date IS NOT NULL AND equ.out_yard_date IS NOT NULL AND 
		            NOT (equ.out_yard_date - equ.in_yard_date > 0) THEN 'Invalid'
		        ELSE 'MissedSomeCases'
		    END AS inorout
		    , equ.*
		FROM equipment_uses equ
	)
SELECT
	ioo.inorout
	, count(*)
FROM inorout ioo
GROUP BY 
	ioo.inorout
;

SELECT count(*) FROM equipment eq WHERE eq.loc_type = 'Y';
SELECT count(*) FROM equipment_history eh WHERE eh.loc_type = 'Y';

SELECT 
    eh.loc_type,
    MAX(CASE WHEN rn = 1 THEN third_fiel END) AS last_row_third_field_value
FROM (
    SELECT 
        group_field,
        third_field,
        ROW_NUMBER() OVER (PARTITION BY group_field ORDER BY sort_field DESC) AS rn
    FROM your_table
) subquery
WHERE rn = 1
GROUP BY group_field;

SELECT * FROM cg_ref_codes;

--Alpha metrics query 23475
WITH
	containers_in_inventory AS (
		SELECT
			eq.nbr 
			, eq.OWNER_ID 
			, eq.sztp_id
			, eq.SZTP_EQSZ_ID 
			, eq.SZTP_EQTP_ID 
			, eq.damage
			, eq.LOC_TYPE 
			, eq.POS_ID 
			, equ.category
			, equ.status
			, equ.destination
			, equ.load_port_id
			, equ.gross_weight
			, equ.required_temp
			, equ.customs_status
			, equ.line_release_status
			, equ.in_yard_date
			, equ.out_yard_date
			, equ.transship
			, equ.placard
			, equ.vgm_weight
		FROM equipment eq 
		JOIN equipment_uses equ ON equ.gkey = eq.equse_gkey
		WHERE 
			eq.loc_type = 'Y' AND 
			eq.sztp_class = 'CTR'
	)
SELECT 
	count(*) AS containers_count
FROM containers_in_inventory
;

--With the above results as the goal, find an alternative source

--First attempt uses in_yard_date and out_yard_date from equipment_uses
--and insists that there is an entry in the equipment table for the container
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

--Switching to ZLO UAT 2
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

--The last months for ZLO are really high, seems like.
--But the standard quey gives 24140 so I don't know.
SELECT 
	count(*)
FROM equipment eq
WHERE 
	eq.loc_type = 'Y'
;

--Quick look at ZLO Prod
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

SELECT 
	count(*)
FROM equipment eq
WHERE 
	eq.loc_type = 'Y'
;

--Swtiching to PCT
WITH 
	DateSeries (MonthStart) AS (
		SELECT 
			TRUNC(TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'MONTH') AS MonthStart
		FROM 
			dual
		UNION ALL
		SELECT 
			ADD_MONTHS(MonthStart, 1)
		FROM 
			DateSeries
		WHERE 
			ADD_MONTHS(MonthStart, 1) <= TRUNC(SYSDATE, 'MONTH')
	), dates_of_interest AS (
		SELECT 
			MonthStart
		FROM 
			DateSeries	
	)
SELECT 
	doi.monthstart
	, count(*)
FROM dates_of_interest doi
JOIN equipment_uses equ ON 
	(	equ.out_yard_date IS NULL OR 
		equ.out_yard_date > monthstart	)
	AND equ.in_yard_date IS NOT NULL
	AND equ.in_yard_date < monthstart
LEFT JOIN equipment eq ON equ.gkey = eq.equse_gkey
WHERE 
	eq.equse_gkey IS NOT NULL 
GROUP BY monthstart
ORDER BY monthstart
;

SELECT 
	count(*)
FROM equipment eq
WHERE 
	eq.loc_type = 'Y'
;