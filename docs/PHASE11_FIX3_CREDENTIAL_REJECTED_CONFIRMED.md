# Phase 11 Fix 3 — Credential Rejected Confirmed

Date: 07.07.2026

Repository: `nanotech-solutions-norway/Powershell-`

## Status

A new run of `Manual - Domeneshop MCP Protected Status Validation` was reviewed.

## Evidence summary

The workflow checked out the current `main` branch at commit:

```text
49a475cf1bfc91270261cf559cf82cf52abb5be5
```

The workflow received a masked protected value in the environment.

The validation script reached `/status.php` and completed its sanitized report generation.

The resulting classification was:

```text
credential_rejected
```

The report artifact upload succeeded.

## Interpretation

This is not a stale workflow issue.

This is not a missing protected value issue.

This is not a repository-side execution issue.

The endpoint rejected the protected value supplied by GitHub Actions.

## Required operator action

Recheck the protected value against the server-side `MCP_BRIDGE_BEARER_TOKEN` value used by `/status.php`.

The GitHub protected value must contain only the exact token value.

Do not include:

```text
MCP_BRIDGE_BEARER_TOKEN
MCP_BRIDGE_BEARER_TOKEN=
DOMENESHOP_MCP_STATUS_CREDENTIAL=
Bearer
Authorization: Bearer
quotes
extra spaces
Domeneshop API token
Domeneshop API secret
SFTP password
```

## Recommended safe verification

Run the operator-local status validation from a local PowerShell session using the same value intended for GitHub.

If local validation succeeds but GitHub validation still returns `credential_rejected`, replace the GitHub protected value by copying the exact same working local value.

## Closure boundary

Phase 11 remains open until `Manual - Domeneshop MCP Protected Status Validation` returns a healthy sanitized artifact.

No provider writes, DNS changes, hosting file operations, SQL/database operations, staging authority, production authority, or runtime credential changes are enabled by this diagnostic record.
