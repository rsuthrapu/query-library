/*New Business*/	
select distinct dp.policy_search_nbr, to_number(to_char(to_date(trans_date),'mm')) "MONTH", a.domicile_state, dp.agency_code, dp.agency_name, dp.legal_name,	
  case when dept_nbr in (29,114,120,121,125,127) then 'Farm' else business_line_name end "BUSINESS_LINE_NAME", d.dept_nbr, d.dept_desc, dp.term_effective_date, 	
  case when a.agency_code in (24949,26906,26908,26910,26911,26914,26916,26917,26919,26922,	
    26924,26946,26947,26949,26951,26961,27250,27251,27252,27901,27902,27903, 27904,27905,27906,27908,27911,	
    27913,27916,27917,27918,27919,27922,27923,27924,27925,27945,27946,27947,27959,27961,47141,47179,47212,	
    47222,47225,47247,49951,50018,50022,50023,50024,50025,50035,50038,50039,50042,50043,50046,50048,50049,	
    50051,50053,50054,50056,50105,50147,50161,50950,50951,50952,71000,71001,71002,71005,71006,71008,71009,	
    71012,71013,71015,71016,71017,71018,71019,71020,71021,71022,71023,71024,71025,71025,71026,71027,71028,	
    71029,71030,71031,71032,71033,71034,71035,71036,71037,71038,71039,71040,71041,71042,71044,71045,71046,	
    71047,71048,71049,71050,71051,71052,71053,71054,71055,71056,71057,71058,71059,71060,71061,71062,71063,	
    71070,71071,71072,71073) then 'Washington Branch' when a.agency_code in (48060, 66420, 26700, 47471,	
    55001, 24210, 24212, 48210, 48212, 26432, 26433,27432, 27433, 71232, 71233, 24214,48214, 26439) then 'ARD'	
    else dp.branch_name end "BRANCH_NAME",	
  sum(p.written_prem) "NEW_WP" 	
from prem p, dec_policy dp, dept d, business_line bl, major_line ml, policy py1, policy py2, agency a	
where p.trans_date > to_date(:YEAR_END||'11:59:59 PM','dd-mon-yyyy hh:mi:ss PM') 	
  and p.trans_date <= to_date(:MONTH_END||'11:59:59 PM', 'dd-mon-yyyy hh:mi:ss PM') 	
  and p.dec_policy = dp.dec_policy	
  and p.dept = d.dept	
  and (d.dept_nbr in (29,114,120,121,125,127) or ml.major_line_name = 'Farm')	
  and d.business_line = bl.business_line	
  and d.major_line = ml.major_line	
  and dp.policy = py1.policy	
  and py1.renewed_from = py2.policy(+)	
  and dp.agency_code = a.agency_code	
  and nvl(py2.quote_flag, 1) = 1 	
  and nvl(dp.term_nbr,1)/decode(ml.major_line_name,'Auto',2,1) <= 1   	
  and dp.quote_flag = 0	
group by dp.policy_search_nbr, to_number(to_char(to_date(trans_date),'mm')), a.domicile_state, dp.agency_code, dp.agency_name, dp.legal_name,	
  case when dept_nbr in (29,114,120,121,125,127) then 'Farm' else business_line_name end, d.dept_nbr,dept_desc, dp.term_effective_date, 	
  case when a.agency_code in (24949,26906,26908,26910,26911,26914,26916,26917,26919,26922,	
    26924,26946,26947,26949,26951,26961,27250,27251,27252,27901,27902,27903, 27904,27905,27906,27908,27911,	
    27913,27916,27917,27918,27919,27922,27923,27924,27925,27945,27946,27947,27959,27961,47141,47179,47212,	
    47222,47225,47247,49951,50018,50022,50023,50024,50025,50035,50038,50039,50042,50043,50046,50048,50049,	
    50051,50053,50054,50056,50105,50147,50161,50950,50951,50952,71000,71001,71002,71005,71006,71008,71009,	
    71012,71013,71015,71016,71017,71018,71019,71020,71021,71022,71023,71024,71025,71025,71026,71027,71028,	
    71029,71030,71031,71032,71033,71034,71035,71036,71037,71038,71039,71040,71041,71042,71044,71045,71046,	
    71047,71048,71049,71050,71051,71052,71053,71054,71055,71056,71057,71058,71059,71060,71061,71062,71063,	
    71070,71071,71072,71073) then 'Washington Branch' when a.agency_code in (48060, 66420, 26700, 47471,	
    55001, 24210, 24212, 48210, 48212, 26432, 26433,27432, 27433, 71232, 71233, 24214,48214, 26439) then 'ARD'	
    else dp.branch_name end;	
 	
