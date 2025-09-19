CREATE OR REPLACE PROCEDURE billing_pe_stg.etl_ctrl.sp_truncate_tables_in_schemas(
    db_name STRING,                 -- e.g. 'EDW_PROD'
    schema_name STRING,             -- e.g. 'DWH,STAGING'
    dry_run BOOLEAN,                -- TRUE = list only; FALSE = execute
    exclude_tables VARIANT          -- e.g. PARSE_JSON('["AUDIT_LOG","KEEP_THIS"]') or NULL
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
/* NOTE: Snowflake uppercases param identifiers. Use DB_NAME, SCHEMA_NAME, etc. */
const db = (DB_NAME || '').trim();
if (!db) throw "db_name cannot be empty.";

const schemas = ((SCHEMA_NAME || '') + '')
  .split(',')
  .map(s => s.trim())
  .filter(s => s.length > 0);
if (schemas.length === 0) throw "schema_name must contain at least one schema.";

const excludeRaw = EXCLUDE_TABLES;   // VARIANT -> JS value (array/null/etc.)
const excludes = Array.isArray(excludeRaw)
  ? excludeRaw.map(x => ("" + x).toUpperCase())
  : [];

const actions = [];

for (const schema of schemas) {
  const sql = `
    SELECT table_name
    FROM ${db}.information_schema.tables
    WHERE table_schema = :1
      AND table_type = 'BASE TABLE'
  `;
  const stmt = snowflake.createStatement({ sqlText: sql, binds: [schema] });
  const rs = stmt.execute();

  while (rs.next()) {
    const tbl = rs.getColumnValue(1);

    if (excludes.includes(tbl.toUpperCase())) {
      actions.push(`SKIP "${db}"."${schema}"."${tbl}" (excluded)`);
      continue;
    }

    const qname = `"${db}"."${schema}"."${tbl}"`;
    const cmd = `TRUNCATE TABLE ${qname}`;
    if (DRY_RUN) {
      actions.push(`DRY RUN -> ${cmd}`);
    } else {
      snowflake.execute({ sqlText: cmd });
      actions.push(cmd);
    }
  }
}

return actions.join('\n');
$$;


CREATE OR REPLACE PROCEDURE billing_pe_stg.etl_ctrl.sp_truncate_tables_in_schemas(
    db_name STRING,                 -- e.g. 'EDW_PROD'
    schema_name STRING,             -- e.g. 'DWH,STAGING'
    dry_run BOOLEAN,                -- TRUE = list only; FALSE = execute
    exclude_tables VARIANT          -- e.g. PARSE_JSON('["AUDIT_LOG","KEEP_THIS"]') or NULL
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
/* NOTE: Snowflake uppercases param identifiers. Use DB_NAME, SCHEMA_NAME, etc. */
const db = (DB_NAME || '').trim();
if (!db) throw "db_name cannot be empty.";

const schemas = ((SCHEMA_NAME || '') + '')
  .split(',')
  .map(s => s.trim())
  .filter(s => s.length > 0);
if (schemas.length === 0) throw "schema_name must contain at least one schema.";

const excludeRaw = EXCLUDE_TABLES;   // VARIANT -> JS value (array/null/etc.)
const excludes = Array.isArray(excludeRaw)
  ? excludeRaw.map(x => ("" + x).toUpperCase())
  : [];

const actions = [];

/* =======================================================
   Special Deletes (always executed unless dry_run = TRUE)
   ======================================================= */
const specialDeletes = [
  'DELETE FROM BILLING_PE_STG.ETL_CTRL.JC_BATCH_STATUS`,  
  `DELETE FROM BILLING_PE_STG.ETL_CTRL.JC_MANIFEST_DETAILS`
];

for (const del of specialDeletes) {
  if (DRY_RUN) {
    actions.push(`DRY RUN -> ${del}`);
  } else {
    snowflake.execute({ sqlText: del });
    actions.push(del);
  }
}

/* =======================================================
   Schema-based TRUNCATES
   ======================================================= */
for (const schema of schemas) {
  const sql = `
    SELECT table_name
    FROM ${db}.information_schema.tables
    WHERE table_schema = :1
      AND table_type = 'BASE TABLE'
  `;
  const stmt = snowflake.createStatement({ sqlText: sql, binds: [schema] });
  const rs = stmt.execute();

  while (rs.next()) {
    const tbl = rs.getColumnValue(1);

    if (excludes.includes(tbl.toUpperCase())) {
      actions.push(`SKIP "${db}"."${schema}"."${tbl}" (excluded)`);
      continue;
    }

    const qname = `"${db}"."${schema}"."${tbl}"`;
    const cmd = `TRUNCATE TABLE ${qname}`;
    if (DRY_RUN) {
      actions.push(`DRY RUN -> ${cmd}`);
    } else {
      snowflake.execute({ sqlText: cmd });
      actions.push(cmd);
    }
  }
}

return actions.join('\n');
$$;


CALL claims_pe_stg.etl_ctrl.sp_truncate_tables_in_schemas(
  'CLAIMS_PE_STG',
  'MRG,STG',
  FALSE,
  PARSE_JSON('[]')  -- or NULL
);

CALL policy_pe_stg.etl_ctrl.sp_truncate_tables_in_schemas(
  'POLICY_PE_STG',
  'MRG,STG',
  FALSE,
  PARSE_JSON('[]')  -- or NULL
);

CALL billing_pe_stg.etl_ctrl.sp_truncate_tables_in_schemas(
  'BILLING_PE_STG',
  'MRG,STG',
  FALSE,
  PARSE_JSON('[]')  -- or NULL
);




SELECT * FROM CLAIMS_PE_STG.ETL_CTRL.JC_BATCH_STATUS ORDER BY BATCHID DESC;
--delete from CLAIMS_PE_STG.ETL_CTRL.JC_BATCH_STATUs;
select * from CLAIMS_PE_STG.ETL_CTRL.JC_MANIFEST_DETAILS;
--delete from CLAIMS_PE_STG.ETL_CTRL.JC_MANIFEST_DETAILS;


 
select batchid, max(row_insert_tms) 
from claims_pe_stg.stg.cc_claim
group by batchid
order by 2 desc
;


SELECT * FROM POLICY_PE_STG.ETL_CTRL.JC_BATCH_STATUS ORDER BY BATCHID DESC;
--delete from POLICY_PE_STG.ETL_CTRL.JC_BATCH_STATUs;
select * from POLICY_PE_STG.ETL_CTRL.JC_MANIFEST_DETAILS;
--delete from POLICY_PE_STG.ETL_CTRL.JC_MANIFEST_DETAILS;


select batchid, max(row_insert_tms) 
from policy_pe_stg.stg.pc_policy
group by batchid
order by 2 desc
;

SELECT * FROM BILLING_PE_STG.ETL_CTRL.JC_BATCH_STATUS ORDER BY BATCHID DESC;
--delete from BILLING_PE_STG.ETL_CTRL.JC_BATCH_STATUs;
select * from BILLING_PE_STG.ETL_CTRL.JC_MANIFEST_DETAILS;
--delete from BILLING_PE_STG.ETL_CTRL.JC_MANIFEST_DETAILS;

SELECT * FROM BILLING_PE_STG.ETL_CTRL.JC_TABLE_STATUS WHERE STATUS <> 'completed';
SELECT * FROM BILLING_PE_STG.ETL_CTRL.JC_ERROR_LOG;

UPDATE BILLING_PE_STG.ETL_CTRL.JC_BATCH_STATUS
SET STATUS = 'completed'
WHERE BATCHID = 1131;

select * from BILLING_PE_STG.mrg.bc_outboundfile


select batchid, max(row_insert_tms) 
from billing_pe_stg.stg.bc_policy
group by batchid
order by 2 desc
;
