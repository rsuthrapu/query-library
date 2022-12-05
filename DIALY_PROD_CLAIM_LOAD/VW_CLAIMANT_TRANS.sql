--------------------------------------------------------
--  DDL for View VW_CLAIMANT_TRANS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "DATALAKE"."VW_CLAIMANT_TRANS" ("CLAIMANT_TRANS", "CLAIMANT_COVERAGE", "TRANSACTION_DATE", "TRANSDATE", "TRANSTIME", "TRANSACTION_TYPE", "TRANSACTION_PRIMARY", "TRANSACTION_STATUS", "CHECK_PAYABLE", "DRAFT_NUMBER", "EXPENSE_CODE", "OS_LOSS", "OS_ALAE", "OS_ULAE", "PAID_LOSS", "PAID_ALAE", "PAID_ULAE", "CCTCL", "CCTCLMT", "CCTCOL", "CCTCOV", "LOAD_DATE") AS 
  WITH ct
        AS (SELECT dct.*, 1 as ct_rowmax FROM dec30_claimant_trans dct
            UNION
            
            SELECT *
            FROM (
                    --20211116 sc : added partition to remove duplicate claim transactions in Daily Production (VW_CLAIMANT_TRANS->VAR_CLAIMANT_TRANS[visual_load]->REPORT_DAILYPRODUCTION_CLAIM[production_load]->REPORT_DAILY_PRODUCTION)
					select ct.* 
                    ,ROW_NUMBER() OVER (PARTITION BY CLAIMANT_TRANS ORDER BY LOAD_DATE DESC) CT_ROWMAX
                    FROM DATALAKE.DAILY_CLAIMANT_TRANS ct  
                    WHERE load_date > TO_DATE ('12-30-2015', 'mm-dd-yyyy')
                  )
            where CT_ROWMAX = 1
            )
   SELECT ct.claimant_trans,
          ct.claimant_coverage,
          TRUNC (ct.trans_date)            AS transaction_date,
          (  EXTRACT (YEAR FROM CAST (ct.trans_date AS TIMESTAMP)) * 10000
           + EXTRACT (MONTH FROM CAST (ct.trans_date AS TIMESTAMP)) * 100
           + EXTRACT (DAY FROM CAST (ct.trans_date AS TIMESTAMP)))
             transdate,
          (  EXTRACT (HOUR FROM CAST (ct.trans_date AS TIMESTAMP)) * 10000
           + EXTRACT (MINUTE FROM CAST (ct.trans_date AS TIMESTAMP)) * 100
           + EXTRACT (SECOND FROM CAST (ct.trans_date AS TIMESTAMP)))
             transtime,
          ct.trans_type                    AS transaction_type,
          ltt.transaction_primary,
          ltt.transaction_status,
          NVL (ct.check_payable, -1)       AS check_payable,
          NVL (ct.draft_nbr, -1)           AS draft_number,
          NVL (ct.expense_code, -1)        AS expense_code,
          CASE
             WHEN LOWER (SUBSTR (ct.trans_type, 1, 6)) IN ('credit') THEN 0
             ELSE NVL (ct.loss_reserve, 0) - NVL (ct.loss_paid, 0)
          END
             os_loss,
          CASE
             WHEN LOWER (SUBSTR (ct.trans_type, 1, 6)) IN ('credit')
             THEN
                0
             ELSE
                  NVL (ct.alloc_expense_reserve, 0)
                - NVL (ct.alloc_expense_paid, 0)
          END
             os_alae,
          CASE
             WHEN LOWER (SUBSTR (ct.trans_type, 1, 6)) IN ('credit')
             THEN
                0
             ELSE
                  NVL (ct.unalloc_expense_reserve, 0)
                - NVL (ct.unalloc_expense_paid, 0)
          END
             os_ulae,
          NVL (ct.loss_paid, 0)            AS paid_loss,
          NVL (ct.alloc_expense_paid, 0)   AS paid_alae,
          NVL (ct.unalloc_expense_paid, 0) AS paid_ulae,
          ct.claim                         cctcl,
          ct.claimant                      cctclmt,
          ct.cause_of_loss                 cctcol,
          ct.coverage                      cctcov,
          ct.load_date
     FROM ct
          LEFT OUTER JOIN
          (SELECT DISTINCT claim
             FROM ct
            WHERE claimant_coverage IS NULL AND claim IS NOT NULL) nullcc
             ON ct.claim = nullcc.claim
          LEFT OUTER JOIN l_transtype ltt ON ct.trans_type = ltt.trans_type
    WHERE nullcc.claim IS NULL AND ct.claimant_coverage IS NOT NULL
    UNION 
     SELECT TR.ID claimant_trans,
          EX.ID AS claimant_coverage,
          TRUNC (TR.UPDATETIME)            AS transaction_date,
          (  EXTRACT (YEAR FROM CAST (TR.UPDATETIME AS TIMESTAMP)) * 10000
           + EXTRACT (MONTH FROM CAST (TR.UPDATETIME AS TIMESTAMP)) * 100
           + EXTRACT (DAY FROM CAST (TR.UPDATETIME AS TIMESTAMP)))
             transdate,
          (  EXTRACT (HOUR FROM CAST (TR.UPDATETIME AS TIMESTAMP)) * 10000
           + EXTRACT (MINUTE FROM CAST (TR.UPDATETIME AS TIMESTAMP)) * 100
           + EXTRACT (SECOND FROM CAST (TR.UPDATETIME AS TIMESTAMP)))
             transtime,
          TLRC.NAME                    AS transaction_type,
       --   ltt.transaction_primary,
      --    ltt.transaction_status,
          NVL (CH.ID, -1)       AS check_payable,
          NVL (CH.CHECKNUMBER, -1)           AS draft_number,
          NVL (TLCG.TYPECODE , -1)        AS expense_code,
          CASE
             WHEN LOWER (SUBSTR (TLRC.NAME , 1, 6)) IN ('credit') THEN 0
             ELSE 
              CASE WHEN TLTR.NAME = 'Reserve'
                 AND TLCSTTY.TYPECODE = 'claimcost' THEN 
                NVL(TRLI.RESERVINGAMOUNT,0)
                END -        
                CASE
                WHEN TLTR.NAME = 'Payment'
                     AND TLCSTTY.TYPECODE = 'claimcost' THEN 
                  NVL(TRLI.CLAIMAMOUNT,0)
              END 
          END
             os_loss,
          CASE
             WHEN LOWER (SUBSTR (TLRC.NAME , 1, 6)) IN ('credit')
             THEN
                0
             ELSE
             CASE
                WHEN TLTR.NAME = 'Reserve'
                     AND TLCSTTY.TYPECODE = 'dccexpense' THEN 
                    NVL(TRLI.RESERVINGAMOUNT,0)
                END -  
                CASE
                WHEN TLTR.NAME = 'Payment'
                     AND TLCSTTY.TYPECODE = 'aoexpense' THEN 
                    NVL(TRLI.CLAIMAMOUNT,0)
                END    
          END
             os_alae,
          CASE
             WHEN LOWER (SUBSTR (TLRC.NAME , 1, 6)) IN ('credit')
             THEN
                0
             ELSE
             CASE
                WHEN TLTR.NAME = 'Reserve'
                     AND TLCSTTY.TYPECODE = 'aoexpense' THEN 
                    NVL(TRLI.RESERVINGAMOUNT,0)
               END  -       
               CASE
                 WHEN TLTR.NAME = 'Payment'
                   AND TLCSTTY.TYPECODE = 'aoexpense' THEN 
                   NVL(TRLI.CLAIMAMOUNT,0)
                 END
          END
             os_ulae,
          CASE
            WHEN TLTR.NAME = 'Payment'
                 AND TLCSTTY.TYPECODE = 'claimcost' THEN 
              NVL(TRLI.CLAIMAMOUNT,0)
          END  AS paid_loss,  
          CASE
            WHEN TLTR.NAME = 'Payment'
                 AND TLCSTTY.TYPECODE = 'dccexpense' THEN 
               NVL(TRLI.CLAIMAMOUNT,0)
          END AS paid_alae,
          CASE
            WHEN TLTR.NAME = 'Payment'
                 AND TLCSTTY.TYPECODE = 'aoexpense' THEN 
                NVL(TRLI.CLAIMAMOUNT,0)
          END AS paid_ulae,
          C.ID                         cctcl,
          CCTE.ID                      cctclmt,
          TLLC.ID                     cctcol,
          COV.ID                      cctcov
          FROM
     DATALAKE.DAILY_CC_CLAIM@ECIG_TO_CC_LINK C 
     INNER JOIN DATALAKE.DAILY_CC_EXPOSURE@ECIG_TO_CC_LINK EX ON EX.CLAIMID=C.ID AND EX.RETIRED=0
     INNER JOIN DATALAKE.DAILY_CC_CLAIMCONTACT@ECIG_TO_CC_LINK CCTE ON  CCTE.CLAIMID=C.ID AND CCTE.RETIRED=0 
     INNER JOIN DATALAKE.DAILY_CC_TRANSACTION@ECIG_TO_CC_LINK TR ON TR.CLAIMID = C.ID AND EX.ID=TR.EXPOSUREID AND TR.RETIRED = 0
     INNER JOIN DATALAKE.DAILY_CCTL_TRANSACTION@ECIG_TO_CC_LINK              TLTR ON TLTR.ID = TR.SUBTYPE AND TLTR.RETIRED = 0
     LEFT OUTER JOIN DATALAKE.DAILY_CCTL_RECOVERYCATEGORY@ECIG_TO_CC_LINK    TLRC ON TLRC.ID   = TR.RECOVERYCATEGORY AND TLRC.RETIRED = 0             
     INNER JOIN DATALAKE.DAILY_CC_TRANSACTIONLINEITEM@ECIG_TO_CC_LINK        TRLI ON TRLI.TRANSACTIONID = TR.ID AND TRLI.RETIRED = 0
    LEFT OUTER JOIN DATALAKE.DAILY_CCTL_TRANSACTIONSTATUS@ECIG_TO_CC_LINK   TLTRS ON TLTRS.ID = TR.STATUS AND TLTRS.RETIRED = 0
    LEFT OUTER JOIN DATALAKE.DAILY_CCTL_COSTTYPE@ECIG_TO_CC_LINK            TLCSTTY ON TLCSTTY.ID = TR.COSTTYPE AND TLCSTTY.RETIRED = 0
    LEFT OUTER JOIN DATALAKE.DAILY_CCTL_COSTCATEGORY@ECIG_TO_CC_LINK        TLCG ON TLCG.ID = TR.COSTCATEGORY AND TLCG.RETIRED =0
    LEFT OUTER JOIN DATALAKE.DAILY_CC_CHECK@ECIG_TO_CC_LINK                 CH ON CH.ID = TR.CHECKID AND CH.RETIRED = 0
    LEFT OUTER JOIN DATALAKE.DAILY_CCTL_LOSSCAUSE@ECIG_TO_CC_LINK              TLLC ON TLLC.ID = C.LOSSCAUSE AND TLLC.RETIRED = 0
    LEFT OUTER JOIN DATALAKE.DAILY_CC_COVERAGE@ECIG_TO_CC_LINK COV ON COV.ID=EX.COVERAGEID AND COV.RETIRED=0
    WHERE EX.ID IS NULL AND C.ID IS NOT NULL;

