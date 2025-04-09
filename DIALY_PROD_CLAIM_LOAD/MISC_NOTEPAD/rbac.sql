 
--PROD_DATA_ENGINEER_L3
grant usage on database CLAIMS_PROD to role PROD_DATA_ENGINEER_L1;
grant usage on database CLAIMS_PROD to role PROD_DATA_ENGINEER_L2;
grant usage on database CLAIMS_PROD to role PROD_DATA_ENGINEER_L3;

--etl_ctrl
grant all privileges on schema etl_ctrl to role PROD_DATA_ENGINEER_L3;
grant all privileges on future tables in schema etl_ctrl to role PROD_DATA_ENGINEER_L3;
grant all privileges on future views in schema etl_ctrl to role PROD_DATA_ENGINEER_L3;
grant all privileges on future stages in schema etl_ctrl to role PROD_DATA_ENGINEER_L3;

grant all privileges on all tables in schema etl_ctrl to role PROD_DATA_ENGINEER_L3;
grant all privileges on all views in schema etl_ctrl to role PROD_DATA_ENGINEER_L3;
grant all privileges on all stages in schema etl_ctrl to role PROD_DATA_ENGINEER_L3;
grant usage on all procedures in schema etl_ctrl to role PROD_DATA_ENGINEER_L3;


grant usage on file format FF_JSON_FORMAT to role PROD_DATA_ENGINEER_L3;
grant usage on file format FF_PARQUET_FORMAT  to role PROD_DATA_ENGINEER_L3;
grant usage on SEQUENCE SEQ_BATCHID to role PROD_DATA_ENGINEER_L3;
grant usage on FUNCTION GET_BATCHID()   to role PROD_DATA_ENGINEER_L3;
grant usage on all procedures in schema ETL_CTRL to role PROD_DATA_ENGINEER_L3;

--RAW
grant all privileges on schema RAW to role PROD_DATA_ENGINEER_L3;
grant all privileges on future tables in schema RAW to role PROD_DATA_ENGINEER_L3;
grant all privileges on future views in schema RAW to role PROD_DATA_ENGINEER_L3;
grant all privileges on future stages in schema RAW to role PROD_DATA_ENGINEER_L3;

grant all privileges on all tables in schema RAW to role PROD_DATA_ENGINEER_L3;
grant all privileges on all views in schema RAW to role PROD_DATA_ENGINEER_L3;
grant all privileges on all stages in schema RAW to role PROD_DATA_ENGINEER_L3;


--STG
grant all privileges on schema STG to role PROD_DATA_ENGINEER_L3;
grant all privileges on future tables in schema STG to role PROD_DATA_ENGINEER_L3;
grant all privileges on future views in schema STG to role PROD_DATA_ENGINEER_L3;
grant all privileges on future stages in schema STG to role PROD_DATA_ENGINEER_L3;

grant all privileges on all tables in schema STG to role PROD_DATA_ENGINEER_L3;
grant all privileges on all views in schema STG to role PROD_DATA_ENGINEER_L3;
grant all privileges on all stages in schema STG to role PROD_DATA_ENGINEER_L3;


--MRG
grant all privileges on schema MRG to role PROD_DATA_ENGINEER_L3;
grant all privileges on future tables in schema MRG to role PROD_DATA_ENGINEER_L3;
grant all privileges on future views in schema MRG to role PROD_DATA_ENGINEER_L3;
grant all privileges on future stages in schema MRG to role PROD_DATA_ENGINEER_L3;

grant all privileges on all tables in schema MRG to role PROD_DATA_ENGINEER_L3;
grant all privileges on all views in schema MRG to role PROD_DATA_ENGINEER_L3;
grant all privileges on all stages in schema MRG to role PROD_DATA_ENGINEER_L3;


--VALIDATE
grant all privileges on schema VALIDATE to role PROD_DATA_ENGINEER_L3;
grant all privileges on future tables in schema VALIDATE to role PROD_DATA_ENGINEER_L3;
grant all privileges on future views in schema VALIDATE to role PROD_DATA_ENGINEER_L3;
grant all privileges on future stages in schema VALIDATE to role PROD_DATA_ENGINEER_L3;

grant all privileges on all tables in schema VALIDATE to role PROD_DATA_ENGINEER_L3;
grant all privileges on all views in schema VALIDATE to role PROD_DATA_ENGINEER_L3;
grant all privileges on all stages in schema VALIDATE to role PROD_DATA_ENGINEER_L3;
grant usage on all procedures in schema VALIDATE to role PROD_DATA_ENGINEER_L3;

--OUTBOUND_ON_PREM
grant all privileges on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L3;
grant all privileges on future tables in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L3;
grant all privileges on future views in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L3;
grant all privileges on future stages in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L3;

grant all privileges on all tables in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L3;
grant all privileges on all views in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L3;
grant all privileges on all stages in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L3;
grant usage on all procedures in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L3;
------------------------------------------------------------------------------------------------

