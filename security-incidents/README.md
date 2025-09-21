# Security incident presets

Presets in this directory provide fast, centralized mitigations in response to supply‑chain or ecosystem incidents (for example, malicious releases, compromised packages, or high‑risk regressions). They are designed to be narrow, reviewable, and temporary.

> [!CAUTION]
> #### Adding or changing a preset here does not automatically apply it across repositories.
>
> A maintainer must manually wire each preset into [base/security.json](../base/security.json). A CI workflow validates that every preset in this directory is referenced there.

## Authoring and wiring guidance

For the full process, directory layout, common patterns, and maintenance expectations, see the contributor guide: [CONTRIBUTING.md — Security incident response presets](../CONTRIBUTING.md#security-incident-response-presets)
