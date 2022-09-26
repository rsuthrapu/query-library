WITH
    FUNCTION START_OF_YEAR (
            P_DATE IN DATE
            , P_GWPC  VARCHAR2  DEFAULT NULL
            )RETURN DATE DETERMINISTIC
            IS
            BEGIN
                RETURN CASE WHEN P_GWPC ='PC' THEN
                     TRUNC (P_DATE, 'YEAR') + INTERVAL '1' MINUTE
                ELSE 
                    TRUNC (P_DATE, 'YEAR')
                END;
            END;
     FUNCTION LAST_DAY_OF_YEAR (
            P_DATE IN DATE
            )RETURN DATE DETERMINISTIC
            IS
            BEGIN
                RETURN  ADD_MONTHS (TRUNC (P_DATE, 'YEAR'), 12) - 1 + INTERVAL '1' DAY - INTERVAL '1' SECOND;
                -- THIS WOULD CHANGE FOR GW X CENTERS especially PC, as the time period starts around 00:01:00
            END;
      FUNCTION NEXT_MONTH (
            P_DATE IN DATE
            )RETURN DATE DETERMINISTIC
            IS
            BEGIN
                RETURN  ADD_MONTHS (TRUNC (P_DATE, 'MONTH'), 1);
                -- THIS WOULD CHANGE FOR GW X CENTERS especially PC, as the time period starts around 00:01:00
            END;
      FUNCTION PREVIOUS_MONTH (
        P_DATE IN DATE
        )RETURN DATE DETERMINISTIC
        IS
        BEGIN
            RETURN  ADD_MONTHS (TRUNC (P_DATE, 'MONTH'), -1);
            -- THIS WOULD CHANGE FOR GW X CENTERS especially PC, as the time period starts around 00:01:00
        END;
     FUNCTION NEAREST_WEEK (
        P_DATE IN DATE
        )RETURN DATE DETERMINISTIC
        IS
        BEGIN
            RETURN  TRUNC (P_DATE, 'ww');
            -- THIS WOULD CHANGE FOR GW X CENTERS especially PC, as the time period starts around 00:01:00
        END;
    FUNCTION START_WEEK (
        P_DATE IN DATE
        )RETURN DATE DETERMINISTIC
        IS
        BEGIN
            RETURN  TRUNC (P_DATE, 'iw');
            -- THIS WOULD CHANGE FOR GW X CENTERS especially PC, as the time period starts around 00:01:00
        END;
     FUNCTION START_OF_MONTH (
        P_DATE IN DATE
        )RETURN DATE DETERMINISTIC
        IS
        BEGIN
            RETURN  TRUNC (P_DATE, 'mm');
            -- THIS WOULD CHANGE FOR GW X CENTERS especially PC, as the time period starts around 00:01:00
        END;
SAMPLE_DATE AS (
SELECT SYSDATE AS TESTDATE FROM DUAL
)
SELECT
     START_OF_YEAR(TESTDATE, 'PC')
    , START_OF_YEAR(TESTDATE)
    , LAST_DAY_OF_YEAR (TESTDATE)
    , PREVIOUS_MONTH(TESTDATE)
    , NEXT_MONTH(TESTDATE)
    , NEAREST_WEEK(TESTDATE)
    , START_WEEK(TESTDATE)
    , START_OF_MONTH(TESTDATE)
    , LAST_DAY(TRUNC(TESTDATE)) + INTERVAL '1' DAY - INTERVAL '1' SECOND
    , TESTDATE 
FROM SAMPLE_DATE
;