-- Find all tasks successfully completed after exactly 2 visits, 
-- where the engineer notes from both visits include at least 5 words in common.

WITH task_visits AS (
  SELECT task_id, visit_id, engineer_note
  FROM visits
  WHERE outcome = 'SUCCESS'
)
SELECT t1.task_id
FROM task_visits t1
JOIN task_visits t2
  ON t1.task_id = t2.task_id
  AND t1.visit_id < t2.visit_id -- To avoid self-join duplicates
GROUP BY t1.task_id
HAVING COUNT(DISTINCT t1.engineer_note) >= 5;