-- SoloLevelUp — extensions required by later migrations.
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "pg_cron";    -- daily auto-skip job (0007_scheduled_jobs.sql)
