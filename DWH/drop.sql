BEGIN
  FOR rec IN
    (
      SELECT
        table_name
      FROM
        all_tables
      WHERE
        table_name LIKE '%DAILY%' --'CCST_DW%'
    )
  LOOP
    EXECUTE immediate 'DROP TABLE  '||rec.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
END;
---------------------------------------------------------------------------------------------------------------------------------

BEGIN
  FOR rec IN
    (
      SELECT
        view_name
      FROM
        all_views
      WHERE
        view_name LIKE '%VW_%' and owner = 'DMSADMIN01'
    )
  LOOP
    EXECUTE immediate 'DROP VIEW  '||rec.view_name || ' CASCADE CONSTRAINTS';
  END LOOP;
END; 