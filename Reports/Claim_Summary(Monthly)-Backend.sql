-- FINANCIAL DATA
WITH MAX_CLAIMDETAIL AS
(
    SELECT    MAXCLAIM.CLAIM_KEY,
              MAXCLAIM.DW_CLAIMANT_DETAIL,
              DETAIL.STAFF_ADJUSTER,
              DETAIL.Adjuster_Supervisor,
              DETAIL.Independent_Adjuster       
    from      (
                  SELECT    CLAIM_KEY,
                            MAX(DW_CLAIMANT_DETAIL) as DW_CLAIMANT_DETAIL
                  FROM      whouse.DW_CLAIMANT_DETAIL
                  GROUP  BY CLAIM_KEY
              ) MAXCLAIM
    left JOIN  	whouse.DW_CLAIMANT_DETAIL DETAIL
    ON          DETAIL.DW_CLAIMANT_DETAIL = MAXCLAIM.DW_CLAIMANT_DETAIL
)

,DISTINCT_CLAIMKEY AS
(
    SELECT    DISTINCT SUB.CLAIM_KEY 
    FROM      whouse.DW_CLAIMANT_DETAIL SUB 
    WHERE     EXTRACT(YEAR FROM sub.Trans_Date) >= EXTRACT(YEAR FROM SYSDATE) - 2
)

,DISTINCT_CLAIMANTKEY AS
(
    SELECT    DISTINCT SUB.Claimant_Key 
    FROM      whouse.DW_CLAIMANT_DETAIL SUB 
    WHERE     EXTRACT(YEAR FROM sub.Trans_Date) >= EXTRACT(YEAR FROM SYSDATE) - 2
)


SELECT   dwc.Claim_Nbr
        ,dwct.Policy_Nbr
        ,dwct.Insured_Name
        ,DWC.CLAIM_STATUS
        ,CASE WHEN dwc.Claim_Status = 'Closed'
              THEN dwc.Claim_Status_Date
              ELSE NULL
        END AS "Close_Date"
        ,dwct.Date_of_Loss
        ,dwcd.Business_Line_Name
        ,dwcd.Dept_Desc
        ,dwc.Claim_Status_Date AS "Claim_Reported"  
        ,NVL(c.Is_RQY,0) AS "RQY_Flag"
        ,NVL(dwct.CAT_NBR,'N/A') AS "CAT_Number"
        ,NVL(DWCT.CAT_DESC,'Non-CAT') AS "CAT_Description"
        
        ,maxdet.STAFF_ADJUSTER AS "Current_CIG_Adjustor"
        ,MAXDET.ADJUSTER_SUPERVISOR AS "Current_CIG_Supervisor"
        ,maxdet.Independent_Adjuster AS "Current_Independent_Adjustor"   
        ,CASE WHEN DWCT.lawsuit_status IS NULL
              THEN 'N'
              ELSE 'Y'
        END AS "Litigation_Flag"
        ,DWCD.TRANS_DATE AS "Transaction_Date"
        ,CASE WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage')
              THEN 0
              ELSE NVL(dwcd.Loss_Reserve,0)
        END AS "Incurred_Loss"
        ,CASE WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage')
              THEN 0
              ELSE NVL(dwcd.Loss_Paid,0)
        END AS "Paid_Loss"
        ,CASE WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage')
              THEN 0
              ELSE NVL(dwcd.Loss_Reserve,0)-NVL(dwcd.Loss_Paid,0)
        END AS "Loss_Reserve_Change"
        ,CASE WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage')
              THEN 0
              ELSE NVL(dwcd.Alloc_Expense_Reserve,0)
        END AS "DCC_Incurred"
        ,CASE WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage')
              THEN 0
              ELSE NVL(dwcd.Alloc_Expense_Paid,0)
        END AS "DCC_Paid"
        ,CASE WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage')
              THEN 0
              ELSE NVL(dwcd.Alloc_Expense_Reserve,0)-NVL(dwcd.Alloc_Expense_Paid,0)
        END AS "DCC_Reserve_Change"
        ,CASE WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage')
              THEN 0
              ELSE NVL(dwcd.Unalloc_Expense_Reserve,0)
        END AS "AO_Incurred"
        ,CASE WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage')
              THEN 0
              ELSE NVL(dwcd.Unalloc_Expense_Paid,0)
        END AS "AO_Paid"
        ,CASE WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage')
              THEN 0
              ELSE NVL(dwcd.Unalloc_Expense_Reserve,0)-NVL(dwcd.Unalloc_Expense_Paid,0)
        END AS "AO_Reserve_Change"
        ,CASE WHEN dwcd.Trans_Type ='Credit Subro'
              THEN -1*NVL(dwcd.Loss_Paid,0)
              ELSE 0
         END AS "Loss_Subro"
        ,CASE WHEN dwcd.Trans_Type ='Credit Salvage'
              THEN -1*NVL(dwcd.Loss_Paid,0)
              ELSE 0
        END AS "Loss_Salvage"
        ,CASE WHEN dwcd.Trans_Type ='Credit Subro'
              THEN -1*NVL(dwcd.Alloc_Expense_Paid,0)
              ELSE 0
        END AS "DCC_Subro"
        ,CASE WHEN dwcd.Trans_Type ='Credit Salvage'
              THEN -1*NVL(dwcd.Alloc_Expense_Paid,0)
              ELSE 0
        END AS "DCC_Salvage"
        ,CASE WHEN dwcd.Trans_Type ='Credit Subro'
              THEN -1*NVL(dwcd.Unalloc_Expense_Paid,0)
              ELSE 0
        END AS "AO_Subro"
        ,CASE WHEN dwcd.Trans_Type ='Credit Salvage'
              THEN -1*NVL(dwcd.Unalloc_Expense_Paid,0)
              ELSE 0
        END AS "AO_Salvage"
        ,DWC.source
