--------------------------------------------------------
--  DDL for View VW_DAILY_CLAIM_CC
--------------------------------------------------------

CREATE OR REPLACE FORCE EDITIONABLE VIEW "DLAKEDEV"."VW_DAILY_CLAIM_CC" ("CLAIM" , "PLAINTIFF_FIRM" ,"CLAIM_NBR" ,"SIZE_OF_LOSS","DEC_POLICY" , 
	"CATASTROPHE" , "BRANCH" , "ATTORNEY" ,	"POLICY" ,	"UNIT_KEY" ,"DATE_OF_LOSS" , "CLAIM_STATUS" , "CLAIM_STATUS_DATE" ,	"STAFF" , 
	"CLAIM_DESC" , "LOCATION" , "CITY" , "STATE" , "COUNTY", "COUNTRY" ,"SUIT_TYPE" , "SUIT_REASON" ,"COURT" , "LAWSUIT_STATUS", 
	"LAWSUIT_STATUS_DATE" , "CUMIS_COUNCIL" , "RESOLUTION_METHOD" , "RESOLUTION_AMT" ,"REINS_REASON" ,	"REINS_REPORTED" , "REINS_BILL_STATUS" , 
	"REINS_TYPE" ,	"REINS_YEAR" , "DRIVER" , "AT_FAULT" , "DATE_LETTER_SENT_TO" ,"CREATE_ID", 	"FIRST_MODIFIED" , "AUDIT_ID" ,
    "LAST_MODIFIED" , 	"DEFENSE_FIRM" ,"OCCUR" , "PAF_LETTER" ,"PAF2" , "PAF_SENT" , "PAF_RESCINDED" ,	"NOT_OUR_VEHICLE" ,	"PARKED" , 
	"DRIVER_NOT_LISTED" , "PAF_REASON", "TABLE_NAME" ,	"DOING_BUSINESS_AS", 	"PERIL_TYPE" , 	"CLAIM_ASSIGNMENT_FLAG" , 	"CLAIM_TITLE" , 
    "RECOVERY_STRATEGY" , 	"CLOSING_DATE" , 	"BATCH_NUMBER" ,	"RENTALCAR_PICKUP_DT", 	"CLAIM_FOLDER", 	"FAULT_TYPE" , 	"VEHICLE_MOVEOUT_DT" , 
	"CURNIS_COUNCIL" , 	"CLAIM_PREFIX", 	"OFFER_REFER_NUMBER" , 	"ACCIDENT_FAULT", 	"SUITE" , 	"ZIP_CODE" , 	"RENTALCAR_AUTH_DT" , 
	"RESERVE_MEMO_STATUS" , 	"IDEMNITY_PORTION" , 	"PAF_EXCEPTION", 	"PAF", 	"ORIGINATE_DATE" , 	"INCOMING" , 	"SOURCE" , 	"ACP_NAME" , 
	"DEDUCTIBLE_AMOUNT", 	"CLAIM_EVENT_TIME" , 	"AUTORIZATION_LEVEL" , 	"VEHICLE_MOVEIN_DT",	"DUAL_COVERAGE" , 	"REASON", 	"UNIT_NBR" , 
	"OUTGOING_PAYMENTS" , 	"REJECT_CLAIM_COMMENTS" , 	"CLAIM_NUMBER" , 	"CALLCODE" , 	"ACCEPT_CLAIM" , 	"PAF2_LETTER" , 	"RENTALCAR_RETURN_DT" , 
	"PAF1_LETTER" , 	"SETTLEMENT_CURRENCY_SELECTION" , 	"CMS_ISO_POLICY_TYPE" , 	"LOCATION_CODE" , 	"CLAIM_REMARKS" , 
	"CAT_LOSS_DESC", 	"IS_RQY" , "CLAIM_SOURCE",	"LOAD_DATE" ) AS 
