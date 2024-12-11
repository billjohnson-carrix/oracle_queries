SELECT count(*)
FROM truck_visits
WHERE trunc(exited) BETWEEN
	to_date('2024-11-01', 'YYYY-MM-DD') AND to_date('2024-11-30', 'YYYY-MM-DD')
	AND entered IS NOT NULL
	AND exited IS NOT NULL
; --41,754

WITH visits AS (
	SELECT gkey, trk_id, entered, exited,
		(exited - entered) * 24 * 60 AS turn_time_minutes
	FROM truck_visits
	WHERE trunc(exited) BETWEEN
		to_date('2024-11-01', 'YYYY-MM-DD') AND to_date('2024-11-30', 'YYYY-MM-DD')
		AND entered IS NOT NULL
		AND exited IS NOT NULL
)
SELECT avg(turn_time_minutes) AS avg_turn_time_minutes FROM visits
; --222.1 minutes

WITH visits AS (
	SELECT gkey, trk_id, entered, exited,
		(exited - entered) * 24 * 60 AS turn_time_minutes
	FROM truck_visits
	WHERE trunc(exited) BETWEEN
		to_date('2024-11-01', 'YYYY-MM-DD') AND to_date('2024-11-30', 'YYYY-MM-DD')
		AND entered IS NOT NULL
		AND exited IS NOT NULL
)
SELECT count(*)
FROM visits
WHERE turn_time_minutes > 90
; --6,046 OR 14.5%

WITH visits AS (
	SELECT gkey, trk_id, entered, exited,
		(exited - entered) * 24 * 60 AS turn_time_minutes
	FROM truck_visits
	WHERE trunc(exited) BETWEEN
		to_date('2024-11-01', 'YYYY-MM-DD') AND to_date('2024-11-30', 'YYYY-MM-DD')
		AND entered IS NOT NULL
		AND exited IS NOT NULL
)
SELECT count(*)
FROM visits
WHERE turn_time_minutes > 1440 -- OVER a day
; --1,735 OR 4.2%

WITH visits AS (
	SELECT gkey AS visits_gkey, trk_id, entered, exited,
		(exited - entered) * 24 * 60 AS turn_time_minutes
	FROM truck_visits
	WHERE trunc(exited) BETWEEN
		to_date('2024-11-01', 'YYYY-MM-DD') AND to_date('2024-11-30', 'YYYY-MM-DD')
		AND entered IS NOT NULL
		AND exited IS NOT NULL
), transactions AS (
	SELECT gkey AS transactions_gkey, ctr_nbr, tran_status, line_id, wtask_id, category, status, tv_gkey
	FROM gate_transactions
)
, joined AS (
	SELECT visits.*, transactions.*
	FROM visits
	LEFT JOIN transactions ON visits.visits_gkey = transactions.tv_gkey
)
SELECT *
FROM joined
WHERE turn_time_minutes > 90
ORDER BY turn_time_minutes desc, ctr_nbr desc
;