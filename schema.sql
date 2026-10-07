CREATE DATABASE IF NOT EXISTS f1;
USE f1;

CREATE TABLE teams (
  team_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE drivers (
  driver_id INT AUTO_INCREMENT PRIMARY KEY,
  code CHAR(3) NOT NULL UNIQUE,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL
);

CREATE TABLE races (
  race_id INT AUTO_INCREMENT PRIMARY KEY,
  season SMALLINT NOT NULL,
  round TINYINT NOT NULL,
  name VARCHAR(100) NOT NULL,
  race_date DATE,
  UNIQUE (season, round)
);

CREATE TABLE sessions (
  session_id INT AUTO_INCREMENT PRIMARY KEY,
  race_id INT NOT NULL,
  session_type ENUM('FP1','FP2','FP3','Q','SPRINT','R') NOT NULL,
  UNIQUE (race_id, session_type),
  FOREIGN KEY (race_id) REFERENCES races(race_id)
);

CREATE TABLE entries (
  race_id INT NOT NULL,
  driver_id INT NOT NULL,
  team_id INT NOT NULL,
  PRIMARY KEY (race_id, driver_id),
  FOREIGN KEY (race_id) REFERENCES races(race_id),
  FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
  FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

CREATE TABLE laps (
  lap_id INT AUTO_INCREMENT PRIMARY KEY,
  session_id INT NOT NULL,
  driver_id INT NOT NULL,
  lap_number SMALLINT NOT NULL,
  lap_time_ms INT NULL,
  compound ENUM('SOFT','MEDIUM','HARD','INTERMEDIATE','WET') NULL,
  tyre_age SMALLINT NULL,
  stint_no TINYINT NULL,
  UNIQUE (session_id, driver_id, lap_number),
  FOREIGN KEY (session_id) REFERENCES sessions(session_id),
  FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);

CREATE TABLE pit_stops (
  pit_id INT AUTO_INCREMENT PRIMARY KEY,
  session_id INT NOT NULL,
  driver_id INT NOT NULL,
  stop_no TINYINT NOT NULL,
  lap_number SMALLINT NOT NULL,
  duration_ms INT NULL,
  UNIQUE (session_id, driver_id, stop_no),
  FOREIGN KEY (session_id) REFERENCES sessions(session_id),
  FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);