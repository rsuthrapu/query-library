create or replace FUNCTION GetTableScript(TAB_NAME IN VARCHAR2)
RETURN CLOB IS 
 columnList  CLOB;
BEGIN
  select 
    regexp_replace(rtrim(xmlagg(xmlelement(e,column_name || '  ' || data_type || 
               case when data_type not like('%TIMESTAMP%') then 
                     '('|| data_length ||')' end ,', '|| chr(10))
                     .extract('//text()') order by column_name).getclobval(),', '), ',([^,]*)$', '\1') str
    into columnList
    from all_tab_columns@ECIG_TO_CC_LINK C
    where rownum <= 500 AND C.TABLE_NAME = TAB_NAME AND OWNER = 'CCADMIN02';
    return columnList;
END;