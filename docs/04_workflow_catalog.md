# GitHub Actions Workflow Catalog — 03:24, 26.06.2026

## Workflows

| Workflow | Trigger | Runner | Purpose |
|---|---|---|---|
| `ci-powershell-quality.yml` | Push/PR/manual | `ubuntu-latest` | PSScriptAnalyzer + Pester |
| `manual-atlas-health-check.yml` | Manual | `ubuntu-latest` | Atlas endpoint health check |
| `manual-atlas-validation.yml` | Manual | `ubuntu-latest` | Repository and endpoint validation |
| `manual-atlas-deployment-preflight.yml` | Manual | `ubuntu-latest` | Deployment-readiness gate without writes |
| `manual-run-script.yml` | Manual | selectable | Approved script execution |
| `scheduled-atlas-health.yml` | Schedule/manual | `ubuntu-latest` | Scheduled health evidence |

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

## Production gate pattern

```yaml
environment: production
```

Use this only after the `production` environment has required reviewers configured.

## Write-gate pattern

Workflows that evaluate write readiness should pass both `WRITE_TOOLS_ENABLED` and a controlled `write_mode` input.

```yaml
env:
  WRITE_TOOLS_ENABLED: ${{ vars.WRITE_TOOLS_ENABLED }}
```

Default repository variable:

```text
WRITE_TOOLS_ENABLED=false
```
