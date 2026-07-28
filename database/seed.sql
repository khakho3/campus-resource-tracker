-- Idempotent GCTU Library demo data
USE campus_resource_tracker;

INSERT INTO libraries (
  name,
  is_open,
  opening_time,
  closing_time,
  motion_detected
)
VALUES ('GCTU Library', TRUE, '08:00:00', '20:00:00', TRUE)
ON DUPLICATE KEY UPDATE
  is_open = VALUES(is_open),
  opening_time = VALUES(opening_time),
  closing_time = VALUES(closing_time),
  motion_detected = VALUES(motion_detected);

INSERT INTO seats (code, is_occupied, last_distance_cm)
VALUES
  ('A1', TRUE, NULL),
  ('A2', FALSE, NULL)
ON DUPLICATE KEY UPDATE
  is_occupied = VALUES(is_occupied),
  last_distance_cm = VALUES(last_distance_cm);

INSERT INTO staff (
  staff_code,
  name,
  rfid_uid,
  is_present,
  last_scanned_at
)
VALUES (
  'STAFF-001',
  'Demo Library Staff',
  'DEMO-RFID-001',
  TRUE,
  NULL
)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  rfid_uid = VALUES(rfid_uid),
  is_present = VALUES(is_present),
  last_scanned_at = VALUES(last_scanned_at);
