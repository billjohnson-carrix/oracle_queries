SELECT
	avg (sysdate - eq.yard_date) AS avg_dwell
FROM equipment eq
LEFT JOIN equipment_uses uses ON
	eq.equse_gkey = uses.gkey
WHERE
	eq.loc_type = 'Y'
	AND uses.status = 'E'
	AND uses.category = 'I'
	AND uses.transship IS NULL
	-- 180 day cutoff
	AND eq.yard_date > to_date('2024-11-14', 'YYYY-MM-DD')
; -- 38.536 days