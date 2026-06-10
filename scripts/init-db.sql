-- ============================================================
-- init-db.sql
-- Runs automatically on first container startup.
-- Creates the application schema and base objects.
-- ============================================================

-- Connect as SYSTEM to the PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Create application schema
-- (APP_SCHEMA and APP_SCHEMA_PASSWORD are passed as env vars)
DECLARE
  v_schema VARCHAR2(30) := SYS_CONTEXT('USERENV', 'APP_SCHEMA');
BEGIN
  -- Fallback if env var not set
  IF v_schema IS NULL THEN v_schema := 'MYAPP-LOCAL'; END IF;
  EXECUTE IMMEDIATE 'CREATE USER ' || v_schema ||
    ' IDENTIFIED BY "Welcome1!"' ||
    ' DEFAULT TABLESPACE USERS' ||
    ' QUOTA UNLIMITED ON USERS';
  EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE TO ' || v_schema;
  EXECUTE IMMEDIATE 'GRANT CREATE VIEW, CREATE SEQUENCE, CREATE PROCEDURE TO ' || v_schema;
  -- Allow ORDS/APEX to use this schema
  EXECUTE IMMEDIATE 'GRANT APEX_ADMINISTRATOR_ROLE TO ' || v_schema;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1920 THEN RAISE; END IF; -- ignore "user already exists"
END;
/

-- Error log table (used by all PL/SQL packages)
CREATE TABLE IF NOT EXISTS MYAPP.APP_ERROR_LOG (
  log_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  log_time      TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
  error_code    NUMBER,
  error_message VARCHAR2(4000),
  call_stack    CLOB,
  created_by    VARCHAR2(100) DEFAULT SYS_CONTEXT('APEX$SESSION','APP_USER')
);

COMMIT;