/*Canceled Business*/	
/*This query is impossible to run unless you create a table out of the subquery first*/	
select distinct p.policy_search_nbr, to_number(to_char(to_date(p.cancel_effective_date ),'mm')) "MONTH", d.dept_nbr, a.agency_code, a.agency_name,	
  case when to_date(p.cancel_effective_date) = to_date(p.term_effective_date) then 'CXD AT RENEWAL'	
    when to_date(p.cancel_effective_date) = to_date(p.term_expiration_date) then 'CXD AT RENEWAL' else 'CXD MID-TERM' end "CX_TIME", p.policy_status,	
  p.term_effective_date, p.term_expiration_date, p.cancel_effective_date, ni.legal_name, nr.subject, nr.subject_text, prm.premium	
from policy p, dec_policy dp, agency a, policy_reason pr, notice_reason nr, parent_agency pa, prem pm, dept d, major_line m, named_insured ni,	
 (select policy_search_nbr, sum(inforce_prem) "PREMIUM"	
  from prem pm, dec_policy dp, dept d, major_line m	
  where pm.dec_policy = dp.dec_policy	
    and pm.term_nbr = dp.term_nbr	
    and pm.dept = d.dept	
    and m.major_line = d.major_line	
    and (dept_nbr in (29,114,120,121,125,127) or major_line_name = 'Farm')	
    and dp.dec_sequence = (select (max(dec_sequence)-1) from dec_policy dp2 where dp2.policy = dp.policy)	
  group by policy_search_nbr) prm	
where p.agency_code = a.agency_code	
  and p.policy = pr.policy	
  and dp.policy = p.policy	
  and pr.notice_reason = nr.notice_reason	
  and ni.named_insured = p.named_insured	
  and p.quote_flag = 0	
  and pm.policy = p.policy	
  and pm.dept = d.dept	
  and m.major_line = d.major_line	
  and prm.policy_search_nbr = p.policy_search_nbr	
  and a.parent_agency = pa.parent_agency	
  and dp.dec_sequence = (select max(dec_sequence) from dec_policy dp2 where dp2.policy = dp.policy and dp.dec_type = 'Cancel')	
  and dp.term_nbr = pm.term_nbr	
  --and nr.subject not in ('Non-Payment','Rewritten','Effective Date Revised')	
  and p.policy_status not in ('Active','Hold','Declined Application')	
  and (dept_nbr in (29,114,120,121,125,127) or major_line_name = 'Farm')	
  and ((p.cancel_effective_date between to_date(:YEAR_END||' 11:59:59 PM', 'dd-mon-yyyy hh:mi:ss PM') and to_date(:MONTH_END||' 11:59:59 PM', 'dd-mon-yyyy hh:mi:ss PM'))	
  or ((p.policy_status = 'Non-Renewed') and	
      ((p.term_effective_date between to_date(:YEAR_END||' 11:59:59 PM', 'dd-mon-yyyy hh:mi:ss PM')and to_date(:MONTH_END||' 11:59:59 PM','dd-mon-yyyy hh:mi:ss PM')) or (p.term_expiration_date between to_date(:YEAR_END||' 11:59:59 PM', 'dd-mon-yyyy hh:mi:ss PM') and to_date(:MONTH_END||' 11:59:59 PM', 'dd-mon-yyyy hh:mi:ss PM')))	
      ))	
