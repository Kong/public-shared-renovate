# Contributing to `Kong/public-shared-renovate`

Thank you for helping improve Kong's shared Renovate presets. This guide explains how to propose new presets, update existing ones, and keep our configuration consistent and safe for broad reuse.

This document is for contributors authoring or modifying presets in this repository. If you are consuming these presets in your repository, start with the [README](README.md) instead.

## Common guidelines (apply to all presets)

These guidelines standardize how we author presets and reduce the maintenance burden. Please read them before opening a PR.

1. **No secrets or encrypted tokens in this public repo**

   * **Rationale**: This repository is public. Any secrets or credentials here would be exposed
   * **Requirements**: Keep all tokens/credentials in private repositories or in Renovate’s hosting environment
   * **Pitfalls to avoid**: Do not embed `npmToken`, `hostRules` with credentials, encrypted blobs, or GitHub App private keys

2. **One preset per file — keep the scope tight and responsibilities clear**

   * **Rationale**: Small, single-purpose presets are easier to reason about, review, and roll back. Broad files create accidental couplings and noisy PRs
   * **Requirements**: Split unrelated concerns (e.g. Go module policy vs. GitHub Actions policy) into separate files
   * **Pitfalls to avoid**: Do not add project-specific logic to broadly shared presets — move it to `scoped/`

3. **Strict JSON only — do not use JSON5/JSONC**

   * **Rationale**: Renovate expects strict JSON; strict JSON keeps parsing predictable across tools and produces clean diffs
   * **Requirements**: Use `.json` with double-quoted keys/strings and no comments or trailing commas
   * **Pitfalls to avoid**: Do not use single quotes, comments, `NaN`/`Infinity`, hex numbers, or unquoted keys. Do not add new `.json5` files (a single legacy file exists only for compatibility)

4. **Document intent in `description` and, when helpful, add reviewer guidance in `prBodyNotes`**

   * **Rationale**: Clear context lowers review friction and reduces operational risk
   * **Requirements**: Use `description` (the array of strings) to explain what the preset does and why. Use `prBodyNotes` for checklists, cautions, or links during incidents. Keep both free of implementation noise; focus on intent, scope, and reviewer action
   * **Formatting rules for `description`**:

      * Keep each string around 100 characters; hard-wrap longer text
      * Start every string with a single leading space for alignment and to avoid Markdown triggers at column 0
      * Insert an empty string `""` to create blank lines between sections

   * **Example `description` fragment**:

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

   * **Example `prBodyNotes` (for security incidents)**:

     ```json
     {
       "prBodyNotes": [
         "---\n> [!CAUTION]\n> Review upstream issue before merging; see the link[...]"
       ]
     }
     ```

5. **Prefer small, composable rules that are straightforward to review and roll back**

   * **Rationale**: Composition beats duplication. Small pieces can be reused, tested, and reverted independently
   * **Requirements**: Create `helpers/` for reusable behaviors and `overrides/` for small tweaks; compose them in `base/` as needed
   * **Pitfalls to avoid**: Do not copy-paste large blocks across files — extract and reference a helper or override instead

6. **Preset ID shape: `Kong/public-shared-renovate//<path-without-extension>`**

   * **Rationale**: Extension-less IDs are stable and match Renovate’s expectations
   * **Requirements**: Reference presets like "Kong/public-shared-renovate//base/go" (omit `.json`)
   * **Pitfalls to avoid**: Do not include file extensions or local relative paths in `extends`

7. **Use short, descriptive, kebab-case file names that reflect subject and intent**

   * **Rationale**: Predictable names improve discoverability and make grep searches easier
   * **Requirements**: Use names like `github-actions.json`, `go.json`, `labels.json`, `tj-actions-changed-files.json`
   * **Pitfalls to avoid**: Do not use vague or overly long names. Avoid spaces and CamelCase

8. **Keep diffs minimal and ordering stable**

   * **Rationale**: Stable ordering reduces churn and keeps reviews focused on intent
   * **Requirements**: Keep ordering stable; alphabetize arrays when reasonable; avoid incidental reformatting
   * **Pitfalls to avoid**: Do not make unrelated reordering changes in the same PR

9. **Default to conservative behavior**

   * **Rationale**: Safer defaults reduce org-wide risk
   * **Requirements**: Prefer grouping, `minimumReleaseAge`, or review gates unless there's a clear, reviewed need for speed

## Choosing the right directory

Use this guide to decide where new presets belong. Each directory has a distinct purpose.

### Quick decision checklist

* **Org-wide, stable, reusable rules?** → `base/`
* **Small tweak to defaults, reusable across repos?** → `overrides/`
* **Tiny utility, composable anywhere, can be used standalone?** → `helpers/`
* **Team- or product-specific conventions, shared across a few repos?** → `scoped/`
* **Security-focused policies (labels, alerts, enforcement)?** → `security/`
* **Temporary guardrail for an active incident?** → `security/incidents/`
* **Truly a one-off, only for a single repo?** → keep it in that repo’s `renovate.json`

### [`base/`](./base)

