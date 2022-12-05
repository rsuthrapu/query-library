/* create plan data table
create table DATALAKE.REPORT_DAILYPRODUCTION_PLAN as
select 'plan' as source
      ,region, core_line_of_business
      ,daily_booked_date, monthly_booked_date, entry_date, trunc(sysdate)-1 as valuation_date
      ,booked_premium_plan
from DATALAKE.L_2016PLAN
;
 end plan data table */
/* create polmast */
exec DBMS_SNAPSHOT.REFRESH( 'BRVW_MASTER_AGENCY','c'); 
exec DBMS_SNAPSHOT.REFRESH( 'PCVW_POLICYPERIOD','c');
truncate table DATALAKE.VWM_POLMAST_ECIG reuse storage;
insert /*+ APPEND_VALUES */ into DATALAKE.VWM_POLMAST_ECIG
   select decpol.dec_policy, decpol.policy
         ,case when dp11.renewed_from is not null and dp11.policy_search_nbr <> dp22.policy_search_nbr then 'Y' else '' END as RENEWED_FROM_FLAG
         ,case when dp11.renewed_from is not null and dp11.policy_search_nbr <> dp22.policy_search_nbr and dp22.quote_flag = '1' then 'Q' 
               when dp11.renewed_from is not null and dp11.policy_search_nbr <> dp22.policy_search_nbr and  dp22.quote_flag <> '1' then  'P' 
               else '' END as RENEWED_FROM_QUOTE_FLAG
         ,decpol.dec_sequence, decpol.term_nbr
         ,decpol.policy_search_nbr as policy_number, decpol.legal_name as insured_name
         ,decpol.writing_company, decpol.dec_type, l.policy_transaction_type
         ,decpol.begin_date as transaction_effective_date, decpol.end_date as transaction_expiration_date
         ,DECPOL.TERM_EFFECTIVE_DATE, DECPOL.TERM_EXPIRATION_DATE, DECPOL.ORIGINAL_INCEPTION_DATE
         ,case when DECPOL.INSURED_STREET_NAME is null and DECPOL.INSURED_PO is not null and LOWER(decpol.INSURED_PO) not like '%box%' then 'P.O. Box ' || TRIM(decpol.INSURED_PO)
               when decpol.insured_street_name is null and decpol.insured_po is not null then trim(decpol.insured_po)
               else trim(
                         NVL2(DECPOL.INSURED_ADDR_NBR, CONCAT(TRIM(DECPOL.INSURED_ADDR_NBR), ' '), null) ||
                         NVL2(DECPOL.INSURED_PREFIX, CONCAT(TRIM(DECPOL.INSURED_PREFIX), ' '), null) ||
                         nvl2(decpol.insured_street_name, concat(trim(decpol.insured_street_name), ' '), NULL) ||
                         trim(decpol.insured_suffix)
						 )
               end as insured_address_line1
         ,decpol.insured_suite as insured_address_line2
         ,decpol.insured_city, decpol.insured_state, decpol.insured_zipcode
         ,decpol.quote_flag 
         ,AGENCY.*
   from (
      select /*+ ORDERED */  *
         from (
            select decpol.*, row_number() over (partition by dec_policy order by load_date desc) decpol_rowmax
            from datalake.DAILY_DEC_POLICY decpol
              )
        where DECPOL_ROWMAX=1
      ) decpol
   inner join (
          select * from DATALAKE.DEC_CURRENT_POLICY 
              ) CURRPOL on decpol.DEC_POLICY = currpol.DEC_POLICY
   left outer join DATALAKE.BRVW_MASTER_AGENCY agency on decpol.agency_code = agency.agency_code
   left outer join DATALAKE.L_POLICY_TRANSACTION_TYPE l on decpol.dec_type = l.dec_type
   left outer join (select  * from (select dp1.*, row_number() over (partition by policy order by load_date desc) dp_rowmax 
                    from DATALAKE.DAILY_POLICY dp1 ) where dp_rowmax=1) dp11 on  decpol.policy = dp11.policy
   left outer join (select  * from (select dp2.*, row_number() over (partition by policy order by load_date desc) dp_rowmax 
                    from DATALAKE.DAILY_POLICY dp2 ) where dp_rowmax=1) dp22 on  dp11.renewed_from = dp22.policy;
