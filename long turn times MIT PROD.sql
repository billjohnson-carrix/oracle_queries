WITH long_turn_time_visits as(
	SELECT
		*
	FROM truck_visits tv
	WHERE (tv.exited - tv.entered) * 24 * 60 > 600
		AND tv.entered > to_date ('2024-06-01','YYYY-MM-DD')
		AND tv.entered < to_date ('2024-07-01','YYYY-MM-DD')
)
SELECT
	gt.tv_gkey
	, gt.ctr_nbr
	, ltt.entered
	, ltt.exited
	, (ltt.exited - ltt.entered) * 24 * 60 AS minutes
	, gt.*
	, ltt.*
FROM gate_transactions gt
INNER JOIN long_turn_time_visits ltt ON
	ltt.gkey = gt.tv_gkey
ORDER BY gt.tv_gkey
;