FROM    whouse.DW_CLAIMANT DWCT
LEFT JOIN    MAX_CLAIMDETAIL MAXDET
ON           MAXDET.CLAIM_KEY = DWCT.CLAIM_KEY
JOIN    whouse.DW_CLAIMANT_DETAIL DWCD ON DWCD.CLAIMANT_KEY = DWCT.CLAIMANT_KEY AND     DWCD.CLAIM_KEY = DWCT.CLAIM_KEY
JOIN    whouse.DW_CLAIM DWC ON      DWC.CLAIM_KEY = DWCD.CLAIM_KEY
JOIN    cigadmin.CLAIM C ON      c.Claim = dwct.Claim_Key and dwct.source = 'CMS'
--LEFT JOIN cigadmin.CMS_LEGAL_ACTION LA ON        LA.CLAIM = DWCT.CLAIM_KEY

WHERE   ( ( DWCD.CLAIM_KEY IN (SELECT * FROM DISTINCT_CLAIMKEY) 
              AND DWCD.CLAIMANT_KEY IN (SELECT * FROM DISTINCT_CLAIMANTKEY))
          OR DWC.CLAIM_STATUS IN ('Open','ReOpen'))
AND     TRUNC(DWCD.TRANS_DATE) <= LAST_DAY(ADD_MONTHS(SYSDATE,-1))
  
ORDER BY  dwcd.Trans_Date DESC
          ,dwct.Date_of_Loss ASC
          ,dwc.Claim_Nbr ASC

;



-- OPEN CLOSE DATA
WITH MAX_CLAIMDETAIL AS
(
    SELECT    MAXCLAIM.CLAIM_KEY,
              MAXCLAIM.DW_CLAIMANT_DETAIL,
              DETAIL.STAFF_ADJUSTER,
              DETAIL.Adjuster_Supervisor,
              DETAIL.Independent_Adjuster       
    from      (
                  SELECT    CLAIM_KEY,
                            MAX(DW_CLAIMANT_DETAIL) AS DW_CLAIMANT_DETAIL
                  FROM      whouse.DW_CLAIMANT_DETAIL
                  GROUP  BY CLAIM_KEY
              ) MAXCLAIM
    left JOIN  whouse.DW_CLAIMANT_DETAIL DETAIL
    on          DETAIL.DW_CLAIMANT_DETAIL = maxclaim.DW_CLAIMANT_DETAIL
),