commit;
truncate table DATALAKE.VWM_POLMAST_POLICYCENTER reuse storage;
insert /*+ APPEND_VALUES */ into DATALAKE.VWM_POLMAST_POLICYCENTER
   select pp.period_id as dec_policy, NULL as policy 
 ,case when pp1.basedonid is not null and pp1.policynumber  <> pp2.policynumber  then 'Y' else '' END as RENEWED_FROM_FLAG
 ,case when pp1.basedonid is not null and pp1.policynumber  <> pp2.policynumber 
       and  pp2.period_status in('New','Draft','Quoted','Renewing','Temporary','NotTaking','NotTaken','Rescinded','Withdrawn','Declined','Expired','Canceling
')   then 'Q' 
       when pp1.basedonid is not null and pp1.policynumber  <> pp2.policynumber  and pp2.period_status 
       in('Bound','NonRenewing','NonRenewed') then  'P' 
       else '' END as RENEWED_FROM_QUOTE_FLAG	
         ,pp.policyModelNumber as dec_sequence, pp.termnumber as term_nbr 
         ,pp.policyNumber as policy_number, pp.primaryinsuredname as insured_name
         ,pp.underwritingcompany as writing_company, pp.jobtype as dec_type, l.policy_transaction_type
         ,trunc(pp.editeffectivedate) as transaction_effective_date, trunc(pp.periodend) as transaction_expiration_date
         ,trunc(pp.periodstart) as term_effective_date, trunc(pp.periodend) as term_expiration_date
         ,trunc(pp.originalinceptiondate) as original_inception_date
         ,pp.addressline1 as insured_address_line1
         ,pp.addressline2 as insured_address_line2
         ,pp.city as insured_city, pp.state as insured_state, pp.zipcode as insured_zipcode
         ,case when pp.period_status = 'Bound' and pp.dummy is null then 0 else 1 end as quote_flag 
         ,agency.*
   from DATALAKE.PCVW_POLICYPERIOD pp
      left outer join DATALAKE.BRVW_MASTER_AGENCY agency on pp.periodagencycode = agency.agency_code
      left outer join DATALAKE.L_POLICY_TRANSACTION_TYPE l on pp.jobtype = l.dec_type
      left outer join DATALAKE.PCVW_POLICYPERIOD pp1 on pp.policynumber = pp1.policynumber and pp.period_id = pp1.period_id
      left outer join DATALAKE.PCVW_POLICYPERIOD pp2 on pp1.basedonid   = pp2.period_id ;
commit;
--/* end create polmast */
--/* premium insert */
drop table DATALAKE.REPORT_DAILYPRODUCTION_PREM;
create table DATALAKE.REPORT_DAILYPRODUCTION_PREM as
--/*real primary key is dec_policy, premium_transaction_type, effective_date*/
--/*errors add the following fields to the primary key - entry date and department, very few additional records*/
--/*each row is a transaction, no transaction key included*/
with prem as (
   select policy, dec_policy, dept, premium_transaction_type
         ,daily_booked_date, monthly_booked_date, entry_date
         ,department_number, department_name, business_line_name, major_line_name, core_line_of_business
         ,sum(source_written_premium) as source_written_premium
         ,sum(source_inforce_premium) as source_inforce_premium
         ,sum(source_written_commission) as source_written_commission
   from (
      select prem.policy, prem.dec_policy, prem.dept
            ,prem.trans_type as premium_transaction_type
            ,case when trunc(prem.first_modified) > trunc(prem.trans_date) then trunc(prem.first_modified)
                  else trunc(prem.trans_date)
             end daily_booked_date
            ,case when (to_char(trunc(prem.first_modified),'mm') != to_char(trunc(prem.trans_date),'mm') or
                        to_char(trunc(prem.first_modified),'yyyy') != to_char(trunc(prem.trans_date),'yyyy')) and
                       trunc(prem.first_modified) < trunc(prem.trans_date)
                  then add_months(last_day(trunc(prem.trans_date))+1,-1)
                  when prem.trans_date is null then null
                  else trunc(prem.first_modified)
             end monthly_booked_date
            ,trunc(prem.first_modified) as entry_date
            ,department.department_number, department.department_name
            ,department.business_line_name, department.major_line_name, department.core_line_of_business
            ,prem.written_prem as source_written_premium
            ,prem.inforce_prem_change as source_inforce_premium
            ,prem.commission_amt as source_written_commission
      from (
         select *
         from (select prem.*, row_number() over (partition by prem order by load_date desc) prem_rowmax
               from DATALAKE.DAILY_PREM prem
               where trunc(trans_date) > add_months(last_day(trunc(sysdate)),-61) or trunc(first_modified) > add_months(last_day(trunc(sysdate)),-61)
              )
         where prem_rowmax=1
         ) prem
             inner join DATALAKE.BRVW_DEPARTMENT department on prem.dept = department.dept
   )
   group by policy, dec_policy, dept, premium_transaction_type
         ,daily_booked_date, monthly_booked_date, entry_date
         ,department_number, department_name, business_line_name, major_line_name, core_line_of_business
)
   select 'ecig' as source, polmast.policy_number, polmast.RENEWED_FROM_FLAG, polmast.RENEWED_FROM_QUOTE_FLAG 
         ,to_char(polmast.dec_sequence) as dec_sequence, polmast.term_nbr 
         ,polmast.insured_name, polmast.writing_company
         ,polmast.dec_type, polmast.policy_transaction_type
         ,polmast.transaction_effective_date, polmast.transaction_expiration_date
         ,polmast.term_effective_date, polmast.term_expiration_date, polmast.original_inception_date
         ,polmast.insured_address_line1, polmast.insured_address_line2
         ,polmast.insured_city, polmast.insured_state, polmast.insured_zipcode
         ,to_char(polmast.agency_code) as agency_code, polmast.agency_name, polmast.domicile_state
         ,case when polmast.customer_service_center_pl=1 then 'Y' else 'N' end as customer_service_center_pl
         ,case when polmast.customer_service_center_cl=1 then 'Y' else 'N' end as customer_service_center_cl
         ,polmast.current_agency_status, polmast.current_agency_status_date
         ,polmast.current_agency_status_pl, polmast.current_agency_status_cl, polmast.current_agency_status_fm
         ,polmast.agency_state, polmast.agency_county, polmast.agency_city, polmast.agency_zipcode, polmast.agency_address_type
         ,to_char(polmast.branch_number) as branch_number, polmast.branch_name
		 
		 ,CASE --,polmast.region : AS-492 adding new region logic based on agency_code/dept : sc 20200807
              WHEN to_char(prem.department_number) = '115' OR gp.policy_search_nbr IS NOT NULL
                THEN 'Golf Program'
			  when (polmast.agency_code in (26728,27708,66004,66028,66501,66580,71508,26730) 			
					and to_char(prem.department_number) not in (10,15,21,40,50,71)) 
				then 'Other' --'Alternative Markets Programs'			    
			  when to_char(prem.department_number) in (115,119)  
				then 'Other' --'Alternative Markets Programs'
              ELSE polmast.region 
		  END region
		 
         ,to_char(polmast.parent_agency) as parent_agency, to_char(polmast.parent_agency_code) as parent_agency_code, polmast.parent_name
         ,polmast.cluster_name, polmast.master_code, polmast.master_name, polmast.master_location
         ,polmast.agency_development_manager, polmast.commercial_underwriter, polmast.farm_underwriter, polmast.personal_underwriter
         ,case when prem.core_line_of_business='Commercial' then polmast.commercial_underwriter
               when prem.core_line_of_business='Farm' then polmast.farm_underwriter
               when prem.core_line_of_business='Personal' then polmast.personal_underwriter
          end as underwriter
         ,polmast.master_tier, to_char(polmast.agency_tier_2014) as agency_tier_2014, to_char(polmast.agency_tier_2015) as agency_tier_2015
         ,polmast.agency, prem.policy, prem.dec_policy, prem.dept     
         ,prem.daily_booked_date, prem.monthly_booked_date, prem.entry_date, trunc(sysdate)-1 as valuation_date
         ,to_char(prem.department_number) as department_number, prem.department_name, prem.business_line_name, prem.major_line_name, prem.core_line_of_business
         ,prem.premium_transaction_type
         ,prem.source_written_premium, prem.source_inforce_premium, prem.source_written_commission,    pln.plan_growth_pct
   from prem inner join (select * from DATALAKE.VWM_POLMAST_ECIG where quote_flag=0) polmast on prem.dec_policy = polmast.dec_policy
         left join (select DISTINCT PLAN_GROWTH_PCT, TO_CHAR(Daily_booked_date,'YYYY') pln_year, business_line_name, REGION 
               FROM DATALAKE.REPORT_DAILYPRODUCTION_PLAN ) pln 
              on (to_char(prem.daily_booked_date,'YYYY') =  pln.pln_year 
      and prem.business_line_name = pln.business_line_name
      and polmast.region = pln.region)
	LEFT JOIN DATALAKE.GOLF_PROGRAM_2017 gp on polmast.policy_number = gp.policy_search_nbr --AS-492
;
insert into DATALAKE.REPORT_DAILYPRODUCTION_PREM
with prem as (
   select transplus2.branchid
         ,transplus2.daily_booked_date, transplus2.monthly_booked_date, transplus2.entry_date
         ,transplus2.department_number, dept.department_name, dept.business_line_name, dept.major_line_name, dept.core_line_of_business
         ,sum(transplus2.amountbilling) as source_written_premium
   from (
      select transplus.*, nvl(ca7.department_number, nvl(bp7.department_number, cup7.department_number)) as department_number
      from (
         select trans.transaction_id, trans.branchid, trans.bp7classcode, trans.amountbilling
               ,pp.lineofbusiness
               ,case when pp.jobclosedate is null then NULL
                     when trunc(pp.jobclosedate) > trunc(pp.editeffectivedate) then trunc(pp.jobclosedate) else trunc(pp.editeffectivedate)
                     end as daily_booked_date
               ,case when pp.jobclosedate is null then NULL
                     when (to_char(trunc(pp.jobclosedate),'mm') != to_char(trunc(pp.editeffectivedate),'mm') or
                           to_char(trunc(pp.jobclosedate),'yyyy') != to_char(trunc(pp.editeffectivedate),'yyyy')) and
                                   trunc(pp.jobclosedate) < trunc(pp.editeffectivedate)
                        then add_months(last_day(trunc(pp.editeffectivedate))+1,-1)
                     else trunc(pp.jobclosedate)
                     end as monthly_booked_date
               ,trunc(pp.jobclosedate) as entry_date
               ,case when pp.lineofbusiness='CA7Line' then pp.policytype else NULL end as ca7policytype
               ,SUBSTR(PP.POLICYNUMBER,INSTR(PP.POLICYNUMBER,'-', 1, 1)+1,3) as POLICY_PREFIX
               ,case when pp.lineofbusiness='CommercialUmbrellaLine_CUE' then pp.policytype else null end as cupolicytype   /*Update-11/13/17: added to include Commercial Umbrella - sc*/
         from (
            select transaction_id, branchid, bp7classcode, amountbilling from DATALAKE.PCVW_BP7TRANSBUILDINGCLASS
               union
            select transaction_id, branchid, bp7classcode, amountbilling from DATALAKE.PCVW_BP7TRANSCOVERAGE
               union
            select transaction_id, branchid, bp7classcode, amountbilling from DATALAKE.PCVW_BP7TRANSLOCATION
               union
            select id as TRANSACTION_ID, BRANCHID, null as BP7CLASSCODE, AMOUNTBILLING from DATALAKE.PCX_CA7TRANSACTION
               union
            select id as transaction_id, branchid, NULL as bp7classcode, amountbilling from DATALAKE.PCX_CUPTRANSACTION_CUE   /*Update-11/13/17: added to include Commercial Umbrella - sc*/
         ) trans
            inner join DATALAKE.PCVW_POLICYPERIOD pp on trans.branchid = pp.period_id
      ) transplus
         left join (
            select *
            from (select dept.*, row_number() over (partition by prefix, pc_class_code order by effective_date desc) row_max
                  from DATALAKE.BRVW_BP7DEPT dept
                 )
            where row_max = 1
            ) bp7 on transplus.policy_prefix = bp7.prefix
                 and transplus.bp7classcode = bp7.pc_class_code
         left join DATALAKE.L_CA7DEPT CA7 on TRANSPLUS.CA7POLICYTYPE = CA7.CA7POLICYTYPE
         left join DATALAKE.L_CUPDEPT cup7 on transplus.cupolicytype = cup7.cuppolicytype    /*Update-11/13/17: added to include Commercial Umbrella - sc*/
   ) transplus2
      left join (
         select *
         from (select dept.*, row_number() over (partition by department_number order by business_line desc) row_max
               from DATALAKE.BRVW_DEPARTMENT dept
              )
         where row_max = 1
         ) dept on transplus2.department_number = dept.department_number
   group by transplus2.branchid
         ,transplus2.daily_booked_date, transplus2.monthly_booked_date, transplus2.entry_date
         ,transplus2.department_number, dept.department_name, dept.business_line_name, dept.major_line_name, dept.core_line_of_business
)
   select 'pc' as source, polmast.policy_number, polmast.RENEWED_FROM_FLAG, polmast.RENEWED_FROM_QUOTE_FLAG, 
          to_char(polmast.dec_sequence) as dec_sequence, polmast.term_nbr 
         ,polmast.insured_name, polmast.writing_company
         ,polmast.dec_type, polmast.policy_transaction_type
         ,polmast.transaction_effective_date, polmast.transaction_expiration_date
         ,polmast.term_effective_date, polmast.term_expiration_date, polmast.original_inception_date
         ,polmast.insured_address_line1, polmast.insured_address_line2
         ,polmast.insured_city, polmast.insured_state, polmast.insured_zipcode
         ,to_char(polmast.agency_code) as agency_code, polmast.agency_name, polmast.domicile_state
         ,case when polmast.customer_service_center_pl=1 then 'Y' else 'N' end as customer_service_center_pl
         ,case when polmast.customer_service_center_cl=1 then 'Y' else 'N' end as customer_service_center_cl
         ,polmast.current_agency_status, polmast.current_agency_status_date
         ,polmast.current_agency_status_pl, polmast.current_agency_status_cl, polmast.current_agency_status_fm
         ,polmast.agency_state, polmast.agency_county, polmast.agency_city, polmast.agency_zipcode, polmast.agency_address_type
         ,to_char(polmast.branch_number) as branch_number, polmast.branch_name
		 
		 ,CASE --,polmast.region : AS-492 adding new region logic based on agency_code/dept : sc 20200807
              WHEN to_char(prem.department_number) = '115' OR gp.policy_search_nbr IS NOT NULL
                THEN 'Golf Program'
			  when (polmast.agency_code in (26728,27708,66004,66028,66501,66580,71508,26730) 			
					and to_char(prem.department_number) not in (10,15,21,40,50,71)) 
				then 'Other' --'Alternative Markets Programs'			    
			  when to_char(prem.department_number) in (115,119)  
				then 'Other' --'Alternative Markets Programs'
              ELSE polmast.region 
		  END region
		 
         ,to_char(polmast.parent_agency) as parent_agency, to_char(polmast.parent_agency_code) as parent_agency_code, polmast.parent_name
         ,polmast.cluster_name, polmast.master_code, polmast.master_name, polmast.master_location
         ,polmast.agency_development_manager, polmast.commercial_underwriter, polmast.farm_underwriter, polmast.personal_underwriter
         ,case when prem.core_line_of_business='Commercial' then polmast.commercial_underwriter
               when prem.core_line_of_business='Farm' then polmast.farm_underwriter
               when prem.core_line_of_business='Personal' then polmast.personal_underwriter
          end as underwriter
         ,polmast.master_tier, to_char(polmast.agency_tier_2014) as agency_tier_2014, to_char(polmast.agency_tier_2015) as agency_tier_2015
         ,polmast.agency, polmast.policy, polmast.dec_policy, NULL as dept       
         ,prem.daily_booked_date, prem.monthly_booked_date, prem.entry_date, trunc(sysdate)-1 as valuation_date
         ,to_char(prem.department_number) as department_number, prem.department_name, prem.business_line_name, prem.major_line_name, prem.core_line_of_business
         ,NULL as premium_transaction_type
         ,prem.source_written_premium, 0 as source_inforce_premium, 0 as source_written_commission, pln.PLAN_GROWTH_PCT
   from prem inner join (select * from DATALAKE.VWM_POLMAST_POLICYCENTER where quote_flag=0) polmast on prem.branchid = polmast.dec_policy
         and trunc(daily_booked_date) > add_months(last_day(trunc(sysdate)),-61)
         left join (select DISTINCT PLAN_GROWTH_PCT, TO_CHAR(Daily_booked_date,'YYYY') pln_year, business_line_name, REGION 
               FROM DATALAKE.REPORT_DAILYPRODUCTION_PLAN ) pln 
              on (to_char(prem.daily_booked_date,'YYYY') =  pln.pln_year 
      and prem.business_line_name = pln.business_line_name
      and polmast.region = pln.region)
	LEFT JOIN DATALAKE.GOLF_PROGRAM_2017 gp on polmast.policy_number = gp.policy_search_nbr --AS-492
; 
 commit;
--/* end premium insert */
--/* create temp claim transaction file with attributes */
--/*claim level information*/
create table DATALAKE.TEMP_CLAIMTRANS as
WITH DCLAIM AS (
    select *
    from (
      SELECT VWCLAIM.*
            ,row_number() over (partition by claim order by load_date desc) claimlookup_rowmax
      from DATALAKE.DAILY_CLAIM vwclaim
   ) 
   where claimlookup_rowmax=1
),
-- INTEGRATED CC DATA INTO VW_CLAIM
vc as (
   select claim, policy, dec_policy, catastrophe
        ,claim_number, claim_prefix, date_of_loss, claim_description
        ,CLAIM_COUNTRY, CLAIM_STATE, CLAIM_COUNTY, CLAIM_CITY, CLAIM_ZIPCODE, CLAIM_LOCATION
        ,first_modified as claim_report_date --AS-52
   from (
      SELECT VWCLAIM.*
            ,ROW_NUMBER() OVER (PARTITION BY VWCLAIM.CLAIM ORDER BY VWCLAIM.C_TRANS_DATE DESC) CLAIMLOOKUP_ROWMAX
            ,dclaim.first_modified
      FROM DATALAKE.VW_CLAIM VWCLAIM
      left join DCLAIM on DCLAIM.claim = vwclaim.claim
   ) 
   where claimlookup_rowmax=1
),
-- vcla as (
--    select claim, suit_status
--    from (
--       select claim, cms_suit_status
--       from (
--          select claim, cms_suit_status
--             ,row_number() over (partition by claim order by legal_trans_date desc) legal_rowmax
--          from DATALAKE.VW_CMS_LEGAL_ACTION
--        ) where legal_rowmax=1) legal
--          left outer join (
--       select cms_suit_status, suit_status
--       from (
--          select cms_suit_status, suit_status_desc as suit_status
--                ,row_number() over (partition by cms_suit_status order by trunc(last_modified) desc) suitstatus_rowmax
--          from DATALAKE.DAILY_CMS_SUIT_STATUS
--       ) where suitstatus_rowmax=1) status on legal.cms_suit_status = status.cms_suit_status
-- ),

-- CC INTRAGED . NEED TO CLARIFY ON VW_CMS_LEGAL_ACTION FIELDS W.R.T CC
vcla as (
   select claim, suit_status
   from (
      select claim, cms_suit_status
      from (
         select claim, cms_suit_status
            ,row_number() over (partition by claim order by legal_trans_date desc) legal_rowmax
         from DATALAKE.VW_CMS_LEGAL_ACTION
       ) where legal_rowmax=1) legal
         left outer join (
      select cms_suit_status, suit_status
      from (
         select cms_suit_status, suit_status_desc as suit_status
               ,row_number() over (partition by cms_suit_status order by trunc(last_modified) desc) suitstatus_rowmax
         from DATALAKE.DAILY_CMS_SUIT_STATUS) where suitstatus_rowmax=1
         UNION 
        select cms_suit_status, suit_status
          from (
         select ID AS cms_suit_status
         , CASE WHEN FINALSETTLEDATE IS NOT NULL
                        Then 'Close'
                        ELSE 'Open'
                      END suit_status
               ,row_number() over (partition by ID order by trunc(UPDATETIME) desc) cc_suitstatus_rowmax
         from DAILY_CC_MATTER) where cc_suitstatus_rowmax=1) status
         on legal.cms_suit_status = status.cms_suit_status
),
-- dcatastrophe as (
--    select catastrophe, cat_no as cat_number
--    from (
--       select dcatastrophe.*
--             ,row_number() over (partition by catastrophe order by trunc(last_modified) desc) catastrophe_rowmax
--       from DATALAKE.DAILY_CATASTROPHE dcatastrophe
--    ) where catastrophe_rowmax=1
-- ),
WITH CMS_dcatastrophe as (
   select catastrophe, cat_no as cat_number
   from (
      select dcatastrophe.*
            ,row_number() over (partition by catastrophe order by trunc(last_modified) desc) catastrophe_rowmax
      from DATALAKE.DAILY_CATASTROPHE dcatastrophe
   ) where catastrophe_rowmax=1
),
CC_dcatastrophe AS 
(
   select ID AS catastrophe, CATASTROPHENUMBER as cat_number
   from (
      select ccdcatastrophe.*
            ,row_number() over (partition by ID order by trunc(UPDATETIME) desc) cc_catastrophe_rowmax
      from DATALAKE.DAILY_CC_CATASTROPHE ccdcatastrophe
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
	 ,vc.claim_report_date  --AS-52
   from vc
      left outer join vcla on vc.claim = vcla.claim
      left outer join dcatastrophe on vc.catastrophe = dcatastrophe.catastrophe
      left outer join pcclaim on vc.claim = pcclaim.claim
),
--/*end claim level information*/
--/*cause level information*/
-- INTEGRATED WITH CC
vcc as ( --HUB-552/553 sc
	SELECT CLAIMANT_COVERAGE, CLAIM, DEPT, cause_of_loss FROM (
      select claimant_coverage, claim, dept, cause_of_loss
            ,row_number() over (partition by claimant_coverage order by cc_trans_date desc) cc_rowmax
      FROM DATALAKE.VW_CLAIMANT_COVERAGE
    ) WHERE CC_ROWMAX=1
),
-- -- INTEGRATED WITH CC. PENDING BRVW_DEPARTMENT
totcause as ( --HUB-552/553 sc
   SELECT
       vcc.claimant_coverage, vcc.claim, vcc.dept, col.CAUSE_OF_LOSS, col.CAUSE_NAME
      ,department.department_number, department.department_name
      ,department.business_line_name, department.major_line_name, department.core_line_of_business
   from vcc
      LEFT OUTER JOIN DATALAKE.BRVW_DEPARTMENT DEPARTMENT ON VCC.DEPT = DEPARTMENT.DEPT
      left join (
      --     SELECT CAUSE_OF_LOSS, CAUSE_NAME FROM (
      --       select cause_of_loss, cause_name
      --             ,ROW_NUMBER() OVER (PARTITION BY CAUSE_OF_LOSS ORDER BY LOAD_DATE DESC) COL_ROWMAX
      --       FROM DATALAKE.DAILY_CAUSE_OF_LOSS 
      --     ) WHERE COL_ROWMAX=1
           SELECT CAUSE_OF_LOSS, CAUSE_NAME FROM (
            select cause_of_loss, cause_name
                  ,ROW_NUMBER() OVER (PARTITION BY CAUSE_OF_LOSS ORDER BY LOAD_DATE DESC) COL_ROWMAX
            FROM DATALAKE.DAILY_CAUSE_OF_LOSS 
          ) WHERE COL_ROWMAX=1
         union 
              SELECT CAUSE_OF_LOSS, CAUSE_NAME FROM (
            select TLLC.ID AS cause_of_loss, TLLC.TYPECODE AS cause_name
                  ,ROW_NUMBER() OVER (PARTITION BY TLLC.ID ORDER BY TLLC.LOAD_DATE DESC) CC_COL_ROWMAX
            FROM DATALAKE.DAILY_CCTL_LOSSCAUSE TLLC
          ) WHERE CC_COL_ROWMAX=1
      ) col on col.CAUSE_OF_LOSS = vcc.cause_of_loss
),
--/*end cause level information*/
--/*transaction level information*/
-- ceded as (
--    select claimant_trans
--          ,sum(loss_reserve) as ceded_caseos_loss
--          ,sum(expense_reserve) as ceded_caseos_alae_dcc
--          ,sum(ulae_reserve) as ceded_caseos_alae_ao
--          ,sum(loss_paid) as ceded_paid_loss
--          ,sum(expense_paid) as ceded_paid_alae_dcc
--          ,sum(ulae_paid) as ceded_paid_alae_ao
--    from DATALAKE.DAILY_CEDED_CLAIMANT_TRANS
--    group by claimant_trans
-- ),
with cms_ceded as 
(
select claimant_trans
         ,sum(loss_reserve) as ceded_caseos_loss
         ,sum(expense_reserve) as ceded_caseos_alae_dcc
         ,sum(ulae_reserve) as ceded_caseos_alae_ao
         ,sum(loss_paid) as ceded_paid_loss
         ,sum(expense_paid) as ceded_paid_alae_dcc
         ,sum(ulae_paid) as ceded_paid_alae_ao
   from CEDED_CLAIMANT_TRANS
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
            from DATALAKE.DAILY_CC_CLAIM@ECIG_TO_CC_LINK C
            INNER JOIN DATALAKE.DAILY_CC_EXPOSURE@ECIG_TO_CC_LINK EX ON EX.CLAIMID=C.ID AND EX.RETIRED=0
            LEFT OUTER JOIN DATALAKE.DAILY_CC_RITRANSACTION@ECIG_TO_CC_LINK         RIT ON RIT.CLAIMID = C.ID 
            LEFT OUTER JOIN DATALAKE.DAILY_CCTL_RITRANSACTION@ECIG_TO_CC_LINK       TLRIT ON TLRIT.ID = RIT.SUBTYPE AND  TLRIT.RETIRED=0
            LEFT OUTER JOIN DATALAKE.DAILY_CCTL_COSTTYPE@ECIG_TO_CC_LINK            TLCSTTY ON TLCSTTY.ID = RIT.COSTTYPE AND TLCSTTY.RETIRED = 0)
            GROUP BY claimant_trans
),
ceded AS 
(
SELECT * FROM cms_ceded
UNION ALL
select * from cc_ceded
),
-- CC intg done in visual_load_datalake.sql and the feeding source is DATALAKE.VW_CLAIMANT_TRANS
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
		 ,totclaim.claim_report_date  --AS-52
   from totclaim
      inner join trans on totclaim.claim = trans.claim
) 
select * from alltrans
  union all
