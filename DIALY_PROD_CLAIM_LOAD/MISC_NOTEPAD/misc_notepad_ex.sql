# Import python packages
import streamlit as st
from snowflake.snowpark import Session

connection_parameters = {
    "account": "REA00670",
    "user": "rsuthrapu@ciginsurance.com",
    "password": "Welcome123!",
    "role": "ACCOUNTADMIN",  # optional
    "warehouse": "WH_DATA_TEAM",  # optional
    "database": "CLAIMS_STG",  # optional
    "schema": "RAW_BC",  # optional
 }  
new_session = Session.builder.configs(connection_parameters).create()


# Define your SQL query
sql_query = """WITH POLICY_CONTACTS AS (
  SELECT POLICYID,
         MAX(DECODE(CTROLE_POLICY_TYPECODE, 'agent', NAME)) AS AGENT,
         MAX(DECODE(CTROLE_POLICY_TYPECODE, 'insured', NAME)) AS INSURED
  --, BUSINESS_NAME
  FROM (
    SELECT CCTRP.POLICYID,
           TLCCTR.TYPECODE AS CTROLE_POLICY_TYPECODE,
           CASE WHEN CTP.NAME IS NOT NULL
                THEN CTP.NAME
                WHEN CTP.FIRSTNAME IS NOT NULL AND CTP.LASTNAME IS NOT NULL
                THEN CTP.LASTNAME || ' ' || CTP.FIRSTNAME
             WHEN CTP.FIRSTNAME IS NOT NULL
                THEN CTP.FIRSTNAME
             WHEN CTP.LASTNAME IS NOT NULL
                THEN CTP.LASTNAME
            END NAME
    FROM CC_CLAIMCONTACTROLE CCTRP
    INNER JOIN CCTL_CONTACTROLE TLCCTR ON TLCCTR.ID = CCTRP.ROLE
                                                 AND TLCCTR.TYPECODE IN ('agent', 'insured')
                                                 AND TLCCTR.RETIRED = 0 -- FOR AGENT
    INNER JOIN CC_CLAIMCONTACT CCTP ON CCTRP.ClaimContactID = CCTP.ID
                                              AND CCTP.RETIRED = 0 -- FOR AGENT
    INNER JOIN CC_CONTACT CTP ON CTP.ID = CCTP.CONTACTID AND CTP.RETIRED = 0
  )
  GROUP BY POLICYID
)
SELECT * FROM POLICY_CONTACTS;"""

# Execute the query using Snowpark
dataframe = session.sql(sql_query).to_pandas()

# Display the results in your Streamlit app
st.dataframe(dataframe)


-- MOVE THE TABLESPACE 
DECLARE
  mv_name VARCHAR2(100);
BEGIN
  FOR mv_rec IN (SELECT mview_name FROM ALL_MVIEWS WHERE OWNER = 'CCADMIN') LOOP
    mv_name := mv_rec.mview_name;
    EXECUTE IMMEDIATE 'alter table ' || mv_name || ' move tablespace CCMVIEW';
  END LOOP;
END;


-- MOVE THE TABLE SPACE
DECLARE
  mv_name VARCHAR2(100);
BEGIN
  FOR mv_rec IN (SELECT mview_name FROM ALL_MVIEWS WHERE OWNER = 'PCADMIN') LOOP
    mv_name := mv_rec.mview_name;
    EXECUTE IMMEDIATE 'alter table ' || mv_name || ' move tablespace PCMVIEW';
  END LOOP;
END;



-- DATA_SIZE MORE THAN 1000MB
WITH DATA_SIZE AS (
SELECT SEGMENT_NAME, BYTES/1024/1024 as MB FROM DBA_SEGMENTS
WHERE OWNER='PCADMIN')
SELECT * FROM DATA_SIZE WHERE MB > 1000
;

--DROP MVIEWS
BEGIN
  FOR i IN (SELECT mview_name FROM ALL_MVIEWS WHERE OWNER = 'PCADMIN') LOOP
    EXECUTE IMMEDIATE 'DROP Materialized  VIEW ' || i.mview_name;
  END LOOP;
END;


-- RUN AND CREATE THE MVIEWS 
EXEC gp_curr_state_pc_Mviews('PCDMSADMIN','PCADMIN');

--1 ST - AP 
--JOB SCheduler 
DECLARE
  mv_name VARCHAR2(100);
  CURSOR mv_cursor IS