financials as (
select dwct.CLAIM_KEY
,sum(CASE 
  WHEN dwcd.Trans_Type ='Credit Subro' THEN -1*NVL(dwcd.Loss_Paid,0)
  ELSE 0
END) AS Loss_Subro
,sum(CASE 
  WHEN dwcd.Trans_Type ='Credit Salvage' THEN -1*NVL(dwcd.Loss_Paid,0)
  ELSE 0
END) AS Loss_Salvage
,sum(CASE 
  WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage') THEN 0
  ELSE NVL(dwcd.Alloc_Expense_Paid,0)
END) AS DCC_Paid
,sum(CASE 
  WHEN dwcd.Trans_Type IN ('Credit Subro','Credit Salvage') THEN 0
  ELSE NVL(dwcd.Unalloc_Expense_Paid,0)
END) AS AO_Paid
from whouse.dw_claimant_detail dwcd
inner join whouse.DW_Claimant dwct on dwcd.CLAIMANT_KEY = dwct.CLAIMANT_KEY
inner join whouse.DW_Claim dwc ON dwc.Claim_Key = dwct.Claim_Key
WHERE EXTRACT(YEAR FROM dwc.Claim_Status_Date) >= (EXTRACT(YEAR FROM SYSDATE) - 2)
  OR dwc.Claim_Status IN ('Open','ReOpen')
group by dwct.CLAIM_KEY
)

SELECT  DISTINCT dwc.Claim_Nbr
,dwct.Policy_Nbr
,dwct.Insured_Name
,dwc.Claim_Status
,CASE 
  WHEN dwc.Claim_Status = 'Closed' THEN dwc.Claim_Status_Date
  ELSE NULL
END AS "Close_Date"
,dwct.Date_of_Loss
,dwc.Claim_Status_Date AS "Claim_Reported" 
,NVL(c.Is_RQY,0) AS "RQY_Flag"
,NVL(dwct.CAT_NBR,'N/A') AS "CAT_Number"
,NVL(DWCT.CAT_DESC,'Non-CAT') AS "CAT_Description"
,maxdet.STAFF_ADJUSTER AS "Current_CIG_Adjustor"
,MAXDET.ADJUSTER_SUPERVISOR AS "Current_CIG_Supervisor"
,maxdet.Independent_Adjuster AS "Current_Independent_Adjustor"   
,CASE 
  WHEN DWCT.lawsuit_status IS NULL THEN 'N'
  ELSE 'Y'
END AS "Litigation_Flag"
,Loss_Subro as Subro_Recovery
,Loss_Salvage as Salvage_Recovery
,DCC_Paid
,AO_Paid
,DWC.source
FROM whouse.DW_CLAIMANT DWCT
left join MAX_CLAIMDETAIL MAXDET ON MAXDET.CLAIM_KEY = DWCT.CLAIM_KEY
JOIN whouse.DW_CLAIM DWC ON DWC.CLAIM_KEY = DWCT.CLAIM_KEY
JOIN cigadmin.CLAIM C ON C.CLAIM = DWCT.CLAIM_KEY and DWCT.source = 'CMS'
--LEFT JOIN cigadmin.CMS_LEGAL_ACTION LA ON la.Claim = dwct.Claim_Key
left join financials f on DWCT.CLAIM_KEY = f.CLAIM_KEY
WHERE EXTRACT(YEAR FROM DWC.CLAIM_STATUS_DATE) >= (EXTRACT(YEAR FROM SYSDATE) - 2)
  OR dwc.Claim_Status IN ('Open','ReOpen')
ORDER BY dwct.Date_of_Loss ASC
  ,dwc.Claim_Nbr ASC
;