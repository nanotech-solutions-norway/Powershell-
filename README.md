# Atlas AI GitHub PowerShell Blueprint — 26.06.2026

This repository is the reusable **PowerShell execution and automation control layer** for Atlas AI and other NanoTech Solutions Norway projects.

It now also includes a foundation **Python control-plane layer** for development-only Python execution, testing, debugging, and validation through GitHub Actions.

Primary operating purpose:

- run controlled PowerShell scripts through **GitHub Actions** rather than Android-local execution;
- run controlled Python quality, debug, and approved-script workflows through **GitHub Actions** rather than assuming local Python access;
- provide a browser-operated execution model suitable for Android, desktop, and tablet use;
- separate scripts, secrets, workflows, validation, audit logs, and deployment gates;
- support Atlas AI first, while keeping the pattern adaptable to SolarEX, Conta Bridge/MCP, Domeneshop tooling, website QA, and future platform modules.

## Repository identity

| Item | Value |
|---|---|
| GitHub repository | `nanotech-solutions-norway/Powershell-` |
| Main target project | Atlas AI |
| Execution model | GitHub Actions + PowerShell 7 (`pwsh`) + Python |
| Interactive model | GitHub Codespaces where needed |
| Security posture | Read-first, write-paused by default, environment-gated |
| Mobile control | Android browser or GitHub app triggers Actions manually |

## Recommended operating order

1. Add repository secrets and variables in GitHub.
2. Keep all write/deploy workflows paused until validation is complete.
3. Run `CI - PowerShell Quality Gate`.
4. Run `CI - Python Quality Gate` when Python files or Python workflows are in scope.
5. Run `Manual - Python Debug` for Python diagnostics when needed.
6. Run `Manual - Python Run Script` only for approved scripts and development-only execution.
7. Run `Manual - Atlas Health Check`.
8. Run `Manual - Atlas Validation`.
9. Run `Manual - Atlas Deployment Preflight`.
10. Run `Manual - Project Health Check` for each project adapter.
11. Run `Scheduled - Project Health Matrix` manually once.
12. Enable staging deployment only after health, validation, and preflight pass.
13. Enable production deployment only behind a protected GitHub Environment.

## Workflows

| Workflow | Purpose |
|---|---|
| `CI - PowerShell Quality Gate` | PSScriptAnalyzer + Pester baseline |
| `CI - Python Quality Gate` | Ruff + mypy + pytest baseline |
| `Manual - Python Debug` | Sanitized Python diagnostics and artifact upload |
| `Manual - Python Run Script` | Development-only approved Python script execution |
| `Manual - Atlas Health Check` | Manual Atlas DNS/HTTP health check |
| `Manual - Atlas Validation` | Repository and endpoint validation |
| `Manual - Atlas Deployment Preflight` | Deployment-readiness gate without writes |
| `Manual - Project Health Check` | Project adapter health check for Atlas, SolarEX, Domeneshop, Conta, Wix |
| `Scheduled - Project Health Matrix` | Scheduled matrix health evidence for all project adapters |
| `Manual - Run Approved PowerShell Script` | Controlled manual script execution |
| `Scheduled - Atlas Health Evidence` | Daily scheduled health evidence |

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
| `docs/PYTHON_CONTROL_PLANE.md` | Python execution, testing, debug, and governance layer |
| `docs/CHATGPT_PYTHON_ORCHESTRATOR_COMMANDS.md` | ChatGPT command patterns for Python operations |

## Write gate

Write functions are structurally prepared but paused by default.

Keep this repository variable unless a specific staging/production write operation is approved:

```text
WRITE_TOOLS_ENABLED=false
```

## Key principle

GitHub should execute the automation. Android should only control it.

That gives Atlas AI a repeatable, logged, auditable, and credential-safe execution layer.
