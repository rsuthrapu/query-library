--Unused tables in Snowflake


-- Tables not being queried in last X days
with TablesRecent as
(
  select 
    f1.value:"objectName"::string as TN
  from SNOWFLAKE.ACCOUNT_USAGE.access_history
  , lateral flatten(base_objects_accessed) f1
  where
    f1.value:"objectDomain"::string='Table'
    and f1.value:"objectId" IS NOT NULL
    and query_start_time >= dateadd('day', -90, current_timestamp())
  group by 1
),

TablesAll as
(
  SELECT
    TABLE_ID::integer as TID, 
    TABLE_CATALOG || '.' || TABLE_SCHEMA || '.' || TABLE_NAME AS TN1  
  FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES 
  WHERE DELETED IS NULL
)

SELECT * FROM TablesAll 
  WHERE 