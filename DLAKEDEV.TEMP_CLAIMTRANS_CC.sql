    create table DLAKEDEV.TEMP_CLAIMTRANS_CC as
WITH DCLAIM AS (
    select *
    from (
      SELECT VWCLAIM.*
            ,row_number() over (partition by claim order by load_date desc) claimlookup_rowmax
      from DATALAKE.DAILY_CLAIM vwclaim
   ) 
   where claimlookup_rowmax=1
),
vc as (
   select claim, policy, dec_policy, catastrophe
        ,claim_number, claim_prefix, date_of_loss, claim_description
        ,CLAIM_COUNTRY, CLAIM_STATE, CLAIM_COUNTY, CLAIM_CITY, CLAIM_ZIPCODE, CLAIM_LOCATION
        ,first_modified as claim_report_date , CLAIM_SOURCE--AS-52
   from (
      SELECT VWCLAIM.*
            ,ROW_NUMBER() OVER (PARTITION BY VWCLAIM.CLAIM ORDER BY VWCLAIM.C_TRANS_DATE DESC) CLAIMLOOKUP_ROWMAX
            ,dclaim.first_modified
      FROM DLAKEDEV.VW_CLAIM VWCLAIM
      left join DCLAIM on DCLAIM.claim = vwclaim.claim
   ) 
   where claimlookup_rowmax=1
),
vcla as (
  select claim, suit_status, CLAIM_SOURCE
   from (
      select claim, cms_suit_status
      from (
         select claim, cms_suit_status
            ,row_number() over (partition by claim order by legal_trans_date desc) legal_rowmax
         from DLAKEDEV.VW_CMS_LEGAL_ACTION
       ) where legal_rowmax=1) legal
         left outer join (
      select cms_suit_status, suit_status, CLAIM_SOURCE
      from (
         select cms_suit_status, suit_status_desc as suit_status,
                      'CMS' AS CLAIM_SOURCE
               ,row_number() over (partition by cms_suit_status order by trunc(last_modified) desc) suitstatus_rowmax
         from DATALAKE.DAILY_CMS_SUIT_STATUS) where suitstatus_rowmax=1
         UNION 
        select cms_suit_status, suit_status, CLAIM_SOURCE
          from (
         select ID AS cms_suit_status
         , CASE WHEN FINALSETTLEDATE IS NOT NULL
                        Then 'Close'
                        ELSE 'Open'
                      END suit_status,
                      'CC' AS CLAIM_SOURCE
               ,row_number() over (partition by ID order by trunc(UPDATETIME) desc) cc_suitstatus_rowmax
         from DLAKEDEV.DAILY_CC_MATTER) where cc_suitstatus_rowmax=1) status
         on legal.cms_suit_status = status.cms_suit_status
),
CMS_dcatastrophe as (
   select catastrophe, cat_no as cat_number, 'CMS' AS CLAIM_SOURCE
   from (
      select dcatastrophe.*
            ,row_number() over (partition by catastrophe order by trunc(last_modified) desc) catastrophe_rowmax
      from DATALAKE.DAILY_CATASTROPHE dcatastrophe
   ) where catastrophe_rowmax=1
),
CC_dcatastrophe AS 
(
   select ID AS catastrophe, CATASTROPHENUMBER as cat_number,  'CC' AS CLAIM_SOURCE
   from (
      select ccdcatastrophe.*
            ,row_number() over (partition by ID order by trunc(UPDATETIME) desc) cc_catastrophe_rowmax
      from DLAKEDEV.DAILY_CC_CATASTROPHE ccdcatastrophe
   ) where cc_catastrophe_rowmax=1
),
dcatastrophe AS 
(
SELECT * FROM CMS_dcatastrophe
UNION ALL
SELECT * FROM CC_dcatastrophe
),
pcclaim as (
--/*change made to remove duplicate claims- sc 07112018*/ 
    select cp.cms_policy,claim, policy_search_nbr, dec_sequence
    from (
    select *
    from
    (
          select cmsclaimpolicy.*
                ,row_number() over (partition by Claim order by trunc(load_date) desc) cmsclaimpolicy_rowmax
          from DATALAKE.DAILY_CMS_CLAIM_POLICY cmsclaimpolicy
    ) where cmsclaimpolicy_rowmax=1) cp
    inner join( 
    select *
    from(
          select cmspolicy.*
                ,row_number() over (partition by cms_policy order by trunc(load_date) desc) cmspolicy_rowmax
          FROM DATALAKE.DAILY_CMS_POLICY CMSPOLICY) 
    where cmspolicy_rowmax=1) p
    on cp.cms_policy = p.cms_policy
),
totclaim as (
   select
      vc.claim, vc.policy, vc.dec_policy, pcclaim.policy_search_nbr, pcclaim.dec_sequence, vc.catastrophe
     ,vc.claim_number, vc.claim_prefix, vc.date_of_loss, vc.claim_description
     ,vc.claim_country, vc.claim_state, vc.claim_county, vc.claim_city, vc.claim_zipcode, vc.claim_location
     ,nvl(vcla.suit_status,'No Legal') as suit_status
     ,nvl(dcatastrophe.cat_number,'N/A') as cat_number
	 ,vc.claim_report_date,vc.claim_source  --AS-52
   from vc
      left outer join vcla on vc.claim = vcla.claim
      left outer join dcatastrophe on vc.catastrophe = dcatastrophe.catastrophe
      left outer join pcclaim on vc.claim = pcclaim.claim
),
--/*end claim level information*/
--/*cause level information*/
vcc as ( --HUB-552/553 sc
	SELECT CLAIMANT_COVERAGE, CLAIM, DEPT, cause_of_loss,CLAIM_SOURCE FROM (
      select claimant_coverage, claim, dept, cause_of_loss,CLAIM_SOURCE
            ,row_number() over (partition by claimant_coverage order by cc_trans_date desc) cc_rowmax
      FROM DLAKEDEV.VW_CLAIMANT_COVERAGE
    ) WHERE CC_ROWMAX=1
),
totcause as ( --HUB-552/553 sc
   SELECT
       vcc.claimant_coverage, vcc.claim, vcc.dept, col.CAUSE_OF_LOSS, col.CAUSE_NAME,vcc.CLAIM_SOURCE
      ,department.department_number, department.department_name
      ,department.business_line_name, department.major_line_name, department.core_line_of_business
   from vcc
      LEFT OUTER JOIN DATALAKE.BRVW_DEPARTMENT DEPARTMENT ON VCC.DEPT = DEPARTMENT.DEPT
      left join (
            SELECT CAUSE_OF_LOSS, CAUSE_NAME FROM (
            select cause_of_loss, cause_name
                  ,ROW_NUMBER() OVER (PARTITION BY CAUSE_OF_LOSS ORDER BY LOAD_DATE DESC) COL_ROWMAX
            FROM DATALAKE.DAILY_CAUSE_OF_LOSS 
          ) WHERE COL_ROWMAX=1
         union 
              SELECT CAUSE_OF_LOSS, CAUSE_NAME FROM (
            select TLLC.ID AS cause_of_loss, TLLC.TYPECODE AS cause_name
                  ,ROW_NUMBER() OVER (PARTITION BY TLLC.ID ORDER BY TLLC.LOAD_DATE DESC) CC_COL_ROWMAX
            FROM DLAKEDEV.DAILY_CCTL_LOSSCAUSE TLLC
          ) WHERE CC_COL_ROWMAX=1
      ) col on col.CAUSE_OF_LOSS = vcc.cause_of_loss
),
--/*end cause level information*/
--/*transaction level information*/
cms_ceded as 
(
select claimant_trans
         ,sum(loss_reserve) as ceded_caseos_loss
         ,sum(expense_reserve) as ceded_caseos_alae_dcc
         ,sum(ulae_reserve) as ceded_caseos_alae_ao
         ,sum(loss_paid) as ceded_paid_loss
         ,sum(expense_paid) as ceded_paid_alae_dcc
         ,sum(ulae_paid) as ceded_paid_alae_ao
   from DATALAKE.DAILY_CEDED_CLAIMANT_TRANS
   group by claimant_trans
),
cc_ceded AS(
            SELECT claimant_trans, SUM(ceded_paid_loss) AS ceded_paid_loss,SUM(ceded_paid_alae_dcc)AS ceded_paid_alae_dcc,
            SUM(ceded_caseos_loss) AS ceded_caseos_loss, SUM(ceded_caseos_alae_dcc) AS ceded_caseos_alae_dcc, 
            SUM(ceded_paid_alae_ao) AS ceded_paid_alae_ao , SUM(ceded_caseos_alae_ao) AS ceded_caseos_alae_ao
            FROM (
            SELECT 
                  RIT.CLAIMAMOUNT  AS CEDED_AMOUNT,
                  EX.ID AS claimant_trans,
                 CASE
                        WHEN TLRIT.name = 'RIRecoverable'
                             AND TLCSTTY.typecode IN( 'claimcost', 'dccexpense')  THEN 
                         ( RIT.CLAIMAMOUNT )
                    END                        AS ceded_paid_loss,                         
                    CASE
                        WHEN TLRIT.name = 'RIRecoverable'
                             AND TLCSTTY.typecode = 'dccexpense' THEN 
                            ( RIT.CLAIMAMOUNT )
                    END                        AS ceded_paid_alae_dcc,                         
                    CASE
                        WHEN TLRIT.name = 'RICededReserve'
                             AND TLCSTTY.typecode IN( 'claimcost', 'dccexpense')  THEN 
                         ( RIT.CLAIMAMOUNT )
                    END                        AS ceded_caseos_loss,                         
                    CASE
                        WHEN TLRIT.name = 'RICededReserve'
                             AND TLCSTTY.typecode = 'dccexpense' THEN 
                            ( RIT.CLAIMAMOUNT )
                    END                        AS ceded_caseos_alae_dcc  
                    , CASE
                        WHEN TLRIT.name = 'RIRecoverable'
                             AND TLCSTTY.typecode = 'aoexpense' THEN 
                            ( RIT.CLAIMAMOUNT )
                    END                        AS ceded_paid_alae_ao            
                    , CASE
                        WHEN TLRIT.name = 'RICededReserve'
                             AND TLCSTTY.typecode = 'aoexpense' THEN 
                            ( RIT.CLAIMAMOUNT )
                    END                        AS ceded_caseos_alae_ao
            from DLAKEDEV.DAILY_CC_CLAIM C
            INNER JOIN DLAKEDEV.DAILY_CC_EXPOSURE EX ON EX.CLAIMID=C.ID AND EX.RETIRED=0
            LEFT OUTER JOIN DLAKEDEV.DAILY_CC_RITRANSACTION         RIT ON RIT.CLAIMID = C.ID 
            LEFT OUTER JOIN DLAKEDEV.DAILY_CCTL_RITRANSACTION       TLRIT ON TLRIT.ID = RIT.SUBTYPE AND  TLRIT.RETIRED=0
            LEFT OUTER JOIN DLAKEDEV.DAILY_CCTL_COSTTYPE            TLCSTTY ON TLCSTTY.ID = RIT.COSTTYPE AND TLCSTTY.RETIRED = 0)
            GROUP BY claimant_trans
),
ceded AS 
(
SELECT * FROM cms_ceded
UNION ALL
select * from cc_ceded
),
-- pending is l_transtype fields
transfilter as (
   select distinct vcc.claim
   from (
      select distinct claimant_coverage
      from DATALAKE.VAR_CLAIMANT_TRANS
      where trunc(transaction_date) > add_months(last_day(trunc(sysdate)),-61)
   ) vct
      inner join vcc on vct.claimant_coverage = vcc.claimant_coverage
),
-- CC intg done in visual_load_datalake.sql and the feeding source is DATALAKE.VW_CLAIMANT_TRANS
-- pending is l_transtype fields
trans as (
   SELECT VCT3.CLAIM, VCT3.TRANSACTION_PRIMARY, VCT3.TRANSACTION_STATUS, VCT3.TRANSACTION_DATE
         ,vct3.dept, vct3.department_number, vct3.department_name, vct3.business_line_name, vct3.major_line_name, vct3.core_line_of_business, vct3.cause_name --HUB-552/553 sc
         ,sum(os_loss) as direct_caseos_loss, sum(os_alae) as direct_caseos_alae_dcc, sum(os_ulae) as direct_caseos_alae_ao
         ,sum(paid_loss) as direct_paid_loss, sum(paid_alae) as direct_paid_alae_dcc, sum(paid_ulae) as direct_paid_alae_ao
         ,sum(ceded_caseos_loss) as ceded_caseos_loss
         ,sum(ceded_caseos_alae_dcc) as ceded_caseos_alae_dcc, sum(ceded_caseos_alae_ao) as ceded_caseos_alae_ao
         ,sum(ceded_paid_loss) as ceded_paid_loss
         ,sum(ceded_paid_alae_dcc) as ceded_paid_alae_dcc, sum(ceded_paid_alae_ao) as ceded_paid_alae_ao
   from (
      SELECT VCT2.*, TOTCAUSE.CLAIM, TOTCAUSE.DEPT
            ,totcause.department_number, totcause.department_name, totcause.business_line_name, totcause.major_line_name, totcause.core_line_of_business, totcause.cause_name--HUB-552/553 sc
      from (
         select vct.claimant_trans, vct.claimant_coverage, vct.transaction_primary, vct.transaction_status, vct.transaction_date
               ,vct.os_loss, vct.os_alae, vct.os_ulae, vct.paid_loss, vct.paid_alae, vct.paid_ulae
               ,ceded.ceded_caseos_loss, ceded.ceded_caseos_alae_dcc, ceded.ceded_caseos_alae_ao, ceded.ceded_paid_loss, ceded.ceded_paid_alae_dcc, ceded.ceded_paid_alae_ao
         from DATALAKE.VAR_CLAIMANT_TRANS vct
            left outer join ceded on vct.claimant_trans = ceded.claimant_trans
      ) vct2 inner join totcause on vct2.claimant_coverage = totcause.claimant_coverage
   ) vct3
      INNER JOIN TRANSFILTER ON VCT3.CLAIM = TRANSFILTER.CLAIM
   group by vct3.claim, vct3.transaction_primary, vct3.transaction_status, vct3.transaction_date
         ,vct3.dept, vct3.department_number, vct3.department_name, vct3.business_line_name, vct3.major_line_name, vct3.core_line_of_business, VCT3.CAUSE_NAME--HUB-552/553 sc
)
,ceded_correct as (
select 
vc.dec_policy
,vc.claim
,vcc.dept
,pcclaim.policy_search_nbr
,pcclaim.dec_sequence
,ceded.trans_date as transaction_date
,department.department_number
,department.department_name
,department.business_line_name
,department.major_line_name
,department.core_line_of_business
,ceded.cause_of_loss as cause_name
,vc.claim_number
,vc.claim_prefix
,vc.date_of_loss
,vc.claim_description
,vc.claim_country
,vc.claim_state
,vc.claim_county 
,vc.claim_city 
,vc.claim_zipcode 
,vc.claim_location 
,vcla.suit_status
,dcatastrophe.cat_number
,transtype.transaction_primary
,to_char(transtype.transaction_status) as transaction_status
,-(ceded.loss_reserve-ceded.loss_paid) as direct_caseos_loss 
,-(ceded.alloc_expense_reserve-ceded.alloc_expense_paid) as direct_caseos_alae_dcc 
,-(ceded.unalloc_expense_reserve-ceded.unalloc_expense_paid) as direct_caseos_alae_ao 
,-(ceded.alloc_expense_reserve-ceded.alloc_expense_paid+ceded.unalloc_expense_reserve-ceded.unalloc_expense_paid) as direct_caseos_alae 
,-(ceded.loss_paid) as direct_paid_loss 
,-(ceded.alloc_expense_paid) as direct_paid_alae_dcc 
,-(ceded.unalloc_expense_paid) as direct_paid_alae_ao 
,-(ceded.alloc_expense_paid+ceded.unalloc_expense_paid) as direct_paid_alae 
,-(ceded.ceded_loss_reserve) as ceded_caseos_loss 
,-(ceded.ceded_expense_reserve) as ceded_caseos_alae_dcc 
,-(ceded.ceded_ulae_reserve) as ceded_caseos_alae_ao 
,-(ceded.ceded_expense_reserve+ceded.ceded_ulae_reserve) as ceded_caseos_alae  
,-(ceded.ceded_loss_paid) as ceded_paid_loss
,-(ceded.ceded_expense_paid) as ceded_paid_alae_dcc 
,-(ceded.ceded_ulae_paid) as ceded_paid_alae_ao
,-(ceded.ceded_expense_paid+ceded.ceded_ulae_paid) as ceded_paid_alae 
,1 as is_ceded_correction
,vc.claim_report_date  --AS-52
,vcla.claim_source
from ceded_corrections ceded 
left join vc on vc.claim = ceded.claim_key
left join (select claim, dept from vcc group by claim, dept)vcc on vcc.claim = ceded.claim_key
left join vcla on vcla.claim = ceded.claim_key
left join dcatastrophe on vc.catastrophe = dcatastrophe.catastrophe
left join datalake.brvw_department department on vcc.dept = department.dept
left join pcclaim on vc.claim = pcclaim.claim
left join datalake.l_transtype transtype on transtype.trans_type = ceded.trans_type
)
,alltrans as (
select totclaim.dec_policy, totclaim.claim, trans.dept, totclaim.policy_search_nbr, totclaim.dec_sequence
         ,trans.transaction_date
         ,trans.department_number, trans.department_name, trans.business_line_name, trans.major_line_name, trans.core_line_of_business, trans.cause_name--hub-552/553 sc
         ,totclaim.claim_number, totclaim.claim_prefix, totclaim.date_of_loss, totclaim.claim_description
         ,totclaim.claim_country, totclaim.claim_state, totclaim.claim_county, totclaim.claim_city, totclaim.claim_zipcode, totclaim.claim_location
         ,totclaim.suit_status, totclaim.cat_number
         ,trans.transaction_primary, to_char(trans.transaction_status) as transaction_status
         ,trans.direct_caseos_loss, trans.direct_caseos_alae_dcc, trans.direct_caseos_alae_ao
         ,(trans.direct_caseos_alae_dcc + trans.direct_caseos_alae_ao) as direct_caseos_alae
         ,trans.direct_paid_loss, trans.direct_paid_alae_dcc, trans.direct_paid_alae_ao
         ,(trans.direct_paid_alae_dcc + trans.direct_paid_alae_ao) as direct_paid_alae
         ,-nvl(trans.ceded_caseos_loss,0) as ceded_caseos_loss, -nvl(trans.ceded_caseos_alae_dcc,0) as ceded_caseos_alae_dcc
         ,-nvl(trans.ceded_caseos_alae_ao,0) as ceded_caseos_alae_ao
         ,-nvl(trans.ceded_caseos_alae_dcc + trans.ceded_caseos_alae_ao,0) as ceded_caseos_alae
         ,-nvl(trans.ceded_paid_loss,0) as ceded_paid_loss, -nvl(trans.ceded_paid_alae_dcc,0) as ceded_paid_alae_dcc
         ,-nvl(trans.ceded_paid_alae_ao,0) as ceded_paid_alae_ao
         ,-nvl(trans.ceded_paid_alae_dcc + trans.ceded_paid_alae_ao,0) as ceded_paid_alae
         ,0 as is_ceded_correction
		 ,totclaim.claim_report_date , totclaim.claim_source --AS-52
   from totclaim
      inner join trans on totclaim.claim = trans.claim
) 
select * from alltrans
  union all
select * from ceded_correct
;