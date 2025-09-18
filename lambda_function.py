# lambda_function.py
import os
import json
from typing import List, Tuple, Dict, Any, Optional
from datetime import datetime, timedelta, timezone

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError, BotoCoreError

# ---------- boto3 clients with sane retries ----------
_BOTO_CFG = Config(
    retries={"max_attempts": 5, "mode": "standard"},
    connect_timeout=5,
    read_timeout=60,
)
s3 = boto3.client("s3", config=_BOTO_CFG)

# ---------- Utilities ----------
def _now_utc() -> datetime:
    return datetime.now(timezone.utc)

def _bool(v: Any, default: bool = False) -> bool:
    if v is None:
        return default
    if isinstance(v, bool):
        return v
    return str(v).strip().lower() in {"1", "true", "t", "yes", "y", "on"}

def _age_cutoff(min_age_hours: Optional[int]) -> Optional[datetime]:
    if not min_age_hours or int(min_age_hours) <= 0:
        return None
    return _now_utc() - timedelta(hours=int(min_age_hours))

def _json_env(name: str) -> Any:
    raw = os.getenv(name)
    if not raw:
        raise ValueError(f"{name} env var is required.")
    try:
        return json.loads(raw)
    except Exception as e:
        raise ValueError(f"{name} must be valid JSON. Error: {e}")

def _get_env() -> str:
    env = (os.getenv("ENV_NAME") or "").strip().lower()
    if not env:
        raise ValueError("ENV_NAME env var is required (e.g., dev|qa|saasstg|penupgstg|prod).")
    return env

def _get_bucket_map() -> Dict[str, Dict[str, str]]:
    parsed = _json_env("BUCKET_MAP_JSON")
    if not isinstance(parsed, dict):
        raise ValueError("BUCKET_MAP_JSON must be a JSON object: { env: { xcenter: bucket } }")
    return parsed

def _resolve_bucket(xc: str) -> str:
    env = _get_env()
    bucket_map = _get_bucket_map()  # {env:{xc:bucket}}
    xc_l = (xc or "").strip().lower()
    if env not in bucket_map:
        raise ValueError(f"ENV_NAME '{env}' not found in BUCKET_MAP_JSON.")
    inner = bucket_map[env]
    if not isinstance(inner, dict):
        raise ValueError(f"BUCKET_MAP_JSON['{env}'] must be an object mapping xcenter->bucket.")
    if xc_l not in inner:
        raise ValueError(f"xcenter '{xc_l}' not found in BUCKET_MAP_JSON for env '{env}'.")
    bucket = (inner[xc_l] or "").strip()
    if not bucket:
        raise ValueError(f"Bucket for xcenter '{xc_l}' in env '{env}' is empty.")
    return bucket

def _list_prefixes(event: Dict[str, Any]) -> List[str]:
    """
    Priority:
      1) event["prefixes"] (list)
      2) env DEFAULT_PREFIXES (comma-separated)
      3) [""] -> whole bucket
    """
    if isinstance(event.get("prefixes"), list):
        # If caller included "" (root), treat as whole-bucket
        if any(p is None or str(p).strip() == "" for p in event["prefixes"]):
            return [""]

        # Otherwise keep the non-empty prefixes
        uniq = []
        for p in event["prefixes"]:
            ps = str(p or "").strip()
            if ps and ps not in uniq:
                uniq.append(ps)
        if uniq:
            return uniq
        # If they provided a list but it ended up empty, fall through to defaults

    env_default = os.getenv("DEFAULT_PREFIXES", "")
    if env_default.strip():
        uniq = []
        for p in env_default.split(","):
            ps = p.strip()
            if ps and ps not in uniq:
                uniq.append(ps)
        if uniq:
            return uniq

    return [""]  # full bucket

def _bucket_is_versioned(bucket: str) -> bool:
    try:
        vr = s3.get_bucket_versioning(Bucket=bucket)
    except ClientError as e:
        _log("WARN", "GetBucketVersioningFailed", bucket=bucket, error=str(e))
        return False
    return vr.get("Status") in ("Enabled", "Suspended")

def _delete_batch(bucket: str, objects: List[Dict[str, str]], dry_run: bool) -> int:
    """Delete up to 1000 objects/versions; returns count actually deleted (or would delete in dry_run)."""
    if not objects:
        return 0
    if dry_run:
        # simulate success
        return len(objects)
    try:
        resp = s3.delete_objects(Bucket=bucket, Delete={"Objects": objects})
        deleted = resp.get("Deleted", [])
        # Note: if some failed due to AccessDenied or NotFound, they will appear under 'Errors'
        if resp.get("Errors"):
            _log("WARN", "PartialDeleteErrors", bucket=bucket, errors=resp["Errors"])
        return len(deleted) or len(objects)  # best effort metric
    except ClientError as e:
        _log("ERROR", "DeleteObjectsFailed", bucket=bucket, error=str(e))
        return 0