order by month;	
 	
 	
/*Loss*/	
select nvl(to_char(dd.claim_nbr),'TOTAL') CLAIM_NBR, dl.dept_desc DEPARTMENT, b.branch_name BRANCH, dd.agency_code, policy_nbr, dd.insured_name, dd.date_of_loss,	
  sum(case when to_char(dl.trans_date,'mm') = '01' then nvl(dl.loss_reserve,0) else 0 end) JAN_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '01' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) JAN_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '02' then nvl(dl.loss_reserve,0) else 0 end) FEB_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '02' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) FEB_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '03' then nvl(dl.loss_reserve,0) else 0 end) MAR_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '03' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) MAR_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '04' then nvl(dl.loss_reserve,0) else 0 end) APR_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '04' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) APR_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '05' then nvl(dl.loss_reserve,0) else 0 end) MAY_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '05' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) MAY_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '06' then nvl(dl.loss_reserve,0) else 0 end) JUN_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '06' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) JUN_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '07' then nvl(dl.loss_reserve,0) else 0 end) JUL_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '07' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) JUL_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '08' then nvl(dl.loss_reserve,0) else 0 end) AUG_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '08' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) AUG_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '09' then nvl(dl.loss_reserve,0) else 0 end) SEP_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '09' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) SEP_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '10' then nvl(dl.loss_reserve,0) else 0 end) OCT_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '10' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) OCT_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '11' then nvl(dl.loss_reserve,0) else 0 end) NOV_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '11' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) NOV_ALAE_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '12' then nvl(dl.loss_reserve,0) else 0 end) DEC_LOSS_INC,	
  sum(case when to_char(dl.trans_date,'mm') = '12' then nvl(dl.alloc_expense_reserve,0) + nvl(dl.unalloc_expense_reserve,0) else 0 end) DEC_ALAE_INC,	
  sum(nvl(dl.loss_reserve,0)) YEAR_INCURRED,	
  sum(nvl(dl.alloc_expense_reserve,0)) + sum(nvl(dl.unalloc_expense_reserve,0)) YEAR_ALAE_INC,dl.SOURCE	
from dw_claimant_detail dl, dw_claimant dd, agency a, branch b	
where dl.claimant_key = dd.claimant_key	
 and trans_date > to_date(:YEAR_END||' 11:59:59 PM', 'dd-mon-yyyy hh:mi:ss PM')	
 and trans_date <= to_date(:MONTH_END||' 11:59:59 PM', 'dd-mon-yyyy hh:mi:ss PM')	
  and dd.agency_code = a.agency_code	
  and a.branch = b.branch	
  and (dept_nbr in (29,114,120,121,125,127) or major_line_name = 'Farm')
  group by nvl(to_char(dd.claim_nbr),'TOTAL'), to_char(dd.claim_nbr), dd.claim_nbr, 'TOTAL', dl.dept_desc, 
