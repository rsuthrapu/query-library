CREATE OR REPLACE FUNCTION  CLAIMANT_FINANCIALS(CLAIM_NBR VARCHAR2)
RETURN CLAIMANT_FINANCIAL_DETAILS_OBJ 
AS 
THISCLAIM CLAIMANT_FINANCIAL_DETAILS_OBJ;

BEGIN

WITH CLAIMANT_TRANS AS(
            SELECT * FROM (
            SELECT  
                    CD.ID AS CLAIM_KEY 
                    , CD.CLAIMNUMBER
                    , TR.ID                     AS CLAIMANT_TRANS_ID
                    , EX.ID             AS EX_EXPOSUREID
                    , TR.EXPOSUREID             AS TR_EXPOSUREID
                    , TR.UPDATETIME             AS TRANS_DATE
                    , TLCG.TYPECODE             AS EXPENSE_CODE
                    , TLPM.NAME                 AS CLAIM_DRAFT_TYPE
                    , TR.CREATEUSERID           AS OPERATOR_USER_ID
                    , TRUCR.USERNAME            AS OPERATOR_ID
                    -- CHECK DETAILS
                    , TLTR.NAME                 AS TRANS_SUB_TYPE
                    , TLRC.NAME                 AS TRANS_TYPE_PYMT
                     , TLCSTTY.TYPECODE              AS COST_TYPE 
                    , TLCG.TYPECODE               AS COST_CATEGORY
                    , CH.CHECKNUMBER            AS CHECK_NBR
                    , TLCHS.NAME AS CHECK_STATUS
            --        , CH.TRANSACTIONID AS CHECK_TR_ID
                    , TR.ID AS TR_ID
                    , TRLI.TRANSACTIONID AS TRLI_ID
                    , TRLI.CLAIMAMOUNT
                    , TRLI.RESERVINGAMOUNT
                    -- PAYMENTS
                    ,   CASE
                            WHEN TLTR.NAME = 'Payment'
                                 AND TLCSTTY.TYPECODE = 'claimcost' THEN 
                                ( TRLI.CLAIMAMOUNT )
                        END  AS DRAFT_PAID_AMT
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
                    FROM 
                    CC_CLAIM@ECIG_TO_CC_LINK CD 
                    INNER JOIN CC_EXPOSURE@ECIG_TO_CC_LINK                  EX ON EX.CLAIMID=CD.ID AND EX.RETIRED=0
                    INNER JOIN CC_TRANSACTION@ECIG_TO_CC_LINK                TR ON TR.CLAIMID = CD.ID AND EX.ID=TR.EXPOSUREID AND TR.RETIRED = 0
                    LEFT OUTER JOIN CCTL_RECOVERYCATEGORY@ECIG_TO_CC_LINK    TLRC ON TLRC.ID   = TR.RECOVERYCATEGORY AND TLRC.RETIRED = 0
                    LEFT OUTER JOIN CCTL_PAYMENTTYPE@ECIG_TO_CC_LINK         TLPT ON TLPT.ID = TR.PAYMENTTYPE AND TLPT.RETIRED = 0     
                    INNER JOIN CCTL_TRANSACTION@ECIG_TO_CC_LINK              TLTR ON TLTR.ID = TR.SUBTYPE AND TLTR.RETIRED = 0
                    INNER JOIN CC_TRANSACTIONLINEITEM@ECIG_TO_CC_LINK        TRLI ON TRLI.TRANSACTIONID = TR.ID AND TRLI.RETIRED = 0
                    LEFT OUTER JOIN CCTL_TRANSACTIONSTATUS@ECIG_TO_CC_LINK   TLTRS ON TLTRS.ID = TR.STATUS AND TLTRS.RETIRED = 0
                    LEFT OUTER JOIN CCTL_COSTTYPE@ECIG_TO_CC_LINK            TLCSTTY ON TLCSTTY.ID = TR.COSTTYPE AND TLCSTTY.RETIRED = 0
                    LEFT OUTER JOIN CCTL_COSTCATEGORY@ECIG_TO_CC_LINK        TLCG ON TLCG.ID = TR.COSTCATEGORY AND TLCG.RETIRED =0
                    LEFT OUTER JOIN CC_CHECK@ECIG_TO_CC_LINK                 CH ON CH.ID = TR.CHECKID AND CH.RETIRED = 0 --AND TR.SUBTYPE=
                    LEFT OUTER JOIN CCTL_TRANSACTIONSTATUS@ECIG_TO_CC_LINK   TLCHS ON TLCHS.ID = CH.STATUS AND TLCHS.RETIRED = 0
                    LEFT OUTER  JOIN CCTL_PAYMENTMETHOD@ECIG_TO_CC_LINK      TLPM ON TLPM.ID = CH.PAYMENTMETHOD AND TLPM.RETIRED = 0
                    LEFT OUTER JOIN CC_USER@ECIG_TO_CC_LINK                  TRU ON TR.CREATEUSERID = TRU.ID AND TRU.RETIRED = 0
                    LEFT OUTER JOIN CC_CREDENTIAL@ECIG_TO_CC_LINK            TRUCR ON TRUCR.ID = TRU.CREDENTIALID AND TRUCR.RETIRED = 0
                    INNER JOIN CC_USER@ECIG_TO_CC_LINK                       UU ON TRU.UPDATEUSERID = UU.ID AND UU.RETIRED = 0
                    INNER JOIN CC_CREDENTIAL@ECIG_TO_CC_LINK                 UUCR  ON UUCR.ID = UU.CREDENTIALID AND UUCR.RETIRED = 0
                    ORDER BY TR.UPDATETIME
                ) 
            ),           
            CLAIMANT_FINANCIALS AS
            (
               SELECT 
                 CT.CLAIM_KEY
                ,CT.CLAIMNUMBER
               -- ,CT.EX_EXPOSUREID
                ,CT.LOSS_PAID
                ,CT.UNALLOC_EXPENSE_PAID
                ,CT.ALLOC_EXPENSE_PAID
                ,CT.LOSS_RESERVE
                ,CT.UNALLOC_EXPENSE_RESERVE
                ,CT.ALLOC_EXPENSE_RESERVE
               FROM CLAIMANT_TRANS CT
            )
            SELECT *
            INTO THISCLAIM
            FROM CLAIMANT_FINANCIALS  WHERE CLAIMNUMBER = CLAIM_NBR;

	 RETURN THISCLAIM;
END CLAIMANT_FINANCIALS;


CREATE OR REPLACE TYPE CLAIMANT_FINANCIAL_DETAILS_OBJ IS OBJECT
(
   CLAIM_KEY NUMBER(38),
   CLAIMNUMBER NUMBER(38),
   LOSS_PAID FLOAT(126),
   UNALLOC_EXPENSE_PAID FLOAT(126),
   ALLOC_EXPENSE_PAID FLOAT(126),
   LOSS_RESERVE FLOAT(126),
   UNALLOC_EXPENSE_RESERVE FLOAT(126),
   ALLOC_EXPENSE_RESERVE FLOAT(126)
);
            

