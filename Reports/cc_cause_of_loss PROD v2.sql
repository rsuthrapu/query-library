-- BEGIN
  -- EXECUTE IMMEDIATE 'DROP TABLE WHOUSE.CC_CAUSE_OF_LOSS'; 
  -- WHEN OTHERS THEN NULL;
-- END;

CREATE TABLE whouse.cc_cause_of_loss AS 

SELECT
      exp.id AS exposure_id,
      
      CASE 
        WHEN tllpty.typecode IN('insured') 
         AND tlcovsty.typecode IN('HO_CalAdd_Ext') 
           THEN
           'Cal Add'       

        WHEN tlcovsty.typecode IN('PAPIP_ORChildCare_Ext' , 'CMGarageKeepersPIPORChildCare_Ext') 
           THEN
           'Child Care'         

        WHEN  tlcovsty.typecode IN('PAPIP_ORIncome_Ext' , 'PAPIP_WAIncome_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
           THEN
           'Wages'           

        WHEN tllpty.typecode IN('third_party') 
         AND tlcovsty.typecode IN('HOWorkCompIndemnity_Ext', 'FMWorkCompIndemnity_Ext') 
           THEN
           'WC -Indemnity' 

        WHEN tllpty.typecode IN('third_party') 
         AND tlcovsty.typecode IN('HOWorkCompLiability_Ext', 'WCEmpLiabCov', 'FMWorkCompLiability_Ext')
           THEN
           'WC -Liability' 

        WHEN tllpty.typecode IN('third_party') 
         AND tlcovsty.typecode IN('WCWorkersCompMED', 'HOWorkCompMedical_Ext', 'FMWorkCompMedical_Ext')
           THEN
           'WC-Med'

        WHEN tllpty.typecode IN('insured') 
         AND tlcovsty.typecode IN('HOServiceLine_Ext') 
           THEN
           'Service Line'

        WHEN tlinc.typecode NOT IN('InjuryIncident')  
         AND tlcovsty.typecode IN('HOBreakdownElec_Ext', 'CMEquipmentBreakdownElec_Ext', 'CMEquipmentBreakdownMech_Ext', 
                                  'CMEquipmentBreakdownOther_Ext', 'CMEquipmentBreakdownWAElec_Ext', 'CMEquipmentBreakdownWAMech_Ext', 
                                  'CMEquipmentBreakdownWAOther_Ext', 'BP7EquipmentBreakdownProtection', 'BOPMechBreakdownCov', 
                                  'HOBreakdownMech_Ext', 'CMEquipmentBreakdownFarmElec_Ext', 'CMEquipmentBreakdownFarmMech_Ext', 
                                  'CMEquipmentBreakdownFarmOther_Ext', 'FMApplianceBreakdownPolicy_Ext', 'FMApplianceBreakdownRisk_Ext', 
                                  'FMBoilerAndMachinery_Ext', 'FMEquipmentBreakdown_Ext')
           THEN 
           'Mechanical Breakdown'                  

        WHEN  tllpty.typecode IN('third_party') 
         AND  tlcovsty.typecode IN ('BOPEmpBenExtRpting', 'BOPEmpBenefits', 'BP7EmpBenefitsLiabCov', 'CA7EmplBenefitsLiab', 
                                    'CIG_ULEmployeeBenefitLiabilityCov', 'CMLiabilityEmployeeBenefits_Ext', 
                                    'GLEmpBenefitsLiabilityCov')
           THEN 
           'Employee Benefits' 

        WHEN  tlcovsty.typecode IN('BOPEmpDisCov', 'BP7EmployeeDishty', 'BP7LocationEmployeeDishty', 
                                   'CMPropCommercialCrimeEmployeeDishonesty_Ext') 
         AND (tlpty.NAME IN ('Businessowners') 
          OR  tlpty.NAME IN('Commercial Manual'))
           THEN 
           'Employee Dishonesty' 

        WHEN  tlcovsty.typecode IN('BP7EmploymentRelatedPracticesLiabilityCov', 'CMLiabilityEmploymentPractices_Ext', 
                                  'CMLiabilityEmploymentPracticesBI_Ext', 'FMEmploymentPracticesBI_Ext', 
                                  'FMEmploymentPractices_Ext')
         AND (tlpty.NAME IN ('Businessowners') 
          OR  tlpty.NAME IN('Commercial Manual')
          OR  tlpty.typecode IN ('farmowners'))
           THEN 
           'Employment Practices' 

        WHEN tlcovsty.typecode IN('CIG_BP7BarberandBeautyProfessionalLiability', 'BP7BarbersBeauticiansProflLiab', 
                                  'BP7BeautySalonsProflLiab', 'BP7FuneralDirectorsProflLiab', 'CIG_BP7VeterinarianProfessionalLiability', 
                                  'BP7VeterinariansProflLiab', 'CIG_BP7BarberandBeautyProfessionalLiabilityBI', 
                                  'CIG_BP7BarberandBeautyProfessionalLiabilityMP', 'CIG_BP7BarberandBeautyProfessionalLiabilityPD', 
                                  'CIG_BP7VeterinarianProfessionalLiabilityBI', 'CIG_BP7VeterinarianProfessionalLiabilityMP', 
                                  'CIG_BP7VeterinarianProfessionalLiabilityPD')  
           THEN
           'Malpractice, Professional Liability'  

        WHEN tlinc.typecode IN('InjuryIncident') 
         AND tlpty.typecode NOT LIKE '%Auto%'
         AND tlcovsty.typecode IN('DFComprehensivePersonalLiabilityMP_Ext', 'z8tjsluucfmoh3nho364cli3uv8', 'BAOwnedMedPayCov', 
                                  'CA7VehicleMedPay', 'DFMedPay_Ext', 'PAMedPayCov', 'BADOCMedPayCov', 
                                  'CA7DriveOtherCarCovBroadCovForNamedIndividualsMedP', 'CIG_CA7MedicalPaymentsDOC', 
                                  'CA7VehicleMedPayAuto', 'CA7VehicleMedPayLocationsAndOps', 'CMLiabilityCovCMedPay_Ext', 
                                  'DFMedPayAddResidence_Ext', 'HOMiscCovEndorseMP_Ext', 'HOOtherLiabMP_Ext', 'HOOtherStructEndorseMP_Ext', 
                                  'HOSpoilStockMP_Ext', 'CMLiabilityCovBMedPay_Ext', 'CMGarageKeepersMedPay_Ext', 
                                  'CMGarageKeepersMedPayAuto_Ext', 'HOAddInsuredManagersLessorsMP_Ext', 'HOAddInsuredVendorsMP_Ext', 
                                  'HOAddResidenceLiabMP_Ext', 'HOHomeBusinessMP_Ext', 'HOHomeFarmCovMP_Ext', 'FMEmployeeMedicalPayments_Ext', 
                                  'BP7BusinessLiabilityMP_Ext', 'CIG_BP7DirectorsAndOfficersLiabilityCoverageMP', 'FMLiabilityMedPay_Ext', 
                                  'FMMedPay_Ext', 'FMCustomFarmingMedPay_Ext')
           THEN
           'Medical Payments'  

        WHEN  tlinc.typecode IN('InjuryIncident') 
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
         AND  tlcovsty.typecode IN('DFComprehensivePersonalLiabilityMP_Ext', 'z8tjsluucfmoh3nho364cli3uv8', 'BAOwnedMedPayCov', 
                                 'CA7VehicleMedPay', 'DFMedPay_Ext', 'PAMedPayCov', 'BADOCMedPayCov', 
                                 'CA7DriveOtherCarCovBroadCovForNamedIndividualsMedP', 'CIG_CA7MedicalPaymentsDOC', 
                                 'CA7VehicleMedPayAuto', 'CA7VehicleMedPayLocationsAndOps', 'CMLiabilityCovCMedPay_Ext', 
                                 'DFMedPayAddResidence_Ext', 'HOMiscCovEndorseMP_Ext', 'HOOtherLiabMP_Ext', 'HOOtherStructEndorseMP_Ext', 
                                 'HOSpoilStockMP_Ext', 'CMLiabilityCovBMedPay_Ext', 'CMGarageKeepersMedPay_Ext', 
                                 'CMGarageKeepersMedPayAuto_Ext', 'HOAddInsuredManagersLessorsMP_Ext', 'HOAddInsuredVendorsMP_Ext', 
                                 'HOAddResidenceLiabMP_Ext', 'HOHomeBusinessMP_Ext', 'HOHomeFarmCovMP_Ext', 'FMEmployeeMedicalPayments_Ext', 
                                 'BP7BusinessLiabilityMP_Ext', 'CIG_BP7DirectorsAndOfficersLiabilityCoverageMP', 'FMLiabilityMedPay_Ext', 
                                 'FMMedPay_Ext', 'FMCustomFarmingMedPay_Ext')
           THEN
           'MP (Auto)' 

        WHEN tllpty.typecode IN('third_party') 
         AND tlpty.typecode IN('Commercial Manual') 
         AND tlcovsty.typecode IN('CMGolfBallDamage_Ext') 
           THEN
           'Golf Ball Damage'  

        WHEN tllpty.typecode IN('insured') 
         AND tlpty.typecode IN ('HOPHomeowners') 
         AND tlcovsty.typecode IN('z2tgk324p0qk1fq75ei5be8g5gb', 'BP7IDFraudExpenseCov', 'HOCyberIdentityRecovery_Ext')
           THEN
           'ID Theft' 

        WHEN tllpty.typecode IN('insured') 
         AND tlpty.typecode NOT LIKE '%Auto%' 
         AND tlcovsty.typecode IN('CMPropGlass_Ext')
           THEN
           'Glass' 

         WHEN tlcovsty.typecode IN('CMGarageKeepersPIPOR_Ext','PAPIP_ORMedical_Ext','CMGarageKeepersPIPWA_Ext',
                                   'PAPIP_WAMedical_Ext','CA7VehiclePIP') 
            THEN
            'Medical'  

         WHEN tllpty.typecode IN('insured') 
          AND tlpty.typecode IN ('BusinessOwners') 
          AND tlcovsty.typecode IN('BOPPersonalEffects') 
            THEN
            'Personal Effects' 

         WHEN tllpty.typecode IN('third_party') 
          AND tlcovsty.typecode IN('CMProductRecall_Ext','CA7LmtdProductWithdrawalExpenseEndorsement','ProductWithdrawalLtd') 
            THEN
            'Product Recall'    

        WHEN tlet.typecode IN ('VehicleDamage' , 'LossOfUseDamage') 
         AND tlpty.typecode IN ('PersonalAuto', 'CA7CommAuto') 
         AND tlcovsty.typecode IN('BARentalCov', 'CA7PolicyRentalReimbursement', 'PARentalCov', 'CA7RentalReimbursementPBT',
                                  'CA7RentalReimbursementPPT', 'CA7RentalReimbursementSPV', 'CA7RentalReimbursementTTT', 
                                  'CIG_CA7RentalReimbursementOTCPBT', 'CIG_CA7RentalReimbursementOTCPPT', 
                                  'CIG_CA7RentalReimbursementOTCSPV', 'CIG_CA7RentalReimbursementOTCTTT', 
                                  'CA7HiredAutoRentalReimbursement', 'ContractorsEquipRentalReibursement')
           THEN
           'RR'  

        WHEN tlcovsty.typecode IN('PAPIP_ORFuneral_Ext', 'PAPIP_ORServices_Ext', 'PAPIP_WAFuneral_Ext', 'PAPIP_WAServices_Ext', 
                                  'CMGarageKeepersPIPORFuneral_Ext', 'CMGarageKeepersPIPORServices_Ext', 
                                  'CMGarageKeepersPIPWAFuneral_Ext', 'CMGarageKeepersPIPWAServices_Ext') 
           THEN
           'Services'

        WHEN tlcovsty.typecode IN('BP7ExtddReportingPeriodEmpBenefitsLiabCov', 'BP7ExtddReportingPeriodEmpBenefitsLiabCovBI_Ext',
                                  'FMFarmEmployersLiabilityStopGapWA_Ext') 
           THEN
           'Stop Gap - Employers Liability'

        WHEN  tllpty.typecode IN('insured') 
         AND  tlet.typecode IN('BodilyInjuryDamage') 
         AND  tlcovsty.typecode IN('CA7VehicleUnderinsuredMotoristPolicy', 'BAOwnedUIMBICov', 'PAUIMBICov', 'PAUIMBICSLCov_Ext', 
                                   'CMGarageKeepersUIM_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
           THEN
           'UIM'    

        WHEN  tlinc.typecode IN('VehicleIncident')       
         AND  tlcovsty.typecode IN('BADOCUninsuredVEH', 'BADOCUninsuredBI', 'BADOCUninsuredPD', 'BADOCUnderinsCov',
                                  'BAOwnedUIMPDCov', 'CIG_CA7UnderinsuredMotoristCovDOC', 'CIG_CA7UnderinsuredMotoristBIAndPD',
                                  'CIG_CA7UnderinsuredMotoristBIPDDOC', 'CA7DriveOtherCarCovBroadCovForNamedIndividualsUnde', 
                                  'PAUMPDCov', 'CIG_CA7UninsuredMotoristPropertyDamageCovDOC', 'CIG_CA7UninsuredMotoristPropertyDamage', 
                                  'CA7DriveOtherCarCovBroadCovForNamedIndividualsUnin', 'CIG_CA7UninsuredMotoristCovDOC', 
                                  'CIG_CA7UnderinsuredMotorBIPDDOC', 'PAUIMPDCov', 'CIG_CA7UnderinsuredMotoristBIAndPDCov_bi_Ext', 
                                  'CIG_CA7UnderinsuredMotoristBIAndPDCov_vd_Ext', 'CIG_CA7UnderinsuredMotoristBIPDDOCCov_bi_Ext', 
                                  'CIG_CA7UnderinsuredMotoristBIPDDOCCov_vd_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))   
           THEN 
           'UMPD'

        WHEN  tlet.typecode IN('GeneralDamage') 
         AND  tlcovsty.typecode IN('CIG_CA7VehicleCollisionDedWaiverPBT', 'CIG_CA7VehicleCollisionDedWaiverPPT',
                                   'CIG_CA7VehicleCollisionDedWaiverSPV', 'CIG_CA7VehicleCollisionDedWaiverTTT', 
                                   'PAUMCollisionCov_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))
           THEN 
           'UM COLL'

        WHEN  tlcovsty.typecode IN('BAOwnedUMBICov', 'PAUMBICov', 'PAUMBICSLCov_Ext', 'CMGarageKeepersUMBI_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))
           THEN 
           'UMBI'

        WHEN tllpty.typecode IN('insured') 
         AND tlcovsty.typecode IN('BATowingLaborCov', 'CA7VehicleTowingLaborPPT', 'CIG_CA7VehicleTowingLaborPBT', 
                                  'CIG_CA7VehicleTowingLaborSPV', 'CIG_CA7VehicleTowingLaborTTT', 'PATowingLaborCov', 
                                  'CIG_CA7TowingLabor', 'CIG_CA7TowingLaborPBT')
           THEN
           'TL (Towing and Labor)' 

        WHEN  tlcovsty.typecode IN('CMLiabilityCovBAdvertising_Ext', 'FMPersonalAndAdvertisingAI_Ext')
          OR (tlet.typecode NOT IN('PersonalInjury_Ext')
         AND  tlcovsty.typecode IN('BP7AmendmentOfPersonalAndAdvertisingInjuryDefntn', 
                                   'CA7LmtdContractualLiabCovForPersonalAndAdvertising', 'BOPPersAdvertInj', 
                                   'GLLimitedPAandInjuryCov', 'GLCGLCov_adv_gd'))
           THEN 
           'Advertising'

        WHEN  tlinc.typecode IN('InjuryIncident') 
         AND  tlet.typecode IN('BodilyInjuryDamage') 
         AND  tlcovsty.typecode IN('CMLiabilityNonOwnedAutoBI_Ext', 'BP7HiredNonOwnedAutoBI', 'CA7NonOwnedAutoLiabCov_bi_Ext', 
                                   'CIG_CA7NonOwnedAutoLiabCov_bi_Ext', 'BP7NonOwnedAutoBI_Ext','CA7FarmLaborContractorsPBT',
                                   'CA7FarmLaborContractorsTTT')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))  
           THEN
           'BI (Auto)'  

        WHEN tlinc.typecode IN('InjuryIncident') 
         AND tlpty.typecode NOT LIKE '%Auto%'
         AND  tlcovsty.typecode IN('CMLiabilityNonOwnedAutoBI_Ext', 'BP7HiredNonOwnedAutoBI', 'CA7NonOwnedAutoLiabCov_bi_Ext', 
                                   'CIG_CA7NonOwnedAutoLiabCov_bi_Ext', 'BP7NonOwnedAutoBI_Ext','CA7FarmLaborContractorsPBT',
                                   'CA7FarmLaborContractorsTTT')
           THEN
           'Bodily Injury' 

        WHEN  tlcovsty.typecode IN('CA7AutosLeasedHiredRentedWithDriversPhysDamageCov1', 'BAComprehensiveCov', 'PAComprehensiveCov', 
                                   'BADOCCompCov', 'DFComprehensivePersonalLiabilityPD_Ext', 'DFComprehensivePersonalLiabilityPDVeh_Ext', 
                                   'BAHiredCompCov', 'HOFarmEquipComp_Ext', 'HOFarmEquipCompTheft_Ext', 
                                   'DFComprehensivePersonalLiabilityPIPPI_Ext', 'DFComprehensivePersonalLiabilityPDPI_Ext', 
                                   'DFComprehensivePersonalLiabilityPDVehPI_Ext')
           THEN
           'Comp'           

        WHEN tllc.typecode IN('habitability_Ext') 
         AND tllpty.typecode IN('third_party') 
           THEN
           'Habitability' 

         WHEN tllpty.typecode IN('third_party')  
          AND tlpty.typecode NOT LIKE '%Auto%'
          AND tlinc.typecode IN('Incident') 
          AND tlcovsty.typecode IN('HOCovEPI_Ext', 'CMLiabilityCovBPI_Ext', 'HOMiscCovEndorsePersonalInjury_Ext',
                                   'HOOtherLiabPersonalInjury_Ext', 'HOOtherStructEndorsePI_Ext', 'DFPersonalInjuryClaimExpenses_Ext', 
                                   'HOAddInsuredManagersLessorsPersonalInjury_Ext', 'HOAddInsuredVendorsPersonalInjury_Ext', 
                                   'HOAddResidenceLiabPersonalInjury_Ext', 'HOCalPakPersonalInjury_Ext', 'HOCalPakNevPakPersonalInjury_Ext', 
                                   'HOHomeBusinessPI_Ext', 'HOCalPak2PersonalInjury_Ext', 'FULiabilityPI_Ext', 'FUOtherLiabilityPI_Ext', 
                                   'CMGarageKeepersPersInj_Ext', 'PULiabilityPI_Ext', 'PUOtherLiabilityPI_Ext', 'BP7BusinessLiabilityPI_Ext', 
                                   'FMPersonalAndAdvertisingPI_Ext')
            THEN
            'Personal Injury'   

         WHEN tllc.typecode IN('environmentalPollution_Ext') 
          AND tllpty.typecode IN('insured') 
          AND tlpty.typecode NOT LIKE '%Auto%'  
            THEN
            'Environmental'  

         WHEN tllc.typecode IN('environmentalPollution_Ext') 
          AND tllpty.typecode IN('third_party') 
            THEN
            'Pollution'   

         WHEN tlcovsty.typecode IN('BADealerLimitLiabCov_pd', 'BABobtailLiabCov_pd', 'zd7gujr17mccs3puv5jreeu1e59PD', 
                                   'HOCovEPDVehicles_Ext', 'BADOCLiabilityCovPD', 'farm_pd', 'CMLiabilityHiredAutoPD_Ext', 
                                   'CMLiabilityHiredAutoPDVeh_Ext', 'CMLiabilityLiquorLiabilityPD_Ext', 'CMLiabilityLiquorLiabilityPDVeh_Ext', 
                                   'CMLiabilityNonOwnedAutoPD_Ext', 'CMLiabilityNonOwnedAutoPDVeh_Ext', 'liab_trav_pr', 'PALiabilityCov_pd_Ext', 
                                   'BALimitedPropDamCov', 'BANonownedLiabCov_pd', 'DFOwnerLandlordTenantPD_Ext', 'DFOwnerLandlordTenantPDVeh_Ext', 
                                   'DFLiabilityPremisesLiabilityPD_Ext', 'DFLiabilityPremisesLiabilityPDVehicles_Ext', 'BASeasonTrailerLiabCov_pd',
                                   'CMLiabilityCovAPD_Ext', 'CMLiabilityCovAPDVeh_Ext', 'PALiabilityCSLCov_pd_Ext', 'HOCalPak2PD_Ext', 
                                   'HOCalPak2PDVehicles_Ext', 'HOAddCovCasHO3PD_Ext', 'HOAddCovCasHO4PD_Ext', 'HOAddCovCasHO5PD_Ext', 
                                   'HOAddCovCasHO6PD_Ext', 'HOLimitedPollutionPD_Ext', 'HOLimitedPollutionPDVehicles_Ext', 'HOMiscCovEndorsePD_Ext',
                                   'HOMiscCovEndorsePDVehicles_Ext', 'HOOtherLiabPD_Ext', 'HOOtherLiabPDVehicles_Ext', 'HOOtherStructEndorsePD_Ext', 
                                   'HOOtherStructEndorsePDVehicles_Ext', 'DFPremisesLiabilityAddResidencePD_Ext', 
                                   'DFPremisesLiabilityAddResidencePDVehicles_Ext', 'HOSpoilStockPD_Ext', 'HOAddInsuredManagersLessorsPD_Ext',
                                   'HOAddInsuredManagersLessorsPDVehicles_Ext', 'HOAddInsuredVendorsPD_Ext', 'HOAddInsuredVendorsPDVehicles_Ext',
                                   'HOAddResidenceLiabPD_Ext', 'HOAddResidenceLiabPDVehicles_Ext', 'HOCalPakPD_Ext', 'HOCalPakPDVehicles_Ext', 
                                   'HOCalPakNevPakPD_Ext', 'HOCalPakNevPakPDVehicles_Ext', 'GLCGLCov_ops_pd', 'GLCGLCov_prod_pd', 
                                   'HOHomeBusinessPD_Ext', 'HOHomeBusinessPDVehicles_Ext', 'HOHomeFarmCovPD_Ext', 'HOHomeFarmCovPDVehicles_Ext',
                                   'PALiabilityCov_pd', 'HOHorsesPD_Ext', 'HOHorsesPDVehicles_Ext', 'CMProductsCompletedOpsPD_Ext',
                                   'FULiabilityPD_Ext', 'FUOtherLiabilityPD_Ext', 'CIG_CULiabilityPD_Ext', 'CMGarageKeepersPD_Ext',
                                   'CMGarageKeepersPDVeh_Ext', 'PULiabilityPD_Ext', 'PUOtherLiabilityPD_Ext', 'DFOwnerLandlordTenantPDPI_Ext',
                                   'DFOwnerLandlordTenantPDVehPI_Ext', 'DFLiabilityPremisesLiabilityPDPI_Ext', 
                                   'DFLiabilityPremisesLiabilityPDVehiclesPI_Ext', 'CIG_BP7DirectorsAndOfficersLiabilityCoveragePD',
                                   'FMLiabilityPD_Ext', 'FMLiabilityPDVeh_Ext', 'CA7HiredAutoLiabilityCov_pd_Ext', 'CA7LiabilityCov_pd_Ext', 
                                   'CA7LimitedMexicoCov_pd_Ext', 'CA7NonOwnedAutoLiabCov_pd_Ext', 'CIG_CA7NonOwnedAutoLiabCov_pd_Ext',
                                   'CA7PltnLiabBroadCovBsnsAutoMtrCarrierTrCov_pd_Ext', 'CA7PltnLiabBroadCovForCvrdAutoGarageCovForm_pd_Ext',
                                   'CA7WorldwideGeneralLiabCovs_pd_Ext', 'FMBodilyInjuryAndPropertyDamagePD_Ext', 
                                   'FMBodilyInjuryAndPropertyDamagePDVeh_Ext', 'FMChemicalDriftPD_Ext', 'FMCropDustingPD_Ext', 
                                   'FMCustomFarmingPD_Ext', 'FMCustomFarmingPDVeh_Ext', 'FMLimitedPollutionPD_Ext', 'BP7BusinessLiabilityPD_Ext',
                                   'BP7BusinessLiabilityPDVehicle_Ext', 'BP7HiredAutoPD_Ext', 'BP7HiredAutoVehicle_Ext', 
                                   'CIG_BP7ClassLiquorLiabilityPD_Ext', 'CIG_BP7ClassLiquorLiabilityPDVeh_Ext', 'BP7NonOwnedAutoVehicle_Ext', 
                                   'BP7NonOwnedAutoPD_Ext','CIG_BP7SuppPayments','FMLiabilityFireLegalLiability_Ext', 'FMFireLegalLiability_Ext',
                                   'CIG_BP7TenantLegalLiabilityCov')
          AND tlpty.typecode NOT LIKE '%Auto%'
            THEN
            'Property Damage'  

         WHEN tlcovsty.typecode IN('BADealerLimitLiabCov_pd', 'BABobtailLiabCov_pd', 'zd7gujr17mccs3puv5jreeu1e59PD', 
                                   'HOCovEPDVehicles_Ext', 'BADOCLiabilityCovPD', 'farm_pd', 'CMLiabilityHiredAutoPD_Ext', 
                                   'CMLiabilityHiredAutoPDVeh_Ext', 'CMLiabilityLiquorLiabilityPD_Ext', 'CMLiabilityLiquorLiabilityPDVeh_Ext', 
                                   'CMLiabilityNonOwnedAutoPD_Ext', 'CMLiabilityNonOwnedAutoPDVeh_Ext', 'liab_trav_pr', 'PALiabilityCov_pd_Ext', 
                                   'BALimitedPropDamCov', 'BANonownedLiabCov_pd', 'DFOwnerLandlordTenantPD_Ext', 'DFOwnerLandlordTenantPDVeh_Ext', 
                                   'DFLiabilityPremisesLiabilityPD_Ext', 'DFLiabilityPremisesLiabilityPDVehicles_Ext', 'BASeasonTrailerLiabCov_pd',
                                   'CMLiabilityCovAPD_Ext', 'CMLiabilityCovAPDVeh_Ext', 'PALiabilityCSLCov_pd_Ext', 'HOCalPak2PD_Ext', 
                                   'HOCalPak2PDVehicles_Ext', 'HOAddCovCasHO3PD_Ext', 'HOAddCovCasHO4PD_Ext', 'HOAddCovCasHO5PD_Ext', 
                                   'HOAddCovCasHO6PD_Ext', 'HOLimitedPollutionPD_Ext', 'HOLimitedPollutionPDVehicles_Ext', 'HOMiscCovEndorsePD_Ext',
                                   'HOMiscCovEndorsePDVehicles_Ext', 'HOOtherLiabPD_Ext', 'HOOtherLiabPDVehicles_Ext', 'HOOtherStructEndorsePD_Ext', 
                                   'HOOtherStructEndorsePDVehicles_Ext', 'DFPremisesLiabilityAddResidencePD_Ext', 
                                   'DFPremisesLiabilityAddResidencePDVehicles_Ext', 'HOSpoilStockPD_Ext', 'HOAddInsuredManagersLessorsPD_Ext',
                                   'HOAddInsuredManagersLessorsPDVehicles_Ext', 'HOAddInsuredVendorsPD_Ext', 'HOAddInsuredVendorsPDVehicles_Ext',
                                   'HOAddResidenceLiabPD_Ext', 'HOAddResidenceLiabPDVehicles_Ext', 'HOCalPakPD_Ext', 'HOCalPakPDVehicles_Ext', 
                                   'HOCalPakNevPakPD_Ext', 'HOCalPakNevPakPDVehicles_Ext', 'GLCGLCov_ops_pd', 'GLCGLCov_prod_pd', 
                                   'HOHomeBusinessPD_Ext', 'HOHomeBusinessPDVehicles_Ext', 'HOHomeFarmCovPD_Ext', 'HOHomeFarmCovPDVehicles_Ext',
                                   'PALiabilityCov_pd', 'HOHorsesPD_Ext', 'HOHorsesPDVehicles_Ext', 'CMProductsCompletedOpsPD_Ext',
                                   'FULiabilityPD_Ext', 'FUOtherLiabilityPD_Ext', 'CIG_CULiabilityPD_Ext', 'CMGarageKeepersPD_Ext',
                                   'CMGarageKeepersPDVeh_Ext', 'PULiabilityPD_Ext', 'PUOtherLiabilityPD_Ext', 'DFOwnerLandlordTenantPDPI_Ext',
                                   'DFOwnerLandlordTenantPDVehPI_Ext', 'DFLiabilityPremisesLiabilityPDPI_Ext', 
                                   'DFLiabilityPremisesLiabilityPDVehiclesPI_Ext', 'CIG_BP7DirectorsAndOfficersLiabilityCoveragePD',
                                   'FMLiabilityPD_Ext', 'FMLiabilityPDVeh_Ext', 'CA7HiredAutoLiabilityCov_pd_Ext', 'CA7LiabilityCov_pd_Ext', 
                                   'CA7LimitedMexicoCov_pd_Ext', 'CA7NonOwnedAutoLiabCov_pd_Ext', 'CIG_CA7NonOwnedAutoLiabCov_pd_Ext',
                                   'CA7PltnLiabBroadCovBsnsAutoMtrCarrierTrCov_pd_Ext', 'CA7PltnLiabBroadCovForCvrdAutoGarageCovForm_pd_Ext',
                                   'CA7WorldwideGeneralLiabCovs_pd_Ext', 'FMBodilyInjuryAndPropertyDamagePD_Ext', 
                                   'FMBodilyInjuryAndPropertyDamagePDVeh_Ext', 'FMChemicalDriftPD_Ext', 'FMCropDustingPD_Ext', 
                                   'FMCustomFarmingPD_Ext', 'FMCustomFarmingPDVeh_Ext', 'FMLimitedPollutionPD_Ext', 'BP7BusinessLiabilityPD_Ext',
                                   'BP7BusinessLiabilityPDVehicle_Ext', 'BP7HiredAutoPD_Ext', 'BP7HiredAutoVehicle_Ext', 
                                   'CIG_BP7ClassLiquorLiabilityPD_Ext', 'CIG_BP7ClassLiquorLiabilityPDVeh_Ext', 'BP7NonOwnedAutoVehicle_Ext', 
                                   'BP7NonOwnedAutoPD_Ext','CIG_BP7SuppPayments','FMLiabilityFireLegalLiability_Ext', 'FMFireLegalLiability_Ext',
                                   'CIG_BP7TenantLegalLiabilityCov','BADOCLiabilityCovVEH', 'BANonOwnSSExtendCovVEH', 'BADealerLimitLiabCov_vd', 
                                   'BABobtailLiabCov_vd', 'BOPHiredAutoVEH', 'BAHiredLiabilityCovVEH', 'BOPNonOwnedAutoVEH', 'BAOwnedLiabilityCov_vd', 
                                   'PALiabilityCov_vd_Ext', 'BANonownedLiabCov_vd', 'BASeasonTrailerLiabCov_vd', 'PALiabilityCSLCov_vd_Ext', 
                                   'PALiabilityCov_vd', 'PAMexicoCovVEH', 'CA7HiredAutoLiabilityCov_vd_Ext', 'CA7LiabilityCov_vd_Ext', 
                                   'CA7LimitedMexicoCov_vd_Ext', 'CA7NonOwnedAutoLiabCov_vd_Ext', 'CIG_CA7NonOwnedAutoLiabCov_vd_Ext', 
                                   'CA7PltnLiabBroadCovBsnsAutoMtrCarrierTrCov_vd_Ext', 'CA7PltnLiabBroadCovForCvrdAutoGarageCovForm_vd_Ext',
                                   'CA7WorldwideGeneralLiabCovs_vd_Ext')
          AND (tlpty.typecode IN ('PersonalAuto') 
           OR  tlpty.typecode IN('CA7CommAuto'))  
            THEN
            'PD (Auto)'        

        WHEN tlpty.typecode IN('BusinessOwners') 
         AND tlcovsty.typecode IN('CIG_BP7CyberLiabilityDataBreachCov')
           THEN
           'Cyber' 

        WHEN tlpty.typecode IN ('HOPHomeowners')
         AND tlcovsty.typecode IN('HOCyberCyberbullying_Ext', 'HOCyberDataBreach_Ext', 'HOCyberIdentityRecovery_Ext', 'HOCyber_Ext')
           THEN
           'Home Cyber' 

        WHEN tlcovsty.typecode IN('CA7AutosLeasedHiredRentedWithDriversPhysDamageCovC', 'BACollisionCov', 'CA7VehicleCollisionGRD', 
                                  'CA7VehicleCollisionGRS', 'CA7VehicleCollisionPBT', 'CA7VehicleCollisionPPT', 'CA7VehicleCollisionSPV',
                                  'CA7VehicleCollisionTTT', 'PACollisionCov', 'BADOCCollisionCov', 'BACollisionLimited_MAMI', 
                                  'CA7DriveOtherCarCovBroadCovForNamedIndividualsColl', 'CIG_CA7CollisionDOC',
                                  'CIG_CA7VehicleCollisionDedWaiverPBT', 'CIG_CA7VehicleCollisionDedWaiverPPT',
                                  'CIG_CA7VehicleCollisionDedWaiverSPV', 'CIG_CA7VehicleCollisionDedWaiverTTT', 
                                  'CA7DealersDriveAwayCollisionCov', 'CA7GaragekeepersCovCollisionGRD', 'CA7GaragekeepersCovCollisionGRS',
                                  'CA7GaragekeepersCovCustomersSoundReceivingEquipGRS', 'BAHiredCollisionCov', 'CA7HiredAutoCollision',
                                  'PACollision_MA_MI_Limited', 'HOFarmEquipColl_Ext')     
           THEN
           'Coll'   




        WHEN tllc.typecode IN('advertising_Ext') 
         AND tlet.NAME IN('General') 
           THEN
           'Advertising'

        WHEN  tllc.typecode IN('animal') 
         AND  tlinc.typecode IN('PropertyContentsIncident')
         AND  tllpty.typecode IN('insured')
         AND (tlpty.typecode IN ('farmowners') 
          OR  tlpty.NAME IN('Commercial Manual'))  
           THEN
           'Animal Loss'

        WHEN tllc.typecode IN('burglary') 
         AND tlinc.typecode IN('FixedPropertyIncident', 'PropertyContentsIncident', 'LivingExpensesIncident')
         AND tllpty.typecode IN('insured') 
           THEN
           'Burglary'

        WHEN tllc.typecode IN('animal', 'animalcollision', 'FallingObject' , 'riotandcivil','vandalism', 
                              'wind' ,'snowice','waterdamage','firedamage', 'loadingdamage') 
         AND tlinc.typecode IN('VehicleIncident') 
         AND tllpty.typecode IN('insured') 
           THEN
           'Comp'

        WHEN tllc.typecode NOT IN('animal', 'animalcollision', 'FallingObject' , 'riotandcivil','vandalism', 
                                  'wind' ,'snowice','waterdamage','firedamage', 'loadingdamage') 
         AND tlinc.typecode IN('VehicleIncident') 
         AND tllpty.typecode IN('insured') 
           THEN
           'Coll'   

        WHEN  tllc.typecode IN ('glassbreakage')  
         AND  tlinc.typecode IN('VehicleIncident') 
         AND  tllpty.typecode IN('insured')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
           THEN
           'Comp (Glass)'

        WHEN  tllc.typecode IN ('theftentire' , 'theftparts')  
         AND  tlinc.typecode IN('VehicleIncident') 
         AND  tllpty.typecode IN('insured')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
           THEN
           'Comp (Theft)'

        WHEN tllc.typecode IN ('cyber_Ext') 
         AND tlpty.typecode IN ('BusinessOwners') 
           THEN
           'Cyber' 

        WHEN tllc.typecode IN ('cyber_Ext')  
         AND tlpty.typecode IN ('HOPHomeowners') 
           THEN
           'Home Cyber' 

        WHEN tllc.typecode IN('earthquake')  
           THEN
           'Earthquake'

        WHEN tllc.typecode IN ('mechanicalElectricalBreakdown_Ext')  
         AND tlinc.typecode NOT IN('InjuryIncident')  
           THEN 
           'Mechanical Breakdown'

         WHEN tllc.typecode IN('explosion')  
            THEN
            'Explosion' 

         WHEN tllc.typecode IN('fire')  
            THEN
            'Fire' 

         WHEN tllc.typecode IN('glassbreakage','broken_glass','buildingGlass_Ext')
          AND tlpty.typecode NOT LIKE '%Auto%' 
            THEN
            'Glass' 

         WHEN tllc.typecode IN('professionalLiability_Ext') 
          AND tllpty.typecode IN('third_party')  
            THEN
            'Malpractice, Professional Liability'  

         WHEN  tlinc.typecode IN('InjuryIncident') 
          AND  tlet.typecode IN ('MedPay') 
          AND (tlpty.typecode IN ('PersonalAuto') 
           OR  tlpty.typecode IN('CA7CommAuto')) 
            THEN
            'MP (Auto)' 

         WHEN  tlinc.typecode IN('VehicleIncident') 
          AND (tlpty.typecode IN ('PersonalAuto') 
           OR  tlpty.typecode IN('CA7CommAuto'))  
            THEN
            'PD (Auto)'        

         WHEN tllc.typecode IN('personal_injury_Ext') 
          AND tllpty.typecode IN('third_party')  
          AND tlpty.typecode NOT LIKE '%Auto%'
          AND tlinc.typecode IN('Incident') 
            THEN
            'Personal Injury'   

         WHEN tlet.typecode IN ('PropertyDamage', 'VehicleDamage')  
          AND tllpty.typecode IN('third_party')  
          AND tlpty.typecode NOT LIKE '%Auto%'
            THEN
            'Property Damage'  

        WHEN tllc.typecode IN('riotandcivil')  
         AND tllpty.typecode IN('insured')
           THEN
           'Riot, Civil Commotion'

        WHEN tllc.typecode IN('storm_Ext','hail','lightning_Ext','snowice','freeze_Ext') 
           THEN
           'Storm'  

        WHEN tllc.typecode IN('other_property_Ext','structfailure')
         AND tllpty.typecode IN('insured') 
         AND tlinc.typecode NOT IN('FixedPropertyIncident') 
           THEN
           'Structure'      

        WHEN tllc.typecode IN('theft_Ext')   
         AND tllpty.typecode IN('insured') 
           THEN
           'Theft'   

        WHEN tllc.typecode IN('vandalism')   
         AND tllpty.typecode IN('insured') 
           THEN
           'Vandalism, Malicious Mischief'  

        WHEN tllc.typecode IN('waterdamage')  
           THEN
           'Water' 

        WHEN  tlinc.typecode IN('InjuryIncident')  
         AND  tlet.typecode IN('BodilyInjuryDamage') 
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))  
           THEN
           'BI (Auto)'  

        WHEN tlinc.typecode IN('InjuryIncident')  
         AND tlpty.typecode NOT LIKE '%Auto%'
         AND tllc.typecode NOT IN('habitability_Ext','professionalLiability_Ext','environmentalPollution_Ext')
           THEN
           'Bodily Injury' 

        WHEN  tlinc.typecode IN('PropertyContentsIncident', 'MobilePropertyIncident')
         AND  tlet.typecode IN('Content' ,'PersonalPropertyDamage','BusinessPP_Ext','PropertyDamage')
         AND  tllpty.typecode IN('insured')
         AND (tlpty.typecode IN ('HOPHomeowners') 
          OR  tlpty.typecode IN('DwellingFire_Ext') 
          OR  tlpty.typecode IN ('BusinessOwners')) 
           THEN
           'Contents'

           ELSE 
           'Other'  
        END AS CAUSE_NAME,
        
      CASE 
        WHEN tllpty.typecode IN('insured') 
         AND tlcovsty.typecode IN('HO_CalAdd_Ext') 
           THEN
           34       

        WHEN tlcovsty.typecode IN('PAPIP_ORChildCare_Ext' , 'CMGarageKeepersPIPORChildCare_Ext') 
           THEN
           188         

        WHEN  tlcovsty.typecode IN('PAPIP_ORIncome_Ext' , 'PAPIP_WAIncome_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
           THEN
           173          

        WHEN tllpty.typecode IN('third_party') 
         AND tlcovsty.typecode IN('HOWorkCompIndemnity_Ext', 'FMWorkCompIndemnity_Ext') 
           THEN
           310 

        WHEN tllpty.typecode IN('third_party') 
         AND tlcovsty.typecode IN('HOWorkCompLiability_Ext', 'WCEmpLiabCov', 'FMWorkCompLiability_Ext')
           THEN
           311 

        WHEN tllpty.typecode IN('third_party') 
         AND tlcovsty.typecode IN('WCWorkersCompMED', 'HOWorkCompMedical_Ext', 'FMWorkCompMedical_Ext')
           THEN
           309

        WHEN tllpty.typecode IN('insured') 
         AND tlcovsty.typecode IN('HOServiceLine_Ext') 
           THEN
           511

        WHEN tlinc.typecode NOT IN('InjuryIncident')  
         AND tlcovsty.typecode IN('HOBreakdownElec_Ext', 'CMEquipmentBreakdownElec_Ext', 'CMEquipmentBreakdownMech_Ext', 
                                  'CMEquipmentBreakdownOther_Ext', 'CMEquipmentBreakdownWAElec_Ext', 'CMEquipmentBreakdownWAMech_Ext', 
                                  'CMEquipmentBreakdownWAOther_Ext', 'BP7EquipmentBreakdownProtection', 'BOPMechBreakdownCov', 
                                  'HOBreakdownMech_Ext', 'CMEquipmentBreakdownFarmElec_Ext', 'CMEquipmentBreakdownFarmMech_Ext', 
                                  'CMEquipmentBreakdownFarmOther_Ext', 'FMApplianceBreakdownPolicy_Ext', 'FMApplianceBreakdownRisk_Ext', 
                                  'FMBoilerAndMachinery_Ext', 'FMEquipmentBreakdown_Ext')
           THEN 
           140                  

        WHEN  tllpty.typecode IN('third_party') 
         AND  tlcovsty.typecode IN ('BOPEmpBenExtRpting', 'BOPEmpBenefits', 'BP7EmpBenefitsLiabCov', 'CA7EmplBenefitsLiab', 
                                    'CIG_ULEmployeeBenefitLiabilityCov', 'CMLiabilityEmployeeBenefits_Ext', 
                                    'GLEmpBenefitsLiabilityCov')
           THEN 
           143 

        WHEN  tlcovsty.typecode IN('BOPEmpDisCov', 'BP7EmployeeDishty', 'BP7LocationEmployeeDishty', 
                                   'CMPropCommercialCrimeEmployeeDishonesty_Ext') 
         AND (tlpty.NAME IN ('Businessowners') 
          OR  tlpty.NAME IN('Commercial Manual'))
           THEN 
           139 

        WHEN  tlcovsty.typecode IN('BP7EmploymentRelatedPracticesLiabilityCov', 'CMLiabilityEmploymentPractices_Ext', 
                                  'CMLiabilityEmploymentPracticesBI_Ext', 'FMEmploymentPracticesBI_Ext', 
                                  'FMEmploymentPractices_Ext')
         AND (tlpty.NAME IN ('Businessowners') 
          OR  tlpty.NAME IN('Commercial Manual')
          OR  tlpty.typecode IN ('farmowners'))
           THEN 
           411 

        WHEN tlcovsty.typecode IN('CIG_BP7BarberandBeautyProfessionalLiability', 'BP7BarbersBeauticiansProflLiab', 
                                  'BP7BeautySalonsProflLiab', 'BP7FuneralDirectorsProflLiab', 'CIG_BP7VeterinarianProfessionalLiability', 
                                  'BP7VeterinariansProflLiab', 'CIG_BP7BarberandBeautyProfessionalLiabilityBI', 
                                  'CIG_BP7BarberandBeautyProfessionalLiabilityMP', 'CIG_BP7BarberandBeautyProfessionalLiabilityPD', 
                                  'CIG_BP7VeterinarianProfessionalLiabilityBI', 'CIG_BP7VeterinarianProfessionalLiabilityMP', 
                                  'CIG_BP7VeterinarianProfessionalLiabilityPD')  
           THEN
           39  

        WHEN tlinc.typecode IN('InjuryIncident') 
         AND tlpty.typecode NOT LIKE '%Auto%'
         AND tlcovsty.typecode IN('DFComprehensivePersonalLiabilityMP_Ext', 'z8tjsluucfmoh3nho364cli3uv8', 'BAOwnedMedPayCov', 
                                  'CA7VehicleMedPay', 'DFMedPay_Ext', 'PAMedPayCov', 'BADOCMedPayCov', 
                                  'CA7DriveOtherCarCovBroadCovForNamedIndividualsMedP', 'CIG_CA7MedicalPaymentsDOC', 
                                  'CA7VehicleMedPayAuto', 'CA7VehicleMedPayLocationsAndOps', 'CMLiabilityCovCMedPay_Ext', 
                                  'DFMedPayAddResidence_Ext', 'HOMiscCovEndorseMP_Ext', 'HOOtherLiabMP_Ext', 'HOOtherStructEndorseMP_Ext', 
                                  'HOSpoilStockMP_Ext', 'CMLiabilityCovBMedPay_Ext', 'CMGarageKeepersMedPay_Ext', 
                                  'CMGarageKeepersMedPayAuto_Ext', 'HOAddInsuredManagersLessorsMP_Ext', 'HOAddInsuredVendorsMP_Ext', 
                                  'HOAddResidenceLiabMP_Ext', 'HOHomeBusinessMP_Ext', 'HOHomeFarmCovMP_Ext', 'FMEmployeeMedicalPayments_Ext', 
                                  'BP7BusinessLiabilityMP_Ext', 'CIG_BP7DirectorsAndOfficersLiabilityCoverageMP', 'FMLiabilityMedPay_Ext', 
                                  'FMMedPay_Ext', 'FMCustomFarmingMedPay_Ext')
           THEN
           42  

        WHEN  tlinc.typecode IN('InjuryIncident') 
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
         AND  tlcovsty.typecode IN('DFComprehensivePersonalLiabilityMP_Ext', 'z8tjsluucfmoh3nho364cli3uv8', 'BAOwnedMedPayCov', 
                                 'CA7VehicleMedPay', 'DFMedPay_Ext', 'PAMedPayCov', 'BADOCMedPayCov', 
                                 'CA7DriveOtherCarCovBroadCovForNamedIndividualsMedP', 'CIG_CA7MedicalPaymentsDOC', 
                                 'CA7VehicleMedPayAuto', 'CA7VehicleMedPayLocationsAndOps', 'CMLiabilityCovCMedPay_Ext', 
                                 'DFMedPayAddResidence_Ext', 'HOMiscCovEndorseMP_Ext', 'HOOtherLiabMP_Ext', 'HOOtherStructEndorseMP_Ext', 
                                 'HOSpoilStockMP_Ext', 'CMLiabilityCovBMedPay_Ext', 'CMGarageKeepersMedPay_Ext', 
                                 'CMGarageKeepersMedPayAuto_Ext', 'HOAddInsuredManagersLessorsMP_Ext', 'HOAddInsuredVendorsMP_Ext', 
                                 'HOAddResidenceLiabMP_Ext', 'HOHomeBusinessMP_Ext', 'HOHomeFarmCovMP_Ext', 'FMEmployeeMedicalPayments_Ext', 
                                 'BP7BusinessLiabilityMP_Ext', 'CIG_BP7DirectorsAndOfficersLiabilityCoverageMP', 'FMLiabilityMedPay_Ext', 
                                 'FMMedPay_Ext', 'FMCustomFarmingMedPay_Ext')
           THEN
           111 

        WHEN tllpty.typecode IN('third_party') 
         AND tlpty.typecode IN('Commercial Manual') 
         AND tlcovsty.typecode IN('CMGolfBallDamage_Ext') 
           THEN
           350  

        WHEN tllpty.typecode IN('insured') 
         AND tlpty.typecode IN ('HOPHomeowners') 
         AND tlcovsty.typecode IN('z2tgk324p0qk1fq75ei5be8g5gb', 'BP7IDFraudExpenseCov', 'HOCyberIdentityRecovery_Ext')
           THEN
           148 

        WHEN tllpty.typecode IN('insured') 
         AND tlpty.typecode NOT LIKE '%Auto%' 
         AND tlcovsty.typecode IN('CMPropGlass_Ext')
           THEN
           136 

         WHEN tlcovsty.typecode IN('CMGarageKeepersPIPOR_Ext','PAPIP_ORMedical_Ext','CMGarageKeepersPIPWA_Ext',
                                   'PAPIP_WAMedical_Ext','CA7VehiclePIP') 
            THEN
            171  

         WHEN tllpty.typecode IN('insured') 
          AND tlpty.typecode IN ('BusinessOwners') 
          AND tlcovsty.typecode IN('BOPPersonalEffects') 
            THEN
            370 

         WHEN tllpty.typecode IN('third_party') 
          AND tlcovsty.typecode IN('CMProductRecall_Ext','CA7LmtdProductWithdrawalExpenseEndorsement','ProductWithdrawalLtd') 
            THEN
            492    

        WHEN tlet.typecode IN ('VehicleDamage' , 'LossOfUseDamage') 
         AND tlpty.typecode IN ('PersonalAuto', 'CA7CommAuto') 
         AND tlcovsty.typecode IN('BARentalCov', 'CA7PolicyRentalReimbursement', 'PARentalCov', 'CA7RentalReimbursementPBT',
                                  'CA7RentalReimbursementPPT', 'CA7RentalReimbursementSPV', 'CA7RentalReimbursementTTT', 
                                  'CIG_CA7RentalReimbursementOTCPBT', 'CIG_CA7RentalReimbursementOTCPPT', 
                                  'CIG_CA7RentalReimbursementOTCSPV', 'CIG_CA7RentalReimbursementOTCTTT', 
                                  'CA7HiredAutoRentalReimbursement', 'ContractorsEquipRentalReibursement')
           THEN
           105  

        WHEN tlcovsty.typecode IN('PAPIP_ORFuneral_Ext', 'PAPIP_ORServices_Ext', 'PAPIP_WAFuneral_Ext', 'PAPIP_WAServices_Ext', 
                                  'CMGarageKeepersPIPORFuneral_Ext', 'CMGarageKeepersPIPORServices_Ext', 
                                  'CMGarageKeepersPIPWAFuneral_Ext', 'CMGarageKeepersPIPWAServices_Ext') 
           THEN
           172

        WHEN tlcovsty.typecode IN('BP7ExtddReportingPeriodEmpBenefitsLiabCov', 'BP7ExtddReportingPeriodEmpBenefitsLiabCovBI_Ext',
                                  'FMFarmEmployersLiabilityStopGapWA_Ext') 
           THEN
           491

        WHEN  tllpty.typecode IN('insured') 
         AND  tlet.typecode IN('BodilyInjuryDamage') 
         AND  tlcovsty.typecode IN('CA7VehicleUnderinsuredMotoristPolicy', 'BAOwnedUIMBICov', 'PAUIMBICov', 'PAUIMBICSLCov_Ext', 
                                   'CMGarageKeepersUIM_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
           THEN
           113    

        WHEN  tlinc.typecode IN('VehicleIncident')       
         AND  tlcovsty.typecode IN('BADOCUninsuredVEH', 'BADOCUninsuredBI', 'BADOCUninsuredPD', 'BADOCUnderinsCov',
                                  'BAOwnedUIMPDCov', 'CIG_CA7UnderinsuredMotoristCovDOC', 'CIG_CA7UnderinsuredMotoristBIAndPD',
                                  'CIG_CA7UnderinsuredMotoristBIPDDOC', 'CA7DriveOtherCarCovBroadCovForNamedIndividualsUnde', 
                                  'PAUMPDCov', 'CIG_CA7UninsuredMotoristPropertyDamageCovDOC', 'CIG_CA7UninsuredMotoristPropertyDamage', 
                                  'CA7DriveOtherCarCovBroadCovForNamedIndividualsUnin', 'CIG_CA7UninsuredMotoristCovDOC', 
                                  'CIG_CA7UnderinsuredMotorBIPDDOC', 'PAUIMPDCov', 'CIG_CA7UnderinsuredMotoristBIAndPDCov_bi_Ext', 
                                  'CIG_CA7UnderinsuredMotoristBIAndPDCov_vd_Ext', 'CIG_CA7UnderinsuredMotoristBIPDDOCCov_bi_Ext', 
                                  'CIG_CA7UnderinsuredMotoristBIPDDOCCov_vd_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))   
           THEN 
           106

        WHEN  tlet.typecode IN('GeneralDamage') 
         AND  tlcovsty.typecode IN('CIG_CA7VehicleCollisionDedWaiverPBT', 'CIG_CA7VehicleCollisionDedWaiverPPT',
                                   'CIG_CA7VehicleCollisionDedWaiverSPV', 'CIG_CA7VehicleCollisionDedWaiverTTT', 
                                   'PAUMCollisionCov_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))
           THEN 
           107

        WHEN  tlcovsty.typecode IN('BAOwnedUMBICov', 'PAUMBICov', 'PAUMBICSLCov_Ext', 'CMGarageKeepersUMBI_Ext')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))
           THEN 
           112

        WHEN tllpty.typecode IN('insured') 
         AND tlcovsty.typecode IN('BATowingLaborCov', 'CA7VehicleTowingLaborPPT', 'CIG_CA7VehicleTowingLaborPBT', 
                                  'CIG_CA7VehicleTowingLaborSPV', 'CIG_CA7VehicleTowingLaborTTT', 'PATowingLaborCov', 
                                  'CIG_CA7TowingLabor', 'CIG_CA7TowingLaborPBT')
           THEN
           104 
           
       WHEN tllc.typecode IN('advertising_Ext')   AND tlet.NAME IN('General') 
           THEN  43
           
       WHEN  tlcovsty.typecode IN('CMLiabilityCovBAdvertising_Ext', 'FMPersonalAndAdvertisingAI_Ext')
          OR (tlet.typecode NOT IN('PersonalInjury_Ext')
         AND  tlcovsty.typecode IN('BP7AmendmentOfPersonalAndAdvertisingInjuryDefntn', 
                                   'CA7LmtdContractualLiabCovForPersonalAndAdvertising', 'BOPPersAdvertInj', 
                                   'GLLimitedPAandInjuryCov', 'GLCGLCov_adv_gd'))
           THEN 
           43

        WHEN  tlinc.typecode IN('InjuryIncident') 
         AND  tlet.typecode IN('BodilyInjuryDamage') 
         AND  tlcovsty.typecode IN('CMLiabilityNonOwnedAutoBI_Ext', 'BP7HiredNonOwnedAutoBI', 'CA7NonOwnedAutoLiabCov_bi_Ext', 
                                   'CIG_CA7NonOwnedAutoLiabCov_bi_Ext', 'BP7NonOwnedAutoBI_Ext','CA7FarmLaborContractorsPBT',
                                   'CA7FarmLaborContractorsTTT')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))  
           THEN
           109  

        WHEN tlinc.typecode IN('InjuryIncident') 
         AND tlpty.typecode NOT LIKE '%Auto%'
         AND  tlcovsty.typecode IN('CMLiabilityNonOwnedAutoBI_Ext', 'BP7HiredNonOwnedAutoBI', 'CA7NonOwnedAutoLiabCov_bi_Ext', 
                                   'CIG_CA7NonOwnedAutoLiabCov_bi_Ext', 'BP7NonOwnedAutoBI_Ext','CA7FarmLaborContractorsPBT',
                                   'CA7FarmLaborContractorsTTT')
           THEN
           36 

        WHEN  tlcovsty.typecode IN('CA7AutosLeasedHiredRentedWithDriversPhysDamageCov1', 'BAComprehensiveCov', 'PAComprehensiveCov', 
                                   'BADOCCompCov', 'DFComprehensivePersonalLiabilityPD_Ext', 'DFComprehensivePersonalLiabilityPDVeh_Ext', 
                                   'BAHiredCompCov', 'HOFarmEquipComp_Ext', 'HOFarmEquipCompTheft_Ext', 
                                   'DFComprehensivePersonalLiabilityPIPPI_Ext', 'DFComprehensivePersonalLiabilityPDPI_Ext', 
                                   'DFComprehensivePersonalLiabilityPDVehPI_Ext')
           THEN
           102           

        WHEN tllc.typecode IN('habitability_Ext') 
         AND tllpty.typecode IN('third_party') 
           THEN
           47 

         WHEN tllpty.typecode IN('third_party')  
          AND tlpty.typecode NOT LIKE '%Auto%'
          AND tlinc.typecode IN('Incident') 
          AND tlcovsty.typecode IN('HOCovEPI_Ext', 'CMLiabilityCovBPI_Ext', 'HOMiscCovEndorsePersonalInjury_Ext',
                                   'HOOtherLiabPersonalInjury_Ext', 'HOOtherStructEndorsePI_Ext', 'DFPersonalInjuryClaimExpenses_Ext', 
                                   'HOAddInsuredManagersLessorsPersonalInjury_Ext', 'HOAddInsuredVendorsPersonalInjury_Ext', 
                                   'HOAddResidenceLiabPersonalInjury_Ext', 'HOCalPakPersonalInjury_Ext', 'HOCalPakNevPakPersonalInjury_Ext', 
                                   'HOHomeBusinessPI_Ext', 'HOCalPak2PersonalInjury_Ext', 'FULiabilityPI_Ext', 'FUOtherLiabilityPI_Ext', 
                                   'CMGarageKeepersPersInj_Ext', 'PULiabilityPI_Ext', 'PUOtherLiabilityPI_Ext', 'BP7BusinessLiabilityPI_Ext', 
                                   'FMPersonalAndAdvertisingPI_Ext')
            THEN
            45   

         WHEN tllc.typecode IN('environmentalPollution_Ext') 
          AND tllpty.typecode IN('insured') 
          AND tlpty.typecode NOT LIKE '%Auto%'  
            THEN
            46  

         WHEN tllc.typecode IN('environmentalPollution_Ext') 
          AND tllpty.typecode IN('third_party') 
            THEN
            108   

         WHEN tlcovsty.typecode IN('BADealerLimitLiabCov_pd', 'BABobtailLiabCov_pd', 'zd7gujr17mccs3puv5jreeu1e59PD', 
                                   'HOCovEPDVehicles_Ext', 'BADOCLiabilityCovPD', 'farm_pd', 'CMLiabilityHiredAutoPD_Ext', 
                                   'CMLiabilityHiredAutoPDVeh_Ext', 'CMLiabilityLiquorLiabilityPD_Ext', 'CMLiabilityLiquorLiabilityPDVeh_Ext', 
                                   'CMLiabilityNonOwnedAutoPD_Ext', 'CMLiabilityNonOwnedAutoPDVeh_Ext', 'liab_trav_pr', 'PALiabilityCov_pd_Ext', 
                                   'BALimitedPropDamCov', 'BANonownedLiabCov_pd', 'DFOwnerLandlordTenantPD_Ext', 'DFOwnerLandlordTenantPDVeh_Ext', 
                                   'DFLiabilityPremisesLiabilityPD_Ext', 'DFLiabilityPremisesLiabilityPDVehicles_Ext', 'BASeasonTrailerLiabCov_pd',
                                   'CMLiabilityCovAPD_Ext', 'CMLiabilityCovAPDVeh_Ext', 'PALiabilityCSLCov_pd_Ext', 'HOCalPak2PD_Ext', 
                                   'HOCalPak2PDVehicles_Ext', 'HOAddCovCasHO3PD_Ext', 'HOAddCovCasHO4PD_Ext', 'HOAddCovCasHO5PD_Ext', 
                                   'HOAddCovCasHO6PD_Ext', 'HOLimitedPollutionPD_Ext', 'HOLimitedPollutionPDVehicles_Ext', 'HOMiscCovEndorsePD_Ext',
                                   'HOMiscCovEndorsePDVehicles_Ext', 'HOOtherLiabPD_Ext', 'HOOtherLiabPDVehicles_Ext', 'HOOtherStructEndorsePD_Ext', 
                                   'HOOtherStructEndorsePDVehicles_Ext', 'DFPremisesLiabilityAddResidencePD_Ext', 
                                   'DFPremisesLiabilityAddResidencePDVehicles_Ext', 'HOSpoilStockPD_Ext', 'HOAddInsuredManagersLessorsPD_Ext',
                                   'HOAddInsuredManagersLessorsPDVehicles_Ext', 'HOAddInsuredVendorsPD_Ext', 'HOAddInsuredVendorsPDVehicles_Ext',
                                   'HOAddResidenceLiabPD_Ext', 'HOAddResidenceLiabPDVehicles_Ext', 'HOCalPakPD_Ext', 'HOCalPakPDVehicles_Ext', 
                                   'HOCalPakNevPakPD_Ext', 'HOCalPakNevPakPDVehicles_Ext', 'GLCGLCov_ops_pd', 'GLCGLCov_prod_pd', 
                                   'HOHomeBusinessPD_Ext', 'HOHomeBusinessPDVehicles_Ext', 'HOHomeFarmCovPD_Ext', 'HOHomeFarmCovPDVehicles_Ext',
                                   'PALiabilityCov_pd', 'HOHorsesPD_Ext', 'HOHorsesPDVehicles_Ext', 'CMProductsCompletedOpsPD_Ext',
                                   'FULiabilityPD_Ext', 'FUOtherLiabilityPD_Ext', 'CIG_CULiabilityPD_Ext', 'CMGarageKeepersPD_Ext',
                                   'CMGarageKeepersPDVeh_Ext', 'PULiabilityPD_Ext', 'PUOtherLiabilityPD_Ext', 'DFOwnerLandlordTenantPDPI_Ext',
                                   'DFOwnerLandlordTenantPDVehPI_Ext', 'DFLiabilityPremisesLiabilityPDPI_Ext', 
                                   'DFLiabilityPremisesLiabilityPDVehiclesPI_Ext', 'CIG_BP7DirectorsAndOfficersLiabilityCoveragePD',
                                   'FMLiabilityPD_Ext', 'FMLiabilityPDVeh_Ext', 'CA7HiredAutoLiabilityCov_pd_Ext', 'CA7LiabilityCov_pd_Ext', 
                                   'CA7LimitedMexicoCov_pd_Ext', 'CA7NonOwnedAutoLiabCov_pd_Ext', 'CIG_CA7NonOwnedAutoLiabCov_pd_Ext',
                                   'CA7PltnLiabBroadCovBsnsAutoMtrCarrierTrCov_pd_Ext', 'CA7PltnLiabBroadCovForCvrdAutoGarageCovForm_pd_Ext',
                                   'CA7WorldwideGeneralLiabCovs_pd_Ext', 'FMBodilyInjuryAndPropertyDamagePD_Ext', 
                                   'FMBodilyInjuryAndPropertyDamagePDVeh_Ext', 'FMChemicalDriftPD_Ext', 'FMCropDustingPD_Ext', 
                                   'FMCustomFarmingPD_Ext', 'FMCustomFarmingPDVeh_Ext', 'FMLimitedPollutionPD_Ext', 'BP7BusinessLiabilityPD_Ext',
                                   'BP7BusinessLiabilityPDVehicle_Ext', 'BP7HiredAutoPD_Ext', 'BP7HiredAutoVehicle_Ext', 
                                   'CIG_BP7ClassLiquorLiabilityPD_Ext', 'CIG_BP7ClassLiquorLiabilityPDVeh_Ext', 'BP7NonOwnedAutoVehicle_Ext', 
                                   'BP7NonOwnedAutoPD_Ext','CIG_BP7SuppPayments','FMLiabilityFireLegalLiability_Ext', 'FMFireLegalLiability_Ext',
                                   'CIG_BP7TenantLegalLiabilityCov')
          AND tlpty.typecode NOT LIKE '%Auto%'
            THEN
            37  

         WHEN tlcovsty.typecode IN('BADealerLimitLiabCov_pd', 'BABobtailLiabCov_pd', 'zd7gujr17mccs3puv5jreeu1e59PD', 
                                   'HOCovEPDVehicles_Ext', 'BADOCLiabilityCovPD', 'farm_pd', 'CMLiabilityHiredAutoPD_Ext', 
                                   'CMLiabilityHiredAutoPDVeh_Ext', 'CMLiabilityLiquorLiabilityPD_Ext', 'CMLiabilityLiquorLiabilityPDVeh_Ext', 
                                   'CMLiabilityNonOwnedAutoPD_Ext', 'CMLiabilityNonOwnedAutoPDVeh_Ext', 'liab_trav_pr', 'PALiabilityCov_pd_Ext', 
                                   'BALimitedPropDamCov', 'BANonownedLiabCov_pd', 'DFOwnerLandlordTenantPD_Ext', 'DFOwnerLandlordTenantPDVeh_Ext', 
                                   'DFLiabilityPremisesLiabilityPD_Ext', 'DFLiabilityPremisesLiabilityPDVehicles_Ext', 'BASeasonTrailerLiabCov_pd',
                                   'CMLiabilityCovAPD_Ext', 'CMLiabilityCovAPDVeh_Ext', 'PALiabilityCSLCov_pd_Ext', 'HOCalPak2PD_Ext', 
                                   'HOCalPak2PDVehicles_Ext', 'HOAddCovCasHO3PD_Ext', 'HOAddCovCasHO4PD_Ext', 'HOAddCovCasHO5PD_Ext', 
                                   'HOAddCovCasHO6PD_Ext', 'HOLimitedPollutionPD_Ext', 'HOLimitedPollutionPDVehicles_Ext', 'HOMiscCovEndorsePD_Ext',
                                   'HOMiscCovEndorsePDVehicles_Ext', 'HOOtherLiabPD_Ext', 'HOOtherLiabPDVehicles_Ext', 'HOOtherStructEndorsePD_Ext', 
                                   'HOOtherStructEndorsePDVehicles_Ext', 'DFPremisesLiabilityAddResidencePD_Ext', 
                                   'DFPremisesLiabilityAddResidencePDVehicles_Ext', 'HOSpoilStockPD_Ext', 'HOAddInsuredManagersLessorsPD_Ext',
                                   'HOAddInsuredManagersLessorsPDVehicles_Ext', 'HOAddInsuredVendorsPD_Ext', 'HOAddInsuredVendorsPDVehicles_Ext',
                                   'HOAddResidenceLiabPD_Ext', 'HOAddResidenceLiabPDVehicles_Ext', 'HOCalPakPD_Ext', 'HOCalPakPDVehicles_Ext', 
                                   'HOCalPakNevPakPD_Ext', 'HOCalPakNevPakPDVehicles_Ext', 'GLCGLCov_ops_pd', 'GLCGLCov_prod_pd', 
                                   'HOHomeBusinessPD_Ext', 'HOHomeBusinessPDVehicles_Ext', 'HOHomeFarmCovPD_Ext', 'HOHomeFarmCovPDVehicles_Ext',
                                   'PALiabilityCov_pd', 'HOHorsesPD_Ext', 'HOHorsesPDVehicles_Ext', 'CMProductsCompletedOpsPD_Ext',
                                   'FULiabilityPD_Ext', 'FUOtherLiabilityPD_Ext', 'CIG_CULiabilityPD_Ext', 'CMGarageKeepersPD_Ext',
                                   'CMGarageKeepersPDVeh_Ext', 'PULiabilityPD_Ext', 'PUOtherLiabilityPD_Ext', 'DFOwnerLandlordTenantPDPI_Ext',
                                   'DFOwnerLandlordTenantPDVehPI_Ext', 'DFLiabilityPremisesLiabilityPDPI_Ext', 
                                   'DFLiabilityPremisesLiabilityPDVehiclesPI_Ext', 'CIG_BP7DirectorsAndOfficersLiabilityCoveragePD',
                                   'FMLiabilityPD_Ext', 'FMLiabilityPDVeh_Ext', 'CA7HiredAutoLiabilityCov_pd_Ext', 'CA7LiabilityCov_pd_Ext', 
                                   'CA7LimitedMexicoCov_pd_Ext', 'CA7NonOwnedAutoLiabCov_pd_Ext', 'CIG_CA7NonOwnedAutoLiabCov_pd_Ext',
                                   'CA7PltnLiabBroadCovBsnsAutoMtrCarrierTrCov_pd_Ext', 'CA7PltnLiabBroadCovForCvrdAutoGarageCovForm_pd_Ext',
                                   'CA7WorldwideGeneralLiabCovs_pd_Ext', 'FMBodilyInjuryAndPropertyDamagePD_Ext', 
                                   'FMBodilyInjuryAndPropertyDamagePDVeh_Ext', 'FMChemicalDriftPD_Ext', 'FMCropDustingPD_Ext', 
                                   'FMCustomFarmingPD_Ext', 'FMCustomFarmingPDVeh_Ext', 'FMLimitedPollutionPD_Ext', 'BP7BusinessLiabilityPD_Ext',
                                   'BP7BusinessLiabilityPDVehicle_Ext', 'BP7HiredAutoPD_Ext', 'BP7HiredAutoVehicle_Ext', 
                                   'CIG_BP7ClassLiquorLiabilityPD_Ext', 'CIG_BP7ClassLiquorLiabilityPDVeh_Ext', 'BP7NonOwnedAutoVehicle_Ext', 
                                   'BP7NonOwnedAutoPD_Ext','CIG_BP7SuppPayments','FMLiabilityFireLegalLiability_Ext', 'FMFireLegalLiability_Ext',
                                   'CIG_BP7TenantLegalLiabilityCov','BADOCLiabilityCovVEH', 'BANonOwnSSExtendCovVEH', 'BADealerLimitLiabCov_vd', 
                                   'BABobtailLiabCov_vd', 'BOPHiredAutoVEH', 'BAHiredLiabilityCovVEH', 'BOPNonOwnedAutoVEH', 'BAOwnedLiabilityCov_vd', 
                                   'PALiabilityCov_vd_Ext', 'BANonownedLiabCov_vd', 'BASeasonTrailerLiabCov_vd', 'PALiabilityCSLCov_vd_Ext', 
                                   'PALiabilityCov_vd', 'PAMexicoCovVEH', 'CA7HiredAutoLiabilityCov_vd_Ext', 'CA7LiabilityCov_vd_Ext', 
                                   'CA7LimitedMexicoCov_vd_Ext', 'CA7NonOwnedAutoLiabCov_vd_Ext', 'CIG_CA7NonOwnedAutoLiabCov_vd_Ext', 
                                   'CA7PltnLiabBroadCovBsnsAutoMtrCarrierTrCov_vd_Ext', 'CA7PltnLiabBroadCovForCvrdAutoGarageCovForm_vd_Ext',
                                   'CA7WorldwideGeneralLiabCovs_vd_Ext')
          AND (tlpty.typecode IN ('PersonalAuto') 
           OR  tlpty.typecode IN('CA7CommAuto'))  
            THEN
            110        

        WHEN tlpty.typecode IN('BusinessOwners') 
         AND tlcovsty.typecode IN('CIG_BP7CyberLiabilityDataBreachCov')
           THEN
           551 

        WHEN tlpty.typecode IN ('HOPHomeowners')
         AND tlcovsty.typecode IN('HOCyberCyberbullying_Ext', 'HOCyberDataBreach_Ext', 'HOCyberIdentityRecovery_Ext', 'HOCyber_Ext')
           THEN
           591 

        WHEN tlcovsty.typecode IN('CA7AutosLeasedHiredRentedWithDriversPhysDamageCovC', 'BACollisionCov', 'CA7VehicleCollisionGRD', 
                                  'CA7VehicleCollisionGRS', 'CA7VehicleCollisionPBT', 'CA7VehicleCollisionPPT', 'CA7VehicleCollisionSPV',
                                  'CA7VehicleCollisionTTT', 'PACollisionCov', 'BADOCCollisionCov', 'BACollisionLimited_MAMI', 
                                  'CA7DriveOtherCarCovBroadCovForNamedIndividualsColl', 'CIG_CA7CollisionDOC',
                                  'CIG_CA7VehicleCollisionDedWaiverPBT', 'CIG_CA7VehicleCollisionDedWaiverPPT',
                                  'CIG_CA7VehicleCollisionDedWaiverSPV', 'CIG_CA7VehicleCollisionDedWaiverTTT', 
                                  'CA7DealersDriveAwayCollisionCov', 'CA7GaragekeepersCovCollisionGRD', 'CA7GaragekeepersCovCollisionGRS',
                                  'CA7GaragekeepersCovCustomersSoundReceivingEquipGRS', 'BAHiredCollisionCov', 'CA7HiredAutoCollision',
                                  'PACollision_MA_MI_Limited', 'HOFarmEquipColl_Ext')     
           THEN
           103   


        WHEN tllc.typecode IN('advertising_Ext') 
         AND tlet.NAME IN('General') 
           THEN
           43

        WHEN  tllc.typecode IN('animal') 
         AND  tlinc.typecode IN('PropertyContentsIncident')
         AND  tllpty.typecode IN('insured')
         AND (tlpty.typecode IN ('farmowners') 
          OR  tlpty.NAME IN('Commercial Manual'))  
           THEN
           142

        WHEN tllc.typecode IN('burglary') 
         AND tlinc.typecode IN('FixedPropertyIncident', 'PropertyContentsIncident', 'LivingExpensesIncident')
         AND tllpty.typecode IN('insured') 
           THEN
           137

        WHEN tllc.typecode IN('animal', 'animalcollision', 'FallingObject' , 'riotandcivil','vandalism', 
                              'wind' ,'snowice','waterdamage','firedamage', 'loadingdamage') 
         AND tlinc.typecode IN('VehicleIncident') 
         AND tllpty.typecode IN('insured') 
           THEN
           102

        WHEN tllc.typecode NOT IN('animal', 'animalcollision', 'FallingObject' , 'riotandcivil','vandalism', 
                                  'wind' ,'snowice','waterdamage','firedamage', 'loadingdamage') 
         AND tlinc.typecode IN('VehicleIncident') 
         AND tllpty.typecode IN('insured') 
           THEN
           103   

        WHEN  tllc.typecode IN ('glassbreakage')  
         AND  tlinc.typecode IN('VehicleIncident') 
         AND  tllpty.typecode IN('insured')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
           THEN
           228

        WHEN  tllc.typecode IN ('theftentire' , 'theftparts')  
         AND  tlinc.typecode IN('VehicleIncident') 
         AND  tllpty.typecode IN('insured')
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto')) 
           THEN
           114

        WHEN tllc.typecode IN ('cyber_Ext') 
         AND tlpty.typecode IN ('BusinessOwners') 
           THEN
           551 

        WHEN tllc.typecode IN ('cyber_Ext')  
         AND tlpty.typecode IN ('HOPHomeowners') 
           THEN
           591 

        WHEN tllc.typecode IN('earthquake')  
           THEN
           32

        WHEN tllc.typecode IN ('mechanicalElectricalBreakdown_Ext')  
         AND tlinc.typecode NOT IN('InjuryIncident')  
           THEN 
           140

         WHEN tllc.typecode IN('explosion')  
            THEN
            41 

         WHEN tllc.typecode IN('fire')  
            THEN
            25 

         WHEN tllc.typecode IN('glassbreakage','broken_glass','buildingGlass_Ext')
          AND tlpty.typecode NOT LIKE '%Auto%' 
            THEN
            136 

         WHEN tllc.typecode IN('professionalLiability_Ext') 
          AND tllpty.typecode IN('third_party')  
            THEN
            39  

         WHEN  tlinc.typecode IN('InjuryIncident') 
          AND  tlet.typecode IN ('MedPay') 
          AND (tlpty.typecode IN ('PersonalAuto') 
           OR  tlpty.typecode IN('CA7CommAuto')) 
            THEN
            111 

         WHEN  tlinc.typecode IN('VehicleIncident') 
          AND (tlpty.typecode IN ('PersonalAuto') 
           OR  tlpty.typecode IN('CA7CommAuto'))  
            THEN
            110        

         WHEN tllc.typecode IN('personal_injury_Ext') 
          AND tllpty.typecode IN('third_party')  
          AND tlpty.typecode NOT LIKE '%Auto%'
          AND tlinc.typecode IN('Incident') 
            THEN
            45   

         WHEN tlet.typecode IN ('PropertyDamage', 'VehicleDamage')  
          AND tllpty.typecode IN('third_party')  
          AND tlpty.typecode NOT LIKE '%Auto%'
            THEN
            37  

        WHEN tllc.typecode IN('riotandcivil')  
         AND tllpty.typecode IN('insured')
           THEN
           30

        WHEN tllc.typecode IN('storm_Ext','hail','lightning_Ext','snowice','freeze_Ext') 
           THEN
           26  

        WHEN tllc.typecode IN('other_property_Ext','structfailure')
         AND tllpty.typecode IN('insured') 
         AND tlinc.typecode NOT IN('FixedPropertyIncident') 
           THEN
           29      

        WHEN tllc.typecode IN('theft_Ext')   
         AND tllpty.typecode IN('insured') 
           THEN
           28   

        WHEN tllc.typecode IN('vandalism')   
         AND tllpty.typecode IN('insured') 
           THEN
           31  

        WHEN tllc.typecode IN('waterdamage')  
           THEN
           27 

        WHEN  tlinc.typecode IN('InjuryIncident')  
         AND  tlet.typecode IN('BodilyInjuryDamage') 
         AND (tlpty.typecode IN ('PersonalAuto') 
          OR  tlpty.typecode IN('CA7CommAuto'))  
           THEN
           109  

        WHEN tlinc.typecode IN('InjuryIncident')  
         AND tlpty.typecode NOT LIKE '%Auto%'
         AND tllc.typecode NOT IN('habitability_Ext','professionalLiability_Ext','environmentalPollution_Ext')
           THEN
           36 

        WHEN  tlinc.typecode IN('PropertyContentsIncident', 'MobilePropertyIncident')
         AND  tlet.typecode IN('Content' ,'PersonalPropertyDamage','BusinessPP_Ext','PropertyDamage')
         AND  tllpty.typecode IN('insured')
         AND (tlpty.typecode IN ('HOPHomeowners') 
          OR  tlpty.typecode IN('DwellingFire_Ext') 
          OR  tlpty.typecode IN ('BusinessOwners')) 
           THEN
           101

           ELSE 
           141  
        END AS cause_of_loss_code,

      CASE 
        WHEN tllpty.typecode = 'insured'
        THEN '1st Party Property' 
        ELSE '3rd Party Casualty'
        END AS cause_group    
        
      FROM ccadmin.cc_claim@ecig_to_gwcc_prd_link                                clm
INNER JOIN ccadmin.cc_exposure@ecig_to_gwcc_prd_link                             exp 
        ON exp.claimid = clm.id 
       AND exp.retired = 0      
 LEFT JOIN ccadmin.cctl_losscause@ecig_to_gwcc_prd_link                          tllc 
        ON tllc.id = clm.losscause 
 LEFT JOIN (SELECT id, subtype, retired
            FROM ccadmin.cc_incident@ecig_to_gwcc_prd_link)                      inc 
        ON inc.id = exp.incidentid 
       AND inc.retired = 0
 LEFT JOIN ccadmin.cctl_incident@ecig_to_gwcc_prd_link                           tlinc 
        ON tlinc.id = inc.subtype 
 LEFT JOIN ccadmin.cctl_losspartytype@ecig_to_gwcc_prd_link                      tllpty 
        ON tllpty.id = exp.lossparty 
 LEFT JOIN ccadmin.cctl_exposuretype@ecig_to_gwcc_prd_link                       tlet 
        ON tlet.id = exp.exposuretype 
INNER JOIN ccadmin.cc_policy@ecig_to_gwcc_prd_link                               pol 
        ON pol.id = clm.policyid 
       AND pol.retired = 0
INNER JOIN ccadmin.cctl_policytype@ecig_to_gwcc_prd_link                         tlpty 
        ON tlpty.id = pol.policytype 
 LEFT JOIN ccadmin.cctl_coveragesubtype@ecig_to_gwcc_prd_link                    tlcovsty 
        ON tlcovsty.id = exp.coveragesubtype
 LEFT JOIN ccadmin.cctl_coveragetype@ecig_to_gwcc_prd_link                       tlcovty 
        ON tlcovty.id = exp.primarycoverage 
WHERE clm.retired = 0
;