# Atlas AI GitHub PowerShell Blueprint — 22:38, 25.06.2026

## Executive conclusion

Using GitHub for PowerShell functions is the preferred model for Atlas AI. It gives controlled execution, mobile-triggered operation, repeatable workflow runs, secret isolation, evidence artifacts, and environment-protected deployment gates.

The package in this folder is designed for the GitHub repository `nanotech-solutions-norway/Powershell-` and can be adapted to other projects by replacing the project key, base URLs, scripts, secrets, and workflow names.

## Included deliverables

1. Atlas AI GitHub PowerShell blueprint.
2. Atlas-specific execution playbook.
3. Security and secrets model.
4. GitHub Actions workflow catalog.
5. Android operation guide.
6. Adaptation guide for other projects.
7. Evidence/audit model.
8. Troubleshooting playbook.
9. PowerShell scripts.
10. GitHub Actions workflows.
11. Pester/PSScriptAnalyzer quality gate.

## Deployment recommendation

Use this repository as the central PowerShell automation utility repo, not as a project-specific website repo. Keep Atlas-specific scripts under `scripts/atlas/` and add other projects under their own folders.

Default operating mode should remain:

```text
WRITE_TOOLS_ENABLED=false
default write mode = read_only
production writes = protected environment only
```

## First run

Run these in order:

1. `CI - PowerShell Quality Gate`
2. `Manual - Atlas Health Check`
3. `Manual - Atlas Validation`
4. `Manual - Run Approved PowerShell Script` with `Invoke-AtlasDeploymentPreflight`
5. Add project-specific scripts only after baseline validation passes.

## Notes

The repository discovered through the GitHub connector is named `Powershell-` with a trailing hyphen. The user-facing project name may remain "Powershell", but the operational repository identifier is `nanotech-solutions-norway/Powershell-` unless renamed in GitHub.
