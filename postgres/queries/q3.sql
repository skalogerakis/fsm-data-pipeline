-- DONE. Find all nodes within 2 hops of Node 94.

-- First find all those with one hop
WITH first_hop AS (
  SELECT adj_node AS hop_node
  FROM NETWORK
  WHERE node = 94
),
-- Second hop
second_hop AS (
  SELECT adj_node AS hop_node
  FROM NETWORK
  WHERE node IN (SELECT hop_node FROM first_hop)
)

SELECT DISTINCT hop_node FROM first_hop
UNION
SELECT DISTINCT hop_node FROM second_hop;