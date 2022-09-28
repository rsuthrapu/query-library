WITH CLAIM_DATA AS (
            SELECT
                C.ID            AS CLAIM_KEY,
                P.ID            AS POLICY_KEY,
                p.PolicyNumber  AS POLICY_SEARCH_NBR,
                P.ExpirationDate  AS EXPIRATION ,
                P.ProducerCode  AS AGENCY_CODE,
                C.CLAIMNUMBER   AS CLAIM_NBR,
                TLLC.NAME      AS CAUSE_NAME,
                C.LOSSDATE      AS DATE_OF_LOSS,
                TLS.NAME        AS CLAIM_STATUS,
                INC.FAULT_EXT AS FAULT
            FROM
                CC_CLAIM@ECIG_TO_CC_LINK   C
                LEFT OUTER JOIN CC_POLICY@ECIG_TO_CC_LINK  P ON C.POLICYID = P.ID AND P.RETIRED = 0
                LEFT OUTER JOIN CCTL_CLAIMSTATE@ECIG_TO_CC_LINK TLS ON TLS.ID = C.STATE AND TLS.RETIRED = 0
                LEFT OUTER JOIN CCTL_LOSSCAUSE@ECIG_TO_CC_LINK              TLLC ON TLLC.ID = C.LOSSCAUSE AND TLLC.RETIRED = 0
                LEFT OUTER JOIN CC_INCIDENT@ECIG_TO_CC_LINK  INC ON INC.ClaimID = C.ID AND INC.RETIRED = 0
                LEFT OUTER JOIN CCTL_INCIDENT@ECIG_TO_CC_LINK TLINC ON TLINC.ID=INC.SUBTYPE AND TLINC.TYPECODE IN ('VehicleIncident') AND TLINC.RETIRED=0
             ),
             POLICY_CONTACTS AS(
            select POLICYID
            , MAX(AGENCYDOMICILESTATE_EXT) AS AGENCYDOMICILESTATE
            , MAX(DECODE(CTROLE_POLICY_TYPECODE, 'agent', NAME)) AS AGENCY
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
            CLAIMANT_TRANS AS(
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
                    LEFT OUTER JOIN CCTL_COSTTYPE@ECIG_TO_CC_LINK            TLCSTTY ON TLCSTTY.ID = TR.COSTTYPE AND TLCSTTY.RETIRED = 0
                ),
            CLAIM AS
            (
              SELECT DISTINCT
             -- CD.CLAIM_KEY,
              CD.POLICY_SEARCH_NBR,
              CD.EXPIRATION,
              CD.AGENCY_CODE,
              PC.AGENCY as AGENCY_NAME,
              PC.AGENCYDOMICILESTATE AS STATE,
              CD.CLAIM_NBR,
              CD.DATE_OF_LOSS,
              CD.CAUSE_NAME,
              CD.CLAIM_STATUS,
              SUM(DECODE(CLT.TRANS_TYPE,'Subrogation',0,'Salvage',0,'Deductible',0,LTRIM('Credit to expense'),0,LTRIM('Credit to loss'),0,
                        (NVL(CLT.LOSS_RESERVE,0)+NVL(CLT.UNALLOC_EXPENSE_RESERVE,0)+NVL(CLT.ALLOC_EXPENSE_RESERVE,0)
                        -NVL(CLT.LOSS_PAID,0)-NVL(CLT.UNALLOC_EXPENSE_PAID,0)-NVL(CLT.ALLOC_EXPENSE_PAID,0)))) RESERVE,
                        
              SUM(NVL(CLT.LOSS_PAID,0)+NVL(CLT.UNALLOC_EXPENSE_PAID,0)+NVL(CLT.ALLOC_EXPENSE_PAID,0)) TOTAL_PAID,
              
              SUM(CASE WHEN CLT.TRANS_TYPE IN ('Subrogation' , 'Salvage' , 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))
              THEN
              NVL(CLT.LOSS_PAID,0)+NVL(CLT.UNALLOC_EXPENSE_PAID,0)+NVL(CLT.ALLOC_EXPENSE_PAID,0) 
              ELSE 
              NVL(CLT.LOSS_RESERVE,0)+NVL(CLT.UNALLOC_EXPENSE_RESERVE,0)+NVL(CLT.ALLOC_EXPENSE_RESERVE,0) END) LOSS_ALAE_INCURRED, 
              CLT.DATE_RSRVE_CHNGED, 
              CD.FAULT AS FAULT_AUTO_CL_RPT,
              -- CRU INDICATOR
              PC.UNDERWRITER 
              FROM CLAIM_DATA CD
              INNER JOIN POLICY_CONTACTS PC ON PC.POLICYID=CD.POLICY_KEY
              LEFT OUTER JOIN CLAIMANT_TRANS CLT ON CLT.CLAIM_KEY=CD.CLAIM_KEY
              group by CD.POLICY_SEARCH_NBR, CD.EXPIRATION, CD.AGENCY_CODE, PC.AGENCY, PC.AGENCYDOMICILESTATE, 
                CD.CLAIM_NBR, CD.DATE_OF_LOSS, CD.CAUSE_NAME, CD.CLAIM_STATUS, CLT.LOSS_RESERVE, 
                CLT.DATE_RSRVE_CHNGED, CD.FAULT, PC.UNDERWRITER
            )
           SELECT * FROM CLAIM;

