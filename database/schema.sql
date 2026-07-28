-- Campus Resource Tracker - MySQL 8 schema
CREATE DATABASE IF NOT EXISTS campus_resource_tracker
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE campus_resource_tracker;

CREATE TABLE IF NOT EXISTS libraries (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  is_open BOOLEAN NOT NULL DEFAULT TRUE,
  opening_time TIME NOT NULL,
  closing_time TIME NOT NULL,
  motion_detected BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_libraries_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS seats (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(20) NOT NULL,
  is_occupied BOOLEAN NOT NULL DEFAULT FALSE,
  last_distance_cm DOUBLE NULL,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
    ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_seats_code (code),
  KEY ix_seats_code (code),
  CONSTRAINT chk_seats_distance
    CHECK (last_distance_cm IS NULL OR last_distance_cm BETWEEN 0 AND 1000)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS staff (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  staff_code VARCHAR(40) NOT NULL,
  name VARCHAR(120) NOT NULL,
  rfid_uid VARCHAR(120) NOT NULL,
  is_present BOOLEAN NOT NULL DEFAULT FALSE,
  last_scanned_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_staff_staff_code (staff_code),
  UNIQUE KEY uq_staff_rfid_uid (rfid_uid),
  KEY ix_staff_staff_code (staff_code),
  KEY ix_staff_rfid_uid (rfid_uid)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sensor_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  device_id VARCHAR(120) NOT NULL,
  event_type VARCHAR(60) NOT NULL,
  payload JSON NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_sensor_events_device_id (device_id),
  KEY ix_sensor_events_event_type (event_type),
  KEY ix_sensor_events_created_at (created_at)
) ENGINE=InnoDB;
