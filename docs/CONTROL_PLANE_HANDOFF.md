# PowerShell Control Plane Handoff

Repository: `nanotech-solutions-norway/Powershell-`

Status: validated through the current control-plane chain.

## Validated workflows

- CI - PowerShell Quality Gate
- Manual - Control Plane Readiness
- Manual - Workflow Governance Audit
- Manual - Project Control Report
- Scheduled - Workflow Governance Audit
- Scheduled - Project Control Report

## Recommended validation order

1. Run CI - PowerShell Quality Gate.
2. Run Manual - Control Plane Readiness.
3. Run Manual - Workflow Governance Audit.
4. Run Manual - Project Control Report with `target_environment: development`.
5. Run Scheduled - Project Control Report manually once after material workflow changes.

## Main artifacts

- `control-plane-readiness-report`
- `workflow-governance-report`
- `project-control-report`
- `scheduled-project-control-report`

## Operating note

Use the control report as the top-level review artifact. Use the readiness report to confirm that the file set is complete. Use the governance report to review workflow posture. Use the project control report to review adapter health, diagnostics, and governance in one place.
