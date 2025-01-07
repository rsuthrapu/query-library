CREATE TABLE CLASS_CODE_DATA as             
    WITH CLASS_CODE_DATA AS(
                    SELECT
                    BP7CLASSCODE,
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