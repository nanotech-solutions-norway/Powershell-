# Phase 10 — Protected Status Validation Workflow Design

Date: 03.07.2026

Repository: `nanotech-solutions-norway/Powershell-`

## Status

Phase 10 is opened as a design-only phase.

No active GitHub Actions workflow is added in this phase.

## Purpose

Phase 10 defines the control pattern for a later protected GitHub workflow that validates the Domeneshop MCP status endpoint while keeping credential material outside repository files, logs, artifacts, comments, and chat messages.

## Starting point

Phase 9 operator-local validation passed.

The status endpoint can therefore be considered functionally valid, but a protected GitHub workflow is not yet approved.

## Design objective

A future workflow may validate the status endpoint only if it can satisfy these controls:

1. It runs in the development environment first.
2. It requires an explicit operator start.
3. It does not print request headers.
4. It does not print credential values.
5. It writes only sanitized fields to artifacts.
6. It does not change runtime files.
7. It does not perform provider operations.
8. It does not perform DNS operations.
9. It does not perform hosting file operations.
10. It does not perform SQL or database operations.
11. It does not grant staging or production authority.

## Required sanitized artifact fields

A future workflow artifact may contain only non-sensitive status facts such as:

```text
ok
runtime_env_resolved
config_dir_resolved
site_id_count
safe_validation_posture
api_base_url_present
auth_user_present
auth_value_present
write_tools_enabled
dry_run_default
operator_approval_required
```

## Required blocked artifact fields

A future workflow artifact must not contain:

```text
request_headers
credential_values
raw_runtime_file_content
provider_api_values
full_environment_dump
server_secret_values
```

## Proposed workflow name

```text
Manual - Domeneshop MCP Protected Status Validation
```

## Proposed artifact name

```text
domeneshop-mcp-protected-status-validation-report
```

## Implementation prerequisites

Before an active workflow is added, all of the following must be validated:

1. Phase 9 closure has passed the standard validation sequence.
2. The development environment protection model is reviewed.
3. The credential source is configured outside repository content.
4. The script output is verified to be sanitized.
5. The artifact content is verified to be sanitized.
6. Failure handling is limited to sanitized status codes and error classifications.

## Acceptance criteria for a later implementation phase

The later implementation phase passes only if:

1. The workflow runs manually in development.
2. The workflow succeeds without printing sensitive values.
3. The artifact contains only the approved sanitized field set.
4. The workflow does not modify repository files.
5. The workflow does not modify remote endpoint state.
6. The standard validation sequence passes afterward.

## Out of scope

Phase 10 does not implement:

- an active status workflow;
- provider writes;
- DNS changes;
- hosting file operations;
- SQL/database operations;
- staging enablement;
- production enablement;
- runtime credential changes.

## Next safe step

Run the standard validation sequence after this design document is added.

If that passes, the next phase may implement the protected status workflow under the controls defined here.
