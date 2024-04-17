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
SELECT 
	ds.BLOCK_ID 
	, ds.START_ROW_ID 
	, ds.STOP_ROW_ID 
	, r.NAME 
	, ds.START_STACK 
	, ds.STOP_STACK 
	, ds.NUM_TIERS 
	, ds.type
FROM ypdisabled_space ds
JOIN td_row r ON r.id = ds.START_ROW_ID 
WHERE 
	ds.BLOCK_ID = '107588315'
ORDER BY 
	ds.START_ROW_ID 
	, ds.NUM_TIERS 
;

SELECT 
	count(*)
FROM YPSPACE y 
;

SELECT 
	y.ID 
	, tb.NAME AS block_name
	, tr.name AS start_row_name
	, tr2.name AS stop_row_name 
	, y.START_STACK 
	, y.STOP_STACK 
	, tsn.custom_name AS start_stack_name
	, tsn2.custom_name AS stop_stack_name
	, CASE 
		WHEN tr.name = tr2.name THEN 'TRUE'
		ELSE 'FALSE'
	  END AS "Check"
	, CASE 
		WHEN tsn.custom_name = tsn2.CUSTOM_NAME THEN 'TRUE'
		ELSE 'FALSE'
	  END AS "Check2"
	, y.NUM_TIERS 
	, y.ENABLED 
FROM YPSPACE y 
JOIN TD_BLOCK tb ON y.BLOCK_ID = tb.ID 
JOIN TD_ROW tr ON y.START_ROW_ID = tr.ID 
JOIN TD_ROW tr2 ON y.STOP_ROW_ID = tr2.id	
JOIN TD_STACK_NAME tsn ON y.START_STACK = tsn.STACK_INDEX AND y.BLOCK_ID = tsn.BLOCK_ID  
JOIN TD_STACK_NAME tsn2 ON y.STOP_STACK = tsn2.stack_index AND y.block_id = tsn2.block_id
ORDER BY 
	tb.name
	, tr.name
	, tsn.custom_name
;
WITH 
	conv_to_text AS (
		SELECT
			r.name
			, REGEXP_REPLACE(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),'0+$') AS STACKS_MASK 
			, length(REGEXP_REPLACE(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),'0+$')) AS char_length
		FROM td_row r
	), decinum AS (
		SELECT 
			ctt.*
			, to_number (ctt.stacks_mask, rpad ('X',ctt.char_length,'X')) AS decimalnum
		FROM conv_to_text ctt
	), hexchars AS (
		SELECT 
			dn.*
			, to_char (TRUNC(dn.decimalnum / 1048576), 'FMX') AS hex1
			, to_char (trunc(MOD(dn.decimalnum, 1048576)/65536), 'FMX') AS hex2
			, to_char (TRUNC(MOD(dn.decimalnum,65536)/4096), 'FMX') AS hex3
			, to_char (TRUNC(MOD(dn.decimalnum,4096)/256), 'FMX') AS hex4
			, to_char (TRUNC(MOD(dn.decimalnum,256)/16), 'FMX') AS hex5
			, to_char (mod(dn.decimalnum, 16), 'FMX') AS hex6
		FROM decinum dn
	), stack_terms AS (
		SELECT
			hc.*
			, CASE 
				WHEN hc.hex1 = '0' THEN '0000'
				WHEN hc.hex1 = '1' THEN '0001'
				WHEN hc.hex1 = '2' THEN '0010'
				WHEN hc.hex1 = '3' THEN '0011'
				WHEN hc.hex1 = '4' THEN '0100'
				WHEN hc.hex1 = '5' THEN '0101'
				WHEN hc.hex1 = '6' THEN '0110'
				WHEN hc.hex1 = '7' THEN '0111'
				WHEN hc.hex1 = '8' THEN '1000'
				WHEN hc.hex1 = '9' THEN '1001'
				WHEN hc.hex1 = 'A' THEN '1010'
				WHEN hc.hex1 = 'B' THEN '1011'
				WHEN hc.hex1 = 'C' THEN '1100'
				WHEN hc.hex1 = 'D' THEN '1101'
				WHEN hc.hex1 = 'E' THEN '1110'
				WHEN hc.hex1 = 'F' THEN '1111'
			  END AS bin1
			, CASE 
				WHEN hc.hex2 = '0' THEN '0000'
				WHEN hc.hex2 = '1' THEN '0001'
				WHEN hc.hex2 = '2' THEN '0010'
				WHEN hc.hex2 = '3' THEN '0011'
				WHEN hc.hex2 = '4' THEN '0100'
				WHEN hc.hex2 = '5' THEN '0101'
				WHEN hc.hex2 = '6' THEN '0110'
				WHEN hc.hex2 = '7' THEN '0111'
				WHEN hc.hex2 = '8' THEN '1000'
				WHEN hc.hex2 = '9' THEN '1001'
				WHEN hc.hex2 = 'A' THEN '1010'
				WHEN hc.hex2 = 'B' THEN '1011'
				WHEN hc.hex2 = 'C' THEN '1100'
				WHEN hc.hex2 = 'D' THEN '1101'
				WHEN hc.hex2 = 'E' THEN '1110'
				WHEN hc.hex2 = 'F' THEN '1111'
			  END AS bin2
			, CASE 
				WHEN hc.hex3 = '0' THEN '0000'
				WHEN hc.hex3 = '1' THEN '0001'
				WHEN hc.hex3 = '2' THEN '0010'
				WHEN hc.hex3 = '3' THEN '0011'
				WHEN hc.hex3 = '4' THEN '0100'
				WHEN hc.hex3 = '5' THEN '0101'
				WHEN hc.hex3 = '6' THEN '0110'
				WHEN hc.hex3 = '7' THEN '0111'
				WHEN hc.hex3 = '8' THEN '1000'
				WHEN hc.hex3 = '9' THEN '1001'
				WHEN hc.hex3 = 'A' THEN '1010'
				WHEN hc.hex3 = 'B' THEN '1011'
				WHEN hc.hex3 = 'C' THEN '1100'
				WHEN hc.hex3 = 'D' THEN '1101'
				WHEN hc.hex3 = 'E' THEN '1110'
				WHEN hc.hex3 = 'F' THEN '1111'
			  END AS bin3
			, CASE 
				WHEN hc.hex4 = '0' THEN '0000'
				WHEN hc.hex4 = '1' THEN '0001'
				WHEN hc.hex4 = '2' THEN '0010'
				WHEN hc.hex4 = '3' THEN '0011'
				WHEN hc.hex4 = '4' THEN '0100'
				WHEN hc.hex4 = '5' THEN '0101'
				WHEN hc.hex4 = '6' THEN '0110'
				WHEN hc.hex4 = '7' THEN '0111'
				WHEN hc.hex4 = '8' THEN '1000'
				WHEN hc.hex4 = '9' THEN '1001'
				WHEN hc.hex4 = 'A' THEN '1010'
				WHEN hc.hex4 = 'B' THEN '1011'
				WHEN hc.hex4 = 'C' THEN '1100'
				WHEN hc.hex4 = 'D' THEN '1101'
				WHEN hc.hex4 = 'E' THEN '1110'
				WHEN hc.hex4 = 'F' THEN '1111'
			  END AS bin4
			, CASE 
				WHEN hc.hex5 = '0' THEN '0000'
				WHEN hc.hex5 = '1' THEN '0001'
				WHEN hc.hex5 = '2' THEN '0010'
				WHEN hc.hex5 = '3' THEN '0011'
				WHEN hc.hex5 = '4' THEN '0100'
				WHEN hc.hex5 = '5' THEN '0101'
				WHEN hc.hex5 = '6' THEN '0110'
				WHEN hc.hex5 = '7' THEN '0111'
				WHEN hc.hex5 = '8' THEN '1000'
				WHEN hc.hex5 = '9' THEN '1001'
				WHEN hc.hex5 = 'A' THEN '1010'
				WHEN hc.hex5 = 'B' THEN '1011'
				WHEN hc.hex5 = 'C' THEN '1100'
				WHEN hc.hex5 = 'D' THEN '1101'
				WHEN hc.hex5 = 'E' THEN '1110'
				WHEN hc.hex5 = 'F' THEN '1111'
			  END AS bin5
			, CASE 
				WHEN hc.hex6 = '0' THEN '0000'
				WHEN hc.hex6 = '1' THEN '0001'
				WHEN hc.hex6 = '2' THEN '0010'
				WHEN hc.hex6 = '3' THEN '0011'
				WHEN hc.hex6 = '4' THEN '0100'
				WHEN hc.hex6 = '5' THEN '0101'
				WHEN hc.hex6 = '6' THEN '0110'
				WHEN hc.hex6 = '7' THEN '0111'
				WHEN hc.hex6 = '8' THEN '1000'
				WHEN hc.hex6 = '9' THEN '1001'
				WHEN hc.hex6 = 'A' THEN '1010'
				WHEN hc.hex6 = 'B' THEN '1011'
				WHEN hc.hex6 = 'C' THEN '1100'
				WHEN hc.hex6 = 'D' THEN '1101'
				WHEN hc.hex6 = 'E' THEN '1110'
				WHEN hc.hex6 = 'F' THEN '1111'
			  END AS bin6
			, CASE 
				WHEN hc.hex1 = '0' THEN 0
				WHEN hc.hex1 = '1' THEN 1
				WHEN hc.hex1 = '2' THEN 1
				WHEN hc.hex1 = '3' THEN 2
				WHEN hc.hex1 = '4' THEN 1
				WHEN hc.hex1 = '5' THEN 2
				WHEN hc.hex1 = '6' THEN 2
				WHEN hc.hex1 = '7' THEN 3
				WHEN hc.hex1 = '8' THEN 1
				WHEN hc.hex1 = '9' THEN 2
				WHEN hc.hex1 = 'A' THEN 2
				WHEN hc.hex1 = 'B' THEN 3
				WHEN hc.hex1 = 'C' THEN 2
				WHEN hc.hex1 = 'D' THEN 3
				WHEN hc.hex1 = 'E' THEN 3
				WHEN hc.hex1 = 'F' THEN 4
			  END AS stack_term1
			, CASE 
				WHEN hc.hex2 = '0' THEN 0
				WHEN hc.hex2 = '1' THEN 1
				WHEN hc.hex2 = '2' THEN 1
				WHEN hc.hex2 = '3' THEN 2
				WHEN hc.hex2 = '4' THEN 1
				WHEN hc.hex2 = '5' THEN 2
				WHEN hc.hex2 = '6' THEN 2
				WHEN hc.hex2 = '7' THEN 3
				WHEN hc.hex2 = '8' THEN 1
				WHEN hc.hex2 = '9' THEN 2
				WHEN hc.hex2 = 'A' THEN 2
				WHEN hc.hex2 = 'B' THEN 3
				WHEN hc.hex2 = 'C' THEN 2
				WHEN hc.hex2 = 'D' THEN 3
				WHEN hc.hex2 = 'E' THEN 3
				WHEN hc.hex2 = 'F' THEN 4
			  END AS stack_term2
			, CASE 
				WHEN hc.hex3 = '0' THEN 0
				WHEN hc.hex3 = '1' THEN 1
				WHEN hc.hex3 = '2' THEN 1
				WHEN hc.hex3 = '3' THEN 2
				WHEN hc.hex3 = '4' THEN 1
				WHEN hc.hex3 = '5' THEN 2
				WHEN hc.hex3 = '6' THEN 2
				WHEN hc.hex3 = '7' THEN 3
				WHEN hc.hex3 = '8' THEN 1
				WHEN hc.hex3 = '9' THEN 2
				WHEN hc.hex3 = 'A' THEN 2
				WHEN hc.hex3 = 'B' THEN 3
				WHEN hc.hex3 = 'C' THEN 2
				WHEN hc.hex3 = 'D' THEN 3
				WHEN hc.hex3 = 'E' THEN 3
				WHEN hc.hex3 = 'F' THEN 4
			  END AS stack_term3
			, CASE 
				WHEN hc.hex4 = '0' THEN 0
				WHEN hc.hex4 = '1' THEN 1
				WHEN hc.hex4 = '2' THEN 1
				WHEN hc.hex4 = '3' THEN 2
				WHEN hc.hex4 = '4' THEN 1
				WHEN hc.hex4 = '5' THEN 2
				WHEN hc.hex4 = '6' THEN 2
				WHEN hc.hex4 = '7' THEN 3
				WHEN hc.hex4 = '8' THEN 1
				WHEN hc.hex4 = '9' THEN 2
				WHEN hc.hex4 = 'A' THEN 2
				WHEN hc.hex4 = 'B' THEN 3
				WHEN hc.hex4 = 'C' THEN 2
				WHEN hc.hex4 = 'D' THEN 3
				WHEN hc.hex4 = 'E' THEN 3
				WHEN hc.hex4 = 'F' THEN 4
			  END AS stack_term4
			, CASE 
				WHEN hc.hex5 = '0' THEN 0
				WHEN hc.hex5 = '1' THEN 1
				WHEN hc.hex5 = '2' THEN 1
				WHEN hc.hex5 = '3' THEN 2
				WHEN hc.hex5 = '4' THEN 1
				WHEN hc.hex5 = '5' THEN 2
				WHEN hc.hex5 = '6' THEN 2
				WHEN hc.hex5 = '7' THEN 3
				WHEN hc.hex5 = '8' THEN 1
				WHEN hc.hex5 = '9' THEN 2
				WHEN hc.hex5 = 'A' THEN 2
				WHEN hc.hex5 = 'B' THEN 3
				WHEN hc.hex5 = 'C' THEN 2
				WHEN hc.hex5 = 'D' THEN 3
				WHEN hc.hex5 = 'E' THEN 3
				WHEN hc.hex5 = 'F' THEN 4
			  END AS stack_term5
			, CASE 
				WHEN hc.hex6 = '0' THEN 0
				WHEN hc.hex6 = '1' THEN 1
				WHEN hc.hex6 = '2' THEN 1
				WHEN hc.hex6 = '3' THEN 2
				WHEN hc.hex6 = '4' THEN 1
				WHEN hc.hex6 = '5' THEN 2
				WHEN hc.hex6 = '6' THEN 2
				WHEN hc.hex6 = '7' THEN 3
				WHEN hc.hex6 = '8' THEN 1
				WHEN hc.hex6 = '9' THEN 2
				WHEN hc.hex6 = 'A' THEN 2
				WHEN hc.hex6 = 'B' THEN 3
				WHEN hc.hex6 = 'C' THEN 2
				WHEN hc.hex6 = 'D' THEN 3
				WHEN hc.hex6 = 'E' THEN 3
				WHEN hc.hex6 = 'F' THEN 4
			  END AS stack_term6
			FROM hexchars hc
	), num_stacks AS (
		SELECT 
			st.*
			, stack_term1 + stack_term2 + stack_term3 + stack_term4 + stack_term5 + stack_term6 AS num_stacks
		FROM stack_terms st
	)