def _log(level: str, msg: str, **kv):
    record = {"level": level, "msg": msg, "ts": _now_utc().isoformat()}
    record.update(kv)
    print(json.dumps(record, default=str))

# ---------- Core deletion routines ----------
def _delete_unversioned(bucket: str, prefix: str, cutoff: Optional[datetime], dry_run: bool) -> Tuple[int, int]:
    scanned = 0
    deleted = 0
    paginator = s3.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        contents = page.get("Contents", []) or []
        batch: List[Dict[str, str]] = []
        for obj in contents:
            scanned += 1
            # obj has keys: Key, LastModified, Size, ETag, StorageClass, etc.
            if cutoff and obj.get("LastModified") and obj["LastModified"] > cutoff:
                continue
            batch.append({"Key": obj["Key"]})
            if len(batch) == 1000:
                deleted += _delete_batch(bucket, batch, dry_run)
                batch = []
        if batch:
            deleted += _delete_batch(bucket, batch, dry_run)
    return scanned, deleted

def _delete_versioned(bucket: str, prefix: str, cutoff: Optional[datetime], dry_run: bool) -> Tuple[int, int]:
    scanned = 0
    deleted = 0
    paginator = s3.get_paginator("list_object_versions")
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        versions = (page.get("Versions") or []) + (page.get("DeleteMarkers") or [])
        batch: List[Dict[str, str]] = []
        for v in versions:
            scanned += 1
            # v has Keys: Key, VersionId, IsLatest, LastModified, etc.
            if cutoff and v.get("LastModified") and v["LastModified"] > cutoff:
                continue
            batch.append({"Key": v["Key"], "VersionId": v["VersionId"]})
            if len(batch) == 1000:
                deleted += _delete_batch(bucket, batch, dry_run)
                batch = []
        if batch:
            deleted += _delete_batch(bucket, batch, dry_run)
    return scanned, deleted

