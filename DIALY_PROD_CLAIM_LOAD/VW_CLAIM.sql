--------------------------------------------------------
--  DDL for View VW_CLAIM
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "DATALAKE"."VW_CLAIM" ("CLAIM", "POLICY", "DEC_POLICY", "CATASTROPHE", "CLAIM_STATUS", "DATE_OF_LOSS", "CLAIM_NUMBER", "CLAIM_PREFIX", "CLAIM_DESCRIPTION", "CLAIM_LOCATION", "CLAIM_ZIPCODE", "CLAIM_CITY", "CLAIM_COUNTY", "CLAIM_STATE", "CLAIM_COUNTRY", "C_TRANS_DATE", "C_LOAD_DATE") AS 
  SELECT CLAIM,
            POLICY,
            DEC_POLICY,
            CATASTROPHE,
            CLAIM_STATUS,
            DATE_OF_LOSS,
            CLAIM_NUMBER,
            CLAIM_PREFIX,
            CLAIM_DESCRIPTION,
            CLAIM_LOCATION,
            CLAIM_ZIPCODE,
            CLAIM_CITY,
            CLAIM_COUNTY,
            CLAIM_STATE,
            CLAIM_COUNTRY,
            C_TRANS_DATE,
            C_LOAD_DATE
       FROM (SELECT claim,
                    policy,
                    dec_policy,
                    catastrophe,
                    claim_status,
                    date_of_loss,
                    claim_nbr               AS claim_number,
                    claim_prefix,
                    claim_desc              AS claim_description,
                    NVL (location, 'Unknown') AS claim_location,
                    NVL (zip_code, 'Unknown') AS claim_zipcode,
                    NVL (city, 'Unknown')   AS claim_city,
                    NVL (county, 'Unknown') AS claim_county,
                    NVL (state, 'Unknown')  AS claim_state,
                    NVL (country, 'Unknown') AS claim_country,
                    TRUNC (last_modified)   AS c_trans_date,
                    load_date               AS c_load_date,
                    'CMS' as claim_source,
                     case when DEC_POLICY is not null then
                      'PC'
                      else
                      'eCIG' 
                      end as policy_source
               FROM dec30_claim
             UNION
             SELECT claim,
                    policy,
                    dec_policy,
                    catastrophe,
                    claim_status,
                    date_of_loss,
                    claim_nbr               AS claim_number,
                    claim_prefix,
                    claim_desc              AS claim_description,
                    NVL (location, 'Unknown') AS claim_location,
                    NVL (zip_code, 'Unknown') AS claim_zipcode,
                    NVL (city, 'Unknown')   AS claim_city,
                    NVL (county, 'Unknown') AS claim_county,
                    NVL (state, 'Unknown')  AS claim_state,
                    NVL (country, 'Unknown') AS claim_country,
                    TRUNC (last_modified)   AS c_trans_date,
                    load_date               AS c_load_date,
                    'CMS' as claim_source,
                     case when DEC_POLICY is not null then
                      'PC'
                      else
                      'eCIG' 
                      end as policy_source
               FROM datalake.daily_claim
             WHERE load_date > TO_DATE ('12-30-2015', 'mm-dd-yyyy')
                          union 
             SELECT  c.id as claim,
                    p.id as policy,
                    case when P.DECPOLICY_EXT is not null THEN
                      p.PolicySystemPeriodID
                      else
                      P.DECPOLICY_EXT
                     END AS dec_policy,  
                    CCAT.ID  AS catastrophe,
                    TLS.NAME AS claim_status,
                    C.LOSSDATE as date_of_loss,
                    C.CLAIMNUMBER AS claim_number,
                    'C' as claim_prefix,
                    C.Description   AS claim_description,
                    NVL (CA.ADDRESSLINE1, 'Unknown') AS claim_location,
                    NVL (CA.POSTALCODE, 'Unknown') AS claim_zipcode,
                    NVL (CA.CITY, 'Unknown')   AS claim_city,
                    NVL (CA.COUNTY, 'Unknown') AS claim_county,
                    NVL (TLST.TYPECODE, 'Unknown')  AS claim_state,
                    NVL(CA.COUNTRY, 0) AS claim_country,
                    TRUNC (C.UPDATETIME)   AS c_trans_date,
                    C.load_date               AS c_load_date,
                    'CC' as claim_source,
                     case when p.DECPOLICY_EXT is not null then
                      'PC'
                      else
                      'eCIG' 
                      end as policy_source
              from datalake.daily_cc_claim c
              INNER JOIN datalake.daily_CC_POLICY P ON P.ID=C.POLICYID
              LEFT OUTER JOIN datalake.daily_CCTL_CLAIMSTATE TLS ON TLS.ID = C.STATE AND TLS.RETIRED = 0
              LEFT OUTER JOIN datalake.daily_CC_CATASTROPHE CCAT ON C.CATASTROPHEID = CCAT.ID AND CCAT.RETIRED = 0
              LEFT OUTER JOIN datalake.daily_CC_ADDRESS CA ON CA.ID = C.LOSSLOCATIONID AND CA.RETIRED = 0
              LEFT OUTER JOIN datalake.daily_CCTL_STATE TLST ON TLST.ID = CA.STATE AND TLST.RETIRED = 0
              )
   ORDER BY claim, c_trans_date;
