
-- CREATE VISIT TABLE
CREATE TABLE IF NOT EXISTS VISITS (
    task_id INT,
    node_id INT,
    visit_id INT,
    visit_date TIMESTAMP,
    original_reported_date TIMESTAMP,
    node_age INT,
    node_type INT,
    task_type INT,
    engineer_skill_level INT,
    engineer_note INT,
    outcome VARCHAR(200)
);

-- CREATE NETWORK TABLE
CREATE TABLE IF NOT EXISTS NETWORK (
    node INT,
    adj_node INT
);

