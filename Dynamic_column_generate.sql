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


CREATE OR REPLACE FUNCTION SPLIT_STRING (
  p_string IN VARCHAR2
) RETURN VARCHAR2 IS
  v_length CONSTANT NUMBER := 32767;
  v_result VARCHAR2(4000) := '';
  v_sub_str VARCHAR2(4000);
  v_pos NUMBER := 1;
BEGIN
  WHILE v_pos <= LENGTH(p_string) LOOP
    v_sub_str := REGEXP_SUBSTR(p_string, v_pos, v_length);
    v_result := v_result || v_sub_str || CHR(10); -- Add newline character to separate chunks
    v_pos := v_pos + v_length;
  END LOOP;
  RETURN v_result;
END SPLIT_STRING;