--PROD_DATA_ENGINEER_L2

--ETL_CTRL
grant CREATE TABLE on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE VIEW on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE MATERIALIZED VIEW on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE MASKING POLICY on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE STAGE on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE FILE FORMAT on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE SEQUENCE on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE FUNCTION on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE STREAM on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE PROCEDURE on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant CREATE PIPE on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;

grant select on all views in schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant usage  on all procedures in schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant usage  on all stages in schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;



--RAW
grant CREATE TABLE on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE VIEW on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE MATERIALIZED VIEW on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE MASKING POLICY on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE STAGE on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE FILE FORMAT on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE SEQUENCE on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE FUNCTION on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE STREAM on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE PROCEDURE on schema RAW to role PROD_DATA_ENGINEER_L2;
grant CREATE PIPE on schema RAW to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema RAW to role PROD_DATA_ENGINEER_L2;

grant usage on all stages in schema RAW to role PROD_DATA_ENGINEER_L2;
grant select on all views in schema RAW to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema RAW to role PROD_DATA_ENGINEER_L2;

--STG
grant CREATE TABLE on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE VIEW on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE MATERIALIZED VIEW on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE MASKING POLICY on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE STAGE on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE FILE FORMAT on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE SEQUENCE on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE FUNCTION on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE STREAM on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE PROCEDURE on schema STG to role PROD_DATA_ENGINEER_L2;
grant CREATE PIPE on schema STG to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema STG to role PROD_DATA_ENGINEER_L2;
grant select on all views in schema STG to role PROD_DATA_ENGINEER_L2;
grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema STG to role PROD_DATA_ENGINEER_L2;


--MRG
grant usage on database BILLING_PROD to role PROD_DATA_ENGINEER_L2;
grant CREATE TABLE on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE VIEW on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE MATERIALIZED VIEW on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE MASKING POLICY on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE STAGE on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE FILE FORMAT on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE SEQUENCE on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE FUNCTION on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE STREAM on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE PROCEDURE on schema MRG to role PROD_DATA_ENGINEER_L2;
grant CREATE PIPE on schema MRG to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema MRG to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema MRG to role PROD_DATA_ENGINEER_L2;

grant select on all views in schema MRG to role PROD_DATA_ENGINEER_L2;




--VALIDATE
grant CREATE TABLE on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE VIEW on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE MATERIALIZED VIEW on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE MASKING POLICY on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE STAGE on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE FILE FORMAT on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE SEQUENCE on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE FUNCTION on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE STREAM on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE PROCEDURE on schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant CREATE PIPE on schema VALIDATE to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema VALIDATE to role PROD_DATA_ENGINEER_L2;

grant select on all views in schema VALIDATE to role PROD_DATA_ENGINEER_L2;

grant usage on all functions in schema VALIDATE to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema VALIDATE to role PROD_DATA_ENGINEER_L2;
grant usage on all procedures in schema VALIDATE to role PROD_DATA_ENGINEER_L2;


--OUTBOUND_ON_PREM
grant CREATE TABLE on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE VIEW on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE MATERIALIZED VIEW on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE MASKING POLICY on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE STAGE on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE FILE FORMAT on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE SEQUENCE on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE FUNCTION on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE STREAM on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE PROCEDURE on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
grant CREATE PIPE on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;

grant select on all views in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;

grant usage on all functions in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;

grant usage on all procedures in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;

grant usage on file format FF_JSON_FORMAT to role PROD_DATA_ENGINEER_L2;
grant usage on file format FF_PARQUET_FORMAT  to role PROD_DATA_ENGINEER_L2;
grant usage on SEQUENCE SEQ_BATCHID to role PROD_DATA_ENGINEER_L2;
grant usage on FUNCTION GET_BATCHID()   to role PROD_DATA_ENGINEER_L2;
grant usage on all procedures in schema VALIDATE to role PROD_DATA_ENGINEER_L2;

grant usage on schema ETL_CTRL to role PROD_DATA_ENGINEER_L2;
grant usage on schema MRG to role PROD_DATA_ENGINEER_L2;
grant usage on schema RAW to role PROD_DATA_ENGINEER_L2;
grant usage on schema STG to role PROD_DATA_ENGINEER_L2;
grant usage on schema validate to role PROD_DATA_ENGINEER_L2;
grant usage on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L2;
------------------------------------------------------------------------------------------

--PROD_DATA_ENGINEER_L1


grant usage on schema ETL_CTRL to role PROD_DATA_ENGINEER_L1;
grant usage on schema MRG to role PROD_DATA_ENGINEER_L1;
grant usage on schema RAW to role PROD_DATA_ENGINEER_L1;
grant usage on schema STG to role PROD_DATA_ENGINEER_L1;
grant usage on schema validate to role PROD_DATA_ENGINEER_L1;
grant usage on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L1;


