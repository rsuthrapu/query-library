CREATE TABLE DLAKEDEV.VAR_CLAIMANT_COVERAGE AS
with vcc as (
   select claimant_coverage, claim, claimant, cause_of_loss, coverage, cause_status, dept,CLAIM_SOURCE from (
      select claimant_coverage, claim, claimant, cause_of_loss, coverage, cause_status, dept,CLAIM_SOURCE
            ,row_number() over (partition by claimant_coverage order by cc_trans_date desc) cc_rowmax
      from (select * from DLAKEDEV.VW_CLAIMANT_COVERAGE cross join DATALAKE.L_EVALDATE where cc_trans_date < evaldate)
    ) where cc_rowmax=1
),
vcn as (
   select claimant, claimant_name, medicare_eligible,CLAIM_SOURCE from (
      select claimant, claimant_name, medicare_eligible,CLAIM_SOURCE
            ,row_number() over (partition by claimant order by claimant_trans_date desc) claimant_rowmax
      from (select * from DLAKEDEV.VW_CLAIMANT_NAME cross join DATALAKE.L_EVALDATE where claimant_trans_date < evaldate)
   ) where claimant_rowmax=1
),
vcmscol as (
   select claim, claimant, cause_of_loss, coverage
         ,adj_independent, adj_assistant, adj_hosupervisor, adj_supervisor, adj_staff,CLAIM_SOURCE
   from (
      select claim, claimant, cause_of_loss, coverage
            ,adj_independent, adj_assistant, adj_hosupervisor, adj_supervisor, adj_staff,CLAIM_SOURCE
            ,row_number() over (partition by claim, claimant, cause_of_loss, coverage order by cmscol_trans_date desc) cmscol_rowmax
      from (select * from DLAKEDEV.VW_CMS_COL_ADJUSTER cross join DATALAKE.L_EVALDATE where cmscol_trans_date < evaldate)
   ) where cmscol_rowmax=1
),
vstaff as (
   select staff, staffname, functional_role, cms_user_function_role
         ,branch, region_nbr, unit_nbr, '' AS CLAIM_SOURCE
   from (
      select staff, staffname, functional_role, cms_user_function_role
            ,branch, region_nbr, unit_nbr,'' AS CLAIM_SOURCE
            ,row_number() over (partition by staff order by staff_trans_date desc) staff_rowmax
      from (select * from DATALAKE.VW_STAFF cross join DATALAKE.L_EVALDATE where staff_trans_date < evaldate or staff_load_date=to_date('12-30-2015','mm-dd-yyyy'))
   ) where staff_rowmax=1
),
varcc as (
   select claimant_coverage, claim, claimant, cause_of_loss, coverage, cause_status, dept
            ,claimant_name, medicare_eligible
            ,adj_staff, adj_supervisor, adj_hosupervisor, adj_assistant, adj_independent
            ,adj_staff_name, functional_role, cms_user_function_role, branch, region_nbr, unit_nbr
            ,varcc_trans_date,'' AS CLAIM_SOURCE
   from (
      select claimant_coverage, claim, claimant, cause_of_loss, coverage, cause_status, dept
            ,claimant_name, medicare_eligible
            ,adj_staff, adj_supervisor, adj_hosupervisor, adj_assistant, adj_independent
            ,adj_staff_name, functional_role, cms_user_function_role, branch, region_nbr, unit_nbr
            ,varcc_trans_date,'' AS CLAIM_SOURCE
            ,row_number() over (partition by claimant_coverage order by varcc_trans_date desc) varcc_rowmax
      from (select * from DATALAKE.VAR_CLAIMANT_COVERAGE cross join DATALAKE.L_EVALDATE where varcc_trans_date < evaldate - 1)
   ) where varcc_rowmax=1
)
select claimant_coverage, claim, claimant, cause_of_loss, coverage, cause_status, dept
      ,claimant_name, medicare_eligible
      ,adj_staff, adj_supervisor, adj_hosupervisor, adj_assistant, adj_independent
      ,adj_staff_name, functional_role, cms_user_function_role, branch, region_nbr, unit_nbr
      ,varcc_trans_date,CLAIM_SOURCE
from (
   select claimant_coverage, claim, claimant, cause_of_loss, coverage, cause_status, dept
         ,claimant_name, medicare_eligible
         ,adj_staff, adj_supervisor, adj_hosupervisor, adj_assistant, adj_independent
         ,adj_staff_name, functional_role, cms_user_function_role, branch, region_nbr, unit_nbr
         ,min(varcc_trans_date) as varcc_trans_date,CLAIM_SOURCE
   from ((
      select  vcc.claimant_coverage, vcc.claim, vcc.claimant, vcc.cause_of_loss, vcc.coverage
             ,vcc.cause_status, vcc.dept
             ,vcn.claimant_name
             ,vcn.medicare_eligible
             ,vcmscol.adj_staff
             ,vcmscol.adj_supervisor
             ,vcmscol.adj_hosupervisor
             ,vcmscol.adj_assistant
             ,vcmscol.adj_independent
             ,vstaff.staffname as adj_staff_name
             ,vstaff.functional_role
             ,vstaff.cms_user_function_role
             ,vstaff.branch
             ,vstaff.region_nbr
             ,vstaff.unit_nbr
             ,l_evaldate.evaldate - 1 as varcc_trans_date
             , vcc.CLAIM_SOURCE
      from vcc
         inner join vcmscol
            on vcc.claim=vcmscol.claim and vcc.claimant=vcmscol.claimant and
               vcc.cause_of_loss=vcmscol.cause_of_loss and vcc.coverage=vcmscol.coverage
         inner join vcn on vcc.claimant=vcn.claimant
         inner join vstaff on vcmscol.adj_staff=vstaff.staff
         cross join DATALAKE.L_EVALDATE
       ) union (select * from varcc))
   group by claimant_coverage, claim, claimant, cause_of_loss, coverage, cause_status, dept
         ,claimant_name, medicare_eligible
         ,adj_staff, adj_supervisor, adj_hosupervisor, adj_assistant, adj_independent
         ,adj_staff_name, functional_role, cms_user_function_role, branch, region_nbr, unit_nbr,CLAIM_SOURCE
   ) cross join DATALAKE.L_EVALDATE
where varcc_trans_date > (evaldate - 2)
;