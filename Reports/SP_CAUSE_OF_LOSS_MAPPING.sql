create or replace PROCEDURE SP_CAUSE_OF_LOSS_MAPPING(V_EXPOSUREID IN NUMBER , V_CAUSE_NAME OUT VARCHAR2 , V_CAUSE_GROUP_NAME OUT VARCHAR2) IS
BEGIN 
WITH CAUSE_OF_LOSS_MAP AS (
 SELECT 
      CASE 
        WHEN TLLC.TYPECODE IN('advertising_Ext','buildingGlass_Ext','environmentalPollution_Ext','professionalLiability_Ext','abandonment',
            'AccidentalDeath_Ext','animal','animal_bite','assault','breach','broken_glass','burglary','burn_scald','cancellation','caught_in','leftcollision',
            'animalcollision','bikecollision','fixedobjcoll','vehcollision','otherobjcoll','pedcollision','trainbuscoll','electrical_curr','air_crash',
            'rail_crash','water_veh_crash','cut','cyber_Ext','loadingdamage','death','delay','documents','earthquake','errors','excess','explosion','fall',
            'FallingObject','construction','fire','firedamage','freeze_Ext','glassbreakage','habitability_Ext','hail','hurricane','lightning_Ext','vandalism',
            'official_duty','med_error','miscellaneous','missed_departure','mold','motorvehicle','other_property_Ext','other_third_party_Ext','parking_lot_accident_Ext',
            'personal_injury_Ext','personal_misconduct','preex_med_condition','product','professional_sports','rearend','riotandcivil','roadsideassistance_Ext',
            'rollover','rubbed','snowice','storm_Ext','strain','striking','struck','structfailure','terrorism_hijack','theft_Ext','theftparts','theftentire',
            'vehicle_Ext','waterdamage','wind','livestock_Ext','mechanicalElectricalBreakdown_Ext','recall_Ext')
        AND  TLLPTY.TYPECODE IN('Insured') AND TLCG.TYPECODE IN('pathogenicOrganism_Ext') THEN
         '1st P Mold' 
        WHEN TLLC.TYPECODE IN('advertising_Ext') AND TLLPTY.TYPECODE IN('third_party') AND TLET.NAME IN('General') THEN
         'Advertising'
        WHEN TLLC.TYPECODE IN('burglary') AND TLINC.TYPECODE IN('PropertyIncident')
             AND (TLPTY.TYPECODE IN ('farmowners') OR TLPTY.TYPECODE IN('Commercial Manual'))  THEN
         'Animal Loss'
        WHEN TLINC.TYPECODE IN('InjuryIncident') AND TLET.TYPECODE IN('BodilyInjuryDamage') AND TLLPTY.TYPECODE IN('third_party') 
             AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto'))  THEN
         'BI(Auto)'  
        WHEN TLINC.TYPECODE IN('InjuryIncident') AND TLLPTY.TYPECODE IN('third_party') 
             AND (TLPTY.TYPECODE NOT LIKE '%Auto%')  THEN
         'Bodily Injury'   
        WHEN  TLLC.TYPECODE IN('burglary') AND TLINC.TYPECODE IN('FixedPropertyIncident', 'PropertyContentsIncident', 'LivingExpensesIncident')
              AND TLLPTY.TYPECODE IN('Insured') THEN
        'Burglary'
         WHEN TLLPTY.TYPECODE IN('Insured') AND TLCOVTY.TYPECODE IN('HO_CalAdd_Ext') THEN
         'Cal Add' 
        WHEN  TLLPTY.TYPECODE IN('Insured', 'third_party')  AND TLCG.TYPECODE IN('child_care_expenses_Ext')
             AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto')) 
             AND TLCOVSTY.TYPECODE IN('PAPIP_ORChildCare_Ext' , 'CMGarageKeepersPIPORChildCare_Ext') THEN
        'Child Care' 
        WHEN  TLLC.TYPECODE IN('animal', 'animalcollision', 'FallingObject' , 'riotandcivil','vandalism', 
                   'wind' ,'snowice','waterdamage','firedamage', 'loadingdamage') 
                   AND TLINC.TYPECODE IN('VehicleIncident') AND TLLPTY.TYPECODE IN('Insured') THEN
        'Comp'
        WHEN TLLC.TYPECODE NOT IN('animal', 'animalcollision', 'FallingObject' , 'riotandcivil','vandalism', 
                   'wind' ,'snowice','waterdamage','firedamage', 'loadingdamage') 
                   AND TLINC.TYPECODE IN('VehicleIncident') AND TLLPTY.TYPECODE IN('Insured') THEN
        'Coll'       
        WHEN  TLLC.TYPECODE IN ('glassbreakage')  AND TLINC.TYPECODE IN('VehicleIncident') AND TLLPTY.TYPECODE IN('Insured')
              AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto')) THEN
        'Comp(Glass)'
        WHEN  TLLC.TYPECODE IN ('theftentire' , 'theftparts')  AND TLINC.TYPECODE IN('VehicleIncident') AND TLLPTY.TYPECODE IN('Insured')
              AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto')) THEN
        'Comp(Theft)'
        WHEN  TLLC.TYPECODE IN ('other_property_Ext' , 'structfailure')  AND TLINC.TYPECODE IN('PropertyContentsIncident', 'MobilePropertyIncident')
              AND TLET.TYPECODE IN('Content' ,'PersonalPropertyDamage')
              AND TLLPTY.TYPECODE IN('Insured')
              AND (TLPTY.TYPECODE IN ('HOPHomeowners') OR TLPTY.TYPECODE IN('DwellingFire_Ext') OR TLPTY.TYPECODE IN ('BusinessOwners')) THEN
        'Contents'
        WHEN  TLLC.TYPECODE IN ('cyber_Ext') AND TLLPTY.TYPECODE IN('third_party') AND TLPTY.TYPECODE IN ('BusinessOwners') THEN
        'Cyber' 
        WHEN  TLLC.TYPECODE IN ('cyber_Ext') AND TLLPTY.TYPECODE IN('Insured','third_party') AND TLPTY.TYPECODE IN ('HOPHomeowners') THEN
        'Home Cyber' 
        WHEN TLLC.TYPECODE IN('earthquake') AND TLLPTY.TYPECODE IN('Insured') THEN
         'Earthquake'
        WHEN  TLLC.TYPECODE IN ('mechanicalElectricalBreakdown_Ext') AND TLLPTY.TYPECODE IN('Insured') AND TLINC.TYPECODE NOT IN('InjuryIncident')  THEN 
         'Mechanical Breakdown'
        WHEN TLLPTY.TYPECODE IN('third_party') AND (TLPTY.TYPECODE IN ('BusinessOwners') OR TLPTY.TYPECODE IN('Commercial Manual'))
             AND TLCOVTY.TYPECODE IN ('BOPEmpBenefits', 'BP7EmpBenefitsLiabCov', 'CA7EmplBenefitsLiab','CIG_ULEmployeeBenefitLiabilityCov',
                       'GLEmpBenefitsLiabilityCov') THEN 
        'Employee Benefits' 
        WHEN TLLPTY.TYPECODE IN('Insured') AND (TLPTY.TYPECODE IN ('BusinessOwners') OR TLPTY.TYPECODE IN('Commercial Manual'))
             AND TLCOVTY.TYPECODE IN ('BOPEmpDisCov', 'BP7EmployeeDishty', 'BP7LocationEmployeeDishty') THEN 
        'Employee Dishonesty' 
        WHEN TLLPTY.TYPECODE IN('third_party') AND (TLPTY.TYPECODE IN ('BusinessOwners') OR TLPTY.TYPECODE IN('Commercial Manual')
                                  OR  TLPTY.TYPECODE IN ('farmowners'))
             AND TLCOVTY.TYPECODE IN ('BP7EmploymentRelatedPracticesLiabilityCov', 'CMLiabilityEmploymentPractices_Ext', 
                                       'FMEmploymentPractices_Ext', 'FMEmploymentAPractices_Ext') THEN 
        'Employment Practices' 
         WHEN TLLC.TYPECODE IN('environmentalPollution_Ext') AND TLLPTY.TYPECODE IN('Insured') AND (TLPTY.TYPECODE NOT LIKE '%Auto%')  THEN
         'Environmental'  
         WHEN TLLC.TYPECODE IN('explosion')AND TLINC.TYPECODE NOT IN('InjuryIncident') AND TLLPTY.TYPECODE IN('Insured') THEN
         'Explosion' 
         WHEN TLLC.TYPECODE IN('fire') AND TLINC.TYPECODE NOT IN('InjuryIncident') AND TLLPTY.TYPECODE IN('Insured')  THEN
         'Fire' 
         WHEN TLLC.TYPECODE IN('glassbreakage') AND TLINC.TYPECODE NOT IN('InjuryIncident') AND
                TLLPTY.TYPECODE IN('Insured') AND (TLPTY.TYPECODE NOT LIKE '%Auto%')  THEN
         'Glass' 
         WHEN TLLPTY.TYPECODE IN('third_party') AND TLPTY.TYPECODE IN('Commercial Manual') AND TLCOVTY.TYPECODE IN('CMGolfBallDamage_Ext') THEN
         'Golf Ball Damage'  
         WHEN TLLC.TYPECODE IN('habitability_Ext') AND TLLPTY.TYPECODE IN('third_party') THEN
         'Habitability' 
         WHEN TLLPTY.TYPECODE IN('Insured') AND TLPTY.TYPECODE IN ('HOPHomeowners') AND TLCOVTY.TYPECODE IN('z2tgk324p0qk1fq75ei5be8g5gb') THEN
         'ID Theft' 
         WHEN TLLPTY.TYPECODE IN('third_party') AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto')) AND TLCG.TYPECODE IN('loss_of_use_Ext') THEN
         'LOU (Auto)' 
         WHEN TLLC.TYPECODE IN('professionalLiability_Ext') AND TLLPTY.TYPECODE IN('third_party')  THEN
         'Malpractice, Professional Liability'  
         WHEN TLINC.TYPECODE NOT IN('InjuryIncident') AND TLLPTY.TYPECODE IN('Insured','third_party') 
              AND TLCOVSTY.TYPECODE IN('CMGarageKeepersPIPOR_Ext' , 'PAPIP_ORMedical_Ext','CMGarageKeepersPIPOR_Ext', 'CMGarageKeepersPIPWA_Ext',
              'PAPIP_WAMedical_Ext','CMGarageKeepersPIPWA_Ext') THEN
         'Medical'  
         WHEN TLINC.TYPECODE IN('InjuryIncident') AND TLLPTY.TYPECODE IN('Insured','third_party')  AND TLPTY.TYPECODE NOT LIKE '%Auto%'
                  AND TLCOVSTY.TYPECODE IN('CMGarageKeepersPIPOR_Ext' , 'PAPIP_ORMedical_Ext','CMGarageKeepersPIPOR_Ext', 'CMGarageKeepersPIPWA_Ext',
              'PAPIP_WAMedical_Ext','CMGarageKeepersPIPWA_Ext') AND TLET.TYPECODE IN ('MedPay') THEN
         'Medical Payments'  
         WHEN TLINC.TYPECODE IN('InjuryIncident') AND TLET.TYPECODE IN ('MedPay') AND TLLPTY.TYPECODE IN('third_party')
              AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto')) THEN
         'MP (Auto)' 
         WHEN TLINC.TYPECODE IN('VehicleIncident') AND TLLPTY.TYPECODE IN('third_party') THEN
         'PD (Auto)'          
         WHEN TLLPTY.TYPECODE IN('Insured') AND TLPTY.TYPECODE IN ('BusinessOwners') AND TLCOVTY.TYPECODE IN('BOPPersonalEffects') THEN
         'Personal Effects' 
         WHEN TLLPTY.TYPECODE IN('third_party')  AND (TLPTY.TYPECODE NOT LIKE '%Auto%')
         AND TLCOVSTY.TYPECODE IN('HOCovEPI_Ext','CA7NamedIndividualsBroadenedPersonalInjuryProtecti','DFPersonalInjuryProtection_Ext',
                        'CA7VehiclePIP','CMLiabilityCovBPI_Ext','HOMiscCovEndorsePersonalInjury_Ext','HOOtherLiabPersonalInjury_Ext',
                        'HOOtherStructEndorsePI_Ext','DFPersonalInjuryClaimExpenses_Ext','HOAddInsuredManagersLessorsPersonalInjury_Ext',
                        'HOAddInsuredVendorsPersonalInjury_Ext','HOAddResidenceLiabPersonalInjury_Ext','HOCalPakPersonalInjury_Ext','HOCalPakNevPakPersonalInjury_Ext',
                        'HOHomeBusinessPI_Ext','HOCalPak2PersonalInjury_Ext','FULiabilityPI_Ext','FUOtherLiabilityPI_Ext','DFComprehensivePersonalLiabilityPIPPI_Ext',
                        'CMGarageKeepersPersInj_Ext','PULiabilityPI_Ext','PUOtherLiabilityPI_Ext','BP7BusinessLiabilityPI_Ext','DFOwnerLandlordTenantPIPPI_Ext',
                        'DFLiabilityPremisesLiabilityPIPPI_Ext','FMPersonalAndAdvertisingPI_Ext') THEN
         'Personal Injury'   
         WHEN TLLC.TYPECODE IN('environmentalPollution_Ext') AND TLLPTY.TYPECODE IN('third_party') THEN
         'Pollution'   
         WHEN TLLPTY.TYPECODE IN('third_party') AND TLPTY.TYPECODE IN('Commercial Manual') AND TLCOVTY.TYPECODE IN('CMProductRecall_Ext') THEN
         'Product Recall'    
         WHEN TLET.TYPECODE IN ('PropertyDamage', 'VehicleDamage') AND TLLPTY.TYPECODE IN('third_party')  AND (TLPTY.TYPECODE NOT LIKE '%Auto%') THEN
         'Property Damage'  
        WHEN TLLC.TYPECODE IN('riotandcivil') AND  TLLPTY.TYPECODE IN('Insured')THEN
        'Riot, Civil Commotion'
        WHEN TLINC.TYPECODE IN('VehicleIncident') AND  TLET.TYPECODE IN ('VehicleDamage' , 'LossOfUseDamage') AND  TLLPTY.TYPECODE IN('Insured')
        AND TLPTY.TYPECODE IN ('PersonalAuto', 'CA7CommAuto') AND TLCOVTY.TYPECODE IN('CA7HiredAutoRentalReimbursement','BARentalCov','CA7PolicyRentalReimbursement',
                           'PARentalCov','CA7RentalReimbursementPBT','CA7RentalReimbursementPPT','CA7RentalReimbursementSPV','CA7RentalReimbursementTTT',
                           'CIG_CA7RentalReimbursementOTCPBT','CIG_CA7RentalReimbursementOTCPPT','CIG_CA7RentalReimbursementOTCSPV','CIG_CA7RentalReimbursementOTCTTT') THEN
        'RR (Rental Reimbursement)'  
        WHEN  TLLPTY.TYPECODE IN('Insured') AND TLCOVTY.TYPECODE IN('HOServiceLine_Ext') THEN
        'Service Line'
        WHEN  TLLPTY.TYPECODE IN('third_party')  
              AND TLCOVSTY.TYPECODE IN('CMGarageKeepersPIPOR_Ext' , 'PAPIP_ORMedical_Ext','CMGarageKeepersPIPOR_Ext', 'CMGarageKeepersPIPWA_Ext',
              'PAPIP_WAMedical_Ext','CMGarageKeepersPIPWA_Ext') THEN
        'Services'
        WHEN  TLLPTY.TYPECODE IN('Insured','third_party') AND TLCOVTY.TYPECODE IN('FMFarmEmployersLiabilityStopGapWA_Ext') THEN
        'Stop Gap - Employers Liability'
        WHEN  TLLC.TYPECODE IN('storm_Ext','hail','lightning_Ext','snowice') AND TLLPTY.TYPECODE IN('Insured') AND TLINC.TYPECODE NOT IN('FixedPropertyIncident') THEN
        'Storm'  
        WHEN  TLLC.TYPECODE IN('other_property_Ext','structfailure') AND TLLPTY.TYPECODE IN('Insured') AND TLINC.TYPECODE NOT IN('FixedPropertyIncident') THEN
        'Structure'      
        WHEN  TLLC.TYPECODE IN('theft_Ext') AND TLLPTY.TYPECODE IN('Insured') AND TLINC.TYPECODE NOT IN('FixedPropertyIncident','PropertyContentsIncident','LivingExpensesIncident') THEN
        'Theft'   
        WHEN TLLPTY.TYPECODE IN('Insured') AND TLINC.TYPECODE NOT IN('VehicleIncident') AND TLET.TYPECODE IN('TowOnly') THEN
        'TL (Towing and Labor)' 
        WHEN TLLPTY.TYPECODE IN('Insured') AND TLINC.TYPECODE NOT IN('InjuryIncident') AND TLET.TYPECODE IN('BodilyInjuryDamage') 
             AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto')) 
             AND TLCOVTY.TYPECODE IN('CA7VehicleUnderinsuredMotoristPolicy','BAOwnedUIMBICov','PAUIMBICov','PACSLUIMBICov_Ext',
                           'BADOCUnderinsCov','BAOwnedUIMPDCov','CIG_CA7UnderinsuredMotoristCovDOC','CIG_CA7UnderinsuredMotoristBIAndPD',
                           'CIG_CA7UnderinsuredMotoristBIPDDOC','CA7DriveOtherCarCovBroadCovForNamedIndividualsUnde','PAUIMPDCov')
             THEN
        'UIM'    
        WHEN TLLPTY.TYPECODE IN('Insured') AND TLINC.TYPECODE NOT IN('Incident') AND TLET.TYPECODE IN('GeneralDamage') 
             AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto'))
             AND TLCOVTY.TYPECODE IN('PAUMCollisionCov_Ext', 'CIG_CA7VehicleCollisionDedWaiverPBT','CIG_CA7VehicleCollisionDedWaiverPPT',
                                     'CIG_CA7VehicleCollisionDedWaiverSPV' ,'CIG_CA7VehicleCollisionDedWaiverTTT') THEN 
        'UM COLL'  
        WHEN TLINC.TYPECODE IN('VehicleIncident') AND TLET.TYPECODE IN('VehicleDamage') AND TLLPTY.TYPECODE IN('Insured') 
             AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto'))
             AND TLCOVTY.TYPECODE IN('CA7VehicleUninsuredMotoristPolicy','BAOwnedUMBICov','PAUMBICov','PAUMCollisionCov_Ext','PACSLUMBICov_Ext',
                        'BADOCUninsuredCov','BAOwnedUMPDCov','PAUMPDCov','BAOwnedUMBISuppCov','CIG_CA7UninsuredMotoristPropertyDamageCovDOC',
                        'CIG_CA7UninsuredMotoristPropertyDamage','CA7DriveOtherCarCovBroadCovForNamedIndividualsUnin','CIG_CA7UninsuredMotoristCovDOC') THEN 
        'UMBI'  
        WHEN TLINC.TYPECODE IN('VehicleIncident') AND TLET.TYPECODE IN('VehicleDamage') AND TLLPTY.TYPECODE IN('Insured') 
             AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto'))
             AND TLCOVTY.TYPECODE IN('BAOwnedUIMPDCov','PAUIMPDCov','CIG_CA7UninsuredMotoristPropertyDamageCovDOC',
                                 'CIG_CA7UninsuredMotoristPropertyDamage','CIG_CA7UnderinsuredMotoristBIPDDOC','CIG_CA7UnderinsuredMotoristBIAndPD') THEN 
        'UMPD'   
        WHEN TLLC.TYPECODE IN('vandalism') AND TLLPTY.TYPECODE IN('Insured') THEN
        'Vandalism, Malicious Mischief'    
        WHEN TLLPTY.TYPECODE IN('third_party') AND TLCG.TYPECODE IN('lostwages') AND TLCOVTY.TYPECODE IN('APIP_WA', 'CAPIP_OR','PAPIP_OR')
             AND TLCOVSTY.TYPECODE IN('PAPIP_ORIncome_Ext' , 'PAPIP_WAIncome_Ext')
             AND (TLPTY.TYPECODE IN ('PersonalAuto') OR TLPTY.TYPECODE IN('CA7CommAuto')) THEN
        'Wages'   
        WHEN  TLLPTY.TYPECODE IN('Insured') AND TLLC.TYPECODE IN('waterdamage') THEN
        'Water' 
        WHEN  TLLPTY.TYPECODE IN('third_party') AND TLCOVSTY.TYPECODE IN('HOWorkCompIndemnity_Ext') THEN
        'WC -Indemnity' 
        WHEN  TLLPTY.TYPECODE IN('third_party') AND TLCOVSTY.TYPECODE IN('HOWorkCompLiability_Ext') THEN
        'WC -Liability' 
        WHEN  TLLPTY.TYPECODE IN('third_party') AND TLCOVSTY.TYPECODE IN('HOWorkCompMedical_Ext') THEN
        'WC-Med' 
        WHEN TLINC.TYPECODE NOT IN('InjuryIncident') AND TLLPTY.TYPECODE IN('Insured') AND (TLPTY.TYPECODE NOT LIKE '%Auto%') THEN 
        'Other Default'
        ELSE 
        'Other None'  
        END as CAUSE_NAME
     FROM CC_CLAIM@ECIG_TO_CC_LINK C
     INNER JOIN CC_EXPOSURE@ECIG_TO_CC_LINK EX ON EX.CLAIMID=C.ID AND EX.RETIRED=0
     -- PENDING : ADD TRANSTYPE AS PAYMENT INSTEAD OF CHECKING CHECKID IS NOT NULL
     INNER JOIN CC_TRANSACTION@ECIG_TO_CC_LINK  TR ON TR.CLAIMID = C.ID AND EX.ID = TR.EXPOSUREID AND TR.CHECKID IS NOT NULL AND TR.RETIRED = 0
     LEFT OUTER JOIN CCTL_LOSSCAUSE@ECIG_TO_CC_LINK TLLC ON TLLC.ID = C.LOSSCAUSE AND TLLC.RETIRED = 0
     LEFT OUTER JOIN CC_INCIDENT@ECIG_TO_CC_LINK INC ON INC.ID=EX.INCIDENTID AND INC.RETIRED=0
     LEFT OUTER JOIN CCTL_INCIDENT@ECIG_TO_CC_LINK TLINC ON TLINC.ID=INC.SUBTYPE AND TLINC.RETIRED=0
     LEFT OUTER JOIN CCTL_LOSSPARTYTYPE@ECIG_TO_CC_LINK TLLPTY ON TLLPTY.ID=EX.LOSSPARTY AND TLLPTY.RETIRED=0
     LEFT OUTER JOIN CCTL_COSTCATEGORY@ECIG_TO_CC_LINK  TLCG ON TLCG.ID = TR.COSTCATEGORY AND TLCG.RETIRED =0
     LEFT OUTER JOIN CCTL_EXPOSURETYPE@ECIG_TO_CC_LINK TLET ON TLET.ID = EX.EXPOSURETYPE AND TLET.RETIRED =0
     INNER JOIN CC_POLICY@ECIG_TO_CC_LINK P ON P.ID=C.POLICYID AND P.RETIRED=0
     INNER JOIN CCTL_POLICYTYPE@ECIG_TO_CC_LINK TLPTY ON TLPTY.ID=P.POLICYTYPE AND TLPTY.RETIRED=0
     LEFT OUTER JOIN CCTL_COVERAGESUBTYPE@ECIG_TO_CC_LINK TLCOVSTY ON TLCOVSTY.ID=EX.COVERAGESUBTYPE
     LEFT OUTER JOIN CC_COVERAGE@ECIG_TO_CC_LINK COV ON COV.ID=EX.COVERAGEID AND COV.RETIRED=0
     LEFT OUTER JOIN CCTL_COVERAGE@ECIG_TO_CC_LINK TLCOV ON TLCOV.ID=COV.SUBTYPE AND TLCOV.RETIRED=0
     LEFT OUTER JOIN CCTL_COVERAGETYPE@ECIG_TO_CC_LINK TLCOVTY ON TLCOVTY.ID=COV.TYPE AND TLCOVTY.RETIRED=0
     WHERE EX.ID = V_EXPOSUREID
),
CAUSE_GROUP_NAME_MAP AS (
 SELECT 
    COLM.CAUSE_NAME AS CAUSE_NAME,
    CASE WHEN COLM.CAUSE_NAME IN('1st P Mold','Animal Loss','Burglary','Cal Add','Coll','Comp','Comp (Theft)',
                        'Contents','Contents','Contents','Earthquake','Electrical Breakdown',
                        'Employee Dishonesty','Explosion','Fire','Glass','Home Cyber','Home Cyber',
                        'ID Theft','Mechanical Breakdown','Other','Personal Effects','Riot,Civil Commotion','RR (Rental Reimbursement)','RR (Rental Reimbursement)',
                        'Service Line','Storm','Structure','Theft','TL (Towing and Labor)',
                        'UM COLL','UM COLL','UMPD','Vandalism, Malicious Mischief','Water') THEN 
    '1st Party Property' 
    ELSE
     '3rd Party Casualty'
    END AS CAUSE_GROUP_NAME
 FROM CAUSE_OF_LOSS_MAP COLM
)
SELECT CAUSE_NAME,CAUSE_GROUP_NAME
INTO V_CAUSE_NAME , V_CAUSE_GROUP_NAME
FROM CAUSE_GROUP_NAME_MAP;

EXCEPTION
   WHEN OTHERS
   THEN
   RAISE_APPLICATION_ERROR (-20201, 'DATA SELECTION NOT SUCCESSFUL IN SP_CAUSE_OF_LOSS_MAPPING..'||SQLERRM);
  --   DBMS_OUTPUT.put_line (' Exception' || SQLCODE || 'Encountered');

END SP_CAUSE_OF_LOSS_MAPPING;