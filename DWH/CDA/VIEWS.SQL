create or replace procedure   gp_curr_state_views (p_raw_schema_nm varchar2, p_merged_schema_nm varchar2)  as 

TYPE TBL_VARCHAR IS TABLE OF VARCHAR2(32767)
INDEX BY PLS_INTEGER;
T_TABLE_NAME TBL_VARCHAR;
T_VIEW_NAME TBL_VARCHAR;

V_SQL VARCHAR2(32767);
V_COLUMNS_SQL CLOB;

BEGIN
-- Select existing views from MERGE SCHEMA
SELECT VIEW_NAME
BULK COLLECT INTO T_VIEW_NAME
FROM ALL_VIEWS
WHERE OWNER = p_merged_schema_nm;

-- select all tables from RAW SHEMA 

SELECT table_name
BULK COLLECT INTO T_TABLE_NAME
FROM (SELECT
    '01-retirable_ctlentity' AS entity_grp,
    t.table_name             AS table_name
FROM
         all_tab_columns c
    JOIN all_tables t ON c.owner = t.owner
                         AND c.table_name = t.table_name
WHERE
        t.owner = p_raw_schema_nm
    AND UPPER(c.column_name) = 'RETIRED'
    AND substr(t.table_name, 1, 5) IN ( 'PCTL_', 'CCTL_', 'BCTL_',
                                        'ABTL_' )
    AND substr(t.table_name, 1, 5) NOT IN ( 'PCST_', 'CCST_', 'BCST_',
                                            'ABST_' )
UNION
SELECT
    '02-retirable_nonctlentity' AS entity_grp,
    t.table_name                AS table_name
FROM
         all_tab_columns c
    JOIN all_tables t ON c.owner = t.owner
                         AND c.table_name = t.table_name
WHERE
        t.owner = p_raw_schema_nm
    AND UPPER(c.column_name) = 'RETIRED'
    AND substr(t.table_name, 1, 5) NOT IN ( 'PCTL_', 'CCTL_', 'BCTL_',
                                            'ABTL_', 'PCST_', 'VW_CU', 'PCST_', 'CCST_',
                                            'BCST_', 'ABST_' )
UNION
SELECT
    '03-effdated_entity' AS entity_grp,
    t.table_name         AS table_name
FROM
         all_tab_columns c
    JOIN all_tables t ON c.owner = t.owner
                         AND c.table_name = t.table_name
WHERE
        t.owner = p_raw_schema_nm
    AND UPPER(c.column_name) = 'BRANCHID'
    AND substr(t.table_name, 1, 5) NOT IN ( 'PCTL_', 'PCST_', 'VW_CU',
                                            'PCST_' )
    AND t.table_name <> 'PC_PRODUCERCODE'
UNION
SELECT
    '04-allother_entities' AS entity_grp,
    t.table_name         AS table_name
FROM
         all_tables t 
WHERE
        t.owner = p_raw_schema_nm
    AND not exists (SELECT 1 FROM all_tab_columns c1
                            JOIN all_tables t1 ON (c1.owner = t1.owner AND
                                                    c1.table_name = t1.table_name)
                            WHERE t1.table_name  = t.table_name AND
                           ( UPPER(c1.column_name)  in ('BRANCHID','RETIRED') OR
                            substr(t1.table_name, 1, 5)  IN ( 'PCTL_', 'PCST_', 'VW_CU',
                                             'CCTL_', 'BCTL_','ABTL_',  
                                             'CCST_', 'BCST_', 'ABST_' ) OR
                                t1.table_name = 'PC_PRODUCERCODE'))             
 );        

-- Drop all existing view from MERGE SCHEMA
FOR nIndx IN 1..T_VIEW_NAME.COUNT
LOOP
    EXECUTE IMMEDIATE 'DROP VIEW '||p_merged_schema_nm||'.'||T_VIEW_NAME(nIndx);
END LOOP;


--Create view in MERGE SCHEMA for each table in RAW SCHEMA 
FOR nIndx IN 1..T_TABLE_NAME.COUNT
LOOP
    
    SELECT LISTAGG(UPPER(COLUMN_NAME), ', ') AS COLUMN_NAME
    INTO V_COLUMNS_SQL
    FROM all_tab_columns 
    WHERE OWNER = p_merged_schema_nm AND TABLE_NAME = T_TABLE_NAME(nIndx);
 
   V_SQL := 'CREATE OR REPLACE VIEW ' || p_merged_schema_nm || '.' || 'VW_' || T_TABLE_NAME(nIndx)||' AS 
				SELECT t0.* 
 					FROM (SELECT row_number() OVER (PARTITION BY "id" order by lpad("gwcbi___seqval_hex", 32,' || '''0''' || ') desc) as sequencing_num, 
								 ' || V_COLUMNS_SQL || ' 
			 				FROM ' || p_raw_schema_nm || '.' || T_TABLE_NAME(nIndx) || ' t) t0 
 				where t0.sequencing_num = 1' ;
    EXECUTE IMMEDIATE V_SQL;              
END LOOP;

END;