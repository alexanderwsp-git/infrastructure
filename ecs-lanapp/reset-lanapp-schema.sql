-- Reset all Lanapp application data (schema `lanapp`) for a fresh start.
-- Does NOT affect Cognito users or S3 objects.
--
-- Usage (connect to lanappdb as a privileged user):
--   psql "$DATABASE_URL" -f lanapp/scripts/reset-lanapp-schema.sql
--
-- After running: restart ECS lanapp-back tasks so TypeORM reapplies migrations (migrationsRun: true).

DROP SCHEMA IF EXISTS lanapp CASCADE;
CREATE SCHEMA lanapp;
GRANT ALL ON SCHEMA lanapp TO user_lanapp;
GRANT ALL ON ALL TABLES IN SCHEMA lanapp TO user_lanapp;
GRANT ALL ON ALL SEQUENCES IN SCHEMA lanapp TO user_lanapp;
ALTER DEFAULT PRIVILEGES IN SCHEMA lanapp GRANT ALL ON TABLES TO user_lanapp;
ALTER DEFAULT PRIVILEGES IN SCHEMA lanapp GRANT ALL ON SEQUENCES TO user_lanapp;
