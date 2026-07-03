# GitHub Actions Workflow Catalog — 03.07.2026

## Workflows

| Workflow | Trigger | Runner | Purpose |
|---|---|---|---|
| `ci-powershell-quality.yml` | Push/PR/manual | `ubuntu-latest` | PSScriptAnalyzer + Pester |
| `manual-atlas-health-check.yml` | Manual | `ubuntu-latest` | Atlas endpoint health check |
| `manual-atlas-validation.yml` | Manual | `ubuntu-latest` | Repository and endpoint validation |
| `manual-atlas-deployment-preflight.yml` | Manual | `ubuntu-latest` | Deployment-readiness gate without writes |
| `manual-run-script.yml` | Manual | selectable | Approved script execution |
| `manual-development-maintenance.yml` | Manual | `ubuntu-latest` | Development-only approved documentation maintenance with repository commit capability |
| `manual-dispatch-standard-validation-sequence.yml` | Manual | `ubuntu-latest` | Dispatch and optionally monitor the standard validation sequence |
| `manual-domeneshop-mcp-endpoint-validation.yml` | Manual | `ubuntu-latest` | Read-only Domeneshop MCP public endpoint validation |
| `manual-domeneshop-mcp-https-readiness.yml` | Manual | `ubuntu-latest` | Read-only Domeneshop MCP HTTPS readiness diagnostic |
| `scheduled-atlas-health.yml` | Schedule/manual | `ubuntu-latest` | Scheduled health evidence |
| `scheduled-project-control-report.yml` | Schedule/manual | `ubuntu-latest` | Scheduled project control report |

## Standard workflow pattern

```yaml
on:
  workflow_dispatch:

jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main
          fetch-depth: 1
      - shell: pwsh
        run: ./scripts/atlas/Get-AtlasEndpointHealth.ps1 -BaseUrl "https://www.atlas-ai.no"
```

## Evidence upload pattern

```yaml
- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: atlas-evidence
    path: evidence/*.json
```

## Development maintenance pattern

`manual-development-maintenance.yml` is the first development-only workflow-dispatch path with repository commit capability.

Scope:

- environment: `development`
- approved task: `append_task_log`
- approved targets: `docs/CONTROL_PLANE_TASK_LOG.md`, `docs/PHASE7_DEVELOPMENT_EXECUTION_ENABLEMENT.md`
- no production, deployment, secrets, environment, or external endpoint authority

## Domeneshop MCP read-only validation pattern

The Domeneshop MCP validation workflows are development-first and read-only.

| Workflow | Environment | Artifact |
|---|---|---|
| `manual-domeneshop-mcp-endpoint-validation.yml` | `development` | `domeneshop-mcp-endpoint-validation-report` |
| `manual-domeneshop-mcp-https-readiness.yml` | `development` | `domeneshop-mcp-https-readiness-report` |

Default endpoint targets:

```text
http://ds.atlas-ai.no/health.php
https://ds.atlas-ai.no/health.php
```

These workflows do not perform provider API writes, DNS writes, file writes, SQL writes, bearer-token status validation, or deployment writes.

## Standard validation dispatcher pattern

`manual-dispatch-standard-validation-sequence.yml` dispatches the standard validation chain:

1. `CI - PowerShell Quality Gate`
2. `Manual - Control Plane Readiness`
3. `Manual - Workflow Governance Audit` with `fail_on_finding: false`
4. `Manual - Project Control Report` with `target_environment: development`
5. `Scheduled - Project Control Report` manually when selected

The dispatcher is limited to triggering the existing validation workflows and keeps the repository write gate held.

## Production gate pattern

```yaml
environment: production
```

Use this only after the `production` environment has required reviewers configured.

## Write-gate pattern

Workflows that evaluate staging or production write readiness should pass both `WRITE_TOOLS_ENABLED` and a controlled `write_mode` input.

Default repository variable:

```text
WRITE_TOOLS_ENABLED=false
```
