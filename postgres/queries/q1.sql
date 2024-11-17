-- Find all successful visits by engineers with a skill level higher than 2, 
-- took place between 1/1/2020 and 31/3/2020, following at least 2 failed attempts.

SELECT DISTINCT v1.task_id, v1.node_id, v1.visit_date, v1.engineer_skill_level
FROM visits v1
WHERE v1.outcome = 'SUCCESS'
  AND v1.engineer_skill_level > 2
  AND v1.visit_date BETWEEN '2020-01-01' AND '2020-03-31'
  AND (
    SELECT COUNT(DISTINCT v2.visit_id)
    FROM visits v2
    WHERE v2.task_id = v1.task_id
      AND v2.outcome = 'FAIL'
  ) >= 2;
