create or replace PACKAGE                   pkg_aplus AS

	PROCEDURE sp_Write_aplus_File
                   (v_month IN NUMBER,
				    v_year IN NUMBER,
                    v_iso_aplus_account_nbr IN VARCHAR2,
				    v_5yr_flag IN VARCHAR2,
                    V_V_CLAIM_NBR IN NUMBER
                    );

	FUNCTION fn_Convert_Null_To_Space(v_char_input IN VARCHAR2)
	RETURN VARCHAR2;
	FUNCTION fn_Replace_Unprintable (v_char_input IN VARCHAR2)
	RETURN VARCHAR2;

END pkg_aplus;


create or replace PACKAGE BODY PKG_APLUS AS

    PROCEDURE SP_WRITE_APLUS_FILE (
        V_MONTH                 IN NUMBER,
        V_YEAR                  IN NUMBER,
        V_ISO_APLUS_ACCOUNT_NBR IN VARCHAR2,
        V_5YR_FLAG              IN VARCHAR2
        ,V_V_CLAIM_NBR          IN NUMBER
    ) IS

-- Variables

        FILE_HANDLE                   UTL_FILE.FILE_TYPE;
        FILE_OUT                      VARCHAR2(815);
        V_FILE_NAME                   VARCHAR2(20);
        CLUE_FILE_HANDLE              UTL_FILE.FILE_TYPE;
        CLUE_FILE_OUT                 VARCHAR2(815);
        V_CLUE_FILE_NAME              VARCHAR2(20);
        V_INSTANCE                    CIG_INSTANCE.NAME%TYPE;
        V_LOC                         VARCHAR2(254);
        CURSOR_HANDLE                 INTEGER;
        V_MONTH_BEGIN                 DATE;
        V_MONTH_END                   DATE;
        V_MIN_DOL                     DATE;
        V_MONTH_STR                   VARCHAR2(2);
        V_DEC_POLICY                  DEC_POLICY.DEC_POLICY%TYPE;
        V_POLICY                      POLICY.POLICY%TYPE;
        V_CLAIM                       CLAIM.CLAIM%TYPE;
        V_CLAIM_NBR                   CLAIM.CLAIM_NBR%TYPE;
        V_CC                          CLAIMANT_COVERAGE.CLAIMANT_COVERAGE%TYPE;
        V_CC_COVERAGE                 CLAIMANT_COVERAGE.COVERAGE%TYPE;
        V_EXPOSURE_ID                 NUMBER;
        V_LOSS_PAID                   FLOAT;
 -- PL-6986: Added the following variable to store where the policy data
 -- will be comming from.
        V_SOURCE_OF_POLICY            VARCHAR2(20);
        V_SOURCE_OF_CLAIM             VARCHAR2(20);
        V_AM_BEST                     VARCHAR2(6);
        V_FIRST_NAME                  DEC_DRIVER.FIRST_NAME%TYPE;
--      r_subrogation     subrogation%ROWTYPE;
	--v_coverage_desc			coverage.coverage_desc%TYPE;
        V_FIRST_PMT                   DATE;
        V_FIRST_PMT_TXT               VARCHAR2(6);
        V_DRIVER1_BD                  VARCHAR2(6);
        V_DRIVER2_BD                  VARCHAR2(6);
        V_OPERATOR_BD                 VARCHAR2(6);
        V_CREATE                      VARCHAR2(9);
        V_VYEAR                       NUMBER;
        V_SIGN                        VARCHAR2(1);
        V_VO_ADDR_NBR                 DEC_POLICY.INSURED_ADDR_NBR%TYPE;
        V_VO_STREET                   DEC_POLICY.INSURED_STREET_NAME%TYPE;
        V_VO_SUITE                    DEC_POLICY.INSURED_SUITE%TYPE;
        V_VO_CITY                     DEC_POLICY.INSURED_CITY%TYPE;
        V_VO_STATE                    DEC_POLICY.INSURED_STATE%TYPE;
        V_VO_ZIP                      DEC_POLICY.INSURED_ZIPCODE%TYPE;
        V_VO_SSN                      INSURED.SSN%TYPE;
        V_OPERATOR                    VARCHAR2(20);
        V_DRIVER                      VARCHAR2(20);
        V_DD_KEY                      NUMBER;
        V_I                           INTEGER;
        V_CC_STATUS                   VARCHAR2(1);
        V_AT_FAULT                    VARCHAR2(1);
        V_OPEN_CT                     INTEGER;
  --Start APLUS variable fields added
        V_POLICYHOLDER1_DOB           VARCHAR2(8);
        V_POLICYHOLDER2_DOB           VARCHAR2(8);
        V_POLICYHOLDER1_NAMED_INSURED INSURED.NAMED_INSURED%TYPE;
        V_CAUSE_DESC                  CAUSE_OF_LOSS.CAUSE_NAME%TYPE;
        V_CLAIM_TYPE                  CAUSE_OF_LOSS.CAUSE_NAME%TYPE;
        V_POLICY_TYPE                 VARCHAR2(4);
        V_RECORD_TYPE                 VARCHAR2(1);
        V_CLAIM_CAT_FLAG              VARCHAR2(2);
        V_CLAIMANT_DOB                VARCHAR2(8);
        V_CC_CLAIMANT                 CLAIMANT_COVERAGE.CLAIMANT%TYPE;
        V_DP_BUSINESS_LINE            DEC_POLICY.BUSINESS_LINE%TYPE;
  --DBMS display messages
        V_LOSS_AMOUNT_SUBMITTED       NUMBER := 0;
        V_LENGTH                      NUMBER(4);      --variable to display finance_co length
        V_SQL_ERROR_CODE              NUMBER := 0;    --variable to hold sql error code
        V_SQL_ERROR_MSG               VARCHAR2(200);  --variable to hold sql error message

        V_CNT1                        INTEGER := 0;  -- main cursor
        V_CNT2                        INTEGER := 0;  --skipped
        V_CNT3                        INTEGER := 0;  -- insureds
        V_CNT4                        INTEGER := 0;  -- drivers
        V_CNT5                        INTEGER := 0;  -- vehicle operators
        V_CNT6                        INTEGER := 0;  -- vehicles
        V_CNT7                        INTEGER := 0;  -- records output
        V_CNT8                        INTEGER := 0;  -- closed no paid

    -- Declare variables for line number and error message
        V_LINE_NUMBER                 VARCHAR2(4000);
        V_ERROR_MESSAGE               VARCHAR2(4000);
            
