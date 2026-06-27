# ChatGPT Orchestrator Commands for PowerShell Operations

Repository: `nanotech-solutions-norway/Powershell-`

## Execution model

ChatGPT should be used as an orchestrator for this repository. ChatGPT does not need to run local PowerShell directly. Instead, it should guide, inspect, update, and trigger GitHub-controlled workflows or provide the exact manual GitHub Actions steps.

Use this model:

1. User gives a short activation command in the ChatGPT Project.
2. ChatGPT identifies the matching workflow, script, or document in the repository.
3. ChatGPT either updates repo files or gives the exact GitHub Actions workflow to run.
4. User validates the workflow result.
5. ChatGPT proceeds only after validation.

## Simple activation commands

Use these commands in a ChatGPT Project chat.

### Quality gate

```text
PowerShell: run quality gate instructions
```

Expected action:

- Tell the user to run `Actions -> CI - PowerShell Quality Gate -> Run workflow`.
- If logs are attached, inspect them and patch the repo if needed.

### Readiness

```text
PowerShell: run control plane readiness
```

Expected action:

- Tell the user to run `Actions -> Manual - Control Plane Readiness -> Run workflow`.
- Expected artifact: `control-plane-readiness-report`.

### Governance audit

```text
PowerShell: run governance audit
```

Expected action:

- Tell the user to run `Actions -> Manual - Workflow Governance Audit -> Run workflow`.
- Use `fail_on_finding: false` first.
- Expected artifact: `workflow-governance-report`.

### Project control report

```text
PowerShell: run project control report
```

Expected action:

- Tell the user to run `Actions -> Manual - Project Control Report -> Run workflow`.
- Use `target_environment: development` first.
- Expected artifacts: `project-control-raw-evidence` and `project-control-report`.

### Scheduled control report

```text
PowerShell: run scheduled control report manually
```

Expected action:

- Tell the user to run `Actions -> Scheduled - Project Control Report -> Run workflow`.
- Expected artifacts: `scheduled-project-control-raw-evidence` and `scheduled-project-control-report`.

### Diagnose failed run

```text
PowerShell: diagnose failed workflow log
```

Expected action:

- User attaches GitHub Actions log ZIP.
- ChatGPT inspects the log.
- ChatGPT identifies root cause, patches repo if needed, and gives the next validation sequence.

### Continue next phase

```text
PowerShell: continue next recommended phase
```

Expected action:

- ChatGPT checks the current validated baseline.
- ChatGPT proposes or implements the next isolated phase.
- Production writes remain outside scope unless explicitly approved in a separate phase.

## Default validation response format

After each user validation, ChatGPT should respond with:

```text
Confirmed. Proceeding with the next isolated phase.
```

Then it should implement only the next safe, bounded step.

## Safety posture

- Use development first.
- Keep workflow changes small.
- Keep control reports read-only unless a future write phase is explicitly created.
- Treat attached logs as the source of truth when workflows fail.
