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
			REGEXP_REPLACE(RAWTOHEX(DBMS_LOB.SUBSTR(STACKS_MASK , 64, 1)),'0+$') AS STACKS_MASK 
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
	)
SELECT 
	st.*
	, stack_term1 + stack_term2 + stack_term3 + stack_term4 + stack_term5 + stack_term6 AS num_stacks
FROM stack_terms st
;

SELECT 
	TO_number(HEXTORAW('3F'))
FROM dual 
;

SELECT TO_CHAR(15, 'FMX') AS hexadecimal_number FROM dual;
SELECT TO_NUMBER('3F', 'XX') AS binary_number FROM dual;
SELECT LPAD(TO_NUMBER('3F', 'XXXXXX') - 0, 6, '0') AS binary_number FROM dual;
SELECT LPAD(
TO_BINARY(TO_NUMBER('3F', 'XX')), 6, '0') AS binary_number FROM dual;
SELECT TO_NUMBER('3F', 'XX') AS binary_number FROM dual;
SELECT TO_BINARY_DOUBLE(63) FROM dual; 