b.branch_name, dd.agency_code, policy_nbr, dd.insured_name, dd.date_of_loss, 
dl.SOURCE	
having (abs(sum(case when to_char(dl.trans_date,'mm') = '01' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '01' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+ 	
  abs(sum(case when to_char(dl.trans_date,'mm') = '02' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '02' then nvl(dl.unalloc_expense_reserve,0) else 0 end)) +	
  abs(sum(case when to_char(dl.trans_date,'mm') = '03' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '03' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+ 	
  abs(sum(case when to_char(dl.trans_date,'mm') = '04' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '04' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+ 	
  abs(sum(case when to_char(dl.trans_date,'mm') = '05' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '05' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+ 	
  abs(sum(case when to_char(dl.trans_date,'mm') = '06' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '06' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '07' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '07' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+ 	
  abs(sum(case when to_char(dl.trans_date,'mm') = '08' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '08' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '09' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '09' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+ 	
  abs(sum(case when to_char(dl.trans_date,'mm') = '10' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '10' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+ 	
  abs(sum(case when to_char(dl.trans_date,'mm') = '11' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '11' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '12' then nvl(dl.alloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '12' then nvl(dl.unalloc_expense_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '01' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '02' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '03' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '04' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '05' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '06' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '07' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '08' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '09' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '10' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '11' then nvl(dl.loss_reserve,0) else 0 end))+	
  abs(sum(case when to_char(dl.trans_date,'mm') = '12' then nvl(dl.loss_reserve,0) else 0 end))) <> 0;
 	
 	
/*Line Data*/	
select :YEAR YEAR, :MONTH MONTH, case when dept_nbr in (29,114,120,121,125,127) then 'Farm' else major_line_name end MAJOR_LINE_NAME,	
    case when dept_nbr in (29,114,120,121,125,127) then 'Farm' else business_line_name end BUSINESS_LINE_NAME,	
    case when agency_code in (24949,26906,26907,26908,26910,26911,26914, 26916,26917,26919,26922,26924,26946,26947,26949,26951,26961,27250,27251,	
      27252,27901,27902,27903,27904,27905,27906,27908,27909,27911,27913,27916,27917,27918,27919,27922,27923,27924,27925,27945,27946,27947,27959,	
      27961,47141,47179,47212,47222,47225,47247,49951,50018,50022,50023,50024,50025,50035,50038,50039,50042,50043,50046,50048,50049,50051,50053,	
      50054,50056,50105,50147,50161,50950,50951,50952,71000,71001,71002,71005,71006,71008,71009,71010,71011,71012,71013,71015,71016,71017,71018,	
      71019,71020,71021,71022,71023,71024,71025,71025,71026,71027,71028,71029,71030,71031,71032,71033,71034,71035,71036,71037,71038,71039,71040,	
      71041,71042,71044,71045,71046,71047,71048,71049,71050,71051,71052,71053,71054,71055,71056,71057,71058,71059,71060,71061,71062,71063,71070,	
      71071,71072,71073) then 25 when agency_code in (48060, 66420, 26700, 47471, 55001, 24210, 24212, 48210, 48212, 26432, 26433,	
      27432, 27433, 71232, 71233, 24214,48214, 26439) then 60 else branch_nbr end BRANCH_NBR,	
    case when agency_code in (24949,26906,26907,26908,26910,26911,26914, 26916,26917,26919,26922,26924,26946,26947,26949,26951,26961,27250,27251,	
      27252,27901,27902,27903,27904,27905,27906,27908,27909,27911,27913,27916,27917,27918,27919,27922,27923,27924,27925,27945,27946,27947,27959,	
      27961,47141,47179,47212,47222,47225,47247,49951,50018,50022,50023,50024,50025,50035,50038,50039,50042,50043,50046,50048,50049,50051,50053,	
      50054,50056,50105,50147,50161,50950,50951,50952,71000,71001,71002,71005,71006,71008,71009,71010,71011,71012,71013,71015,71016,71017,71018,	
      71019,71020,71021,71022,71023,71024,71025,71025,71026,71027,71028,71029,71030,71031,71032,71033,71034,71035,71036,71037,71038,71039,71040,	
      71041,71042,71044,71045,71046,71047,71048,71049,71050,71051,71052,71053,71054,71055,71056,71057,71058,71059,71060,71061,71062,71063,71070,	
      71071,71072,71073) then 'Washington Branch' when agency_code in (48060, 66420, 26700, 47471, 55001, 24210, 24212, 48210, 48212, 26432, 26433,	
      27432, 27433, 71232, 71233, 24214,48214, 26439) then 'Alternative Markets Programs'	
      else decode(branch_nbr,77,'Non-Admitted',88,'Non-Admitted CA',branch_name) end BRANCH_NAME,	
    dept_nbr||' - '||dept_desc DEPT_NAME,	
    round(sum(decode(year||month,:YEAR-1||:MONTH,nvl(mth_direct_written_prem,0),0)),0) M_PRI_WP,	
    round(sum(decode(year||month,:YEAR||:MONTH,nvl(mth_direct_written_prem,0),0)),0) M_CUR_WP,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(mth_direct_loss_incurred,0)+nvl(mth_direct_alloc_exp_inc,0)+nvl(mth_direct_unalloc_exp_inc,0),0)) M_CUR_L_ALAE_I,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(mth_direct_earned_prem,0),0)) M_CUR_EP,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(mth_inforce_policy_ct,0),0)) M_CUR_POL,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(mth_inforce_policy_ct,0),0)) - sum(decode(year||month,decode(:MONTH,1,:YEAR-1,:YEAR)||decode(:MONTH,1,12,:MONTH-1),nvl(mth_inforce_policy_ct,0),0)) M_POL_CHG,	
    sum(decode(year||month,:YEAR-1||:MONTH,nvl(mth_new_policy_ct,0),0)) M_NEW_POL_PRI,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(mth_new_policy_ct,0),0)) M_NEW_POL_CUR,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(mth_new_policy_ct,0),0)) - sum(decode(year||month,:YEAR-1||:MONTH,nvl(mth_new_policy_ct,0),0)) M_NEW_DIF,	
    round(sum(decode(year||month,:YEAR-1||:MONTH,nvl(ytd_direct_written_prem,0),0)),0) Y_PRI_WP,	
    round(sum(decode(year||month,:YEAR||:MONTH,nvl(ytd_direct_written_prem,0),0)),0) Y_CUR_WP,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(ytd_direct_loss_incurred,0)+nvl(ytd_direct_alloc_exp_inc,0)+nvl(ytd_direct_unalloc_exp_inc,0),0)) Y_CUR_L_ALAE_I,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(ytd_direct_earned_prem,0),0)) Y_CUR_EP,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(mth_inforce_policy_ct,0),0)) - sum(decode(year||month,:YEAR-1||12,nvl(mth_inforce_policy_ct,0),0)) Y_POL_CHG,	
    sum(decode(year||month,:YEAR-1||:MONTH,nvl(ytd_new_policy_ct,0),0)) Y_NEW_POL_PRI,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(ytd_new_policy_ct,0),0)) Y_NEW_POL_CUR,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(ytd_new_policy_ct,0),0)) - sum(decode(year||month,:YEAR-1||:MONTH,nvl(ytd_new_policy_ct,0),0)) Y_NEW_DIF,	
    sum(decode(year||month,:YEAR||:MONTH,nvl(mth_inforce_policy_ct,0),0)) - (sum(decode(year||month,:YEAR||:MONTH,nvl(past_12mth_new_policy_ct,0) ,0)) - sum(decode(year||month,:YEAR||:MONTH,nvl(past_12mth_new_cx_policy_ct,0),0))) "Y_POL_NON_NEW",	
    sum(decode(year||month,:YEAR-1||:MONTH,nvl(mth_inforce_policy_ct,0),0)) Y_PRI_POL,	
    agency_state,	
    case when dept_nbr in (29,114,120,121,125,127) then 'FARM' else decode(major_line_name,'Personal','PERS','Auto','PERS','Farm','FARM','Non Admitted','NA','COMM') end SUB_ML,	
    case when branch_nbr in (66,77,88) then 'JEFF G' else 'WALT' end HANDLED_BY,	
    case when (agency_code like '990%' or agency_code in (48060,66420,26700,47471,55001,24210,24212,48210,48212,26432,26433,27432,27433,71232,71233,24214,48214,26439)) then 'ARD'	
      else 'OTHER' end ALT_RISK, 'Yes' FARM	