Foundational, broadly reusable rules that apply across the entire organization. These presets act as safe defaults and establish consistent Renovate behavior across many repos.

**Usage**

* Form the building blocks for other presets
* Collected into the default (`Kong/public-shared-renovate`), so most repos get them automatically by extending it
* Ideal place for policies that should rarely change once established

**Examples**

* Go dependency update policies shared across all Go repos
* Rules for GitHub Actions updates (pinning, digest handling, schedule)
* Security-related update settings that apply to all projects

**Notes**

* Serves as the canonical source of truth for common behavior
* Documented carefully so that maintainers understand the rationale
* Should not include project-specific or experimental rules

### [`overrides/`](./overrides)

Lightweight, reusable adjustments that modify or refine the behavior defined in `base/` or the default (`Kong/public-shared-renovate`). They allow selective changes without duplicating entire presets.

**Usage**

* Must be extended **after** the default for changes to take effect, because of Renovate’s precedence rules
* Good for making small, reusable tweaks that multiple repos may want to apply on top of defaults

**Examples**

* Adding or changing labels on PRs
* Assigning reviewers automatically
* Adjusting automerge schedules for certain types of updates

**Notes**

* Should not be tied to a specific incident or team
* Keeps complexity low by avoiding full duplication of `base/`
* Works like “patches” layered on top of defaults

### [`helpers/`](./helpers)

Tiny, standalone utilities that can be used in any configuration. They are building blocks rather than full policies and do not depend on other presets.

**Usage**

* Can be extended directly in a repo’s `renovate.json` without including the default or `base/`
* Can be composed inside `packageRules` or other presets
* Only applied when explicitly added—never inherited automatically

**Examples**

* A helper that makes Renovate open PRs immediately instead of waiting for schedule
* A helper that disables updates for a specific GitHub Action
* Utility matchers to simplify complex `packageRules`

**Notes**

* Highly composable and flexible
* Useful for rapid customization without modifying defaults
* Always keep them small and focused on one behavior

### [`scoped/`](./scoped)

Rules that are specific to a product, repo family, or team. These rely on conventions meaningful only within that scope and would not be safe to apply org-wide.

**Usage**

* Apply only to repos belonging to that team or product area
* Useful when shared conventions differ from org-wide defaults
* Intended to be shared across several repos in a scope, not just a single repo

**Examples**

* Go module paths or replace directives specific to one product line
* Image tag policies used by one team’s workflows
* Versioning rules tied to a product’s release process

**Notes**

* Not for one-offs; one-off config belongs in a repo’s `renovate.json`
* Helps teams maintain consistent behavior without affecting global defaults
* Bridges the gap between org-wide `base/` and repo-local configs

### [`security/`](./security)

A central, long-lived baseline for security-related Renovate configuration. It ensures consistent security practices across all repos without duplicating logic.

**Usage**

* Extend `security/base.json` to apply org-wide security-focused behavior
* Adds a `security` label to PRs in addition to the usual `dependencies` label
* Enables OSV and GitHub vulnerability alerts
* Cleans up commit messages by removing the `[SECURITY]` suffix for better changelog integration
* Automatically includes incident guardrails from [`security/_incidents.json`](./security/_incidents.json)

**Examples**

* Ensure that GitHub Actions under `*/public-shared-actions/security-actions/**` are updated immediately
* Provide consistent labeling for vulnerability PRs
* Centralize security-related schedules and policies

**Notes**

* Stable and reusable across the org
* Customizable for labels, cadence, or scope
* Represents long-term policy, not temporary incident handling

### [`security/incidents/`](./security/incidents)

Short-lived, high-priority presets created in response to active security incidents. They mitigate urgent risks until upstream fixes are available.

**Usage**

* Block or delay updates to a risky dependency
* Force replacement of a compromised dependency with a safe version
* Temporarily disable updates that could break builds during an incident

**Examples**

* Blocking a newly disclosed vulnerable version of a package
* Pausing updates for a dependency under active investigation
* Forcing a dependency to a patched version before upstream releases stabilizes

**Notes**

* Automatically aggregated into `security/_incidents.json` by CI
* CI validates wiring, so maintainers only add new files here
* Must always be cleaned up once the incident is resolved
* High urgency and org-wide scope, but explicitly temporary

## Testing and validation

* Validate JSON locally (your editor or a linter should catch syntax issues). Presets must be strict JSON
* Sanity-check with Renovate: reference your new preset in a throwaway repo or a local renovate-config validator/dry-run if available
* For incident presets: no manual changes to the aggregator are needed. CI will update `security/_incidents.json` to include your preset and will fail validation if coverage is missing

## Security incident response presets

When a supply‑chain incident or other security event requires immediate guardrails, use the shared incident presets to quickly enforce safer behavior across all repositories.

> [!NOTE]  
> These presets are temporary and can be removed once upstream issues are fixed. That's why we suggest avoiding extending them directly. Instead, rely on the default preset, or if absolutely necessary, extend from security/base.

### Process to add a new incident preset

