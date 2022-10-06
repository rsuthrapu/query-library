WITH    all_months    AS
(
    SELECT  ADD_MONTHS ( TRUNC ( DATE '2020-06-30', 'MONTH')
               , 1 - LEVEL
               ) AS START_DATE,
               ADD_MONTHS ( TRUNC ( DATE '2020-06-30', 'MONTH')
               , 2 - LEVEL
               ) AS END_DATE
    FROM    dual
    CONNECT BY  LEVEL <= 1 + MONTHS_BETWEEN ( DATE '2020-06-30'
                                    , DATE '2020-01-01' -- First date to add
                            )
)
    SELECT a.START_DATE, A.END_DATE
    FROM    all_months  a;