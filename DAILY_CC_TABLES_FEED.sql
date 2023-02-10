INSERT INTO DLAKEDEV.DAILY_CC_CATASTROPHE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_ADDRESS@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_CHECK
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_CATASTROPHE@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_CHECK
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_CHECK@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_CLAIM
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_CLAIM@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_CLAIMCONTACT 
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_CLAIMCONTACT@CIGDW_TO_CC_QA_LINK T 
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_CONTACT 
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_CONTACT@CIGDW_TO_CC_QA_LINK T 
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_CLAIMCONTACTROLE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_CLAIMCONTACTROLE@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_COVERAGE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_COVERAGE@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_EXPOSURE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_EXPOSURE@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_GROUP
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_GROUP@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_GROUPUSER
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_GROUPUSER@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CC_MATTER
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_MATTER@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_POLICY
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_POLICY@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_PROPERTYWATERDAMAGE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_PROPERTYWATERDAMAGE@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_RITRANSACTION
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_RITRANSACTION@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_SERVICEREQUEST
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_SERVICEREQUEST@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_TRANSACTION
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_TRANSACTION@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_TRANSACTIONLINEITEM
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_TRANSACTIONLINEITEM@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CC_USER
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CC_USER@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CCX_MIRREPORTABLE_ACC
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCX_MIRREPORTABLE_ACC@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

INSERT INTO DLAKEDEV.DAILY_CCX_POLICYDEPARTMENT_EXT
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCX_POLICYDEPARTMENT_EXT@CIGDW_TO_CC_QA_LINK T
WHERE TRUNC(UPDATETIME) > TRUNC(SYSDATE)-2 AND TRUNC(UPDATETIME) < TRUNC(SYSDATE);

--- TYPELIST - EXECUTE BASED ON NEED --


INSERT INTO DLAKEDEV.DAILY_CCTL_CLAIMSTATE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_CLAIMSTATE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_CONTACT
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_CONTACT@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_CONTACTROLE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_CONTACTROLE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_COSTCATEGORY
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_COSTCATEGORY@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_COSTTYPE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_COSTTYPE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_EXPOSURESTATE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_EXPOSURESTATE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_LEGALSPECIALTY
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_LEGALSPECIALTY@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_LOSSCAUSE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_LOSSCAUSE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_LOSTPROPERTYTYPE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_LOSTPROPERTYTYPE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_MATTERCOURTDISTRICT
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_MATTERCOURTDISTRICT@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_MATTERTYPE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_MATTERTYPE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_NAMESUFFIX
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_NAMESUFFIX@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_POLICYTYPE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_POLICYTYPE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_PRIMARYCAUSETYPE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_PRIMARYCAUSETYPE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_RECOVERYCATEGORY
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_RECOVERYCATEGORY@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_RESOLUTIONTYPE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_RESOLUTIONTYPE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_RITRANSACTION
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_RITRANSACTION@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_STATE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_STATE@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_TRANSACTION
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_TRANSACTION@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_TRANSACTIONSTATUS
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_TRANSACTIONSTATUS@CIGDW_TO_CC_QA_LINK T;

INSERT INTO DLAKEDEV.DAILY_CCTL_WATERSOURCE
SELECT T.* , TRUNC(SYSDATE)-1 AS LOAD_DATE, 'CC' AS CLAIM_SOURCE FROM CCTL_WATERSOURCE@CIGDW_TO_CC_QA_LINK T;
