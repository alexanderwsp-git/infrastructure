-- Create myxperiences schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS myxperiences;

-- Grant permissions to user_admin
GRANT ALL PRIVILEGES ON SCHEMA myxperiences TO user_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA myxperiences TO user_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA myxperiences TO user_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA myxperiences GRANT ALL PRIVILEGES ON TABLES TO user_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA myxperiences GRANT ALL PRIVILEGES ON SEQUENCES TO user_admin;