SELECT 
	nm.name
	, nm.num_stacks 
FROM num_stacks nm
;

--The maximum number of stacks for a row in a block is defined by the number of stacks with the block's key in the 
--TD_STACK_NAME table. The number of stacks per row is defined by the BLOB called stacks_mask in the TD_ROW table.
--Individual fine spots cannot be deleted, only entire columns of fine spots and entire rows. The defined
--space in the yard including disabled spaces is grained by the row. I need to create a table where each row is a
--row of a block, decode the stacks_mask field for that row as the number of stacks, and join that to the number of
--tiers for the block. Multiplying those fields for each row and summing the table yields the defined spaces in
--TEUs. The disabled spaces will then need to be subtracted to get the yard capacity.

--This query isn't quite right. What I need to do instead, is start with the TD_STACK_NAME table and determine the
--maximum number of stacks for each block. From that I can then determine how many hex character I need and extract
--them. I then translate that to binary and extract the number of bits to match the max number of stacks. Any
--extracted '0' is a deleted stack. 
WITH 
	conv_to_text AS (
		SELECT
			r.id
			, r.name
			, REGEXP_REPLACE(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),'0+$') AS STACKS_MASK 
			, length(REGEXP_REPLACE(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),'0+$')) AS char_length
		FROM td_row r
	), decinum AS (
		SELECT 
			ctt.*
			, to_number (ctt.stacks_mask, rpad ('X',ctt.char_length,'X')) AS decimalnum
		FROM conv_to_text ctt
	), hexchars AS (
		SELECT 
			dn.*
			, to_char (mod(dn.decimalnum, 16), 'FMX') AS hex1
			, to_char (TRUNC(MOD(dn.decimalnum,256)/16), 'FMX') AS hex2
			, to_char (TRUNC(MOD(dn.decimalnum,4096)/256), 'FMX') AS hex3
			, to_char (TRUNC(MOD(dn.decimalnum,65536)/4096), 'FMX') AS hex4
			, to_char (trunc(MOD(dn.decimalnum, 1048576)/65536), 'FMX') AS hex5
			, to_char (TRUNC(dn.decimalnum / 1048576), 'FMX') AS hex6
		FROM decinum dn
	), stack_terms AS (
		SELECT
			hc.*
			, CASE 
				WHEN hc.hex1 = '0' THEN '0000'
				WHEN hc.hex1 = '1' THEN '1000'
				WHEN hc.hex1 = '2' THEN '0100'
				WHEN hc.hex1 = '3' THEN '1100'
				WHEN hc.hex1 = '4' THEN '0010'
				WHEN hc.hex1 = '5' THEN '1010'
				WHEN hc.hex1 = '6' THEN '0110'
				WHEN hc.hex1 = '7' THEN '1110'
				WHEN hc.hex1 = '8' THEN '0001'
				WHEN hc.hex1 = '9' THEN '1001'
				WHEN hc.hex1 = 'A' THEN '0101'
				WHEN hc.hex1 = 'B' THEN '1101'
				WHEN hc.hex1 = 'C' THEN '0011'
				WHEN hc.hex1 = 'D' THEN '1011'
				WHEN hc.hex1 = 'E' THEN '0111'
				WHEN hc.hex1 = 'F' THEN '1111'
			  END AS bin1
			, CASE 
				WHEN hc.hex2 = '0' THEN '0000'
				WHEN hc.hex2 = '1' THEN '1000'
				WHEN hc.hex2 = '2' THEN '0100'
				WHEN hc.hex2 = '3' THEN '1100'
				WHEN hc.hex2 = '4' THEN '0010'
				WHEN hc.hex2 = '5' THEN '1010'
				WHEN hc.hex2 = '6' THEN '0110'
				WHEN hc.hex2 = '7' THEN '1110'
				WHEN hc.hex2 = '8' THEN '0001'
				WHEN hc.hex2 = '9' THEN '1001'
				WHEN hc.hex2 = 'A' THEN '0101'
				WHEN hc.hex2 = 'B' THEN '1101'
				WHEN hc.hex2 = 'C' THEN '0011'
				WHEN hc.hex2 = 'D' THEN '1011'
				WHEN hc.hex2 = 'E' THEN '0111'
				WHEN hc.hex2 = 'F' THEN '1111'
			  END AS bin2
			, CASE 
				WHEN hc.hex3 = '0' THEN '0000'
				WHEN hc.hex3 = '1' THEN '1000'
				WHEN hc.hex3 = '2' THEN '0100'
				WHEN hc.hex3 = '3' THEN '1100'
				WHEN hc.hex3 = '4' THEN '0010'
				WHEN hc.hex3 = '5' THEN '1010'
				WHEN hc.hex3 = '6' THEN '0110'
				WHEN hc.hex3 = '7' THEN '1110'
				WHEN hc.hex3 = '8' THEN '0001'
				WHEN hc.hex3 = '9' THEN '1001'
				WHEN hc.hex3 = 'A' THEN '0101'
				WHEN hc.hex3 = 'B' THEN '1101'
				WHEN hc.hex3 = 'C' THEN '0011'
				WHEN hc.hex3 = 'D' THEN '1011'
				WHEN hc.hex3 = 'E' THEN '0111'
				WHEN hc.hex3 = 'F' THEN '1111'
			  END AS bin3
			, CASE 
				WHEN hc.hex4 = '0' THEN '0000'
				WHEN hc.hex4 = '1' THEN '1000'
				WHEN hc.hex4 = '2' THEN '0100'
				WHEN hc.hex4 = '3' THEN '1100'
				WHEN hc.hex4 = '4' THEN '0010'
				WHEN hc.hex4 = '5' THEN '1010'
				WHEN hc.hex4 = '6' THEN '0110'
				WHEN hc.hex4 = '7' THEN '1110'
				WHEN hc.hex4 = '8' THEN '0001'
				WHEN hc.hex4 = '9' THEN '1001'
				WHEN hc.hex4 = 'A' THEN '0101'
				WHEN hc.hex4 = 'B' THEN '1101'
				WHEN hc.hex4 = 'C' THEN '0011'
				WHEN hc.hex4 = 'D' THEN '1011'
				WHEN hc.hex4 = 'E' THEN '0111'
				WHEN hc.hex4 = 'F' THEN '1111'
			  END AS bin4
			, CASE 
				WHEN hc.hex5 = '0' THEN '0000'
				WHEN hc.hex5 = '1' THEN '1000'
				WHEN hc.hex5 = '2' THEN '0100'
				WHEN hc.hex5 = '3' THEN '1100'
				WHEN hc.hex5 = '4' THEN '0010'
				WHEN hc.hex5 = '5' THEN '1010'
				WHEN hc.hex5 = '6' THEN '0110'
				WHEN hc.hex5 = '7' THEN '1110'
				WHEN hc.hex5 = '8' THEN '0001'
				WHEN hc.hex5 = '9' THEN '1001'
				WHEN hc.hex5 = 'A' THEN '0101'
				WHEN hc.hex5 = 'B' THEN '1101'
				WHEN hc.hex5 = 'C' THEN '0011'
				WHEN hc.hex5 = 'D' THEN '1011'
				WHEN hc.hex5 = 'E' THEN '0111'
				WHEN hc.hex5 = 'F' THEN '1111'
			  END AS bin5
			, CASE 
				WHEN hc.hex6 = '0' THEN '0000'
				WHEN hc.hex6 = '1' THEN '1000'
				WHEN hc.hex6 = '2' THEN '0100'
				WHEN hc.hex6 = '3' THEN '1100'
				WHEN hc.hex6 = '4' THEN '0010'
				WHEN hc.hex6 = '5' THEN '1010'
				WHEN hc.hex6 = '6' THEN '0110'
				WHEN hc.hex6 = '7' THEN '1110'
				WHEN hc.hex6 = '8' THEN '0001'
				WHEN hc.hex6 = '9' THEN '1001'
				WHEN hc.hex6 = 'A' THEN '0101'
				WHEN hc.hex6 = 'B' THEN '1101'
				WHEN hc.hex6 = 'C' THEN '0011'
				WHEN hc.hex6 = 'D' THEN '1011'
				WHEN hc.hex6 = 'E' THEN '0111'
				WHEN hc.hex6 = 'F' THEN '1111'
			  END AS bin6
			, CASE 
				WHEN hc.hex1 = '0' THEN 0
				WHEN hc.hex1 = '1' THEN 1
				WHEN hc.hex1 = '2' THEN 1
				WHEN hc.hex1 = '3' THEN 2
				WHEN hc.hex1 = '4' THEN 1
				WHEN hc.hex1 = '5' THEN 2
				WHEN hc.hex1 = '6' THEN 2
				WHEN hc.hex1 = '7' THEN 3
				WHEN hc.hex1 = '8' THEN 1
				WHEN hc.hex1 = '9' THEN 2
				WHEN hc.hex1 = 'A' THEN 2
				WHEN hc.hex1 = 'B' THEN 3
				WHEN hc.hex1 = 'C' THEN 2
				WHEN hc.hex1 = 'D' THEN 3
				WHEN hc.hex1 = 'E' THEN 3
				WHEN hc.hex1 = 'F' THEN 4
			  END AS stack_term1
			, CASE 
				WHEN hc.hex2 = '0' THEN 0
				WHEN hc.hex2 = '1' THEN 1
				WHEN hc.hex2 = '2' THEN 1
				WHEN hc.hex2 = '3' THEN 2
				WHEN hc.hex2 = '4' THEN 1
				WHEN hc.hex2 = '5' THEN 2
				WHEN hc.hex2 = '6' THEN 2
				WHEN hc.hex2 = '7' THEN 3
				WHEN hc.hex2 = '8' THEN 1
				WHEN hc.hex2 = '9' THEN 2
				WHEN hc.hex2 = 'A' THEN 2
				WHEN hc.hex2 = 'B' THEN 3
				WHEN hc.hex2 = 'C' THEN 2
				WHEN hc.hex2 = 'D' THEN 3
				WHEN hc.hex2 = 'E' THEN 3
				WHEN hc.hex2 = 'F' THEN 4
			  END AS stack_term2
			, CASE 
				WHEN hc.hex3 = '0' THEN 0
				WHEN hc.hex3 = '1' THEN 1
				WHEN hc.hex3 = '2' THEN 1
				WHEN hc.hex3 = '3' THEN 2
				WHEN hc.hex3 = '4' THEN 1
				WHEN hc.hex3 = '5' THEN 2
				WHEN hc.hex3 = '6' THEN 2
				WHEN hc.hex3 = '7' THEN 3
				WHEN hc.hex3 = '8' THEN 1
				WHEN hc.hex3 = '9' THEN 2
				WHEN hc.hex3 = 'A' THEN 2
				WHEN hc.hex3 = 'B' THEN 3
				WHEN hc.hex3 = 'C' THEN 2
				WHEN hc.hex3 = 'D' THEN 3
				WHEN hc.hex3 = 'E' THEN 3
				WHEN hc.hex3 = 'F' THEN 4
			  END AS stack_term3
			, CASE 
				WHEN hc.hex4 = '0' THEN 0
				WHEN hc.hex4 = '1' THEN 1
				WHEN hc.hex4 = '2' THEN 1
				WHEN hc.hex4 = '3' THEN 2
				WHEN hc.hex4 = '4' THEN 1
				WHEN hc.hex4 = '5' THEN 2
				WHEN hc.hex4 = '6' THEN 2
				WHEN hc.hex4 = '7' THEN 3
				WHEN hc.hex4 = '8' THEN 1
				WHEN hc.hex4 = '9' THEN 2
				WHEN hc.hex4 = 'A' THEN 2
				WHEN hc.hex4 = 'B' THEN 3
				WHEN hc.hex4 = 'C' THEN 2
				WHEN hc.hex4 = 'D' THEN 3
				WHEN hc.hex4 = 'E' THEN 3
				WHEN hc.hex4 = 'F' THEN 4
			  END AS stack_term4
			, CASE 
				WHEN hc.hex5 = '0' THEN 0
				WHEN hc.hex5 = '1' THEN 1
				WHEN hc.hex5 = '2' THEN 1
				WHEN hc.hex5 = '3' THEN 2
				WHEN hc.hex5 = '4' THEN 1
				WHEN hc.hex5 = '5' THEN 2
				WHEN hc.hex5 = '6' THEN 2
				WHEN hc.hex5 = '7' THEN 3
				WHEN hc.hex5 = '8' THEN 1
				WHEN hc.hex5 = '9' THEN 2
				WHEN hc.hex5 = 'A' THEN 2
				WHEN hc.hex5 = 'B' THEN 3
				WHEN hc.hex5 = 'C' THEN 2
				WHEN hc.hex5 = 'D' THEN 3
				WHEN hc.hex5 = 'E' THEN 3
				WHEN hc.hex5 = 'F' THEN 4
			  END AS stack_term5
			, CASE 
				WHEN hc.hex6 = '0' THEN 0
				WHEN hc.hex6 = '1' THEN 1
				WHEN hc.hex6 = '2' THEN 1
				WHEN hc.hex6 = '3' THEN 2
				WHEN hc.hex6 = '4' THEN 1
				WHEN hc.hex6 = '5' THEN 2
				WHEN hc.hex6 = '6' THEN 2
				WHEN hc.hex6 = '7' THEN 3
				WHEN hc.hex6 = '8' THEN 1
				WHEN hc.hex6 = '9' THEN 2
				WHEN hc.hex6 = 'A' THEN 2
				WHEN hc.hex6 = 'B' THEN 3
				WHEN hc.hex6 = 'C' THEN 2
				WHEN hc.hex6 = 'D' THEN 3
				WHEN hc.hex6 = 'E' THEN 3
				WHEN hc.hex6 = 'F' THEN 4
			  END AS stack_term6
			FROM hexchars hc
	)--, num_stacks AS (
		SELECT 
			st.*
			, stack_term1 + stack_term2 + stack_term3 + stack_term4 + stack_term5 + stack_term6 AS num_stacks
		FROM stack_terms st
	), r_with_num_stacks AS (
		SELECT 
			nm.id 
			, nm.name
			, nm.num_stacks 
		FROM num_stacks nm
	), num_tiers AS ( -- 163 blocks
		SELECT 
--			count(DISTINCT b.id)
			b.id
			, b.name
			, count(*) AS num_tiers
		FROM td_block b
		LEFT JOIN td_tier_name t ON t.block_id = b.id
		GROUP BY b.id, b.name
		ORDER BY b.name
	), def_by_row AS (
		SELECT
		--	count(*)
			b.ID AS block_id 
			, b.name AS block_name
			, r.ID AS row_id
			, r.NAME AS row_name
			, ns.num_stacks
			, t.num_tiers
		FROM td_block b
		LEFT JOIN td_row r ON r.BLOCK_ID = b.ID 
		LEFT JOIN r_with_num_stacks ns ON ns.id = r.id
		LEFT JOIN num_tiers t ON t.id = b.id
		WHERE
			NOT (b.TYPE = '4') -- No heaps
		ORDER BY
			block_name,
			row_name
	), def_spots AS (
		SELECT
			dr.*
			, dr.num_stacks * dr.num_tiers AS def_spots
		FROM def_by_row dr
	)
