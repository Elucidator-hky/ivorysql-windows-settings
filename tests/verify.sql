\pset pager off
SELECT version() AS running_server, current_setting('ivorysql.database_mode') AS cluster_mode;
SELECT lower(current_setting('ivorysql.database_mode')) = :'expected_mode' AS verified_identity \gset
\if :verified_identity
\else
  \echo 'The running server did not report the requested IvorySQL cluster mode.'
  \quit 1
\endif

CREATE EXTENSION pg_track_settings;
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_track_settings';
SET work_mem = '3MB';
SELECT pg_track_settings_snapshot();
SELECT pg_sleep(0.1);
SET work_mem = '7MB';
SELECT pg_track_settings_snapshot();

SELECT name, setting FROM pg_track_settings_log('work_mem') ORDER BY ts;
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_track_settings_log('work_mem') WHERE setting = '3072')
     OR NOT EXISTS (SELECT 1 FROM pg_track_settings_log('work_mem') WHERE setting = '7168') THEN
    RAISE EXCEPTION 'The extension did not preserve both independently controlled work_mem samples';
  END IF;
END;
$$;
