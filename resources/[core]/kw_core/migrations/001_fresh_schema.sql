-- KWave Fresh Schema — Migration 001
-- Safe to run on existing DB: uses IF NOT EXISTS and IF EXISTS guards

-- ─── Core Users Table ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    identifier    VARCHAR(60)  UNIQUE NOT NULL,
    ssn           VARCHAR(11)  DEFAULT '',
    accounts      JSONB        NOT NULL DEFAULT '{}',
    job           VARCHAR(50)  NOT NULL DEFAULT 'unemployed',
    job_grade     INTEGER      NOT NULL DEFAULT 0,
    "group"       VARCHAR(50)  NOT NULL DEFAULT 'user',
    position      JSONB        DEFAULT NULL,
    inventory     JSONB        DEFAULT NULL,
    loadout       JSONB        DEFAULT NULL,
    skin          JSONB        DEFAULT NULL,
    metadata      JSONB        NOT NULL DEFAULT '{}',
    firstname     VARCHAR(50)  DEFAULT NULL,
    lastname      VARCHAR(50)  DEFAULT NULL,
    dateofbirth   VARCHAR(10)  DEFAULT NULL,
    sex           VARCHAR(1)   DEFAULT NULL,
    height        INTEGER      DEFAULT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Ensure JSONB types (safe on fresh DB, also fixes any old TEXT columns)
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'accounts'
        AND data_type = 'text'
    ) THEN
        ALTER TABLE users
            ALTER COLUMN accounts    TYPE JSONB USING accounts::JSONB,
            ALTER COLUMN metadata    TYPE JSONB USING COALESCE(NULLIF(metadata,''),'{}')::JSONB,
            ALTER COLUMN inventory   TYPE JSONB USING COALESCE(NULLIF(inventory,''),'null')::JSONB,
            ALTER COLUMN loadout     TYPE JSONB USING COALESCE(NULLIF(loadout,''),'null')::JSONB,
            ALTER COLUMN skin        TYPE JSONB USING COALESCE(NULLIF(skin,''),'null')::JSONB,
            ALTER COLUMN position    TYPE JSONB USING COALESCE(NULLIF(position,''),'null')::JSONB;
    END IF;
END $$;

-- Index for fast identifier lookups
CREATE INDEX IF NOT EXISTS idx_users_identifier ON users (identifier);

-- ─── Jobs Table ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS jobs (
    id        SERIAL       PRIMARY KEY,
    name      VARCHAR(50)  UNIQUE NOT NULL,
    label     VARCHAR(100) NOT NULL DEFAULT '',
    type      VARCHAR(50)  NOT NULL DEFAULT 'job'
);

CREATE TABLE IF NOT EXISTS job_grades (
    id          SERIAL       PRIMARY KEY,
    job_name    VARCHAR(50)  NOT NULL REFERENCES jobs(name) ON DELETE CASCADE,
    grade       INTEGER      NOT NULL DEFAULT 0,
    name        VARCHAR(50)  NOT NULL,
    label       VARCHAR(100) NOT NULL DEFAULT '',
    salary      INTEGER      NOT NULL DEFAULT 0,
    skin_male   JSONB        DEFAULT NULL,
    skin_female JSONB        DEFAULT NULL,
    UNIQUE (job_name, grade)
);

CREATE INDEX IF NOT EXISTS idx_job_grades_job_name ON job_grades (job_name);

-- ─── User Licenses ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_licenses (
    id         SERIAL      PRIMARY KEY,
    type       VARCHAR(60) NOT NULL,
    owner      VARCHAR(60) NOT NULL REFERENCES users(identifier) ON DELETE CASCADE,
    UNIQUE (type, owner)
);

-- ─── Licenses (ox_inventory reference table) ────────────────────────────────
CREATE TABLE IF NOT EXISTS licenses (
    type  VARCHAR(60) PRIMARY KEY,
    label VARCHAR(100) NOT NULL DEFAULT ''
);

-- ─── Audit Log ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS kw_audit_log (
    id          BIGSERIAL    PRIMARY KEY,
    identifier  VARCHAR(60)  DEFAULT NULL,
    player_name VARCHAR(100) DEFAULT NULL,
    action      VARCHAR(100) NOT NULL,
    data        JSONB        DEFAULT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_identifier ON kw_audit_log (identifier);
CREATE INDEX IF NOT EXISTS idx_audit_log_action     ON kw_audit_log (action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON kw_audit_log (created_at DESC);

-- ─── Seed: Unemployed Job ────────────────────────────────────────────────────
INSERT INTO jobs (name, label, type) VALUES ('unemployed', 'Civilian', 'job')
    ON CONFLICT (name) DO NOTHING;

INSERT INTO job_grades (job_name, grade, name, label, salary)
    VALUES ('unemployed', 0, 'unemployed', 'Civilian', 0)
    ON CONFLICT (job_name, grade) DO NOTHING;
