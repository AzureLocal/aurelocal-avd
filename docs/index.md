# Azure Virtual Desktop on Azure Local

Infrastructure-as-code and automation for deploying **AVD** with session hosts running on **Azure Local** clusters.

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
| Bicep | `src/bicep/` | Recommended — native ARM, type-safe |
| ARM | `src/arm/` | Direct ARM JSON templates |
| Terraform | `src/terraform/` | Multi-cloud / existing TF estate |
| PowerShell | `src/powershell/` | Interactive / ad-hoc |
| Azure CLI | `scripts/` | Bash-based scripting |
| Ansible | `src/ansible/` | Post-deploy OS/app config |

## Related

- [Architecture Overview](architecture.md)
- [Deployment Scenarios](scenarios.md)
- [Variable Reference](reference/variables.md)
- Companion repo: [azurelocal-sofs-fslogix](https://github.com/AzureLocal/azurelocal-sofs-fslogix)
