select claimant
      ,case
          when trim(business_name) is null
             then trim('Claimant: ' || trim(last_name) || ', ' || trim(first_name) || ' ' || trim(middle_name) || ' ' || trim(suffix))
          when trim(last_name) is null
             then 'Business: ' || trim(business_name)
          else trim('Claimant: ' || trim(last_name) || ', ' || trim(first_name) || ' ' || trim(middle_name) || ' ' || trim(suffix)) || ' || Business: ' || trim(business_name)
       end claimant_name
      ,case when medicareeligible is null then 'Unknown'
            when medicareeligible=0 then 'No'
            when medicareeligible=1 then 'Yes'
       end medicare_eligible
      ,claimant_trans_date
      ,claimant_load_date
      ,claim_source
from (select claimant, business_name, last_name, first_name, middle_name, suffix, medicareeligible,
       trunc(last_modified) as claimant_trans_date, load_date as claimant_load_date,
       'CMS' as claim_source 
       from dec30_cms_party
       WHERE load_date > to_date('12-30-2015','mm-dd-yyyy')
            union
      select claimant, business_name, last_name, first_name, middle_name, suffix, medicareeligible,
      trunc(last_modified) as claimant_trans_date, load_date as claimant_load_date,
      'CMS' as claim_source 
      from datalake.daily_cms_party
      WHERE load_date > to_date('12-30-2015','mm-dd-yyyy')
      UNION
      SELECT CCTP.ID AS claimant, CTP.DOINGBUSINESSAS_EXT AS business_name, CTP.LASTNAME AS last_name,
       CTP.FIRSTNAME AS first_name, CTP.MiddleName AS middle_name, 
      TLNS.TYPECODE AS suffix, TO_NUMBER(CCMACC.BeneficiaryStatus) AS medicareeligible,
      trunc(CCTP.UPDATETIME) as claimant_trans_date , CTP.load_date as claimant_load_date, 'CC' as claim_source
    from DLAKEDEV.daily_CC_CLAIM CD 
    INNER JOIN DLAKEDEV.daily_CC_EXPOSURE EX ON EX.CLAIMID=CD.id AND EX.RETIRED=0
    INNER JOIN DLAKEDEV.daily_CC_POLICY P ON P.ID=CD.POLICYID
    INNER JOIN DLAKEDEV.daily_CC_CLAIMCONTACTROLE CCTRP ON CCTRP.POLICYID=P.ID  AND CCTRP.RETIRED=0
    INNER JOIN DLAKEDEV.daily_CCTL_CONTACTROLE TLCCTR ON TLCCTR.ID=CCTRP.ROLE AND TLCCTR.TYPECODE IN ('insured') AND TLCCTR.RETIRED=0
    INNER JOIN DLAKEDEV.daily_CC_CLAIMCONTACT CCTP ON  CCTRP.ClaimContactID=CCTP.ID AND CCTP.RETIRED=0
    INNER JOIN DLAKEDEV.daily_CC_CONTACT CTP ON CTP.ID=CCTP.CONTACTID AND CTP.RETIRED=0
    LEFT OUTER JOIN DLAKEDEV.daily_CCTL_NAMESUFFIX TLNS ON TLNS.ID = CTP.Suffix  AND TLNS.RETIRED =0
    LEFT OUTER JOIN DLAKEDEV.daily_CCX_MIRREPORTABLE_ACC CCMA ON CCMA.ID = EX.MIRREPORTABLE  
    LEFT OUTER JOIN DLAKEDEV.D_CCX_MIRREPORTABLEHIST_ACCMIT CCMACC ON CCMACC.ID = CCMA.ID
      where CTP.load_date > to_date('12-30-2022','mm-dd-yyyy')
      )
where claimant is not null
order by claimant, claimant_trans_date