SELECT C.ID AS CLAIM,
       CASE WHEN  TLCRA.TYPECODE IN ('plaintifffirm', 'secplaintifffirm', 'independentLawfirm_Ext') THEN
                   TLCRA.ID        
                  END 
       AS PLAINTIFF_FIRM,
       C.CLAIMNUMBER AS CLAIM_NBR,
       'C' AS SIZE_OF_LOSS,
      DP.DEC_POLICY AS DEC_POLICY,
      CCAT.ID AS  CATASTROPHE,
      '' AS  BRANCH,
      TRIM(SUBSTR (CASE
            WHEN TLATCT.TYPECODE IN ('LawFirm')
              THEN  ATCT.name
            WHEN TLATCT.TYPECODE IN ('Attorney')
            THEN ATCT.lastname || ', ' || ATCT.firstname
        END          , 1, 78))  AS  ATTORNEY,
    P.ID AS POLICY,''
    AS  UNIT_KEY,
    C.LOSSDATE AS  DATE_OF_LOSS,
    TLCS.NAME AS  CLAIM_STATUS,
    C.UPDATETIME AS CLAIM_STATUS_DATE,'' AS  STAFF,C.Description AS  CLAIM_DESC,CA.ADDRESSLINE1 AS  LOCATION,
    CA.CITY AS CITY,TLS.TYPECODE  AS  STATE,CA.COUNTY AS  COUNTY,'USA' AS  COUNTRY,TLPC.NAME AS	SUIT_TYPE,'' AS SUIT_REASON,'' AS COURT,
    CASE WHEN CM.FINALSETTLEDATE IS NOT NULL
        Then 'Close'
        ELSE 'Open'
    END AS LAWSUIT_STATUS, 
	'' AS LAWSUIT_STATUS_DATE,'' AS CUMIS_COUNCIL,'' AS RESOLUTION_METHOD,'' AS RESOLUTION_AMT,'' AS REINS_REASON,'' AS REINS_REPORTED,
    '' AS REINS_BILL_STATUS,'' AS REINS_TYPE,'' AS REINS_YEAR,'' AS DRIVER,'' AS AT_FAULT,'' AS DATE_LETTER_SENT_TO,UUCR.USERNAME AS CREATE_ID,
    C.CREATETIME AS FIRST_MODIFIED,UUCR.USERNAME AS AUDIT_ID,C.UPDATETIME AS LAST_MODIFIED, 
    CASE WHEN TLCRA.TYPECODE IN ('defensefirm', 'secdefensefirm') THEN
                  TLCRA.ID        
     END AS DEFENSE_FIRM,
     '' AS OCCUR,'' AS PAF_LETTER,'' AS PAF2,'' AS PAF_SENT,'' AS PAF_RESCINDED,'' AS NOT_OUR_VEHICLE,'' AS PARKED,
    '' AS DRIVER_NOT_LISTED,'' AS PAF_REASON,'' AS TABLE_NAME,'' AS DOING_BUSINESS_AS,'' AS PERIL_TYPE,'' AS CLAIM_ASSIGNMENT_FLAG,
    '' AS LAIM_TITLE,'' AS RECOVERY_STRATEGY,'' AS CLOSING_DATE,'' AS BATCH_NUMBER, 
	'' AS RENTALCAR_PICKUP_DT,'' AS CLAIM_FOLDER,'' AS FAULT_TYPE,'' AS VEHICLE_MOVEOUT_DT,'' AS CURNIS_COUNCIL,'' AS CLAIM_PREFIX,
    '' AS OFFER_REFER_NUMBER,'' AS ACCIDENT_FAULT, 
	'' AS SUITE,CA.POSTALCODE AS ZIP_CODE,'' AS RENTALCAR_AUTH_DT,'' AS RESERVE_MEMO_STATUS,'' AS IDEMNITY_PORTION,'' AS PAF_EXCEPTION,'' AS PAF,
    '' AS ORIGINATE_DATE,'' AS INCOMING,'' AS SOURCE,'' AS ACP_NAME,'' AS DEDUCTIBLE_AMOUNT,'' AS CLAIM_EVENT_TIME,'' AS AUTORIZATION_LEVEL,
    '' AS VEHICLE_MOVEIN_DT,'' AS DUAL_COVERAGE,'' AS REASON, 
	'' AS UNIT_NBR,'' AS OUTGOING_PAYMENTS,'' AS REJECT_CLAIM_COMMENTS,'' AS CLAIM_NUMBER,'' AS CALLCODE,'' AS ACCEPT_CLAIM,
    '' AS PAF2_LETTER,'' AS RENTALCAR_RETURN_DT,'' AS PAF1_LETTER,'' AS SETTLEMENT_CURRENCY_SELECTION,'' AS CMS_ISO_POLICY_TYPE,
    '' AS LOCATION_CODE,'' AS CLAIM_REMARKS,'' AS CAT_LOSS_DESC,'' AS IS_RQY,'CC' AS CLAIM_SOURCE,SYSDATE AS LOAD_DATE
    FROM DLAKEDEV.DAILY_CC_CLAIM C
    INNER JOIN DLAKEDEV.daily_CC_MATTER CM ON C.ID = CM.CLAIMID AND CM.RETIRED = 0
    LEFT OUTER JOIN DLAKEDEV.daily_CCTL_MATTERTYPE TLMT ON CM.MATTERTYPE = TLMT.ID AND TLMT.RETIRED = 0
    LEFT OUTER JOIN DLAKEDEV.daily_CC_CLAIMCONTACTROLE CCTRIA ON CCTRIA.MATTERID = CM.ID AND CCTRIA.RETIRED = 0
    LEFT OUTER JOIN DLAKEDEV.daily_CCTL_CONTACTROLE TLCRA ON TLCRA.ID = CCTRIA.ROLE AND 
               TLCRA.TYPECODE IN('defensefirm', 'secdefensefirm','defenseattorney','secdefattorney','independentAttorney_Ext' ,
               'independentLawfirm_Ext','plaintifffirm', 'secplaintifffirm', 'plaintiffs', 'secplaintiffatt')
    INNER JOIN DLAKEDEV.daily_CC_POLICY P ON P.ID=C.POLICYID AND P.RETIRED=0
    LEFT OUTER JOIN DLAKEDEV.DAILY_DEC_POLICY DP ON DP.DEC_POLICY = P.DECPOLICY_EXT
    LEFT OUTER JOIN DLAKEDEV.PCVW_POLICYPERIOD PP ON PP.PERIOD_ID=P.PolicySystemPeriodID 
    LEFT OUTER JOIN DLAKEDEV.DAILY_CC_CATASTROPHE CCAT ON C.CATASTROPHEID = CCAT.ID AND CCAT.RETIRED = 0
    LEFT OUTER JOIN DLAKEDEV.daily_CC_CLAIMCONTACTROLE CCR ON CCR.MATTERID = CM.ID AND CCR.ACTIVE=1 AND CCR.RETIRED = 0 
    INNER JOIN DLAKEDEV.daily_CC_CLAIMCONTACT CC ON CC.ID = CCR.ClaimContactID AND CC.RETIRED=0
    INNER JOIN DLAKEDEV.daily_CC_CONTACT ATCT ON ATCT.ID = CC.CONTACTID AND ATCT.RETIRED=0
    INNER JOIN DLAKEDEV.daily_CCTL_CONTACT TLATCT ON TLATCT.ID = ATCT.SUBTYPE AND TLATCT.RETIRED=0 
    AND TLATCT.TYPECODE IN ('Attorney', 'LawFirm')
    LEFT OUTER JOIN DLAKEDEV.daily_CCTL_CLAIMSTATE TLCS ON TLCS.ID = C.STATE AND TLCS.RETIRED = 0
    LEFT OUTER JOIN DLAKEDEV.daily_CC_ADDRESS CA ON CA.ID = C.LOSSLOCATIONID AND CA.RETIRED = 0
    LEFT OUTER JOIN DLAKEDEV.daily_CCTL_STATE TLS ON TLS.ID = CA.STATE AND TLS.RETIRED = 0
    LEFT OUTER JOIN DLAKEDEV.daily_CCTL_PRIMARYCAUSETYPE TLPC ON TLPC.ID = CM.PrimaryCause   AND TLPC.RETIRED=0
    INNER JOIN DLAKEDEV.daily_CC_USER  UU ON CC.UPDATEUSERID = UU.ID AND UU.RETIRED = 0
    INNER JOIN DLAKEDEV.daily_CC_CREDENTIAL UUCR ON UUCR.ID = UU.CREDENTIALID AND UUCR.RETIRED = 0
    ;
    


