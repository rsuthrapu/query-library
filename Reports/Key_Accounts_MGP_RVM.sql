WITH POLICIES AS (
--SELECT REGEXP_SUBSTR('6-BOP-2-1943755,6-BOP-2-1651267,6-BOP-4-1796323,6-BOP-2-1651260,6-MGA-1-2070696,6-MGA-2-2070696,6-MGA-2-056759,6-BAA-1-070011855,6-BOP-1-1869930,6-CUL-1-070011897','[^,]+', 1, LEVEL) AS POLICY_NUMBER FROM DUAL
--                CONNECT BY REGEXP_SUBSTR('6-BOP-2-1943755,6-BOP-2-1651267,6-BOP-4-1796323,6-BOP-2-1651260,6-MGA-1-2070696,6-MGA-2-2070696,6-MGA-2-056759,6-BAA-1-070011855,6-BOP-1-1869930,6-CUL-1-070011897', '[^,]+', 1, LEVEL) IS NOT NULL
--SELECT REGEXP_SUBSTR('6-CMA-1-2057217,6-BAA-1-070016172,6-BOP-4-070015277,6-BOP-2-070008303,6-BOP-1-070008041,6-CUL-1-070011624,6-MGA-1-056661,6-MGA-2-056759,6-MGA-1-2070696,6-BOP-2-1943755,6-MGA-2-2070696,6-BOP-2-1651260,6-BOP-2-1651267,6-BOP-4-1796323,6-BAA-1-070011855,6-BOP-1-1869930,6-CUL-1-070011897','[^,]+', 1, LEVEL) AS POLICY_NUMBER FROM DUAL
--                CONNECT BY REGEXP_SUBSTR('6-CMA-1-2057217,6-BAA-1-070016172,6-BOP-4-070015277,6-BOP-2-070008303,6-BOP-1-070008041,6-CUL-1-070011624,6-MGA-1-056661,6-MGA-2-056759,6-MGA-1-2070696,6-BOP-2-1943755,6-MGA-2-2070696,6-BOP-2-1651260,6-BOP-2-1651267,6-BOP-4-1796323,6-BAA-1-070011855,6-BOP-1-1869930,6-CUL-1-070011897', '[^,]+', 1, LEVEL) IS NOT NULL
SELECT * FROM KEY_POLICY KP
INNER JOIN KEY_ACCOUNT KA ON KA.KEY_ACCOUNT_ID=KP.KEY_ACCOUNT_ID
WHERE KA.RMID IN ('MGP0601')
-- For MGP ('MGP0601')
-- For RVM ('RVM0601')
),
ECIG_DATA AS 
(
    select
       EXTRACT(YEAR FROM c.date_of_loss) AY,
        P.NAME AS KEY_ACCOUNT_NAME,
        to_char(c.date_of_loss, 'mm/dd/yyyy') DATE_OF_LOSS,        
        dp.policy_search_nbr POLICY_SEARCH_NUMBER, 
        dp.TERM_EFFECTIVE_DATE,
        dp.TERM_EXPIRATION_DATE, 
        dp.agency_domicile_state AS DOMICILE_STATE,
        ASL.A_S_LINE_NBR,
        COV.COVERAGE_DESC AS COVERAGE,
        case 
          when lower(COV.coverage_desc) like '%liability%' then 'Liability'
          when COV.coverage_desc like 'Boiler '|| chr(38) ||' Machinery' then 'Boiler Machinery'
          when col.CAUSE_NAME = 'Fire' then 'Fire'
          when col.CAUSE_NAME = 'Storm' then 'Storm'
          when col.CAUSE_NAME = 'Theft' then 'Theft'
          when col.CAUSE_NAME = 'Vandalism, Malicious Mischief' then 'Vandalism'
          when col.CAUSE_NAME in ('Water', '1st P Mold') then 'Water'
          when col.CAUSE_NAME in ('Riot, Civil Commotion', 'Structure', 'BI (Auto)', 'Coll', 'Contents', 'Employee Dishonesty', 'Employment Practices', 'Habitability', 'Mechanical Breakdown', 'Property Damage', 'Bodily Injury', 'Explosion', 'Glass', 'Other') then 'Other'
          else '-999'
        end as Peril,
        col.CAUSE_NAME AS CAUSE_OF_LOSS,
        c.claim_number CLAIM_NUMBER_CHAR,
        c.claim_NBR CLAIM_NUMBER,
        c.CLAIM CLAIM,
        coalesce(DBL.property_location, DCMC.property_location) as   property_location,
        coalesce(DBL.state, AD.STATE) as   STATE,
        coalesce(TO_CHAR(DBL.zip_code), AD.zip_code) as   zip,
--        (case when ct.trans_type in ('Credit Other') then nvl(ct.loss_paid,0) 
--          else nvl(ct.loss_reserve,0) 
--        end) 
        NULL AS INCURRED_LOSS,
        dp.legal_name INSURED_NAME,     
        c.claim_status CLAIM_STATUS, 
        to_char(c.FIRST_MODIFIED, 'mm/dd/yyyy') FIRST_MODIFIED_BY_CLAIM,
        to_char(c.claim_status_date, 'mm/dd/yyyy') DATE_OF_CLOSURE,
        'eCIG' as "APP"
    from        
        claim c
        INNER JOIN dec_policy dp ON c.dec_policy = dp.dec_policy  
        LEFT OUTER JOIN DEC_BOP_LOCATION DBL ON DBL.dec_policy = DP.dec_policy AND DBL.dec_bop_location = C.unit_key
        left outer join DEC_COMM_MANUAL_COVERAGE DCMC on DCMC.DEC_POLICY = dp.DEC_POLICY AND C.UNIT_KEY = DCMC.DEC_COMM_MANUAL_COVERAGE
        left outer JOIN COMMERCIAL_MANUAL_COVERAGE CMC ON CMC.COMMERCIAL_MANUAL_COVERAGE = DCMC.COMMERCIAL_MANUAL_COVERAGE
        left outer JOIN ADDR AD ON AD.ADDR=CMC.PROPERTY_LOCATION
        INNER JOIN CLAIMANT_COVERAGE CC ON CC.CLAIM=C.CLAIM
        INNER JOIN cause_of_loss col ON cc.cause_of_loss=col.cause_of_loss
        --INNER JOIN CLAIMANT_TRANS@ECHO_ANALYTICS_LINK_USER CT ON COL.CAUSE_OF_LOSS =CT.CAUSE_OF_LOSS AND CC.CLAIM=CT.CLAIM AND C.CLAIM=CT.CLAIM
        INNER JOIN COVERAGE COV ON COV.COVERAGE=CC.COVERAGE
        INNER JOIN A_S_COVERAGE_LINE  ASCL ON ASCL.A_S_COVERAGE_LINE=C.A_S_COVERAGE_LINE
        INNER JOIN A_S_LINE  ASL ON ASL.A_S_LINE=ASCL.A_S_LINE
        --INNER JOIN INCURRED_LOSS@ECHO_ANALYTICS_LINK_USER IL ON IL.CLAIM=C.CLAIM
--            AND dp.agency_domicile_state = 'CA' 
--            AND C.CLAIM_STATUS='Closed'
            INNER JOIN POLICIES P ON P.POLICY_NUMBER=DP.POLICY_SEARCH_NBR
    --WHERE C.CLAIM_STATUS_DATE BETWEEN '01-JAN-2020' and '31-DEC-2020'
),
PC_DATA AS (
select
        EXTRACT(YEAR FROM c.date_of_loss) AY,
        P.NAME AS KEY_ACCOUNT_NAME,
        to_char(c.date_of_loss, 'mm/dd/yyyy') DATE_OF_LOSS,      
        cpc.policy_search_nbr POLICY_SEARCH_NUMBER, 
        cpc.TERM_EFFECTIVE_DATE,
        cpc.TERM_EXPIRATION_DATE,   
        cpc.agency_domicile_state AS DOMICILE_STATE, 
        ASL.A_S_LINE_NBR,
        COV.COVERAGE_DESC AS COVERAGE,
         case 
          when lower(COV.coverage_desc) like '%liability%' then 'Liability'
          when COV.coverage_desc like 'Boiler '|| chr(38) ||' Machinery' then 'Boiler Machinery'
          when col.CAUSE_NAME = 'Fire' then 'Fire'
          when col.CAUSE_NAME = 'Storm' then 'Storm'
          when col.CAUSE_NAME = 'Theft' then 'Theft'
          when col.CAUSE_NAME = 'Vandalism, Malicious Mischief' then 'Vandalism'
          when col.CAUSE_NAME in ('Water', '1st P Mold') then 'Water'
          when col.CAUSE_NAME in ('Riot, Civil Commotion', 'Structure', 'BI (Auto)', 'Coll', 'Contents', 'Employee Dishonesty', 'Employment Practices', 'Habitability', 'Mechanical Breakdown', 'Property Damage', 'Bodily Injury', 'Explosion', 'Glass', 'Other') then 'Other'
          else '-999'
        end as Peril,
        col.CAUSE_NAME AS CAUSE_OF_LOSS,
        c.claim_number CLAIM_NUMBER_CHAR,
        c.claim_NBR CLAIM_NUMBER,
        c.CLAIM CLAIM,
        AD.addr_nbr || ' ' || AD.prefix || ' ' || AD.street_name || ' ' || 
        AD.suffix || ' ' ||  NVL(AD.suite, '') || ' ' || NVL(AD.po_box, '') || ' ' || AD.city as property_location,
        AD.state,
        TO_CHAR(AD.zip_code) as zip,
--        (case when ct.trans_type in ('Credit Other') then nvl(ct.loss_paid,0) 
--          else nvl(ct.loss_reserve,0) 
--        end) 
        NULL AS INCURRED_LOSS,
        cpc.legal_name INSURED_NAME,       
        c.claim_status CLAIM_STATUS,  
        to_char(c.FIRST_MODIFIED, 'mm/dd/yyyy')  FIRST_MODIFIED_BY_CLAIM,
        to_char(c.claim_status_date, 'mm/dd/yyyy') DATE_OF_CLOSURE,
        'PC' as "APP"
from        
        claim c
        INNER JOIN cms_claim_policy ccp ON ccp.claim = c.claim-- AND C.CLAIM_STATUS='Closed'
        INNER JOIN cms_policy cpc ON ccp.cms_policy = cpc.cms_policy--AND cpc.agency_domicile_state = 'CA'
        INNER JOIN CMS_LOCATION CL ON CL.cms_policy = cpc.cms_policy and CL.cms_location = C.unit_key
        INNER JOIN ADDR AD ON AD.addr = CL.addr

        INNER JOIN CLAIMANT_COVERAGE CC ON CC.CLAIM=C.CLAIM
        INNER JOIN COVERAGE COV ON COV.COVERAGE=CC.COVERAGE
        INNER JOIN A_S_COVERAGE_LINE  ASCL ON ASCL.A_S_COVERAGE_LINE=C.A_S_COVERAGE_LINE
        INNER JOIN A_S_LINE  ASL ON ASL.A_S_LINE=ASCL.A_S_LINE
        INNER JOIN cause_of_loss col ON cc.cause_of_loss=col.cause_of_loss
--        INNER JOIN CLAIMANT_TRANS@ECHO_ANALYTICS_LINK_USER CT ON COL.CAUSE_OF_LOSS =CT.CAUSE_OF_LOSS AND CC.CLAIM=CT.CLAIM AND C.CLAIM=CT.CLAIM

        --INNER JOIN INCURRED_LOSS@ECHO_ANALYTICS_LINK_USER IL ON IL.CLAIM=C.CLAIM
        INNER JOIN POLICIES P ON P.POLICY_NUMBER=cpc.POLICY_SEARCH_NBR

    --WHERE C.CLAIM_STATUS_DATE BETWEEN '01-JAN-2020' and '31-DEC-2020'
),
CC_DATA AS (
select
       EXTRACT(YEAR FROM C.LOSSDATE) AS AY,
       PY.NAME AS KEY_ACCOUNT_NAME,
        to_char(C.LOSSDATE, 'mm/dd/yyyy') AS DATE_OF_LOSS,        
        P.POLICYNUMBER AS POLICY_SEARCH_NUMBER, 
        P.EffectiveDate AS TERM_EFFECTIVE_DATE ,
        P.ExpirationDate AS  TERM_EXPIRATION_DATE, 
        ctp.AGENCYDOMICILESTATE_EXT AS DOMICILE_STATE,
        ASL.A_S_LINE_NBR,
        TLCOVTY.description AS COVERAGE,
       case 
          when lower(TLCOVTY.description) like '%liability%' then 'Liability'
          when TLCOVTY.description like 'Boiler '|| chr(38) ||' Machinery' then 'Boiler Machinery'
          when TLLC.NAME = 'Fire' then 'Fire'
          when TLLC.NAME = 'Storm' then 'Storm'
          when TLLC.NAME = 'Theft' then 'Theft'
          when TLLC.NAME = 'Malicious mischief and vandalism' then 'Vandalism'
          when TLLC.NAME in ('Water', '1st P Mold') then 'Water'
          when TLLC.NAME in ('Riot, Civil Commotion', 'Structure', 'BI (Auto)', 'Coll', 'Contents', 'Employee Dishonesty', 'Employment Practices', 'Habitability', 'Mechanical Breakdown', 'Property Damage', 'Bodily Injury', 'Explosion', 'Glass', 'Other') then 'Other'
          else '-999'
        end as Peril,
       TLLC.NAME AS CAUSE_OF_LOSS,
       '' AS CLAIM_NUMBER_CHAR,
       C.CLAIMNUMBER AS CLAIM_NUMBER,
       C.ID AS CLAIM,
        AD.ADDRESSLINE1 || ' ' || --AD.ADDRESSLINE2 || ' ' || AD.ADDRESSLINE3 || ' ' || 
        NVL(AD.POSTALCODE, '') || ' ' || AD.CITY AS PROPERTY_LOCATION,
       TLS.TYPECODE AS STATE,
       TO_CHAR(AD.POSTALCODE) as zip,
       NULL AS INCURRED_LOSS,
       (SUBSTR(DECODE(TLCCTR.TYPECODE, 'insured', CTP.LASTNAME || ' ' || CTP.FIRSTNAME),1,80)) AS INSURED_NAME,
       TLCS.NAME AS CLAIM_STATUS,
       to_char(c.CREATETIME, 'mm/dd/yyyy')  FIRST_MODIFIED_BY_CLAIM,
       to_char(C.CloseDate , 'mm/dd/yyyy') DATE_OF_CLOSURE,
       'CC' as "APP"
FROM CC_CLAIM@ECIG_TO_CC_LINK C
INNER JOIN CC_EXPOSURE@ECIG_TO_CC_LINK EX ON EX.CLAIMID=C.ID AND EX.RETIRED=0
INNER JOIN CC_POLICY@ECIG_TO_CC_LINK P ON C.POLICYID =  P.ID AND P.RETIRED = 0
LEFT OUTER JOIN DEC_POLICY DP ON DP.DEC_POLICY = P.DECPOLICY_EXT
LEFT OUTER JOIN CC_COVERAGE@ECIG_TO_CC_LINK COV ON COV.ID=EX.COVERAGEID AND COV.RETIRED=0
 LEFT OUTER JOIN CCTL_COVERAGETYPE@ECIG_TO_CC_LINK TLCOVTY ON TLCOVTY.ID=COV.TYPE AND TLCOVTY.RETIRED=0
LEFT OUTER JOIN A_S_COVERAGE_LINE ASCL ON ASCL.A_S_COVERAGE_LINE=COV.ASCOVERAGELINE_EXT
LEFT OUTER JOIN A_S_LINE ASL ON ASL.A_S_LINE=ASCL.A_S_LINE
INNER JOIN CC_CLAIMCONTACTROLE@ECIG_TO_CC_LINK CCTRP ON CCTRP.POLICYID=C.POLICYID  AND CCTRP.RETIRED=0 -- FOR AGENT
INNER JOIN CCTL_CONTACTROLE@ECIG_TO_CC_LINK TLCCTR ON TLCCTR.ID=CCTRP.ROLE AND TLCCTR.TYPECODE IN ('insured') AND TLCCTR.RETIRED=0 
INNER JOIN CC_CLAIMCONTACT@ECIG_TO_CC_LINK CCTP ON  CCTRP.ClaimContactID=CCTP.ID AND CCTP.RETIRED=0 -- FOR AGENT
INNER JOIN CC_CONTACT@ECIG_TO_CC_LINK CTP ON CTP.ID=CCTP.CONTACTID AND CTP.RETIRED=0 
LEFT OUTER JOIN CCTL_LOSSCAUSE@ECIG_TO_CC_LINK TLLC ON TLLC.ID = C.LOSSCAUSE AND TLLC.RETIRED = 0
LEFT OUTER JOIN CC_ADDRESS@ECIG_TO_CC_LINK AD ON AD.ID = C.LOSSLOCATIONID AND AD.RETIRED = 0
LEFT OUTER JOIN CCTL_STATE@ECIG_TO_CC_LINK TLS ON TLS.ID = AD.STATE AND TLS.RETIRED = 0
LEFT OUTER JOIN CCTL_CLAIMSTATE@ECIG_TO_CC_LINK TLCS ON TLCS.ID = C.STATE AND TLCS.RETIRED = 0
INNER JOIN POLICIES PY ON PY.POLICY_NUMBER=P.POLICYNUMBER
),
CMS_DATA AS (
SELECT DISTINCT
    ED.AY, ED.KEY_ACCOUNT_NAME, ED.DATE_OF_LOSS, ED.POLICY_SEARCH_NUMBER, 
    ED.TERM_EFFECTIVE_DATE, ED.DOMICILE_STATE, ED.A_S_LINE_NBR, 
    ED.COVERAGE, ED.PERIL, ED.CAUSE_OF_LOSS, ED.CLAIM_NUMBER_CHAR, ED.CLAIM_NUMBER,  ED.CLAIM,
    ED.PROPERTY_LOCATION, ED.STATE, ED.ZIP
    -- ADDITIONAL FIELDS 
        , ED.INSURED_NAME, ED.CLAIM_STATUS, ED.DATE_OF_CLOSURE
    --,ED.INCURRED_LOSS 
FROM ECIG_DATA ED
UNION ALL 
SELECT  DISTINCT PD.AY, PD.KEY_ACCOUNT_NAME, PD.DATE_OF_LOSS, PD.POLICY_SEARCH_NUMBER, 
    PD.TERM_EFFECTIVE_DATE, PD.DOMICILE_STATE, PD.A_S_LINE_NBR, 
    PD.COVERAGE, PD.PERIL, PD.CAUSE_OF_LOSS, PD.CLAIM_NUMBER_CHAR, PD.CLAIM_NUMBER, PD.CLAIM,
    PD.PROPERTY_LOCATION, PD.STATE, PD.ZIP
    --,PD.INCURRED_LOSS  
     -- ADDITIONAL FIELDS 
        , PD.INSURED_NAME, PD.CLAIM_STATUS, PD.DATE_OF_CLOSURE
FROM PC_DATA PD 
UNION ALL
SELECT  DISTINCT CCD.AY, CCD.KEY_ACCOUNT_NAME, CCD.DATE_OF_LOSS, CCD.POLICY_SEARCH_NUMBER, 
    CCD.TERM_EFFECTIVE_DATE, CCD.DOMICILE_STATE, CCD.A_S_LINE_NBR, 
    CCD.COVERAGE, CCD.PERIL, CCD.CAUSE_OF_LOSS, CCD.CLAIM_NUMBER_CHAR, CCD.CLAIM_NUMBER, CCD.CLAIM,
    CCD.PROPERTY_LOCATION, CCD.STATE, CCD.ZIP
    --,PD.INCURRED_LOSS  
     -- ADDITIONAL FIELDS 
        , CCD.INSURED_NAME, CCD.CLAIM_STATUS, CCD.DATE_OF_CLOSURE
FROM CC_DATA CCD 
),
CMS_INCURRED_LOSS AS (
SELECT
        C.CLAIM,
     --   CD.CLAIM_NUMBER,
--        COL.CAUSE_OF_LOSS,
        COL.CAUSE_NAME,
--        COV.COVERAGE_DESC,
        --cause_of_loss.cause_name,
        SUM( ROUND(LOSS_OS) )AS LOSSOS,
        SUM(NVL(LOSS_PAID,0)) AS LOSS_PAID,
        SUM (NVL( ROUND(LOSS_OS),0) + NVL(LOSS_PAID,0)) AS INC_LOSS,
        SUM(NVL( ROUND(UNALLOC_EXPENSE_OS) ,0)) AS ULAE,
        SUM (NVL(UNALLOC_EXPENSE_PAID,0)) AS ULAEPAID,
        SUM(NVL( ROUND(ALLOC_EXPENSE_OS) ,0)) AS ALAE,
        SUM (NVL(ALLOC_EXPENSE_PAID,0)) AS ALAEPAID,
        SUM (NVL(UNALLOC_EXPENSE_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL( ROUND(ALLOC_EXPENSE_OS),0)+NVL( ROUND(UNALLOC_EXPENSE_OS),0))AS INC_EXP
  FROM
        CLAIM C 
        INNER JOIN CLAIMANT_COVERAGE CC ON CC.CLAIM=C.CLAIM 
        INNER JOIN COVERAGE COV ON COV.COVERAGE=CC.COVERAGE --AND COV.COVERAGE_DESC=CD.COVERAGE
        INNER JOIN cause_of_loss COL ON cc.cause_of_loss=col.cause_of_loss --AND COL.CAUSE_NAME=CD.cause_of_loss
        INNER JOIN CMS_DATA CD ON CC.CLAIM=CD.CLAIM AND COV.COVERAGE_DESC=CD.COVERAGE AND COL.CAUSE_NAME=CD.cause_of_loss

  GROUP BY 
        C.CLAIM,
       -- CD.CLAIM_NUMBER,
        COL.CAUSE_NAME
--        COL.CAUSE_NAME,
--        COV.COVERAGE_DESC
),
CC_INCURRED_LOSS AS (
SELECT 
  CLAIM , CAUSE_NAME ,
  SUM( ROUND(LOSS_RESERVE) )AS LOSSOS,
    SUM(NVL(LOSS_PAID,0)) AS LOSS_PAID,
    SUM (NVL( ROUND(LOSS_RESERVE),0) + NVL(LOSS_PAID,0)) AS INC_LOSS,
    SUM(NVL( ROUND(UNALLOC_EXPENSE_RESERVE) ,0)) AS ULAE,
    SUM (NVL(UNALLOC_EXPENSE_PAID,0)) AS ULAEPAID,
    SUM(NVL( ROUND(ALLOC_EXPENSE_RESERVE) ,0)) AS ALAE,
    SUM (NVL(ALLOC_EXPENSE_PAID,0)) AS ALAEPAID,
    SUM (NVL(UNALLOC_EXPENSE_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL( ROUND(ALLOC_EXPENSE_RESERVE),0)+NVL( ROUND(UNALLOC_EXPENSE_RESERVE),0))AS INC_EXP
FROM 
(
SELECT
        C.ID AS CLAIM,
        TLLC.NAME AS CAUSE_NAME,
        CASE
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
FROM CC_CLAIM@ECIG_TO_CC_LINK C 
LEFT OUTER JOIN CCTL_LOSSCAUSE@ECIG_TO_CC_LINK TLLC ON TLLC.ID = C.LOSSCAUSE AND TLLC.RETIRED = 0
INNER JOIN CC_EXPOSURE@ECIG_TO_CC_LINK EX ON EX.CLAIMID=C.ID AND EX.RETIRED=0
INNER JOIN CC_TRANSACTION@ECIG_TO_CC_LINK   TR ON TR.CLAIMID = C.ID AND EX.ID=TR.EXPOSUREID AND TR.RETIRED = 0
INNER JOIN CC_TRANSACTIONLINEITEM@ECIG_TO_CC_LINK        TRLI ON TRLI.TRANSACTIONID = TR.ID AND TRLI.RETIRED = 0
INNER JOIN CCTL_TRANSACTION@ECIG_TO_CC_LINK              TLTR ON TLTR.ID = TR.SUBTYPE AND TLTR.RETIRED = 0
LEFT OUTER JOIN CCTL_COSTTYPE@ECIG_TO_CC_LINK  TLCSTTY ON TLCSTTY.ID = TR.COSTTYPE AND TLCSTTY.RETIRED = 0
INNER JOIN CC_DATA CD ON C.ID=CD.CLAIM  AND TLLC.NAME=CD.cause_of_loss --AND COV.COVERAGE_DESC=CD.COVERAGE
)
GROUP BY  CLAIM, CAUSE_NAME
),
CMS_CC_IL AS 
(
  SELECT * FROM CMS_INCURRED_LOSS
  UNION ALL
  SELECT * FROM CC_INCURRED_LOSS
),
CMS_CC_DATA_WITH_INCURRED_LOSS AS (

SELECT 
CD.AY, CD.KEY_ACCOUNT_NAME, CD.DATE_OF_LOSS, CD.POLICY_SEARCH_NUMBER, 
    CD.TERM_EFFECTIVE_DATE, CD.DOMICILE_STATE, CD.A_S_LINE_NBR, 
    CD.COVERAGE, CD.PERIL, CD.CAUSE_OF_LOSS, CD.CLAIM_NUMBER_CHAR, CD.CLAIM_NUMBER, CD.CLAIM,
    CD.PROPERTY_LOCATION, CD.STATE, CD.ZIP,
    -- INCURRED LOSS FIELDS 
    CIL.LOSSOS, CIL.LOSS_PAID, CIL.INC_LOSS, CIL.ULAE, CIL.ULAEPAID, CIL.ALAE, CIL.ALAEPAID, CIL.INC_EXP
    -- ADDITIONAL FIELDS
    , CD.INSURED_NAME, CD.CLAIM_STATUS, CD.DATE_OF_CLOSURE
FROM 
CMS_DATA CD 
INNER JOIN CMS_CC_IL CIL ON CIL.CLAIM=CD.CLAIM AND CIL.CAUSE_NAME=CD.cause_of_loss-- AND CIL.COVERAGE_DESC=CD.COVERAGE
)

SELECT CD.* --DISTINCT POLICY_SEARCH_NUMBER
--CD.AY, CD.DATE_OF_LOSS, CD.POLICY_SEARCH_NUMBER, 
--    CD.TERM_EFFECTIVE_DATE, CD.DOMICILE_STATE, CD.A_S_LINE_NBR, 
--    CD.COVERAGE, CD.PERIL, CD.CAUSE_OF_LOSS, CD.CLAIM_NUMBER_CHAR, CD.CLAIM_NUMBER, CD.CLAIM,
--    CD.PROPERTY_LOCATION, CD.STATE, CD.ZIP 
--    -- INCURRED LOSS DETAILS
--    -- ADDITIONAL FIELDS
--    , CD.INSURED_NAME, CD.CLAIM_STATUS, CD.DATE_OF_CLOSURE
    --, CD.INCURRED_LOSS
--    , CFS.CLAIM_NBR, CFS.INCURRED_LOSS
--, 
-- case when CD.INC_LOSS=CFS.INCURRED_LOSS then 'MATCH' 
--          else 'NOT MATCHED'
--        end
FROM CMS_CC_DATA_WITH_INCURRED_LOSS CD
--INNER JOIN REPORTSUSER.CLAIMS_FEATURES_SUMMARY CFS ON CFS.CLAIM_NBR=CD.CLAIM_NUMBER 
--AND CFS.CAUSE_OF_LOSS=CD.CAUSE_OF_LOSS
--AND CD.A_S_LINE_NBR=CFS.A_S_LINE_NBR
--AND CFS.COVERAGE_DESC=CD.COVERAGE
--ORDER BY DATE_OF_CLOSURE
--WHERE APP='PC'
--WHERE 
--AY > 2017 
--AND POLICY_SEARCH_NUMBER='6-BOP-1-1869930'
--AND 
--CD.CLAIM IN ( 3743705)--,
--1486875
--)
--POLICY_SEARCH_NUMBER='6-BOP-1-1869930'
ORDER BY CD.KEY_ACCOUNT_NAME, CD.AY, CD.DATE_OF_LOSS, CD.TERM_EFFECTIVE_DATE, CD.DOMICILE_STATE
;

