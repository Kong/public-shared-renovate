# Helpers presets

Helpers are small, reusable building blocks that are useful on their own and as ingredients when composing other presets (e.g., inside `packageRules`). They are focused, self‑contained, and safe to reuse broadly.

## Referencing a helper example

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["*/public-shared-actions/security-actions/**"],
      "extends": ["Kong/public-shared-renovate//helpers/immediately"]
    }
  ]
}
```

## Available helpers

- `helpers/immediately`: Bypass scheduling and create PRs immediately across the board
