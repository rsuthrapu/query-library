create table DLAKEDEV.VAR_CLAIMANT_TRANS_CC as
with cctstatus as (
   select row_number() over (partition by claimant_coverage order by transdate, transtime, claimant_trans) ccstatus_row_num
         ,claimant_coverage, claimant_trans, transtime, transaction_primary, transaction_status,CLAIM_SOURCE as tsjoin
   from (select * from DLAKEDEV.VW_CLAIMANT_TRANS where transaction_status in('Closed','Open','Reopen'))
),
cctstatus2 as (
   select row_number() over (partition by claimant_coverage order by transdate, transtime, claimant_trans)+1 ccstatus_row_num2
         ,claimant_coverage as claimant_coverage2
         ,transaction_status as tsjoin2
         ,CLAIM_SOURCE
   from (select * from DLAKEDEV.VW_CLAIMANT_TRANS where transaction_status in('Closed','Open','Reopen'))
),
addstatus as (
   select claimant_trans, transtime,CLAIM_SOURCE
         ,ccstatus_row_num as srn
         ,case when transaction_primary='Open' then 'Open'
               when transaction_primary='Reopen' and ccstatus_row_num = 1 then 'Open'
               when transaction_primary='Reopen' and ccstatus_row_num > 1 then 'Reopen'
               when transaction_primary='Fast Track' and ccstatus_row_num = 1 then 'Fast Track'
               when transaction_primary='Fast Track' and ccstatus_row_num = 2 then 'Closed'
               when transaction_primary='Fast Track' and ccstatus_row_num > 2 then 'Reclosed'
               when transaction_primary in('Closed','Final Payment') and ccstatus_row_num < 3 then 'Closed'
               when transaction_primary in('Closed','Final Payment') and ccstatus_row_num > 2 then 'Reclosed'
          end ts
   from cctstatus
      left outer join cctstatus2 on cctstatus.claimant_coverage=cctstatus2.claimant_coverage2 and
                                    cctstatus.ccstatus_row_num=cctstatus2.ccstatus_row_num2
   where cctstatus.tsjoin != cctstatus2.tsjoin2 or cctstatus2.tsjoin2 is null
)
   select vwtrans.claimant_trans, vwtrans.claimant_coverage, vwtrans.transaction_date, vwtrans.transdate, vwtrans.transtime
         ,vwtrans.transaction_type, vwtrans.transaction_primary
         ,case when transaction_primary = 'Payment - No O/S reserves' then 99
               when srn is null then -1
               else srn
          end status_row_num
         ,case when transaction_primary = 'Payment - No O/S reserves' then 'Payment NOR'
               when ts is null then 'Other'
               else ts
          end transaction_status
         ,check_payable, draft_number, expense_code
         ,os_loss, os_alae, os_ulae, paid_loss, paid_alae, paid_ulae
         ,vwtrans.load_date
         ,vwtrans.CLAIM_SOURCE
   from DLAKEDEV.VW_CLAIMANT_TRANS vwtrans
      left outer join addstatus on vwtrans.claimant_trans=addstatus.claimant_trans and vwtrans.transtime=addstatus.transtime;