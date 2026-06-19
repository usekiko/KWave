-- Migration 002: ox_inventory support tables
-- Safe to run multiple times

CREATE TABLE IF NOT EXISTS ox_inventory (
    id         BIGSERIAL   PRIMARY KEY,
    owner      VARCHAR(60) DEFAULT NULL,
    name       VARCHAR(60) NOT NULL,
    data       JSONB       NOT NULL DEFAULT '{}',
    slots      INTEGER     NOT NULL DEFAULT 50,
    weight     NUMERIC     NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ox_inventory_owner_name ON ox_inventory (owner, name);
