-- KWave Job System 2.0 — Migration 003
-- Adds JSONB permissions array to the job_grades table

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'job_grades' AND column_name = 'permissions'
    ) THEN
        ALTER TABLE job_grades
        ADD COLUMN permissions JSONB NOT NULL DEFAULT '[]'::jsonb;
    END IF;
END $$;
