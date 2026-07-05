# Atlas AI GitHub PowerShell Blueprint — 03.07.2026

This repository is the reusable **PowerShell execution and automation control layer** for Atlas AI and other NanoTech Solutions Norway projects.

Primary operating purpose:

- run controlled PowerShell scripts through **GitHub Actions** rather than Android-local execution;
- provide a browser-operated execution model suitable for Android, desktop, and tablet use;
- separate scripts, secrets, workflows, validation, audit logs, and deployment gates;
- support Atlas AI first, while keeping the pattern adaptable to SolarEX, Conta Bridge/MCP, Domeneshop tooling, website QA, and future platform modules.

## Repository identity

| Item | Value |
|---|---|
| GitHub repository | `nanotech-solutions-norway/Powershell-` |
| Main target project | Atlas AI |
| Execution model | GitHub Actions + PowerShell 7 (`pwsh`) |
| Interactive model | GitHub Codespaces where needed |
| Security posture | Read-first, write-paused by default, environment-gated |
| Mobile control | Android browser or GitHub app triggers Actions manually |

## Current release closure baseline

Phase 6 records the validated control-plane release closure. Phase 5, `Project Control Report Classification Hardening`, is implemented and validated.

Final validated Phase 6 workflow chain:

| Workflow | Status | Evidence |
|---|---|---|
| `CI - PowerShell Quality Gate` | Working | User-validated Phase 6 baseline |
| `Manual - Control Plane Readiness` | Working | User-validated Phase 6 baseline |
| `Manual - Workflow Governance Audit` | Working | User-validated Phase 6 baseline |
| `Manual - Project Control Report` | Working | https://github.com/nanotech-solutions-norway/Powershell-/actions/runs/28290638114/attempts/1#summary-83821898248 |
| `Scheduled - Project Control Report` | Working | https://github.com/nanotech-solutions-norway/Powershell-/actions/runs/28290655449/attempts/1#summary-83821943679 |

## Phase 7 development execution status

Phase 7 adds a development-only workflow-dispatch maintenance path with repository commit capability.

Workflow:

- `Manual - Development Maintenance Task`

Scope:

- development environment only
- approved documentation-maintenance task only
- approved targets under `docs/` only
- no production authority
- no deployment authority
- no secret, environment, or external endpoint changes

## Phase 8 Domeneshop MCP read-only validation status

Phase 8 adds development-first, read-only validation coverage for the Domeneshop MCP public endpoint and HTTPS/TLS readiness diagnostics.

Validated workflows:

- `Manual - Domeneshop MCP Endpoint Validation`
- `Manual - Domeneshop MCP HTTPS Readiness`
- `Manual - Dispatch Standard Validation Sequence`

Scope:

- development environment only
- read-only endpoint validation only
- no provider writes
- no DNS writes
- no file or SQL mutations
- no bearer-token workflow validation yet
- HTTPS production readiness remains pending certificate correction

## Phase 9 status endpoint validation status

Phase 9 operator-local status endpoint validation is passed.

Documents:

- `docs/PHASE9_STATUS_ENDPOINT_VALIDATION_DESIGN.md`
- `docs/PHASE9_OPERATOR_STATUS_VALIDATION_RUNBOOK.md`
- `docs/PHASE9_STATUS_VALIDATION_CLOSURE.md`

Scope:

- operator-local validation passed
- sanitized evidence boundary only
- no credential material stored in repository
- no GitHub status workflow yet
- no runtime credential changes
- no staging or production authority

## Recommended operating order

1. Keep all production/deployment workflows paused until a separate write-gate phase is explicitly approved.
2. Run `CI - PowerShell Quality Gate`.
3. Run `Manual - Control Plane Readiness`.
4. Run `Manual - Workflow Governance Audit` with `fail_on_finding: false`.
5. Run `Manual - Project Control Report` with `target_environment: development`.
6. Run `Scheduled - Project Control Report` manually once after material changes.
7. For Phase 7 development maintenance, run `Manual - Development Maintenance Task` first with `dry_run: true`, then with `dry_run: false` only for approved documentation targets.
8. For Domeneshop MCP read-only validation, run `Manual - Domeneshop MCP Endpoint Validation` and `Manual - Domeneshop MCP HTTPS Readiness` before considering HTTPS, bearer-status, or write-gate progression.
9. For Phase 9, use `docs/PHASE9_STATUS_VALIDATION_CLOSURE.md` as the closure record.
10. If a workflow fails, inspect the attached GitHub Actions log ZIP before proposing or applying another patch.

