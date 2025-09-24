# Kong Renovate presets

Shared Renovate presets for Kong repositories. Use these as building blocks or extend the default preset for a secure, low-noise setup that works across languages and ecosystems.

## Quick start

Use the default preset to get a secure, low-noise setup that works across languages and ecosystems.

### Floating version (recommended)

Use the floating preset so projects automatically pick up changes:

```json
{
  "extends": ["Kong/public-shared-renovate"]
}
```

#### Why floating version is recommended

- Renovate does not support digest pinning for presets, so exact tags bring no real security gain
- Presets are config, not executable code, and are loaded by Renovate at runtime
- Floating avoids delays and lets shared preset improvements roll out quickly without waiting for a tag bump in every repo

### Pin to a release tag (optional, for holdbacks or downgrades)

Pin only when you must hold back or temporarily downgrade because a change breaks your workflow:

```json
{
  "extends": ["Kong/public-shared-renovate@<VERSION>"]
}
```

If pinned, Renovate will open PRs to bump the preset via the [**renovate-config-presets**](https://docs.renovatebot.com/modules/manager/renovate-config-presets/) manager unless that manager is explicitly disabled. Replace `<VERSION>` with the specific release tag you want to use from the releases' page (for example, the last known good version if you are downgrading).

## What you get by default

A concise summary of the default preset (see [default.json](./default.json) for full details):

- Clear PRs and commits: messages show from → to, including short SHAs for digests
- Merge Confidence badges are shown on PRs for extra signal
- Standard labeling: the 'dependencies' label is added to all Renovate PRs
- Extra version discovery via custom managers: Dockerfile ARG versions, Helm Chart appVersion, Makefile versions, and Terraform tfvars
- GitHub Actions kept healthy: grouped sensibly and pinned by commit for security and stability
- Security posture: vulnerability alerts are enabled and surfaced via the base security preset
- Fresh releases are gated briefly by default: `minimumReleaseAge` is 12 days (override locally as needed)

## Common variations

### Add up to five extra labels to all PRs

The labels override always includes the standard 'dependencies' label and appends up to five optional labels you provide.

```json
{
  "extends": [
    "Kong/public-shared-renovate",
    "Kong/public-shared-renovate//overrides/labels(renovate,ci)"
  ]
}
```

### Request up to five reviewers on Renovate PRs

Use the [`Kong/public-shared-renovate//overrides/reviewers`](./overrides/reviewers.json) preset to automatically request specific users or teams on Renovate PRs.

- Accepts up to five reviewers as arguments
- Arguments can be either a **user** (e.g. `octocat`) or a **team** using the `team:` prefix
- When referencing a team, you must [use only the last segment of the GitHub team name](https://docs.renovatebot.com/configuration-options/#reviewers). For example, if the full team name is `@organization/foo`, you must pass `team:foo`
- Place this override after the default preset in `extends`, as order matters

> [!IMPORTANT]
> **Reviewers are added only when the PR is created and are not updated afterward**

Example:

```json
{
  "extends": [
    "Kong/public-shared-renovate",
    "Kong/public-shared-renovate//overrides/reviewers(octocat,team:foo)"
  ]
}
```

### Adjust update cadence (e.g. run daily)

You can change how often Renovate runs by adding a schedule preset. Place it after the shared preset so it takes effect — the order of items in `extends` matters because later entries override earlier ones.

Example:

```json
{
  "extends": [
    "Kong/public-shared-renovate",
    "schedule:daily"
  ]
}
```

See the options' reference for more: [Renovate configuration options](https://docs.renovatebot.com/configuration-options/)

### Change timezone for scheduling

Renovate interprets schedules in a configurable timezone. If no timezone is set in your config, Renovate [defaults to UTC](https://docs.renovatebot.com/key-concepts/scheduling/#default-timezone). To change the timezone for your consumer repository, extend the builtin timezone preset with an [IANA Time Zone (TZ) identifier](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). Place it after the shared preset in `extends` so it overrides any timezone configured by presets you include.

Example:

```json
{
  "extends": [
    "Kong/public-shared-renovate",
    ":timezone(America/New_York)"
  ]
}
```

### Control when automerge can happen

By default, Renovate uses GitHub's platform automerge. When a PR is eligible and all requirements are met (for example, required status checks pass), Renovate enables auto-merge on the PR and GitHub merges it as soon as conditions are satisfied. There is no schedule involved in this default flow.

If you want automerge to follow a schedule, first disable platform automerge by setting [platformAutomerge](https://docs.renovatebot.com/configuration-options/#platformautomerge) to `false`. Then configure a schedule either with [automergeSchedule](https://docs.renovatebot.com/configuration-options/#automergeschedule) directly or via one of the [Renovate schedule presets](https://docs.renovatebot.com/presets-schedule/).

Example using a preset:

```json
{
  "extends": ["Kong/public-shared-renovate", "schedule:automergeWeekdays"],
  "platformAutomerge": false
}
```

Example configuring manually:

```json
{
  "extends": ["Kong/public-shared-renovate"],
  "automergeSchedule": ["every weekday"],
  "platformAutomerge": false
}
```

## Security preset customization examples

These examples show how to adapt the defaults from [security/base.json](./security/base.json) using security overrides: [overrides/security-labels.json](./overrides/security-labels.json) and [overrides/security-reviewers.json](./overrides/security-reviewers.json).

### Remove the default `security` label

Use this if your repository already applies its own risk labels or if you want to reduce visual noise from security PRs. This removes only the `security` label added by the shared preset for vulnerability alerts. Existing PRs keep their labels; new PRs reflect the change.

```json
{
  "ignorePresets": ["Kong/public-shared-renovate//overrides/security-labels"],
  "extends": ["Kong/public-shared-renovate"]
}
```

### Replace the `security` label with a custom one

Use this if your team prefers a different label name for security updates or to align with existing dashboards. Pass the desired label as the first argument. GitHub creates the label if it does not exist. Applies to security-scoped updates (vulnerability alerts and security-actions rules). Choose a label your processes already recognize (e.g. `sec-critical`, `security-high`).

```json
{
  "extends": [
    "Kong/public-shared-renovate",
    "Kong/public-shared-renovate//overrides/security-labels(sec-critical)"
  ]
}
```

### Keep the `security` label but add another

Use this if you want to keep the standard `security` label and add another one for routing or automation. Provide up to five labels as arguments, separated by a comma, with no spaces. Order does not matter. Useful for dashboards or rules that depend on labels like `ci`, `platform`, or team-specific tags. GitHub creates labels if they do not exist.

```json
{
  "extends": [
    "Kong/public-shared-renovate",
    "Kong/public-shared-renovate//overrides/security-labels(security,ci)"
  ]
}
```

### Adjust the minimum release age for updates

The `minimumReleaseAge` setting controls how long Renovate waits before creating a PR for a new version. By default, we enforce a **12-day delay** to balance delivery speed with stability and security.

When defined at the root level, this setting applies to all dependencies and update types. For finer control, you can define it inside `packageRules` to apply the delay only to specific dependencies or groups.

```json
{
  "extends": ["Kong/public-shared-renovate"],
  "minimumReleaseAge": "30 days",
  "packageRules": [
    {
      "matchDepNames": ["left-pad"],
      "minimumReleaseAge": "a billion years"
    }
  ]
}
```

⚠️ **Note:** This setting does not apply to updates triggered by `vulnerabilityAlerts`. Security-related updates always bypass `minimumReleaseAge` and Renovate will open a PR as soon as a fix is available.

> [!CAUTION]
> #### Reducing the minimum release age
>
> The default value is **12 days**. Lowering it, either globally or within a `packageRule`, must only happen in rare and very specific cases that are reviewed and pre-approved by the security team.
>
> This delay protects against supply-chain risks where a new version might later prove malicious or unstable. It gives the ecosystem time to catch issues, publish advisories, and release fixes before updates reach our codebase. Shortening the window weakens this safeguard and raises the risk of introducing compromised or broken dependencies.

## Order of precedence

When multiple Renovate presets or rules overlap, Renovate applies settings based on a clear precedence model. Knowing this hierarchy helps avoid surprises and ensures that the intended configuration is actually used.

1. **Later extended presets override earlier ones**

   - The order in the `extends` array matters. A preset listed later takes precedence over one listed earlier
   - Example: if both `base/go` and `overrides/labels` define labels, the labels from `overrides/labels` will be applied if it comes after `base/go` in the list

2. **Direct values in a config override inherited presets**

   - Any setting defined directly in a repo's `renovate.json` (or equivalent) always overrides values inherited from presets
   - Example: if a preset sets `automerge: false` but the repo's `renovate.json` sets `automerge: true`, the direct value wins

3. **`packageRules` targeting specific dependencies or versions override direct values**

   - `packageRules` act as more granular overrides for individual dependencies, package managers, or version ranges
   - Example: a repo may set `automerge: true` globally, but add a `packageRule` for `golang` that sets `automerge: false`. Renovate will follow the more specific rule

4. **If multiple `packageRules` match, the later one wins**

   - The order of rules in the array matters. When multiple rules match the same dependency or update, Renovate applies the last matching rule
   - Example: one `packageRule` may schedule updates daily, while a later one may schedule them weekly. Renovate will use the weekly schedule

### Practical implication

Because of this precedence model:

- Presets in `overrides/` must be extended **after** the default (`Kong/public-shared-renovate`) to take effect
- Helpers are only applied when explicitly added and follow the same rules as other presets
- Scoped or security presets can override base behavior if extended later in the chain

This order of precedence ensures predictability: start with the org-wide defaults, apply scoped or override presets as needed, and finally tune behavior with direct config, and `packageRules`.

## Preset directories overview

Kong's shared Renovate presets are organized by purpose:

- [`base/`](./base) – reusable building blocks for org-wide policy (Go, GitHub Actions, security, frontend), composed into the top-level [default](./default.json). Most repos just extend the default (`Kong/public-shared-renovate`).
- [`overrides/`](./overrides) – small reusable tweaks layered on top of `base/` or the default (labels, reviewers, automerge adjustments).
- [`helpers/`](./helpers) – tiny, standalone utilities usable directly in `renovate.json` or within other presets.
- [`scoped/`](./scoped) – rules for a specific product, project, or team, not meant for org-wide use.
- [`security/`](./security) – long-lived security defaults ([`security/base.json`](./security/base.json)) plus short-lived incident guardrails ([`security/incidents/`](./security/incidents)).

For detailed guidance, see [Choosing the right directory](./CONTRIBUTING.md#choosing-the-right-directory).

## Security incidents

Guidance for creating, wiring, and maintaining security-incident presets is documented in the [contributor guide](./CONTRIBUTING.md#security-incident-response-presets). This includes the full process, directory layout, common patterns, examples, and expectations for deprecation and cleanup.
