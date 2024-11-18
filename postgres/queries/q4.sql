-- Find all the nodes that are within 2 hops of Node 94 and have also been associated with at least 10 failed visits during 2020
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

SELECT h.hop_node
FROM two_hops h
JOIN VISITS v ON h.hop_node = v.node_id
WHERE v.outcome = 'FAIL'
  AND v.visit_date BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY h.hop_node
HAVING COUNT(*) >= 10;
