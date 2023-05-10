create or replace FUNCTION CDACTABLESCRIPT(TAB_NAME IN VARCHAR2)
RETURN CLOB IS 
 columnList  CLOB;

BEGIN
  select 
 regexp_replace(rtrim(xmlagg(xmlelement(e,column_name || '  ' || data_type || 
               case when data_type like('%SDO_GEOMETRY%')  then 
                   ''||  ''
                   when data_type like('%CLOB%')  then 
                      ''||  '' 
                   when data_type NOT like('%TIMESTAMP%')  then 
                     '('|| data_length ||')' end  ,', ' || chr(10))
                     .extract('//text()') order by column_id).getclobval(),', '), ',([^,]*)$', '\1') 
     into columnList                
    from all_tab_columns@ECIG_TO_CC_LINK C
    where rownum <= 500 AND C.TABLE_NAME = 'CC_CONTACT' AND OWNER = 'CCADMIN02';
    return columnList;
END;