# ---------- Handler ----------
def lambda_handler(event, context):
    """
    Delete objects (and versions, if enabled) from S3, filtered by prefix & age.
    Event examples:
      { "xcenter": "cc", "prefixes": ["landing/"], "dry_run": false, "min_age_hours": 0 }
      { "xcenters": ["cc","bc","pc"], "prefixes": ["landing/","tmp/"], "dry_run": true, "min_age_hours": 24 }
      { "xcenter": "cc" }  # uses DEFAULT_PREFIXES or whole bucket

    Required ENV:
      ENV_NAME = dev|qa|saasstg|penupgstg
      BUCKET_MAP_JSON = {
        "qa":   { "cc": "dev-cc-landing", "bc": "dev-bc-landing", "pc": "dev-pc-landing" },
        "saasstg": { "cc": "cig-stg-env-saasqa-gw-landing-zone-cc-01-bucket-archive",
                  "bc": "cig-stg-env-saasqa-gw-landing-zone-bc-01-bucket-archive", 
                  "pc": "cig-stg-env-saasqa-gw-landing-zone-pc-01-bucket-archive"  },
        "penupgstg": { "cc": "cig-stg2-env-saasstg-gw-landing-zone-cc-02-bucket-archive",
                  "bc": "cig-stg2-env-saasstg-gw-landing-zone-bc-02-bucket-archive", 
                  "pc": "cig-stg2-env-saasstg-gw-landing-zone-pc-02-bucket-archive" }
      }

    Optional ENV:
      DEFAULT_PREFIXES = "landing/,tmp/"
      DRY_RUN = "true"|"false" (default false)
      MIN_AGE_HOURS = "0"|"4"|...

    Permissions (execution role):
      - s3:ListBucket, s3:GetBucketVersioning, s3:ListBucketVersions
      - s3:DeleteObject, s3:DeleteObjectVersion
      (Grant on bucket & bucket/*; KMS not required to delete)
    """
    _log("INFO", "InvokeStart", event=event)

    # Validate required event keys (xcenter/xcenters)
    if event.get("xcenter"):
        xcenters = [str(event["xcenter"]).strip().lower()]
    elif isinstance(event.get("xcenters"), list) and event["xcenters"]:
        xcenters = [str(x).strip().lower() for x in event["xcenters"] if str(x).strip()]
    else:
        raise ValueError("Provide 'xcenter' or 'xcenters' in the event.")

    # Options (event overrides ENV defaults)
    dry_run = _bool(event.get("dry_run"), default=_bool(os.getenv("DRY_RUN", "false")))
    try:
        min_age_hours = int(event.get("min_age_hours", os.getenv("MIN_AGE_HOURS", "0")))
    except Exception:
        min_age_hours = 0
    cutoff = _age_cutoff(min_age_hours)
    prefixes = _list_prefixes(event)

    env = _get_env()
    results = []

    for xc in xcenters:
        bucket = _resolve_bucket(xc)
        versioned = _bucket_is_versioned(bucket)
        total_scanned = 0
        total_deleted = 0
        per_prefix: List[Dict[str, Any]] = []

        _log(
            "INFO",
            "WorkStart",
            xcenter=xc,
            bucket=bucket,
            versioned=versioned,
            dry_run=dry_run,
            prefixes=prefixes,
            min_age_hours=min_age_hours,
        )

        for p in prefixes:
            try:
                if versioned:
                    scanned, deleted = _delete_versioned(bucket, p, cutoff, dry_run)
                else:
                    scanned, deleted = _delete_unversioned(bucket, p, cutoff, dry_run)
            except (ClientError, BotoCoreError) as e:
                _log("ERROR", "PrefixDeleteFailed", bucket=bucket, prefix=p, error=str(e))
                scanned, deleted = 0, 0

            total_scanned += scanned
            total_deleted += deleted
            per_prefix.append({"prefix": p, "scanned": scanned, "deleted": deleted})
            _log("INFO", "PrefixDone", bucket=bucket, prefix=p, scanned=scanned, deleted=deleted)

        summary = {
            "xcenter": xc,
            "bucket": bucket,
            "versioned": versioned,
            "dry_run": dry_run,
            "min_age_hours": min_age_hours,
            "prefixes": prefixes,
            "total_scanned": total_scanned,
            "total_deleted": total_deleted,
            "by_prefix": per_prefix,
        }
        results.append(summary)
        _log("INFO", "WorkDone", **summary)

    response = {"status": "ok", "env": env, "results": results}
    _log("INFO", "InvokeDone", response=response)
    return response


# -------- Optional: local debug entrypoint --------
if __name__ == "__main__":
    # Local test payload; adjust as needed
    test_event = {
        "xcenter": "cc",
        "prefixes": ["landing/"],
        "dry_run": True,
        "min_age_hours": 0,
    }
    print(json.dumps(lambda_handler(test_event, None), indent=2, default=str))



# Environment Variables 

# BUCKET_MAP_JSON - {"qa":{"cc":"qa-cc-landing","bc":"qa-bc-landing","pc":"qa-pc-landing"},"saasstg":{"cc":"cig-stg-env-saasqa-gw-landing-zone-cc-01-bucket-archive","bc":"cig-stg-env-saasqa-gw-landing-zone-bc-01-bucket-archive","pc":"cig-stg-env-saasqa-gw-landing-zone-pc-01-bucket-archive"},"penupgstg":{"cc":"cig-stg2-env-saasstg-gw-landing-zone-cc-02-bucket-archive","bc":"cig-stg2-env-saasstg-gw-landing-zone-bc-02-bucket-archive","pc":"cig-stg2-env-saasstg-gw-landing-zone-pc-02-bucket-archive"}} 
# ENV_NAME - penupgstg


# Test Cases 

# 1. All the XCENTERS
#{
 # "xcenters": ["cc","bc","pc"],
 # "prefixes": [""],
 # "dry_run": false,
 # "min_age_hours": 0
#}

# 2. BC XCENTER
#{
 # "xcenters": ["bc"],
 # "prefixes": [""],
 # "dry_run": false,
 # "min_age_hours": 0
#}

# 3. CC XCENTER
#{
 # "xcenters": ["cc"],
 # "prefixes": [""],
 # "dry_run": false,
 # "min_age_hours": 0
#}

# 4. PC XCENTER
#{
 # "xcenters": ["pc"],
 # "prefixes": [""],
 # "dry_run": false,
 # "min_age_hours": 0
#}

# dry_run = true ,  will provide you the count and wont delete anything from bucket 
# dry_run = false ,  will delete the files from bucket 
# prefixes , we can provide the name of landing zone like '/landing' 
# min_age_hours =0 , doesn't look for any time period . we can specify the time like week or month 
