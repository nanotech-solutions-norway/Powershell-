# ChatGPT Python Orchestrator Commands — 14:31, 27.06.2026

## Command: Python: run quality gate instructions

Use when the user wants the baseline Python validation run.

Action for ChatGPT:

1. Instruct the user to open GitHub Actions.
2. Run `CI - PowerShell Quality Gate` first.
3. Run `CI - Python Quality Gate`.
4. Ask for the workflow result and, if failed, the GitHub Actions log ZIP or relevant artifact.
5. Do not propose code changes until logs or artifacts have been inspected.

Expected result:

- Workflow succeeds.
- Artifact `python-quality-test-results` is available.

## Command: Python: run approved script

Use when the user wants to execute a repository-approved Python script.

Action for ChatGPT:

1. Confirm the script exists in the documented allowlist.
2. Instruct the user to run `Manual - Python Run Script`.
3. Select `script_name=hello_control_plane` for foundation validation.
4. Select `target_environment=development`.
5. Select `run_mode=read_only`.
6. Inspect `python-approved-script-output` after completion.

Expected result:

- Workflow succeeds.
- Artifact contains `approved-script-run-summary.json`, `hello-control-plane-output.json`, and `stdout.txt`.

## Command: Python: debug failed run

Use when any Python workflow fails.

Action for ChatGPT:

1. Request the failed workflow log ZIP or uploaded artifacts.
2. Run `Manual - Python Debug` with `target_environment=development`.
3. Start with `diagnostic_level=baseline`.
4. Escalate to `diagnostic_level=dependencies` or `diagnostic_level=repository` only when needed.
5. Patch only the smallest isolated layer after evidence is reviewed.

Expected result:

- Artifact `python-debug-artifacts` is available.
- No secrets are printed.

## Command: Python: inspect Python workflow logs

Use when the user uploads a GitHub Actions log ZIP.

Action for ChatGPT:

1. Read the log ZIP.
2. Identify failing workflow, job, and step.
3. Separate dependency failures, syntax failures, test failures, GitHub Actions syntax failures, and policy guardrail failures.
4. Recommend one minimal patch or a no-change rerun if the issue is transient.
5. Provide the next validation sequence.

## Command: Python: add new approved script

Use when the user wants a new Python script executable through GitHub Actions.

Action for ChatGPT:

1. Create the script under `python/scripts/`.
2. Add tests under `python/tests/`.
3. Add the script to `APPROVED_SCRIPTS` in `python/tools/approved_scripts.py`.
4. Add the same script key to the `manual-python-run-script.yml` workflow_dispatch choices.
5. Keep the script development-only unless a later approved phase adds stronger gates.
6. Run the full validation sequence.

Minimum validation:

1. `CI - PowerShell Quality Gate`
2. `CI - Python Quality Gate`
3. `Manual - Python Debug`
4. `Manual - Python Run Script`

## Command: Python: continue next safe phase

Use when the foundation has passed all validations.

Action for ChatGPT:

1. Review current artifacts and latest workflow status.
2. Confirm no production write capability was introduced.
3. Propose the smallest next phase.
4. Keep write-capable Python operations deferred unless explicitly approved.
5. Provide exact workflow inputs for the next validation run.

## Foundation validation order

1. `CI - PowerShell Quality Gate`
2. `CI - Python Quality Gate`
3. `Manual - Python Debug`
   - `target_environment=development`
   - `diagnostic_level=baseline`
4. `Manual - Python Run Script`
   - `script_name=hello_control_plane`
   - `target_environment=development`
   - `run_mode=read_only`
5. `Manual - Control Plane Readiness`
6. `Manual - Project Control Report`
   - `target_environment=development`

## Failure rule

When a Python workflow fails, ChatGPT must inspect the GitHub Actions log ZIP or uploaded artifact before proposing a repository patch.