-- PL-6986: Added the source of data to the following two cursors so that
-- any additonal data needed can be obtained from the appropriate data sources.
        CURSOR C_MAIN IS
        WITH CC_DATA AS (
            SELECT
                C.ID                                         AS CLAIM,
                CASE
                    WHEN REGEXP_LIKE ( CLAIMNUMBER,
                                       '^[0-9]*$' ) THEN
                        TO_NUMBER(CLAIMNUMBER)
                    ELSE
                        00000
                END                                          AS CLAIM_NBR,
                P.ID                                         AS POLICY,
                NVL(P.DECPOLICY_EXT, P.POLICYSYSTEMPERIODID) AS DEC_POLICY,
                COV.ID                                       AS COVERAGE,
                CCTE.ID                                      AS CLAIMANT
--        , TLCOVSTY.NAME AS EXPOSURE_COV_SUBTYPE
--        , TLCOV.NAME AS COVERAGE_SUBTYPE
--        , TLCOVTY.NAME AS COVERAGE_TYPE
                ,
                TLPS.NAME                                    AS POLICY_SOURCE
        --, TLPT.NAME AS POLICY_TYPE
                ,
                'CC'                                         AS CLAIM_SOURCE,
                E.ID                                         AS EXPOSURE_ID,
                CASE
                    WHEN TLT.NAME = 'Payment'
                         AND TLCT.NAME = 'Claim Cost' THEN
                        TLI.TRANSACTIONAMOUNT
                    WHEN TLT.NAME = 'Recovery'
                         AND TLCT.NAME = 'Claim Cost' THEN
                        - TLI.TRANSACTIONAMOUNT
                    ELSE
                        0
                END                                          AS LOSS_PAID
            FROM
                CCADMIN.CC_TRANSACTION@ECIG_TO_GWCC_PRD_LINK         T
                LEFT JOIN CCADMIN.CC_TRANSACTIONLINEITEM@ECIG_TO_GWCC_PRD_LINK TLI ON TLI.TRANSACTIONID = T.ID
                                                                                      AND TLI.RETIRED = 0
                LEFT JOIN CCADMIN.CCTL_TRANSACTION@ECIG_TO_GWCC_PRD_LINK       TLT ON TLT.ID = T.SUBTYPE
                LEFT JOIN CCADMIN.CCTL_COSTTYPE@ECIG_TO_GWCC_PRD_LINK          TLCT ON TLCT.ID = T.COSTTYPE
                LEFT JOIN CCADMIN.CCTL_PAYMENTTYPE@ECIG_TO_GWCC_PRD_LINK       TLPMT ON TLPMT.ID = T.PAYMENTTYPE
                LEFT JOIN CCADMIN.CC_EXPOSURE@ECIG_TO_GWCC_PRD_LINK            E ON E.ID = T.EXPOSUREID
                                                                         AND E.RETIRED = 0
                LEFT JOIN CCADMIN.CC_CLAIM@ECIG_TO_GWCC_PRD_LINK               C ON C.ID = NVL(E.CLAIMID, T.CLAIMID)
                                                                      AND C.RETIRED = 0
                INNER JOIN CCADMIN.CC_POLICY@ECIG_TO_GWCC_PRD_LINK              P ON C.POLICYID = P.ID
                LEFT OUTER JOIN CCADMIN.CC_CLAIMCONTACT@ECIG_TO_GWCC_PRD_LINK        CCTE ON CCTE.CLAIMID = C.ID
                                                                                      AND CCTE.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CC_CONTACT@ECIG_TO_GWCC_PRD_LINK             CTE ON CTE.ID = CCTE.CONTACTID
                                                                                AND CTE.RETIRED = 0
                                                                                AND E.CLAIMANTDENORMID = CTE.ID
                INNER JOIN CCADMIN.CC_CLAIMCONTACTROLE@ECIG_TO_GWCC_PRD_LINK    CCTRE ON CCTRE.CLAIMCONTACTID = CCTE.ID
                                                                                      AND CCTRE.EXPOSUREID = E.ID
                                                                                      AND CCTRE.RETIRED = 0
                INNER JOIN CCADMIN.CCTL_CONTACTROLE@ECIG_TO_GWCC_PRD_LINK       TLCCTR ON TLCCTR.ID = CCTRE.ROLE
                                                                                    AND TLCCTR.TYPECODE IN ( 'claimant' )
                                                                                    AND TLCCTR.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CCTL_COVERAGESUBTYPE@ECIG_TO_GWCC_PRD_LINK   TLCOVSTY ON TLCOVSTY.ID = E.COVERAGESUBTYPE
                LEFT OUTER JOIN CCADMIN.CC_COVERAGE@ECIG_TO_GWCC_PRD_LINK            COV ON COV.ID = E.COVERAGEID
                                                                                 AND COV.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CCTL_COVERAGE@ECIG_TO_GWCC_PRD_LINK          TLCOV ON TLCOV.ID = COV.SUBTYPE
                                                                                     AND TLCOV.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CCTL_COVERAGETYPE@ECIG_TO_GWCC_PRD_LINK      TLCOVTY ON TLCOVTY.ID = COV.TYPE
                                                                                           AND TLCOVTY.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CCTL_POLICYSOURCE@ECIG_TO_GWCC_PRD_LINK      TLPS ON TLPS.ID = P.POLICYSOURCE
                LEFT OUTER JOIN CCADMIN.CCTL_POLICYTYPE@ECIG_TO_GWCC_PRD_LINK        TLPT ON TLPT.ID = P.POLICYTYPE
            WHERE
        --cp.Business_line = 'Business Owner' OR --Businessowners
--    cp.Business_line = 'Commercial Umbrella' OR --Commercial Umbrella
--    cp.Business_line = 'Dwelling Fire' OR -- Dwelling Fire
--    cp.Business_line = 'Farm' OR -- Farmowners
--    cp.Business_line = 'Farm Umbrella' OR -- Farm Umbrella
--    cp.Business_line = 'Homeowner' OR -- Homeowners
--    cp.Business_line = 'Manual' OR  -- Commercial Manual
--    cp.Business_line = 'Personal Umbrella' --Personal Excess
                TLPT.NAME IN ( 'Businessowners', 'Commercial Umbrella', 'Dwelling Fire', 'Farmowners', 'Farm Umbrella',
                               'Homeowners', 'Commercial Manual', 'Personal Excess' )
                AND T.UPDATETIME BETWEEN TO_DATE(TO_CHAR(V_MONTH)
                                                 || '/01/'
                                                 || TO_CHAR(V_YEAR),
        'MM/DD/YYYY') AND LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                           || '/01/'
                                           || TO_CHAR(V_YEAR)
                                           || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM'))
                AND C.LOSSDATE > ADD_MONTHS(LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                                             || '/01/'
                                                             || TO_CHAR(V_YEAR)
                                                             || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM')),- 60)
        )
        SELECT
            CLAIM,
            CLAIM_NBR,
            POLICY,
            DEC_POLICY,
            COVERAGE,
            CLAIMANT--, COVERAGE, CLAIMANT--, EXPOSURE_COV_SUBTYPE, COVERAGE_SUBTYPE, COVERAGE_TYPE
            ,
            POLICY_SOURCE--, POLICY_TYPE
            ,
            CLAIM_SOURCE,
            EXPOSURE_ID,
            SUM(LOSS_PAID) AS LOSS_PAID
        FROM
            CC_DATA WHERE CLAIM_NBR = V_V_CLAIM_NBR
        GROUP BY
            CLAIM,
            CLAIM_NBR,
            POLICY,
            DEC_POLICY,
            COVERAGE,
            CLAIMANT--, COVERAGE, CLAIMANT--, EXPOSURE_COV_SUBTYPE, COVERAGE_SUBTYPE, COVERAGE_TYPE
            ,
            POLICY_SOURCE,
            CLAIM_SOURCE,
            EXPOSURE_ID
        UNION
        SELECT
            C.CLAIM,
            C.CLAIM_NBR,
            C.POLICY,
            C.DEC_POLICY,
            CC.COVERAGE,
            CC.CLAIMANT,
            'eCIG'            AS POLICY_SOURCE,
            'CMS'             AS CLAIM_SOURCE,
            NULL              AS EXPOSURE_ID,
            SUM(CT.LOSS_PAID) AS LOSS_PAID
        FROM
            CLAIM             C,
            CLAIMANT_TRANS    CT,
            CLAIMANT_COVERAGE CC,
            DEC_POLICY        DP
        WHERE
            CT.TRANS_DATE BETWEEN TO_DATE(TO_CHAR(V_MONTH)
                                          || '/01/'
                                          || TO_CHAR(V_YEAR),
        'MM/DD/YYYY') AND LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                           || '/01/'
                                           || TO_CHAR(V_YEAR)
                                           || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM'))
            AND C.DATE_OF_LOSS > ADD_MONTHS(LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                                             || '/01/'
                                                             || TO_CHAR(V_YEAR)
                                                             || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM')),- 60)
            AND C.CLAIM = CT.CLAIM
            AND CC.CLAIMANT_COVERAGE = CT.CLAIMANT_COVERAGE
            AND C.DEC_POLICY = DP.DEC_POLICY
            AND ( DP.BUSINESS_LINE = 'Business Owner'
                  OR DP.BUSINESS_LINE = 'Commercial Umbrella'
                  OR DP.BUSINESS_LINE = 'Dwelling Fire'
                  OR DP.BUSINESS_LINE = 'Farm'
                  OR DP.BUSINESS_LINE = 'Farm Umbrella'
                  OR DP.BUSINESS_LINE = 'Homeowner'
                  OR DP.BUSINESS_LINE = 'Manual'
                  OR DP.BUSINESS_LINE = 'Personal Umbrella' ) AND  C.CLAIM_NBR = V_V_CLAIM_NBR
        GROUP BY
            C.CLAIM,
            C.CLAIM_NBR,
            C.POLICY,
            C.DEC_POLICY,
            CC.COVERAGE,
            CC.CLAIMANT--, EXPOSURE_ID
        UNION
        SELECT
            C.CLAIM,
            C.CLAIM_NBR,
            CP.CMS_POLICY     POLICY,
            CP.CMS_POLICY     DEC_POLICY,
            CC.COVERAGE,
            CC.CLAIMANT,
            'PolicyCenter'    AS POLICY_SOURCE,
            'CMS'             AS CLAIM_SOURCE,
            NULL              AS EXPOSURE_ID,
            SUM(CT.LOSS_PAID) AS LOSS_PAID
        FROM
            CLAIM             C,
            CLAIMANT_TRANS    CT,
            CLAIMANT_COVERAGE CC,
            CMS_CLAIM_POLICY  CCP,
            CMS_POLICY        CP
        WHERE
            CT.TRANS_DATE BETWEEN TO_DATE(TO_CHAR(V_MONTH)
                                          || '/01/'
                                          || TO_CHAR(V_YEAR),
        'MM/DD/YYYY') AND LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                           || '/01/'
                                           || TO_CHAR(V_YEAR)
                                           || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM'))
            AND C.DATE_OF_LOSS > ADD_MONTHS(LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                                             || '/01/'
                                                             || TO_CHAR(V_YEAR)
                                                             || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM')),
                                            - 60)
            AND C.CLAIM = CT.CLAIM
            AND CC.CLAIMANT_COVERAGE = CT.CLAIMANT_COVERAGE
            AND C.CLAIM = CCP.CLAIM
            AND CCP.CMS_POLICY = CP.CMS_POLICY
            AND ( CP.BUSINESS_LINE = 'Business Owner'
                  OR CP.BUSINESS_LINE = 'Commercial Umbrella'
                  OR CP.BUSINESS_LINE = 'Dwelling Fire'
                  OR CP.BUSINESS_LINE = 'Farm'
                  OR CP.BUSINESS_LINE = 'Farm Umbrella'
                  OR CP.BUSINESS_LINE = 'Homeowner'
                  OR CP.BUSINESS_LINE = 'Manual'
                  OR CP.BUSINESS_LINE = 'Personal Umbrella' )  AND  C.CLAIM_NBR = V_V_CLAIM_NBR
        GROUP BY
            C.CLAIM,
            C.CLAIM_NBR,
            CP.CMS_POLICY,
            CP.CMS_POLICY,
            CC.COVERAGE,
            CC.CLAIMANT--, EXPOSURE_ID
        ORDER BY
            CLAIM_NBR,
            COVERAGE;

        CURSOR C_MAIN_5YR IS
        WITH CC_DATA AS (
            SELECT
                C.ID                                         AS CLAIM,
                CASE
                    WHEN REGEXP_LIKE ( CLAIMNUMBER,
                                       '^[0-9]*$' ) THEN
                        TO_NUMBER(CLAIMNUMBER)
                    ELSE
                        00000
                END                                          AS CLAIM_NBR,
                P.ID                                         AS POLICY,
                NVL(P.DECPOLICY_EXT, P.POLICYSYSTEMPERIODID) AS DEC_POLICY,
                COV.ID                                       AS COVERAGE,
                CCTE.ID                                      AS CLAIMANT
--        , TLCOVSTY.NAME AS EXPOSURE_COV_SUBTYPE
--        , TLCOV.NAME AS COVERAGE_SUBTYPE
--        , TLCOVTY.NAME AS COVERAGE_TYPE
                ,
                TLPS.NAME                                    AS POLICY_SOURCE
        --, TLPT.NAME AS POLICY_TYPE
                ,
                'CC'                                         AS CLAIM_SOURCE,
                E.ID                                         AS EXPOSURE_ID,
                CASE
                    WHEN TLT.NAME = 'Payment'
                         AND TLCT.NAME = 'Claim Cost' THEN
                        TLI.TRANSACTIONAMOUNT
                    WHEN TLT.NAME = 'Recovery'
                         AND TLCT.NAME = 'Claim Cost' THEN
                        - TLI.TRANSACTIONAMOUNT
                    ELSE
                        0
                END                                          AS LOSS_PAID
            FROM
                CCADMIN.CC_TRANSACTION@ECIG_TO_GWCC_PRD_LINK         T
                LEFT JOIN CCADMIN.CC_TRANSACTIONLINEITEM@ECIG_TO_GWCC_PRD_LINK TLI ON TLI.TRANSACTIONID = T.ID
                                                                                      AND TLI.RETIRED = 0
                LEFT JOIN CCADMIN.CCTL_TRANSACTION@ECIG_TO_GWCC_PRD_LINK       TLT ON TLT.ID = T.SUBTYPE
                LEFT JOIN CCADMIN.CCTL_COSTTYPE@ECIG_TO_GWCC_PRD_LINK          TLCT ON TLCT.ID = T.COSTTYPE
                LEFT JOIN CCADMIN.CCTL_PAYMENTTYPE@ECIG_TO_GWCC_PRD_LINK       TLPMT ON TLPMT.ID = T.PAYMENTTYPE
                LEFT JOIN CCADMIN.CC_EXPOSURE@ECIG_TO_GWCC_PRD_LINK            E ON E.ID = T.EXPOSUREID
                                                                         AND E.RETIRED = 0
                LEFT JOIN CCADMIN.CC_CLAIM@ECIG_TO_GWCC_PRD_LINK               C ON C.ID = NVL(E.CLAIMID, T.CLAIMID)
                                                                      AND C.RETIRED = 0
                INNER JOIN CCADMIN.CC_POLICY@ECIG_TO_GWCC_PRD_LINK              P ON C.POLICYID = P.ID
                LEFT OUTER JOIN CCADMIN.CC_CLAIMCONTACT@ECIG_TO_GWCC_PRD_LINK        CCTE ON CCTE.CLAIMID = C.ID
                                                                                      AND CCTE.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CC_CONTACT@ECIG_TO_GWCC_PRD_LINK             CTE ON CTE.ID = CCTE.CONTACTID
                                                                                AND CTE.RETIRED = 0
                                                                                AND E.CLAIMANTDENORMID = CTE.ID
                INNER JOIN CCADMIN.CC_CLAIMCONTACTROLE@ECIG_TO_GWCC_PRD_LINK    CCTRE ON CCTRE.CLAIMCONTACTID = CCTE.ID
                                                                                      AND CCTRE.EXPOSUREID = E.ID
                                                                                      AND CCTRE.RETIRED = 0
                INNER JOIN CCADMIN.CCTL_CONTACTROLE@ECIG_TO_GWCC_PRD_LINK       TLCCTR ON TLCCTR.ID = CCTRE.ROLE
                                                                                    AND TLCCTR.TYPECODE IN ( 'claimant' )
                                                                                    AND TLCCTR.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CCTL_COVERAGESUBTYPE@ECIG_TO_GWCC_PRD_LINK   TLCOVSTY ON TLCOVSTY.ID = E.COVERAGESUBTYPE
                LEFT OUTER JOIN CCADMIN.CC_COVERAGE@ECIG_TO_GWCC_PRD_LINK            COV ON COV.ID = E.COVERAGEID
                                                                                 AND COV.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CCTL_COVERAGE@ECIG_TO_GWCC_PRD_LINK          TLCOV ON TLCOV.ID = COV.SUBTYPE
                                                                                     AND TLCOV.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CCTL_COVERAGETYPE@ECIG_TO_GWCC_PRD_LINK      TLCOVTY ON TLCOVTY.ID = COV.TYPE
                                                                                           AND TLCOVTY.RETIRED = 0
                LEFT OUTER JOIN CCADMIN.CCTL_POLICYSOURCE@ECIG_TO_GWCC_PRD_LINK      TLPS ON TLPS.ID = P.POLICYSOURCE
                LEFT OUTER JOIN CCADMIN.CCTL_POLICYTYPE@ECIG_TO_GWCC_PRD_LINK        TLPT ON TLPT.ID = P.POLICYTYPE
            WHERE
        --cp.Business_line = 'Business Owner' OR --Businessowners
--    cp.Business_line = 'Commercial Umbrella' OR --Commercial Umbrella
--    cp.Business_line = 'Dwelling Fire' OR -- Dwelling Fire
--    cp.Business_line = 'Farm' OR -- Farmowners
--    cp.Business_line = 'Farm Umbrella' OR -- Farm Umbrella
--    cp.Business_line = 'Homeowner' OR -- Homeowners
--    cp.Business_line = 'Manual' OR  -- Commercial Manual
--    cp.Business_line = 'Personal Umbrella' --Personal Excess
                TLPT.NAME IN ( 'Businessowners', 'Commercial Umbrella', 'Dwelling Fire', 'Farmowners', 'Farm Umbrella',
                               'Homeowners', 'Commercial Manual', 'Personal Excess' )
                AND T.UPDATETIME BETWEEN TO_DATE(TO_CHAR(V_MONTH)
                                                 || '/01/'
                                                 || TO_CHAR(V_YEAR),
        'MM/DD/YYYY') AND LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                           || '/01/'
                                           || TO_CHAR(V_YEAR)
                                           || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM'))
                AND C.LOSSDATE > ADD_MONTHS(LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                                             || '/01/'
                                                             || TO_CHAR(V_YEAR)
                                                             || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM')),- 60)
        )
        SELECT
            CLAIM,
            CLAIM_NBR,
            POLICY,
            DEC_POLICY,
            COVERAGE,
            CLAIMANT--, COVERAGE, CLAIMANT--, EXPOSURE_COV_SUBTYPE, COVERAGE_SUBTYPE, COVERAGE_TYPE
            ,
            POLICY_SOURCE--, POLICY_TYPE
            ,
            CLAIM_SOURCE--, EXPOSURE_ID
            ,
            EXPOSURE_ID,
            SUM(LOSS_PAID) AS LOSS_PAID
        FROM
            CC_DATA WHERE CLAIM_NBR = V_V_CLAIM_NBR
    --    WHERE CLAIM_NBR IN (2000001)
        GROUP BY
            CLAIM,
            CLAIM_NBR,
            POLICY,
            DEC_POLICY,
            COVERAGE,
            CLAIMANT--, COVERAGE, CLAIMANT--, EXPOSURE_COV_SUBTYPE, COVERAGE_SUBTYPE, COVERAGE_TYPE
            ,
            POLICY_SOURCE,
            CLAIM_SOURCE,
            EXPOSURE_ID
        UNION
        SELECT
            C.CLAIM,
            C.CLAIM_NBR,
            C.POLICY,
            C.DEC_POLICY,
            CC.COVERAGE,
            CC.CLAIMANT,
            'eCIG'            AS POLICY_SOURCE,
            'CMS'             AS CLAIM_SOURCE,
            NULL              AS EXPOSURE_ID,
            SUM(CT.LOSS_PAID) AS LOSS_PAID
        FROM
            CLAIM             C,
            CLAIMANT_TRANS    CT,
            CLAIMANT_COVERAGE CC,
            DEC_POLICY        DP
        WHERE
            CT.TRANS_DATE BETWEEN TO_DATE(TO_CHAR(V_MONTH)
                                          || '/01/'
                                          || TO_CHAR(V_YEAR),
        'MM/DD/YYYY') AND LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                           || '/01/'
                                           || TO_CHAR(V_YEAR)
                                           || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM'))
            AND C.DATE_OF_LOSS > ADD_MONTHS(LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                                             || '/01/'
                                                             || TO_CHAR(V_YEAR)
                                                             || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM')),- 60)
            AND C.CLAIM = CT.CLAIM
            AND CC.CLAIMANT_COVERAGE = CT.CLAIMANT_COVERAGE
            AND C.DEC_POLICY = DP.DEC_POLICY
            AND ( DP.BUSINESS_LINE = 'Business Owner'
                  OR DP.BUSINESS_LINE = 'Commercial Umbrella'
                  OR DP.BUSINESS_LINE = 'Dwelling Fire'
                  OR DP.BUSINESS_LINE = 'Farm'
                  OR DP.BUSINESS_LINE = 'Farm Umbrella'
                  OR DP.BUSINESS_LINE = 'Homeowner'
                  OR DP.BUSINESS_LINE = 'Manual'
                  OR DP.BUSINESS_LINE = 'Personal Umbrella' )  AND  C.CLAIM_NBR = V_V_CLAIM_NBR

        GROUP BY
            C.CLAIM,
            C.CLAIM_NBR,
            C.POLICY,
            C.DEC_POLICY,
            CC.COVERAGE,
            CC.CLAIMANT--, EXPOSURE_ID
        UNION
        SELECT
            C.CLAIM,
            C.CLAIM_NBR,
            CP.CMS_POLICY     POLICY,
            CP.CMS_POLICY     DEC_POLICY,
            CC.COVERAGE,
            CC.CLAIMANT,
            'PolicyCenter'    AS POLICY_SOURCE,
            'CMS'             AS CLAIM_SOURCE,
            NULL              AS EXPOSURE_ID,
            SUM(CT.LOSS_PAID) AS LOSS_PAID
        FROM
            CLAIM             C,
            CLAIMANT_TRANS    CT,
            CLAIMANT_COVERAGE CC,
            CMS_CLAIM_POLICY  CCP,
            CMS_POLICY        CP
        WHERE
            CT.TRANS_DATE BETWEEN TO_DATE(TO_CHAR(V_MONTH)
                                          || '/01/'
                                          || TO_CHAR(V_YEAR),
        'MM/DD/YYYY') AND LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                           || '/01/'
                                           || TO_CHAR(V_YEAR)
                                           || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM'))
            AND C.DATE_OF_LOSS > ADD_MONTHS(LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                                             || '/01/'
                                                             || TO_CHAR(V_YEAR)
                                                             || ' 11:59:59 PM',
        'MM/DD/YYYY HH:MI:SS PM')),- 60)
            AND C.CLAIM = CT.CLAIM
            AND CC.CLAIMANT_COVERAGE = CT.CLAIMANT_COVERAGE
            AND C.CLAIM = CCP.CLAIM
            AND CCP.CMS_POLICY = CP.CMS_POLICY
            AND ( CP.BUSINESS_LINE = 'Business Owner'
                  OR CP.BUSINESS_LINE = 'Commercial Umbrella'
                  OR CP.BUSINESS_LINE = 'Dwelling Fire'
                  OR CP.BUSINESS_LINE = 'Farm'
                  OR CP.BUSINESS_LINE = 'Farm Umbrella'
                  OR CP.BUSINESS_LINE = 'Homeowner'
                  OR CP.BUSINESS_LINE = 'Manual'
                  OR CP.BUSINESS_LINE = 'Personal Umbrella' )  AND  C.CLAIM_NBR = V_V_CLAIM_NBR
    -- AND 1=0
        GROUP BY
            C.CLAIM,
            C.CLAIM_NBR,
            CP.CMS_POLICY,
            CP.CMS_POLICY,
            CC.COVERAGE,
            CC.CLAIMANT--, EXPOSURE_ID
        ORDER BY
            CLAIM_NBR,
            COVERAGE;

-- PL-6986: Split up the c_dp cursor into c_dp and c_dp_pc so that we are
-- looking for data only from the appropriate source of data depanding on where
-- the policy is (eCig or Policy Center).
        CURSOR C_DP IS
        SELECT
            POLICY_SEARCH_NBR,
            INSURED_ADDR_NBR,
            UPPER(INSURED_STREET_NAME) INSURED_ADDR_STREET_NAME,
            UPPER(INSURED_SUFFIX)      INSURED_ADDR_STREET_TYPE,
            UPPER(INSURED_SUITE)       INSURED_ADDR_APT_NBR,
            UPPER(INSURED_CITY)        INSURED_ADDR_CITY,
            INSURED_STATE              INSURED_ADDR_STATE,
            INSURED_ZIPCODE            INSURED_ADDR_ZIPCODE,
            UPPER(INSURED_PO)          INSURED_ADDR_PO_BOX,
            WRITING_COMPANY,
            UPPER(LEGAL_NAME)          BUSINESS_NAME,
            BUSINESS_LINE              V_DP_BUSINESS_LINE
        FROM
            DEC_POLICY
        WHERE
                DEC_POLICY = V_DEC_POLICY
            AND 'eCIG' = V_SOURCE_OF_POLICY -- ADDING THE POLICY SOURCE AND CLAIM SOURCE AS NOT TO MATCH THE CC's POLICYID with the DEC_POLICY
            AND 'CMS' = V_SOURCE_OF_CLAIM;

        CURSOR C_DP_PC IS
        SELECT
            REGEXP_SUBSTR(POLICY_SEARCH_NBR, '[^-]+$') AS POLICY_SEARCH_NBR,
            INSUREDAD.ADDR_NBR                         INSURED_ADDR_NBR,
            UPPER(INSUREDAD.STREET_NAME)               INSURED_ADDR_STREET_NAME,
            UPPER(INSUREDAD.SUFFIX)                    INSURED_ADDR_STREET_TYPE,
            UPPER(INSUREDAD.SUITE)                     INSURED_ADDR_APT_NBR,
            UPPER(INSUREDAD.CITY)                      INSURED_ADDR_CITY,
            INSUREDAD.STATE                            INSURED_ADDR_STATE,
            INSUREDAD.ZIP_CODE                         INSURED_ADDR_ZIPCODE,
            UPPER(INSUREDAD.PO_BOX)                    INSURED_ADDR_PO_BOX,
            WRITING_COMPANY,
            UPPER(LEGAL_NAME)                          BUSINESS_NAME,
            BUSINESS_LINE                              V_DP_BUSINESS_LINE
        FROM
            CMS_POLICY
            LEFT OUTER JOIN CMS_INSURED CI ON CMS_POLICY.CMS_POLICY = CI.CMS_POLICY
            LEFT OUTER JOIN ADDR        INSUREDAD ON CI.CMS_INSURED = INSUREDAD.TABLE_KEY
                                              AND INSUREDAD.TABLE_NAME = 'CMS_INSURED'
        WHERE
                CMS_POLICY.CMS_POLICY = V_DEC_POLICY
            AND 'PolicyCenter' = V_SOURCE_OF_POLICY-- ADDING THE POLICY SOURCE AND CLAIM SOURCE AS NOT TO MATCH THE CC's POLICYID with the DEC_POLICY
            AND 'CMS' = V_SOURCE_OF_CLAIM;

        CURSOR C_DP_CC_POLICIES IS
        SELECT
            P.POLICYNUMBER     AS POLICY_SEARCH_NBR
--,INSURED_ADDRESS_DETAILS
            ,
            NULL               AS INSURED_ADDR_NBR,
            CA.ADDRESSLINE1
            || ' '
            || CA.ADDRESSLINE2 AS INSURED_ADDR_STREET_NAME,
            NULL               AS INSURED_ADDR_STREET_TYPE,
            NULL               AS INSURED_ADDR_APT_NBR,
            CA.CITY            AS INSURED_ADDR_CITY,
            TLST.TYPECODE      AS INSURED_ADDR_STATE,
            CA.POSTALCODE      AS INSURED_ADDR_ZIPCODE,
            NULL               AS INSURED_ADDR_PO_BOX
--,TLCT.NAME AS SUBTYPE_NAME
            ,
            TLUCT.NAME         AS WRITING_COMPANY
--,CT.NAME AS COMPANY_NAME, CT.FIRSTNAME, CT.LASTNAME
--, CT.SUBTYPE,
            ,
            P.LEGALNAME_EXT    AS BUSINESS_NAME,
            CASE
                WHEN ( TLPTY.NAME = 'Businessowners' ) THEN
                    'Business Owner'
                WHEN ( TLPTY.NAME = 'Comm/Farm Auto' ) THEN
                        CASE
                            WHEN ( P.POLICYNUMBER LIKE '%FAA%'
                                   OR P.POLICYNUMBER LIKE '%SAA%'
                                   OR P.POLICYNUMBER LIKE '%GAA%' ) THEN
                                'Farm Auto'
                            ELSE
                                'Commercial Auto'
                        END
                WHEN ( TLPTY.NAME = 'Farmowners' ) THEN
                    'Farm'
                WHEN ( TLPTY.NAME = 'Commercial Manual' ) THEN
                    'Manual'
                WHEN ( TLPTY.NAME = 'Homeowners' ) THEN
                    'Homeowner'
                WHEN ( TLPTY.NAME = 'Personal Auto' ) THEN
                    'Personal Automobile'
                WHEN ( TLPTY.NAME = 'Personal Excess' ) THEN
                    'Personal Umbrella'
                ELSE
                    TLPTY.NAME
            END                AS V_DP_BUSINESS_LINE
        FROM
                 CCADMIN.CC_CLAIM@ECIG_TO_GWCC_PRD_LINK C
            INNER JOIN CCADMIN.CC_POLICY@ECIG_TO_GWCC_PRD_LINK                    P ON P.ID = C.POLICYID
            INNER JOIN CCADMIN.CC_CONTACT@ECIG_TO_GWCC_PRD_LINK                   CT ON CT.ID = C.INSUREDDENORMID
            INNER JOIN CCADMIN.CC_ADDRESS@ECIG_TO_GWCC_PRD_LINK                   CA ON CA.ID = CT.PRIMARYADDRESSID
            INNER JOIN CCADMIN.CCTL_CONTACT@ECIG_TO_GWCC_PRD_LINK                 TLCT ON TLCT.ID = CT.SUBTYPE
            LEFT OUTER JOIN CCADMIN.CCTL_UNDERWRITINGCOMPANYTYPE@ECIG_TO_GWCC_PRD_LINK TLUCT ON P.UNDERWRITINGCO = TLUCT.ID
                                                                                                AND TLUCT.RETIRED = 0
            LEFT OUTER JOIN CCADMIN.CCTL_POLICYTYPE@ECIG_TO_GWCC_PRD_LINK              TLPTY ON TLPTY.ID = P.POLICYTYPE
                                                                                   AND TLPTY.RETIRED = 0
            LEFT OUTER JOIN CCADMIN.CCTL_STATE@ECIG_TO_GWCC_PRD_LINK                   TLST ON TLST.ID = CA.STATE
        WHERE
            ( ( P.DECPOLICY_EXT = V_DEC_POLICY
                AND 'CC' = V_SOURCE_OF_CLAIM
                AND ( 'eCIG' = V_SOURCE_OF_POLICY
                      OR 'AQS' = V_SOURCE_OF_POLICY ) )
              OR ( P.POLICYSYSTEMPERIODID = V_DEC_POLICY
                   AND 'CC' = V_SOURCE_OF_CLAIM
                   AND 'PolicyCenter' = V_SOURCE_OF_POLICY ) )
            AND 'CC' = V_SOURCE_OF_CLAIM;

        R_DP                          C_DP%ROWTYPE;

-- 8/18/05 Issue 6424 GN: replace insureds ssn with zeros
        CURSOR C_POLICYHOLDER IS
        SELECT
            UPPER(I.SALUTATION)  SALUTATION,
            UPPER(I.LAST_NAME)   LAST_NAME,
            UPPER(I.FIRST_NAME)  FIRST_NAME,
            UPPER(I.MIDDLE_NAME) MIDDLE_NAME,
            UPPER(I.SUFFIX)      SUFFIX,
            '000000000'          SSN,
            I.DATE_OF_BIRTH      DOB,
            I.GENDER,
            I.NAMED_INSURED,
            'eCIG'               AS POLICY_SOURCE,
            'CMS'                AS CLAIM_SOURCE
        FROM
            POLICY  P,
            INSURED I
        WHERE
                P.POLICY = V_POLICY
            AND I.NAMED_INSURED = P.NAMED_INSURED
            AND I.FIRST_NAME IS NOT NULL
            AND 'eCIG' = V_SOURCE_OF_POLICY
            AND 'CMS' = V_SOURCE_OF_CLAIM
        UNION
        SELECT
            NULL                 AS SALUTATION,
            UPPER(I.LAST_NAME)   LAST_NAME,
            UPPER(I.FIRST_NAME)  FIRST_NAME,
            UPPER(I.MIDDLE_NAME) MIDDLE_NAME,
            UPPER(I.SUFFIX)      SUFFIX,
            '000000000'          SSN,
            I.DATE_OF_BIRTH      DOB,
            I.GENDER,
            I.CMS_INSURED        AS NAMED_INSURED,
            'PolicyCenter'       AS POLICY_SOURCE,
            'CMS'                AS CLAIM_SOURCE
        FROM
            CMS_POLICY  P,
            CMS_INSURED I
        WHERE
                P.CMS_POLICY = V_POLICY
            AND I.CMS_POLICY = P.CMS_POLICY
            AND I.FIRST_NAME IS NOT NULL
            AND 'PolicyCenter' = V_SOURCE_OF_POLICY
            AND 'CMS' = V_SOURCE_OF_CLAIM
        UNION
        SELECT
            NULL                 AS SALUTATION,
            UPPER(CT.LASTNAME)   LAST_NAME,
            CASE
                WHEN TLCT.NAME = 'Company' THEN
                    UPPER(CT.NAME)
                ELSE
                    UPPER(CT.FIRSTNAME)
            END                  FIRST_NAME,
            UPPER(CT.MIDDLENAME) MIDDLE_NAME,
            NULL                 AS SUFFIX,
            '000000000'          SSN,
            CT.DATEOFBIRTH       DOB
--, CT.gender
            ,
            TLG.TYPECODE         AS GENDER,
            CT.ID                AS NAMED_INSURED -- Use CONTACT ID, as TAXID and DOINGBUSINESSAS_EXT is available in the CC_CONTACT table
            ,
            TLPS.NAME            AS POLICY_SOURCE,
            'CC'                 AS CLAIM_SOURCE
        FROM
                 CCADMIN.CC_CLAIM@ECIG_TO_GWCC_PRD_LINK C
            INNER JOIN CCADMIN.CC_POLICY@ECIG_TO_GWCC_PRD_LINK                    P ON P.ID = C.POLICYID
            INNER JOIN CCADMIN.CC_CONTACT@ECIG_TO_GWCC_PRD_LINK                   CT ON CT.ID = C.INSUREDDENORMID
            LEFT OUTER JOIN CCADMIN.CCTL_GENDERTYPE@ECIG_TO_GWCC_PRD_LINK              TLG ON TLG.ID = CT.GENDER
            LEFT OUTER JOIN CCADMIN.CC_ADDRESS@ECIG_TO_GWCC_PRD_LINK                   CA ON CA.ID = CT.PRIMARYADDRESSID
            LEFT OUTER JOIN CCADMIN.CCTL_CONTACT@ECIG_TO_GWCC_PRD_LINK                 TLCT ON TLCT.ID = CT.SUBTYPE
            LEFT OUTER JOIN CCADMIN.CCTL_UNDERWRITINGCOMPANYTYPE@ECIG_TO_GWCC_PRD_LINK TLUCT ON P.UNDERWRITINGCO = TLUCT.ID
                                                                                                AND TLUCT.RETIRED = 0
            LEFT OUTER JOIN CCADMIN.CCTL_POLICYTYPE@ECIG_TO_GWCC_PRD_LINK              TLPTY ON TLPTY.ID = P.POLICYTYPE
                                                                                   AND TLPTY.RETIRED = 0
            LEFT OUTER JOIN CCADMIN.CCTL_STATE@ECIG_TO_GWCC_PRD_LINK                   TLST ON TLST.ID = CA.STATE
            LEFT OUTER JOIN CCADMIN.CCTL_POLICYSOURCE@ECIG_TO_GWCC_PRD_LINK            TLPS ON TLPS.ID = P.POLICYSOURCE
        WHERE
                P.ID = V_POLICY
            AND 'CC' = V_SOURCE_OF_CLAIM;

        R_POLICYHOLDER1               C_POLICYHOLDER%ROWTYPE;
        R_POLICYHOLDER2               C_POLICYHOLDER%ROWTYPE;
        CURSOR C_CLAIM IS
        SELECT
            DATE_OF_LOSS,
            TABLE_NAME,
            UNIT_KEY,
            CLAIM_STATUS,
            TO_CHAR(CATASTROPHE) CAT_NBR,
            UPPER(LOCATION)      LOSS_LOCATION,
            UPPER(CITY)          LOSS_CITY,
            UPPER(STATE)         LOSS_STATE,
            TO_CHAR(ZIP_CODE)    LOSS_ZIPCODE,
            'CMS'                AS SOURCE
        FROM
            CLAIM
        WHERE
                CLAIM = V_CLAIM
            AND 'CMS' = V_SOURCE_OF_CLAIM
--ORDER By date_of_loss  DESC
        UNION
        SELECT
            C.LOSSDATE           AS DATE_OF_LOSS,
            NULL                 AS TABLE_NAME,
            NULL                 AS UNIT_KEY,
            TLCS.NAME            AS CLAIM_STATUS,
            CT.CATASTROPHENUMBER AS CAT_NBR -- This is the actual Cat number, where for the CMS primary key was considered
            ,
            UPPER(TRIM(CA.ADDRESSLINE1
                       || ' '
                       || CA.ADDRESSLINE2
                       || ' '
                       || CA.ADDRESSLINE3)) AS LOSS_LOCATION,
            CA.CITY              AS LOSS_CITY,
            TLST.TYPECODE        AS LOSS_STATE,
            CA.POSTALCODE        AS LOSS_ZIPCODE,
            'CC'                 AS SOURCE
        FROM
            CCADMIN.CC_CLAIM@ECIG_TO_GWCC_PRD_LINK        C
            LEFT OUTER JOIN CCADMIN.CCTL_CLAIMSTATE@ECIG_TO_GWCC_PRD_LINK TLCS ON TLCS.ID = C.STATE
            LEFT OUTER JOIN CCADMIN.CC_CATASTROPHE@ECIG_TO_GWCC_PRD_LINK  CT ON CT.ID = C.CATASTROPHEID
            LEFT OUTER JOIN CCADMIN.CC_ADDRESS@ECIG_TO_GWCC_PRD_LINK      CA ON CA.ID = C.LOSSLOCATIONID
            LEFT OUTER JOIN CCADMIN.CCTL_STATE@ECIG_TO_GWCC_PRD_LINK      TLST ON TLST.ID = CA.STATE
        WHERE
                C.ID = V_CLAIM
            AND 'CC' = V_SOURCE_OF_CLAIM;

        R_CLAIM                       C_CLAIM%ROWTYPE;
        CURSOR C_SUBRO IS
        SELECT
            SUBROGATION,
            SUBRO_STATUS,
            AMT_COVERED,
            'CMS' AS CLAIM_SOURCE
        FROM
            SUBROGATION
        WHERE
                CLAIM = V_CLAIM
            AND 'CMS' = V_SOURCE_OF_CLAIM
        UNION
        SELECT
            S.ID     AS SUBROGATION,
            TLS.NAME AS SUBRO_STATUS,
            NULL     AS AMT_COVERED -- currently for CMS this value is always null, need to address this one for CC
            ,
            'CC'     AS CLAIM_SOURCE
        FROM
                 CCADMIN.CC_SUBROGATIONSUMMARY@ECIG_TO_GWCC_PRD_LINK SS
            INNER JOIN CCADMIN.CC_CLAIM@ECIG_TO_GWCC_PRD_LINK               C ON C.ID = SS.CLAIMID
            INNER JOIN CCADMIN.CC_SUBROGATION@ECIG_TO_GWCC_PRD_LINK         S ON S.SUBROGATIONSUMMARYID = SS.ID
            INNER JOIN CCADMIN.CCTL_SUBROGATIONSTATUS@ECIG_TO_GWCC_PRD_LINK TLS ON TLS.ID = S.STATUS
        WHERE
                C.ID = V_CLAIM
            AND 'CC' = V_SOURCE_OF_CLAIM;

        R_SUBROGATION                 C_SUBRO%ROWTYPE;
        CURSOR C_STATUS IS
        SELECT
            COUNT(CLAIMANT_COVERAGE)
        FROM
            CLAIMANT_COVERAGE
        WHERE
                CLAIM = V_CLAIM
            AND COVERAGE = V_CC_COVERAGE
            AND STATUS IN ( 'OPEN', 'Reopened' )
            AND 'CMS' = V_SOURCE_OF_CLAIM
        UNION
        SELECT
            COUNT(EX.ID)
        FROM
                 CCADMIN.CC_EXPOSURE@ECIG_TO_GWCC_PRD_LINK EX
            INNER JOIN CCADMIN.CC_CLAIM@ECIG_TO_GWCC_PRD_LINK           C ON C.ID = EX.CLAIMID
            INNER JOIN CCADMIN.CCTL_EXPOSURESTATE@ECIG_TO_GWCC_PRD_LINK TLES ON TLES.ID = EX.STATE
        WHERE
            TLES.NAME IN ( 'Open','Closed' )
            AND C.ID = V_CLAIM
            AND 'CC' = V_SOURCE_OF_CLAIM
-- Looks like the usage of c_status below is not being used anywhere.
            ;

-----------------------------------------------------------------
--Get 'Doing Business AS' & Federal Tax ID (insured_business)
        CURSOR C_DBA IS
        SELECT
            UPPER(DOING_BUSINESS_AS) DOING_BUSINESS_AS,
            TAX_ID
        FROM
            INSURED_BUSINESS
--WHERE named_insured = r.named_insured;
        WHERE
                NAMED_INSURED = V_POLICYHOLDER1_NAMED_INSURED
            AND 'CMS' = V_SOURCE_OF_CLAIM
            AND 'eCIG' = V_SOURCE_OF_POLICY
        UNION
        SELECT
            UPPER(DOING_BUSINESS_AS) DOING_BUSINESS_AS,
            TAX_ID
        FROM
            CMS_INSURED
        WHERE
                CMS_INSURED = V_POLICYHOLDER1_NAMED_INSURED
            AND 'CMS' = V_SOURCE_OF_CLAIM
            AND 'PolicyCenter' = V_SOURCE_OF_POLICY
        UNION
        SELECT
            UPPER(DOINGBUSINESSAS_EXT) AS DOING_BUSINESS_AS,
            TAXID                      AS TAX_ID
        FROM
            CCADMIN.CC_CONTACT@ECIG_TO_GWCC_PRD_LINK
        WHERE
                ID = V_POLICYHOLDER1_NAMED_INSURED
            AND 'CC' = V_SOURCE_OF_CLAIM;

        R_DBA                         C_DBA%ROWTYPE;

--Get Mortgagee & Loan Number (dec_addl_interest)
        CURSOR C_DAI IS
        SELECT
            UPPER(SUBSTR(FINANCIAL_NAME, 1, 40)) FINANCE_CO,
            LOAN_NBR
        FROM
            DEC_ADDL_INTEREST DAI,
            CLAIM             C
        WHERE
            ( V_CLAIM_NBR = C.CLAIM_NBR
              AND DAI.TABLE_NAME = C.TABLE_NAME
              AND DAI.TABLE_KEY = C.UNIT_KEY
              AND 'CMS' = V_SOURCE_OF_CLAIM );

        R_DAI                         C_DAI%ROWTYPE;

--Convert dept_nbr to "policy type"
        CURSOR C_DEPT IS
        SELECT
            DEPT_NBR,
            'CMS' AS CLAIM_SOURCE
        FROM
            DEPT              D,
            CLAIMANT_COVERAGE CC
        WHERE
            ( V_CC_CLAIMANT = CC.CLAIMANT
              AND V_CC_COVERAGE = CC.COVERAGE
              AND CC.DEPT = D.DEPT )
            AND 'CMS' = V_SOURCE_OF_CLAIM
        UNION
--BELOW SQL CODE WAS ADDED IN PLACE OF THE EARLIER CODE(vw_deptnumber in WHOUSE), AS WE ARE FACING AN ISSUE
-- WITH DEPT_NBR not being populated for a CLAIM due to the CLAIM Object graph issue in
-- ClaimCenter
        SELECT DISTINCT
            DEPT_NBR,
            'CC' AS CLAIM_SOURCE
        FROM
            WHOUSE.DW_CLAIMANT_DETAIL
        WHERE
                SOURCE = 'CC'
            AND CLAIM_KEY = V_CLAIM;

        R_DEPT                        C_DEPT%ROWTYPE;

--Convert cause of loss name to "claim type"
        CURSOR C_CAUSE_OF_LOSS1 IS
        SELECT
            DECODE(CAUSE_NAME, '1st P Mold', 'CONTA',              --01
             'Advertising', 'OTHER',             --02
                   'Animal Loss', 'OTHER',             --03
                   'BI (Auto)', 'OTHER',               --04
                   'Bodily Injury',
                   'OTHER',           --05
                   'Burglary', 'THEFT',                --06
                   'Cal Add', 'OTHER',                 --07
                   'Coll', 'OTHER',                    --08
                   'Comp', 'OTHER',                    --09
                   'Comp (Theft)',
                   'OTHER',            --10
                   'Contents', 'OTHER',                --11
                   'Earthquake', 'QUAKE',              --12
                   'Employee Benefits', 'OTHER',       --13
                   'Employee Dishonesty', 'OTHER',     --14
                   'Environmental',
                   'OTHER',           --15
                   'Explosion', 'OTHER',               --16
                   'Fire', 'FIRE',                     --17
                   'Flood (Mobile Home Only)', 'FLOOD',--18
                   'Glass', 'OTHER',                   --19
                   'Habitability',
                   'OTHER',            --20
                   'MP (Auto)', 'OTHER',               --21
                   'Malpractice, Professional Liability', 'OTHER', --22
                   'Mechanical Breakdown', 'OTHER',    --23
                   'Medical Payments', 'MEDICAL',      --24
                   'Mold BI',
                   'CONTA',                 --25
                   'Mold PD', 'CONTA',                 --26
                   'Mold PI', 'CONTA',                 --27
                   'Other', 'OTHER',                   --28
                   'PD (Auto)', 'OTHER',               --29
                   'Personal Injury',
                   'OTHER',          --30
                   'Pollution', 'CONTA',               --31
                   'Property Damage', 'PHYDA',         --32
                   'RR', 'OTHER',                      --33
                   'Reinsurance-Bodily Injury', 'OTHER',               --34
                   'Riot, Civil Commtion',
                   'OTHER',    --35
                   'Robbery', 'OTHER',                 --36
                   'Storm', 'OTHER',                   --37
                   'Structure', 'PHYDA',               --38
                   'TL', 'OTHER',                      --39
                   'Theft',
                   'THEFT',                   --40
                   'UIM', 'OTHER',                     --41
                   'UM COLL', 'OTHER',                 --42
                   'UMBI', 'OTHER',                    --43
                   'UMPD', 'OTHER',                    --44
                   'Vandalism, Malicious Mischief',
                   'VMM',             --45
                   'Water', 'WATER',                   --46
                   'Workers Compensation', 'WC',       --47
                   'WC -Indemnity', 'WC',               --48 - Niraj - CMS Maint  rel 3.4  TTP#629
                   'WC-Med', 'WC',               --49 -  Niraj - CMS Maint  rel 3.4 TTP#629
                   'WC -Liability',
                   'WC',               --50 - Niraj -  CMS Maint  rel 3.4 TTP#629
                   'Electrical Breakdown', 'OTHER',               --51 - Niraj -  CMS Maint  rel 3.4 TTP#629
                   'Rupture/Bursting/Explosion/Implosion', 'OTHER',               --52 - Niraj -  CMS Maint  rel 3.4 TTP#629
				   'Employment Practices', -- 53
				   'OTHER',
				   'Service Line', -- 54
				   'OTHER',
				   'Riot, Civil Commotion', -- 55
                   'Riot or Civil Commotion',
                   'Home Cyber', -- 56
                   'OTHER',
                   'ID Theft', --57
                   'Identification Thef',
                   '**' || CAUSE_NAME)
        FROM
            CAUSE_OF_LOSS     COL,
            CLAIMANT_COVERAGE CC
        WHERE
            ( V_CC_CLAIMANT = CC.CLAIMANT
              AND V_CC_COVERAGE = CC.COVERAGE
              AND CC.CAUSE_OF_LOSS = COL.CAUSE_OF_LOSS
              AND 'CMS' = V_SOURCE_OF_CLAIM )
        UNION
        SELECT
            DECODE(WHOUSE.GET_CAUSE_OF_LOSS(V_EXPOSURE_ID),
                   '1st P Mold',
                   'CONTA',      --01
                   'Advertising',
                   'OTHER',         --02
                   'Animal Loss',
                   'OTHER',         --03
                   'BI (Auto)',
                   'OTHER',           --04
                   'Bodily Injury',
                   'OTHER',       --05
                   'Burglary',
                   'THEFT',       --06
                   'Cal ADD',
                   'OTHER',             --07
                   'Coll',
                   'OTHER',                --08
                   'Comp',
                   'OTHER',                --09
                   'Comp (Theft)',
                   'OTHER',        --10
                   'Contents',
                   'OTHER',            --11
                   'Earthquake',
                   'QUAKE',              --12
                   'Employee Benefits',
                   'OTHER',   --13
                   'Employee Dishonesty',
                   'OTHER', --14
                   'Environmental',
                   'OTHER',       --15
                   'Explosion',
                   'OTHER',           --16
                   'Fire',
                   'FIRE',                     --17
                   'Flood (Mobile Home Only)',
                   'FLOOD',--18
                   'Glass',
                   'OTHER',               --19
                   'Habitability',
                   'OTHER',        --20
                   'MP (Auto)',
                   'OTHER',           --21
                   'Malpractice, Professional Liability',
                   'OTHER', --22
                   'Mechanical Breakdown',
                   'OTHER',--23
                   'Medical Payments',
                   'MEDICAL',             --24
                   'Mold BI',
                   'CONTA',         --25
                   'Mold PD',
                   'CONTA',         --26
                   'Mold PI',
                   'CONTA',         --27
                   'Other',
                   'OTHER',               --28
                   'PD (Auto)',
                   'OTHER',           --29
                   'Personal Injury',
                   'OTHER',      --30
                   'Pollution',
                   'CONTA',       --31
                   'Property Damage',
                   'PHYDA',  --32
                   'RR',
                   'OTHER',                  --33
                   'Reinsurance-Bodily Injury',
                   'OTHER',           --34
                   'Riot, Civil Commtion',
                   'OTHER',--35
                   'Robbery',
                   'OTHER',             --36
                   'Storm',
                   'OTHER',               --37
                   'Structure',
                   'PHYDA',        --38
                   'TL',
                   'OTHER',                  --39
                   'Theft',
                   'THEFT',          --40
                   'UIM',
                   'OTHER',                 --41
                   'UM COLL',
                   'OTHER',             --42
                   'UMBI',
                   'OTHERR',                --43
                   'UMPD',
                   'OTHER',                --44
                   'Vandalism, Malicious Mischief',
                   'VMM',--45
                   'Water',
                   'WATER',                   --46
                   'Workers Compensation',
                   'WC',       --47
                   'WC -Indemnity',
                   'WC',               --48 - Niraj - CMS Maint  rel 3.4  TTP#629
                   'WC-Med',
                   'WC',               --49 -  Niraj - CMS Maint  rel 3.4 TTP#629
                   'WC -Liability',
                   'WC',               --50 - Niraj -  CMS Maint  rel 3.4 TTP#629
                   'Electrical Breakdown',
                   'OTHER',               --51 - Niraj -  CMS Maint  rel 3.4 TTP#629
                   'Rupture/Bursting/Explosion/Implosion',
                   'OTHER',               --52 - Niraj -  CMS Maint  rel 3.4 TTP#629
				   'Employment Practices', -- 53
				   'OTHER',
				   'Service Line', -- 54
				   'OTHER',
				   'Riot, Civil Commotion', -- 55
                   'Riot or Civil Commotion',
                   'Home Cyber', -- 56
                   'OTHER',
                   'ID Theft', --57
                   'Identification Thef',
                   '**' || WHOUSE.GET_CAUSE_OF_LOSS(V_EXPOSURE_ID))
        FROM
            DUAL
        WHERE
            'CC' = V_SOURCE_OF_CLAIM;
--r_cause_of_loss1     c_cause_of_loss1%ROWTYPE;

--Convert cause of loss name to "claim desc"
        CURSOR C_CAUSE_OF_LOSS2 IS
--SELECT UPPER(cause_name) cause_desc
        SELECT
            DECODE(CAUSE_NAME, '1st P Mold', 'CONTAMINATION',      --01
             'Advertising', 'ALL OTHER',         --02
                   'Animal Loss', 'ALL OTHER',         --03
                   'BI (Auto)', 'ALL OTHER',           --04
                   'Bodily Injury',
                   'ALL OTHER',       --05
                   'Burglary', 'THEFT/BURGLARY',       --06
                   'Cal ADD', 'ALL OTHER',             --07
                   'Coll', 'ALL OTHER',                --08
                   'Comp', 'ALL OTHER',                --09
                   'Comp (Theft)',
                   'ALL OTHER',        --10
                   'Contents', 'ALL OTHER',            --11
                   'Earthquake', 'QUAKE',              --12
                   'Employee Benefits', 'ALL OTHER',   --13
                   'Employee Dishonesty', 'ALL OTHER', --14
                   'Environmental',
                   'ALL OTHER',       --15
                   'Explosion', 'ALL OTHER',           --16
                   'Fire', 'FIRE',                     --17
                   'Flood (Mobile Home Only)', 'FLOOD',--18
                   'Glass', 'ALL OTHER',               --19
                   'Habitability',
                   'OTHER',        --20
                   'MP (Auto)', 'ALL OTHER',           --21
                   'Malpractice, Professional Liability', 'ALL OTHER', --22
                   'Mechanical Breakdown', 'ALL OTHER',--23
                   'Medical Payments', 'MEDICAL PAYMENTS',             --24
                   'Mold BI',
                   'CONTAMINATION',         --25
                   'Mold PD', 'CONTAMINATION',         --26
                   'Mold PI', 'CONTAMINATION',         --27
                   'Other', 'ALL OTHER',               --28
                   'PD (Auto)', 'ALL OTHER',           --29
                   'Personal Injury',
                   'ALL OTHER',      --30
                   'Pollution', 'CONTAMINATION',       --31
                   'Property Damage', 'PHYSICAL DAMAGE (ALL OTHERS)',  --32
                   'RR', 'ALL OTHER',                  --33
                   'Reinsurance-Bodily Injury', 'ALL OTHER',           --34
                   'Riot, Civil Commtion',
                   'ALL OTHER',--35
                   'Robbery', 'ALL OTHER',             --36
                   'Storm', 'ALL OTHER',               --37
                   'Structure', 'PHYSICAL DAMAGE (ALL OTHERS)',        --38
                   'TL', 'ALL OTHER',                  --39
                   'Theft',
                   'THEFT/BURGLARY',          --40
                   'UIM', 'ALL OTHER',                 --41
                   'UM COLL', 'ALL OTHER',             --42
                   'UMBI', 'ALL OTHER',                --43
                   'UMPD', 'ALL OTHER',                --44
                   'Vandalism, Malicious Mischief',
                   'VANDALISM, MALICIOUS MISCHIEF',--45
                   'Water', 'WATER DAMAGE',                   --46
                   'Workers Compensation', 'WORKERS'' COMPENSATION',       --47
                   'WC -Indemnity', 'WORKERS'' COMPENSATION',               --48 - Niraj - CMS Maint  rel 3.4  TTP#629
                   'WC-Med', 'WORKERS'' COMPENSATION',               --49 -  Niraj - CMS Maint  rel 3.4 TTP#629
                   'WC -Liability',
                   'WORKERS'' COMPENSATION',               --50 - Niraj -  CMS Maint  rel 3.4 TTP#629
                   'Electrical Breakdown', 'ALL OTHER',               --51 - Niraj -  CMS Maint  rel 3.4 TTP#629
                   'Rupture/Bursting/Explosion/Implosion', 'ALL OTHER',               --52 - Niraj -  CMS Maint  rel 3.4 TTP#629
				   'Employment Practices', -- 53
				   'OTHER',
				   'Service Line', -- 54
				   'OTHER',
				   'Riot, Civil Commotion', -- 55
                   'Riot or Civil Commotion',
                   'Home Cyber', -- 56
                   'OTHER',
                   'ID Theft', --57
                   'Identification Thef',
                   '**' || CAUSE_NAME)
        FROM
            CAUSE_OF_LOSS     COL,
            CLAIMANT_COVERAGE CC
        WHERE
            ( V_CC_CLAIMANT = CC.CLAIMANT
              AND V_CC_COVERAGE = CC.COVERAGE
              AND CC.CAUSE_OF_LOSS = COL.CAUSE_OF_LOSS
              AND 'CMS' = V_SOURCE_OF_CLAIM )
        UNION
        SELECT
            DECODE(WHOUSE.GET_CAUSE_OF_LOSS(V_EXPOSURE_ID),
                   '1st P Mold',
                   'CONTAMINATION',      --01
                   'Advertising',
                   'ALL OTHER',         --02
                   'Animal Loss',
                   'ALL OTHER',         --03
                   'BI (Auto)',
                   'ALL OTHER',           --04
                   'Bodily Injury',
                   'ALL OTHER',       --05
                   'Burglary',
                   'THEFT/BURGLARY',       --06
                   'Cal ADD',
                   'ALL OTHER',             --07
                   'Coll',
                   'ALL OTHER',                --08
                   'Comp',
                   'ALL OTHER',                --09
                   'Comp (Theft)',
                   'ALL OTHER',        --10
                   'Contents',
                   'ALL OTHER',            --11
                   'Earthquake',
                   'QUAKE',              --12
                   'Employee Benefits',
                   'ALL OTHER',   --13
                   'Employee Dishonesty',
                   'ALL OTHER', --14
                   'Environmental',
                   'ALL OTHER',       --15
                   'Explosion',
                   'ALL OTHER',           --16
                   'Fire',
                   'FIRE',                     --17
                   'Flood (Mobile Home Only)',
                   'FLOOD',--18
                   'Glass',
                   'ALL OTHER',               --19
                   'Habitability',
                   'OTHER',        --20
                   'MP (Auto)',
                   'ALL OTHER',           --21
                   'Malpractice, Professional Liability',
                   'ALL OTHER', --22
                   'Mechanical Breakdown',
                   'ALL OTHER',--23
                   'Medical Payments',
                   'MEDICAL PAYMENTS',             --24
                   'Mold BI',
                   'CONTAMINATION',         --25
                   'Mold PD',
                   'CONTAMINATION',         --26
                   'Mold PI',
                   'CONTAMINATION',         --27
                   'Other',
                   'ALL OTHER',               --28
                   'PD (Auto)',
                   'ALL OTHER',           --29
                   'Personal Injury',
                   'ALL OTHER',      --30
                   'Pollution',
                   'CONTAMINATION',       --31
                   'Property Damage',
                   'PHYSICAL DAMAGE (ALL OTHERS)',  --32
                   'RR',
                   'ALL OTHER',                  --33
                   'Reinsurance-Bodily Injury',
                   'ALL OTHER',           --34
                   'Riot, Civil Commtion',
                   'ALL OTHER',--35
                   'Robbery',
                   'ALL OTHER',             --36
                   'Storm',
                   'ALL OTHER',               --37
                   'Structure',
                   'PHYSICAL DAMAGE (ALL OTHERS)',        --38
                   'TL',
                   'ALL OTHER',                  --39
                   'Theft',
                   'THEFT/BURGLARY',          --40
                   'UIM',
                   'ALL OTHER',                 --41
                   'UM COLL',
                   'ALL OTHER',             --42
                   'UMBI',
                   'ALL OTHER',                --43
                   'UMPD',
                   'ALL OTHER',                --44
                   'Vandalism, Malicious Mischief',
                   'VANDALISM, MALICIOUS MISCHIEF',--45
                   'Water',
                   'WATER DAMAGE',                   --46
                   'Workers Compensation',
                   'WORKERS'' COMPENSATION',       --47
                   'WC -Indemnity',
                   'WORKERS'' COMPENSATION',               --48 - Niraj - CMS Maint  rel 3.4  TTP#629
                   'WC-Med',
                   'WORKERS'' COMPENSATION',               --49 -  Niraj - CMS Maint  rel 3.4 TTP#629
                   'WC -Liability',
                   'WORKERS'' COMPENSATION',               --50 - Niraj -  CMS Maint  rel 3.4 TTP#629
                   'Electrical Breakdown',
                   'ALL OTHER',               --51 - Niraj -  CMS Maint  rel 3.4 TTP#629
                   'Rupture/Bursting/Explosion/Implosion',
                   'ALL OTHER',               --52 - Niraj -  CMS Maint  rel 3.4 TTP#629
				   'Employment Practices', -- 53
				   'OTHER',
				   'Service Line', -- 54
				   'OTHER',
				   'Riot, Civil Commotion', -- 55
                   'Riot or Civil Commotion',
                   'Home Cyber', -- 56
                   'OTHER',
                   'ID Theft', --57
                   'Identification Thef',
                   '**' || WHOUSE.GET_CAUSE_OF_LOSS(V_EXPOSURE_ID))
        FROM
            DUAL
        WHERE
            'CC' = V_SOURCE_OF_CLAIM;
--r_cause_of_loss2     c_cause_of_loss2%ROWTYPE;

        CURSOR C_CLAIMANT_NAME IS
        SELECT
            INSURED            INS_FLAG,
            UPPER(LAST_NAME)   LNAME,
            UPPER(FIRST_NAME)  FNAME,
            UPPER(MIDDLE_NAME) MNAME,
            BIRTHDATE          DOB,
            UPPER(GENDER)      GENDER,
            'CMS'              AS CLAIM_SOURCE
        FROM
            CLAIMANT
        WHERE
                V_CC_CLAIMANT = CLAIMANT.CLAIMANT
            AND 'CMS' = V_SOURCE_OF_CLAIM
        UNION
        SELECT
            CCTE.CONTACTID        AS INS_FLAG,
            UPPER(CTE.LASTNAME)   AS LNAME,
            UPPER(CTE.FIRSTNAME)  AS FNAME,
            UPPER(CTE.MIDDLENAME) AS MNAME,
            CTE.DATEOFBIRTH       DOB
--, CT.gender
            ,
            UPPER(TLG.TYPECODE)   AS GENDER,
            'CC'                  AS CLAIM_SOURCE
        FROM
                 CCADMIN.CC_CLAIMCONTACT@ECIG_TO_GWCC_PRD_LINK CCTE
            INNER JOIN CCADMIN.CC_CONTACT@ECIG_TO_GWCC_PRD_LINK      CTE ON CTE.ID = CCTE.CONTACTID
                                                                       AND CTE.RETIRED = 0 --AND E.CLAIMANTDENORMID=CTE.ID
            LEFT OUTER JOIN CCADMIN.CCTL_GENDERTYPE@ECIG_TO_GWCC_PRD_LINK TLG ON TLG.ID = CTE.GENDER
        WHERE
                CCTE.ID = V_CC_CLAIMANT
            AND 'CC' = V_SOURCE_OF_CLAIM;

        R_CLAIMANT_NAME               C_CLAIMANT_NAME%ROWTYPE;
        CURSOR C_CLAIMANT_ADDR IS
        SELECT
            ADDR_NBR           STREET_NBR,
            UPPER(STREET_NAME) STREET_NAME,
            UPPER(SUFFIX)      STREET_TYPE,
            UPPER(SUITE)       APT_NBR,
            UPPER(CITY)        CITY,
            UPPER(STATE)       STATE,
            ZIP_CODE,
            'CMS'              AS CLAIM_SOURCE
        FROM
            ADDR
        WHERE
            ( V_CC_CLAIMANT = ADDR.TABLE_KEY
              AND ADDR.TABLE_NAME = 'CLAIMANT' )
            AND 'CMS' = V_SOURCE_OF_CLAIM
        UNION
        SELECT
            NULL                  AS STREET_NBR,
            TRIM(UPPER(TRIM(CA.ADDRESSLINE1
                            || ' '
                            || CA.ADDRESSLINE2
                            || ' '
                            || CA.ADDRESSLINE3))) AS STREET_NAME,
            NULL                  AS STREET_TYPE,
            NULL                  AS APT_NBR,
            UPPER(CA.CITY)        AS CITY,
            TLST.TYPECODE         AS STATE,
            CA.POSTALCODE         AS ZIPCODE,
            'CC'                  AS CLAIM_SOURCE
        FROM
                 CCADMIN.CC_CLAIMCONTACT@ECIG_TO_GWCC_PRD_LINK CCTE
            INNER JOIN CCADMIN.CC_CONTACT@ECIG_TO_GWCC_PRD_LINK CTE ON CTE.ID = CCTE.CONTACTID
                                                                       AND CTE.RETIRED = 0 --AND E.CLAIMANTDENORMID=CTE.ID
            INNER JOIN CCADMIN.CC_ADDRESS@ECIG_TO_GWCC_PRD_LINK CA ON CA.ID = CTE.PRIMARYADDRESSID
            INNER JOIN CCADMIN.CCTL_STATE@ECIG_TO_GWCC_PRD_LINK TLST ON TLST.ID = CA.STATE
        WHERE
                CCTE.ID = V_CC_CLAIMANT
            AND 'CC' = V_SOURCE_OF_CLAIM;

        R_CLAIMANT_ADDR               C_CLAIMANT_ADDR%ROWTYPE;
    BEGIN
        V_MONTH_BEGIN := TO_DATE ( TO_CHAR(V_MONTH)
                                   || '/01/'
                                   || TO_CHAR(V_YEAR), 'MM/DD/YYYY' );

        V_MONTH_END := LAST_DAY(TO_DATE(TO_CHAR(V_MONTH)
                                        || '/01/'
                                        || TO_CHAR(V_YEAR)
                                        || ' 11:59:59 PM', 'MM/DD/YYYY HH:MI:SS PM'));

        DBMS_OUTPUT.PUT_LINE('Starting APLUS Property Extract for:  '
                             || V_MONTH_BEGIN
                             || ' TO '
                             || V_MONTH_END);
        DBMS_OUTPUT.PUT_LINE('Processing Begins:  ' || TO_CHAR(SYSDATE, 'MM/DD/YYYY HH:MI'));
        DBMS_OUTPUT.PUT_LINE('Five Year Flag= ' || V_5YR_FLAG);

--	Don't include claims WHERE the DATE OF loss > 5 yrs PRIOR TO the DATE OF tape creation.
        V_MIN_DOL := ADD_MONTHS(V_MONTH_END, -60);
        V_MONTH_STR := LPAD(TO_CHAR(V_MONTH), 2, '0');
        DBMS_OUTPUT.PUT_LINE('Min DOL: ' || V_MIN_DOL);
	-- Determine what instance we're in.
        BEGIN
            SELECT
                NAME
            INTO V_INSTANCE
            FROM
                CIG_INSTANCE;

        EXCEPTION
            WHEN TOO_MANY_ROWS THEN
                V_INSTANCE := 'bravo';
            WHEN NO_DATA_FOUND THEN
                V_INSTANCE := 'bravo';
            WHEN OTHERS THEN
                V_INSTANCE := 'bravo';
        END;

        V_INSTANCE := LOWER(V_INSTANCE);
        V_LOC := '/db/data/a3/oracle/'
                 || V_INSTANCE
                 || '/interfaces';
        IF V_5YR_FLAG = 'Y' THEN
            V_FILE_NAME := 'APPROP_5YR.'
                           || V_MONTH_STR
                           || V_YEAR;
            V_CLUE_FILE_NAME := 'CLUE_PROP_5YR.'
                                || V_MONTH_STR
                                || V_YEAR;
        ELSE
            V_FILE_NAME := 'APPROP.'
                           || V_MONTH_STR
                           || V_YEAR;
            V_CLUE_FILE_NAME := 'CLUE_PROP.'
                                || V_MONTH_STR
                                || V_YEAR;
        END IF;

        DBMS_OUTPUT.PUT_LINE('Instance: '
                             || V_INSTANCE
                             || ', Filename: '
                             || V_FILE_NAME);
-- Open the file handle
      --  FILE_HANDLE := UTL_FILE.FOPEN(V_LOC, V_FILE_NAME, 'W');
      --  CLUE_FILE_HANDLE := UTL_FILE.FOPEN(V_LOC, V_CLUE_FILE_NAME, 'W');
        DBMS_OUTPUT.PUT_LINE('Opened output file: ' || V_FILE_NAME);
        DBMS_OUTPUT.PUT_LINE('Opened clue output file: ' || V_CLUE_FILE_NAME);

-- Create file header records

--v_create := RPAD(TO_CHAR(SYSDATE,'YYDDDHH24Mi'),9,' ');

        IF V_5YR_FLAG = 'Y' THEN
            OPEN C_MAIN_5YR;
        ELSE
            OPEN C_MAIN;
        END IF;

--DBMS_OUTPUT.PUT_LINE ( ' List of Variables = v_source_of_policy :' || v_source_of_policy || 'v_source_of_claim :' || v_source_of_claim  || ' v_claim:' || v_claim || ' v_claim_nbr:'||v_claim_nbr||' v_policy:' || v_policy || ' v_dec_policy:' ||v_dec_policy ||v_source_of_policy ||' ' || v_source_of_claim|| ': ' || v_claim_nbr || ' - ' || v_policy);
	DBMS_OUTPUT.PUT_LINE('Execution process started... ' || V_MONTH || ',' || V_YEAR );
        LOOP
            BEGIN
                << NEXT_CLAIM >>
--	  Driving cursor
-- PL-6986: Added the source of the policy data to the following two fetches.
                 IF V_5YR_FLAG = 'Y' THEN
                    FETCH C_MAIN_5YR INTO
                        V_CLAIM,
                        V_CLAIM_NBR,
                        V_POLICY,
                        V_DEC_POLICY,
                        V_CC_COVERAGE,
                        V_CC_CLAIMANT,
                        V_SOURCE_OF_POLICY,
                        V_SOURCE_OF_CLAIM,
                        V_EXPOSURE_ID,
                        V_LOSS_PAID;

                    EXIT WHEN C_MAIN_5YR%NOTFOUND;
                ELSE
                    FETCH C_MAIN INTO
                        V_CLAIM,
                        V_CLAIM_NBR,
                        V_POLICY,
                        V_DEC_POLICY,
                        V_CC_COVERAGE,
                        V_CC_CLAIMANT,
                        V_SOURCE_OF_POLICY,
                        V_SOURCE_OF_CLAIM,
                        V_EXPOSURE_ID,
                        V_LOSS_PAID;

                    EXIT WHEN C_MAIN%NOTFOUND;
                END IF;

                V_CNT1 := V_CNT1 + 1;
-- 	dbms_output.put_line('Claim nbr: '||v_claim_nbr||' for dec_policy:'||v_dec_policy);
                IF V_LOSS_PAID < 0 THEN
                    V_LOSS_PAID := V_LOSS_PAID * -1;
                    V_SIGN := '-';
                ELSE
                    V_SIGN := '+';
                END IF;

-- Claim info
                OPEN C_CLAIM;
                FETCH C_CLAIM INTO R_CLAIM;
                IF C_CLAIM%NOTFOUND THEN
                    R_CLAIM := NULL;
                END IF;
                IF R_CLAIM.CAT_NBR IS NOT NULL THEN
                    V_CLAIM_CAT_FLAG := 'Y ';
                ELSE
                    V_CLAIM_CAT_FLAG := '  ';
                END IF;

                IF R_CLAIM.LOSS_CITY = 'CONVERSION' THEN
                    R_CLAIM.LOSS_CITY := NULL;
                END IF;
                CLOSE C_CLAIM;

-- Claim Status
                OPEN C_STATUS;
                FETCH C_STATUS INTO V_OPEN_CT;
                IF C_STATUS%NOTFOUND THEN
                    V_OPEN_CT := 0;
                END IF;
                CLOSE C_STATUS;

	--  IF r_claim.table_name = 'DEC_UMBRELLA_COVERAGE' THEN
	  --    dbms_output.put_line('skipped - umbrella');
	--  	  v_cnt2 := v_cnt2 + 1;
	--      GOTO next_claim;
	--  END IF;

	--  IF r_claim.claim_status = 'Closed' AND v_loss_paid = 0 THEN
	--  	  v_cnt8 := v_cnt8 + 1;
	--      GOTO next_claim;
	--  END IF;

                OPEN C_SUBRO;
                FETCH C_SUBRO INTO R_SUBROGATION;
                IF C_SUBRO%NOTFOUND THEN
                    R_SUBROGATION.SUBROGATION := NULL;
                ELSIF
                    R_SUBROGATION.SUBRO_STATUS = 'Closed'
                    AND NVL(R_SUBROGATION.AMT_COVERED, 0) = 0
                THEN
                    R_SUBROGATION.SUBROGATION := NULL;
                END IF;

                CLOSE C_SUBRO;
                IF R_SUBROGATION.SUBROGATION IS NOT NULL THEN
                    V_CC_STATUS := 'S';
                ELSIF R_CLAIM.CLAIM_STATUS = 'Closed' THEN
                    V_CC_STATUS := 'C';
                ELSE
                    V_CC_STATUS := 'O';
                END IF;

--   Dec_policy for Policyholder address info (mailing address)
-- PL-6986: Broke the c_dp cursor into two separate cursors. The one that will
-- be used will depend on where the policy is (eCig or Policy Center).
                IF
                    V_SOURCE_OF_POLICY = 'eCIG'
                    AND V_SOURCE_OF_CLAIM = 'CMS'
                THEN
       -- DBMS_OUTPUT.PUT_LINE ( ' Assigning to rdp = ' ||v_source_of_policy ||' ' || v_source_of_claim|| ': ' || v_claim_nbr || ' - ' || v_policy);

                    OPEN C_DP;
                    FETCH C_DP INTO R_DP;
                    IF C_DP%NOTFOUND THEN
            --  DBMS_OUTPUT.PUT_LINE ( 'c_dp NOTFOUND ' || v_source_of_policy ||'-' || v_source_of_claim || ' r_dp = ' || r_dp.business_name ||' ' || r_dp.insured_addr_nbr|| ': ' || r_dp.insured_addr_street_name || ' - ' || r_dp.insured_addr_city);

                        R_DP := NULL;
                    END IF;
                    CLOSE C_DP;
                ELSIF
                    V_SOURCE_OF_POLICY = 'PolicyCenter'
                    AND V_SOURCE_OF_CLAIM = 'CMS'
                THEN
        --DBMS_OUTPUT.PUT_LINE (  ' Assigning to rdp = '|| v_source_of_policy ||' ' || v_source_of_claim|| ': ' || v_claim_nbr || ' - ' || v_policy);

                    OPEN C_DP_PC;
                    FETCH C_DP_PC INTO R_DP;
                    IF C_DP_PC%NOTFOUND THEN
         -- DBMS_OUTPUT.PUT_LINE ( 'c_dp_pc NOTFOUND ' || v_source_of_policy ||'-' || v_source_of_claim || ' r_dp = ' || r_dp.business_name ||' ' || r_dp.insured_addr_nbr|| ': ' || r_dp.insured_addr_street_name || ' - ' || r_dp.insured_addr_city);

                        R_DP := NULL;
                    END IF;
                    CLOSE C_DP_PC;
                ELSE -- All ClaimCenter data
        --DBMS_OUTPUT.PUT_LINE ( ' Assigning to rdp = ' || v_source_of_policy ||' ' || v_source_of_claim|| ': ' || v_claim_nbr || ' - ' || v_policy);

                    OPEN C_DP_CC_POLICIES;
                    FETCH C_DP_CC_POLICIES INTO R_DP;
                    IF C_DP_CC_POLICIES%NOTFOUND THEN
             -- DBMS_OUTPUT.PUT_LINE ( 'c_dp_CC_policies NOTFOUND ' || v_source_of_policy ||'-' || v_source_of_claim || ' r_dp = ' || r_dp.business_name ||' ' || r_dp.insured_addr_nbr|| ': ' || r_dp.insured_addr_street_name || ' - ' || r_dp.insured_addr_city);

                        R_DP := NULL;
                    END IF;
                    CLOSE C_DP_CC_POLICIES;
                END IF;

                IF R_DP.WRITING_COMPANY = 'California Capital Insurance Company' THEN
                    V_AM_BEST := '003136';
                ELSIF R_DP.WRITING_COMPANY = 'Eagle West Insurance Company' THEN
                    V_AM_BEST := '003125';
                ELSIF R_DP.WRITING_COMPANY = 'Monterey Insurance Company' THEN
                    V_AM_BEST := '010603';
                ELSIF R_DP.WRITING_COMPANY = 'Nevada Capital Insurance Company' THEN
                    V_AM_BEST := '012493';     --from AM Best via Mike Ferguson / Verified
                ELSE
--       DBMS_OUTPUT.PUT_LINE ( 'r_dp.writing_company NOT FOUND ' || r_dp.writing_company );
--        DBMS_OUTPUT.PUT_LINE ( ' r_dp.writing_company NOT FOUND Variables = v_claim:' || v_claim || ' v_claim_nbr:'||v_claim_nbr||' v_policy:' || v_policy || ' v_dec_policy:' ||v_dec_policy ||v_source_of_policy ||' ' || v_source_of_claim|| ': ' || v_claim_nbr || ' - ' || v_policy);

                    V_AM_BEST := '999999';
                END IF;

                IF R_DP.INSURED_ADDR_STREET_NAME IS NULL THEN
                    R_DP.INSURED_ADDR_STREET_NAME := R_DP.INSURED_ADDR_PO_BOX;
                END IF;

-----------------------------------------------------------------
--	  Policyholder info for 2 insureds
                OPEN C_POLICYHOLDER;
                FETCH C_POLICYHOLDER INTO R_POLICYHOLDER1;
                IF C_POLICYHOLDER%NOTFOUND THEN
                    R_POLICYHOLDER1 := NULL;
                END IF;
                IF R_POLICYHOLDER1.DOB IS NOT NULL THEN
                    V_POLICYHOLDER1_DOB := TO_CHAR(R_POLICYHOLDER1.DOB, 'YYYYMMDD');
                ELSE
                    V_POLICYHOLDER1_DOB := 00000000;
                END IF;

                IF R_POLICYHOLDER1.NAMED_INSURED IS NOT NULL THEN
                    V_POLICYHOLDER1_NAMED_INSURED := R_POLICYHOLDER1.NAMED_INSURED;
                ELSE
                    V_POLICYHOLDER1_NAMED_INSURED := 00000000;
                END IF;

                FETCH C_POLICYHOLDER INTO R_POLICYHOLDER2;
                IF C_POLICYHOLDER%NOTFOUND THEN
                    R_POLICYHOLDER2 := NULL;
                END IF;
                IF R_POLICYHOLDER2.DOB IS NOT NULL THEN
                    V_POLICYHOLDER2_DOB := TO_CHAR(R_POLICYHOLDER2.DOB, 'YYYYMMDD');
                ELSE
                    V_POLICYHOLDER2_DOB := 00000000;
                END IF;

                CLOSE C_POLICYHOLDER;

-----------------------------------------------------------------

--Get 'Doing Business AS' & Tax id (insured_business.doing_business_as)
    --IF v_dp_business_line = 'Homeowner' THEN
                IF ( ( R_DP.V_DP_BUSINESS_LINE = 'Homeowner' OR R_DP.V_DP_BUSINESS_LINE = 'Dwelling Fire' ) ) THEN
                    V_RECORD_TYPE := 'I';
                    R_DBA := NULL;
                    R_DP.BUSINESS_NAME := NULL;
                ELSE
                    V_RECORD_TYPE := 'B';
                    OPEN C_DBA;
                    FETCH C_DBA INTO R_DBA;
         --   DBMS_OUTPUT.PUT_LINE ( 'r_dba ' || v_source_of_policy ||'-' || v_source_of_claim || ' r_dba = ' || r_dba.doing_business_as);

                    IF C_DBA%NOTFOUND THEN
                        R_DBA := NULL;
                    END IF;
                    CLOSE C_DBA;
                END IF;

--Get Mortgagee & Loan Number (dec_addl_interest)
                OPEN C_DAI;
                FETCH C_DAI INTO R_DAI;
                IF C_DAI%NOTFOUND THEN
                    R_DAI := NULL;
                END IF;
                CLOSE C_DAI;

--Dept number to "policy type"
                OPEN C_DEPT;
                FETCH C_DEPT INTO R_DEPT;
                IF C_DEPT%NOTFOUND THEN
                    R_DEPT := NULL;
                END IF;
                CLOSE C_DEPT;
                IF R_DEPT.DEPT_NBR = 10 THEN        --10 Dwelling
                    V_POLICY_TYPE := 'FIRE';
                ELSIF R_DEPT.DEPT_NBR = 15 THEN    --15 Homeowners
                    V_POLICY_TYPE := 'HO';
                ELSIF R_DEPT.DEPT_NBR = 20 THEN    --20 Commercial Fire
                    V_POLICY_TYPE := 'FIRE';
                ELSIF R_DEPT.DEPT_NBR = 21 THEN    --21 Apt. Pack
                    V_POLICY_TYPE := 'W';
                ELSIF R_DEPT.DEPT_NBR = 22 THEN    --22 Contents Package
                    V_POLICY_TYPE := 'X';
                ELSIF R_DEPT.DEPT_NBR = 23 THEN    --23 Retail
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 24 THEN    --24 Commercial Multi Peril
                    V_POLICY_TYPE := 'CMP';
                ELSIF R_DEPT.DEPT_NBR = 25 THEN    --25 Motel
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 26 THEN    --26 Church
                    V_POLICY_TYPE := 'Y';
                ELSIF R_DEPT.DEPT_NBR = 27 THEN    --27 Office
                    V_POLICY_TYPE := 'U';
                ELSIF R_DEPT.DEPT_NBR = 28 THEN    --28 Day Care
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 29 THEN    --29 Wineries
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 30 THEN    --30 Farm Fire
                    V_POLICY_TYPE := 'FIRE';
                ELSIF R_DEPT.DEPT_NBR = 31 THEN    --31 Farm Fire
                    V_POLICY_TYPE := 'FIRE';
                ELSIF R_DEPT.DEPT_NBR = 32 THEN    --32 Farm Owners
                    V_POLICY_TYPE := 'HO';
                ELSIF R_DEPT.DEPT_NBR = 33 THEN    --33 Farm Lines
                    V_POLICY_TYPE := 'FARM';
                ELSIF R_DEPT.DEPT_NBR = 37 THEN    --37 Farm Umbrella
                    V_POLICY_TYPE := 'J';
                ELSIF R_DEPT.DEPT_NBR = 38 THEN    --38 Farm Auto
                    V_POLICY_TYPE := 'NRPT';
                ELSIF R_DEPT.DEPT_NBR = 40 THEN    --40 Personal Auto
--      v_policy_type := 'AUTO';
                    V_POLICY_TYPE := 'NRPT';
                ELSIF R_DEPT.DEPT_NBR = 41 THEN    --41 Assigned Risk
                    V_POLICY_TYPE := 'NRPT';
                ELSIF R_DEPT.DEPT_NBR = 50 THEN    --50 Excess Liability
                    V_POLICY_TYPE := 'X';
                ELSIF R_DEPT.DEPT_NBR = 52 THEN    --52 Commercial Excess Liability
                    V_POLICY_TYPE := 'X';
                ELSIF R_DEPT.DEPT_NBR = 60 THEN    --60 Commercial C.O.C.
                    V_POLICY_TYPE := 'FIRE';
                ELSIF R_DEPT.DEPT_NBR = 61 THEN    --61 Office Contents
                    V_POLICY_TYPE := 'U';
                ELSIF R_DEPT.DEPT_NBR = 62 THEN    --62 Restaurant
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 63 THEN    --63 Bakery/Cafe
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 64 THEN    --64 Senior Residence
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 65 THEN    --65 Print Shop
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 66 THEN    --66 Dry Clean
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 67 THEN    --67 Veterinarians
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 68 THEN    --68 Funeral
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 69 THEN    --69 Municipal
                    V_POLICY_TYPE := 'X';
                ELSIF R_DEPT.DEPT_NBR = 70 THEN    --70 Photo Processing
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 71 THEN    --71 Commercial Auto
                    V_POLICY_TYPE := 'NRPT';
                ELSIF R_DEPT.DEPT_NBR = 73 THEN    --73 Basic Lawn Care
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 74 THEN    --74 Mobilehome Park
                    V_POLICY_TYPE := 'X';
                ELSIF R_DEPT.DEPT_NBR = 80 THEN    --80 SA/Package & Monoline
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 81 THEN    --81 SA/Business Owner
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 82 THEN    --82 SA/Apartment
                    V_POLICY_TYPE := 'W';
                ELSIF R_DEPT.DEPT_NBR = 83 THEN    --83 SA/Commercial Umbrella
                    V_POLICY_TYPE := 'J';
                ELSIF R_DEPT.DEPT_NBR = 84 THEN    --84 SA/Commercial Auto
                    V_POLICY_TYPE := 'NRPT';
                ELSIF R_DEPT.DEPT_NBR = 85 THEN    --85 SA/Garage
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 89 THEN    --89 SA/US Entry
                    V_POLICY_TYPE := 'X';
                ELSIF R_DEPT.DEPT_NBR = 90 THEN    --90 Warranty
                    V_POLICY_TYPE := 'X';
                ELSIF R_DEPT.DEPT_NBR = 101 THEN   --101 SA/Janitorial
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 102 THEN   --102 SA/Household Appliance Installation
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 103 THEN   --103 SA/TV, Satellite & Telephone Installation
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 104 THEN   --104 SA/Carpet & Furniture Cleaning
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 105 THEN   --105 SA/Fence Erection Contractors
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 106 THEN   --106 SA/Floor Covering Installation
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 107 THEN   --107 SA/Home Furniture Installation
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 108 THEN   --108 SA/Office Furniture Installation
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 109 THEN   --109 SA/Office Machine Installation
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 110 THEN   --110 SA/Piano Tuning
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 111 THEN   --111 SA/Sign Painting
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 112 THEN   --112 SA/Swimming Pool Service
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 113 THEN   --113 SA/Assisted Living
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 210 THEN   --210 Fire CPF
                    V_POLICY_TYPE := 'FIRE';
                ELSIF R_DEPT.DEPT_NBR = 215 THEN   --215 Home CPF
                    V_POLICY_TYPE := 'HO';
                ELSIF R_DEPT.DEPT_NBR = 240 THEN   --240 Personal Auto CPF
                    V_POLICY_TYPE := 'NRPT';
    --Begin code changes for Maintenance and Requests TTP Issue 1694.
                ELSIF R_DEPT.DEPT_NBR = 114 THEN   --114 SA/Wineries
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 115 THEN   --115 Golf Courses
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 116 THEN   --116 Self Storage
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 117 THEN   --117 SA/Motels
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 118 THEN   --118 SA/Restaurants
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 119 THEN   --119 SA/Limousines
                    V_POLICY_TYPE := 'NRPT';
                ELSIF R_DEPT.DEPT_NBR = 120 THEN   --120 Wineries
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 121 THEN   --121 Nurseries
                    V_POLICY_TYPE := 'Z';
                ELSIF R_DEPT.DEPT_NBR = 122 THEN   --122 Residential Condos
                    V_POLICY_TYPE := 'V';
                ELSIF R_DEPT.DEPT_NBR = 123 THEN   --123 SA/Residential Condos
                    V_POLICY_TYPE := 'V';
                ELSIF R_DEPT.DEPT_NBR = 124 THEN   --124 SA/Entertainment Equipment
                    V_POLICY_TYPE := 'N';
                ELSIF R_DEPT.DEPT_NBR = 125 THEN   --125 Ag Related
                    V_POLICY_TYPE := 'FARM';
                ELSIF R_DEPT.DEPT_NBR = 126 THEN   --126 SA/Card Room Casinos
                    V_POLICY_TYPE := 'N';
				ELSIF R_DEPT.DEPT_NBR = 127 THEN   --127 Agricultural Output
                    V_POLICY_TYPE := 'X';
				ELSIF R_DEPT.DEPT_NBR = 130 THEN   --130 Captial Assets
                    V_POLICY_TYPE := 'X';
    --End code changes for Maintenance and Requests TTP Issue 1694.
                ELSE
      --v_policy_type := 'NRPT';
                    V_POLICY_TYPE := '*' || R_DEPT.DEPT_NBR;
                END IF;

--Cause of loss name to "claim type"
                OPEN C_CAUSE_OF_LOSS1;
                FETCH C_CAUSE_OF_LOSS1 INTO V_CLAIM_TYPE;
                IF C_CAUSE_OF_LOSS1%NOTFOUND THEN
                    V_CLAIM_TYPE := NULL;
                END IF;
                CLOSE C_CAUSE_OF_LOSS1;

--Cause of loss name to "claim desc"
                OPEN C_CAUSE_OF_LOSS2;
                FETCH C_CAUSE_OF_LOSS2 INTO V_CAUSE_DESC;
                IF C_CAUSE_OF_LOSS2%NOTFOUND THEN
                    V_CAUSE_DESC := NULL;
                END IF;
                CLOSE C_CAUSE_OF_LOSS2;

--Claimant info
                OPEN C_CLAIMANT_NAME;
                FETCH C_CLAIMANT_NAME INTO R_CLAIMANT_NAME;
                IF C_CLAIMANT_NAME%NOTFOUND THEN
                    R_CLAIMANT_NAME := NULL;
                END IF;
                IF R_CLAIMANT_NAME.DOB IS NOT NULL THEN
                    V_CLAIMANT_DOB := TO_CHAR(R_CLAIMANT_NAME.DOB, 'YYYYMMDD');
                ELSE
                    V_CLAIMANT_DOB := 00000000;
                END IF;

                CLOSE C_CLAIMANT_NAME;
                OPEN C_CLAIMANT_ADDR;
                FETCH C_CLAIMANT_ADDR INTO R_CLAIMANT_ADDR;
                IF C_CLAIMANT_ADDR%NOTFOUND THEN
                    R_CLAIMANT_ADDR := NULL;
                END IF;
                CLOSE C_CLAIMANT_ADDR;

    -- The following clmt zip_code conditions, spaces or 'unknown',
    -- made the whole record fail to be submitted.
    -- Encountered one or two errors every run month.
                IF R_CLAIMANT_ADDR.ZIP_CODE = ' ' THEN
                    R_CLAIMANT_ADDR.ZIP_CODE := NULL;
                ELSIF UPPER(R_CLAIMANT_ADDR.ZIP_CODE) LIKE 'U%' THEN
                    R_CLAIMANT_ADDR.ZIP_CODE := NULL;
                END IF;

   -- DBMS_OUTPUT.PUT_LINE ( ' BEFORE INSERTING Assigning to rdp = ' || r_dba.doing_business_as||' - ' ||v_source_of_policy ||' ' || v_source_of_claim|| ': ' || v_claim_nbr || ' - ' || v_policy);
  --  DBMS_OUTPUT.PUT_LINE ( ' BEFORE INSERTING r_policyholder1 = ' || r_policyholder1.first_name||' - ' ||r_policyholder1.last_name ||' ' || r_policyholder1.middle_name|| ': ' || v_claim_nbr || ' - ' || v_policy);

-- Create the APLUS output record.
-----------------------------------------------------------------
--START APLUS RECORD
                FILE_OUT :=
		        --'I' ||                                              --01 byte  001-001
                 RPAD(NVL(V_RECORD_TYPE, ' '), 01)
                            ||                 --01 bytes 001-001
                             RPAD(NVL(R_DP.BUSINESS_NAME, ' '), 40)
                            ||            --40 bytes 002-041
                             RPAD(NVL(R_DBA.DOING_BUSINESS_AS, ' '), 40)
                            ||       --40 bytes 042-081
                             RPAD(NVL(REPLACE(R_DBA.TAX_ID, '-', ''), 0), 9, '0')
                            ||--9bytes 165-173
--  First Insured info:
                             RPAD(NVL(R_POLICYHOLDER1.LAST_NAME, ' '), 24)
                            ||     --24 bytes 091-114
                             RPAD(NVL(R_POLICYHOLDER1.FIRST_NAME, ' '), 12)
                            ||    --12 bytes 115-126
                             RPAD(NVL(R_POLICYHOLDER1.MIDDLE_NAME, ' '), 01)
                            ||   --01 byte  127-127
                             RPAD(' ', 37, ' ')
                            ||--filler(s.b. ins1 a.k.a.       --37 bytes 128-164
                             RPAD(NVL(REPLACE(R_POLICYHOLDER1.SSN, '-', ''), 0), 9, '0')
                            ||--165-173
                             RPAD(V_POLICYHOLDER1_DOB, 8, 0)
                            ||                  --08 bytes 174-181
                             RPAD(NVL(REPLACE(R_POLICYHOLDER1.GENDER, 'U', ' '), ' '), 1)
                            ||  --182-182
--  Second Insured info:
                             RPAD(NVL(R_POLICYHOLDER2.LAST_NAME, ' '), 24)
                            ||     --24 bytes 183-206
                             RPAD(NVL(R_POLICYHOLDER2.FIRST_NAME, ' '), 12)
                            ||    --12 bytes 207-218
                             RPAD(NVL(R_POLICYHOLDER2.MIDDLE_NAME, ' '), 01)
                            ||   --01 byte  219-219
                             RPAD(' ', 37, ' ')
                            ||--filler(s.b. ins2 a.k.a.       --37 bytes 220-256
                             RPAD(NVL(REPLACE(R_POLICYHOLDER2.SSN, '-', ''), '0'), 9, '0')
                            ||--257-265
                             RPAD(V_POLICYHOLDER2_DOB, 8, 0)
                            ||                  --08 bytes 266-273
                             RPAD(NVL(REPLACE(R_POLICYHOLDER2.GENDER, 'U', ' '), ' '), 1)
                            ||  --274-274
                             RPAD(' ', 07, ' ')
                            ||--filler                        --07 bytes 275-281
                             RPAD(NVL(R_CLAIM.LOSS_LOCATION, ' '), 20)
                            ||         --20 bytes 282-301
                             RPAD(' ', 08, ' ')
                            ||--filler                        --08 bytes 302-309
                             RPAD(NVL(R_CLAIM.LOSS_CITY, ' '), 20)
                            ||             --20 bytes 310-329
                             RPAD(NVL(R_CLAIM.LOSS_STATE, ' '), 02)
                            ||            --02 bytes 330-331
                --07/10/13:Umesh-TTP 779- Retrive the ZipCode from Claim record
                             RPAD(NVL(R_CLAIM.LOSS_ZIPCODE, 0), 9, 0)
                            ||  --filler (s.b. loss location zip)   --09 bytes 332-340
                             RPAD(NVL(R_DP.INSURED_ADDR_NBR, ' '), 7)
                            ||          --07 bytes 341-347
                             RPAD(NVL(R_DP.INSURED_ADDR_STREET_NAME, ' '), 20)
                            || --20 bytes 348-367
                             RPAD(NVL(R_DP.INSURED_ADDR_STREET_TYPE, ' '), 3)
                            ||  --03 bytes 368-370
                             RPAD(NVL(R_DP.INSURED_ADDR_APT_NBR, ' '), 5)
                            ||      --05 bytes 371-375
                             RPAD(NVL(R_DP.INSURED_ADDR_CITY, ' '), 20)
                            ||        --20 bytes 376-395
                             RPAD(NVL(R_DP.INSURED_ADDR_STATE, ' '), 2)
                            ||        --02 bytes 396-397
                             RPAD(NVL(REPLACE(R_DP.INSURED_ADDR_ZIPCODE, '-', ''), 0), 9, 0)
                            ||--398-406
                             RPAD(NVL(R_DAI.FINANCE_CO, ' '), 40)
                            ||              --40 bytes 407-446
                             RPAD(NVL(R_DAI.LOAN_NBR, ' '), 16)
                            ||                --16 bytes 447-462
                             RPAD(NVL(V_POLICY_TYPE, ' '), 04)
                            ||                 --04 bytes 463-466
                             RPAD(NVL(R_DP.POLICY_SEARCH_NBR, ' '), 16)
                            ||        --16 bytes 467-482
              --331000000000||     --confirmed aplus account number              --483-494
                             LPAD(TO_NUMBER(V_ISO_APLUS_ACCOUNT_NBR, '999999999999'), 12, '0')
                            ||--483-494
                             RPAD(TO_CHAR(NVL(R_CLAIM.DATE_OF_LOSS, SYSDATE), 'YYYYMMDD'), 8, ' ')
                            || SUBSTR(LTRIM(TO_CHAR(NVL(V_LOSS_PAID, 0) * 100, '09999999999')), 1, 11)
                            ||--08 bytes 503-510
                             RPAD(NVL(V_CLAIM_TYPE, ' '), 11)
                            ||            --NOTE : 11 bytes 514-524 Loss Type Code AS PER APLUS Property Casuality reporting specification document
                             RPAD(V_CLAIM_NBR, 18)
                            ||                             --18 bytes 525-542
                             RPAD(V_CLAIM_CAT_FLAG, 2, ' ')
                            ||                     --02 bytes 543-544
                             RPAD(NVL(V_CAUSE_DESC, ' '), 45)
                            ||                  --45 bytes 545-589
--  Claimant info:
                             RPAD(NVL(R_CLAIMANT_NAME.LNAME, ' '), 24)
                            ||         --24 bytes 590-613
                             RPAD(NVL(R_CLAIMANT_NAME.FNAME, ' '), 12)
                            ||         --12 bytes 614-625
                             RPAD(NVL(R_CLAIMANT_NAME.MNAME, ' '), 1)
                            ||          --01 byte  626-626
                             RPAD(NVL(R_CLAIMANT_ADDR.STREET_NBR, ' '), 7)
                            ||     --07 bytes 627-633
                             RPAD(NVL(R_CLAIMANT_ADDR.STREET_NAME, ' '), 20)
                            ||   --20 bytes 634-653
                             RPAD(NVL(R_CLAIMANT_ADDR.STREET_TYPE, ' '), 3)
                            ||    --03 bytes 654-656
                             RPAD(NVL(R_CLAIMANT_ADDR.APT_NBR, ' '), 5)
                            ||        --05 bytes 657-661
                             RPAD(NVL(R_CLAIMANT_ADDR.CITY, ' '), 20)
                            ||          --20 bytes 662-681
                             RPAD(NVL(R_CLAIMANT_ADDR.STATE, ' '), 2)
                            ||          --02 bytes 682-683
                             RPAD(NVL(REPLACE(R_CLAIMANT_ADDR.ZIP_CODE, '-', ''), '0'), 9, '0')
                            ||    --684-692
                             RPAD(0, 9, 0)
                            ||      --filler (s.b. clmt ssn)        --09 bytes 693-701
                             RPAD(V_CLAIMANT_DOB, 8, 0)
                            ||                       --08 bytes 702-709
                             RPAD(NVL(REPLACE(R_CLAIMANT_NAME.GENDER, 'U', ' '), ' '), 1)
                            ||      --710-710
                             RPAD(' ', 12, ' ')
                            ||--filler(s.b.Orig clms office)  --12 bytes 711-722
                             RPAD(V_CC_STATUS, 1)
                            ||                             --01 byte  723-723
                             V_SIGN
                            ||   -- ('A'/+/- Reporting update flag)      --01 byte  724-724
                             RPAD(NVL(V_AM_BEST, ' '), 6)
                            ||                      --06 bytes 725-730
                             RPAD(' ', 85, ' ');   --EOR filler (End of Record)     --85 bytes 731-815

                --FILE_OUT := FN_REPLACE_UNPRINTABLE(FILE_OUT);
               -- UTL_FILE.PUT_LINE(FILE_HANDLE, FILE_OUT);
                V_CNT7 := V_CNT7 + 1;
                IF V_SIGN = '-' THEN
                    V_LOSS_AMOUNT_SUBMITTED := ( V_LOSS_AMOUNT_SUBMITTED - V_LOSS_PAID );
                ELSE
                    V_LOSS_AMOUNT_SUBMITTED := ( V_LOSS_AMOUNT_SUBMITTED + V_LOSS_PAID );
                END IF;

                DBMS_OUTPUT.PUT_LINE('Inserting APLUS RECORD FOR v_claim_nbr= ' || V_CLAIM_NBR || V_POLICY_TYPE || R_DP.POLICY_SEARCH_NBR);
                INSERT INTO CIGADMIN.DOWNSTREAM_INTEGRATION (
                    DOWNSTREAM_INTEGRATION,
                    DOWNSTREAM_JOB,
                    SOURCE_TYPE,
                    CLAIM_NUMBER,
                    INPUT_RECORD,
                    MONTH,
                    YEAR,
                    FIRST_MODIFIED,
                    LAST_MODIFIED,
                    CREATE_ID,
                    AUDIT_ID
                ) VALUES (
                    CIGADMIN.SEQ_DOWNSTREAM_INTEGRATION.NEXTVAL,
                    V_FILE_NAME,
                    V_SOURCE_OF_CLAIM
                    || ' '
                    || V_SOURCE_OF_POLICY,
                    V_CLAIM_NBR,
                    FILE_OUT,
                    V_MONTH,
                    V_YEAR,
                    SYSDATE,
                    SYSDATE,
                    USER,
                    USER
                );

	-- Create the CLUE output record.
	-----------------------------------------------------------------
                CLUE_FILE_OUT :=
		        --'I' ||                                              --01 byte  001-001
                 RPAD(NVL(V_RECORD_TYPE, ' '), 01)
                                 ||                 --01 bytes 001-001
                                  RPAD(NVL(R_DP.BUSINESS_NAME, ' '), 40)
                                 ||            --40 bytes 002-041
                                  RPAD(NVL(R_DBA.DOING_BUSINESS_AS, ' '), 40)
                                 ||       --40 bytes 042-081
                                  RPAD(NVL(REPLACE(R_DBA.TAX_ID, '-', ''), 0), 9, '0')
                                 ||--9bytes 165-173
		--  First Insured info:
                                  RPAD(NVL(R_POLICYHOLDER1.LAST_NAME, ' '), 24)
                                 ||     --24 bytes 091-114
                                  RPAD(NVL(R_POLICYHOLDER1.FIRST_NAME, ' '), 12)
                                 ||    --12 bytes 115-126
                                  RPAD(NVL(R_POLICYHOLDER1.MIDDLE_NAME, ' '), 01)
                                 ||   --01 byte  127-127
                                  RPAD(' ', 37, ' ')
                                 ||--filler(s.b. ins1 a.k.a.       --37 bytes 128-164
                                  RPAD(NVL(REPLACE(R_POLICYHOLDER1.SSN, '-', ''), 0), 9, '0')
                                 ||--165-173
                                  RPAD(V_POLICYHOLDER1_DOB, 8, 0)
                                 ||                  --08 bytes 174-181
                                  RPAD(NVL(REPLACE(R_POLICYHOLDER1.GENDER, 'U', ' '), ' '), 1)
                                 ||  --182-182
		--  Second Insured info:
                                  RPAD(NVL(R_POLICYHOLDER2.LAST_NAME, ' '), 24)
                                 ||     --24 bytes 183-206
                                  RPAD(NVL(R_POLICYHOLDER2.FIRST_NAME, ' '), 12)
                                 ||    --12 bytes 207-218
                                  RPAD(NVL(R_POLICYHOLDER2.MIDDLE_NAME, ' '), 01)
                                 ||   --01 byte  219-219
                                  RPAD(' ', 37, ' ')
                                 ||--filler(s.b. ins2 a.k.a.       --37 bytes 220-256
                                  RPAD(NVL(REPLACE(R_POLICYHOLDER2.SSN, '-', ''), '0'), 9, '0')
                                 ||--257-265
                                  RPAD(V_POLICYHOLDER2_DOB, 8, 0)
                                 ||                  --08 bytes 266-273
                                  RPAD(NVL(REPLACE(R_POLICYHOLDER2.GENDER, 'U', ' '), ' '), 1)
                                 ||  --274-274
                                  RPAD(' ', 07, ' ')
                                 ||--filler                        --07 bytes 275-281
                                  RPAD(NVL(R_CLAIM.LOSS_LOCATION, ' '), 20)
                                 ||         --20 bytes 282-301
                                  RPAD(' ', 08, ' ')
                                 ||--filler                        --08 bytes 302-309
                                  RPAD(NVL(R_CLAIM.LOSS_CITY, ' '), 20)
                                 ||             --20 bytes 310-329
                                  RPAD(NVL(R_CLAIM.LOSS_STATE, ' '), 02)
                                 ||            --02 bytes 330-331
                --07/10/13:Umesh-TTP 779- Retrive the ZipCode from Claim record.
                                  RPAD(NVL(R_CLAIM.LOSS_ZIPCODE, 0), 9, 0)
                                 ||  --filler (s.b. loss location zip)   --09 bytes 332-340
                                  RPAD(NVL(R_DP.INSURED_ADDR_NBR, ' '), 7)
                                 ||          --07 bytes 341-347
                                  RPAD(NVL(R_DP.INSURED_ADDR_STREET_NAME, ' '), 20)
                                 || --20 bytes 348-367
                                  RPAD(NVL(R_DP.INSURED_ADDR_STREET_TYPE, ' '), 3)
                                 ||  --03 bytes 368-370
                                  RPAD(NVL(R_DP.INSURED_ADDR_APT_NBR, ' '), 5)
                                 ||      --05 bytes 371-375
                                  RPAD(NVL(R_DP.INSURED_ADDR_CITY, ' '), 20)
                                 ||        --20 bytes 376-395
                                  RPAD(NVL(R_DP.INSURED_ADDR_STATE, ' '), 2)
                                 ||        --02 bytes 396-397
                                  RPAD(NVL(REPLACE(R_DP.INSURED_ADDR_ZIPCODE, '-', ''), 0), 9, 0)
                                 ||--398-406
                                  RPAD(NVL(R_DAI.FINANCE_CO, ' '), 40)
                                 ||              --40 bytes 407-446
                                  RPAD(NVL(R_DAI.LOAN_NBR, ' '), 16)
                                 ||                --16 bytes 447-462
                                  RPAD(NVL(V_POLICY_TYPE, ' '), 04)
                                 ||                 --04 bytes 463-466
                                  RPAD(NVL(R_DP.POLICY_SEARCH_NBR, ' '), 16)
                                 ||        --16 bytes 467-482
              --  For CLUE send spaces instead of APLUS account number --483-494
                                  RPAD(' ', 12, ' ')
                                 ||												--483-494
                                  RPAD(TO_CHAR(NVL(R_CLAIM.DATE_OF_LOSS, SYSDATE), 'YYYYMMDD'), 8, ' ')
                                 || SUBSTR(LTRIM(TO_CHAR(NVL(V_LOSS_PAID, 0) * 100, '09999999')), 1, 8)
                                 ||--08 bytes 503-510
                                  RPAD(NVL(V_CLAIM_TYPE, ' '), 14)
                                 || RPAD(V_CLAIM_NBR, 18)
                                 ||                             --18 bytes 525-542
                                  RPAD(V_CLAIM_CAT_FLAG, 2, ' ')
                                 ||                     --02 bytes 543-544
                                  RPAD(NVL(V_CAUSE_DESC, ' '), 45)
                                 ||                  --45 bytes 545-589
		--  Claimant info:
                                  RPAD(NVL(R_CLAIMANT_NAME.LNAME, ' '), 24)
                                 ||         --24 bytes 590-613
                                  RPAD(NVL(R_CLAIMANT_NAME.FNAME, ' '), 12)
                                 ||         --12 bytes 614-625
                                  RPAD(NVL(R_CLAIMANT_NAME.MNAME, ' '), 1)
                                 ||          --01 byte  626-626
                                  RPAD(NVL(R_CLAIMANT_ADDR.STREET_NBR, ' '), 7)
                                 ||     --07 bytes 627-633
                                  RPAD(NVL(R_CLAIMANT_ADDR.STREET_NAME, ' '), 20)
                                 ||   --20 bytes 634-653
                                  RPAD(NVL(R_CLAIMANT_ADDR.STREET_TYPE, ' '), 3)
                                 ||    --03 bytes 654-656
                                  RPAD(NVL(R_CLAIMANT_ADDR.APT_NBR, ' '), 5)
                                 ||        --05 bytes 657-661
                                  RPAD(NVL(R_CLAIMANT_ADDR.CITY, ' '), 20)
                                 ||          --20 bytes 662-681
                                  RPAD(NVL(R_CLAIMANT_ADDR.STATE, ' '), 2)
                                 ||          --02 bytes 682-683
                                  RPAD(NVL(REPLACE(R_CLAIMANT_ADDR.ZIP_CODE, '-', ''), '0'), 9, '0')
                                 ||    --684-692
                                  RPAD(0, 9, 0)
                                 ||      --filler (s.b. clmt ssn)        --09 bytes 693-701
                                  RPAD(V_CLAIMANT_DOB, 8, 0)
                                 ||                       --08 bytes 702-709
                                  RPAD(NVL(REPLACE(R_CLAIMANT_NAME.GENDER, 'U', ' '), ' '), 1)
                                 ||      --710-710
                                  RPAD(' ', 12, ' ')
                                 ||--filler(s.b.Orig clms office)  --12 bytes 711-722
                                  RPAD(V_CC_STATUS, 1)
                                 ||                             --01 byte  723-723
                                  V_SIGN
                                 ||   -- ('A'/+/- Reporting update flag)      --01 byte  724-724
                                  RPAD(NVL(V_AM_BEST, ' '), 6)
                                 ||                      --06 bytes 725-730
                                  RPAD(' ', 85, ' ');   --EOR filler (End of Record)     --85 bytes 731-815

              --  CLUE_FILE_OUT := FN_REPLACE_UNPRINTABLE(CLUE_FILE_OUT);
               -- UTL_FILE.PUT_LINE(CLUE_FILE_HANDLE, CLUE_FILE_OUT);
                DBMS_OUTPUT.PUT_LINE('Inserting CLUE RECORD FOR v_claim_nbr= ' || V_CLAIM_NBR || V_POLICY_TYPE);
                INSERT INTO CIGADMIN.DOWNSTREAM_INTEGRATION (
                    DOWNSTREAM_INTEGRATION,
                    DOWNSTREAM_JOB,
                    SOURCE_TYPE,
                    CLAIM_NUMBER,
                    INPUT_RECORD,
                    MONTH,
                    YEAR,
                    FIRST_MODIFIED,
                    LAST_MODIFIED,
                    CREATE_ID,
                    AUDIT_ID
                ) VALUES (
                    CIGADMIN.SEQ_DOWNSTREAM_INTEGRATION.NEXTVAL,
                    V_CLUE_FILE_NAME,
                    V_SOURCE_OF_CLAIM
                    || ' '
                    || V_SOURCE_OF_POLICY,
                    V_CLAIM_NBR,
                    FILE_OUT,
                    V_MONTH,
                    V_YEAR,
                    SYSDATE,
                    SYSDATE,
                    USER,
                    USER
                );

            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Failed ON v_claim_nbr= ' || V_CLAIM_NBR);
                    DBMS_OUTPUT.PUT_LINE('Oracle Error Code (SQLCODE)= ' || SQLCODE);
                    DBMS_OUTPUT.PUT_LINE('Oracle Error Message (SQLERRM)= ' || SQLERRM);
					V_LINE_NUMBER := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE();
                    DBMS_OUTPUT.PUT_LINE('line number =' ||V_LINE_NUMBER);
            END;
        END LOOP;

        COMMIT;
		DBMS_OUTPUT.PUT_LINE('Execution process ended... ' || V_MONTH || ',' || V_YEAR );

        IF V_5YR_FLAG = 'Y' THEN
            CLOSE C_MAIN_5YR;
        ELSE
            CLOSE C_MAIN;
        END IF;
     --   UTL_FILE.FCLOSE(FILE_HANDLE);
     --   UTL_FILE.FCLOSE(CLUE_FILE_HANDLE);
        DBMS_OUTPUT.PUT_LINE('Processing Complete:  ' || TO_CHAR(SYSDATE, 'MM/DD/YYYY HH:MI'));
        DBMS_OUTPUT.PUT_LINE('Claim coverages selected: ' || V_CNT1);
--dbms_output.put_line('Bypassed - dec_umbrella_coverage: '||v_cnt2);
--dbms_output.put_line('Bypassed - Closed w/Zero paid: '||v_cnt8);
        DBMS_OUTPUT.PUT_LINE('Total Records Output: ' || V_CNT7);
        DBMS_OUTPUT.PUT_LINE('Total Paid Loss Submitted: ' || TO_CHAR(V_LOSS_AMOUNT_SUBMITTED, '999g999g999d99'));
    EXCEPTION
        WHEN UTL_FILE.INVALID_PATH THEN
           -- UTL_FILE.FCLOSE_ALL;
          --  DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            RAISE_APPLICATION_ERROR(-20003, 'Invalid path.');
        WHEN UTL_FILE.WRITE_ERROR THEN
           -- UTL_FILE.FCLOSE_ALL;
          --  DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            RAISE_APPLICATION_ERROR(-20011, 'WRITE error.');
        WHEN UTL_FILE.INTERNAL_ERROR THEN
          --  UTL_FILE.FCLOSE_ALL;
          --  DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            RAISE_APPLICATION_ERROR(-20005, 'Internal error.');
        WHEN UTL_FILE.INVALID_FILEHANDLE THEN
           -- UTL_FILE.FCLOSE_ALL;
          --  DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            RAISE_APPLICATION_ERROR(-20006, 'Invalid FILE handle.');
        WHEN UTL_FILE.INVALID_MODE THEN
            --UTL_FILE.FCLOSE_ALL;
         --   DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            RAISE_APPLICATION_ERROR(-20007, 'Invalid MODE.');
        WHEN UTL_FILE.INVALID_OPERATION THEN
          --  UTL_FILE.FCLOSE_ALL;
           -- DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            RAISE_APPLICATION_ERROR(-20008, 'Invalid operation.');
        WHEN NO_DATA_FOUND THEN
         --   UTL_FILE.FCLOSE_ALL;
           -- DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            RAISE_APPLICATION_ERROR(-20009, 'No data found.');
        WHEN TOO_MANY_ROWS THEN
           -- UTL_FILE.FCLOSE_ALL;
           -- DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            RAISE_APPLICATION_ERROR(-20010, 'Too many ROWS found.');
        WHEN UTL_FILE.READ_ERROR THEN
         --   UTL_FILE.FCLOSE_ALL;
           -- DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            RAISE_APPLICATION_ERROR(-20004, 'Read error.');
        WHEN OTHERS THEN
          --  UTL_FILE.FCLOSE_ALL;
            --DBMS_SQL.CLOSE_CURSOR(CURSOR_HANDLE);
            V_LINE_NUMBER := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE();
            V_ERROR_MESSAGE := SQLERRM;

      -- Print or log the line number and error message
            DBMS_OUTPUT.PUT_LINE('Error at line '
                                 || V_LINE_NUMBER
                                 || ': '
                                 || V_ERROR_MESSAGE);
            DBMS_OUTPUT.PUT_LINE('Inner exception: ' || SQLERRM);
            RAISE_APPLICATION_ERROR(-20026, 'Unknown error IN sp_Write_aplus_File');
    END SP_WRITE_APLUS_FILE;

    FUNCTION FN_CONVERT_NULL_TO_SPACE (
        V_CHAR_INPUT IN VARCHAR2
    ) RETURN VARCHAR2 IS
        V_CHAR_OUT VARCHAR2(100);
    BEGIN
        IF LTRIM(RTRIM(V_CHAR_INPUT)) IS NULL THEN
            V_CHAR_OUT := ' ';
        ELSE
            V_CHAR_OUT := V_CHAR_INPUT;
        END IF;

        RETURN ( V_CHAR_OUT );
    END FN_CONVERT_NULL_TO_SPACE;

    FUNCTION FN_REPLACE_UNPRINTABLE (
        V_CHAR_INPUT IN VARCHAR2
    ) RETURN VARCHAR2 IS

        V_CHAR_OUT VARCHAR2(1032);
        V_CHAR     VARCHAR2(1);
        V_LENGTH   NUMBER(4);
        V_COUNT    NUMBER(4) := 1;
        V_ASCII    NUMBER(4);
    BEGIN
        V_CHAR_OUT := V_CHAR_INPUT;

	-- Get the length of the string
        V_LENGTH := LENGTH(V_CHAR_INPUT);
        WHILE V_LENGTH >= V_COUNT LOOP

		-- Get the character and ascii number.
            V_CHAR := SUBSTR(V_CHAR_OUT, V_COUNT, 1);
            V_ASCII := ASCII(V_CHAR);
            IF ( V_ASCII < 32 OR V_ASCII > 126 ) THEN
                V_CHAR_OUT := REPLACE(V_CHAR_OUT, V_CHAR, ' ');
            END IF;

		-- Increment the counter
            V_COUNT := V_COUNT + 1;
        END LOOP;

        RETURN ( V_CHAR_OUT );
    END FN_REPLACE_UNPRINTABLE;

END PKG_APLUS;


SET SERVEROUT ON;

DECLARE
  V_MONTH NUMBER;
  V_YEAR NUMBER;
  V_ISO_APLUS_ACCOUNT_NBR VARCHAR2(200);
  V_5YR_FLAG VARCHAR2(200);
  V_V_CLAIM_NBR NUMBER;
BEGIN
  V_MONTH := 12;
  V_YEAR := 2024;
  V_ISO_APLUS_ACCOUNT_NBR := 331000000000;
  V_5YR_FLAG := 'N';
  V_V_CLAIM_NBR := 2018849;
  
  CIGADMIN.PKG_APLUS.SP_WRITE_APLUS_FILE(
    V_MONTH => V_MONTH,
    V_YEAR => V_YEAR,
    V_ISO_APLUS_ACCOUNT_NBR => V_ISO_APLUS_ACCOUNT_NBR,
    V_5YR_FLAG => V_5YR_FLAG
    ,V_V_CLAIM_NBR => V_V_CLAIM_NBR
  );
END;