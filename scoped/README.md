# Scoped presets

Presets in this directory are intentionally scoped to a specific product, project, or team. They capture rules that are not generally applicable across Kong's repositories and may encode assumptions unique to that scope (naming, dependency layout, release cadence, migration strategy, etc.).

These presets live alongside the broadly reusable presets under [`base/`](../base) and [`overrides/`](../overrides), but they are not meant for general consumption. Consumers should be the specific projects/teams they're designed for.

## Directory layout and naming

Structure scoped presets by project/team, and use descriptive, kebab-case file names:

```
scoped/
  <project-or-team>/
    <purpose>.json
```

## Ownership and maintenance

- Each subdirectory should be owned by relevant CODEOWNERS so reviews are routed correctly (see [CODEOWNERS](../CODEOWNERS))
- Keep presets minimal, well-commented (via `description`), and conservative by default
- Avoid secrets or encrypted tokens; public configs here must not include credentials
- If a preset is moved or replaced, add a temporary alias at the old path with clear deprecation guidance and a removal timeline

## Example: Kuma preset

The [`scoped/kuma/go-control-plane.json`](./kuma/go-control-plane.json) preset manages updates for `github.com/kumahq/go-control-plane` replace directives in Kuma Go modules. It uses a custom regex manager, disables conflicting default managers, and groups related updates for review.

Usage in a Kuma repo:

```json
{
  "extends": ["Kong/public-shared-renovate//scoped/kuma/go-control-plane"]
}
```

## FAQ

### Can other teams use a scoped preset?

They technically can, but it's discouraged unless the assumptions match their project. Consider promoting the logic to [`base/`](../base) if it's broadly useful.

### Do scoped presets get auto-wired anywhere?

No. Unlike [`security-incidents/`](../security-incidents), scoped presets are consumed directly by the target projects and are not automatically extended elsewhere.

### How long should a scoped preset live?

As long as it serves that project. If it becomes obsolete or general, deprecate/move accordingly.
