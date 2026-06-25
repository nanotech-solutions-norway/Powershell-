# Security Policy — 22:38, 25.06.2026

## Supported operating model

This repository supports controlled PowerShell execution through GitHub Actions.

## Sensitive data policy

Do not commit, print, upload, or expose:

- API keys;
- bearer tokens;
- passwords;
- SSH private keys;
- customer confidential data;
- accounting or bank data;
- private backend traces;
- unredacted raw API payloads.

## Reporting security issues

If a secret is exposed:

1. Disable affected workflow.
2. Rotate the exposed secret.
3. Delete unsafe artifacts/logs where possible.
4. Review commit history.
5. Create a corrective action note.
6. Re-enable only after validation.

## Production operations

Production write operations require:

- protected GitHub Environment;
- required reviewer;
- write mode explicitly set to `production_write_enabled`;
- evidence artifact;
- no exposed secret in logs.
