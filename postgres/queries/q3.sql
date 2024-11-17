-- Find all nodes within 2 hops of Node 94.

-- First hop
WITH first_hop AS (
  SELECT connected_node AS node
  FROM networks
  WHERE node_id = '94'
),
-- Second hop
second_hop AS (
  SELECT connected_node AS node
  FROM networks
  WHERE node_id IN (SELECT node FROM first_hop)
)
SELECT DISTINCT node FROM first_hop
UNION
SELECT DISTINCT node FROM second_hop;