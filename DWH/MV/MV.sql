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

-- job scheduler 
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