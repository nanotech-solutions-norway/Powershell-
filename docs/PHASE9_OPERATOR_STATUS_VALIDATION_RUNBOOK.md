# Phase 9 Operator Status Validation Runbook

Date: 03.07.2026

Repository: `nanotech-solutions-norway/Powershell-`

## Purpose

This runbook describes the first approved status endpoint validation path for Domeneshop MCP.

The runbook is operator-local and does not require a GitHub Actions workflow that reads protected values.

## Target

```text
http://ds.atlas-ai.no/status.php
```

## Preconditions

- Phase 8 is closed.
- Public endpoint validation has passed.
- The private runtime file has the expected status endpoint credential configured server-side.
- The operator has the matching credential available locally.

## Local PowerShell validation

Run from a trusted local PowerShell session.

Do not paste the credential into chat.

```powershell
$BaseUrl = "http://ds.atlas-ai.no"
$CredentialValue = Read-Host "Enter status endpoint credential"
$Headers = @{
    Authorization = "Bearer $CredentialValue"
}

try {
    $Response = Invoke-RestMethod -Method GET -Uri "$BaseUrl/status.php" -Headers $Headers -TimeoutSec 20
    $Sanitized = [ordered]@{
        ok = $Response.ok
        runtime_env_resolved = $Response.runtime_env_resolved
        config_dir_resolved = $Response.config_dir_resolved
        site_id_count = $Response.site_id_count
        safe_validation_posture = $Response.safe_validation_posture
        api_base_url_present = $Response.api_base_url_present
        auth_user_present = $Response.auth_user_present
        auth_value_present = $Response.auth_value_present
        write_tools_enabled = $Response.write_tools_enabled
        dry_run_default = $Response.dry_run_default
        operator_approval_required = $Response.operator_approval_required
    }

    $Sanitized | Format-List
}
finally {
    Remove-Variable CredentialValue -ErrorAction SilentlyContinue
    Remove-Variable Headers -ErrorAction SilentlyContinue
}
```

## Expected result

```text
ok: True
runtime_env_resolved: True
config_dir_resolved: True
site_id_count: 40
safe_validation_posture: True
api_base_url_present: True
auth_user_present: True
auth_value_present: True
write_tools_enabled: False
dry_run_default: True
operator_approval_required: True
```

## Evidence rule

Only copy the sanitized field list above into project evidence.

Do not copy:

- request headers;
- credential values;
- raw runtime file contents;
- API values;
- server private paths beyond already approved path references;
- full environment dumps.

## Failure handling

If the endpoint returns an error, record only:

```text
http_status
error_code
sanitized_error_message
```

Then inspect whether the server runtime file contains the required key and whether the endpoint credential matches.

Do not print or upload the credential.