## Workflows

| Workflow | Purpose |
|---|---|
| `CI - PowerShell Quality Gate` | PSScriptAnalyzer + Pester baseline |
| `Manual - Control Plane Readiness` | Readiness artifact and file-set validation |
| `Manual - Project Health Suite` | Manual project health and diagnostics evidence |
| `Manual - Workflow Governance Audit` | Workflow posture and governance review |
| `Manual - Project Control Report` | Development-first consolidated project control report |
| `Scheduled - Project Control Report` | Scheduled project control report, manually runnable after material changes |
| `Manual - Run Approved PowerShell Script` | Controlled manual script execution, subject to repository guardrails |
| `Manual - Development Maintenance Task` | Development-only approved documentation maintenance with repository commit capability |
| `Manual - Dispatch Standard Validation Sequence` | Manual dispatcher for the standard validation sequence |
| `Manual - Domeneshop MCP Endpoint Validation` | Read-only public Domeneshop MCP endpoint payload validation |
| `Manual - Domeneshop MCP HTTPS Readiness` | Read-only Domeneshop MCP HTTPS/TLS readiness diagnostic |

## Documents

| File | Purpose |
|---|---|
| `docs/01_blueprint.md` | Architecture and operating model |
| `docs/02_playbook_atlas_ai.md` | Atlas-specific execution playbook |
| `docs/03_security_secrets.md` | Secrets, tokens, environment gates, audit model |
| `docs/04_workflow_catalog.md` | GitHub Actions workflow reference |
| `docs/05_android_operations.md` | Android/browser operation instructions |
| `docs/06_adaptation_guide.md` | How to adapt this repo to other projects |
| `docs/07_evidence_audit.md` | Evidence and audit logging model |
| `docs/08_troubleshooting.md` | Failure patterns and corrective actions |
| `docs/09_phase2_operations.md` | Phase 2 hardening and next operating steps |
| `docs/10_phase3_project_adapters.md` | Project adapter model and default health targets |
| `docs/11_phase4_scheduled_project_health.md` | Scheduled project health matrix note |
| `docs/CONTROL_PLANE_COMPLETION_REPORT.md` | Completion status and validated operating state |
| `docs/CONTROL_PLANE_HANDOFF.md` | Handoff instructions and validation order |
| `docs/CONTROL_PLANE_RELEASE_PHASE.md` | Release phase marker and scope boundary |
| `docs/PHASE6_CONTROL_PLANE_RELEASE_CLOSURE.md` | Phase 6 release closure note and validation record |
| `docs/PHASE7_DEVELOPMENT_EXECUTION_ENABLEMENT.md` | Phase 7 development execution enablement record |
| `docs/PHASE8_DOMENESHOP_MCP_READONLY_VALIDATION.md` | Phase 8 Domeneshop MCP read-only validation record |
| `docs/PHASE8_RELEASE_CLOSURE.md` | Phase 8 release closure record |
| `docs/PHASE9_STATUS_ENDPOINT_VALIDATION_DESIGN.md` | Phase 9 status endpoint validation design |
| `docs/PHASE9_OPERATOR_STATUS_VALIDATION_RUNBOOK.md` | Phase 9 operator-local status validation runbook |
| `docs/PHASE9_STATUS_VALIDATION_CLOSURE.md` | Phase 9 status validation closure record |
| `docs/CHATGPT_ORCHESTRATOR_COMMANDS.md` | ChatGPT orchestration commands |
| `docs/CHATGPT_PROJECT_FOLDER_INSTRUCTIONS.md` | Project-folder setup instructions |

## Write gate

Write functions are structurally prepared but paused by default for staging and production.

Keep this repository variable unless a specific staging/production write operation is approved in a separate write-gate phase:

```text
WRITE_TOOLS_ENABLED=false
```

Production writes remain out of scope. Deployment writes remain out of scope. Future staging or production write gates require a separate approved phase.

## Key principle

GitHub should execute the automation. Android should only control it.

That gives Atlas AI a repeatable, logged, auditable, and credential-safe execution layer.
