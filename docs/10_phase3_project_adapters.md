# Phase 3 Project Health Adapters — 26.06.2026

## Purpose

Phase 3 extends the validated Atlas AI PowerShell model into reusable project health checks while keeping all write operations paused.

## Added files

| File | Purpose |
|---|---|
| `scripts/projects/Invoke-ProjectHealthCheck.ps1` | Project adapter router |
| `.github/workflows/manual-project-health-check.yml` | Manual project health workflow |
| `tests/Atlas.Tests.ps1` | Expanded tests for adapters and workflow guardrails |

## Supported adapters

| Project | Default base URL | Default path | Default check mode |
|---|---|---|---|
| `atlas` | `https://www.atlas-ai.no` | `/` | `dns` |
| `solarex` | `https://nanotech-solutions-norway.github.io/SolarEX-Final-recreate/` | `/` | `http` |
| `domeneshop` | `https://forms.nanotech-solutions.com` | `/solarex_forms/health.php` | `http` |
| `conta` | `https://mcp.atlas-ai.no` | `/health` | `http` |
| `wix` | `https://www.atlas-ai.no` | `/` | `dns` |

## Operating notes

- Atlas and Wix currently default to DNS mode because `atlas-ai.no` does not yet have a published homepage.
- SolarEX defaults to HTTP mode because the GitHub Pages site should return a web response.
- Domeneshop defaults to the existing SolarEX forms health endpoint.
- Conta defaults to `https://mcp.atlas-ai.no/health`; override the path if the deployed bridge uses a different health route.

## Manual workflow usage

Run:

```text
Actions → Manual - Project Health Check → Run workflow
```

Recommended first checks:

```text
project: atlas
check_mode: auto
fail_on_unhealthy: false
```

```text
project: solarex
check_mode: auto
fail_on_unhealthy: false
```

```text
project: domeneshop
check_mode: auto
fail_on_unhealthy: false
```

## Write policy

No project adapter enables writes. All checks run with:

```text
WriteMode = read_only
```

Keep repository variable:

```text
WRITE_TOOLS_ENABLED=false
```

until a separate, reviewed Phase 4 write-control design is approved.
