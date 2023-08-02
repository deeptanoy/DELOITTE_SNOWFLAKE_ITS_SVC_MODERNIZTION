CREATE OR REPLACE PROCEDURE SF_SANDBOX_DB.SF_SANDBOX_SCHEMA.SP_SF_PLTFRM_CREATE_DATABASE_PROC("P_TENANT_ABRV" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS '
DECLARE
       DATABASE_NM VARCHAR DEFAULT '''';
       DB_SQL VARCHAR DEFAULT '''';
BEGIN
    DATABASE_NM := P_TENANT_ABRV||''_DB'';
    DB_SQL:= ''CREATE OR REPLACE DATABASE ''|| :DATABASE_NM;

    EXECUTE IMMEDIATE :DB_SQL;

    USE WAREHOUSE SF_SANDBOX_WH;
    USE DATABASE SF_SANDBOX_DB;
    USE SCHEMA SF_SANDBOX_SCHEMA;

    INSERT INTO TEMP_T_DATABASE(DATABASE_NAME, PRIMARY_TAG)
    SELECT  :DATABASE_NM, :P_TENANT_ABRV;

        
/*EXCEPTION
    WHEN OTHER THEN
      IS_ERROR := ''1'';
      JOB_LOG_DESCRIPTION := ''SQLCODE:'' || SQLCODE || '' SQLERRM:'' || SQLERRM || '' SQLSTATE:'' ||SQLSTATE;
      RETURN ARRAY_CONSTRUCT(:IS_ERROR,:JOB_LOG_DESCRIPTION)  ;
*/
RETURN ''DATABASE CREATED'';
END;
';


CREATE OR REPLACE PROCEDURE SF_SANDBOX_DB.SF_SANDBOX_SCHEMA.SP_SF_PLTFRM_CREATE_RM("P_TENANT_ABRV" VARCHAR(16777216), "P_CREDIT_QUOTA" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS '
DECLARE
	RM_NAME VARCHAR DEFAULT '''';
	WH_NAME VARCHAR DEFAULT '''';
BEGIN
	USE ROLE ACCOUNTADMIN;
	SELECT WAREHOUSE_NAME INTO WH_NAME FROM TEMP_T_WAREHOUSE;
	RM_NAME := WH_NAME||''_RM'';	
	EXECUTE IMMEDIATE ''CREATE RESOURCE MONITOR ''||RM_NAME||'' WITH CREDIT_QUOTA = ''||P_CREDIT_QUOTA||'' FREQUENCY = NEVER 
                START_TIMESTAMP = IMMEDIATELY NOTIFY_USERS = (PRADSR) TRIGGERS
				ON 95 PERCENT DO SUSPEND 
				ON 98 PERCENT DO SUSPEND_IMMEDIATE 
				ON 90 PERCENT DO NOTIFY'';
    
    INSERT INTO TEMP_T_RESOURCE_MONITOR(RM_NAME,CREDIT_LIMIT, START_TIME,PRIMARY_TAG)
    SELECT  :RM_NAME,:P_CREDIT_QUOTA,CURRENT_TIMESTAMP,:P_TENANT_ABRV;
    
    EXECUTE IMMEDIATE ''ALTER WAREHOUSE ''||WH_NAME||'' SET RESOURCE_MONITOR = ''||RM_NAME;
	
/*EXCEPTION
    WHEN OTHER THEN
      IS_ERROR := ''1'';
      JOB_LOG_DESCRIPTION := ''SQLCODE:'' || SQLCODE || '' SQLERRM:'' || SQLERRM || '' SQLSTATE:'' ||SQLSTATE;
      RETURN ARRAY_CONSTRUCT(:IS_ERROR,:JOB_LOG_DESCRIPTION)  ;
*/
	
RETURN ''SUCCEEDED, ''||RM_NAME||'' IS CREATED AND ASSIGNED TO WAREHOUSE ''||WH_NAME;
END;
';


CREATE OR REPLACE PROCEDURE SF_SANDBOX_DB.SF_SANDBOX_SCHEMA.SP_SF_PLTFRM_CREATE_ROLE("P_TENANT_ABRV" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS '
DECLARE
	ROLE_NM VARCHAR DEFAULT '''';
	ROLE_SQL VARCHAR DEFAULT '''';
	DB_NAME VARCHAR DEFAULT '''';
    
BEGIN
    USE ROLE SECURITYADMIN;
	ROLE_NM := P_TENANT_ABRV||''_ROLE'';
	ROLE_SQL := ''CREATE ROLE ''|| ROLE_NM;
	
	EXECUTE IMMEDIATE :ROLE_SQL;
    
    INSERT INTO TEMP_T_ROLES(ROLE_NAME)
    SELECT  :ROLE_NM;

    SELECT DATABASE_NAME INTO DB_NAME FROM "SF_SANDBOX_DB"."SF_SANDBOX_SCHEMA"."TEMP_T_DATABASE";    
    EXECUTE IMMEDIATE ''GRANT ALL PRIVILEGES ON DATABASE ''||DB_NAME||'' TO ROLE ''||ROLE_NM;
	
/*EXCEPTION
    WHEN OTHER THEN
      IS_ERROR := ''1'';
      JOB_LOG_DESCRIPTION := ''SQLCODE:'' || SQLCODE || '' SQLERRM:'' || SQLERRM || '' SQLSTATE:'' ||SQLSTATE;
      RETURN ARRAY_CONSTRUCT(:IS_ERROR,:JOB_LOG_DESCRIPTION);
*/
	
RETURN ''SUCCEEDED: ''||ROLE_NM||'' IS CREATED AND GRANTED NECESSARY ACCESS TO DATABASE ''||DB_NAME;
END;
';



CREATE OR REPLACE PROCEDURE SF_SANDBOX_DB.SF_SANDBOX_SCHEMA.SP_SF_PLTFRM_CREATE_TENANT_PROC("P_TENANT_NAME" VARCHAR(16777216), "P_TENANT_ABRV" VARCHAR(16777216), "P_CLIENT_EMAIL" VARCHAR(16777216), "P_CLIENT_NAME" VARCHAR(16777216), "P_BUSINESS_PURPOSE" VARCHAR(16777216), "P_APPROVER" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS '
DECLARE
    CLIENT VARCHAR DEFAULT ''GCP'';
    CLOUD VARCHAR DEFAULT ''GCP'';
    APPROVER VARCHAR DEFAULT ''RUPESH DANDEKAR - RUDANDEKAR@DELOITTE.COM'';
    IS_ACTIVE VARCHAR DEFAULT ''Y'';
    
BEGIN

    CLIENT := P_CLIENT_NAME||'' - ''||P_CLIENT_EMAIL;
    INSERT INTO TEMP_T_TENANT(ACCOUNT_ID,TENANT_NAME,CLIENT,TENANT_ABRV,BUSINESS_PURPOSE,T_APPROVER,CLOUD,IS_ACTIVE)
    SELECT  1,
            :P_TENANT_NAME,
            :CLIENT,
            :P_TENANT_ABRV,
            :P_BUSINESS_PURPOSE,
            :APPROVER,
            :CLOUD,
            :IS_ACTIVE;

        
/*EXCEPTION
    WHEN OTHER THEN
      IS_ERROR := ''1'';
      JOB_LOG_DESCRIPTION := ''SQLCODE:'' || SQLCODE || '' SQLERRM:'' || SQLERRM || '' SQLSTATE:'' ||SQLSTATE;
      RETURN ARRAY_CONSTRUCT(:IS_ERROR,:JOB_LOG_DESCRIPTION)  ;
*/
RETURN ''TENANT CREATED'';
END;
';

CREATE OR REPLACE PROCEDURE SF_SANDBOX_DB.SF_SANDBOX_SCHEMA.SP_SF_PLTFRM_CREATE_USER("P_TENANT_ABRV" VARCHAR(16777216), "P_CLIENT_NAME" VARCHAR(16777216), "P_CLIENT_EMAIL" VARCHAR(16777216), "P_IS_PRIMARY" VARCHAR(10))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS '
DECLARE
	ROLE_NM VARCHAR DEFAULT '''';
	WAREHOUSE_NM VARCHAR DEFAULT '''';
	USER_NAME VARCHAR DEFAULT '''';
	IS_PRIMARY VARCHAR DEFAULT '''';
    USER_SQL VARCHAR DEFAULT '''';
BEGIN
	USE ROLE SECURITYADMIN;
	SELECT COALESCE(:P_IS_PRIMARY,''N'') INTO IS_PRIMARY;
	SELECT ROLE_NAME INTO ROLE_NM FROM "SF_SANDBOX_DB"."SF_SANDBOX_SCHEMA"."TEMP_T_ROLES";
	SELECT WAREHOUSE_NAME INTO WAREHOUSE_NM FROM "SF_SANDBOX_DB"."SF_SANDBOX_SCHEMA"."TEMP_T_WAREHOUSE";
	select split_part(:P_CLIENT_EMAIL, ''@'', 0) INTO USER_NAME;
    
	USER_SQL:= ''CREATE USER ''||USER_NAME||'' PASSWORD = WELCOME123 LOGIN_NAME = ''||USER_NAME||'' DISPLAY_NAME = ''||USER_NAME||'' 
	FIRST_NAME = ''||P_CLIENT_NAME||'' 
	EMAIL = "''||P_CLIENT_EMAIL||''" DEFAULT_ROLE = ''||ROLE_NM||'' 
	DEFAULT_WAREHOUSE = ''||WAREHOUSE_NM||'' DEFAULT_NAMESPACE = ''||USER_NAME||'' MUST_CHANGE_PASSWORD = TRUE'';
    EXECUTE IMMEDIATE :USER_SQL;

    INSERT INTO TEMP_T_USERS(USER_NAME,EMAIL_ID,IS_PRIMARY,PRIMARY_TAG)
    SELECT  :USER_NAME,:P_CLIENT_EMAIL,:IS_PRIMARY,:P_TENANT_ABRV;
  
    EXECUTE IMMEDIATE ''GRANT ROLE ''||ROLE_NM||'' TO USER ''||USER_NAME;
 
	
/*EXCEPTION
    WHEN OTHER THEN
      IS_ERROR := ''1'';
      JOB_LOG_DESCRIPTION := ''SQLCODE:'' || SQLCODE || '' SQLERRM:'' || SQLERRM || '' SQLSTATE:'' ||SQLSTATE;
      RETURN ARRAY_CONSTRUCT(:IS_ERROR,:JOB_LOG_DESCRIPTION)  ;
*/
	
RETURN ''SUCCEEDED, USER ''||USER_NAME||'' IS CREATED AND ROLE ''||ROLE_NM||'' IS ASSIGNED'';
END;
';



CREATE OR REPLACE PROCEDURE SF_SANDBOX_DB.SF_SANDBOX_SCHEMA.SP_SF_PLTFRM_CREATE_WAREHOUSE("P_TENANT_ABRV" VARCHAR(16777216), "P_WAREHOUSE_SIZE" VARCHAR(48))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS '
DECLARE
	WH_NAME VARCHAR DEFAULT '''';
	ROLE_NM VARCHAR DEFAULT '''';
    WH_SIZE VARCHAR DEFAULT '''';
BEGIN
    SELECT COALESCE(:P_WAREHOUSE_SIZE,''XSMALL'') INTO WH_SIZE;
	WH_NAME := P_TENANT_ABRV||''_WH'';
    USE ROLE SYSADMIN;
	EXECUTE IMMEDIATE ''CREATE WAREHOUSE ''||WH_NAME||'' WITH WAREHOUSE_SIZE=''||WH_SIZE||'' WAREHOUSE_TYPE = STANDARD AUTO_SUSPEND = 300 AUTO_RESUME = TRUE MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1 SCALING_POLICY = STANDARD'';
    INSERT INTO TEMP_T_WAREHOUSE(WAREHOUSE_NAME,WAREHOUSE_SIZE,PRIMARY_TAG)
    SELECT  :WH_NAME,:WH_SIZE,:P_TENANT_ABRV;

    SELECT ROLE_NAME INTO ROLE_NM FROM "SF_SANDBOX_DB"."SF_SANDBOX_SCHEMA"."TEMP_T_ROLES";
    USE ROLE SECURITYADMIN;
    EXECUTE IMMEDIATE ''GRANT MONITOR, OPERATE, USAGE ON WAREHOUSE ''||WH_NAME||'' TO ROLE ''||ROLE_NM;
	
/*EXCEPTION
    WHEN OTHER THEN
      IS_ERROR := ''1'';
      JOB_LOG_DESCRIPTION := ''SQLCODE:'' || SQLCODE || '' SQLERRM:'' || SQLERRM || '' SQLSTATE:'' ||SQLSTATE;
      RETURN ARRAY_CONSTRUCT(:IS_ERROR,:JOB_LOG_DESCRIPTION)  ;
*/
	
RETURN ''SUCCEEDED, ''||WH_NAME||'' IS CREATED AND GRANTED MONITOR, OPERATE, USAGE ACCESE TO ROLE ''||ROLE_NM;
END;
';


CREATE OR REPLACE PROCEDURE SF_SANDBOX_DB.SF_SANDBOX_SCHEMA.SP_SF_PLTFRM_WRAPPER_PROC("P_TENANT_NAME" VARCHAR(16777216), "P_TENANT_ABRV" VARCHAR(16777216), "P_CLIENT_EMAIL" VARCHAR(16777216), "P_CLIENT_NAME" VARCHAR(16777216), "P_BUSINESS_PURPOSE" VARCHAR(16777216), "P_APPROVER" VARCHAR(16777216), "P_WH_SIZE" VARCHAR(16777216), "P_CREDIT_LIMIT" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS '
DECLARE
    TENANT_NAME VARCHAR DEFAULT '''';
    TENANT_ABRV VARCHAR DEFAULT  '''';
    CLIENT_EMAIL VARCHAR DEFAULT  '''';
    CLIENT_NAME VARCHAR DEFAULT  '''';
    BUSINESS_PURPOSE VARCHAR DEFAULT '''';
    APPROVER VARCHAR DEFAULT  '''';
    WH_SIZE VARCHAR DEFAULT  '''';
    CREDIT_LIMIT VARCHAR DEFAULT '''';
	V_TENANT_ID VARCHAR DEFAULT '''';
	V_ROLE_ID VARCHAR DEFAULT '''';
	V_RM_ID VARCHAR DEFAULT '''';
    WRONG_PARAMETER_EXCEPTION EXCEPTION ;
       
BEGIN

IF ((P_TENANT_NAME IS NULL OR TRIM(P_TENANT_NAME) = '''') OR 
    (P_TENANT_ABRV IS NULL OR TRIM(P_TENANT_ABRV) = '''') OR
    (P_CLIENT_EMAIL IS NULL OR TRIM(P_CLIENT_EMAIL) = '''') OR
    (P_CLIENT_NAME IS NULL OR TRIM(P_CLIENT_NAME) = '''') OR
    (P_BUSINESS_PURPOSE IS NULL OR TRIM(P_BUSINESS_PURPOSE) = '''') OR
    (P_APPROVER IS NULL OR TRIM(P_APPROVER) = '''') OR
    (P_WH_SIZE IS NULL OR TRIM(P_WH_SIZE) = '''') OR
    (P_CREDIT_LIMIT IS NULL OR TRIM(P_CREDIT_LIMIT) = ''''))
    THEN RAISE WRONG_PARAMETER_EXCEPTION;
END IF;

   TENANT_NAME := UPPER(P_TENANT_NAME);
   TENANT_ABRV := UPPER(P_TENANT_ABRV);
   CLIENT_EMAIL := UPPER(P_CLIENT_EMAIL);
   CLIENT_NAME := UPPER(P_CLIENT_NAME);
   BUSINESS_PURPOSE := UPPER(P_BUSINESS_PURPOSE);
   APPROVER := UPPER(P_APPROVER);
   WH_SIZE := UPPER(P_WH_SIZE);
   

    --CREATING TEMP TABLS TO HOLD VALUES DURING COURSE OF ONBOARDING
   CREATE OR REPLACE TEMPORARY TABLE TEMP_T_TENANT LIKE T_TENANT;
   CREATE OR REPLACE TEMPORARY TABLE TEMP_T_DATABASE LIKE  T_DATABASE;
   CREATE OR REPLACE TEMPORARY TABLE TEMP_T_RESOURCE_MONITOR LIKE  T_RESOURCE_MONITOR;
   CREATE OR REPLACE TEMPORARY TABLE TEMP_T_ROLES LIKE T_ROLES;
   CREATE OR REPLACE TEMPORARY TABLE TEMP_T_USERS LIKE T_USERS;
   CREATE OR REPLACE TEMPORARY TABLE TEMP_T_WAREHOUSE LIKE T_WAREHOUSE;

   --INVOKE PROCEDURES ONE BY ONE
  CALL SP_SF_PLTFRM_CREATE_TENANT_PROC(
    :TENANT_NAME,
    :TENANT_ABRV,
    :CLIENT_EMAIL,
    :CLIENT_NAME,
    :BUSINESS_PURPOSE,
    :APPROVER);

USE WAREHOUSE SF_SANDBOX_WH;
USE DATABASE SF_SANDBOX_DB;
USE SCHEMA SF_SANDBOX_SCHEMA;

 CALL SP_SF_PLTFRM_CREATE_DATABASE_PROC(:TENANT_ABRV);

USE WAREHOUSE SF_SANDBOX_WH;
USE DATABASE SF_SANDBOX_DB;
USE SCHEMA SF_SANDBOX_SCHEMA;
 
 CALL SP_SF_PLTFRM_CREATE_ROLE(:TENANT_ABRV);

USE WAREHOUSE SF_SANDBOX_WH;
USE DATABASE SF_SANDBOX_DB;
USE SCHEMA SF_SANDBOX_SCHEMA;

 CALL SP_SF_PLTFRM_CREATE_WAREHOUSE(:TENANT_ABRV,
 :WH_SIZE);

USE WAREHOUSE SF_SANDBOX_WH;
USE DATABASE SF_SANDBOX_DB;
USE SCHEMA SF_SANDBOX_SCHEMA; 
 
 CALL SP_SF_PLTFRM_CREATE_USER (:TENANT_ABRV, :CLIENT_NAME, :CLIENT_EMAIL, ''Y'');

USE WAREHOUSE SF_SANDBOX_WH;
USE DATABASE SF_SANDBOX_DB;
USE SCHEMA SF_SANDBOX_SCHEMA;
 
 CALL SP_SF_PLTFRM_CREATE_RM (:TENANT_ABRV, :P_CREDIT_LIMIT);
 
USE WAREHOUSE SF_SANDBOX_WH;
USE DATABASE SF_SANDBOX_DB;
USE SCHEMA SF_SANDBOX_SCHEMA;

    INSERT INTO T_TENANT(ACCOUNT_ID,TENANT_NAME,CLIENT,TENANT_ABRV,ONBOARDING_DATE,BUSINESS_PURPOSE,T_APPROVER,CLOUD,IS_ACTIVE) SELECT 5,TENANT_NAME,CLIENT,TENANT_ABRV,CURRENT_TIMESTAMP,BUSINESS_PURPOSE,T_APPROVER,CLOUD,IS_ACTIVE FROM TEMP_T_TENANT WHERE TENANT_NAME NOT IN (SELECT TENANT_NAME FROM T_TENANT);
    SELECT TENANT_ID INTO V_TENANT_ID FROM T_TENANT WHERE TENANT_ABRV=:TENANT_ABRV;
	INSERT INTO T_DATABASE (TENANT_ID, DATABASE_NAME, PRIMARY_TAG) SELECT :V_TENANT_ID, DATABASE_NAME, PRIMARY_TAG FROM TEMP_T_DATABASE;
	INSERT INTO T_ROLES (TENANT_ID,ROLE_NAME) SELECT :V_TENANT_ID, ROLE_NAME FROM TEMP_T_ROLES;
	SELECT ROLE_ID INTO V_ROLE_ID FROM T_ROLES WHERE ROLE_NAME IN (SELECT ROLE_NAME FROM TEMP_T_ROLES);
    INSERT INTO T_USERS (TENANT_ID,ROLE_ID,USER_NAME,EMAIL_ID,IS_PRIMARY,PRIMARY_TAG) SELECT :V_TENANT_ID, :V_ROLE_ID,USER_NAME,EMAIL_ID,IS_PRIMARY,PRIMARY_TAG FROM TEMP_T_USERS;
	INSERT INTO T_RESOURCE_MONITOR (TENANT_ID,RM_NAME,CREDIT_LIMIT,FREQUENCY,START_TIME,CLUSTER_SIZE,PRIMARY_TAG) SELECT :V_TENANT_ID,RM_NAME,CREDIT_LIMIT,''NEVER'',START_TIME,1,PRIMARY_TAG FROM TEMP_T_RESOURCE_MONITOR;
	SELECT RM_ID INTO V_RM_ID FROM T_RESOURCE_MONITOR WHERE RM_NAME IN (SELECT RM_NAME FROM TEMP_T_RESOURCE_MONITOR);
    INSERT INTO T_WAREHOUSE (TENANT_ID,RM_ID,WAREHOUSE_NAME,WAREHOUSE_SIZE,TYPE,CLUSTER_SIZE,PRIMARY_TAG) SELECT :V_TENANT_ID,:V_RM_ID,WAREHOUSE_NAME,WAREHOUSE_SIZE,''STANDARD'',1,PRIMARY_TAG FROM TEMP_T_WAREHOUSE;
    
RETURN ''TENANT ONBOARDED'';

EXCEPTION

   WHEN WRONG_PARAMETER_EXCEPTION  THEN
    RETURN ''WRONG PARAMETER PASSED TO THE WRAPPER PROC''  ;

  /*WHEN OTHER THEN
    IS_ERROR := ''1'';
    JOB_LOG_DESCRIPTION := ''SQLCODE:'' || SQLCODE || '' SQLERRM:'' || SQLERRM || '' SQLSTATE:'' ||SQLSTATE;
    RETURN ARRAY_CONSTRUCT(:IS_ERROR,:JOB_LOG_DESCRIPTION)  ;
  */ 
  
END;
';
