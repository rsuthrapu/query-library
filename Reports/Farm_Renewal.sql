--Run in Echo                      
--Farm
                     
select p.policy_search_nbr,                                        
ni.legal_name, 
term_effective_date, 
term_expiration_date, 
p.current_inforce,                                
    round(case when nvl(z.incurred_loss_3yr,0) = 0 then 0 else nvl(z.incurred_loss_3yr,0)/pr.THREE_YR_PREM end,3) "3_YR_LR",                         
    round(case when nvl(z.incurred_loss_5yr,0) = 0 then 0 else nvl(z.incurred_loss_5yr,0)/pr.FIVE_YR_PREM end,3) "5_YR_LR",                         
    sum(round(case when nvl(aa.incurred_loss,0) <> 0 and aa.trans_year = :YEAR - 5 then nvl(aa.incurred_loss,0) else 0 end,5)) "2013",                  
    sum(round(case when nvl(aa.incurred_loss,0) <> 0 and aa.trans_year = :YEAR - 4 then nvl(aa.incurred_loss,0) else 0 end,5)) "2014",                  
    sum(round(case when nvl(aa.incurred_loss,0) <> 0 and aa.trans_year = :YEAR - 3 then nvl(aa.incurred_loss,0) else 0 end,5)) "2015",                  
    sum(round(case when nvl(aa.incurred_loss,0) <> 0 and aa.trans_year = :YEAR - 2 then nvl(aa.incurred_loss,0) else 0 end,5)) "2016",                  
    sum(round(case when nvl(aa.incurred_loss,0) <> 0 and aa.trans_year = :YEAR - 1 then nvl(aa.incurred_loss,0) else 0 end,5)) "2017",                  
    sum(round(case when nvl(aa.incurred_loss,0) <> 0 and aa.trans_year = :YEAR then nvl(aa.incurred_loss,0) else 0 end,5)) "2018",                                            
    null "IRPM", 
    a.domicile_state "STATE", 
    a.agency_code, 
    agency_name, 
    null "UNDERWRITER", 
    ab.nonrenewal_date                   
  from policy p                   
  left join                              
  (select pr.policy, max(pr.dept) dept, bl.business_line, bl.business_line_name, ml.major_line_name, sum(pr.written_prem) FIVE_YR_PREM,
  sum(case when pr.trans_date >= (to_date(add_months(:MONTH_END,5))-1186) then pr.written_prem else 0 end) THREE_YR_PREM                             
  from prem pr                   
  left join dept d on pr.dept = d.dept                        
  left join business_line bl on d.business_line = bl.business_line                  
  left join major_line ml on d.major_line = ml.major_line                
  where pr.trans_date >= (to_date(add_months(:MONTH_END,5))-1916)                
  and (ml.major_line_name = 'Farm' or d.dept_nbr in (120,121,125,129,127))                         
  group by pr.policy, bl.BUSINESS_LINE, bl.business_line_name, ml.major_line_name) pr on p.policy = pr.policy                     
  left join agency a on a.agency_code = p.agency_code                   
  left join branch b on a.branch = b.branch                            
  left join dept d on d.dept = pr.dept                        
  left join named_insured ni on p.named_insured = ni.named_insured                     
  left join agency_business ab on a.agency = ab.agency and ab.business_line = pr.business_line                    
  left join --Region policies that have less than 5 vehicles that are not trailers - determines fleet or non-fleet status                                
   (select p.policy                               
    from policy p, commercial_auto_coverage c, commercial_vehicle cv, agency a, branch br                            
    where p.policy_status in ('Active','Hold')                           
      and p.agency_code = a.agency_code                
      and a.branch = br.branch                       
      and br.branch_nbr not in (66,77,88,82)                            
      and p.policy = c.policy                              
      and upper(nvl(cv.body_type,'blank')) not like '%TRAILER%'                     
      and c.commercial_auto_coverage = cv.commercial_auto_coverage                   
    having count(cv.identification) < 5                        
    group by p.policy) --End Region                             
    x on x.policy = p.policy                               
  left join --Region Claims for the last 5.25 years: Comm Auto                        
       (
--       select cl.policy,                        
--       sum(case when ct.trans_date >= (to_date(add_months(:MONTH_END,5))-1916) then 
--       case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other') then 
--       nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) 
--       else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end
--       else 0 end) "INCURRED_LOSS_5YR",                               
--       sum(case when ct.trans_date >= (to_date(add_months(:MONTH_END,5))-1186) then case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other') then 
--       nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) 
--       else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end else 0 end) "INCURRED_LOSS_3YR"                
--    from claimant_trans ct, claim cl, claimant_coverage cc                                
--    where ct.trans_date >= (to_date(add_months(:MONTH_END,5))-1916)  --this is 5.25 years prior                              
--      and ct.claimant_coverage = cc.claimant_coverage                      
--      and cc.claim = cl.claim                             
--    group by cl.policy
WITH INCURRED_LOSS_CC AS(
                SELECT  POLICY,
               SUM(CASE WHEN TRANS_DATE >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916) THEN 
               CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))  THEN 
               NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) 
               ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END
               ELSE 0 END) "INCURRED_LOSS_5YR",                               
               SUM(CASE WHEN TRANS_DATE >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1186) THEN 
               CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))  THEN 
               NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) 
               ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END ELSE 0 END) "INCURRED_LOSS_3YR"  , SOURCE
            FROM (
            SELECT
               P.ID AS POLICY,
               TLRC.NAME AS TRANS_TYPE,
               TR.UPDATETIME AS TRANS_DATE ,
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
                END                        AS ALLOC_EXPENSE_RESERVE  ,
            'CC' AS SOURCE
            FROM   
            CC_CLAIM@ECIG_TO_CC_LINK C
            INNER JOIN CC_POLICY@ECIG_TO_CC_LINK P ON P.ID = C.POLICYID
            LEFT OUTER JOIN PC_POLICYPERIOD@ECIG_TO_PC_LINK PP ON PP.ID=P.PolicySystemPeriodID
            INNER JOIN CC_TRANSACTION@ECIG_TO_CC_LINK  TR ON TR.CLAIMID = C.ID
            LEFT OUTER JOIN CCTL_RECOVERYCATEGORY@ECIG_TO_CC_LINK    TLRC ON TLRC.ID   = TR.RECOVERYCATEGORY AND TLRC.RETIRED = 0
            INNER JOIN CCTL_TRANSACTION@ECIG_TO_CC_LINK              TLTR ON TLTR.ID = TR.SUBTYPE AND TLTR.RETIRED = 0
            INNER JOIN CC_TRANSACTIONLINEITEM@ECIG_TO_CC_LINK        TRLI ON TRLI.TRANSACTIONID = TR.ID AND TRLI.RETIRED = 0
            LEFT OUTER JOIN CCTL_COSTTYPE@ECIG_TO_CC_LINK            TLCSTTY ON TLCSTTY.ID = TR.COSTTYPE AND TLCSTTY.RETIRED = 0
            WHERE TR.UPDATETIME >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916))
            GROUP BY POLICY, SOURCE  
            ),
       INCURRED_LOSS_ECIG AS (
            SELECT  POLICY,
               SUM(CASE WHEN TRANS_DATE >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916) THEN 
               CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other') THEN 
               NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) 
               ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END
               ELSE 0 END) "INCURRED_LOSS_5YR",                               
               SUM(CASE WHEN TRANS_DATE >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1186) THEN CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other') THEN 
               NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) 
               ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END ELSE 0 END) "INCURRED_LOSS_3YR"  , SOURCE
            FROM(
               SELECT CL.POLICY AS POLICY,                        
               CT.TRANS_DATE,CT.TRANS_TYPE ,   CT.LOSS_PAID,CT.ALLOC_EXPENSE_PAID, CT.UNALLOC_EXPENSE_PAID,
               CT.LOSS_RESERVE,CT.ALLOC_EXPENSE_RESERVE,CT.UNALLOC_EXPENSE_RESERVE , 'CMS' AS SOURCE
               FROM CLAIMANT_TRANS CT, CLAIM CL, CLAIMANT_COVERAGE CC                                
               WHERE CT.TRANS_DATE >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916)  --THIS IS 5.25 YEARS PRIOR                              
              AND CT.CLAIMANT_COVERAGE = CC.CLAIMANT_COVERAGE                      
              AND CC.CLAIM = CL.CLAIM)
           GROUP BY POLICY, SOURCE
            ),
            
           INCURRED_LOSS_CC_ECIG AS (
                SELECT * FROM INCURRED_LOSS_CC 
                UNION ALL
                SELECT * FROM INCURRED_LOSS_ECIG
            )
        SELECT * FROM INCURRED_LOSS_CC_ECIG

    )                       
    --End Region                  
    z on z.policy = p.policy                               
  left join --Region Incurred Losses for the past 5 years                     
    (
--    select cl.policy, extract(year from ct.trans_date) TRANS_YEAR, sum(case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other') then 
--    nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) 
--    else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end) "INCURRED_LOSS"                                
--    from claimant_trans ct, claim cl, claimant_coverage cc                                
--    where ct.trans_date > (to_date('31-Dec-'||to_char(:YEAR-6), 'dd-mon-yyyy'))                 
--      and ct.trans_date <= (to_date(:MONTH_END, 'dd-mon-yyyy'))                              
--      and ct.claimant_coverage = cc.claimant_coverage                      
--      and cc.claim = cl.claim                             
--    group by cl.policy, extract(year from ct.trans_date)
WITH INCURRED_LOSS_CC AS(
            SELECT  POLICY, extract(year from TRANS_DATE) AS TRANS_YEAR,
               SUM(CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))  THEN 
               NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) 
               ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END) "INCURRED_LOSS", SOURCE
            FROM (
            SELECT
               P.ID AS POLICY,
               TLRC.NAME AS TRANS_TYPE,
               TR.UPDATETIME AS TRANS_DATE ,
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
                END                        AS ALLOC_EXPENSE_RESERVE  ,
            'CC' AS SOURCE
            FROM   
            CC_CLAIM@ECIG_TO_CC_LINK C
            INNER JOIN CC_POLICY@ECIG_TO_CC_LINK P ON P.ID = C.POLICYID
            LEFT OUTER JOIN PC_POLICYPERIOD@ECIG_TO_PC_LINK PP ON PP.ID=P.PolicySystemPeriodID
            INNER JOIN CC_TRANSACTION@ECIG_TO_CC_LINK  TR ON TR.CLAIMID = C.ID
            LEFT OUTER JOIN CCTL_RECOVERYCATEGORY@ECIG_TO_CC_LINK    TLRC ON TLRC.ID   = TR.RECOVERYCATEGORY AND TLRC.RETIRED = 0
            INNER JOIN CCTL_TRANSACTION@ECIG_TO_CC_LINK              TLTR ON TLTR.ID = TR.SUBTYPE AND TLTR.RETIRED = 0
            INNER JOIN CC_TRANSACTIONLINEITEM@ECIG_TO_CC_LINK        TRLI ON TRLI.TRANSACTIONID = TR.ID AND TRLI.RETIRED = 0
            LEFT OUTER JOIN CCTL_COSTTYPE@ECIG_TO_CC_LINK            TLCSTTY ON TLCSTTY.ID = TR.COSTTYPE AND TLCSTTY.RETIRED = 0
            WHERE TR.UPDATETIME > (TO_DATE('31-DEC-'||TO_CHAR(:YEAR-6), 'DD-MON-YYYY'))  
            AND TR.UPDATETIME >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916))
            GROUP BY POLICY,extract(year from trans_date), SOURCE
            ),
       INCURRED_LOSS_ECIG AS (
            SELECT  POLICY, extract(year from trans_date) TRANS_YEAR,
               SUM(CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other') THEN 
               NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) 
               ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END) "INCURRED_LOSS" , SOURCE                             
            FROM(
               SELECT CL.POLICY AS POLICY,                        
               CT.TRANS_DATE,CT.TRANS_TYPE ,   CT.LOSS_PAID,CT.ALLOC_EXPENSE_PAID, CT.UNALLOC_EXPENSE_PAID,
               CT.LOSS_RESERVE,CT.ALLOC_EXPENSE_RESERVE,CT.UNALLOC_EXPENSE_RESERVE , 'CMS' AS SOURCE
               FROM CLAIMANT_TRANS CT, CLAIM CL, CLAIMANT_COVERAGE CC                                
               WHERE  CT.TRANS_DATE > (TO_DATE('31-DEC-'||TO_CHAR(:YEAR-6), 'DD-MON-YYYY'))   
               AND CT.TRANS_DATE >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916)                             
              AND CT.CLAIMANT_COVERAGE = CC.CLAIMANT_COVERAGE                      
              AND CC.CLAIM = CL.CLAIM)
           GROUP BY POLICY,extract(year from trans_date), SOURCE
            ),
            
           INCURRED_LOSS_CC_ECIG AS (
                SELECT * FROM INCURRED_LOSS_CC 
                UNION ALL
                SELECT * FROM INCURRED_LOSS_ECIG
            )
        SELECT * FROM INCURRED_LOSS_CC_ECIG
    ) --year - 1                  
    --End Region                  
    aa on aa.policy = p.policy                          
  where --p.policy = 6225390 and                               
  p.policy_status in ('Active','Hold')                           
    and p.term_expiration_date > last_day(to_date(add_months(:MONTH_END,5)) - 55)         --ONE MONTH                            
    and p.term_expiration_date <= to_date(add_months(:MONTH_END,5))                            
    and (pr.major_line_name = 'Farm' or d.dept_nbr in (120,121,125,129,127))                        
  group by p.policy_search_nbr, --d.dept_nbr,                     
    ni.legal_name, --branch_nbr, parent_agency,                   
    branch_name,              
    term_effective_date, 
    term_expiration_date, 
    p.current_inforce,             
    nvl(z.incurred_loss_3yr,0), 
    nvl(z.incurred_loss_5yr,0),                          
    a.domicile_state, 
    a.agency_code, 
    agency_name, 
    ab.nonrenewal_date,                               
    pr.THREE_YR_PREM, 
    pr.FIVE_YR_PREM                           
    
