 --------------------------------------------------------
--  DDL for View VW_STAFF
--------------------------------------------------------

CREATE OR REPLACE FORCE EDITIONABLE VIEW "DLAKEDEV"."VW_STAFF" ("STAFF", "STAFFNAME", "FUNCTIONAL_ROLE", "CMS_USER_FUNCTION_ROLE", "BRANCH", "REGION_NBR", "UNIT_NBR", "STAFF_TRANS_DATE", "STAFF_LOAD_DATE","CLAIM_SOURCE") AS 
  select daily_staff.staff,
  trim(trim(daily_staff.last_name) || ', ' || trim(daily_staff.first_name) || ' ' || trim(daily_staff.middle_name)) as staffname
      ,nvl(daily_staff.functional_role,0) as functional_role,
      nvl(daily_staff.cms_user_function_role,-1) as cms_user_function_role
      ,daily_staff.branch
      ,case when region is null then -1 else daily_staff.branch end region_nbr
      ,case when region is null then -1 when daily_staff.branch=142 then nvl(cms_unit,0) else daily_staff.branch end unit_nbr
      ,trunc(last_modified) as staff_trans_date,
      load_date as staff_load_date,
      'CMS' AS CLAIM_SOURCE
from daily_staff
left outer join l_region on daily_staff.branch=l_region.branch
UNION ALL 
SELECT 
  CTE.ID AS STAFF, 
  CASE WHEN CTE.NAME IS NOT NULL
    THEN CTE.NAME 
         WHEN CTE.FIRSTNAME IS NOT NULL AND CTE.LASTNAME IS NOT NULL
        THEN TRIM(TRIM(CTE.LASTNAME) || ', ' || TRIM(CTE.FIRSTNAME)  || ' ' || CTE.MIDDLENAME)
  END STAFFNAME,
  TO_NUMBER(0) AS FUNCTIONAL_ROLE ,
  TO_NUMBER(0) AS CMS_USER_FUNTIONAL_ROLE,
   CASE WHEN CTE.AGENCYDOMICILESTATE_EXT IS NOT NULL THEN NULL
        WHEN CTE.AGENCYDOMICILESTATE_EXT IN('CA') THEN CBM.ST_CA
        WHEN CTE.AGENCYDOMICILESTATE_EXT IN('NV') THEN CBM.ST_NV
        WHEN CTE.AGENCYDOMICILESTATE_EXT IN('OR') THEN CBM.ST_OR
        WHEN CTE.AGENCYDOMICILESTATE_EXT IN('AZ') THEN CBM.ST_AZ
        WHEN CTE.AGENCYDOMICILESTATE_EXT IN('WA') THEN CBM.ST_WA
        WHEN CTE.AGENCYDOMICILESTATE_EXT IN('NM') THEN CBM.ST_NM
   END AS BRANCH,
  TO_NUMBER(0) AS REGION_NBR,
  TO_NUMBER(0) AS UNIT_NBR,
  TRUNC(CTE.UPDATETIME) AS STAFF_TRANS_DATE,
   CTE.LOAD_DATE AS STAFF_LOAD_DATE,
  'CC' AS CLAIM_SOURCE
FROM 
DLAKEDEV.DAILY_CC_CONTACT CTE
LEFT OUTER JOIN DLAKEDEV.DAILY_CC_USER STADJU ON  STADJU.CONTACTID = CTE.ID AND STADJU.RETIRED=0
LEFT OUTER JOIN DLAKEDEV.DAILY_CC_GROUPUSER SPRVGU ON SPRVGU.USERID=STADJU.ID
LEFT OUTER JOIN DLAKEDEV.DAILY_CC_GROUP SPRVG ON SPRVG.ID=SPRVGU.GROUPID AND SPRVG.RETIRED=0
LEFT OUTER JOIN DLAKEDEV.DAILY_CLAIM_BRANCH_MAPPING CBM ON CBM.GROUP_ID = SPRVG.ID
;


SELECT AGENCYDOMICILESTATE_EXT FROM DAILY_CC_CONTACT
WHERE AGENCYDOMICILESTATE_EXT IS NOT NULL;