# Atlas AI GitHub PowerShell Phase 2 Operations — 03:24, 26.06.2026

## Status

Phase 2 adds operational hardening after the initial CI quality gate was confirmed working.

## Added controls

| Control | Purpose |
|---|---|
| `scripts/common/Test-WriteGate.ps1` | Central write-permission guard |
| `scripts/atlas/Invoke-AtlasDeploymentPreflight.ps1` | Pre-deployment validation without deployment writes |
| `.github/workflows/manual-atlas-deployment-preflight.yml` | Manual preflight workflow |
| `.github/workflows/scheduled-atlas-health.yml` | Scheduled health evidence workflow |
| updated `.github/workflows/manual-run-script.yml` | Adds deployment preflight to approved script list |
| updated `tests/Atlas.Tests.ps1` | Adds tests for new scripts, workflows, and write gate |

## Recommended run order

1. Run `CI - PowerShell Quality Gate`.
2. Run `Manual - Atlas Health Check` using `development`, `https://www.atlas-ai.no`, and `/`.
3. Run `Manual - Atlas Validation` using `development`.
4. Run `Manual - Atlas Deployment Preflight` using `development` and `read_only`.
5. Configure `staging` and `production` GitHub Environments.
6. Keep `WRITE_TOOLS_ENABLED=false` until a specific staging write operation is approved.

## Write policy

Write functionality is structurally prepared but paused by default.

The write gate allows writes only when:

- `WRITE_TOOLS_ENABLED=true`, and
- the selected write mode matches the target environment, and
- production writes run inside GitHub Actions using the protected `production` environment.

## Evidence policy

Every health, validation, and preflight run should upload an evidence artifact from:

```text
evidence/*.json
```

Evidence must remain redacted and must not contain secrets, customer data, accounting data, or backend traces.

## Next recommended phase

Phase 3 should add project adapters under `scripts/projects/` or project-specific folders, for example:

- `scripts/solarex/`
- `scripts/domeneshop/`
- `scripts/conta/`
- `scripts/wix/`

Each adapter should use the same health, validation, evidence, and write-gate patterns established for Atlas AI.
