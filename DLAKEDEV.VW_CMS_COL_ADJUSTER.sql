   select C.ID AS claim, TLLC.ID AS cause_of_loss, '' AS CMS_UNIT, '' AS BRANCH, CRE.USERNAME AS CREATE_ID,
        '' AS FIRST_MODIFIED , CRE.USERNAME AS AUDIT_ID , C.UPDATETIME AS LAST_MODIFIED,nvl(SPRVUCT.ID,0) as adj_supervisor,
          '' AS IND_HSB_ADJUSTER,'' AS HOME_OFFICE_SUPERVISOR,'' AS SETTLEMENT_AUTHORITY,
          CASE WHEN CTIA.NAME IS NOT NULL
            THEN CTIA.NAME 
            WHEN CTIA.FIRSTNAME IS NOT NULL AND CTIA.LASTNAME IS NOT NULL
            THEN CTIA.LASTNAME || ' ' || CTIA.FIRSTNAME
            END INDEPENDENT_ADJUSTER ,'' AS ASSIST_ADJUSTER,'' AS DATE_ASSIGNED, COV.ID coverage
            , '' STAFF,'' AS IND_ADJUSTER_COMPLETED, '' AS ASSIST_ADJUSTER_COMPLETED,CCT.ID AS claimant
            , '' AS HSB_ADJUSTER, '' AS ASSIGNED_DATE,'' AS INCURREDLOSS_DATE
            , '' AS IS_MAILPROCESSED, '' AS IS_CAT, '' AS AUTHORISED_BY, '' AS AUTHORISED_DATE
            , SRIA.ASSIGNMENTDATE AS IA_OPEN_DATE,
            CASE WHEN SRIA.CLOSEDATE IS NOT NULL
                                THEN SRIA.CLOSEDATE
                                ELSE  SRC.UPDATETIME 
                              END AS IA_CLOSE_DATE 
           , '' AS SUBRO_DEMAND, '' AS AA_OPEN_DATE, '' AS AA_CLOSE_DATE , '' AS AUTO_ASSIGNED_DATE, '' AS NAWDATEFLAG  
           ,'' AS ADJ_ISO_INIT_DISPLAY , '' AS ADJ_ISO_REPLACE_DISPLAY, '' AS SUP_ISO_INIT_DISPLAY
           ,'' AS SUP_ISO_REPLACE_DISPLAY , '' AS EXPENSE_SETTLEMENT_AUTHORITY , '' AS EXPENSE_AUTHORISED_BY
           , '' AS EXPENSE_AUTHORISED_DATE, tr.load_date AS LOAD_DATE
         ,nvl(STADJU.ID,0) as adj_staff
         ,nvl(0,-1) as adj_hosupervisor, nvl(0,-1) as adj_assistant
         ,nvl(CTIA.ID,0) as adj_independent
         ,trunc(TR.UPDATETIME) as cmscol_trans_date, tr.load_date as cmscol_load_date , 'CC' AS CLAIM_SOURCE
   from 
   DLAKEDEV.daily_CC_CLAIM C 
   INNER JOIN DLAKEDEV.daily_CC_CLAIMCONTACT  CCT ON CCT.CLAIMID=C.ID AND CCT.RETIRED=0 
   LEFT OUTER JOIN DLAKEDEV.daily_CCTL_LOSSCAUSE TLLC ON TLLC.ID = C.LOSSCAUSE AND TLLC.RETIRED = 0
   INNER JOIN DLAKEDEV.daily_CC_EXPOSURE EX ON EX.CLAIMID=C.ID AND EX.RETIRED=0
   INNER JOIN DLAKEDEV.daily_CC_TRANSACTION  TR ON TR.CLAIMID = C.ID AND EX.ID=TR.EXPOSUREID AND TR.RETIRED = 0
   LEFT OUTER JOIN DLAKEDEV.daily_CC_COVERAGE COV ON COV.ID=EX.COVERAGEID AND COV.RETIRED=0
   LEFT OUTER JOIN DLAKEDEV.daily_CC_USER STADJU ON  STADJU.ID = EX.ASSIGNEDUSERID AND STADJU.RETIRED=0
   LEFT OUTER JOIN DLAKEDEV.daily_CC_GROUPUSER SPRVGU ON SPRVGU.USERID=STADJU.ID
   LEFT OUTER JOIN DLAKEDEV.daily_CC_GROUP SPRVG ON SPRVG.ID=SPRVGU.GROUPID AND SPRVG.RETIRED=0 
   LEFT OUTER JOIN DLAKEDEV.daily_CC_USER SPRVU ON  SPRVU.ID = SPRVG.SUPERVISORID  AND SPRVU.RETIRED=0
   LEFT OUTER JOIN DLAKEDEV.CC_CREDENTIAL  CRE ON CRE.ID = SPRVU.CREDENTIALID AND CRE.RETIRED =0
   LEFT OUTER JOIN DLAKEDEV.daily_CC_CONTACT  SPRVUCT ON SPRVUCT.ID = SPRVU.CONTACTID AND SPRVUCT.RETIRED=0
   INNER JOIN DLAKEDEV.daily_CC_SERVICEREQUEST SRIA ON SRIA.CLAIMID=C.ID 
   LEFT OUTER JOIN DLAKEDEV.CC_SERVICEREQUESTCHANGE SRC ON SRC.SERVICEREQUESTID =  SRIA.ID
   INNER JOIN DLAKEDEV.daily_CC_CONTACT CTIA ON CTIA.ID=SRIA.SPECIALISTID AND CTIA.RETIRED=0 
   ;

