SET SERVEROUTPUT ON;
DECLARE
  CURSOR policy_cursor IS
    WITH dept_bop_claims AS (
      SELECT
        dc.claim_nbr,
        p.id AS policyid,
        p.policynumber,
        dl.business_line_name,
        dl.dept_nbr,
        dl.dept_desc,
        p.policysystemperiodid,
        p.effectivedate
      FROM
        dw_claimant_detail dl,
        dw_claimant dc
        LEFT JOIN ccadmin.cc_claim@gw_prd_link c ON c.claimnumber = dc.claim_nbr
        LEFT JOIN ccadmin.cc_policy@gw_prd_link p ON c.policyid = p.id
      WHERE
        dl.claimant_key = dc.CLAIMANT_KEY
        AND dl.source = dc.source
        AND dl.source = 'CC'
        AND dept_nbr = 27
        and dc.claim_nbr = 2013417
      GROUP BY
        dc.claim_nbr,
        p.id,
        p.policynumber,
        p.id,
        dl.business_line_name,
        dl.dept_nbr,
        dl.dept_desc,
        p.policysystemperiodid,
        p.effectivedate
    )
    SELECT *
    FROM dept_bop_claims dbc;

  rec_policy policy_cursor%ROWTYPE;
  v_new_dept_nbr NUMBER; -- Declare a variable to store the result

BEGIN
  OPEN policy_cursor;

  LOOP
    FETCH policy_cursor INTO rec_policy;
    EXIT WHEN policy_cursor%NOTFOUND;

    -- Store the result of the SELECT into the variable
    SELECT
      whouse.get_dept_by_ppid(rec_policy.policynumber, rec_policy.effectivedate, rec_policy.policysystemperiodid)
    INTO v_new_dept_nbr
    FROM dual;

   -- Print all the desired values
    DBMS_OUTPUT.PUT_LINE(
      'Claim Nbr: ' || rec_policy.claim_nbr ||
      ', Policy ID: ' || rec_policy.policyid ||
      ', Policy Number: ' || rec_policy.policynumber ||
      ', Business Line: ' || rec_policy.business_line_name ||
      ', Dept Nbr: ' || rec_policy.dept_nbr ||
      ', Dept Desc: ' || rec_policy.dept_desc ||
      ', Policy Period ID: ' || rec_policy.policysystemperiodid ||
      ', Effective Date: ' || TO_CHAR(rec_policy.effectivedate, 'YYYY-MM-DD HH24:MI:SS') ||
      ', New Dept Nbr: ' || v_new_dept_nbr
    );

  END LOOP;

  CLOSE policy_cursor;
END;

---------------------------TABLE ---------------------------------


CREATE TABLE whouse.dept_bop_claims_with_new_dept (
    claim_nbr VARCHAR2(255),  
    policyid NUMBER,
    policynumber VARCHAR2(255), 
    business_line_name VARCHAR2(255), 
    dept_nbr NUMBER,
    dept_desc VARCHAR2(255), 
    policysystemperiodid NUMBER,
    effectivedate DATE,
    new_dept_nbr NUMBER
);

DECLARE
    CURSOR policy_cursor IS
        WITH dept_bop_claims AS (
            SELECT
                dc.claim_nbr,
                p.id AS policyid,
                p.policynumber,
                dl.business_line_name,
                dl.dept_nbr,
                dl.dept_desc,
                p.policysystemperiodid,
                p.effectivedate
            FROM
                dw_claimant_detail dl,
                dw_claimant dc
                LEFT JOIN ccadmin.cc_claim@gw_prd_link c ON c.claimnumber = dc.claim_nbr
                LEFT JOIN ccadmin.cc_policy@gw_prd_link p ON c.policyid = p.id
            WHERE
                dl.claimant_key = dc.CLAIMANT_KEY
                AND dl.source = dc.source
                AND dl.source = 'CC'
                AND dept_nbr = 27
            GROUP BY
                dc.claim_nbr,
                p.id,
                p.policynumber,
                p.id,
                dl.business_line_name,
                dl.dept_nbr,
                dl.dept_desc,
                p.policysystemperiodid,
                p.effectivedate
        )
        SELECT *
        FROM dept_bop_claims dbc;

    rec_policy policy_cursor%ROWTYPE;
    v_new_dept_nbr NUMBER;

BEGIN
    OPEN policy_cursor;

    LOOP
        FETCH policy_cursor INTO rec_policy;
        EXIT WHEN policy_cursor%NOTFOUND;

        SELECT
            whouse.get_dept_by_ppid(rec_policy.policynumber, rec_policy.effectivedate, rec_policy.policysystemperiodid)
        INTO v_new_dept_nbr
        FROM dual;

        -- Insert the data into the table
        INSERT INTO whouse.dept_bop_claims_with_new_dept (
            claim_nbr,
            policyid,
            policynumber,
            business_line_name,
            dept_nbr,
            dept_desc,
            policysystemperiodid,
            effectivedate,
            new_dept_nbr
        ) VALUES (
            rec_policy.claim_nbr,
            rec_policy.policyid,
            rec_policy.policynumber,
            rec_policy.business_line_name,
            rec_policy.dept_nbr,
            rec_policy.dept_desc,
            rec_policy.policysystemperiodid,
            rec_policy.effectivedate,
            v_new_dept_nbr
        );

    END LOOP;

    CLOSE policy_cursor;
    COMMIT; 
END;
