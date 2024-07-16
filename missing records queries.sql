/* zlo: Oracle, equipment_jn 2024 */
SELECT
    trunc(eh.posted) AS day
    , count(*) as total_rows
FROM equipment_history eh
WHERE trunc(eh.posted) between to_date('2024-01-01', 'YYYY-MM-DD') and to_date('2024-06-30', 'YYYY-MM-DD')
group by trunc(eh.posted)
order by 1 desc;

select
    trunc(vv.created) as jn_datetime
    , count(*) as total_rows
from vessel_visits vv
where trunc(vv.created) between to_date('2024-01-01','YYYY-MM-DD') and to_date('2024-06-30','YYYY-MM-DD')
group by trunc(vv.created)
order by 1 desc;