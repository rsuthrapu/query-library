create or replace FUNCTION        stg_dept_details (
    v_policy_number         IN VARCHAR2,
    v_term_effective_date      IN DATE,
    v_classification_code IN VARCHAR2
) RETURN NUMBER IS
    v_dept_nbr NUMBER;
BEGIN

	 SELECT dept_nbr
			INTO v_dept_nbr
    FROM (
		SELECT
                                d.dept_nbr                                
                            FROM
                                bop_class_codes@PROD_ANALYTICS_LINK_USER      bcc,
                                bop_package_category@PROD_ANALYTICS_LINK_USER bpc,
                                bop_package_type@PROD_ANALYTICS_LINK_USER     bpt,
                                param_values@PROD_ANALYTICS_LINK_USER         pv,
                                policy_prefix@PROD_ANALYTICS_LINK_USER        pp,
                                dept@PROD_ANALYTICS_LINK_USER                 d,
                                param_values@PROD_ANALYTICS_LINK_USER         pv2,
								pcadmin.class_code_data@gw_prd_link cd
                            WHERE
                                    pv.value = cd.bp7classcode
                                AND cd.policynumber =  v_policy_number   
                                AND bcc.bop_package_category = bpc.bop_package_category
                                AND bpc.bop_package_type = bpt.bop_package_type
                                AND bcc.class_code_nbr = pv.param_values
                                AND bpt.type = pv2.param_values
                                AND bpc.dept = d.dept
                                AND d.major_line = pp.major_line
                                 AND pp.policy_prefix IN (
                                        SELECT
                                            policy_prefix
                                        FROM
                                            policy_prefix@PROD_ANALYTICS_LINK_USER
                                        WHERE
                                            prefix = (
                                                SELECT
                                                    decode(instr(v_policy_number, 'SOP'), 1, 'SOP', 'BOP')
                                                FROM
                                                    dual
                                            )
                                    )
                                AND ROWNUM = 1
                                AND bcc.effective_date <= v_term_effective_date
                                AND bcc.effective_date = (
                                    SELECT
                                        MAX(effective_date)
                                    FROM
                                        bop_class_codes@PROD_ANALYTICS_LINK_USER bcc2
                                    WHERE
                                            bcc2.class_code_nbr = bcc.class_code_nbr
                                        AND bcc2.bop_package_category = bcc.bop_package_category
                                        AND bcc2.effective_date <= v_term_effective_date
			)

		UNION ALL
       SELECT
                                dept_nbr
                            FROM
                                "ecig_dept_details_temp"
                            WHERE
                                    classcode = TO_NUMBER(v_classification_code)
                                AND effective_date <= v_term_effective_date
                                AND ROWNUM = 1
		) WHERE ROWNUM = 1;
    RETURN v_dept_nbr;
END;



CREATE GLOBAL TEMPORARY TABLE TEMP_DEPT_INFO (
    DW_PREM_DETAIL VARCHAR2(255),  -- Adjust data types as needed
    PC_POLICY_TRANSACTIONS VARCHAR2(255),
    PTPOLICYNUMBER VARCHAR2(255),
    PREMPOLICYNUMBER VARCHAR2(255),
    DEPT_NBR VARCHAR2(255),
    DEPT_DESC VARCHAR2(255),
    CLASSIFICATION_CODE VARCHAR2(255),
    POLICYTERMEFFETIVE DATE,
    LINE_NBR NUMBER,
    PREMTREMEFFECTIVE DATE,
    ORIGINAL_DEPT_NBR VARCHAR2(255)
) ON COMMIT PRESERVE ROWS; 


INSERT INTO TEMP_DEPT_INFO
WITH dept_info AS (
    SELECT /* MATERIALIZED */
            DWP.DW_PREM_DETAIL,
    PT.PC_POLICY_TRANSACTIONS,
    PT.POLICY_NUMBER AS PTPOLICYNUMBER,
    DWP.POLICY_NBR AS PREMPOLICYNUMBER,
    DWP.DEPT_NBR,
    DWP.DEPT_DESC,
    PT.CLASSIFICATION_CODE,
    PT.TERM_EFFECTIVE_DATE AS POLICYTERMEFFETIVE,
    DWP.LINE_NBR,
    DWP.TERM_EFFECTIVE_DATE AS PREMTREMEFFECTIVE,
    STG_DEPT_DETAILS(
      DWP.POLICY_NBR,
      TO_DATE(DWP.TERM_EFFECTIVE_DATE),
      PT.CLASSIFICATION_CODE
      ) AS ORIGINAL_DEPT_NBR 
    FROM
    DW_PREM_DETAIL@PROD_ANALYTICS_LINK_USER  DWP
    INNER JOIN pc_policy_transactions@PROD_ANALYTICS_LINK_USER PT ON PT.POLICY_NUMBER = DWP.POLICY_NBR
    AND DWP.LINE_NBR = PT.COV_LINE_NUMBER
    AND TRUNC (DWP.TRANS_DATE) = TRUNC (PT.TRANS_DATE)
    WHERE EXTRACT(YEAR FROM DWP.TRANS_DATE) >= 2024 AND EXTRACT(MONTH FROM DWP.TRANS_DATE) >= 09
    AND DWP.BUSINESS_LINE_NAME ='Business Owner'
)
SELECT DISTINCT * FROM dept_info;
COMMIT; 


CREATE TABLE STAGING_DEPT_DETAILS AS
SELECT * FROM TEMP_DEPT_INFO;

COMMIT;