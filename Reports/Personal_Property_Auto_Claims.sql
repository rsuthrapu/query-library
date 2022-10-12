WITH CLAIM_DATA AS (
            SELECT
                C.ID            AS CLAIM_KEY,
                P.ID            AS POLICY_KEY,
                p.PolicyNumber  AS POLICY_SEARCH_NBR,
                P.ExpirationDate AS TERM_EXPIRATION_DATE,
                TO_NUMBER(P.ProducerCode)  AS AGENCY_CODE,
                TO_NUMBER(C.CLAIMNUMBER)   AS CLAIM_NBR,
                TLLC.NAME       AS CAUSE_NAME,
                C.LOSSDATE      AS DATE_OF_LOSS,
                TLS.NAME        AS CLAIM_STATUS,
              --  INC.FAULT_EXT  AS FAULT
                MAX(INC.FAULT_EXT) AS FAULT
            FROM
                CC_CLAIM@ECIG_TO_CC_LINK   C
                INNER JOIN CC_POLICY@ECIG_TO_CC_LINK  P ON C.POLICYID = P.ID AND P.RETIRED = 0
                INNER JOIN CCTL_POLICYTYPE@ECIG_TO_CC_LINK TLPTY ON TLPTY.ID=P.POLICYTYPE AND TLPTY.ID IN(10014,10009,10006,10012) AND  TLPTY.RETIRED=0
                LEFT OUTER JOIN CCTL_CLAIMSTATE@ECIG_TO_CC_LINK TLS ON TLS.ID = C.STATE AND TLS.RETIRED = 0
                LEFT OUTER JOIN CCTL_LOSSCAUSE@ECIG_TO_CC_LINK              TLLC ON TLLC.ID = C.LOSSCAUSE AND TLLC.RETIRED = 0
                LEFT OUTER JOIN CC_INCIDENT@ECIG_TO_CC_LINK  INC ON INC.ClaimID = C.ID AND INC.RETIRED = 0
                LEFT OUTER JOIN CCTL_INCIDENT@ECIG_TO_CC_LINK TLINC ON TLINC.ID=INC.SUBTYPE AND TLINC.TYPECODE IN ('VehicleIncident') AND TLINC.RETIRED=0
               -- WHERE TRUNC(C.LOSSDATE) > LAST_DAY(ADD_MONTHS(TO_DATE(SYSDATE,'DD-MON-YYYY'),-72))
                GROUP BY C.ID, P.ID, p.PolicyNumber, P.ExpirationDate, TO_NUMBER(P.ProducerCode), TO_NUMBER(C.CLAIMNUMBER), TLLC.NAME, C.LOSSDATE, TLS.NAME
               ) ,
             CRU_DATA AS (
              SELECT RREF.CLAIMID, CASE WHEN COUNT  (DISTINCT (RREF.CLAIMID)) > 0 THEN
                                        1
                                        ELSE 0
                                   END AS CRU_INDICATOR
                  FROM CCX_RISKREFERRAL_EXT@ECIG_TO_CC_LINK RREF
                  INNER JOIN CLAIM_DATA CD ON CD.CLAIM_KEY=RREF.CLAIMID 
              GROUP BY RREF.CLAIMID      
             ),
             POLICY_CONTACTS AS(
            select POLICYID
            , MAX(AGENCYDOMICILESTATE_EXT) AS DOMICILE_STATE
            , MAX(DECODE(CTROLE_POLICY_TYPECODE, 'agent', NAME)) AS AGENCY_NAME
            , MAX(DECODE(CTROLE_POLICY_TYPECODE, 'underwriter', NAME)) AS UNDERWRITER
            from (
                SELECT
                         CCTRP.POLICYID
                        , CTP.AGENCYDOMICILESTATE_EXT
                        , TLCCTR.TYPECODE AS CTROLE_POLICY_TYPECODE
                        , CASE WHEN CTP.NAME IS NOT NULL
                            THEN CTP.NAME 
                            WHEN CTP.FIRSTNAME IS NOT NULL AND CTP.LASTNAME IS NOT NULL
                            THEN CTP.LASTNAME || ' ' || CTP.FIRSTNAME
                             WHEN CTP.FIRSTNAME IS NOT NULL
                            THEN CTP.FIRSTNAME
                             WHEN CTP.LASTNAME IS NOT NULL
                            THEN CTP.LASTNAME 
                --                ELSE CD.INSURED_NAME
                            END NAME       
                FROM
                CLAIM_DATA CD 
                INNER JOIN CC_CLAIMCONTACTROLE@ECIG_TO_CC_LINK CCTRP ON CCTRP.POLICYID=CD.POLICY_KEY  AND CCTRP.RETIRED=0 -- FOR AGENT
                INNER JOIN CCTL_CONTACTROLE@ECIG_TO_CC_LINK TLCCTR ON TLCCTR.ID=CCTRP.ROLE AND TLCCTR.TYPECODE IN ('agent', 'insured', 'underwriter') AND TLCCTR.RETIRED=0 -- FOR AGENT
                INNER JOIN CC_CLAIMCONTACT@ECIG_TO_CC_LINK CCTP ON  CCTRP.ClaimContactID=CCTP.ID AND CCTP.RETIRED=0 -- FOR AGENT
                INNER JOIN CC_CONTACT@ECIG_TO_CC_LINK CTP ON CTP.ID=CCTP.CONTACTID AND CTP.RETIRED=0)
                GROUP BY POLICYID
            ),
            CLAIMANT_TRANS_CC AS(
            SELECT CLAIM_KEY, SUM(DECODE(TRANS_TYPE,'Subrogation',0,'Salvage',0,'Deductible',0,LTRIM('Credit to expense'),0,LTRIM('Credit to loss'),0,
                        (NVL(LOSS_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)
                        -NVL(LOSS_PAID,0)-NVL(UNALLOC_EXPENSE_PAID,0)-NVL(ALLOC_EXPENSE_PAID,0))))AS RESERVE,
                    SUM(NVL(LOSS_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)) AS TOTAL_PAID,
                    SUM(CASE WHEN TRANS_TYPE IN ('Subrogation' , 'Salvage' , 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))
                      THEN NVL(LOSS_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)
                      ELSE 
                      NVL(LOSS_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0) END) AS LOSS_ALAE_INCURRED,
                     MAX(DATE_RSRVE_CHNGED) AS DATE_RESERVE_CHANGED 
           FROM(
                      SELECT
                       CD.CLAIM_KEY 
                    , TRLI.CLAIMAMOUNT
                    , TLRC.NAME   AS TRANS_TYPE
                    , TR.EXPOSUREID  AS TR_EXPOSUREID
                    ,   CASE
                            WHEN TLTR.NAME = 'Payment'
                                 AND TLCSTTY.TYPECODE = 'claimcost' THEN 
                                ( TRLI.CLAIMAMOUNT )
                      END                        AS LOSS_PAID 
                    , CASE
                            WHEN TLTR.NAME = 'Payment'
                                 AND TLCSTTY.TYPECODE = 'aoexpense' THEN 
                                ( TRLI.CLAIMAMOUNT )
                      END                        AS UNALLOC_EXPENSE_PAID 
                    , CASE
                            WHEN TLTR.NAME = 'Payment'
                                 AND TLCSTTY.TYPECODE = 'dccexpense' THEN 
                                ( TRLI.CLAIMAMOUNT )
                      END                         AS ALLOC_EXPENSE_PAID 
                    -- RESERVES
                    , CASE
                            WHEN TLTR.NAME = 'Reserve'
                                 AND TLCSTTY.TYPECODE = 'claimcost' THEN 
                                ( TRLI.RESERVINGAMOUNT )
                      END                          AS LOSS_RESERVE
                    , CASE
                            WHEN TLTR.NAME = 'Reserve'
                                 AND TLCSTTY.TYPECODE = 'aoexpense' THEN 
                                ( TRLI.RESERVINGAMOUNT )
                        END                        AS UNALLOC_EXPENSE_RESERVE,
                        CASE
                            WHEN TLTR.NAME = 'Reserve'
                                 AND TLCSTTY.TYPECODE = 'dccexpense' THEN 
                                ( TRLI.RESERVINGAMOUNT )
                        END                        AS ALLOC_EXPENSE_RESERVE   
                     , CASE 
                           WHEN  TLTR.NAME = 'Reserve' THEN
                             TR.UPDATETIME  
                           END AS DATE_RSRVE_CHNGED
                    FROM CLAIM_DATA CD 
                    INNER JOIN CC_TRANSACTION@ECIG_TO_CC_LINK                TR ON TR.CLAIMID = CD.CLAIM_KEY AND TR.RETIRED = 0
                    LEFT OUTER JOIN CCTL_RECOVERYCATEGORY@ECIG_TO_CC_LINK    TLRC ON TLRC.ID   = TR.RECOVERYCATEGORY AND TLRC.RETIRED = 0
                    INNER JOIN CCTL_TRANSACTION@ECIG_TO_CC_LINK              TLTR ON TLTR.ID = TR.SUBTYPE AND TLTR.RETIRED = 0
                    INNER JOIN CC_TRANSACTIONLINEITEM@ECIG_TO_CC_LINK        TRLI ON TRLI.TRANSACTIONID = TR.ID AND TRLI.RETIRED = 0
                    LEFT OUTER JOIN CCTL_TRANSACTIONSTATUS@ECIG_TO_CC_LINK   TLTRS ON TLTRS.ID = TR.STATUS AND TLTRS.RETIRED = 0
                    LEFT OUTER JOIN CCTL_COSTTYPE@ECIG_TO_CC_LINK            TLCSTTY ON TLCSTTY.ID = TR.COSTTYPE AND TLCSTTY.RETIRED = 0)
                   -- WHERE TRUNC(DATE_RSRVE_CHNGED) <= TO_DATE(SYSDATE,'DD-MON-YYYY')
                  --  AND TRUNC(DATE_RSRVE_CHNGED) > LAST_DAY(ADD_MONTHS(TO_DATE(SYSDATE,'DD-MON-YYYY'),-72))
                    GROUP BY CLAIM_KEY
                      ),
            PL_AUTO_PRTY_CC_RPT AS
            (
              SELECT DISTINCT
              CD.POLICY_SEARCH_NBR,
              CD.TERM_EXPIRATION_DATE ,
              CD.AGENCY_CODE,
              PC.AGENCY_NAME,
              PC.DOMICILE_STATE,
              CD.CLAIM_NBR,
              CD.DATE_OF_LOSS,
              CD.CAUSE_NAME,
              nvl(CD.FAULT,0) AS "%_AT_FAULT",
              CD.CLAIM_STATUS,
              CLT.DATE_RESERVE_CHANGED,
              CLT.RESERVE,
              CLT.TOTAL_PAID,
              CLT.LOSS_ALAE_INCURRED,
            --  PC.UNDERWRITER ,
              NVL(CRU.CRU_INDICATOR,0) AS CRU_INDICATOR
              FROM CLAIM_DATA CD
              INNER JOIN POLICY_CONTACTS PC ON PC.POLICYID=CD.POLICY_KEY
              LEFT OUTER JOIN CLAIMANT_TRANS_CC CLT ON CLT.CLAIM_KEY=CD.CLAIM_KEY
              LEFT OUTER JOIN CRU_DATA CRU ON CRU.CLAIMID=CD.CLAIM_KEY
              ),
            CLAIM_DATA_ECIG AS(
                  SELECT DISTINCT
                        P.POLICY_SEARCH_NBR,
                        P.TERM_EXPIRATION_DATE,
                        A.AGENCY_CODE,
                        A.AGENCY_NAME,
                        A.DOMICILE_STATE,
                        CL.CLAIM_NBR,
                        CL.DATE_OF_LOSS,
                        CL.CLAIM_STATUS,
                        CL.CLAIM
                    FROM CLAIM CL, POLICY P, AGENCY A
                    WHERE CL.POLICY = P.POLICY AND P.AGENCY_CODE = A.AGENCY_CODE AND P.BUSINESS_LINE IN(1,5,7,17)
              --      AND TRUNC(DATE_OF_LOSS) > LAST_DAY(ADD_MONTHS(TO_DATE(SYSDATE,'DD-MON-YYYY'),-72))
                ),
            CLAIMANT_TRANS_ECIG AS(
              SELECT
                CLAIM,
                CAUSE_NAME,
                MAX(TRANS_DATE) AS DATE_RESERVE_CHANGED,
                SUM(DECODE(TRANS_TYPE,'Credit Salvage',0,'Credit Subro',0,'Credit Other',0,
                        (NVL(LOSS_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)-NVL(LOSS_PAID,0)
                        -NVL(UNALLOC_EXPENSE_PAID,0)-NVL(ALLOC_EXPENSE_PAID,0)))) RESERVE,
                SUM(NVL(LOSS_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)) TOTAL_PAID,
                SUM(CASE WHEN TRANS_TYPE IN ('Credit Salvage','Credit Subro','Credit Other')
                THEN NVL(LOSS_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)
                ELSE NVL(LOSS_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0) END) LOSS_ALAE_INCURRED
            FROM (
                 SELECT
                   CDE.CLAIM,
                   COL.CAUSE_NAME,
                   CT.TRANS_TYPE,
                   CT.LOSS_RESERVE,
                   CT.UNALLOC_EXPENSE_RESERVE,
                   CT.ALLOC_EXPENSE_RESERVE,
                   CT.LOSS_PAID,
                   CT.UNALLOC_EXPENSE_PAID,
                   CT.ALLOC_EXPENSE_PAID,
                   CT.TRANS_DATE
                  FROM CLAIM_DATA_ECIG CDE , CLAIMANT_TRANS CT, CLAIMANT_COVERAGE CC ,CAUSE_OF_LOSS COL
                  WHERE CDE.CLAIM = CT.CLAIM AND CT.CLAIMANT_COVERAGE = CC.CLAIMANT_COVERAGE AND CC.CAUSE_OF_LOSS = COL.CAUSE_OF_LOSS
                --  AND TRUNC(TRANS_DATE) <= TO_DATE(SYSDATE,'DD-MON-YYYY')
                --  AND TRUNC(TRANS_DATE) > LAST_DAY(ADD_MONTHS(TO_DATE(SYSDATE,'DD-MON-YYYY'),-72))
                  )
                  GROUP BY CLAIM , CAUSE_NAME
                  ),
                 CRU_DATA_ECIG AS
                 (
                  SELECT DISTINCT 1 CRU_INDICATOR, CRU.CLAIM  
                  FROM CLAIM_DATA_ECIG CDE ,CMS_CRU CRU
                  WHERE CDE.CLAIM = CRU.CLAIM
                  GROUP BY CRU.CLAIM, 1
                 ),
                 PAF_ECIG AS(
                 SELECT MAX(NVL(AT_FAULT,0)) AS FAULT , CLAIM
                 FROM (
                   SELECT PAF.AT_FAULT, PAF.CLAIM 
                     FROM CLAIM_DATA_ECIG CDE , PAF_AT_FAULT PAF 
                     WHERE CDE.CLAIM = PAF.CLAIM)
                     GROUP BY CLAIM
                 ),
                 PL_AUTO_PRTY_ECIG_RPT AS (
                  SELECT
                        CDE.POLICY_SEARCH_NBR,
                        CDE.TERM_EXPIRATION_DATE,
                        CDE.AGENCY_CODE,
                        CDE.AGENCY_NAME,
                        CDE.DOMICILE_STATE,
                        CDE.CLAIM_NBR,
                        CDE.DATE_OF_LOSS,
                        CTE.CAUSE_NAME,
                        nvl(PAF.FAULT,0) AS "%_AT_FAULT",
                        CDE.CLAIM_STATUS,
                        CTE.DATE_RESERVE_CHANGED,
                        CTE.RESERVE,
                        CTE.TOTAL_PAID,
                        CTE.LOSS_ALAE_INCURRED,
                        NVL(CRU.CRU_INDICATOR,0) AS CRU_INDICATOR
                  FROM CLAIM_DATA_ECIG CDE
                  LEFT OUTER JOIN CLAIMANT_TRANS_ECIG CTE ON CTE.CLAIM = CDE.CLAIM
                  LEFT OUTER JOIN CRU_DATA_ECIG CRU ON CRU.CLAIM = CDE.CLAIM
                  LEFT OUTER JOIN PAF_ECIG PAF ON PAF.CLAIM =  CDE.CLAIM
                  -- DATALAKE.BRVW_MASTER_AGENCY@CIGDW_ANALYTICS_LINK_USER; TODO UNDERWRITER
                  ),
                  PL_UNIONS_ECIG_CC AS (
                    SELECT * FROM PL_AUTO_PRTY_ECIG_RPT
                    UNION ALL
                    SELECT * FROM PL_AUTO_PRTY_CC_RPT
                    )
                SELECT * FROM PL_UNIONS_ECIG_CC;