# public-shared-renovate

Shared Renovate configs available to both public and private repositories.

**IMPORTANT**: Encrypted NPM tokens **must not** be added to configs in this repository. If your config needs an encrypted token, it **must** be private and reside in the [shared-renovate repository](https://github.com/Kong/shared-renovate).

## Usage

To use the latest add the below line to the top to your `renovate-config.json` file:

```json
{
  "extends": [
    "github>Kong/public-shared-renovate:kong-frontend-config.json"
  ]
}
```

To use a specific tag add the below line to the top of your `renovate-config.json` file:

```json
{
  "extends": [
    "github>Kong/public-shared-renovate:kong-frontend-config.json#0.0.1"
  ]
}
```
