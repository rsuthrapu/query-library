-------------------------------------------------------
--  DDL for View VW_THEFTCOL
--------------------------------------------------------

CREATE OR REPLACE FORCE EDITIONABLE VIEW "DLAKEDEV"."VW_THEFTCOL" ("CLAIMANT_COVERAGE", "THEFT_TRANS_DATE", "THEFT_LOAD_DATE", "THEFT_ITEMS", "TCOL_ART_OR_ANTIQUE", "TCOL_AUDIO_VISUAL", "TCOL_CASH", "TCOL_CLOTHING", "TCOL_COMPUTER_EQUIPMENT", "TCOL_ENGINE", "TCOL_FURS", "TCOL_GUNS", "TCOL_JEWELRY", "TCOL_MOBILE_EQUIPMENT", "TCOL_OFFICE_EQUIPMENT", "TCOL_OTHER", "TCOL_OUTDRIVE", "TCOL_SILVERWARE", "TCOL_SPORTS_EQUIPMENT", "TCOL_TOOLS","CLAIM_SOURCE") AS 
with td as (
   select claimant_coverage, cms_theft_item, trunc(last_modified) as last_modified, load_date, 'CMS' AS CLAIM_SOURCE
   from DATALAKE.DAILY_CMS_COL_THEFT_DETAIL
    
   union
   
   select tdetail.claimant_coverage, cms_theft_item, lm as last_modified, load_date, 'CMS' AS CLAIM_SOURCE
   from DATALAKE.DAILY_CMS_COL_THEFT_DETAIL tdetail
      inner join (select distinct claimant_coverage, trunc(last_modified) as lm from DAILY_CMS_COL_THEFT_DETAIL) tkey
      on tdetail.claimant_coverage=tkey.claimant_coverage
   where trunc(last_modified) < lm
   
   UNION
   
   select EX.ID AS claimant_coverage, tllpy.ID AS cms_theft_item, EX.UPDATETIME AS last_modified,
   EX.load_date , 'CC' AS CLAIM_SOURCE from 
    DAILY_CC_EXPOSURE EX 
    left outer join DLAKEDEV.DAILY_CCTL_LOSTPROPERTYTYPE tllpy on tllpy.id = ex.LostPropertyType
)
select claimant_coverage, last_modified as theft_trans_date, load_date as theft_load_date
         ,'|' || nvl2(ART_OR_ANTIQUE,' ART_OR_ANTIQUE |',NULL) || nvl2(AUDIO_VISUAL,' AUDIO_VISUAL |',NULL) 
              || nvl2(CASH,' CASH |',NULL) || nvl2(CLOTHING,' CLOTHING |',NULL) 
              || nvl2(COMPUTER_EQUIPMENT,' COMPUTER_EQUIPMENT |',NULL) || nvl2(ENGINE,' ENGINE |',NULL)
              || nvl2(FURS,' FURS |',NULL) || nvl2(GUNS,' GUNS |',NULL) || nvl2(JEWELRY,' JEWELRY |',NULL)
              || nvl2(MOBILE_EQUIPMENT,' MOBILE_EQUIPMENT |',NULL) || nvl2(OFFICE_EQUIPMENT,' OFFICE_EQUIPMENT |',NULL)
              || nvl2(OTHER,' OTHER |',NULL) || nvl2(OUTDRIVE,' OUTDRIVE |',NULL) || nvl2(SILVERWARE,' SILVERWARE |',NULL)
              || nvl2(SPORTS_EQUIPMENT,' SPORTS_EQUIPMENT |',NULL) || nvl2(TOOLS,' TOOLS |',NULL)
          as theft_items
         ,nvl(ART_OR_ANTIQUE,'N') as TCOL_ART_OR_ANTIQUE, nvl(AUDIO_VISUAL,'N') as TCOL_AUDIO_VISUAL
         ,nvl(CASH,'N') as TCOL_CASH, nvl(CLOTHING,'N') as TCOL_CLOTHING
         ,nvl(COMPUTER_EQUIPMENT,'N') as TCOL_COMPUTER_EQUIPMENT, nvl(ENGINE,'N') as TCOL_ENGINE
         ,nvl(FURS,'N') as TCOL_FURS, nvl(GUNS,'N') as TCOL_GUNS, nvl(JEWELRY,'N') as TCOL_JEWELRY
         ,nvl(MOBILE_EQUIPMENT,'N') as TCOL_MOBILE_EQUIPMENT, nvl(OFFICE_EQUIPMENT,'N') as TCOL_OFFICE_EQUIPMENT
         ,nvl(OTHER,'N') as TCOL_OTHER, nvl(OUTDRIVE,'N') as TCOL_OUTDRIVE, nvl(SILVERWARE,'N') as TCOL_SILVERWARE
         ,nvl(SPORTS_EQUIPMENT,'N') as TCOL_SPORTS_EQUIPMENT, nvl(TOOLS,'N') as TCOL_TOOLS
         ,CLAIM_SOURCE
   from (
      select * from (
         select td.claimant_coverage, trunc(td.last_modified) as last_modified, td.load_date,TD.CLAIM_SOURCE
            ,replace(replace(replace(upper(ti.theft_item_desc),'/','_OR_'),' - ','_'),' ','_') as theft_col
            ,'Y' as theft_rownum
         from td inner join DATALAKE.DAILY_CMS_THEFT_ITEM ti on td.cms_theft_item=ti.cms_theft_item
         left outer join DLAKEDEV.DAILY_CCTL_LOSTPROPERTYTYPE tllpys on td.cms_theft_item = tllpys.ID
      )
      pivot
         (max(theft_rownum) for theft_col
          in ( 'ART_OR_ANTIQUE' as ART_OR_ANTIQUE, 'AUDIO_VISUAL' as AUDIO_VISUAL, 'CASH' as CASH
              ,'CLOTHING' as CLOTHING, 'COMPUTER_EQUIPMENT' as COMPUTER_EQUIPMENT, 'ENGINE' as ENGINE
              ,'FURS' as FURS, 'GUNS' as GUNS, 'JEWELRY' as JEWELRY, 'MOBILE_EQUIPMENT' as MOBILE_EQUIPMENT
              ,'OFFICE_EQUIPMENT' as OFFICE_EQUIPMENT, 'OTHER' as OTHER, 'OUTDRIVE' as OUTDRIVE
              ,'SILVERWARE' as SILVERWARE, 'SPORTS_EQUIPMENT' as SPORTS_EQUIPMENT, 'TOOLS' as TOOLS
              )
          )
      order by claimant_coverage, last_modified, load_date
   );