SELECT MVIEW_NAME
    FROM ALL_MVIEWS
    WHERE OWNER IN('CCADMIN','PCADMIN') AND (MVIEW_NAME) IN ( 'CC_CLAIMCONTACT', 'CC_CLAIMCONTACTROLE', 'CC_CONTACT',
                                            'CCTL_CONTACTROLE', 'CC_CLAIM', 'CC_POLICY', 'CC_TRANSACTION', 'CC_CHECK',
                                            'CCTL_COSTTYPE', 'CCTL_TRANSACTIONSTATUS' ,'CCTL_LOSSCAUSE',
                                            'CCTL_POLICYSOURCE', 'CCTL_POLICYTYPE','CCTL_POLICYSTATUS','PC_POLICYPERIOD'
,'PC_PRODUCERCODE','PC_POLICYTERM','PC_POLICY','PC_JOB','PCTL_JOB','PC_POLICYLINE','PCTL_POLICYLINE'
,'PC_ACCOUNT','PCTL_POLICYPERIODSTATUS','PC_ORGANIZATION','PC_PRIMARYACCTLOC','PC_POLICYLOCATION'
,'PC_ADDRESS','PCTL_STATE','PCTL_ADDRESS','PC_CONTACT'); 
BEGIN
BEGIN FOR mv_rec IN mv_cursor LOOP DBMS_SYNC.REFRESH(mv_rec.mview_name); 
  DBMS_SCHEDULER.CREATE_JOB (
    job_name => 'REFRESH_ALL_MVS',
    job_type => 'PLSQL_BLOCK',
    job_action => DBMS_SYNC.REFRESH(mv_rec.mview_name);,
    schedule_type => 'INTERVAL',
    interval_expr => 'INTERVAL 4 HOUR'
  );
  END LOOP;
  END;
  
  DBMS_OUTPUT.PUT_LINE('Job created successfully!');
END;
/


-- 2 ND JON  - 1ST JOB 
--JOB SCheduler 
DECLARE
  mv_name VARCHAR2(100);
  CURSOR mv_cursor IS
    SELECT mview_name
    FROM ALL_MVIEWS
    WHERE OWNER = 'CCADMIN' AND substr(MVIEW_NAME, 1, 5) NOT IN ( 'PCTL_', 'CCTL_', 'BCTL_',
                                            'ABTL_', 'PCST_', 'VW_CU', 'PCST_', 'CCST_',
                                            'BCST_', 'ABST_' );  -- Adjust for specific schema if needed
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name => 'REFRESH_ALL_MVS',
    job_type => 'PLSQL_BLOCK',
    job_action => 'BEGIN FOR mv_rec IN mv_cursor LOOP DBMS_SYNC.REFRESH(mv_rec.mview_name); END LOOP; END;',
    schedule_type => 'INTERVAL',
    interval_expr => 'INTERVAL 4 HOUR'
  );
  
  DBMS_OUTPUT.PUT_LINE('Job created successfully!');
END;
/

-- 3RD JOB 



-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA33a4RfJXzlTyV/f+RQEz
mZLI1cdfs+hS6X10lxCm+WoLSDOFObRD10+09k2JAImjryJAxhZydj3R4YstBo16
p0HnGZZDvLL5OzcmmU8oV/9pwdsIQk25SsM+c+IhGxCgGcw5UKObVm9cR+okE/SL
Qcdo0RH/cP1CQwk1GgaLKOYShyjRHAuzJd7FMrrfi4mMur2BRGVjC1yz9vVKB6Hd
pM2vl+9b8TkzyT3YnwCbTV9HpEtDBFQxrs7ohZf3KaKs61+2kV0MNye3kEMmQSpK
6z3sfQG6MJP+7Wy03lo4Ukc+dqdBEetQfJTHuLv6oOTLLnOZ6Y+KOwnE1uLfxAr1
LQIDAQAB
-----END PUBLIC KEY-----