select * from ceded_correct
;
--/*end transaction level information*/
--/* end create temp claim transaction file with attributes */
--/* claims insert */
DROP TABLE datalake.REPORT_DAILYPRODUCTION_CLAIM;
create table datalake.REPORT_DAILYPRODUCTION_CLAIM as
   select 'ecig' as source, polmast.policy_number, polmast.renewed_from_flag, polmast.renewed_from_quote_flag 
         ,to_char(polmast.dec_sequence) as dec_sequence, polmast.term_nbr  
         ,polmast.insured_name, polmast.writing_company, polmast.dec_type, polmast.policy_transaction_type
         ,polmast.transaction_effective_date, polmast.transaction_expiration_date
         ,polmast.term_effective_date, polmast.term_expiration_date, polmast.original_inception_date
         ,polmast.insured_address_line1, polmast.insured_address_line2
         ,polmast.insured_city, polmast.insured_state, polmast.insured_zipcode
         ,to_char(polmast.agency_code) as agency_code, polmast.agency_name, polmast.domicile_state
         ,case when polmast.customer_service_center_pl=1 then 'Y' else 'N' end as customer_service_center_pl
         ,case when polmast.customer_service_center_cl=1 then 'Y' else 'N' end as customer_service_center_cl
         ,polmast.current_agency_status, polmast.current_agency_status_date
         ,polmast.current_agency_status_pl, polmast.current_agency_status_cl, polmast.current_agency_status_fm
         ,polmast.agency_state, polmast.agency_county, polmast.agency_city, polmast.agency_zipcode
         ,polmast.agency_address_type
         ,to_char(polmast.branch_number) as branch_number, polmast.branch_name
		 
		 ,CASE --,polmast.region : AS-492 adding new region logic based on agency_code/dept : sc 20200807
              WHEN to_char(trans.department_number) = '115' OR gp.policy_search_nbr IS NOT NULL
                THEN 'Golf Program'
			  when (polmast.agency_code in (26728,27708,66004,66028,66501,66580,71508,26730) 			
					and to_char(trans.department_number) not in (10,15,21,40,50,71)) 
				then 'Other' --'Alternative Markets Programs'			    
			  when to_char(trans.department_number) in (115,119)  
				then 'Other' --'Alternative Markets Programs'
              ELSE polmast.region 
		  END region
		 
         ,to_char(polmast.parent_agency) as parent_agency, to_char(polmast.parent_agency_code) as parent_agency_code, polmast.parent_name
         ,polmast.cluster_name, polmast.master_code, polmast.master_name, polmast.master_location
         ,polmast.agency_development_manager, polmast.commercial_underwriter, polmast.farm_underwriter, polmast.personal_underwriter
         ,case when core_line_of_business='Commercial' then polmast.commercial_underwriter
               when core_line_of_business='Farm' then polmast.farm_underwriter
               when core_line_of_business='Personal' then polmast.personal_underwriter
          end as underwriter
         ,polmast.master_tier, to_char(polmast.agency_tier_2014) as agency_tier_2014, to_char(polmast.agency_tier_2015) as agency_tier_2015
         ,polmast.agency, polmast.policy, polmast.dec_policy, trans.claim, trans.dept
         ,trans.transaction_date as daily_booked_date, trans.transaction_date as monthly_booked_date, trans.transaction_date as entry_date, trunc(sysdate)-1 as valuation_date
         ,to_char(trans.department_number) as department_number, trans.department_name, trans.business_line_name, trans.major_line_name, trans.core_line_of_business, trans.CAUSE_NAME--HUB-552/553 sc
         ,to_char(trans.claim_number) as claim_number, trans.claim_prefix, trans.date_of_loss, trans.claim_description
         ,trans.claim_country, trans.claim_state, trans.claim_county, trans.claim_city, trans.claim_zipcode, trans.claim_location
         ,trans.suit_status, trans.cat_number
         ,trans.transaction_primary as claim_transaction_type, trans.transaction_status as claim_master_transaction_type
         ,trans.direct_caseos_loss, trans.direct_caseos_alae_dcc, trans.direct_caseos_alae_ao
         ,(trans.direct_caseos_alae_dcc + trans.direct_caseos_alae_ao) as direct_caseos_alae
         ,trans.direct_paid_loss, trans.direct_paid_alae_dcc, trans.direct_paid_alae_ao
         ,(trans.direct_paid_alae_dcc + trans.direct_paid_alae_ao) as direct_paid_alae
         ,-nvl(trans.ceded_caseos_loss,0) as ceded_caseos_loss, -nvl(trans.ceded_caseos_alae_dcc,0) as ceded_caseos_alae_dcc
         ,-nvl(trans.ceded_caseos_alae_ao,0) as ceded_caseos_alae_ao
         ,-nvl(trans.ceded_caseos_alae_dcc + trans.ceded_caseos_alae_ao,0) as ceded_caseos_alae
         ,-nvl(trans.ceded_paid_loss,0) as ceded_paid_loss, -nvl(trans.ceded_paid_alae_dcc,0) as ceded_paid_alae_dcc
         ,-nvl(trans.ceded_paid_alae_ao,0) as ceded_paid_alae_ao
         ,-NVL(TRANS.CEDED_PAID_ALAE_DCC + TRANS.CEDED_PAID_ALAE_AO,0) AS CEDED_PAID_ALAE
         ,trans.IS_CEDED_CORRECTION
		 ,trans.claim_report_date  --AS-52
   from datalake.TEMP_CLAIMTRANS trans
      inner join datalake.VWM_POLMAST_ECIG polmast on trans.dec_policy = polmast.dec_policy
	  LEFT JOIN DATALAKE.GOLF_PROGRAM_2017 gp on polmast.policy_number = gp.policy_search_nbr --AS-492