from dw_summary dw	
where month in (12,:MONTH,:MONTH-1)	
  and year in (:YEAR,:YEAR-1)	
  and dept_nbr in (29,31,32,33,37,38,114,120,121,125,127)	
having abs(round(sum(decode(year||month,(:YEAR-1)||:MONTH,nvl(mth_direct_written_prem,0),0)),0)) +	
    abs(round(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_direct_written_prem,0),0)),0)) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_direct_loss_incurred,0),0))) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_direct_alloc_exp_inc,0),0)))+	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_direct_unalloc_exp_inc,0),0)))+	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_direct_earned_prem,0),0))) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_inforce_policy_ct,0),0))) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_inforce_policy_ct,0),0))-sum(decode(year||month,(decode(:MONTH,1,:YEAR-1,:YEAR))||(decode(:MONTH,1,12,:MONTH-1)),nvl(mth_inforce_policy_ct,0),0))) +	
    abs(sum(decode(year||month,(:YEAR-1)||:MONTH,nvl(mth_new_policy_ct,0),0))) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_new_policy_ct,0),0))) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_new_policy_ct,0),0))-sum(decode(year||month,(:YEAR-1)||:MONTH,nvl(mth_new_policy_ct,0),0))) +	
    abs(round(sum(decode(year||month,(:YEAR-1)||:MONTH,nvl(ytd_direct_written_prem,0),0)),0)) +	
    abs(round(sum(decode(year||month,(:YEAR)||:MONTH,nvl(ytd_direct_written_prem,0),0)),0)) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(ytd_direct_loss_incurred,0),0))) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(ytd_direct_alloc_exp_inc,0),0)))+	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(ytd_direct_unalloc_exp_inc,0),0)))+	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(ytd_direct_earned_prem,0),0)) ) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(mth_inforce_policy_ct,0),0))-sum(decode(year||month,(:YEAR-1)||12,nvl(mth_inforce_policy_ct,0),0))) +	
    abs(sum(decode(year||month,(:YEAR-1)||:MONTH,nvl(ytd_new_policy_ct,0),0))) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(ytd_new_policy_ct,0),0))) +	
    abs(sum(decode(year||month,(:YEAR)||:MONTH,nvl(ytd_new_policy_ct,0),0))-sum(decode(year||month,(:YEAR-1)||:MONTH,nvl(ytd_new_policy_ct,0),0))) +	
    abs(sum(decode(year||month,(:YEAR)||(:MONTH),nvl(mth_inforce_policy_ct,0),0)) - (sum(decode(year||month,(:YEAR)||(:MONTH),nvl(past_12mth_new_policy_ct,0) ,0)) - sum(decode(year||month,(:YEAR)||(:MONTH),nvl(past_12mth_new_cx_policy_ct,0),0)))) +	
    abs(sum(decode(year||month,(:YEAR-1)||(:MONTH),nvl(mth_inforce_policy_ct,0),0))) <> 0	
