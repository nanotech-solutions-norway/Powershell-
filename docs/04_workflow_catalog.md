# GitHub Actions Workflow Catalog — 22:38, 25.06.2026

## Workflows

| Workflow | Trigger | Runner | Purpose |
|---|---|---|---|
| `manual-atlas-health-check.yml` | Manual | `ubuntu-latest` | Atlas endpoint health check |
| `manual-atlas-validation.yml` | Manual | `ubuntu-latest` | Repository and endpoint validation |
| `manual-run-script.yml` | Manual | selectable | Approved script execution |
| `ci-powershell-quality.yml` | Push/PR/manual | `ubuntu-latest` | PSScriptAnalyzer + Pester |
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
