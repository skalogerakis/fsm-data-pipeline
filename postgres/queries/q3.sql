-- Find all the nodes within 2 hops of Node 94

SELECT DISTINCT n1.adj_node AS hop_node
FROM network n1
WHERE n1.node = 94
UNION
SELECT DISTINCT n2.adj_node AS hop_node
FROM network n1
JOIN network n2 ON n1.adj_node = n2.node
WHERE n1.node = 94