;
insert into datalake.REPORT_DAILYPRODUCTION_CLAIM
   select 'pc' as source, polmast.policy_number, polmast.RENEWED_FROM_FLAG, polmast.RENEWED_FROM_QUOTE_FLAG 
         ,to_char(polmast.dec_sequence) as dec_sequence, polmast.term_nbr  
         ,polmast.insured_name, polmast.writing_company, polmast.dec_type, polmast.policy_transaction_type
         ,polmast.transaction_effective_date, polmast.transaction_expiration_date
         ,polmast.term_effective_date, polmast.term_expiration_date, polmast.original_inception_date
         ,polmast.insured_address_line1, polmast.insured_address_line2
         ,polmast.insured_city, polmast.insured_state, polmast.insured_zipcode
         ,to_char(polmast.agency_code) as agency_code, polmast.agency_name, polmast.domicile_state
         ,case when polmast.customer_service_center_pl=1 then 'Y' else 'N' end as customer_service_center_pl
         ,case when polmast.customer_service_center_cl=1 then 'Y' else 'N' end as customer_service_center_cl
         ,polmast.current_agency_status, polmast.current_agency_status_date
         ,polmast.current_agency_status_pl, polmast.current_agency_status_cl, polmast.current_agency_status_fm
         ,polmast.agency_state, polmast.agency_county, polmast.agency_city, polmast.agency_zipcode
         ,polmast.agency_address_type
         ,to_char(polmast.branch_number) as branch_number, polmast.branch_name
		 
		 ,CASE --,polmast.region : AS-492 adding new region logic based on agency_code/dept : sc 20200807
              WHEN to_char(trans.department_number) = '115' OR gp.policy_search_nbr IS NOT NULL
                THEN 'Golf Program'
			  when (polmast.agency_code in (26728,27708,66004,66028,66501,66580,71508,26730) 			
					and to_char(trans.department_number) not in (10,15,21,40,50,71)) 
				then 'Other' --'Alternative Markets Programs'			    
			  when to_char(trans.department_number) in (115,119)  
				then 'Other' --'Alternative Markets Programs'
              ELSE polmast.region 
		  END region
		 
         ,to_char(polmast.parent_agency) as parent_agency, to_char(polmast.parent_agency_code) as parent_agency_code, polmast.parent_name
         ,polmast.cluster_name, polmast.master_code, polmast.master_name, polmast.master_location
         ,polmast.agency_development_manager, polmast.commercial_underwriter, polmast.farm_underwriter, polmast.personal_underwriter
         ,case when trans.core_line_of_business='Commercial' then polmast.commercial_underwriter
               when trans.core_line_of_business='Farm' then polmast.farm_underwriter
               when trans.core_line_of_business='Personal' then polmast.personal_underwriter
          end as underwriter
         ,polmast.master_tier, to_char(polmast.agency_tier_2014) as agency_tier_2014, to_char(polmast.agency_tier_2015) as agency_tier_2015
         ,polmast.agency, NULL as policy, NULL as dec_policy, trans.claim, trans.dept
         ,trans.transaction_date as daily_booked_date, trans.transaction_date as monthly_booked_date, trans.transaction_date as entry_date, trunc(sysdate)-1 as valuation_date
         ,to_char(trans.department_number) as department_number, trans.department_name, trans.business_line_name, trans.major_line_name, trans.core_line_of_business, trans.CAUSE_NAME--HUB-552/553 sc
         ,to_char(trans.claim_number) as claim_number, trans.claim_prefix, trans.date_of_loss, trans.claim_description
         ,trans.claim_country, trans.claim_state, trans.claim_county, trans.claim_city, trans.claim_zipcode, trans.claim_location
         ,trans.suit_status, trans.cat_number
         ,trans.transaction_primary as claim_transaction_type, trans.transaction_status as claim_master_transaction_type
         ,trans.direct_caseos_loss, trans.direct_caseos_alae_dcc, trans.direct_caseos_alae_ao
         ,(trans.direct_caseos_alae_dcc + trans.direct_caseos_alae_ao) as direct_caseos_alae
         ,trans.direct_paid_loss, trans.direct_paid_alae_dcc, trans.direct_paid_alae_ao
         ,(trans.direct_paid_alae_dcc + trans.direct_paid_alae_ao) as direct_paid_alae
         ,-nvl(trans.ceded_caseos_loss,0) as ceded_caseos_loss, -nvl(trans.ceded_caseos_alae_dcc,0) as ceded_caseos_alae_dcc
         ,-nvl(trans.ceded_caseos_alae_ao,0) as ceded_caseos_alae_ao
         ,-nvl(trans.ceded_caseos_alae_dcc + trans.ceded_caseos_alae_ao,0) as ceded_caseos_alae
         ,-nvl(trans.ceded_paid_loss,0) as ceded_paid_loss, -nvl(trans.ceded_paid_alae_dcc,0) as ceded_paid_alae_dcc
         ,-nvl(trans.ceded_paid_alae_ao,0) as ceded_paid_alae_ao
         ,-NVL(TRANS.CEDED_PAID_ALAE_DCC + TRANS.CEDED_PAID_ALAE_AO,0) AS CEDED_PAID_ALAE
         ,trans.IS_CEDED_CORRECTION
		 ,trans.claim_report_date  --AS-52
   FROM datalake.TEMP_CLAIMTRANS TRANS
   inner join ( SELECT * FROM datalake.VWM_POLMAST_POLICYCENTER  polmast --/*change made to remove duplicate claims- sc 07112018*/ 
          inner join (SELECT 
                      POLICYNUMBER,
                      MODELNUMBER_EXT,
                      MIN(TERMNUMBER) AS TERMNUMBER
                      FROM DATALAKE.PC_POLICYPERIOD
                      GROUP BY POLICYNUMBER,MODELNUMBER_EXT
          ) PCPP ON PCPP.POLICYNUMBER = POLMAST.POLICY_NUMBER AND PCPP.MODELNUMBER_EXT = POLMAST.DEC_SEQUENCE AND PCPP.TERMNUMBER = POLMAST.TERM_NBR
          WHERE POLMAST.QUOTE_FLAG=0
      ) POLMAST on trans.policy_search_nbr = polmast.policy_number AND TRANS.DEC_SEQUENCE = POLMAST.DEC_SEQUENCE
   LEFT JOIN (SELECT * FROM datalake.REPORT_DAILYPRODUCTION_CLAIM ECIG WHERE ECIG.SOURCE = 'ecig') ECIG  --/*change made to remove duplicate claims- sc 07112018*/ 
      on ecig.policy_number = polmast.policy_number and ecig.claim = trans.claim and ecig.date_of_loss = trans.date_of_loss and ecig.entry_date = trans.transaction_date and ecig.CLAIM_TRANSACTION_TYPE = trans.transaction_primary
	LEFT JOIN DATALAKE.GOLF_PROGRAM_2017 gp on polmast.policy_number = gp.policy_search_nbr --AS-492
      WHERE ECIG.SOURCE IS NULL OR (not(ecig.date_of_loss >= ecig.term_effective_date and ecig.date_of_loss <= ecig.term_expiration_date) ) 
 ;
 commit;
