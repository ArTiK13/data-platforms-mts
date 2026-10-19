SET hive.compute.query.using.stats=false;
SHOW PARTITIONS hw3.events;
SELECT event_id, user_id, event_type, dt FROM hw3.events ORDER BY event_id;