SELECT
	sum (ds.def_spots) AS def_TEU
FROM def_spots ds
;

SELECT 
	*
FROM td_row r
WHERE 
	r.BLOCK_ID = '556635172'
;

--Now to build the correct defined space query. Starting with the max num stacks and extracting
--only the necessary characters from the hex and bin.
WITH 
	max_stacks AS (
		SELECT 
			tsn.block_id
			, b.name AS block_name
			, count(*) AS max_stacks --22 IS the largest value FOR MIT UAT, 22 digits OF bin IS six digits OF hex (5.5)
		FROM TD_STACK_NAME tsn 
		LEFT JOIN td_block b ON b.id = tsn.block_id
		WHERE 
			NOT (b.TYPE = '4') -- NO heaps
		GROUP BY 
			tsn.block_id
			, b.name
	), blob_to_bin_pieces AS (
		SELECT 
			ms.*
			, r.ID AS row_id
			, r.NAME AS row_name
		--	, (trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2 AS num_hex_chars
		--	, SUBSTR(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,(trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2) AS STACKS_MASK 
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) AS hex1
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) AS hex2
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) AS hex3
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) AS hex4
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) AS hex5
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) AS hex6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '1111'
			  END AS bin1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '1111'
			  END AS bin2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '1111'
			  END AS bin3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '1111'
			  END AS bin4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '1111'
			  END AS bin5	  
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '1111'
			  END AS bin6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '4'
			  END AS term1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '4'
			  END AS term2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '4'
			  END AS term3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '4'
			  END AS term4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '4'
			  END AS term5
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '4'
			  END AS term6
			FROM max_stacks ms
		LEFT JOIN td_row r ON r.BLOCK_ID = ms.block_id
		--ORDER BY 
		--	ms.name
	)
