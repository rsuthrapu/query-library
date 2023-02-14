SELECT CLAIMANT_COVERAGE,
            CLAIM,
            CLAIMANT,
            CAUSE_OF_LOSS,
            COVERAGE,
            CAUSE_STATUS,
            DEPT,
            CC_TRANS_DATE,
            CC_LOAD_DATE,
            CLAIM_SOURCE
       FROM (SELECT claimant_coverage,
                    claim,
                    claimant,
                    cause_of_loss,
                    coverage,
                    status              AS cause_status,
                    NVL (dept, 0)       AS dept,
                    TRUNC (last_modified) AS cc_trans_date,
                    load_date           AS cc_load_date,
                     'CMS' as claim_source
               FROM dec30_claimant_coverage
             UNION
             SELECT claimant_coverage,
                    claim,
                    claimant,
                    cause_of_loss,
                    coverage,
                    status              AS cause_status,
                    NVL (dept, 0)       AS dept,
                    TRUNC (last_modified) AS cc_trans_date,
                    load_date           AS cc_load_date,
                      'CMS' as claim_source
               FROM DLAKEDEV.daily_claimant_coverage
            WHERE  load_date > TO_DATE ('12-30-2015', 'mm-dd-yyyy')
            UNION 
                 SELECT TR.EXPOSUREID AS claimant_coverage,
                    C.ID AS claim,
                    CCTE.ID AS claimant,
                    TLLC.ID  AS cause_of_loss,
                    COV.ID AS coverage,
                    TLES.NAME  AS cause_status,
                    NVL (D.DEPT, 0)       AS dept,
                    TRUNC (TR.UPDATETIME) AS cc_trans_date,
                    TR.load_date           AS cc_load_date,
                     'CC' as claim_source
               FROM DLAKEDEV.DAILY_CC_CLAIM C
               LEFT OUTER JOIN DLAKEDEV.DAILY_CCTL_LOSSCAUSE  TLLC ON TLLC.ID = C.LOSSCAUSE AND TLLC.RETIRED = 0
               INNER JOIN DLAKEDEV.DAILY_CC_TRANSACTION TR ON TR.CLAIMID=C.ID AND TR.RETIRED=0
               INNER JOIN DLAKEDEV.DAILY_CC_CLAIMCONTACT CCTE ON  CCTE.CLAIMID=C.ID AND CCTE.RETIRED=0 
               INNER JOIN DLAKEDEV.DAILY_CC_EXPOSURE EX ON EX.CLAIMID=C.ID AND EX.RETIRED=0
               LEFT OUTER JOIN DLAKEDEV.DAILY_CC_COVERAGE COV ON COV.ID=EX.COVERAGEID
               INNER JOIN DLAKEDEV.DAILY_CCTL_EXPOSURESTATE TLES ON TLES.ID = EX.STATE AND TLES.RETIRED = 0
               INNER JOIN DLAKEDEV.DAILY_CC_POLICY P ON P.ID=C.POLICYID AND P.RETIRED=0
               LEFT OUTER JOIN DLAKEDEV.DAILY_CCX_POLICYDEPARTMENT_EXT PD ON P.POLICYDEPARTMENT_EXTID = PD.ID AND PD.RETIRED = 0
               LEFT OUTER JOIN DLAKEDEV.DAILY_DEPT D ON D.dept_nbr = PD.DEPTNUMBER
            WHERE  TR.load_date > TO_DATE ('12-30-2022', 'mm-dd-yyyy')
            )
   ORDER BY claimant_coverage, cc_trans_date