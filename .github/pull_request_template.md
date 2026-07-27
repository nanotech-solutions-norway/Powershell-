## PowerShell control-plane security change

### Scope
- [ ] Production write operations remain gated by protected environment, required reviewer and explicit write-mode controls.
- [ ] Repository transfer, visibility change and provider activation are excluded.
- [ ] No API keys, bearer tokens, passwords, private keys, customer data, accounting/bank data or raw protected payloads are included.

### Validation
- [ ] Relevant Pester/tests and workflow validation passed.
- [ ] New or modified Actions are pinned to full commit SHAs and use minimum permissions.
- [ ] Logs and evidence artifacts were checked for secret/data exposure.
- [ ] Failure behavior remains fail-closed.
- [ ] Rollback is documented.

### Evidence
- [ ] SECURITY.md requirements are satisfied.
- [ ] Implementation log updated.
- [ ] Unverified settings remain `PENDING_REVIEW`.

Describe security impact, evidence and manual GitHub settings still required.