SELECT
	btp.block_id
	, Btp.block_name
	, btp.row_id
	, btp.row_name
	, btp.max_stacks
	, substr(bin1 || bin2 || bin3 || bin4 || bin5 || bin6,1,btp.max_stacks) AS flags
	, btp.term1 + btp.term2 + btp.term3 + btp.term4 + btp.term5 + btp.term6 AS num_stacks
FROM blob_to_bin_pieces btp
;

--Now to compute the disabled space in TEU
WITH 
	max_stacks AS (
		SELECT 
			tsn.block_id
			, b.name AS block_name
			, count(*) AS max_stacks --22 IS the largest value FOR MIT UAT, 22 digits OF bin IS six digits OF hex (5.5)
		FROM TD_STACK_NAME tsn 
		LEFT JOIN td_block b ON b.id = tsn.block_id
		WHERE 
			NOT (b.TYPE = '4') -- NO heaps
		GROUP BY 
			tsn.block_id
			, b.name
	), blob_to_bin_pieces AS (
		SELECT 
			ms.*
			, r.ID AS row_id
			, r.NAME AS row_name
		--	, (trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2 AS num_hex_chars
		--	, SUBSTR(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,(trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2) AS STACKS_MASK 
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) AS hex1
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) AS hex2
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) AS hex3
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) AS hex4
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) AS hex5
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) AS hex6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '1111'
			  END AS bin1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '1111'
			  END AS bin2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '1111'
			  END AS bin3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '1111'
			  END AS bin4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '1111'
			  END AS bin5	  
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '1111'
			  END AS bin6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '4'
			  END AS term1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '4'
			  END AS term2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '4'
			  END AS term3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '4'
			  END AS term4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '4'
			  END AS term5
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '4'
			  END AS term6
			FROM max_stacks ms
		LEFT JOIN td_row r ON r.BLOCK_ID = ms.block_id
		--ORDER BY 
		--	ms.name
	), deleted_flags AS (
		SELECT
			btp.block_id
			, Btp.block_name
			, btp.row_id
			, btp.row_name
			, btp.max_stacks
			, substr(bin1 || bin2 || bin3 || bin4 || bin5 || bin6,1,btp.max_stacks) AS flags
			, btp.term1 + btp.term2 + btp.term3 + btp.term4 + btp.term5 + btp.term6 AS num_stacks
		FROM blob_to_bin_pieces btp
	)
SELECT 	
	ys.ID 
	, ys.BLOCK_ID 
	, b.name AS block_name
	, ys.START_ROW_ID
	, r_i.NAME AS start_row_name
	, ys.STOP_ROW_ID 
	, r_f.name AS stop_row_name
	, ys.START_STACK 
	, ys.STOP_STACK 
	, ys.NUM_TIERS 
	, df.flags
FROM YPDISABLED_SPACE ys 
LEFT JOIN td_block b ON b.id = ys.block_id
LEFT JOIN td_row r_i ON r_i.id = ys.START_ROW_ID 
LEFT JOIN td_row r_f ON r_f.id = ys.START_ROW_ID
LEFT JOIN deleted_flags df ON df.row_id = r_i.id
WHERE NOT (b.TYPE = '4')
ORDER BY 
	start_row_name
;

SELECT 
	*
FROM YPDISABLED_SPACE ys 
WHERE ys.id = '385358154'
;

SELECT 
	*
FROM td_block b
WHERE b.id = '52285060'
;

--The strategy now is to create a table that is grained by the fine spot. A fine spot is listed only if it is disabled
--or deleted. I will then select the distinct rows and count them to get the unavailable space and subtract it from 
--the product of the number of rows, the number of stacks, and the number of tiers.

--Soln for splitting the flags
with temp as (select '12456' as str from dual)
select 
	substr(str,level,1) AS CHARACTER
	, LEVEL AS position
from temp
connect by level <= length(str);

--Soln for getting the tiers as rows
WITH number_sequence (num) AS (
  SELECT 0 AS num FROM DUAL
  UNION ALL
  SELECT num + 1 FROM number_sequence WHERE num < 7 - 1
)
SELECT num FROM number_sequence;

