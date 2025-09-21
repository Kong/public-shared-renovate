# Contributing to `Kong/public-shared-renovate`

Thank you for helping improve Kong's shared Renovate presets. This guide explains how to propose new presets, update existing ones, and keep our configuration consistent and safe for broad reuse.

This document is for contributors authoring or modifying presets in this repository. If you are consuming these presets in your repository, start with the [README](README.md) instead.

## Choosing the right directory

Use this decision aid to place new presets correctly. Each directory serves a different purpose.

### [`base/`](base)

- Broadly reusable behavior that many repositories should share
- A stable foundation that other presets (including `default.json`) can build on
- Well-documented policy for a specific ecosystem or domain (for example, Go, GitHub Actions, security)

### [`overrides/`](overrides)

- Minimal, reusable tweaks (for example, add a label or reviewer)
- Parameterized behaviors callable with arguments (for example, two extra labels)
- Not incident-specific and not scoped to a single project/team

### [`helpers/`](helpers)

- Standalone behavior you can drop into any config (for example, create PRs immediately)
- Composable building blocks to reference from `packageRules` or other presets
- Not specific to one project/team and not an incident response

### [`scoped/`](scoped)

- Targets a single product/repo family or team
- Depends on project-specific conventions (module paths, tags, replace directives, and so on)
- Would be confusing or risky if applied org-wide

### [`security-incidents/`](security-incidents)

- Org-wide guardrails that should apply broadly and quickly during incidents
- Slow or gate updates to a risky dependency, temporarily disable updates, block known-bad versions, or force replacements
- Each incident preset must be manually wired into `base/security.json` (CI validates wiring)

## Common guidelines (apply to all presets)

These guidelines standardize how we author presets and reduce the maintenance burden. Please read them before opening a PR.

> [!CAUTION]
> ### 1. No secrets or encrypted tokens in this public repo
>
> - **Why**: This repository is public; any credentials here could be exposed
> - **Do**: Keep all tokens/credentials in private repositories or in Renovate's hosting environment
> - **Don't**: Embed `npmToken`, `hostRules` with credentials, encrypted blobs, or GitHub App private keys here

### 2. One preset per file — keep the scope tight and responsibilities clear

- **Why**: Small, single-purpose presets are easier to reason about, review, and roll back. Broad "kitchen-sink" files create accidental couplings and noisy PRs
- **Do**: Split unrelated concerns (for example, Go module policy vs. GitHub Actions policy) into separate files
- **Don't**: Add project-specific logic to broadly shared presets — move it to `scoped/`

### 3. Strict JSON only — do not use JSON5/JSONC

- **Why**: Renovate expects strict JSON for presets; strict JSON keeps parsing predictable across tools (Renovate, jq, CI) and produces clean diffs
- **Do**: Use `.json` with double-quoted keys/strings and no comments or trailing commas
- **Don't**: Use single quotes, comments, `NaN`/`Infinity`, hex numbers, or unquoted keys. Avoid adding new `.json5` files (a single legacy file exists for compatibility only)

### 4. Document intent in `description` and, when helpful, add reviewer guidance in `prBodyNotes`

- **Why**: Clear context lowers review friction and operational risk
- **Do**: Use `description` (the array of strings) to explain what the preset does and why. Use `prBodyNotes` for checklists, cautions, or links during incidents
- **Formatting requirements for `description` lines**:
  - Keep each string to around 100 characters; hard-wrap longer text into multiple strings. This improves readability in GitHub UIs and keeps diffs tidy
  - Start every string with a single leading space. This maintains consistent alignment with surrounding JSON, creates a clean paragraph look, and avoids accidental Markdown triggers at column 0 (for example, `#`, `>`, or `-`).
  - If you need multiple sections/paragraphs, insert an empty string `""` between sections to create a blank line
- **Example `description` fragment** (note leading spaces and a blank line separator):

  ```json
  {
    "description": [
      " Group non-major updates for Go modules and enable squash automerge on weekdays",
      " Designed for broad reuse across Go repositories",
      "",
      " Applies org-wide defaults; override locally if your project needs a different cadence"
    ]
  }
  ```

- **Example `prBodyNotes` (for security incidents)**:

  ```json
  {
    "prBodyNotes": [
      "---\n> [!CAUTION]\n> Review upstream issue before merging; see the link[...]"
    ]
  }
  ```

