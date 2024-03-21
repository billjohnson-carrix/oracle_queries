SELECT 
	* 
FROM truck_visits_jn jn
WHERE 
	(jn.jn_operation = 'INS' OR jn.JN_OPERATION = 'UPD') AND 
	jn.entered IS NOT NULL AND jn.exited IS NOT NULL
	AND jn.exited BETWEEN to_date('2022-01-01','YYYY-MM-DD') AND to_date('2023-12-31','YYYY-MM-DD')
	--AND jn.trk_id = '679128PA'
ORDER BY 
	jn.trk_id
	, jn.JN_DATETIME 
FETCH FIRST 20 ROWS ONLY 
;

SELECT jn.jn_operation, count(*) FROM truck_visits_jn jn GROUP BY jn.jn_operation;

SELECT * FROM truck_visits_jn WHERE gkey = '8816364' ORDER BY jn_datetime;

SELECT creator, count(*) FROM truck_visits_jn WHERE NOT(jn_operation='DEL') GROUP BY creator ORDER BY 2 desc;
SELECT jn_appln, count(*) FROM truck_visits_jn WHERE NOT(jn_operation='DEL') GROUP BY jn_appln ORDER BY 2 DESC;

SELECT * FROM jn_appln FETCH FIRST 20 ROWS ONLY ;

SELECT jn_oracle_user, jn_appln, count(*)
  FROM truck_visits_jn
 WHERE NOT (jn_operation = 'DEL')
 GROUP BY jn_oracle_user, jn_appln
 ORDER BY 1,2 DESC;