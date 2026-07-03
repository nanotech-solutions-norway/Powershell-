# Phase 8 — Production Write-Gate Enablement — 21:11, 03.07.2026

Repository: `nanotech-solutions-norway/Powershell-`

Status: implemented and validated.

## Purpose

Phase 8 enables a production-gated workflow-dispatch path for approved production operations, deployment markers, and approved external endpoint calls.

## Validated prerequisite stated by operator

The operator manually validated the Phase 7 sequence before Phase 8 implementation:

1. `CI - PowerShell Quality Gate`
2. `Manual - Development Maintenance Task` with `dry_run: true`
3. `Manual - Development Maintenance Task` with `dry_run: false`
4. `CI - PowerShell Quality Gate` after the workflow-generated commit
5. Gmail label `GitHub` review

## Phase 8 validation record

The operator confirmed the Phase 8 validation sequence as working after implementation:

1. `CI - PowerShell Quality Gate`
2. `Manual - Production Operation Task` using `dry_run: true`
3. `Manual - Production Operation Task` using `dry_run: false` and task `append_production_log`
4. `CI - PowerShell Quality Gate` after the workflow-generated commit
5. Gmail label `GitHub` review

Validation classification: `validated_by_operator`.

## Implemented files

- `.github/workflows/manual-production-operation.yml`
- `scripts/common/Invoke-ProductionOperationTask.ps1`
- `tests/ProductionOperation.Tests.ps1`
- `docs/PHASE8_PRODUCTION_WRITE_GATE_ENABLEMENT.md`

## Capability added

The new workflow `Manual - Production Operation Task` can be started with `workflow_dispatch` and runs in the GitHub `production` environment.

Approved tasks:

- `append_production_log`
- `record_deployment_marker`
- `call_approved_external_endpoint`

Required scope:

- `target_environment: production`
- `execution_mode: production_change_enabled`
- `dry_run: true` for validation
- `dry_run: false` for approved execution

## External endpoint boundary

External endpoint changes are enabled only through the named task `call_approved_external_endpoint` and endpoint alias `primary_external_endpoint`.

The endpoint URL must be supplied by the production environment secret `PRODUCTION_EXTERNAL_ENDPOINT_URL`.

The optional bearer token must be supplied by the production environment secret `PRODUCTION_EXTERNAL_ENDPOINT_BEARER_TOKEN`.

The workflow does not modify secrets, GitHub environments, or repository environment settings.

## Deployment boundary

Deployment writes are represented by the approved task `record_deployment_marker`, which records a deployment marker in `docs/PRODUCTION_OPERATIONS_LOG.md`.

This phase does not add arbitrary deployment scripts. Provider-specific deployment scripts must be added as separate approved tasks in future patches.

## Guardrails

- The workflow is bound to the GitHub `production` environment.
- Workflow permissions are limited to `contents: write` and `actions: read`.
- The script requires GitHub Actions runtime.
- The script accepts only `TargetEnvironment=production`.
- The script accepts only `ExecutionMode=production_change_enabled`.
- External endpoint calls require HTTPS.
- External endpoint URL is loaded from a secret, not from free-text workflow input.
- Evidence is uploaded as `production-operation-evidence`.

## Standard validation sequence after future production-operation changes

1. `CI - PowerShell Quality Gate`
2. `Manual - Production Operation Task` using `dry_run: true`
3. `Manual - Production Operation Task` using `dry_run: false` and the approved task being changed
4. `CI - PowerShell Quality Gate` after any workflow-generated commit
5. Gmail label `GitHub` review after the validation runs

## Failure rule

If any workflow fails, inspect the attached GitHub Actions log ZIP before proposing or applying another patch.