### 5. Prefer small, composable rules that are straightforward to review and roll back

- **Why**: Composition beats duplication. Small pieces can be reused, tested, and reverted independently
- **Do**: Create `helpers/` for reusable behaviors and `overrides/` for small tweaks; compose them in `base/` as needed
- **Don't**: Copy-paste large blocks across files — extract and reference a helper or override instead

### 6. Preset ID shape: `Kong/public-shared-renovate//<path-without-extension>`

- **Why**: Extension-less IDs are stable and match Renovate's expectations
- **Do**: Reference presets like `"Kong/public-shared-renovate//base/go"` (omit `.json`)
- **Don't**: Include file extensions or local relative paths in `extends`

### 7. Use short, descriptive, kebab-case file names that reflect subject and intent

- **Why**: Predictable names improve discoverability and grep-ability
- **Do**: `github-actions.json`, `go.json`, `labels.json`, `tj-actions-changed-files.json`
- **Don't**: Use vague or overly long names; avoid spaces and CamelCase

## Preset authoring tips

- Write minimal diffs: keep ordering stable (for example, alphabetize arrays when reasonable) so churn is low
- Be conservative by default: prefer grouping, `minimumReleaseAge`, or review gates unless there's a clear need for speed
- Parameterize where appropriate: accept arguments via `({{arg0}},{{arg1}})` rather than creating near-duplicates; forward args with `({{args}})` from wrapper presets
- Avoid org‑specific assumptions in shared presets: place project/team-specific logic in [`scoped/`](scoped).
- Cross-link related presets in `description` so reviewers have context

## Parameterized presets (`{{arg}}`)

- You can create presets that accept up to N arguments via the path suffix syntax: `//overrides/labels(renovate,ci)`
- Use placeholder tokens `{{arg0}}`, `{{arg1}}`, … inside the preset. Use `{{args}}` to pass through all arguments to a nested preset
- Validate empty args: If an arg may be omitted, ensure the resulting JSON still makes sense (for example, `"labels": ["dependencies", "{{arg0}}", "{{arg1}}"]` is acceptable by Renovate even if arg slots are empty strings)
- Keep argument order intuitive and document it in `description` with examples

## Descriptions and reviewer guidance

- `description`: Provide a succinct, human-oriented explanation; prefer full sentences. Use an array of short strings (each becomes a line)
- `prBodyNotes`: Use for checklists, cautions, or links that should appear in PR bodies. Useful for incident presets to guide reviewers
- Keep both free of implementation noise; focus on intent, scope, and how to act

## Security and privacy

- Never embed secrets (tokens, passwords, private keys, encrypted blobs)
- Prefer pinning GitHub Actions by commit SHA in consumers; presets here should encourage safe defaults
- Use labels like `security/caution-advised` in incident presets to surface risk

## Testing and validation

- Validate JSON locally (your editor or a linter should catch syntax issues). Presets must be strict JSON
- Sanity-check with Renovate: reference your new preset in a throwaway repo or a local renovate-config validator/dry-run if available
- For incident presets, ensure `base/security.json` extends the new preset; CI will fail if wiring is missing

## Security incident response presets

When a supply‑chain incident or other security event requires immediate guardrails, use the shared incident presets to quickly enforce safer behavior across all repositories.

> [!NOTE]
> These presets are intended to be temporary and can be removed once upstream issues are resolved

### Process to add a new incident preset

1. Create a new preset JSON file under [`security-incidents/`](security-incidents). Keep it narrowly scoped to the affected dependency/packages
2. Add human‑readable context in `description`/`prBodyNotes` so reviewers know why and how to proceed
3. Edit [base/security.json](base/security.json) and add your new preset to its `extends` array using the full preset ID: `Kong/public-shared-renovate//security-incidents/<subpath-without-.json>`
4. Open a PR. The CI workflow will verify that [base/security.json](base/security.json) extends all presets in `security-incidents/`

> [!TIP]
> 🌟 Keep these presets conservative and review‑friendly — prefer minimal, targeted rules over broad changes

### Referencing an incident preset directly (rare)

Repositories typically do not consume incident presets directly; they are composed into `base/security.json`, which consumer repositories extend. If you must reference a preset directly (rare):