--Deleted space first
WITH 
	max_stacks AS (
		SELECT 
			tsn.block_id
			, b.name AS block_name
			, count(*) AS max_stacks --22 IS the largest value FOR MIT UAT, 22 digits OF bin IS six digits OF hex (5.5)
		FROM TD_STACK_NAME tsn 
		LEFT JOIN td_block b ON b.id = tsn.block_id
		WHERE 
			NOT (b.TYPE = '4') -- NO heaps
		GROUP BY 
			tsn.block_id
			, b.name
	), blob_to_bin_pieces AS (
		SELECT 
			ms.*
			, r.ID AS row_id
			, r.NAME AS row_name
			, r.num_tiers
		--	, (trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2 AS num_hex_chars
		--	, SUBSTR(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,(trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2) AS STACKS_MASK 
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) AS hex1
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) AS hex2
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) AS hex3
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) AS hex4
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) AS hex5
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) AS hex6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '1111'
			  END AS bin1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '1111'
			  END AS bin2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '1111'
			  END AS bin3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '1111'
			  END AS bin4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '1111'
			  END AS bin5	  
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '1111'
			  END AS bin6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '4'
			  END AS term1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '4'
			  END AS term2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '4'
			  END AS term3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '4'
			  END AS term4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '4'
			  END AS term5
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '4'
			  END AS term6
			FROM max_stacks ms
		LEFT JOIN td_row r ON r.BLOCK_ID = ms.block_id
		--ORDER BY 
		--	ms.name
	), blocks_and_rows AS (
		SELECT
			btp.block_id
			, Btp.block_name
			, btp.row_id
			, btp.row_name
			, btp.num_tiers
			, btp.max_stacks
			, substr(bin1 || bin2 || bin3 || bin4 || bin5 || bin6,1,btp.max_stacks) AS flags
			, btp.term1 + btp.term2 + btp.term3 + btp.term4 + btp.term5 + btp.term6 AS num_stacks
		FROM blob_to_bin_pieces btp
	), blocks_rows_stacks AS (
		SELECT
		    bnr.block_id,
		    bnr.block_name,
		    bnr.row_id,
		    bnr.row_name,
		    bnr.num_tiers,
		    bnr.max_stacks,
		    bnr.flags,
		    SUBSTR(bnr.flags, LEVEL, 1) AS stack_flag,
		    LEVEL - 1 AS stack_index
		FROM 
		    blocks_and_rows bnr
		CONNECT BY 
		    PRIOR bnr.block_id = bnr.block_id
		    AND PRIOR bnr.row_id = bnr.row_id
		    AND PRIOR SYS_GUID() IS NOT NULL
		    AND LEVEL <= LENGTH(bnr.flags)
		ORDER BY
			bnr.row_name
			, stack_index
	), blocks_rows_stacks_tiers (block_id, block_name, row_id, row_name, num_tiers, max_stacks, flags, stack_flag, stack_index, tier_index) AS (
        SELECT 
        	brs.block_id
        	, brs.block_name
        	, brs.row_id
        	, brs.row_name
        	, brs.num_tiers
        	, brs.max_stacks
        	, brs.flags
        	, brs.stack_flag
        	, brs.stack_index
        	, 1 AS tier_index 
        FROM blocks_rows_stacks brs
        UNION ALL
        SELECT 
        	brst.block_id
        	, brst.block_name
        	, brst.row_id
        	, brst.row_name
        	, brst.num_tiers
        	, brst.max_stacks
        	, brst.flags
        	, brst.stack_flag
        	, brst.stack_index
			, brst.tier_index + 1
		FROM blocks_rows_stacks_tiers brst 
        WHERE tier_index < num_tiers
    )
SELECT 
	count(*)
/*	brst.block_id
	, brst.block_name
	, brst.row_id
	, brst.row_name
	, brst.num_tiers
	, brst.max_stacks
	, brst.flags
	, brst.stack_flag
	, brst.stack_index
	, brst.tier_index
*/FROM blocks_rows_stacks_tiers brst
WHERE
	brst.stack_flag = '0'
/*ORDER BY 
	brst.block_name
	, brst.row_name
	, brst.stack_index
	, brst.tier_index
*/;

--Soln for getting the tiers as rows
WITH 
	your_table AS (
		SELECT 7 AS your_value FROM dual -- Example: your_table contains the field with the value 7
	), number_sequence (num) AS (
		SELECT 1 AS num FROM DUAL
		UNION ALL
		SELECT num + 1 FROM number_sequence, your_table WHERE num < your_value - 1
	), first_digit AS (
		SELECT num AS dig1 FROM number_sequence
	), number_sequence2 (num, dig1) AS (
        SELECT 0 AS num, dig1 FROM first_digit
        UNION ALL
        SELECT num + 1, dig1 FROM number_sequence2 
        WHERE num < dig1 - 1
    )
SELECT dig1, num FROM number_sequence2
ORDER BY dig1, num
;

--Deleted space first - rewrite to simplify and de-ChatGPT it
WITH 
	max_stacks AS (
		SELECT 
			tsn.block_id
			, b.name AS block_name
			, count(*) AS max_stacks --22 IS the largest value FOR MIT UAT, 22 digits OF bin IS six digits OF hex (5.5)
		FROM TD_STACK_NAME tsn 
		LEFT JOIN td_block b ON b.id = tsn.block_id
		WHERE 
			NOT (b.TYPE = '4') -- NO heaps
		GROUP BY 
			tsn.block_id
			, b.name
	), blob_to_bin_pieces AS (
		SELECT 
			ms.*
			, r.ID AS row_id
			, r.NAME AS row_name
			, r.num_tiers
		--	, (trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2 AS num_hex_chars
		--	, SUBSTR(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,(trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2) AS STACKS_MASK 
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) AS hex1
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) AS hex2
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) AS hex3
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) AS hex4
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) AS hex5
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) AS hex6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '1111'
			  END AS bin1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '1111'
			  END AS bin2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '1111'
			  END AS bin3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '1111'
			  END AS bin4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '1111'
			  END AS bin5	  
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '1111'
			  END AS bin6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '4'
			  END AS term1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '4'
			  END AS term2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '4'
			  END AS term3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '4'
			  END AS term4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '4'
			  END AS term5
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '4'
			  END AS term6
			FROM max_stacks ms
		LEFT JOIN td_row r ON r.BLOCK_ID = ms.block_id
		--ORDER BY 
		--	ms.name
	), blocks_and_rows AS (
		SELECT
			btp.block_id
			, Btp.block_name
			, btp.row_id
			, btp.row_name
			, btp.num_tiers
			, btp.max_stacks
			, substr(bin1 || bin2 || bin3 || bin4 || bin5 || bin6,1,btp.max_stacks) AS flags
			, btp.term1 + btp.term2 + btp.term3 + btp.term4 + btp.term5 + btp.term6 AS num_stacks
		FROM blob_to_bin_pieces btp
	), blocks_rows_stack_indexes (block_id, block_name, row_id, row_name, num_tiers, max_stacks, flags, num_stacks, stack_index) AS (
		SELECT 
			bnr.block_id
			, bnr.block_name
			, bnr.row_id
			, bnr.row_name
			, bnr.num_tiers
			, bnr.max_stacks
			, bnr.flags
			, bnr.num_stacks
			, 0 AS stack_index
		FROM blocks_and_rows bnr
		UNION ALL
		SELECT
			block_id
			, block_name
			, row_id
			, row_name
			, num_tiers
			, max_stacks
			, flags
			, num_stacks
			, stack_index + 1
		FROM blocks_rows_stack_indexes
		WHERE stack_index < max_stacks - 1
	), blocks_rows_stacks AS (
		SELECT 
			brsi.*
			, substr (brsi.flags,brsi.stack_index+1,1) AS stack_flag
		FROM blocks_rows_stack_indexes brsi
/*		ORDER BY 
			brsi.block_name
			, brsi.row_name
			, brsi.stack_index
*/	), blocks_rows_stacks_tiers (block_id, block_name, row_id, row_name, num_tiers, max_stacks, flags, stack_flag, stack_index, tier_index) AS (
        SELECT 
        	brs.block_id
        	, brs.block_name
        	, brs.row_id
        	, brs.row_name
        	, brs.num_tiers
        	, brs.max_stacks
        	, brs.flags
        	, brs.stack_flag
        	, brs.stack_index
        	, 1 AS tier_index 
        FROM blocks_rows_stacks brs
        UNION ALL
        SELECT 
        	brst.block_id
        	, brst.block_name
        	, brst.row_id
        	, brst.row_name
        	, brst.num_tiers
        	, brst.max_stacks
        	, brst.flags
        	, brst.stack_flag
        	, brst.stack_index
			, brst.tier_index + 1
		FROM blocks_rows_stacks_tiers brst 
        WHERE tier_index < num_tiers
    )
SELECT 
	brst.block_id
	, brst.row_id
	, brst.stack_index
	, brst.tier_index
--	count(*)
/*	brst.block_id
	, brst.block_name
	, brst.row_id
	, brst.row_name
	, brst.num_tiers
	, brst.max_stacks
	, brst.flags
	, brst.stack_flag
	, brst.stack_index
	, brst.tier_index
*/FROM blocks_rows_stacks_tiers brst
WHERE
	brst.stack_flag = '0'
