# Evidence and Audit Model — 22:38, 25.06.2026

## Purpose

Every material PowerShell run should produce a non-sensitive evidence record that can be reviewed later.

## Evidence schema

```json
{
  "schema_version": "1.0",
  "timestamp_utc": "2026-06-25T20:38:00Z",
  "project": "Atlas AI",
  "target_environment": "development",
  "workflow": "manual-atlas-health-check",
  "script": "Get-AtlasEndpointHealth.ps1",
  "write_mode": "read_only",
  "classification": "healthy",
  "manual_review_required": false,
  "secrets_exposed": false
}
```

## Classifications

| Value | Meaning |
|---|---|
| `healthy` | Check passed |
| `degraded` | Partial or warning-level result |
| `unauthorized` | Token or permission issue |
| `not_found` | Endpoint or route mismatch |
| `failed` | Technical failure |
| `manual_review_required` | Human review required |
| `write_paused` | Write blocked by policy |

## Redaction rule

Evidence must not include credentials, request headers, private customer data, accounting data, bank details, or raw internal payloads.
