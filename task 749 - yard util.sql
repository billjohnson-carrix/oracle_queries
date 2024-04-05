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