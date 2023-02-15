--------------------------------------------------------
--  DDL for View VW_WATERCOL
--------------------------------------------------------

CREATE OR REPLACE FORCE EDITIONABLE VIEW "DLAKEDEV"."VW_WATERCOL" ("CLAIMANT_COVERAGE", "WATER_TRANS_DATE", "WATER_LOAD_DATE", "WATER_LOSSTYPES", "WCOL_APPLIANCE", "WCOL_BACKUP_OR_OVERFLOW", "WCOL_BASEMENT_FLOODED", "WCOL_DRAIN_LINE_LEAK", "WCOL_FAILED_MATERIAL", "WCOL_FAUCET_LEFT_OPEN", "WCOL_FREEZE_FIRE_SPRINKLERS", "WCOL_FREEZE_OT_FIRE_SPRINKLERS", "WCOL_OCCUPANT_AWAY", "WCOL_PROPERTY_VACANT", "WCOL_RAIN_WATER_INTRUSION", "WCOL_ROOF", "WCOL_SLAB_LEAK", "WCOL_SUPPLY_LINE", "WCOL_TOILET_LEAK", "WCOL_TREE_ROOTS", "WCOL_WALL_OR_CEILING_LEAK", "WCOL_WATER_HEATER_OR_HVAC", "WCOL_WINDOW","CLAIM_SOURCE") AS 
 with wd as (
   select claimant_coverage, cms_water_loss_factor, trunc(last_modified) as last_modified, load_date, 'CMS' AS CLAIM_SOURCE
   from DATALAKE.DAILY_CMS_COL_WATERLOSS_DETAIL
   where cms_col_waterloss_detail != 5166
   
   union
   
   select wdetail.claimant_coverage, cms_water_loss_factor, lm as last_modified, load_date, 'CMS' AS CLAIM_SOURCE
   from (select * from DATALAKE.DAILY_CMS_COL_WATERLOSS_DETAIL where cms_col_waterloss_detail != 5166) wdetail
      inner join (select distinct claimant_coverage, trunc(last_modified) as lm from DATALAKE.DAILY_CMS_COL_WATERLOSS_DETAIL where cms_col_waterloss_detail != 5166) wkey
      on wdetail.claimant_coverage=wkey.claimant_coverage
   where trunc(last_modified) < lm
   
    UNION
   
   -- do not find 5166
   select EX.ID AS claimant_coverage, TLWS.ID AS cms_water_loss_factor, EX.UPDATETIME AS last_modified, TLWS.load_date, 'CC' AS CLAIM_SOURCE from 
    DLAKEDEV.DAILY_CC_CLAIM C
    INNER JOIN DLAKEDEV.DAILY_CC_EXPOSURE EX ON EX.CLAIMID=C.ID AND EX.RETIRED=0
    LEFT OUTER JOIN DLAKEDEV.DAILY_CC_PROPERTYWATERDAMAGE PRWD ON PRWD.CLAIMID = C.ID
    LEFT OUTER JOIN DLAKEDEV.DAILY_CCTL_WATERSOURCE TLWS ON TLWS.ID = PRWD.WATERSOURCE
)

