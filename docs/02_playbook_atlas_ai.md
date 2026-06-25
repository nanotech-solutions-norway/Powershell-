# Atlas AI PowerShell GitHub Playbook — 22:38, 25.06.2026

## First-time setup

1. Open the repository `nanotech-solutions-norway/Powershell-`.
2. Confirm GitHub Actions are enabled.
3. Create environments: `development`, `staging`, `production`.
4. Add required reviewer protection to `production`.
5. Add secrets only when the related integration is approved.
6. Keep `WRITE_TOOLS_ENABLED=false` until deployment validation is complete.

## Manual operation from Android

1. Open GitHub in browser or app.
2. Open the repository.
3. Tap **Actions**.
4. Select the workflow.
5. Tap **Run workflow**.
6. Choose environment and inputs.
7. Start the run.
8. Review logs and artifacts.

## Recommended first-run order

1. `CI - PowerShell Quality Gate`
2. `Manual - Atlas Health Check`
3. `Manual - Atlas Validation`
4. `Manual - Run Approved PowerShell Script`
5. Staging deployment preflight after all checks pass.

## Workflow selection

| Need | Workflow |
|---|---|
| Check Atlas endpoint | `manual-atlas-health-check.yml` |
| Validate repository and endpoint | `manual-atlas-validation.yml` |
| Run approved script | `manual-run-script.yml` |
| Test/lint PowerShell | `ci-powershell-quality.yml` |

## Production rule

No production write should run unless validation passed, the workflow targets the protected `production` environment, required reviewers approved the job, secrets are configured, and the script writes redacted evidence.