ORDER BY 
	brst.block_id
	, brst.row_id
	, brst.stack_index
	, brst.tier_index
;

--Now for the disabled space
WITH 
	disabled_space_entries AS (
		SELECT 
			ys.id
			, ys.BLOCK_ID 
			, tb.name AS block_name
			, ys.START_ROW_ID
			, tr.name AS start_row_name
			, tr.row_index AS start_row_index
			, ys.STOP_ROW_ID 
			, tr2.name AS stop_row_name
			, tr2.row_index AS stop_row_index
			, ys.START_STACK 
			, tsn.CUSTOM_NAME AS start_stack_name
			, ys.STOP_STACK 
			, tsn2.CUSTOM_NAME AS stop_stack_name
			, ys.NUM_TIERS AS disabled_tiers
		FROM YPDISABLED_SPACE ys 
		LEFT JOIN TD_BLOCK tb ON tb.Id = ys.BLOCK_ID 
		LEFT JOIN td_row tr ON tr.id = ys.START_ROW_ID 
		LEFT JOIN td_row tr2 ON tr2.id = ys.stop_row_id 
		LEFT JOIN TD_STACK_NAME tsn ON tsn.BLOCK_ID = tb.id AND tsn.STACK_INDEX = ys.START_STACK 
		LEFT JOIN TD_STACK_NAME tsn2 ON tsn2.BLOCK_ID = tb.id AND tsn2.STACK_INDEX = ys.STOP_STACK
		WHERE 
			NOT (ys.TYPE = '2') 
	), expanded_rows (id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers, row_index) AS (
        SELECT 
        	id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			start_row_index AS row_index 
        FROM disabled_space_entries
        UNION ALL
        SELECT 
			id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index + 1
		FROM expanded_rows 
        WHERE row_index < stop_row_index
	), added_num_tiers AS (
		SELECT 
			er.*
			, tr.num_tiers AS tiers_in_row
		FROM expanded_rows er
		LEFT JOIN td_row tr ON er.block_id = tr.block_id AND er.row_index = tr.row_index
	), expanded_stacks (id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers, 
			row_index, tiers_in_row, stack_index) AS (
        SELECT 
        	id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, start_stack AS stack_index
        FROM added_num_tiers
        UNION ALL
        SELECT 
			id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, stack_index + 1
		FROM expanded_stacks 
        WHERE stack_index < stop_stack
	), expanded_tiers (id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers, 
			row_index, tiers_in_row, stack_index, tier_index) AS (
        SELECT 
        	id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, stack_index, tiers_in_row AS tier_index
        FROM expanded_stacks
        UNION ALL
        SELECT 
			id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, stack_index, tier_index - 1
		FROM expanded_tiers 
        WHERE tier_index > tiers_in_row - disabled_tiers + 1
	)
SELECT 
	et.block_id
	, tr.id AS row_id
	, et.stack_index
	, et.tier_index
FROM expanded_tiers et
LEFT JOIN td_row tr ON tr.block_id = et.block_id AND tr.row_index = et.row_index
ORDER BY 
	block_id
	, row_id
	, stack_index
	, tier_index
;

--Now for the union and the count
WITH 
	max_stacks AS (
		SELECT 
			tsn.block_id
			, b.name AS block_name
			, count(*) AS max_stacks --22 IS the largest value FOR MIT UAT, 22 digits OF bin IS six digits OF hex (5.5)
		FROM TD_STACK_NAME tsn 
		LEFT JOIN td_block b ON b.id = tsn.block_id
		WHERE 
			NOT (b.TYPE = '4') -- NO heaps
		GROUP BY 
			tsn.block_id
			, b.name
	), blob_to_bin_pieces AS (
		SELECT 
			ms.*
			, r.ID AS row_id
			, r.NAME AS row_name
			, r.num_tiers
		--	, (trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2 AS num_hex_chars
		--	, SUBSTR(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,(trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2) AS STACKS_MASK 
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) AS hex1
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) AS hex2
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) AS hex3
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) AS hex4
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) AS hex5
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) AS hex6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '1111'
			  END AS bin1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '1111'
			  END AS bin2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '1111'
			  END AS bin3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '1111'
			  END AS bin4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '1111'
			  END AS bin5	  
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '1111'
			  END AS bin6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '4'
			  END AS term1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '4'
			  END AS term2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '4'
			  END AS term3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '4'
			  END AS term4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '4'
			  END AS term5
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '4'
			  END AS term6
			FROM max_stacks ms
		LEFT JOIN td_row r ON r.BLOCK_ID = ms.block_id
		--ORDER BY 
		--	ms.name
	), blocks_and_rows AS (
		SELECT
			btp.block_id
			, Btp.block_name
			, btp.row_id
			, btp.row_name
			, btp.num_tiers
			, btp.max_stacks
			, substr(bin1 || bin2 || bin3 || bin4 || bin5 || bin6,1,btp.max_stacks) AS flags
			, btp.term1 + btp.term2 + btp.term3 + btp.term4 + btp.term5 + btp.term6 AS num_stacks
		FROM blob_to_bin_pieces btp
	), blocks_rows_stack_indexes (block_id, block_name, row_id, row_name, num_tiers, max_stacks, flags, num_stacks, stack_index) AS (
		SELECT 
			bnr.block_id
			, bnr.block_name
			, bnr.row_id
			, bnr.row_name
			, bnr.num_tiers
			, bnr.max_stacks
			, bnr.flags
			, bnr.num_stacks
			, 0 AS stack_index
		FROM blocks_and_rows bnr
		UNION ALL
		SELECT
			block_id
			, block_name
			, row_id
			, row_name
			, num_tiers
			, max_stacks
			, flags
			, num_stacks
			, stack_index + 1
		FROM blocks_rows_stack_indexes
		WHERE stack_index < max_stacks - 1
	), blocks_rows_stacks AS (
		SELECT 
			brsi.*
			, substr (brsi.flags,brsi.stack_index+1,1) AS stack_flag
		FROM blocks_rows_stack_indexes brsi
/*		ORDER BY 
			brsi.block_name
			, brsi.row_name
			, brsi.stack_index
*/	), blocks_rows_stacks_tiers (block_id, block_name, row_id, row_name, num_tiers, max_stacks, flags, stack_flag, stack_index, tier_index) AS (
        SELECT 
        	brs.block_id
        	, brs.block_name
        	, brs.row_id
        	, brs.row_name
        	, brs.num_tiers
        	, brs.max_stacks
        	, brs.flags
        	, brs.stack_flag
        	, brs.stack_index
        	, 1 AS tier_index 
        FROM blocks_rows_stacks brs
        UNION ALL
        SELECT 
        	brst.block_id
        	, brst.block_name
        	, brst.row_id
        	, brst.row_name
        	, brst.num_tiers
        	, brst.max_stacks
        	, brst.flags
        	, brst.stack_flag
        	, brst.stack_index
			, brst.tier_index + 1
		FROM blocks_rows_stacks_tiers brst 
        WHERE tier_index < num_tiers
    ), deleted_fine_spots AS (
		SELECT 
			brst.block_id
			, brst.row_id
			, brst.stack_index
			, brst.tier_index
		--	count(*)
		/*	brst.block_id
			, brst.block_name
			, brst.row_id
			, brst.row_name
			, brst.num_tiers
			, brst.max_stacks
			, brst.flags
			, brst.stack_flag
			, brst.stack_index
			, brst.tier_index
		*/FROM blocks_rows_stacks_tiers brst
		WHERE
			brst.stack_flag = '0'
		/*ORDER BY 
			brst.block_id
			, brst.row_id
			, brst.stack_index
			, brst.tier_index*/
	), disabled_space_entries AS (
		SELECT 
			ys.id
			, ys.BLOCK_ID 
			, tb.name AS block_name
			, ys.START_ROW_ID
			, tr.name AS start_row_name
			, tr.row_index AS start_row_index
			, ys.STOP_ROW_ID 
			, tr2.name AS stop_row_name
			, tr2.row_index AS stop_row_index
			, ys.START_STACK 
			, tsn.CUSTOM_NAME AS start_stack_name
			, ys.STOP_STACK 
			, tsn2.CUSTOM_NAME AS stop_stack_name
			, ys.NUM_TIERS AS disabled_tiers
		FROM YPDISABLED_SPACE ys 
		LEFT JOIN TD_BLOCK tb ON tb.Id = ys.BLOCK_ID 
		LEFT JOIN td_row tr ON tr.id = ys.START_ROW_ID 
		LEFT JOIN td_row tr2 ON tr2.id = ys.stop_row_id 
		LEFT JOIN TD_STACK_NAME tsn ON tsn.BLOCK_ID = tb.id AND tsn.STACK_INDEX = ys.START_STACK 
		LEFT JOIN TD_STACK_NAME tsn2 ON tsn2.BLOCK_ID = tb.id AND tsn2.STACK_INDEX = ys.STOP_STACK
		WHERE 
			NOT (ys.TYPE = '2') 
	), expanded_rows (id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers, row_index) AS (
        SELECT 
        	id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			start_row_index AS row_index 
        FROM disabled_space_entries
        UNION ALL
        SELECT 
			id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index + 1
		FROM expanded_rows 
        WHERE row_index < stop_row_index
	), added_num_tiers AS (
		SELECT 
			er.*
			, tr.num_tiers AS tiers_in_row
		FROM expanded_rows er
		LEFT JOIN td_row tr ON er.block_id = tr.block_id AND er.row_index = tr.row_index
	), expanded_stacks (id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers, 
			row_index, tiers_in_row, stack_index) AS (
        SELECT 
        	id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, start_stack AS stack_index
        FROM added_num_tiers
        UNION ALL
        SELECT 
			id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, stack_index + 1
		FROM expanded_stacks 
        WHERE stack_index < stop_stack
	), expanded_tiers (id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers, 
			row_index, tiers_in_row, stack_index, tier_index) AS (
        SELECT 
        	id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, stack_index, tiers_in_row AS tier_index
        FROM expanded_stacks
        UNION ALL
        SELECT 
			id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, stack_index, tier_index - 1
		FROM expanded_tiers 
        WHERE tier_index > tiers_in_row - disabled_tiers + 1
	), disabled_fine_spots AS (
		SELECT 
			et.block_id
			, tr.id AS row_id
			, et.stack_index
			, et.tier_index
		FROM expanded_tiers et
		LEFT JOIN td_row tr ON tr.block_id = et.block_id AND tr.row_index = et.row_index
		ORDER BY 
			block_id
			, row_id
			, stack_index
			, tier_index
	), unavailable_fine_spots AS (
		SELECT 
			DISTINCT block_id, row_id, stack_index, tier_index
		FROM (
			SELECT block_id, row_id, stack_index, tier_index FROM deleted_fine_spots
			UNION 
			SELECT block_id, row_id, stack_index, tier_index FROM disabled_fine_spots
		) combined_results
	)