group by case when dept_nbr in (29,114,120,121,125,127) then 'Farm' else major_line_name end,	
    case when dept_nbr in (29,114,120,121,125,127) then 'Farm' else business_line_name end,	
    case when agency_code in (24949,26906,26907,26908,26910,26911,26914, 26916,26917,26919,26922,26924,26946,26947,26949,26951,26961,27250,27251,	
      27252,27901,27902,27903,27904,27905,27906,27908,27909,27911,27913,27916,27917,27918,27919,27922,27923,27924,27925,27945,27946,27947,27959,	
      27961,47141,47179,47212,47222,47225,47247,49951,50018,50022,50023,50024,50025,50035,50038,50039,50042,50043,50046,50048,50049,50051,50053,	
      50054,50056,50105,50147,50161,50950,50951,50952,71000,71001,71002,71005,71006,71008,71009,71010,71011,71012,71013,71015,71016,71017,71018,	
      71019,71020,71021,71022,71023,71024,71025,71025,71026,71027,71028,71029,71030,71031,71032,71033,71034,71035,71036,71037,71038,71039,71040,	
      71041,71042,71044,71045,71046,71047,71048,71049,71050,71051,71052,71053,71054,71055,71056,71057,71058,71059,71060,71061,71062,71063,71070,	
      71071,71072,71073) then 25 when agency_code in (48060, 66420, 26700, 47471, 55001, 24210, 24212, 48210, 48212, 26432, 26433,	
      27432, 27433, 71232, 71233, 24214,48214, 26439) then 60 else branch_nbr end,	
    case when agency_code in (24949,26906,26907,26908,26910,26911,26914, 26916,26917,26919,26922,26924,26946,26947,26949,26951,26961,27250,27251,	
      27252,27901,27902,27903,27904,27905,27906,27908,27909,27911,27913,27916,27917,27918,27919,27922,27923,27924,27925,27945,27946,27947,27959,	
      27961,47141,47179,47212,47222,47225,47247,49951,50018,50022,50023,50024,50025,50035,50038,50039,50042,50043,50046,50048,50049,50051,50053,	
      50054,50056,50105,50147,50161,50950,50951,50952,71000,71001,71002,71005,71006,71008,71009,71010,71011,71012,71013,71015,71016,71017,71018,	
      71019,71020,71021,71022,71023,71024,71025,71025,71026,71027,71028,71029,71030,71031,71032,71033,71034,71035,71036,71037,71038,71039,71040,	
      71041,71042,71044,71045,71046,71047,71048,71049,71050,71051,71052,71053,71054,71055,71056,71057,71058,71059,71060,71061,71062,71063,71070,	
      71071,71072,71073) then 'Washington Branch' when agency_code in (48060, 66420, 26700, 47471, 55001, 24210, 24212, 48210, 48212, 26432, 26433,	
      27432, 27433, 71232, 71233, 24214,48214, 26439) then 'Alternative Markets Programs'	
      else decode(branch_nbr,77,'Non-Admitted',88,'Non-Admitted CA',branch_name) end,	
    dept_nbr||' - '||dept_desc, agency_state,	
    case when dept_nbr in (29,114,120,121,125,127) then 'FARM' else decode(major_line_name,'Personal','PERS','Auto','PERS','Farm','FARM','Non Admitted','NA','COMM') end,	
    case when branch_nbr in (66,77,88) then 'JEFF G' else 'WALT' end,	
    case when (agency_code like '990%' or agency_code in (48060,66420,26700,47471,55001,24210,24212,48210,48212,26432,26433,27432,27433,71232,71233,24214,48214,26439)) then 'ARD'	
      else 'OTHER' end;	