;   

                          
--Only Farm Auto                             
select * from jzhang.report_renewal_fleet where rownum <= 100;                               
drop table jzhang.REPORT_RENEWAL_FLEET;                       
create table jzhang.report_renewal_fleet as                           
select policynumber, periodstart, max(fleet) FLEET                           
from(                    
  select distinct p.policynumber                 
    ,p.periodstart                
    ,tp.fleet                           
  from datalake.pcvw_policyperiod p                       
    join (select row_number() over (partition by tp.vehicle_fixedid order by tp.transaction_expirationdate desc) ROW_CT, tp.* from datalake.pcvw_ca7transprivatepassenger tp) tp                         
      on (p.period_id = tp.branchid and tp.row_ct = 1)                         
  where p.dummy is null                
    and p.period_status = 'Bound'                               
    --and p.policynumber = '13-BAA-4-1903048' --4 Priv Pass, 1 Truck: no vehicles say Fleet, but data has vehicle 6 saying "Yes"                       
  union all                             
  select distinct p.policynumber                 
    ,p.periodstart                
    ,tt.fleet                            
  from datalake.pcvw_policyperiod p                       
    join (select row_number() over (partition by tt.vehicle_fixedid order by tt.transaction_expirationdate desc) ROW_CT, tt.* from datalake.pcvw_ca7transtruck tt) tt                    
      on (p.period_id = tt.branchid and tt.row_ct = 1)                           
  where p.dummy is null                
    and p.period_status = 'Bound'                               
    --and p.policynumber = '13-BAA-4-1903048' --4 Priv Pass, 1 Truck: no vehicles say Fleet, but data has vehicle 6 saying "Yes"                       
  union all                             
  select distinct p.policynumber                 
    ,p.periodstart                
    ,tb.fleet                           
  from datalake.pcvw_policyperiod p                       
    join (select row_number() over (partition by tb.vehicle_fixedid order by tb.transaction_expirationdate desc) ROW_CT, tb.* from datalake.pcvw_ca7transpublic tb) tb                                
      on (p.period_id = tb.branchid and tb.row_ct = 1)                         
  where p.dummy is null                
    and p.period_status = 'Bound'                               
  union all                             
  select distinct p.policynumber                 
    ,p.periodstart                
    ,ts.fleet                            
  from datalake.pcvw_policyperiod p                       
    join (select row_number() over (partition by ts.vehicle_fixedid order by ts.transaction_expirationdate desc) ROW_CT, ts.* from datalake.pcvw_ca7transspecial ts) ts                
      on (p.period_id = ts.branchid and ts.row_ct = 1)                          
  where p.dummy is null                
    and p.period_status = 'Bound'                               
  union all                             
  select distinct p.policynumber                 
    ,p.periodstart                
    ,ta.fleet                           
  from datalake.pcvw_policyperiod p                       
    join (select row_number() over (partition by ta.vehicle_fixedid order by ta.transaction_expirationdate desc) ROW_CT, ta.* from datalake.pcvw_ca7transautodealer ta) ta                       
      on (p.period_id = ta.branchid and ta.row_ct = 1)                          
  where p.dummy is null                
    and p.period_status = 'Bound'                               
  )                            
