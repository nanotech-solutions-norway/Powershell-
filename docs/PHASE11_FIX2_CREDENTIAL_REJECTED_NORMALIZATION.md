# Phase 11 Fix 2 — Credential Rejected Normalization

Date: 05.07.2026

Repository: `nanotech-solutions-norway/Powershell-`

## Status

A failed run of `Manual - Domeneshop MCP Protected Status Validation` was reviewed after the protected value was configured.

## Finding

The workflow received a protected value and reached the status validation script.

The status endpoint returned:

```text
http_status: 403
classification: failed
```

The sanitized artifact was created and uploaded.

## Root cause classification

```text
credential_rejected
```

The most likely causes are:

- the protected value contains the variable assignment prefix;
- the protected value contains a bearer/header prefix;
- the protected value contains quotes or trailing whitespace;
- the protected value does not exactly match the server-side MCP bridge bearer token.

## Fix applied

The protected status validation script now normalizes the protected value before making the request.

Accepted input forms now include:

```text
actual_token_value
MCP_BRIDGE_BEARER_TOKEN=actual_token_value
DOMENESHOP_MCP_STATUS_CREDENTIAL=actual_token_value
Bearer actual_token_value
Authorization: Bearer actual_token_value
"actual_token_value"
'actual_token_value'
```

The script also classifies HTTP 401 or 403 as:

```text
credential_rejected
```

## Required operator action

Rerun the protected validation workflow.

If the result is still `credential_rejected`, replace the protected value with only the exact token value, not the variable name and not the full assignment line.

Do not paste the value into chat.

## Validation order

1. Run `Manual - Domeneshop MCP Protected Status Validation`.
2. If healthy, run `Manual - Dispatch Standard Validation Sequence`.
3. If still `credential_rejected`, correct the protected value and rerun.
