alter table DAILY_CCX_MIRREPORTABLE_ACC
add (
            LOAD_DATE TIMESTAMP(6), 
            CLAIM_SOURCE VARCHAR2(20) default 'CC'
       ); 


          create table DLAKEDEV.D_CCX_MIRREPORTABLEHIST_ACCMIT  as (select * from   CCX_MIRREPORTABLEHIST_ACCMIT@CIGDW_TO_CC_QA_LINK);