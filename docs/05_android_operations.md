# Android Operation Guide for GitHub PowerShell — 22:38, 25.06.2026

## Operating model

Android should control GitHub Actions. It should not run production PowerShell automation locally.

```text
Android browser / GitHub app
  → GitHub Actions
    → GitHub runner
      → PowerShell 7 (`pwsh`)
```

## Run a workflow from Android

1. Open GitHub.
2. Open `nanotech-solutions-norway/Powershell-`.
3. Open **Actions**.
4. Select the required workflow.
5. Tap **Run workflow**.
6. Select branch and inputs.
7. Start the run.
8. Review logs.
9. Download artifacts if required.

## Recommended Android workflows

| Task | Workflow |
|---|---|
| Quick Atlas status | `Manual - Atlas Health Check` |
| Repository validation | `Manual - Atlas Validation` |
| Controlled script run | `Manual - Run Approved PowerShell Script` |
| QA/lint/test | `CI - PowerShell Quality Gate` |

## Do not use Android for

- storing API keys in local scripts;
- manually running production deployment scripts;
- managing raw accounting/customer/private data;
- editing secrets into workflow files.