group by policynumber, periodstart                         
;                               
select distinct business_line_name from report_dailyproduction_prem where source = 'pc';                          
select * from echo_db_links.business_line;         


--run in PC                          
                               
with loss_ratio as (                          
select policy_search_nbr, sum(cat_flag) CAT_FLAG, sum(premium_3yr) PREMIUM_3YR, sum(incurred_loss_3YR) INCURRED_LOSS_3YR, sum(premium_5yr) PREMIUM_5YR,
sum(incurred_loss_5YR) INCURRED_LOSS_5YR,                           
sum(incurred_loss_2013) incurred_loss_2013,                   
sum(incurred_loss_2014) incurred_loss_2014,                   
sum(incurred_loss_2015) incurred_loss_2015,                   
sum(incurred_loss_2016) incurred_loss_2016,                   
sum(incurred_loss_2017) incurred_loss_2017,                   
sum(incurred_loss_2018) incurred_loss_2018                    
from(                   
--  select nvl(cp.policy_search_nbr,py.policy_search_nbr) POLICY_SEARCH_NBR                    
--    ,0 PREMIUM_3YR                       
--    ,0 PREMIUM_5YR                       
--    ,sum(case when trunc(ct.trans_date) >= (to_date(add_months(:MONTH_END,5))-1186) then case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other')  --this is 3.25 years prior                 
--    then nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) 
--     else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end 
--      else 0 end) INCURRED_LOSS_3YR                   
--    ,sum(case when trunc(ct.trans_date) >= (to_date(add_months(:MONTH_END,5))-1916) then 
--case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other')                  
--    then nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) 
--else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end else 0 end) INCURRED_LOSS_5YR                   
--    ,case when sum(nvl(cl.catastrophe,0)) > 0 then 1 else 0 end CAT_FLAG                              
--    ,sum(case when extract(year from ct.trans_date) = :YEAR-5 then case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other')                   
--    then nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end 
--else 0 end) INCURRED_LOSS_2013                 
--    ,sum(case when extract(year from ct.trans_date) = :YEAR-4 then case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other')                   
--    then nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) else  nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end 
--else 0 end) INCURRED_LOSS_2014                 
--    ,sum(case when extract(year from ct.trans_date) = :YEAR-3 then case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other')                   
--    then nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end
--else 0 end) INCURRED_LOSS_2015                 
--    ,sum(case when extract(year from ct.trans_date) = :YEAR-2 then case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other')                   
--    then nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end
--else 0 end) INCURRED_LOSS_2016                 
--    ,sum(case when extract(year from ct.trans_date) = :YEAR-1 then case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other')                   
--    then nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end 
--else 0 end) INCURRED_LOSS_2017                 
--    ,sum(case when extract(year from ct.trans_date) = :YEAR then case when ct.trans_type in ('Credit Salvage', 'Credit Subro', 'Credit Other')                   
--    then nvl(ct.loss_paid,0)+nvl(ct.alloc_expense_paid,0)+nvl(ct.unalloc_expense_paid,0) else nvl(ct.loss_reserve,0)+nvl(ct.alloc_expense_reserve,0)+nvl(ct.unalloc_expense_reserve,0) end 
--else 0 end) INCURRED_LOSS_2018                 
--  from echo_db_links.claim cl                     
--    join echo_db_links.claimant_coverage cc on (cl.claim = cc.claim)                           
--    join echo_db_links.claimant_trans ct on (cc.claimant_coverage = ct.claimant_coverage)                            
--    left join echo_db_links.cms_claim_policy ccp on (cl.claim = ccp.claim)                 
--    left join echo_db_links.cms_policy cp on (ccp.cms_policy = cp.cms_policy)                       
--    left join echo_db_links.policy py on (cl.policy = py.policy)                         
--    left join echo_db_links.business_line bl on (py.business_line = bl.business_line)                            
--  where ct.claimant_coverage = cc.claimant_coverage                    
--    and cc.claim = cl.claim                               
--    and nvl(cp.business_line,bl.business_line_name)= ('Farm Auto')                           
--    and trunc(trans_date) >= (to_date(add_months(:MONTH_END,5))-1916)                          
--group by nvl(cp.policy_search_nbr,py.policy_search_nbr)     
WITH LOSS_RATIO_CC AS(
            SELECT  POLICY_SEARCH_NBR,
            SUM(CASE WHEN TRUNC(TRANS_DATE) >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1186) THEN CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))   --THIS IS 3.25 YEARS PRIOR                 
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END
            ELSE 0 END) INCURRED_LOSS_3YR                   
            ,SUM(CASE WHEN TRUNC(TRANS_DATE) >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916) THEN CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_5YR                   
            ,CASE WHEN SUM(NVL(CATASTROPHE,0)) > 0 THEN 1 ELSE 0 END CAT_FLAG                              
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR-5 THEN CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END
            ELSE 0 END) INCURRED_LOSS_2013                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR-4 THEN CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))                     
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE  NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END
            ELSE 0 END) INCURRED_LOSS_2014                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR-3 THEN CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_2015                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR-2 THEN CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))                     
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_2016                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR-1 THEN CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))                     
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_2017                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR THEN CASE WHEN TRANS_TYPE IN ('Subrogation', 'Salvage', 'Deductible',LTRIM('Credit to expense'), LTRIM('Credit to loss'))                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_2018 , SOURCE
            FROM (
            SELECT
               P.POLICYNUMBER AS POLICY_SEARCH_NBR,
               TLRC.NAME AS TRANS_TYPE,
               TR.UPDATETIME AS TRANS_DATE ,
                CCAT.ID AS  CATASTROPHE,
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
                END                        AS ALLOC_EXPENSE_RESERVE  ,
            'CC' AS SOURCE
            FROM   
            CC_CLAIM@ECIG_TO_CC_LINK C
            INNER JOIN CC_POLICY@ECIG_TO_CC_LINK P ON P.ID = C.POLICYID
            LEFT OUTER JOIN PC_POLICYPERIOD@ECIG_TO_PC_LINK PP ON PP.ID=P.PolicySystemPeriodID
            INNER JOIN CCTL_POLICYTYPE@ECIG_TO_CC_LINK TLPTY ON TLPTY.ID=P.POLICYTYPE AND 
            (P.POLICYNUMBER LIKE '%FAA%' OR P.POLICYNUMBER LIKE '%SAA%'  OR P.POLICYNUMBER LIKE '%GAA%') AND TLPTY.RETIRED=0
            INNER JOIN CC_TRANSACTION@ECIG_TO_CC_LINK  TR ON TR.CLAIMID = C.ID
            LEFT OUTER JOIN CC_CATASTROPHE@ECIG_TO_CC_LINK               CCAT ON C.CATASTROPHEID = CCAT.ID AND CCAT.RETIRED = 0
            LEFT OUTER JOIN CCTL_RECOVERYCATEGORY@ECIG_TO_CC_LINK    TLRC ON TLRC.ID   = TR.RECOVERYCATEGORY AND TLRC.RETIRED = 0
            INNER JOIN CCTL_TRANSACTION@ECIG_TO_CC_LINK              TLTR ON TLTR.ID = TR.SUBTYPE AND TLTR.RETIRED = 0
            INNER JOIN CC_TRANSACTIONLINEITEM@ECIG_TO_CC_LINK        TRLI ON TRLI.TRANSACTIONID = TR.ID AND TRLI.RETIRED = 0
            LEFT OUTER JOIN CCTL_COSTTYPE@ECIG_TO_CC_LINK            TLCSTTY ON TLCSTTY.ID = TR.COSTTYPE AND TLCSTTY.RETIRED = 0
            WHERE TRUNC( TR.UPDATETIME) >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916))
            GROUP BY POLICY_SEARCH_NBR, SOURCE  
            ),
       LOSS_RATIO_ECIG AS (
            SELECT  POLICY_SEARCH_NBR,
            SUM(CASE WHEN TRUNC(TRANS_DATE) >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1186) THEN CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other')   --THIS IS 3.25 YEARS PRIOR                 
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END
            ELSE 0 END) INCURRED_LOSS_3YR                   
            ,SUM(CASE WHEN TRUNC(TRANS_DATE) >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916) THEN CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other')                   
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_5YR                   
            ,CASE WHEN SUM(NVL(CATASTROPHE,0)) > 0 THEN 1 ELSE 0 END CAT_FLAG                              
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR-5 THEN CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other')                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END
            ELSE 0 END) INCURRED_LOSS_2013                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = 2022-4 THEN CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other')                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE  NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END
            ELSE 0 END) INCURRED_LOSS_2014                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR-3 THEN CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other')                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_2015                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR-2 THEN CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other')                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_2016                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR-1 THEN CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other')                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_2017                 
            ,SUM(CASE WHEN EXTRACT(YEAR FROM TRANS_DATE) = :YEAR THEN CASE WHEN TRANS_TYPE IN ('Credit Salvage', 'Credit Subro', 'Credit Other')                    
            THEN NVL(LOSS_PAID,0)+NVL(ALLOC_EXPENSE_PAID,0)+NVL(UNALLOC_EXPENSE_PAID,0) ELSE NVL(LOSS_RESERVE,0)+NVL(ALLOC_EXPENSE_RESERVE,0)+NVL(UNALLOC_EXPENSE_RESERVE,0) END 
            ELSE 0 END) INCURRED_LOSS_2018 , SOURCE
            FROM(
                SELECT NVL(CP.POLICY_SEARCH_NBR,PY.POLICY_SEARCH_NBR) POLICY_SEARCH_NBR, CT.TRANS_DATE , CT.TRANS_TYPE,
                       CT.LOSS_PAID , CT.ALLOC_EXPENSE_PAID ,   CT.UNALLOC_EXPENSE_PAID 
                       , CT.LOSS_RESERVE ,CT.ALLOC_EXPENSE_RESERVE ,  CT.UNALLOC_EXPENSE_RESERVE,CL.CATASTROPHE , 'CMS' AS SOURCE
                  FROM CLAIM CL                     
                    JOIN CLAIMANT_COVERAGE CC ON (CL.CLAIM = CC.CLAIM)                           
                    JOIN CLAIMANT_TRANS CT ON (CC.CLAIMANT_COVERAGE = CT.CLAIMANT_COVERAGE)                            
                    LEFT JOIN CMS_CLAIM_POLICY CCP ON (CL.CLAIM = CCP.CLAIM)                 
                    LEFT JOIN CMS_POLICY CP ON (CCP.CMS_POLICY = CP.CMS_POLICY)                       
                    LEFT JOIN POLICY PY ON (CL.POLICY = PY.POLICY)                         
                    LEFT JOIN BUSINESS_LINE BL ON (PY.BUSINESS_LINE = BL.BUSINESS_LINE)                            
                  WHERE CT.CLAIMANT_COVERAGE = CC.CLAIMANT_COVERAGE                    
                    AND CC.CLAIM = CL.CLAIM                               
                    AND NVL(CP.BUSINESS_LINE,BL.BUSINESS_LINE_NAME)= ('Farm Auto')                           
                    AND TRUNC(TRANS_DATE) >= (TO_DATE(ADD_MONTHS(:MONTH_END,5))-1916))
            GROUP BY POLICY_SEARCH_NBR, SOURCE   
            ),
           LOSS_RATIO_CC_ECIG AS (
                SELECT * FROM LOSS_RATIO_CC 
                UNION ALL
                SELECT * FROM LOSS_RATIO_ECIG
            )
        SELECT * FROM LOSS_RATIO_CC_ECIG                       
  union all                            
  select policy_nbr                           
    ,sum(case when trans_date >= (to_date(add_months(:MONTH_END,5))-1186) then written_prem else 0 end) PREMIUM_3YR                
    ,sum(written_prem) PREMIUM_5YR                  
    ,0 INCURRED_LOSS_3YR                          
    ,0 INCURRED_LOSS_5YR                          
    ,0 CAT_FLAG                
    ,0 INCURRED_LOSS_2013                        
   ,0 INCURRED_LOSS_2014                         
    ,0 INCURRED_LOSS_2015                        
    ,0 INCURRED_LOSS_2016                        
    ,0 INCURRED_LOSS_2017                        
    ,0 INCURRED_LOSS_2018                        
 @echo.world --use DW_PREM_DETAIL to include historical premium for both Legacy and PC                               
  where trunc(trans_date) >= (to_date(add_months(:MONTH_END,5))-1916)  --this is 3.25 years prior                       
    and business_line_name = ('Farm Auto')                          
  group by policy_nbr                     
  )                           
