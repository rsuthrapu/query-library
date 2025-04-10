CREATE TABLE CLASS_CODE_DATA as             
            WITH CLASS_CODE_DATA AS(
                    SELECT
                    BP7CLASSCODE,
                    C.BRANCHID,
                    PP.POLICYNUMBER,
                    ROW_NUMBER() OVER(PARTITION BY C.BRANCHID, C.BUILDING
                                                    ORDER BY C.BUILDING, C.BP7CLASSCODE) AS BUILDING_ROWNUM
                    FROM  PCADMIN.PCX_BP7CLASSIFICATION C
                    INNER JOIN PCADMIN.PC_POLICYPERIOD PP
                    ON PP.ID=C.BRANCHID 
                    ),
                    CLASS_CODE_RECORD AS(
                        SELECT * FROM CLASS_CODE_DATA WHERE  BUILDING_ROWNUM < 2
                    )
                    select * from CLASS_CODE_RECORD;

CREATE INDEX BP7CLASSCODE_INDX ON CLASS_CODE_DATA(BP7CLASSCODE) TABLESPACE "PCDATA";
CREATE INDEX POLICYNUMBER_INDX ON CLASS_CODE_DATA(POLICYNUMBER) TABLESPACE "PCDATA" ;
CREATE INDEX BRANCHID_INDX ON CLASS_CODE_DATA(BRANCHID) TABLESPACE "PCDATA";