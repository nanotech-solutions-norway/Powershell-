# Phase 9 — Status Endpoint Validation Design

Date: 03.07.2026

Repository: `nanotech-solutions-norway/Powershell-`

## Status

Phase 9 is opened as a design-only phase.

## Purpose

Phase 9 defines how the Domeneshop MCP `/status.php` endpoint should be validated without exposing authentication material in repository files, workflow logs, artifacts, comments, or ChatGPT messages.

This phase does not add a GitHub Actions workflow for `/status.php` yet. It only records the control design and acceptance gates required before implementation.

## Current context

Phase 8 validated the public read-only endpoint workflow and the HTTPS readiness diagnostic workflow.

The existing PowerShell script already contains optional support for the status endpoint:

```text
scripts/domeneshop/Test-DomeneshopMcpEndpoint.ps1
```

The public workflow intentionally avoids the status endpoint.

## Validation objective

The validation must confirm that `/status.php` is reachable and that the private runtime configuration is present, while keeping the credential value outside repository content and outside logs.

Expected non-sensitive result fields include:

```text
ok
runtime_env_resolved
config_dir_resolved
site_id_count
safe_validation_posture
api_base_url_present
auth_user_present
auth_value_present
```

## Approved design options

### Option A — operator-local validation

The operator runs the status validation from a local trusted PowerShell session.

Control properties:

- credential entered interactively;
- no credential committed;
- no credential printed;
- no GitHub artifact contains the credential;
- only sanitized result fields are copied into evidence.

This is the preferred first validation path.

### Option B — GitHub environment-protected validation

A later implementation may use a protected GitHub environment with a repository or environment credential.

Control properties required before implementation:

- environment approval required before run;
- logs must never print request headers;
- workflow artifact must contain only sanitized result fields;
- workflow must remain development-first until separately approved;
- workflow must not enable provider writes, DNS writes, file mutations, SQL mutations, deployment writes, staging writes, or production writes.

## Acceptance gates before implementation

Before adding a workflow for status validation, all of the following must be true:

1. Phase 8 closure validation has passed.
2. The status endpoint works manually with the operator-provided credential.
3. The expected sanitized fields are known and stable.
4. The workflow design has a log-redaction boundary.
5. The workflow design has an artifact-redaction boundary.
6. The run remains development-first and read-only.

## Explicit non-goals

Phase 9 design does not enable:

- provider write actions;
- DNS changes;
- file upload, overwrite, or delete actions;
- SQL/database mutations;
- staging write authority;
- production write authority;
- runtime secret changes.

## Proposed next step

Run operator-local status validation manually and record only sanitized evidence.

If that passes, the next implementation phase can add a protected, development-only GitHub workflow for status validation.
