/*
 * Looking for records in equipment, equipment_history, and/or equipment_uses where the fields differ to ask David DeVisser 	
 * what the best single source of truth is. These fields are in common to the tables:
 * equipment:			ctr_nbr,									equse_gkey,									pos_id, 													sztp_id
 * equipment_uses: 		eq_nbr,		category,	discharge_port_id1,				gross_weight,	haz_imdg_class,			seal_nbr1 and 2,	so_vsl_id,	so_voy_nbr,	status,				required_temp,	transship
 * equipment_history: 	eq_nbr,		category,	discharge_port_id1,	equse_gkey, gross_weight,	haz_class,		pos_id,	seal_nbr1 and 2,	vsl_id,		voyage_id,	status,	sztp_id,	temp_required,	transship
 */

SELECT * FROM equipment FETCH FIRST 100 ROWS ONLY;

WITH eh_recs AS (
	SELECT
		eh.*
		, row_number() OVER (PARTITION BY eh.equse_gkey ORDER BY eh.posted DESC) as rn
	FROM equipment_uses uses
	LEFT JOIN equipment_history eh ON uses.gkey = eh.equse_gkey
	WHERE eh.equse_gkey IS NOT NULL AND eh.eq_class = 'CTR' AND uses.eq_class = 'CTR'
)
, most_recent_eh_rec AS (
	SELECT *
	FROM eh_recs
	WHERE rn = 1
)
SELECT
	uses.gkey AS uses_gkey
	, eq.equse_gkey AS equip_gkey
	, eh.equse_gkey AS ehist_gkey
	, CASE
		WHEN (uses.eq_nbr != eq.ctr_nbr OR uses.eq_nbr != eh.eq_nbr OR eq.ctr_nbr != eh.eq_nbr) THEN 'Container Number'
		WHEN uses.category != eh.category THEN 'Category'
		WHEN uses.discharge_port_id1 != eh.discharge_port_id1 THEN 'Discharge Port ID1'
		WHEN uses.gross_weight != eh.gross_weight THEN 'Gross Weight'
		WHEN eq.pos_id != eh.pos_id THEN 'Position ID'
		WHEN (uses.seal_nbr1 != eh.seal_nbr1 OR uses.seal_nbr2 != eh.seal_nbr2) THEN 'Seal Numbers'
		WHEN uses.status != eh.status THEN 'Status'
		WHEN eq.sztp_id != eh.sztp_id THEN 'Size/Type ID'
		WHEN uses.required_temp != eh.temp_required THEN 'Temperature Required'
		WHEN uses.transship != eh.transship THEN 'Transship'
	END AS mismatch_type
	, uses.eq_nbr AS uses_ctr_nbr
	, eq.ctr_nbr AS equip_ctr_nbr
	, eh.eq_nbr AS ehist_ctr_nbr
	, uses.category AS uses_category
	, eh.category AS ehist_category
	, uses.discharge_port_id1 AS uses_disch_port
	, eh.discharge_port_id1 AS ehist_disch_port
	, uses.gross_weight AS uses_gr_weight
	, eh.gross_weight AS ehist_gr_weight
	, eq.pos_id AS equip_pos_id
	, eh.pos_id AS ehist_pos_id
	, uses.seal_nbr1 AS uses_seal_1
	, eh.seal_nbr1 AS ehist_seal_1
	, uses.seal_nbr2 AS uses_seal_2
	, eh.seal_nbr2 AS ehist_seal_2
	, uses.status AS uses_status
	, eh.status AS ehist_status
	, eq.sztp_id AS equip_sztp
	, eh.sztp_id AS ehist_sztp
	, uses.required_temp AS uses_temp_req
	, eh.temp_required AS ehist_temp_req
	, uses.transship AS uses_transship
	, eh.transship AS ehist_transship
FROM equipment_uses uses
LEFT JOIN equipment eq ON uses.gkey = eq.equse_gkey
LEFT JOIN most_recent_eh_rec eh ON uses.gkey = eh.equse_gkey
WHERE
	eq.equse_gkey IS NOT NULL
	AND eh.equse_gkey IS NOT NULL
	AND uses.eq_class = 'CTR'
	AND eq.sztp_class = 'CTR'
	AND (
		(uses.eq_nbr != eq.ctr_nbr OR uses.eq_nbr != eh.eq_nbr OR eq.ctr_nbr != eh.eq_nbr)
		OR uses.category != eh.category
		OR uses.discharge_port_id1 != eh.discharge_port_id1
		OR uses.gross_weight != eh.gross_weight
		OR eq.pos_id != eh.pos_id
		OR (uses.seal_nbr1 != eh.seal_nbr1 OR uses.seal_nbr2 != eh.seal_nbr2)
		OR uses.status != eh.status
		OR eq.sztp_id != eh.sztp_id
		OR uses.required_temp != eh.temp_required 
		OR uses.transship != eh.transship
	)
ORDER BY mismatch_type
;

SELECT count(*) FROM equipment_uses; --870,260