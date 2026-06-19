-- KWave Core Schema (PostgreSQL)

CREATE TABLE IF NOT EXISTS users (
  identifier VARCHAR(60) NOT NULL,
  ssn VARCHAR(11) NOT NULL,
  accounts TEXT DEFAULT NULL,
  "group" VARCHAR(50) DEFAULT 'user',
  inventory TEXT DEFAULT NULL,
  job VARCHAR(20) DEFAULT 'unemployed',
  job_grade INTEGER DEFAULT 0,
  loadout TEXT DEFAULT NULL,
  metadata TEXT DEFAULT NULL,
  position TEXT DEFAULT NULL,

  PRIMARY KEY (identifier),
  CONSTRAINT unique_ssn UNIQUE (ssn)
);

CREATE TABLE IF NOT EXISTS items (
  name VARCHAR(50) NOT NULL,
  label VARCHAR(50) NOT NULL,
  weight INTEGER NOT NULL DEFAULT 1,
  rare SMALLINT NOT NULL DEFAULT 0,
  can_remove SMALLINT NOT NULL DEFAULT 1,

  PRIMARY KEY (name)
);

CREATE TABLE IF NOT EXISTS job_grades (
  id SERIAL PRIMARY KEY,
  job_name VARCHAR(50) DEFAULT NULL,
  grade INTEGER NOT NULL,
  name VARCHAR(50) NOT NULL,
  label VARCHAR(50) NOT NULL,
  salary INTEGER NOT NULL,
  skin_male TEXT NOT NULL,
  skin_female TEXT NOT NULL
);

INSERT INTO job_grades (id, job_name, grade, name, label, salary, skin_male, skin_female)
VALUES (1, 'unemployed', 0, 'unemployed', 'Unemployed', 200, '{}', '{}')
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('job_grades', 'id'), COALESCE(MAX(id), 1)) FROM job_grades;

CREATE TABLE IF NOT EXISTS jobs (
  name VARCHAR(50) NOT NULL,
  label VARCHAR(50) DEFAULT NULL,

  PRIMARY KEY (name)
);

INSERT INTO jobs (name, label)
VALUES ('unemployed', 'Unemployed')
ON CONFLICT (name) DO NOTHING;
