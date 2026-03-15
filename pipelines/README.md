# CI/CD Pipelines – AVD on Azure Local

Example pipelines for automating AVD deployments using GitHub Actions and Azure DevOps.

---

## Folder Structure

```
pipelines/
├── github-actions/
│   ├── deploy-control-plane.yml      # GitHub Actions workflow – control plane
│   └── deploy-session-hosts.yml      # GitHub Actions workflow – session hosts
└── azure-devops/
    ├── deploy-control-plane.yml      # Azure DevOps pipeline – control plane
    └── deploy-session-hosts.yml      # Azure DevOps pipeline – session hosts
```

---

## GitHub Actions

### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Service principal / federated identity client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |
| `DOMAIN_JOIN_PASSWORD` | Domain-join service account password (stored in KV at deploy time) |

The pipelines use **OIDC federated identity** (`azure/login`) – no client secret needed.

### Trigger

- `deploy-control-plane.yml` – triggered on push to `main` when files under `bicep/control-plane/**` change, or manually via `workflow_dispatch`.
- `deploy-session-hosts.yml` – triggered manually via `workflow_dispatch` (requires registration token to exist in KV first).

---

## Azure DevOps

### Required Variables / Variable Groups

Create a variable group named **`avd-secrets`** in Azure DevOps Library with:

| Variable | Description |
|----------|-------------|
| `AZURE_SERVICE_CONNECTION` | Service connection name |
| `DOMAIN_JOIN_PASSWORD` | Domain-join password (mark as secret) |

### Trigger

Both pipelines can be triggered manually or wired to branch policies.

---

## Secret Management Approach

- Secrets are **never stored in pipeline YAML files** or parameter files.
- The control-plane pipeline stores the AVD registration token in Azure Key Vault after deployment.
- The session-host pipeline reads the token directly from Key Vault at runtime.
- Domain-join passwords are pushed to Key Vault by the control-plane pipeline on first run.
