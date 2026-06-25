# Troubleshooting Playbook — 22:38, 25.06.2026

## Workflow not visible

Check that the workflow file is under `.github/workflows/`, exists on `main`, and includes `workflow_dispatch` if manual execution is required.

## PowerShell command fails

Confirm the workflow step uses:

```yaml
shell: pwsh
```

Use GitHub-hosted runners for default operations.

## Secret missing

Check:

1. `Settings → Secrets and variables → Actions`.
2. Repository vs environment secret scope.
3. Secret name spelling.
4. Whether the job is targeting the correct environment.

## Production job waits for approval

This is expected when the workflow targets a protected GitHub Environment. Approve only after reviewing validation evidence.

## Endpoint unauthorized

Do not print the token. Confirm the secret exists and that the script sends the bearer token through the `Authorization` header.

## Artifact missing

Confirm the script writes to `evidence/*.json` and that the workflow uploads that same path.

## Write operation blocked

This is expected when `WRITE_TOOLS_ENABLED=false`, `WriteMode=read_only`, or `WriteMode=write_paused`. Do not bypass the guard.
