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

--List of blocks, rectangular parallelepiped components for computing TEU capacity
WITH 
	blocks_rows AS (
		SELECT 
			b.ID 
			, b.NAME 
			, count(r.name) AS num_rows
			, r.NUM_TIERS 
		FROM TD_BLOCK b
		LEFT JOIN td_row r ON b.id = r.BLOCK_ID 
		WHERE 
			b.TYPE = 0 
			OR b.TYPE = 6
		GROUP BY 
			b.id 
			, b.name 
			, r.NUM_TIERS 
		ORDER BY 
			b.NAME 
	), brst AS (
		SELECT 	
			br.id
			, br.name
			, br.num_rows
			, br.num_tiers
			, count(tsn.CUSTOM_NAME) AS num_stacks
		FROM blocks_rows br
		LEFT JOIN td_stack_name tsn ON br.id = tsn.BLOCK_ID 
		GROUP BY 
			br.id
			, br.name
			, br.num_rows
			, br.num_tiers
		ORDER BY 
			br.name
	), all_TEU AS (
		SELECT 
			brst.*
			, num_rows * num_tiers * num_stacks AS TEU
		FROM brst
--		ORDER BY brst.name
	), disabled_rpv_components AS (
		SELECT 
			ys.ID 
			, ys.BLOCK_ID 
			, b.name AS block_name
			, ys.START_ROW_ID
			, r1.name AS start_row_name
			, r1.row_index AS start_row_index
			, ys.STOP_ROW_ID 
			, r2.NAME AS stop_row_name
			, r2.ROW_INDEX AS stop_row_index
			, ys.START_STACK 
			, ys.STOP_STACK 
			, ys.NUM_TIERS 
			, r2.row_index - r1.row_index + 1 AS num_rows
			, ys.stop_stack - ys.start_stack + 1 AS num_stacks
			, ys."TYPE" 
		FROM td_block b  
		LEFT JOIN YPDISABLED_SPACE ys ON ys.BLOCK_ID = b.ID
		LEFT JOIN td_row r1 ON r1.id = ys.START_ROW_ID 
		LEFT JOIN td_row r2 ON r2.id = ys.STOP_ROW_ID 
		WHERE 
			b.TYPE = 0 
			OR b.TYPE = 6
		ORDER BY 
			b.name
			, ys.id
	), disabled_TEU AS (
		SELECT 
			block_id
			, block_name
			, sum(num_tiers * num_rows * num_stacks) AS disabled_TEU
		FROM disabled_rpv_components 
		GROUP BY 
			block_id
			, block_name
		ORDER BY 
			block_name
	)
SELECT 
	a.id AS block_id
	, a.name AS block_name
	, a.TEU AS all_TEU
	, COALESCE (d.disabled_TEU,0) AS disabled_teu
	, a.TEU - coalesce (d.disabled_TEU,0) AS able_TEU
FROM all_TEU a
LEFT JOIN disabled_TEU d ON a.id = d.block_id
ORDER BY a.name
;

--Tallying the disabled spaces
WITH 
	disabled_rpv_components AS (
		SELECT 
			ys.ID 
			, ys.BLOCK_ID 
			, b.name AS block_name
			, ys.START_ROW_ID
			, r1.name AS start_row_name
			, r1.row_index AS start_row_index
			, ys.STOP_ROW_ID 
			, r2.NAME AS stop_row_name
			, r2.ROW_INDEX AS stop_row_index
			, ys.START_STACK 
			, ys.STOP_STACK 
			, ys.NUM_TIERS 
			, r2.row_index - r1.row_index + 1 AS num_rows
			, ys.stop_stack - ys.start_stack + 1 AS num_stacks
		FROM YPDISABLED_SPACE ys 
		LEFT JOIN td_block b ON ys.BLOCK_ID = b.ID 
		LEFT JOIN td_row r1 ON r1.id = ys.START_ROW_ID 
		LEFT JOIN td_row r2 ON r2.id = ys.STOP_ROW_ID 
		ORDER BY 
			ys.block_id
	)
SELECT 
	block_id
	, block_name
	, sum(num_tiers * num_rows * num_stacks) AS disabled_rpv_TEUs
FROM disabled_rpv_components 
GROUP BY 
	block_id
	, block_name
ORDER BY 
	block_name
;

SELECT 
	*
FROM YPDISABLED_SPACE ys 
WHERE ys.BLOCK_ID = '477280074'
;	

--Disabled spaces can be disabled multiple times. I need to create a table with a 
--grain that is a fine spot and if the spot occurs in any disabled range then 
--mark it as disabled and tally the able spaces.