select claimant_coverage, last_modified as water_trans_date, load_date as water_load_date
         ,'|' || nvl2(APPLIANCE,' APPLIANCE |',NULL) || nvl2(BACKUP_OR_OVERFLOW,' BACKUP_OR_OVERFLOW |',NULL) 
              || nvl2(BASEMENT_FLOODED,' BASEMENT_FLOODED |',NULL) || nvl2(DRAIN_LINE_LEAK,' DRAIN_LINE_LEAK |',NULL) 
              || nvl2(FAILED_MATERIAL,' FAILED_MATERIAL |',NULL) || nvl2(FAUCET_LEFT_OPEN,' FAUCET_LEFT_OPEN |',NULL)
              || nvl2(FREEZE_FIRE_SPRINKLERS,' FREEZE_FIRE_SPRINKLERS |',NULL) || nvl2(FREEZE_OT_FIRE_SPRINKLERS,' FREEZE_OT_FIRE_SPRINKLERS |',NULL)
              || nvl2(OCCUPANT_AWAY_FROM_PREMISES,' OCCUPANT_AWAY_FROM_PREMISES |',NULL) || nvl2(PROPERTY_VACANT,' PROPERTY_VACANT |',NULL)
              || nvl2(RAIN_WATER_INTRUSION,' RAIN_WATER_INTRUSION |',NULL) || nvl2(ROOF,' ROOF |',NULL) || nvl2(SLAB_LEAK,' SLAB_LEAK |',NULL)
              || nvl2(SUPPLY_LINE,' SUPPLY_LINE |',NULL) || nvl2(TOILET_LEAK,' TOILET_LEAK |',NULL) || nvl2(TREE_ROOTS,' TREE_ROOTS |',NULL)
              || nvl2(WALL_OR_CEILING_LEAK,' WALL_OR_CEILING_LEAK |',NULL) || nvl2(WATER_HEATER_OR_HVAC,' WATER_HEATER_OR_HVAC |',NULL)
              || nvl2(WINDOW,' WINDOW |',NULL)
          as water_losstypes
         ,nvl(APPLIANCE,'N') as WCOL_APPLIANCE, nvl(BACKUP_OR_OVERFLOW,'N') as WCOL_BACKUP_OR_OVERFLOW
         ,nvl(BASEMENT_FLOODED,'N') as WCOL_BASEMENT_FLOODED, nvl(DRAIN_LINE_LEAK,'N') as WCOL_DRAIN_LINE_LEAK
         ,nvl(FAILED_MATERIAL,'N') as WCOL_FAILED_MATERIAL, nvl(FAUCET_LEFT_OPEN,'N') as WCOL_FAUCET_LEFT_OPEN
         ,nvl(FREEZE_FIRE_SPRINKLERS,'N') as WCOL_FREEZE_FIRE_SPRINKLERS, nvl(FREEZE_OT_FIRE_SPRINKLERS,'N') as WCOL_FREEZE_OT_FIRE_SPRINKLERS
         ,nvl(OCCUPANT_AWAY_FROM_PREMISES,'N') as WCOL_OCCUPANT_AWAY, nvl(PROPERTY_VACANT,'N') as WCOL_PROPERTY_VACANT
         ,nvl(RAIN_WATER_INTRUSION,'N') as WCOL_RAIN_WATER_INTRUSION, nvl(ROOF,'N') as WCOL_ROOF, nvl(SLAB_LEAK,'N') as WCOL_SLAB_LEAK
         ,nvl(SUPPLY_LINE,'N') as WCOL_SUPPLY_LINE, nvl(TOILET_LEAK,'N') as WCOL_TOILET_LEAK, nvl(TREE_ROOTS,'N') as WCOL_TREE_ROOTS
         ,nvl(WALL_OR_CEILING_LEAK,'N') as WCOL_WALL_OR_CEILING_LEAK, nvl(WATER_HEATER_OR_HVAC,'N') as WCOL_WATER_HEATER_OR_HVAC
         ,nvl(WINDOW,'N') as WCOL_WINDOW,CLAIM_SOURCE
   from (
      select * from (
      select wd.claimant_coverage, trunc(wd.last_modified) as last_modified, wd.load_date,WD.CLAIM_SOURCE
            ,case when replace(replace(replace(upper(wf.water_losstype),'/','_OR_'),' - ','_'),' ','_') = 'FREEZE_OTHER_THAN_FIRE_SPRINKLERS' then 'FREEZE_OT_FIRE_SPRINKLERS'
                  when replace(replace(replace(upper(wf.water_losstype),'/','_OR_'),' - ','_'),' ','_') = 'FAILED_MATERIAL_NOT_RETAINED_FOR_INSPECTION' then 'FAILED_MATERIAL'
                  else replace(replace(replace(upper(wf.water_losstype),'/','_OR_'),' - ','_'),' ','_')
             end water_col
            ,'Y' as water_rownum
      from wd inner join DATALAKE.DAILY_CMS_WATER_LOSS_FACTOR wf on wd.cms_water_loss_factor=wf.cms_water_loss_factor
       LEFT OUTER JOIN DLAKEDEV.DAILY_CCTL_WATERSOURCE TLWS ON TLWS.ID = wd.cms_water_loss_factor
      )
      pivot
         (max(water_rownum) for water_col
          in ( 'APPLIANCE' as APPLIANCE, 'BACKUP_OR_OVERFLOW' as BACKUP_OR_OVERFLOW, 'BASEMENT_FLOODED' as BASEMENT_FLOODED
              ,'DRAIN_LINE_LEAK' as DRAIN_LINE_LEAK, 'FAILED_MATERIAL' as FAILED_MATERIAL, 'FAUCET_LEFT_OPEN' as FAUCET_LEFT_OPEN
              ,'FREEZE_FIRE_SPRINKLERS' as FREEZE_FIRE_SPRINKLERS, 'FREEZE_OT_FIRE_SPRINKLERS' as FREEZE_OT_FIRE_SPRINKLERS
              ,'OCCUPANT_AWAY_FROM_PREMISES' as OCCUPANT_AWAY_FROM_PREMISES, 'PROPERTY_VACANT' as PROPERTY_VACANT
              ,'RAIN_WATER_INTRUSION' as RAIN_WATER_INTRUSION, 'ROOF' as ROOF, 'SLAB_LEAK' as SLAB_LEAK, 'SUPPLY_LINE' as SUPPLY_LINE
              ,'TOILET_LEAK' as TOILET_LEAK, 'TREE_ROOTS' as TREE_ROOTS, 'WALL_OR_CEILING_LEAK' as WALL_OR_CEILING_LEAK
              ,'WATER_HEATER_OR_HVAC' as WATER_HEATER_OR_HVAC, 'WINDOW' as WINDOW
              )
          )
      order by claimant_coverage, last_modified, load_date
   );
