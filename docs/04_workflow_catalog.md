# GitHub Actions Workflow Catalog — 14:31, 27.06.2026

## Workflows

| Workflow | Trigger | Runner | Purpose |
|---|---|---|---|
| `ci-powershell-quality.yml` | Push/PR/manual | `ubuntu-latest` | PSScriptAnalyzer + Pester |
| `ci-python-quality.yml` | Push/PR/manual | `ubuntu-latest` | Ruff + mypy + pytest |
| `manual-python-debug.yml` | Manual | `ubuntu-latest` | Sanitized Python diagnostics and artifact upload |
| `manual-python-run-script.yml` | Manual | `ubuntu-latest` | Development-only approved Python script execution |
| `manual-atlas-health-check.yml` | Manual | `ubuntu-latest` | Atlas endpoint health check |
| `manual-atlas-validation.yml` | Manual | `ubuntu-latest` | Repository and endpoint validation |
| `manual-atlas-deployment-preflight.yml` | Manual | `ubuntu-latest` | Deployment-readiness gate without writes |
| `manual-run-script.yml` | Manual | selectable | Approved PowerShell script execution |
| `scheduled-atlas-health.yml` | Schedule/manual | `ubuntu-latest` | Scheduled health evidence |

## Standard workflow pattern

```yaml
on:
  workflow_dispatch:

permissions:
  contents: read
  actions: read

jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main
          fetch-depth: 1
```

## Python setup pattern

```yaml
- uses: actions/setup-python@v6
  with:
    python-version: "3.13"
    cache: "pip"
    cache-dependency-path: |
      python/requirements.txt
      python/requirements-dev.txt
```

## Evidence upload pattern

```yaml
- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: workflow-evidence
    path: artifacts/**
    if-no-files-found: warn
```

## Production gate pattern

```yaml
environment: production
```

Use this only after the `production` environment has required reviewers configured.

## Write-gate pattern

Workflows that evaluate write readiness should pass both `WRITE_TOOLS_ENABLED` and a controlled `write_mode` or read-only execution input.

```yaml
env:
  WRITE_TOOLS_ENABLED: ${{ vars.WRITE_TOOLS_ENABLED }}
```

Default repository variable:

```text
WRITE_TOOLS_ENABLED=false
```

## Python approved-script rule

Manual Python execution must select from a workflow choice list and then resolve the script through `python/tools/approved_scripts.py`.

Do not add arbitrary shell command inputs to Python workflows.