```json
{
  "extends": ["Kong/public-shared-renovate//security-incidents/<subpath>"]
}
```

### Directory layout

Use this structure so presets are easy to find, review, and compose:

```
security-incidents/
  github-actions/
    tj-actions-changed-files.json
  npm/
  go/
  docker/
  misc/
```

#### Guidelines

- **Location**: put every incident preset under `security-incidents/`
- **Nesting by ecosystem**: group under a top‑level directory such as `github-actions/`, `npm/`, `go/`, `docker/`, or `misc/` (create others as needed)
- **File naming**: use short, descriptive, kebab-case names that reflect the subject and intent, e.g., `tj-actions-changed-files.json`, `npm-leftpad-block.json`
- **One preset per file**: keep each file narrowly scoped to a single incident or mitigation
- **Format**: `.json` only with strict JSON syntax (no JSON5, no comments, no trailing commas)
- **Preset ID shape**: `Kong/public-shared-renovate//<path-without-.json>` (i.e. `Kong/public-shared-renovate//security-incidents/github-actions/tj-actions-changed-files`)
- **Documentation**: include concise `description` and, when applicable, reviewer guidance in `prBodyNotes` so the rationale and next steps are clear
- **Wiring**: after creating a file, manually add its preset ID to `base/security.json` in the `extends` array (see "Process" above). The CI check will validate this wiring in PRs

### Common patterns

#### Gate risky dependencies with a higher `minimumReleaseAge` and review guardrails

Use this pattern to slow down adoption of a dependency while an incident is investigated or confidence builds. It adds a clear caution label, enforces a `minimumReleaseAge` before PRs are created, and surfaces reviewer guidance via `prBodyNotes` (see [`security-incidents/github-actions/tj-actions-changed-files.json`](security-incidents/github-actions/tj-actions-changed-files.json)).

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["owner/name"],
      "addLabels": ["security/caution-advised"],
      "minimumReleaseAge": "30 days",
      "prBodyNotes": [
        "---\n> [!CAUTION]\n> ...rationale, checklist, links..."
      ]
    }
  ]
}
```

#### Temporarily disable updates for a dependency while waiting for a fix

Apply a narrow, temporary block for a specific package to stop Renovate from proposing new versions until an upstream fix is available. Remember to remove this once the issue is resolved to resume updates.

```json
{
  "packageRules": [
    { "matchPackageNames": ["owner/name"], "enabled": false }
  ]
}
```

#### Block versions using allowedVersions so Renovate won't cross beyond a safe range

Constrain updates to a safe window while a bad version is investigated or until a fixed release is available. Use standard semver ranges in `allowedVersions` (see [Renovate configuration options — allowedVersions](https://docs.renovatebot.com/configuration-options/#allowedversions)).

```json
{
  "packageRules": [
    { "matchPackageNames": ["owner/name"], "allowedVersions": "<1.2.3" }
  ]
}
```

#### Force a replacement (migration or emergency downgrade/upgrade)

Redirect consumers to a different package or a specific safe version when the original is unsafe or deprecated. Configure `replacementName` and optionally `replacementVersion` to enforce the migration or pin (see [replacementName](https://docs.renovatebot.com/configuration-options/#replacementname) and [replacementVersion](https://docs.renovatebot.com/configuration-options/#replacementversion)).

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["owner/name"],
      "replacementName": "new/package",
      "replacementVersion": "1.2.3"
    }
  ]
}
```

### Maintenance and cleanup

- Keep presets conservative and narrowly scoped
- Prefer short‑lived mitigations; remove once upstream issues are resolved
- If mitigation becomes permanent policy, migrate its logic to [`base/`](base) (and leave a temporary alias or deprecation path if needed)

## Deprecating or moving presets

- When deprecating a preset, add a clear notice explaining why, the replacement (if any), and when it will be removed
- When moving a preset, leave a temporary compatibility alias at the old path with a deprecation notice and pointer to the new ID
- Update [README](README.md) and any other docs that reference the old path
- Coordinate with [CODEOWNERS](CODEOWNERS) if ownership or responsibility changes
- Keep deprecation aliases short-lived and remove them once consumers have migrated

### Example: temporary alias at the old path (compatibility shim)

When moving a preset, create a small file at the old path that points to the new preset and clearly communicates the deprecation and removal timeline.

