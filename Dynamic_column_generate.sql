create or replace FUNCTION GetTableScript(TAB_NAME IN VARCHAR2)
RETURN CLOB IS 
 columnList  CLOB;
BEGIN
        select 
        rtrim(xmlagg(xmlelement(e,column_name || '  ' || data_type || 
                   '('|| data_length||')',', ').extract('//text()') order by column_name).getclobval(),', ') str
        into columnList
        from all_tab_columns@ECIG_TO_CC_LINK C
        where rownum <= 500 AND C.TABLE_NAME = TAB_NAME;
    return columnList;
END;