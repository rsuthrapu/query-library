CREATE TABLE whouse.STAGING_DW_PREM_DETAIL AS (
select * from DW_PREM_DETAIL 
WHERE EXTRACT(YEAR FROM TRANS_DATE) >= 2024 AND EXTRACT(MONTH FROM TRANS_DATE) >= 09 AND BUSINESS_LINE_NAME ='Business Owner');

ALTER TABLE whouse.STAGING_DW_PREM_DETAIL
ADD ORIGINAL_DEPT_NBR NUMBER(38,0);

create or replace FUNCTION WHOUSE.FN_STAGING_DEPT_DW_PREM_DETAIL (
    p_policynumber         IN VARCHAR2,
    p_policy_eff_date      IN DATE
) RETURN NUMBER IS
    v_dept_nbr NUMBER;
BEGIN

	 SELECT dept_nbr
			INTO v_dept_nbr
    FROM (
		SELECT
			d.dept_nbr
		FROM
			bop_class_codes                 bcc,
			bop_package_category            bpc,
			bop_package_type                bpt,
			param_values                    pv,
			policy_prefix                   pp,
			dept                            d,
			param_values                    pv2,
			class_code_data@ecig_to_pc_link cd
		WHERE
				pv.value = cd.bp7classcode
			AND cd.policynumber = p_policynumber
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
					policy_prefix
				WHERE
					prefix = (
						SELECT
							decode(instr(p_policynumber, 'SOP'), 1, 'SOP', 'BOP')
						FROM
							dual
					)
			)
			AND ROWNUM = 1
			AND bcc.effective_date <= trunc(to_timestamp(p_policy_eff_date, 'DD-MON-RR HH12:MI:SS.FF AM'))
			AND bcc.effective_date = (
				SELECT
					MAX(effective_date)
				FROM
					bop_class_codes bcc2
				WHERE
						bcc2.class_code_nbr = bcc.class_code_nbr
					AND bcc2.bop_package_category = bcc.bop_package_category
					AND bcc2.effective_date <= trunc(to_timestamp(p_policy_eff_date, 'DD-MON-RR HH12:MI:SS.FF AM'))
			)

		UNION ALL
		SELECT
				dp.dept_nbr
			FROM
				ecig_dept_details_temp                     dp
				INNER JOIN class_code_data@ecig_to_pc_link CD
				ON dp.classcode = cd.bp7classcode
				AND dp.effective_date <= trunc(TO_TIMESTAMP(p_policy_eff_date, 'DD-MON-RR HH12:MI:SS.FF AM'))
				AND ROWNUM = 1
		) WHERE ROWNUM = 1;

    RETURN v_dept_nbr;
END;



DECLARE
  CURSOR c_dept IS
      SELECT POLICY_NBR, TERM_EFFECTIVE_DATE,DW_PREM_DETAIL  FROM whouse.STAGING_DW_PREM_DETAIL;

  TYPE t_rows IS TABLE OF c_dept%ROWTYPE INDEX BY PLS_INTEGER;
  v_rows t_rows;

  v_batch_size NUMBER := 10000;
BEGIN
  OPEN c_dept;

  LOOP
    FETCH c_dept BULK COLLECT INTO v_rows LIMIT v_batch_size;
    EXIT WHEN v_rows.COUNT = 0;

    FORALL i IN 1..v_rows.COUNT
      UPDATE whouse.STAGING_DW_PREM_DETAIL
      SET ORIGINAL_DEPT_NBR = WHOUSE.FN_STAGING_DEPT_DW_PREM_DETAIL(POLICY_NBR,TRUNC(TERM_EFFECTIVE_DATE))
      WHERE DW_PREM_DETAIL = v_rows(i).DW_PREM_DETAIL;

    COMMIT;
  END LOOP;
  CLOSE c_dept;
END;