SELECT count(*) FROM unavailable_fine_spots --10891 IN MIT UAT
;

--De-hacking the BLOB to binary string conversion
WITH 
	stacks_mask AS (
		SELECT
			tr.id
			, RAWTOHEX(DBMS_LOB.SUBSTR(tr.STACKS_MASK , 64, 1)) AS blobby
		FROM td_row tr
		LEFT JOIN td_block b ON b.id = tr.block_id
		WHERE NOT(b.TYPE = '4') --NO heaps
		--FETCH FIRST 2 ROWs only
	), parsed_double_bytes (id, char_index, double_byte, blobby) AS (
		SELECT
			id
			, 3 AS char_index
			, substr (blobby,1,2) AS double_byte
			, blobby
		FROM stacks_mask sm
		UNION ALL 
		SELECT
			id
			, char_index + 2 AS char_index
			, substr (blobby,char_index,2) AS double_byte
			, blobby
		FROM parsed_double_bytes
		WHERE char_index < LENGTH (blobby)
	), ordered_double_bytes AS (
		SELECT
			id
			, char_index - 2 AS char_index
			, substr (double_byte,2,1) || SUBSTR (double_byte,1,1) AS ordered_double_byte
		FROM parsed_double_bytes
		ORDER BY id, char_index
	), ordered_blob AS (
		SELECT
			id
			, listagg (ordered_double_byte) WITHIN GROUP (ORDER BY char_index) AS ordered_blobby
		FROM ordered_double_bytes
		GROUP BY id
	), parsed_hexes_rec (id, char_index, hex, ordered_blobby) AS (
		SELECT
			id
			, 2 AS char_index
			, substr (ordered_blobby,1,1) AS hex
			, ordered_blobby
		FROM ordered_blob
		UNION ALL 
		SELECT 
			id 
			, char_index + 1 AS char_index
			, substr (ordered_blobby,char_index,1) AS hex
			, ordered_blobby
		FROM parsed_hexes_rec
		WHERE char_index < length(ordered_blobby) + 1
	), parsed_hexes AS ( 
		SELECT 
			id 
			, char_index - 1 AS char_index
			, Hex 
		FROM parsed_hexes_rec
		ORDER BY id, char_index
	), hex_to_bin AS (	
		SELECT 
			id,
			char_index,
			hex,
			CASE 
				WHEN hex = '0' THEN '0000'
				WHEN hex = '1' THEN '1000'
				WHEN hex = '2' THEN '0100'
				WHEN hex = '3' THEN '1100'
				WHEN hex = '4' THEN '0010'
				WHEN hex = '5' THEN '1010'
				WHEN hex = '6' THEN '0110'
				WHEN hex = '7' THEN '1110'
				WHEN hex = '8' THEN '0001'
				WHEN hex = '9' THEN '1001'
				WHEN hex = 'A' THEN '0101'
				WHEN hex = 'B' THEN '1101'
				WHEN hex = 'C' THEN '0011'
				WHEN hex = 'D' THEN '1011'
				WHEN hex = 'E' THEN '0111'
				WHEN hex = 'F' THEN '1111'
			END AS binstr
		FROM parsed_hexes
	), binstr AS (
		SELECT
			id,
			listagg (htb.binstr) WITHIN GROUP (ORDER BY char_index) AS binary_string
		FROM hex_to_bin htb
		GROUP BY id
	), max_stacks AS (
		SELECT 
			tsn.block_id
			, b.name AS block_name
			, count(*) AS max_stacks --22 IS the largest value FOR MIT UAT, 22 digits OF bin IS six digits OF hex (5.5)
		FROM TD_STACK_NAME tsn 
		LEFT JOIN td_block b ON b.id = tsn.block_id
		WHERE 
			NOT (b.TYPE = '4') -- NO heaps
		GROUP BY 
			tsn.block_id
			, b.name
	), flags AS (
		SELECT 
			bs.id AS row_id
			, substr (bs.binary_string,0,ms.max_stacks) AS flags
		FROM binstr bs
		LEFT JOIN td_row r ON r.id = bs.id
		LEFT JOIN td_block b ON b.id = r.block_id
		LEFT JOIN max_stacks ms ON ms.block_id = b.id
	), stack_increments (row_id, flags, ch_index, stack_incr) AS (
		SELECT 
			flags.row_id
			, flags.flags
			, 2 AS ch_index
			, to_number(substr (flags,1,1)) AS stack_incr
		FROM flags
		UNION ALL
		SELECT 
			row_id
			, flags
			, ch_index + 1 AS ch_index
			, TO_NUMBER(SUBSTR(flags,ch_index,1)) AS stack_incr
		FROM stack_increments
		WHERE ch_index < LENGTH (flags) + 1
	), num_stacks AS (
		SELECT 
			si.row_id
			, sum(si.stack_incr) AS num_stacks
		FROM stack_increments si
		GROUP BY si.row_id, si.flags
	), indexed_stacks (block_id, row_id, stack_index, max_stacks) AS (
		SELECT 
			ms.block_id
			, r.id AS row_id
			, 0 AS stack_index
			, ms.max_stacks
		FROM max_stacks ms
		LEFT JOIN td_row r ON r.block_id = ms.block_id
		UNION ALL 
		SELECT 
			block_id
			, row_id
			, stack_index + 1 AS stack_index
			, max_stacks
		FROM indexed_stacks
		WHERE stack_index < max_stacks - 1
	), blocks_rows_stacks AS (
		SELECT
			ist.block_id
			, b.name AS block_name
			, ist.row_id
			, r.name AS row_name
			, r.num_tiers
			, ist.max_stacks
			, flags.flags
			, ns.num_stacks
			, ist.stack_index
			, substr(flags.flags,ist.stack_index+1,1) AS stack_flag
		FROM indexed_stacks ist
		LEFT JOIN flags ON flags.ROW_id = ist.row_id
		LEFT JOIN td_block b ON b.id = ist.block_id
		LEFT JOIN td_row r ON r.id = ist.row_id
		LEFT JOIN num_stacks ns ON ns.ROW_id = ist.ROW_id
		ORDER BY b.name, r.name, ist.stack_index	
	), blocks_rows_stacks_tiers (block_id, block_name, row_id, row_name, num_tiers, max_stacks, flags, stack_flag, stack_index, tier_index) AS (
        SELECT 
        	brs.block_id
        	, brs.block_name
        	, brs.row_id
        	, brs.row_name
        	, brs.num_tiers
        	, brs.max_stacks
        	, brs.flags
        	, brs.stack_flag
        	, brs.stack_index
        	, 1 AS tier_index 
        FROM blocks_rows_stacks brs
        UNION ALL
        SELECT 
        	brst.block_id
        	, brst.block_name
        	, brst.row_id
        	, brst.row_name
        	, brst.num_tiers
        	, brst.max_stacks
        	, brst.flags
        	, brst.stack_flag
        	, brst.stack_index
			, brst.tier_index + 1
		FROM blocks_rows_stacks_tiers brst 
        WHERE tier_index < num_tiers
	)
SELECT
	brst.block_id
	, brst.block_name
	, brst.row_id
	, brst.row_name
	, brst.num_tiers
	, brst.max_stacks
	, brst.flags
	, brst.stack_flag
	, brst.stack_index
	, brst.tier_index
