# GitHub PowerShell Security and Secrets Model — 22:38, 25.06.2026

## Hard rules

- Never commit secrets.
- Never echo secrets.
- Never expose bearer tokens in URLs.
- Never upload raw sensitive API responses as artifacts.
- Never store customer, accounting, bank, or confidential data in this repo unless explicitly approved.
- Keep write functions paused until full validation is complete.

## Secret handling

Use GitHub repository, environment, or organization secrets.

```yaml
env:
  ATLAS_HEALTH_BEARER_TOKEN: ${{ secrets.ATLAS_HEALTH_BEARER_TOKEN }}
```

PowerShell access:

```powershell
$token = $env:ATLAS_HEALTH_BEARER_TOKEN
```

## Evidence sanitation

Evidence may include timestamp, workflow, target environment, endpoint, HTTP status, classification, and non-sensitive summaries.

Evidence must not include credentials, request headers, raw customer data, bank details, backend stack traces, or full private payloads.

## Write lock

Use `WRITE_TOOLS_ENABLED=false` as the default repository variable. Production writes must require the GitHub `production` environment and reviewer approval.
