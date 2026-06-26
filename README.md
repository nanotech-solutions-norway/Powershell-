# Atlas AI GitHub PowerShell Blueprint — 03:24, 26.06.2026

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

## Recommended operating order

1. Add repository secrets and variables in GitHub.
2. Keep all write/deploy workflows paused until validation is complete.
3. Run `CI - PowerShell Quality Gate`.
4. Run `Manual - Atlas Health Check`.
5. Run `Manual - Atlas Validation`.
6. Run `Manual - Atlas Deployment Preflight`.
7. Enable staging deployment only after health, validation, and preflight pass.
8. Enable production deployment only behind a protected GitHub Environment.

## Workflows

| Workflow | Purpose |
|---|---|
| `CI - PowerShell Quality Gate` | PSScriptAnalyzer + Pester baseline |
| `Manual - Atlas Health Check` | Manual endpoint health check |
| `Manual - Atlas Validation` | Repository and endpoint validation |
| `Manual - Atlas Deployment Preflight` | Deployment-readiness gate without writes |
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

## Write gate

Write functions are structurally prepared but paused by default.

Keep this repository variable unless a specific staging/production write operation is approved:

```text
WRITE_TOOLS_ENABLED=false
```

## Key principle

GitHub should execute the automation. Android should only control it.

That gives Atlas AI a repeatable, logged, auditable, and credential-safe execution layer.