--ETL_CTRL
grant CREATE TABLE on schema ETL_CTRL to role PROD_DATA_ENGINEER_L1;
grant select on all views in schema ETL_CTRL to role PROD_DATA_ENGINEER_L1;
grant usage on all procedures in schema ETL_CTRL to role PROD_DATA_ENGINEER_L1;
grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema ETL_CTRL to role PROD_DATA_ENGINEER_L1;
grant usage  on all stages in schema ETL_CTRL to role PROD_DATA_ENGINEER_L1;
grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema ETL_CTRL to role PROD_DATA_ENGINEER_L1;

--RAW
grant CREATE TABLE on schema RAW to role PROD_DATA_ENGINEER_L1;
grant select on all views in schema RAW to role PROD_DATA_ENGINEER_L1;
grant usage on all stages in schema RAW to role PROD_DATA_ENGINEER_L1;
grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema RAW to role PROD_DATA_ENGINEER_L1;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema RAW to role PROD_DATA_ENGINEER_L1;

--STG
grant CREATE TABLE on schema STG to role PROD_DATA_ENGINEER_L1;
grant select on all views in schema STG to role PROD_DATA_ENGINEER_L1;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema STG to role PROD_DATA_ENGINEER_L1;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema STG to role PROD_DATA_ENGINEER_L1;

--MRG
grant usage on database BILLING_PROD to role PROD_DATA_ENGINEER_L1;
grant CREATE TABLE on schema MRG to role PROD_DATA_ENGINEER_L1;

grant select on all views in schema MRG to role PROD_DATA_ENGINEER_L1;
grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema MRG to role PROD_DATA_ENGINEER_L1;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema MRG to role PROD_DATA_ENGINEER_L1;


--VALIDATE
grant CREATE TABLE on schema VALIDATE to role PROD_DATA_ENGINEER_L1;
grant select on all views in schema VALIDATE to role PROD_DATA_ENGINEER_L1;
grant usage on all procedures in schema VALIDATE to role PROD_DATA_ENGINEER_L1;
grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema VALIDATE to role PROD_DATA_ENGINEER_L1;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema VALIDATE to role PROD_DATA_ENGINEER_L1;
grant usage on all procedures in schema VALIDATE to role PROD_DATA_ENGINEER_L1;

--OUTBOUND_ON_PREM

grant CREATE TABLE on schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L1;
grant select on all views in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L1;
grant usage on all procedures in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L1;
grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on all tables in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L1;

grant SELECT 
,INSERT
,UPDATE
,TRUNCATE
,DELETE on future tables in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L1;
grant usage on all procedures in schema OUTBOUND_ON_PREM to role PROD_DATA_ENGINEER_L1;
--------------------------------------------------------------------------------------



grant usage on database CLAIMS_PROD to role PROD_DATA_ANALYST;

grant usage on schema ETL_CTRL to role PROD_DATA_ANALYST;
grant usage on all stages in schema ETL_CTRL to role PROD_DATA_ANALYST;
grant select on all tables in schema ETL_CTRL to role PROD_DATA_ANALYST;
grant select on future tables in schema ETL_CTRL to role PROD_DATA_ANALYST;
grant select on all views in schema ETL_CTRL to role PROD_DATA_ANALYST;

grant usage on schema RAW to role PROD_DATA_ANALYST;
grant usage on all stages in schema RAW to role PROD_DATA_ANALYST;
grant select on all tables in schema RAW to role PROD_DATA_ANALYST;
grant select on future tables in schema RAW to role PROD_DATA_ANALYST;
grant select on all views in schema RAW to role PROD_DATA_ANALYST;

grant usage on schema STG to role PROD_DATA_ANALYST;
grant select on all tables in schema STG to role PROD_DATA_ANALYST;
grant select on future tables in schema STG to role PROD_DATA_ANALYST;
grant select on all views in schema STG to role PROD_DATA_ANALYST;

grant usage on schema MRG to role PROD_DATA_ANALYST;
grant select on all tables in schema MRG to role PROD_DATA_ANALYST;
grant select on future tables in schema MRG to role PROD_DATA_ANALYST;
grant select on all views in schema MRG to role PROD_DATA_ANALYST;


grant usage on schema validate to role PROD_DATA_ANALYST;
grant select on all tables in schema validate to role PROD_DATA_ANALYST;
grant select on future tables in schema validate to role PROD_DATA_ANALYST;
grant select on all views in schema validate to role PROD_DATA_ANALYST;

grant usage on schema OUTBOUND_ON_PREM to role PROD_DATA_ANALYST;
grant select on all tables in schema OUTBOUND_ON_PREM to role PROD_DATA_ANALYST;
grant select on future tables in schema OUTBOUND_ON_PREM to role PROD_DATA_ANALYST;
grant select on all views in schema OUTBOUND_ON_PREM to role PROD_DATA_ANALYST;

------------------------------------------------------------------------------------------------