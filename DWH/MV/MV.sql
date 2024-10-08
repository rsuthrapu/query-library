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

--INVALID OBJECTS
SELECT * FROM USER_OBJECTS
WHERE STATUS NOT IN('VALID');


-- COMPLIE INVALIDA OBJECTS
BEGIN
  EXECUTE IMMEDIATE 'alter materialized view CC_RECTACCOUNTTRANSACTION refresh COMPLETE';
END;
/

--STOP JOB SCHEDULE 
BEGIN
    DBMS_SCHEDULER.STOP_JOB(job_name => 'REFRESH__ALL_CC_MVIEWS');
END;
/


SELECT 
mview_name,
       TO_CHAR(LAST_REFRESH_END_TIME, 'DD/MM/YYYY HH24:MI:SS') AS formatted_refresh_time, COMPILE_STATE, STALENESS
--MV.*
FROM DBA_MVIEWS MV
WHERE 
--       TO_CHAR(LAST_REFRESH_END_TIME, 'DD/MM/YYYY HH24:MI:SS') < '23/04/2024 19:38:06'
--       AND
  OWNER='CCADMIN'  and COMPILE_STATE = 'VALID' and STALENESS <> 'FRESH';

   begin 
 DBMS_MVIEW.REFRESH('CCX_EVALUATIONDAMAGE_EXT,CCX_ECONOMICDAMAGE_EXT,CCX_COMPARATIVEFAULT_EXT,CC_EVALUATION,CC_ACTIVITY,CC_CLAIMMETRIC,
CC_CLAIMMETRICRECALCTIME,CC_EXPOSURE,CC_NOTE,CC_RESERVELINE,CC_TRANSACTION,CC_CLAIMINDICATOR,CC_TRANSACTIONLINEITEM,CC_CLAIMRPT,CC_TRANSACTIONSET,
CC_EXPOSURERPT,CC_TACCOUNTTRANSACTION,CC_CHECKRPT,CC_TACCOUNTLINEITEM,CC_ADDRESS,CC_CHECK,CC_EXPOSUREMETRIC,CC_TACCOUNT,CC_DOCUMENT,
CC_USERSETTINGS,CCX_ALERT_ACC,CCX_RISKUPDATE_ACC,CC_CLAIMISOMATCHREPORT,CC_CLAIMCONTACTROLE,CC_CLAIMCONTACT,CC_MATTER,CC_WORKFLOW,CCX_RISKREFERRAL_EXT,
CCX_RISKREFERRALQUESTION_EXT,CC_SERVICEREQSTATEMENTLINE,CC_SERVREQMETRIC,CC_SERVICEREQUESTSTATEMENT,CC_SERVICEREQUESTCHANGE,CC_SERVICEREQUEST,
CC_RICODING,CC_RITACCOUNTTRANSACTION,CC_RITACCOUNTLINEITEM,CC_RITRANSACTION,CC_RITRANSACTIONSET,CC_RITACCOUNT,CC_INCIDENT,CC_SUBROADVERSEPARTY,
CCX_HANDLINGCHAR_ACC,CCX_SCORINGINFO_ACC,CC_POLICY,CC_RIAGREEMENT,CC_RIAGREEMENTGROUP,CC_SUBROGATIONSUMMARY,CC_LITSTATUSTYPELINE,
CC_GROUP_ASSIGN,CC_RISKUNIT,CC_POLICYLOCATION,CC_PROPERTYWATERDAMAGE,CC_SUBROGATION,CCX_RISKREFERRALDOCUMENTS,CC_POLICYPERIOD,CCX_POLICYDEPARTMENT_EXT,
CCX_RUDEDUCTIBLE_EXT,CC_CLAIMINFO,CC_COVERAGE,CC_COVERAGETERMS,CC_ENDORSEMENT,CC_VEHICLE,CC_SITRIGGER,CC_PROPERTYFIREDAMAGE,CC_COVERAGELINE,
CC_AGGREGATELIMIT,CC_BUILDING,CC_GROUP,CC_BULKINVOICE,CCX_CCCAPPRAISALINFO_EXT,CC_SERVICEREQINSTRUCTIONSVC,CC_SERVICEREQUESTINSTRUCTION,
CC_NEGOTIATION,CC_NEGOTIATIONLINE,CC_OTHERCVGDET,CC_METROREPORT,CC_RECTACCOUNTTRANSACTION,CC_RECOVERYTACCOUNTLINEITEM,CC_RECOVERYTACCOUNT,
CC_USERROLEASSIGN,CC_BODYPART,CC_CLAIMSPECPYMTPREAPPROVAL,CC_CLAIMASSOC,CC_INJURYDIAGNOSIS,CC_PROPERTYITEM,CC_INBOUNDFILE,CC_USER,
CC_CLAIM,CCX_MIRREPORTABLEHIST_ACCMIT,CCX_MIRREPORTABLE_ACC,CC_CONTACTTAG,CC_CONTACT','C', atomic_refresh=>FALSE);  
 end;

 -- Analyze MVIEW
EXECUTE IMMEDIATE 'ANALYZE  MATERIALIZED VIEW ' || mv_rec.mview_name || ' COMPUTE STATISTICS';

 -- VIEW last analyzed i.e. COMPUTE STATISTICS
    SELECT owner, table_name, num_rows, avg_row_len, last_analyzed
FROM dba_tables
WHERE owner = 'PCADMIN' and table_name = 'PC_UWISSUE';