**File at the old path (`go.json`)**:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "description": [
    " [MOVED] This preset has been relocated to 'base/go.json'. It is now an alias that extends",
    " the new location to preserve backwards compatibility"
  ],
  "extends": ["Kong/public-shared-renovate//base/go"],
  "prBodyNotes": [
    "---\n> [!WARNING]\n> #### Moved preset: `Kong/public-shared-renovate:go`\n>\n> This preset has been relocated to `Kong/public-shared-renovate//base/go`. Current preset is a temporary compatibility alias to preserve backwards compatibility\n>\n> #### Action required\n>\n> Update your Renovate config to extend directly from `Kong/public-shared-renovate//base/go`\n>\n> #### Examples\n>\n> Before (any of the following):\n>\n> ```json\n> [\n>   { \"extends\": [\"Kong/public-shared-renovate:go\"] },\n>   { \"extends\": [\"Kong/public-shared-renovate:go.json\"] },\n>   { \"extends\": [\"local>Kong/public-shared-renovate:go\"] },\n>   { \"extends\": [\"github>Kong/public-shared-renovate:go\"] }\n> ]\n> ```\n>\n> After:\n>\n> ```json\n> { \"extends\": [\"Kong/public-shared-renovate//base/go\"] }\n> ```\n>\n> #### Timeline\n>\n> This compatibility alias is temporary and is scheduled for removal in **January 2026**"
  ]
}
```

**PR body note content (rendered in Renovate PRs)**:

> [!WARNING]
> #### Moved preset: `Kong/public-shared-renovate:go`
>
> This preset has been relocated to `Kong/public-shared-renovate//base/go`. Current preset is a temporary compatibility alias to preserve backwards compatibility
>
> #### Action required
>
> Update your Renovate config to extend directly from `Kong/public-shared-renovate//base/go`
>
> #### Examples
>
> Before (any of the following):
>
> ```json
> [
>   { "extends": ["Kong/public-shared-renovate:go"] },
>   { "extends": ["Kong/public-shared-renovate:go.json"] },
>   { "extends": ["local>Kong/public-shared-renovate:go"] },
>   { "extends": ["github>Kong/public-shared-renovate:go"] }
> ]
> ```
>
> After:
>
> ```json
> { "extends": ["Kong/public-shared-renovate//base/go"] }
> ```
>
> #### Timeline
>
> This compatibility alias is temporary and is scheduled for removal in **January 2026**

## Preset IDs and naming reference

- **Format**: `Kong/public-shared-renovate//<path-without-.json>`

- **Examples**:
   - `Kong/public-shared-renovate//base/go`
   - `Kong/public-shared-renovate//overrides/labels`
   - `Kong/public-shared-renovate//helpers/immediately`
   - `Kong/public-shared-renovate//security-incidents/github-actions/tj-actions-changed-files`

## PR checklist

Before opening a PR:

- [ ] Chose the correct directory (see [Choosing the right directory](#choosing-the-right-directory))
- [ ] JSON is strict and valid (`.json` only; no comments or trailing commas)
- [ ] `description` explains intent; `prBodyNotes` added if reviewer guidance is needed
- [ ] File name is short, descriptive, kebab-case
- [ ] Parameterized presets document arguments with examples
- [ ] For security incidents: [`base/security.json`](base/security.json) updated to extend the new preset
- [ ] Backward-compatibility alias added if moving/renaming
- [ ] Root [README](README.md) updated if you add user-facing capabilities or move presets

## FAQ

### Why strict JSON instead of JSON5 or JSONC?

Using strict JSON keeps parsing predictable across Renovate, jq, and CI tools, avoids editor and linter inconsistencies, and yields smaller, cleaner diffs without comments or permissive syntax; it also matches what Renovate expects when loading presets. Therefore, presets in this repository must use `.json` only, and JSON5/JSONC features such as comments, trailing commas, single quotes, unquoted keys, hex numbers, or NaN/Infinity are not allowed. A single legacy file `base/gateway.json5` remains only for compatibility; do not add more.

### Why omit the file extension in `extends`?

Renovate resolves preset IDs without file extensions, and extension-less IDs stay stable if formats ever change while preventing mismatches between `.json` and `.json5`. Therefore, when you reference presets in `extends`, always omit the `.json` extension.
