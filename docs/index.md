# Azure Virtual Desktop on Azure Local

Infrastructure-as-code and automation for deploying **AVD** with session hosts running on **Azure Local** clusters.

## Deployment Workflow

```
config/  →  infrastructure/  →  deploy/  →  configure/  →  tests/
```

| Phase | Directory | What happens |
|-------|-----------|-------------|
| **0** | `config/` | Fill in your variables (`variables.yml`) |
| **1** | `infrastructure/` | Provision AVD control plane + session hosts (pick a tool) |
| **2** | `deploy/` | Workload-specific deployment scripts |
| **3** | `configure/` | Post-deployment configuration (Ansible) |
| **4** | `tests/` | Validate the deployment |

## Quick Start

1. Clone the repo and copy the variable template:
   ```bash
   git clone https://github.com/AzureLocal/aurelocal-avd.git
   cd aurelocal-avd
   cp config/variables.example.yml config/variables.yml
   ```
2. Edit `config/variables.yml` with your environment values.
3. Deploy using your preferred tool — see [Getting Started](getting-started.md).

## Tool Options

| Tool | Directory | Best for |
|------|-----------|----------|
| Bicep | `infrastructure/bicep/` | Recommended — native ARM, type-safe |
| ARM | `infrastructure/arm/` | Direct ARM JSON templates |
| Terraform | `infrastructure/terraform/` | Multi-cloud / existing TF estate |
| PowerShell | `infrastructure/powershell/` | Interactive / ad-hoc |
| Azure CLI | `infrastructure/azure-cli/` | Bash-based scripting |
| Ansible | `configure/ansible/` | Post-deploy OS/app config |

## Related

- [Architecture Overview](architecture.md)
- [Deployment Scenarios](scenarios.md)
- [Variable Reference](reference/variables.md)
- Companion repo: [azurelocal-sofs-fslogix](https://github.com/AzureLocal/azurelocal-sofs-fslogix)