having sum(premium_3yr) > 0                   
group by policy_search_nbr                       
)                             
                               
select p.policynumber                   
  ,p.primaryinsuredname                             
  ,p.periodstart                 
  ,p.periodend                  
  ,p.TOTALINFORCEPREMIUMRPT_EXT                   
  ,round(case when nvl(lr.incurred_loss_3yr,0) = 0 then 0 else nvl(lr.incurred_loss_3yr,0)/lr.premium_3yr end,3) THREE_YR_LR                   
  ,round(case when nvl(lr.incurred_loss_5yr,0) = 0 then 0 else nvl(lr.incurred_loss_5yr,0)/lr.premium_5yr end,3) FIVE_YR_LR                       
  ,nvl(lr.incurred_loss_2013,0) "2013"                     
  ,nvl(lr.incurred_loss_2014,0) "2014"                     
  ,nvl(lr.incurred_loss_2015,0) "2015"                     
  ,nvl(lr.incurred_loss_2016,0) "2016"                     
  ,nvl(lr.incurred_loss_2017,0) "2017"                     
  ,nvl(lr.incurred_loss_2018,0) "2018"                    
  ,min(nvl(c_irpm.ratemodifier,0)) IRPM               
  ,ma.domicile_state                      
  ,ma.agency_code                         
  ,ma.agency_name                       
  ,null UNDERWRITER                     
  ,p.cancellationdate                      
  ,null AGENCY_NR_EFF                
