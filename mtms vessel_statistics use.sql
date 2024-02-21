SELECT EXTRACT (MONTH FROM vs.created) AS MONTH, count(*) FROM VESSEL_STATISTICS vs 
WHERE EXTRACT (YEAR FROM vs.CREATED)=2023
GROUP BY EXTRACT (MONTH FROM vs.created);