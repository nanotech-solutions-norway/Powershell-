# Adaptation Guide for Other Projects — 22:38, 25.06.2026

## Purpose

This repository is Atlas-first, but the pattern is reusable for SolarEX, Conta Bridge/MCP, Domeneshop, Wix validation, ROI calculators, and other projects.

## Adaptation steps

1. Define project key, for example `solarex`, `conta`, or `domeneshop`.
2. Create `scripts/<project>/`.
3. Copy the Atlas health and validation pattern.
4. Replace base URLs and secret names.
5. Add Pester tests.
6. Add a manual workflow.
7. Keep writes paused until validation is complete.
8. Use protected environments for production.

## Naming pattern

| Type | Pattern | Example |
|---|---|---|
| Script | `Verb-ProjectNoun.ps1` | `Get-SolarEXEndpointHealth.ps1` |
| Workflow | lowercase hyphenated | `manual-solarex-health-check.yml` |
| Secret | uppercase snake case | `SOLAREX_API_TOKEN` |
| Evidence | timestamped JSON | `solarex-health-20260625-2238.json` |

## Project warnings

| Project | Warning |
|---|---|
| Atlas AI | Do not expose customer/private data |
| SolarEX | Avoid exposing backend/admin endpoints unnecessarily |
| Conta Bridge/MCP | Do not expose accounting, customer, or bank details |
| Domeneshop | Keep API/SFTP credentials in secrets only |
| Wix | Keep writes governed and staged |
