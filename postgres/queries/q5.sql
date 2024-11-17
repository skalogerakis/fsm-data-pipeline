-- Find nodes within 2 hops of Node 94 associated with at least one visit between 1/3/2020 and 31/3/2020, where the engineer’s note included the token ‘126’.

WITH two_hops AS (
  -- Nodes within 2 hops of Node 94
  SELECT connected_node
  FROM networks
  WHERE node_id = '94'
  UNION
  SELECT n2.connected_node
  FROM networks n1
  JOIN networks n2 ON n1.connected_node = n2.node_id
  WHERE n1.node_id = '94'
)
SELECT DISTINCT node_id
FROM visits
WHERE node_id IN (SELECT connected_node FROM two_hops)
  AND visit_date BETWEEN '2020-03-01' AND '2020-03-31'
  AND engineer_note = 126;