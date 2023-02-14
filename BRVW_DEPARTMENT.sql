--------------------------------------------------------
--  DDL for View BRVW_DEPARTMENT
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "DATALAKE"."BRVW_DEPARTMENT" ("DEPT", "DEPARTMENT_NUMBER", "DEPARTMENT_NAME", "BUSINESS_LINE", "BUSINESS_LINE_NAME", "MAJOR_LINE", "MAJOR_LINE_NAME", "CORE_LINE_OF_BUSINESS","CLAIM_SOURCE") AS 
  SELECT dept.dept,
       dept.department_number,
       dept.department_name,
       bline.business_line,
       CASE
            WHEN dept.department_number IN (29,
                                            114,
                                            120,
                                            121,
                                            125,
                                            127,
                                            129)
            THEN
                'Farm Package'
            WHEN bline.business_line_name = 'Farm'
            THEN    
                'Farmowner'
            WHEN bline.business_line_name = 'Manual'
            THEN    
                'Commercial Package'
            ELSE
                bline.business_line_name
        END
            AS business_line_name,
       mline.major_line,
       mline.major_line_name,
       CASE
          WHEN mline.major_line IN (4, 7)
          THEN
             'Personal'
          WHEN mline.major_line IN (6)
          THEN
             'Farm'
          WHEN dept.department_number IN (29,
                                          114,
                                          120,
                                          121,
                                          125,
                                          127)
          THEN
             'Farm'
          ELSE
             'Commercial'
       END
          AS core_line_of_business
       , 'CMS' AS CLAIM_SOURCE   
  FROM (SELECT dept,
               business_line,
               major_line,
               dept_nbr AS department_number,
               dept_desc AS department_name
          FROM (SELECT dept.*,
                       ROW_NUMBER ()
                          OVER (PARTITION BY dept ORDER BY load_date DESC)
                          dept_rowmax
                  FROM DATALAKE.DAILY_DEPT dept)
         WHERE dept_rowmax = 1) dept
       INNER JOIN
       (SELECT business_line, business_line_name
          FROM (SELECT bline.*,
                       ROW_NUMBER ()
                       OVER (PARTITION BY business_line
                             ORDER BY load_date DESC)
                          bline_rowmax
                  FROM DATALAKE.DAILY_BUSINESS_LINE bline)
         WHERE bline_rowmax = 1) bline
          ON dept.business_line = bline.business_line
       INNER JOIN
       (SELECT major_line, major_line_name
          FROM (SELECT mline.*,
                       ROW_NUMBER ()
                       OVER (PARTITION BY major_line ORDER BY load_date DESC)
                          mline_rowmax
                  FROM DATALAKE.DAILY_MAJOR_LINE mline)
         WHERE mline_rowmax = 1) mline
          ON dept.major_line = mline.major_line
 UNION ALL
      SELECT PD.ID AS dept,PD.DEPTNUMBER AS department_number, PD.DEPTNAME AS department_name
      ,TLPTY.ID AS  business_line
      , CASE
            WHEN (TLPTY.NAME = 'Businessowners')
                THEN
                 'Business Owner'
            WHEN (TLPTY.NAME = 'Comm/Farm Auto')
                THEN 
                    CASE WHEN (P.POLICYNUMBER LIKE '%FAA%' OR P.POLICYNUMBER LIKE '%SAA%'  OR P.POLICYNUMBER LIKE '%GAA%')
                        THEN 'Farm Auto'
                        ELSE 'Commercial Auto'
                    END
            WHEN (TLPTY.NAME = 'Farmowners')
                THEN 'Farm'
             WHEN (TLPTY.NAME = 'Commercial Manual')
                THEN 'Manual'      
              WHEN (TLPTY.NAME = 'Homeowners')
                THEN 'Homeowner' 
            WHEN (TLPTY.name = 'Personal Auto')
                  THEN 'Personal Automobile' 
           WHEN (TLPTY.name = 'Personal Excess')
              THEN 'Personal Umbrella' 
            ELSE TLPTY.NAME
      END                        AS business_line_name
      ,TLPTY.ID AS  major_line
      , CASE
            WHEN TLPTY.NAME IN ('Businessowners', 'Commercial Umbrella', 'Commercial Manual')
                THEN 'Commercial'
            WHEN TLPTY.NAME IN ('Homeowners', 'Personal Excess', 'Dwelling Fire' , 'Personal Auto')
                THEN 'Personal'
            WHEN TLPTY.NAME IN ('Farm Umbrella', 'Farmowners')
                THEN 'Farm'                    
            WHEN (TLPTY.NAME = 'Comm/Farm Auto')
                THEN 
                    CASE WHEN (P.POLICYNUMBER LIKE '%FAA%' OR P.POLICYNUMBER LIKE '%SAA%'  OR P.POLICYNUMBER LIKE '%GAA%')
                        THEN 'Farm'
                        ELSE 'Commercial'
                    END
        END AS major_line_name
        , '' AS core_line_of_business
        , 'CC' AS CLAIM_SOURCE
      FROM DLAKEDEV.DAILY_CC_CLAIM C
      INNER JOIN DLAKEDEV.DAILY_CC_POLICY P ON P.ID=C.POLICYID AND P.RETIRED=0
      INNER JOIN DLAKEDEV.DAILY_CCTL_POLICYTYPE TLPTY ON TLPTY.ID=P.POLICYTYPE AND TLPTY.RETIRED=0      
      LEFT OUTER JOIN DLAKEDEV.DAILY_CCX_POLICYDEPARTMENT_EXT PD ON P.POLICYDEPARTMENT_EXTID = PD.ID AND PD.RETIRED = 0
  
          ; 