from datalake.pcvw_policyperiod p                        
  join (select row_number() over (partition by p.policynumber, p.termnumber, p.periodstart order by p.policymodelnumber desc) ROW_CT, p.*                           
        from datalake.pcvw_policyperiod p where p.period_status = 'Bound') prow                
    on (p.period_id = prow.period_id and prow.row_ct = 1) --identifies most recent record for each policy term                     
  join datalake.brvw_master_agency ma on (p.periodagencycode = ma.agency_code)                      
  left join loss_ratio lr on (p.policynumber = lr.policy_search_nbr) --Three-Year Loss Ratio (All Lines)                          
  left join njing.report_renewal_fleet fl on (p.policynumber = fl.policynumber and p.periodstart = fl.periodstart) --Fleet (Comm Auto)                    
--  left join njing.report_renewal_tiv tiv on (p.policynumber = tiv.policynumber and p.periodstart = tiv.periodstart) --TIV (BOP)                            
--  left join datalake.pcx_bp7linemod gl on (p.period_id = gl.branchid and gl.patterncode = 'CIG_BP7GLERC') --GL Experience Credit (BOP)               
--  left join datalake.pcx_bp7linemod md on (p.period_id = md.branchid and md.patterncode = 'CIG_BP7MDC') --Multiple Dispersion Credit (BOP)                              
--  left join datalake.pcx_bp7linemod lf on (p.period_id = lf.branchid and lf.patterncode = 'CIG_BP7LFC') --Loss Free Credit (BOP)                      
--  left join datalake.pcx_bp7linemod irpm on (p.period_id = irpm.branchid and irpm.patterncode = 'BP7IRPM') --IRPM (BOP)                   
  left join datalake.pcx_ca7linemod c_irpm on (p.period_id = c_irpm.branchid and c_irpm.patterncode in ('CIG_CA7MeritRatingPlan','CIG_CA7ScheduleRatingPlan')) --IRPM (Comm Auto)               
