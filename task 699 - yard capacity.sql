--Current yard capacity build
SELECT
	*
FROM td_block
ORDER BY name
;

WITH 
	pos_joins AS (
		SELECT 
			eq.NBR 
			, eq.SZTP_ID 
			, eq.LOC_TYPE 
			, eq.LOC_ID 
			, eq.POS_ID 
			, b.name AS block_name
			, r.NAME AS row_name
			, r.name40 AS row40_name
		FROM mtms.equipment eq
		LEFT JOIN spinnaker.td_block b ON eq.pos_id = b.name
		LEFT JOIN spinnaker.td_row r ON 
			eq.pos_id = r.name 
			OR eq.pos_id = r.NAME40 
			OR SUBSTR(eq.pos_id,1,4) = r.name
			OR SUBSTR(eq.pos_id,1,4) = r.name40
		WHERE 
			eq.sztp_class = 'CTR'
			AND eq.loc_type = 'Y'
	), 
SELECT 
	*
FROM pos_joins 
;

SELECT
	*
FROM spinnaker.td_row r
WHERE 
	NOT (r.name = r.NAME40)
;

SELECT 
	crc.rv_domain
	, count(*)
FROM CG_REF_CODES crc
GROUP BY 
	crc.rv_domain
;

SELECT 
	*
FROM TD_STACK_NAME tsn
WHERE 
	