drop table DATALAKE.TEMP_CLAIMTRANS;
drop table DATALAKE.NEW_REPORT_DAILY_PRODUCTION;
CREATE TABLE DATALAKE.NEW_REPORT_DAILY_PRODUCTION as select * from DATALAKE.REPORT_DAILY_PRODUCTION;
GRANT SELECT ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION TO PUBLIC;
GRANT SELECT ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION TO S_ROLE;
CREATE INDEX DATALAKE.XIE1NEW_REPORT_DAILY_PROD ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(DAILY_BOOKED_DATE)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE2NEW_REPORT_DAILY_PROD  ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(BUSINESS_LINE_NAME)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE3NEW_REPORT_DAILY_PROD  ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(REGION)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );		   		   		   
CREATE INDEX DATALAKE.XIE1NEW_REPORT_DAILYPROD_PREM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(POLICY)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE2NEW_REPORT_DAILYPROD_PREM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(DEC_POLICY)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE3NEW_REPORT_DAILYPROD_PREM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(DEPT)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE4NEW_REPORT_DAILYPROD_PREM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(AGENCY)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE5NEW_REPORT_DAILYPROD_PREM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(POLICY_NUMBER)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE6NEW_REPORT_DAILYPROD_PREM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(AGENCY_CODE)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );	         
CREATE INDEX DATALAKE.XIE2NEW_REPORT_DAILYPROD_CLAIM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(CLAIM_NUMBER)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE3NEW_REPORT_DAILYPROD_CLAIM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(DEC_POLICY, DATE_OF_LOSS)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE5NEW_REPORT_DAILYPROD_CLAIM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(DATE_OF_LOSS)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE6NEW_REPORT_DAILYPROD_CLAIM ON DATALAKE.NEW_REPORT_DAILY_PRODUCTION
(CLAIM)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE1REPORT_DAILYPROD_PREM ON DATALAKE.REPORT_DAILYPRODUCTION_PREM
(POLICY)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE2REPORT_DAILYPROD_PREM ON DATALAKE.REPORT_DAILYPRODUCTION_PREM
(DEC_POLICY)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE3REPORT_DAILYPROD_PREM ON DATALAKE.REPORT_DAILYPRODUCTION_PREM
(DEPT)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE4REPORT_DAILYPROD_PREM ON DATALAKE.REPORT_DAILYPRODUCTION_PREM
(AGENCY)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE5REPORT_DAILYPROD_PREM ON DATALAKE.REPORT_DAILYPRODUCTION_PREM
(POLICY_NUMBER)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE6REPORT_DAILYPROD_PREM ON DATALAKE.REPORT_DAILYPRODUCTION_PREM
(AGENCY_CODE)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           ); 
CREATE INDEX DATALAKE.XIE1REPORT_DAILYPROD_CLAIM ON DATALAKE.REPORT_DAILYPRODUCTION_CLAIM
(POLICY)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE2REPORT_DAILYPROD_CLAIM ON DATALAKE.REPORT_DAILYPRODUCTION_CLAIM
(CLAIM_NUMBER)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );		      		  
CREATE INDEX DATALAKE.XIE3REPORT_DAILYPROD_CLAIM ON DATALAKE.REPORT_DAILYPRODUCTION_CLAIM
(DEC_POLICY, DATE_OF_LOSS)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE4REPORT_DAILYPROD_CLAIM ON DATALAKE.REPORT_DAILYPRODUCTION_CLAIM
(DEC_POLICY)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE5REPORT_DAILYPROD_CLAIM ON DATALAKE.REPORT_DAILYPRODUCTION_CLAIM
(DATE_OF_LOSS)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE6REPORT_DAILYPROD_CLAIM ON DATALAKE.REPORT_DAILYPRODUCTION_CLAIM
(CLAIM)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );
CREATE INDEX DATALAKE.XIE7REPORT_DAILYPROD_CLAIM ON DATALAKE.REPORT_DAILYPRODUCTION_CLAIM
(POLICY_NUMBER)
LOGGING
TABLESPACE DLAKE
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );