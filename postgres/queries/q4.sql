-- DONE.Find nodes within 2 hops of Node 94 with at least 10 failed visits during 2020

WITH two_hops AS (
  -- Nodes within 2 hops of Node 94
  SELECT adj_node
  FROM network
  WHERE node = 94
  UNION
  SELECT n2.adj_node
  FROM network n1
  JOIN network n2 ON n1.adj_node = n2.node
  WHERE n1.node = 94
)
SELECT node_id
FROM visits
WHERE outcome = 'FAIL'
  AND visit_date BETWEEN '2020-01-01' AND '2020-12-31'
  AND node_id IN (SELECT adj_node FROM two_hops)
GROUP BY node_id
HAVING COUNT(DISTINCT task_id) >= 10;
