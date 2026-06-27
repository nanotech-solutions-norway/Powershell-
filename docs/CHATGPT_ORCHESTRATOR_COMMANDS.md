# ChatGPT Orchestrator Commands for PowerShell Operations — 15:20, 27.06.2026

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

### Project health suite

```text
PowerShell: run project health suite
```

Expected action:

- Tell the user to run `Actions -> Manual - Project Health Suite -> Run workflow`.
- Use development/reporting posture first.
- Review project-specific health and diagnostics evidence before proposing any patch.

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

### Release closure

```text
PowerShell: close release / handoff phase
```

Expected action:

- Inspect committed release and handoff documentation first.
- Record the validated workflow chain and run references.
- Patch only release closure / handoff documentation and narrowly required documentation tests.
- Keep production writes, deployment writes, write tools, secrets, GitHub environments, and external endpoints out of scope.

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
- Production writes remain out of scope unless explicitly approved in a separate phase.
- Deployment writes remain out of scope unless explicitly approved in a separate phase.
- Future write gates require a separate approved phase.

## Default validation response format

After each user validation, ChatGPT should respond with:

```text
Confirmed. Proceeding with the next isolated phase.
```

Then it should implement only the next safe, bounded step.

## Phase 6 validation sequence

After Phase 6 release closure documentation changes, use this validation sequence:

1. `CI - PowerShell Quality Gate`
2. `Manual - Control Plane Readiness`
3. `Manual - Workflow Governance Audit` with `fail_on_finding: false`
4. `Manual - Project Control Report` with `target_environment: development`
5. `Scheduled - Project Control Report` manually

If any workflow fails, diagnose the attached GitHub Actions log ZIP before proposing or applying another patch.

## Safety posture

- Use development first.
- Keep workflow changes small.
- Keep control reports read-only unless a future write phase is explicitly created.
- Treat attached logs as the source of truth when workflows fail.
- production writes remain out of scope
- deployment writes remain out of scope
- future write gates require a separate approved phase