FROM blocks_rows_stacks_tiers brst
ORDER BY
	brst.block_name
	, brst.row_name
	, brst.stack_index
	, brst.tier_index
; --just need TO count deleted AND disabled spaces now USING the de-hackified query

WITH 
	max_stacks AS (
		SELECT 
			tsn.block_id
			, b.name AS block_name
			, count(*) AS max_stacks --22 IS the largest value FOR MIT UAT, 22 digits OF bin IS six digits OF hex (5.5)
		FROM TD_STACK_NAME tsn 
		LEFT JOIN td_block b ON b.id = tsn.block_id
		WHERE 
			NOT (b.TYPE = '4') -- NO heaps
		GROUP BY 
			tsn.block_id
			, b.name
	), blob_to_bin_pieces AS (
		SELECT 
			ms.*
			, r.ID AS row_id
			, r.NAME AS row_name
			, r.num_tiers
		--	, (trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2 AS num_hex_chars
		--	, SUBSTR(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,(trunc(ms.max_stacks / 8) + CEIL(MOD(ms.max_stacks,8)/8)) * 2) AS STACKS_MASK 
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) AS hex1
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) AS hex2
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) AS hex3
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) AS hex4
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) AS hex5
			, substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) AS hex6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '1111'
			  END AS bin1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '1111'
			  END AS bin2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '1111'
			  END AS bin3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '1111'
			  END AS bin4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '1111'
			  END AS bin5	  
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1000'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '0100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '1100'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '0010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '1010'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '0110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '1110'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '0001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '1001'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '0101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '1101'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '0011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '1011'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '0111'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '1111'
			  END AS bin6
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),2,1) = 'F' THEN '4'
			  END AS term1
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),1,1) = 'F' THEN '4'
			  END AS term2
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),4,1) = 'F' THEN '4'
			  END AS term3
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),3,1) = 'F' THEN '4'
			  END AS term4
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),6,1) = 'F' THEN '4'
			  END AS term5
			, CASE 
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) IS NULL THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '0' THEN '0'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '1' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '2' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '3' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '4' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '5' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '6' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '7' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '8' THEN '1'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = '9' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'A' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'B' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'C' THEN '2'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'D' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'E' THEN '3'
				WHEN substr (RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),5,1) = 'F' THEN '4'
			  END AS term6
			FROM max_stacks ms
		LEFT JOIN td_row r ON r.BLOCK_ID = ms.block_id
		--ORDER BY 
		--	ms.name
	), blocks_and_rows AS (
		SELECT
			btp.block_id
			, Btp.block_name
			, btp.row_id
			, btp.row_name
			, btp.num_tiers
			, btp.max_stacks
			, substr(bin1 || bin2 || bin3 || bin4 || bin5 || bin6,1,btp.max_stacks) AS flags
			, btp.term1 + btp.term2 + btp.term3 + btp.term4 + btp.term5 + btp.term6 AS num_stacks
		FROM blob_to_bin_pieces btp
	), blocks_rows_stack_indexes (block_id, block_name, row_id, row_name, num_tiers, max_stacks, flags, num_stacks, stack_index) AS (
		SELECT 
			bnr.block_id
			, bnr.block_name
			, bnr.row_id
			, bnr.row_name
			, bnr.num_tiers
			, bnr.max_stacks
			, bnr.flags
			, bnr.num_stacks
			, 0 AS stack_index
		FROM blocks_and_rows bnr
		UNION ALL
		SELECT
			block_id
			, block_name
			, row_id
			, row_name
			, num_tiers
			, max_stacks
			, flags
			, num_stacks
			, stack_index + 1
		FROM blocks_rows_stack_indexes
		WHERE stack_index < max_stacks - 1
	), blocks_rows_stacks AS (
		SELECT 
			brsi.*
			, substr (brsi.flags,brsi.stack_index+1,1) AS stack_flag
		FROM blocks_rows_stack_indexes brsi
/*		ORDER BY 
			brsi.block_name
			, brsi.row_name
			, brsi.stack_index
*/	), blocks_rows_stacks_tiers (block_id, block_name, row_id, row_name, num_tiers, max_stacks, flags, stack_flag, stack_index, tier_index) AS (
        SELECT 
        	brs.block_id
        	, brs.block_name
        	, brs.row_id
        	, brs.row_name
        	, brs.num_tiers
        	, brs.max_stacks
        	, brs.flags
        	, brs.stack_flag
        	, brs.stack_index
        	, 1 AS tier_index 
        FROM blocks_rows_stacks brs
        UNION ALL
        SELECT 
        	brst.block_id
        	, brst.block_name
        	, brst.row_id
        	, brst.row_name
        	, brst.num_tiers
        	, brst.max_stacks
        	, brst.flags
        	, brst.stack_flag
        	, brst.stack_index
			, brst.tier_index + 1
		FROM blocks_rows_stacks_tiers brst 
        WHERE tier_index < num_tiers
    ), deleted_fine_spots AS (
		SELECT 
			brst.block_id
			, brst.row_id
			, brst.stack_index
			, brst.tier_index
		--	count(*)
		/*	brst.block_id
			, brst.block_name
			, brst.row_id
			, brst.row_name
			, brst.num_tiers
			, brst.max_stacks
			, brst.flags
			, brst.stack_flag
			, brst.stack_index
			, brst.tier_index
		*/FROM blocks_rows_stacks_tiers brst
		WHERE
			brst.stack_flag = '0'
		/*ORDER BY 
			brst.block_id
			, brst.row_id
			, brst.stack_index
			, brst.tier_index*/
	), disabled_space_entries AS (
		SELECT 
			ys.id
			, ys.BLOCK_ID 
			, tb.name AS block_name
			, ys.START_ROW_ID
			, tr.name AS start_row_name
			, tr.row_index AS start_row_index
			, ys.STOP_ROW_ID 
			, tr2.name AS stop_row_name
			, tr2.row_index AS stop_row_index
			, ys.START_STACK 
			, tsn.CUSTOM_NAME AS start_stack_name
			, ys.STOP_STACK 
			, tsn2.CUSTOM_NAME AS stop_stack_name
			, ys.NUM_TIERS AS disabled_tiers
		FROM YPDISABLED_SPACE ys 
		LEFT JOIN TD_BLOCK tb ON tb.Id = ys.BLOCK_ID 
		LEFT JOIN td_row tr ON tr.id = ys.START_ROW_ID 
		LEFT JOIN td_row tr2 ON tr2.id = ys.stop_row_id 
		LEFT JOIN TD_STACK_NAME tsn ON tsn.BLOCK_ID = tb.id AND tsn.STACK_INDEX = ys.START_STACK 
		LEFT JOIN TD_STACK_NAME tsn2 ON tsn2.BLOCK_ID = tb.id AND tsn2.STACK_INDEX = ys.STOP_STACK
		WHERE 
			NOT (ys.TYPE = '2') 
	), expanded_rows (id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers, row_index) AS (
        SELECT 
        	id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			start_row_index AS row_index 
        FROM disabled_space_entries
        UNION ALL
        SELECT 
			id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index + 1
		FROM expanded_rows 
        WHERE row_index < stop_row_index
	), added_num_tiers AS (
		SELECT 
			er.*
			, tr.num_tiers AS tiers_in_row
		FROM expanded_rows er
		LEFT JOIN td_row tr ON er.block_id = tr.block_id AND er.row_index = tr.row_index
	), expanded_stacks (id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers, 
			row_index, tiers_in_row, stack_index) AS (
        SELECT 
        	id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, start_stack AS stack_index
        FROM added_num_tiers
        UNION ALL
        SELECT 
			id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, stack_index + 1
		FROM expanded_stacks 
        WHERE stack_index < stop_stack
	), expanded_tiers (id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers, 
			row_index, tiers_in_row, stack_index, tier_index) AS (
        SELECT 
        	id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, stack_index, tiers_in_row AS tier_index
        FROM expanded_stacks
        UNION ALL
        SELECT 
			id, block_id, block_name, start_row_id, start_row_name, start_row_index, 
			stop_row_id, stop_row_name, stop_row_index, start_stack, start_stack_name, stop_stack, stop_stack_name, disabled_tiers,
			row_index, tiers_in_row, stack_index, tier_index - 1
		FROM expanded_tiers 
        WHERE tier_index > tiers_in_row - disabled_tiers + 1
	), disabled_fine_spots AS (
		SELECT 
			et.block_id
			, tr.id AS row_id
			, et.stack_index
			, et.tier_index
		FROM expanded_tiers et
		LEFT JOIN td_row tr ON tr.block_id = et.block_id AND tr.row_index = et.row_index
		ORDER BY 
			block_id
			, row_id
			, stack_index
			, tier_index
	), unavailable_fine_spots AS (
		SELECT 
			DISTINCT block_id, row_id, stack_index, tier_index
		FROM (
			SELECT block_id, row_id, stack_index, tier_index FROM deleted_fine_spots
			UNION 
			SELECT block_id, row_id, stack_index, tier_index FROM disabled_fine_spots
		) combined_results
	)
SELECT count(*) FROM unavailable_fine_spots --10891 IN MIT UAT
;
