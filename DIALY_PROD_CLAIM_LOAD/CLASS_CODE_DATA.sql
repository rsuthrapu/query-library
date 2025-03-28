CREATE TABLE CLASS_CODE_DATA as             
    WITH CLASS_CODE_DATA AS(
                    SELECT
                    BP7CLASSCODE,
                    PP.POLICYNUMBER,
                    C.BRANCHID,
                    ROW_NUMBER() OVER(PARTITION BY C.BRANCHID, C.BUILDING
                                                    ORDER BY C.BUILDING, C.BP7CLASSCODE) AS BUILDING_ROWNUM
                    FROM  PCX_BP7CLASSIFICATION C
                    INNER JOIN PC_POLICYPERIOD PP
                    ON PP.ID=C.BRANCHID 
                    ),
                    CLASS_CODE_RECORD AS(
                        SELECT * FROM CLASS_CODE_DATA
                        WHERE  BUILDING_ROWNUM < 2
                    )
    SELECT * FROM CLASS_CODE_RECORD;


DECLARE ROW_COUNT INTEGER;
BEGIN
SELECT
  COUNT(*) INTO ROW_COUNT
FROM
  ALL_TABLES
WHERE
  TABLE_NAME = 'CLASS_CODE_DATA'
  AND OWNER = 'PCADMIN';
IF ROW_COUNT = 1 THEN EXECUTE IMMEDIATE 'DROP TABLE CLASS_CODE_DATA';
END IF;
EXECUTE IMMEDIATE '
  CREATE TABLE CLASS_CODE_DATA as
            WITH CLASS_CODE_DATA AS(
                    SELECT
                    BP7CLASSCODE,
                    PP.POLICYNUMBER,
                    C.BRANCHID,
                    ROW_NUMBER() OVER(PARTITION BY C.BRANCHID, C.BUILDING
                                                    ORDER BY C.BUILDING, C.BP7CLASSCODE) AS BUILDING_ROWNUM
                    FROM  PCX_BP7CLASSIFICATION C
                    INNER JOIN PC_POLICYPERIOD PP
                    ON PP.ID=C.BRANCHID
                    ),
                    CLASS_CODE_RECORD AS(
                        SELECT DISTINCT *  FROM CLASS_CODE_DATA
                        WHERE  BUILDING_ROWNUM < 2
                    )
                    select * from CLASS_CODE_RECORD';
END;