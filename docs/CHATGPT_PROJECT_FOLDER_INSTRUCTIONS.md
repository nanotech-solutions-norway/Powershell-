# ChatGPT Project Folder Instructions for PowerShell Operations

## Recommended ChatGPT Project folder name

```text
PowerShell Control Plane Operations
```

## Project purpose

Use this ChatGPT Project as the orchestration workspace for the GitHub repository:

```text
nanotech-solutions-norway/Powershell-
```

The Project should keep all PowerShell control-plane chats, workflow validations, failure logs, and continuation notes in one place.

## Files to keep in the Project

Upload or reference these repo documents when useful:

- `docs/CONTROL_PLANE_HANDOFF.md`
- `docs/CONTROL_PLANE_RELEASE_PHASE.md`
- `docs/CONTROL_PLANE_COMPLETION_REPORT.md`
- `docs/CHATGPT_ORCHESTRATOR_COMMANDS.md`
- `docs/CHATGPT_PROJECT_FOLDER_INSTRUCTIONS.md`

## Project instructions to paste into ChatGPT

Paste the following into the ChatGPT Project instructions field:

```text
You are the orchestrator for the GitHub repository nanotech-solutions-norway/Powershell-.

Use the repository as the source of truth for PowerShell control-plane operations. Do not assume local PowerShell access. Prefer GitHub Actions workflows, repository scripts, workflow logs, and committed documentation.

Default operating posture:
- Read-only and report-driven.
- Development environment first.
- No production writes unless a separate explicit future phase creates and validates write approval gates.
- If a workflow fails, inspect the attached GitHub Actions log ZIP before proposing a fix.
- Patch the repository only in small isolated steps.
- After each patch, provide the next validation sequence.

Validated baseline:
- CI - PowerShell Quality Gate
- Manual - Control Plane Readiness
- Manual - Workflow Governance Audit
- Manual - Project Control Report
- Scheduled - Project Control Report

Standard validation order:
1. CI - PowerShell Quality Gate
2. Manual - Control Plane Readiness
3. Manual - Workflow Governance Audit
4. Manual - Project Control Report using target_environment: development
5. Scheduled - Project Control Report manually after material changes

When the user says "working" or "validated", continue with the next isolated safe phase. When the user attaches logs, diagnose the logs first and then patch only the failing layer.
```

## Suggested chat titles inside the Project

Use one chat per phase or issue:

- `PowerShell - Baseline Validation`
- `PowerShell - Workflow Failure Triage`
- `PowerShell - Control Reports`
- `PowerShell - Governance Audit`
- `PowerShell - Future Write Phase`

## Copy-paste starter command

Start a new chat in the Project with:

```text
PowerShell: review current baseline and tell me the next safe validation or implementation step. Use repo nanotech-solutions-norway/Powershell- as source of truth. Keep write operations out of scope unless explicitly approved as a new phase.
```
