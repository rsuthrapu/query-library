SELECT a.session_id, a.oracle_username, a.os_user_name, b.owner, b.object_name, b.object_type
FROM v$locked_object a JOIN dba_objects b ON a.object_id = b.object_id;

SELECT SID, SERIAL# FROM V$SESSION WHERE SID IN (
    SELECT SESSION_ID FROM DBA_DML_LOCKS WHERE SESSION_ID = 644
);

ALTER SYSTEM KILL SESSION '644, 46106';