-----BEGIN ENCRYPTED PRIVATE KEY-----
MIIFNTBfBgkqhkiG9w0BBQ0wUjAxBgkqhkiG9w0BBQwwJAQQnf9kY0lradJxitgb
ZEkbtgICCAAwDAYIKoZIhvcNAgkFADAdBglghkgBZQMEASoEEBlSXJzGc3v0gksY
92TqTU4EggTQfFN4bjC9qLXshCqbBMjaK2SCCQGvkuj2fDXSCkxRogrxFZvvf5dH
GkE6DQmJh4C+rimm3iWAbzS4SCABuSek4EWP+flT4Z3BjT735AN+gHsxZlmT+PU3
pl9GSYlhRMOFIoEV/h5Rwr2O3T6BPQJA17OsiWeEgQlPB1d/jH9Suros6HqYMIL+
3om3np1qbzIAiSwPcgDvlFtcl9HM3Lz2pI4S5F091V9CReINJ8e4jIInfaVE1OY6
tRLTZUK3TXWzvntHKA0/CJR0oZCpGhTMFPoVgPTo+ln8kwX3jZrxvtzOLLqBHqw3
k5GAzO97CU2lTFTrVrEStoYENAVTQyfXDH+vNEsDQFxffty0rfCEZ51MWfzNEj92
j/q5Z7w/8Zzj1WCOIS+hpHOO4zWnQsUfcWNpJbT80gWQheWjnYIyTrSRDAz4Ay2e
oWa2h/sFI92ctxwEWIhK9Nrh23Scbr1cRtaqdfQY4knzUa+yo33AosO9z19rpQtF
BLE4u291tn/3YruGS7T0zH+HBEfOeV5D4e4Im9+nZz/JtTPsnQ6Xw3VSJ+mDW6jq
RigGVGM02spA+L27Yxl9hEFPg89tuGfnSXk8yvpUm347YI2Ee5bv17AJbIZ1Lr8u
Q5RyqO3P/UJmG8fTIP2cU8OwYpOe8Tvvu7SrpOzcpX3/AXKhnKPTR8borMIuUnp1
PsNT96eG0vHVYAheXfzAZUP7m2PNegsskt/NAcvLYBbPwMHR1WzS12lhc2d2DlAO
ZZE8Dei9AJws6D9L+Tmzkfyn8IMpK5kv99nciih9CdWdL72B0OCebttGO+ycgmhB
X0NzxP+0teJUTkNhJ5uBXiVA+kNNvZgoIWkFC6WOd7v9esfcKmNla0BZuA0coHDb
ZS1zGCzHHBG0ijj0HOz8De75sEOKhOA8DCnRj8UDEfHIGUXs+mJjrwT76f56+gi/
PKbOP1G55HwjR5F1pXAECt3JCJgZfWzqdoNs6REXHShtwMxG/nRb75ib2YPG90MS
38qFLilGsBkmVugyxsRP/NNWJZa7yH5Z+AEpz23GdAPIeJDrf2N4+oYgvnirMaFl
kbJxtZMOBq1OEyLk/dcP4+14HeUepDFr1WSqrNrYmhxNvJaXyUhXqR7Kg3bffoER
1tzxahzTs9b6ErpZfyRP2oCD/3LI+8YkDjqGjTf06/8kjokG2f7ixjtL7yx9fE/u
vkcDQKoCKhAJ1JsmlljBYCRCe75up/ZItnF2VRDDJ7GMBz6O3I/pfWzWmYaxfANr
eag3xks92d/JcMRI1nIxGTMH6SONxbHkG6ycXLHtkbH6l9fkO7NiU0MX8vhTicXV
Cv7387SSp/XvzP00xIW/OwBx5rJfXvH2IIXeNe7k3F8uLBlcTbSoLrzMCkSw18pz
kc3NtdmU55CpyyKJhwoZ07U3eDMel118eEE5j0xwrsJJHXGOTaIO60Q84gAaFLhT
16pNNEvopmUe6D65Jynd8JFoR1wBjNTgCoAoX9DRxPIvna503emFwSjsE4Mphk9q
H2AQOzLMMWHy46IOOertYzc2TpKhXiya8xsEJG18yDRHoGHR4m2dbQVeI3rB/AtV
EQmm8izuG3YaGGpIqp7/0ZqquanCpCZ1nWmbV39nvxEnoa6mIa0vxlg=
-----END ENCRYPTED PRIVATE KEY-----



-- STEP 1 
create or replace view CMS.VW_BUILDING as (

)
-- STEP2 
insert into CLAIMS_QA.ETL_CTRL.JC_MATILLION_SOURCE_QUERY_LS VALUES('CCST_BUILDING', 'CURATED','SELECT * FROM CMS.VW_BUILDING', 'PUBLICID','TYPE2' ,TRUE,'CMS');

--STEP 3 
    -- Verify ccst_xxx exists on EDW
-- STEP 4
-- MATILLION PATH - CIG_QA > CIG_GW_SAAS_QA > CIG_FRAMEWORK >> LS_LOAD >> 