# Atlas AI GitHub PowerShell Blueprint — 22:38, 25.06.2026

## Purpose

This blueprint defines how Atlas AI should run PowerShell functions through GitHub using GitHub Actions, PowerShell 7 (`pwsh`), GitHub Secrets, protected environments, and evidence artifacts.

## Architecture

```text
Android / Browser / GitHub App
    → GitHub Actions workflow_dispatch
        → GitHub-hosted runner
            → shell: pwsh
                → scripts/atlas/*.ps1
                    → evidence/*.json
```

## Operating principles

- Android controls execution; GitHub performs execution.
- Scripts are stored in GitHub and executed by GitHub Actions runners.
- Secrets are read from GitHub Secrets, never from committed files.
- Write tools are paused by default.
- Production operations require protected GitHub Environments.
- Each meaningful run should produce a redacted evidence artifact.

## Standard repository structure

```text
.github/workflows/       GitHub Actions workflows
scripts/atlas/           Atlas-specific PowerShell scripts
scripts/common/          Shared execution and evidence functions
tests/                   Pester tests
docs/                    Instructions, blueprint, and playbook
config/                  Example non-secret configuration
evidence/                Runtime evidence output, not committed except .gitkeep
```

## Default execution modes

| Mode | Use |
|---|---|
| `read_only` | Health checks and validation |
| `write_paused` | Write logic exists but must not execute |
| `staging_write_enabled` | Staging-only writes after validation |
| `production_write_enabled` | Production-only writes through protected environment |

## Atlas scope

Use this repository for endpoint health checks, validation, deployment preflight, PowerShell utility execution, evidence packaging, and repeatable controlled automation.

Do not use it to store customer data, accounting data, credentials, private keys, or unredacted backend responses.
