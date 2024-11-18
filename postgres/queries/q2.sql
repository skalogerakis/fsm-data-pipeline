-- Find all tasks that were successfully completed after 2 visits and the 
-- 2 engineer notes left after the visits include at least 5 words in common

WITH success_visits AS (
  SELECT task_id, visit_id, engineer_note
  FROM visits
  WHERE outcome = 'SUCCESS'
  AND visit_id = 2 
)

SELECT s1.task_id
FROM success_visits s1
JOIN visits v1 ON v1.task_id = s1.task_id
GROUP BY s1.task_id
HAVING COUNT(DISTINCT s1.engineer_note) >= 5;
