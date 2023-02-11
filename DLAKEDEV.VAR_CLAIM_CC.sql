CREATE TABLE  DLAKEDEV.VAR_CLAIM_CC AS
with vc as (
   select claim, policy, dec_policy, date_of_loss, catastrophe, claim_status,CLAIM_SOURCE
   from (
      select claim, policy, dec_policy, date_of_loss, catastrophe, claim_status,CLAIM_SOURCE
            ,row_number() over (partition by claim order by c_trans_date desc) c_rowmax
      from (select * from DLAKEDEV.VW_CLAIM cross join DATALAKE.L_EVALDATE where c_trans_date < evaldate)
    ) where c_rowmax=1
),
vcla as (
   select claim, defense_firm, defense_attorney, defense_cumis_council, plaintiff_firm, plaintiff_attorney
         ,cms_suit_status, cms_suit_type, cms_suit_reason, cms_suit_court_type, cms_suit_resolution_method
         ,suit_county, suit_state,CLAIM_SOURCE
   from (
      select claim, defense_firm, defense_attorney, defense_cumis_council, plaintiff_firm, plaintiff_attorney
            ,cms_suit_status, cms_suit_type, cms_suit_reason, cms_suit_court_type, cms_suit_resolution_method
            ,suit_county, suit_state,CLAIM_SOURCE
            ,row_number() over (partition by claim order by legal_trans_date desc) legal_rowmax
      from (select * from DLAKEDEV.VW_CMS_LEGAL_ACTION cross join DATALAKE.L_EVALDATE where legal_trans_date < evaldate)
    ) where legal_rowmax=1
),
varc as (
   select claim, policy, dec_policy, date_of_loss, catastrophe, claim_status
         ,defense_firm, defense_attorney, defense_cumis_council, plaintiff_firm, plaintiff_attorney
         ,cms_suit_status, cms_suit_type, cms_suit_reason, cms_suit_court_type, cms_suit_resolution_method
         ,suit_county, suit_state
         ,varc_trans_date,'' AS CLAIM_SOURCE
   from (
      select claim, policy, dec_policy, date_of_loss, catastrophe, claim_status
            ,defense_firm, defense_attorney, defense_cumis_council, plaintiff_firm, plaintiff_attorney
            ,cms_suit_status, cms_suit_type, cms_suit_reason, cms_suit_court_type, cms_suit_resolution_method
            ,suit_county, suit_state
            ,varc_trans_date,'' AS CLAIM_SOURCE
            ,row_number() over (partition by claim order by varc_trans_date desc) varc_rowmax
      from (select * from DATALAKE.VAR_CLAIM cross join DATALAKE.L_EVALDATE where varc_trans_date < evaldate - 1)
   ) where varc_rowmax=1
)
select claim, policy, dec_policy, date_of_loss, catastrophe, claim_status
      ,defense_firm, defense_attorney, defense_cumis_council, plaintiff_firm, plaintiff_attorney
      ,cms_suit_status, cms_suit_type, cms_suit_reason, cms_suit_court_type, cms_suit_resolution_method
      ,suit_county, suit_state
      ,varc_trans_date
      ,CLAIM_SOURCE
from (
   select claim, policy, dec_policy, date_of_loss, catastrophe, claim_status
         ,defense_firm, defense_attorney, defense_cumis_council, plaintiff_firm, plaintiff_attorney
         ,cms_suit_status, cms_suit_type, cms_suit_reason, cms_suit_court_type, cms_suit_resolution_method
         ,suit_county, suit_state
         ,min(varc_trans_date) as varc_trans_date, CLAIM_SOURCE
   from ((
      select  vc.claim, vc.policy, vc.dec_policy, vc.date_of_loss, vc.catastrophe, vc.claim_status
          ,vcla.defense_firm, vcla.defense_attorney, vcla.defense_cumis_council, vcla.plaintiff_firm, vcla.plaintiff_attorney
          ,vcla.cms_suit_status, vcla.cms_suit_type, vcla.cms_suit_reason, vcla.cms_suit_court_type, vcla.cms_suit_resolution_method
          ,vcla.suit_county, vcla.suit_state
          ,l_evaldate.evaldate - 1 as varc_trans_date
          , vc.CLAIM_SOURCE
      from vc
         left outer join vcla on vc.claim=vcla.claim
         cross join DATALAKE.L_EVALDATE
      ) union (select * from varc))
   group by claim, policy, dec_policy, date_of_loss, catastrophe, claim_status
         ,defense_firm, defense_attorney, defense_cumis_council, plaintiff_firm, plaintiff_attorney
         ,cms_suit_status, cms_suit_type, cms_suit_reason, cms_suit_court_type, cms_suit_resolution_method
         ,suit_county, suit_state,CLAIM_SOURCE
   ) cross join DATALAKE.L_EVALDATE
where varc_trans_date > (evaldate - 2)
;