where p.dummy is null                  
  and p.period_status = 'Bound'                 
  and p.policytype = 'Farm Auto'                
  and p.totalpremiumrpt <> 0 --if most recent record for policy is 0, policy was canceled                  
  and trunc(p.periodend) > last_day(to_date(add_months(:MONTH_END,5)) - 55) --want policies four months out from current month. :MONTH_END is last day of prior month, so use 5 months                             
  and trunc(p.periodend) <= to_date(add_months(:MONTH_END,5)) --want policies four months out from current month. :MONTH_END is last day of prior month, so use 5 months                             
group by                             
  p.policynumber,                           
  case when agency_code in (17000) then 'Ventura'                         
    when agency_code in (17001,17005) then 'Anaheim'                 
    when agency_code in (17002,17009,17027,17030,17020) then 'Sacramento'                  
    when agency_code in (17012,17019,17029,45520,50007) then 'Nevada'                           
    when agency_code in (17024,41080) then 'North Coast'                            
    when agency_code in (26728,26730,66004,66501,66580,71508) then 'GOLF' --'ARM LIMO' shouldn't have these                               
    when agency_code in (48210,48212,24210,24212,26432,26433,27432,27433,71232,71233,24214,48214,26439) then 'GOLF' --Golf not in PC yet                 
    --when ((dept_nbr = 119) or (agency_code in (26728,26730,66004,66501,66580,71508))) then 'GOLF' --'ARM LIMO' shouldn't have these                     
    --when ((dept_nbr = 115) or (agency_code in (48210,48212,24210,24212,26432,26433,27432,27433,71232,71233,24214,48214,26439))) then 'GOLF' --Golf not in PC yet                  
    when agency_code in (48060,99001) or branch_number = 60 then 'GOLF' --'ARM OTHER'                          
    when branch_number = 81 then 'UVIS'                             
    else replace(replace(decode(branch_number,50,'Cal Cap',17,'Franchise Agents',branch_name),' Branch',''),' Office','') end                    
  ,p.primaryinsuredname                             
  ,p.periodstart                 
  ,p.periodend                  
  ,p.TOTALINFORCEPREMIUMRPT_EXT                   
  ,case when p.policytype = 'Farm Auto' then 'Farm Auto'                              
    else 'CHECK' end                         
  ,round(case when nvl(lr.incurred_loss_3yr,0) = 0 then 0 else nvl(lr.incurred_loss_3yr,0)/lr.premium_3yr end,3)                
  ,round(case when nvl(lr.incurred_loss_5yr,0) = 0 then 0 else nvl(lr.incurred_loss_5yr,0)/lr.premium_5yr end,3)                
  ,nvl(lr.incurred_loss_2013,0)                   
  ,nvl(lr.incurred_loss_2014,0)                   
  ,nvl(lr.incurred_loss_2015,0)                   
  ,nvl(lr.incurred_loss_2016,0)                   
  ,nvl(lr.incurred_loss_2017,0)                   
  ,nvl(lr.incurred_loss_2018,0)                   
  ,ma.domicile_state                      
  ,ma.agency_code                         
  ,ma.agency_name                       
  ,p.cancellationdate                      
;                              
