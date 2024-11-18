--Find all the nodes that are within 2 hops of Node 94 and have been associated with at least 1 visit 
-- that took place between 1/3/2020 and 31/3/2020 and for which the visiting engineer’s note included the token ‘126’

WITH two_hops AS (
  SELECT DISTINCT n1.adj_node AS hop_node
  FROM network n1
  WHERE n1.node = 94
  UNION
  SELECT DISTINCT n2.adj_node AS hop_node
  FROM network n1
  JOIN network n2 ON n1.adj_node = n2.node
  WHERE n1.node = 94
)
SELECT DISTINCT h.hop_node
FROM two_hops h
JOIN VISITS v ON h.hop_node = v.node_id
WHERE v.visit_date BETWEEN '2020-03-01' AND '2020-03-31'
  AND v.engineer_note = 126;