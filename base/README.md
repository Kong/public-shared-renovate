# Base presets

Base presets are reusable building blocks that define Kong's shared Renovate policy for major ecosystems (Go, GitHub Actions), security posture, and selected domains (frontend). They are designed for broad reuse and are composed into the top‑level [default.json](../default.json) preset.

> [!TIP]
> 🌟 Most consumer repositories can simply extend the default preset (`Kong/public-shared-renovate`), which already includes the essential `base/` presets. Extend individual `base/` presets directly only when you need finer‑grained control.