1. Create a new preset JSON file under [`security/incidents/`](security/incidents). Keep it narrowly scoped to the affected dependency/packages
2. Add human‑readable context in `description`/`prBodyNotes` so reviewers know why and how to proceed
3. Open a PR. The CI auto-sync workflow will update the aggregator preset [security/_incidents.json](security/_incidents.json) in your PR to include all incident presets (kept in alphabetical order)
4. CI validation will verify that the aggregator includes every preset under `security/incidents/` and that [security/base.json](security/base.json) composes the aggregator

> [!TIP]
> 🌟 Keep these presets conservative and review‑friendly — prefer minimal, targeted rules over broad changes

### Referencing an incident preset directly (rare)

Repositories typically do not consume incident presets directly; they are composed via the aggregator `security/_incidents.json` into `security/base.json`, which consumer repositories extend. If you must reference a preset directly (rare):

```json
{
  "extends": ["Kong/public-shared-renovate//security/incidents/<subpath>"]
}
```

### Directory layout

Use this structure so presets are easy to find, review, and compose:

```
security/
  incidents/
    github-actions/
      tj-actions-changed-files.json
    npm/
    go/
    docker/
    misc/
```

#### Guidelines

* **Location**: put every incident preset under `security/incidents/`
* **Nesting by ecosystem**: group under a top‑level directory such as `github-actions/`, `npm/`, `go/`, `docker/`, or `misc/` (create others as needed)
* **File naming**: use short, descriptive, kebab-case names that reflect the subject and intent, e.g., `tj-actions-changed-files.json`, `npm-leftpad-block.json`
* **One preset per file**: keep each file narrowly scoped to a single incident or mitigation
* **Format**: `.json` only with strict JSON syntax (no JSON5, no comments, no trailing commas)
* **Preset ID shape**: `Kong/public-shared-renovate//<path-without-.json>` (i.e. `Kong/public-shared-renovate//security/incidents/github-actions/tj-actions-changed-files`)
* **Documentation**: include concise `description` and, when applicable, reviewer guidance in `prBodyNotes` so the rationale and next steps are clear
* **Wiring**: no manual wiring required. After you add a file under `security/incidents/`, CI will update the aggregator `security/_incidents.json` in your PR and validate coverage in CI

### Common patterns

#### Gate risky dependencies with a higher `minimumReleaseAge` and review guardrails

Use this pattern to slow down adoption of a dependency while an incident is investigated or confidence builds. It adds a clear caution label, enforces a `minimumReleaseAge` before PRs are created, and surfaces reviewer guidance via `prBodyNotes` (see [`security/incidents/github-actions/tj-actions-changed-files.json`](security/incidents/github-actions/tj-actions-changed-files.json)).

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

* Keep presets conservative and narrowly scoped
* Prefer short‑lived mitigations; remove once upstream issues are resolved
* If mitigation becomes permanent policy, migrate its logic to [`base/`](base) (and leave a temporary alias or deprecation path if needed)

## Deprecating or moving presets

* When deprecating a preset, add a clear notice explaining why, the replacement (if any), and when it will be removed
* When moving a preset, leave a temporary compatibility alias at the old path with a deprecation notice and pointer to the new ID
* Update [README](README.md) and any other docs that reference the old path
* Coordinate with [CODEOWNERS](CODEOWNERS) if ownership or responsibility changes
* Keep deprecation aliases short-lived and remove them once consumers have migrated

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

* **Format**: `Kong/public-shared-renovate//<path-without-.json>`

* **Examples**:
   * `Kong/public-shared-renovate//base/go`
   * `Kong/public-shared-renovate//overrides/labels`
   * `Kong/public-shared-renovate//helpers/immediately`
   * `Kong/public-shared-renovate//security-incidents/github-actions/tj-actions-changed-files`

## PR checklist

Before opening a PR:

* [ ] Chose the correct directory (see [Choosing the right directory](#choosing-the-right-directory))
* [ ] JSON is strict and valid (`.json` only; no comments or trailing commas)
* [ ] `description` explains intent; `prBodyNotes` added if reviewer guidance is needed
* [ ] File name is short, descriptive, kebab-case
* [ ] Parameterized presets document arguments with examples
* [ ] For security incidents: no manual change to the aggregator required — CI will update [`security/_incidents.json`](security/_incidents.json) in your PR
* [ ] Backward-compatibility alias added if moving/renaming
* [ ] Root [README](README.md) updated if you add user-facing capabilities or move presets

## FAQ

### Why strict JSON instead of JSON5 or JSONC?

Using strict JSON keeps parsing predictable across Renovate, jq, and CI tools, avoids editor and linter inconsistencies, and yields smaller, cleaner diffs without comments or permissive syntax; it also matches what Renovate expects when loading presets. Therefore, presets in this repository must use `.json` only, and JSON5/JSONC features such as comments, trailing commas, single quotes, unquoted keys, hex numbers, or NaN/Infinity are not allowed. A single legacy file `base/gateway.json5` remains only for compatibility; do not add more.

### Why omit the file extension in `extends`?

Renovate resolves preset IDs without file extensions, and extension-less IDs stay stable if formats ever change while preventing mismatches between `.json` and `.json5`. Therefore, when you reference presets in `extends`, always omit the `.json` extension.
