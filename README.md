# azurelocal-avd

Scripts and automation for deploying **Azure Virtual Desktop (AVD)** on **Azure Local** (formerly Azure Stack HCI).

This repository covers the full AVD stack:
- **Control plane** – Host pools, application groups, workspaces, and supporting Azure resources deployed **in Azure**.
- **Session hosts** – Windows virtual machines deployed **on Azure Local clusters** and registered to the AVD host pool.

---

## Overview

Azure Virtual Desktop on Azure Local lets you run AVD session hosts on-premises while still using the Azure-hosted control plane for brokering, identity, and management. This repository provides infrastructure-as-code (IaC) and automation samples for every major tooling ecosystem so teams can choose the approach that best fits their workflows.

A companion repository ([azurelocal-sofs-fslogix](https://github.com/AzureLocal/azurelocal-sofs-fslogix)) covers deploying a Scale Out File Server (SOFS) on Azure Local to host FSLogix profile containers for these session hosts.

---

## Repository Structure

```
azurelocal-avd/
├── docs/                    # Architecture diagrams, scenarios, getting-started, and contributing guides
├── powershell/              # PowerShell scripts for AVD control-plane and session-host deployment
├── azure-cli/               # Azure CLI / Bash scripts for deployment
├── bicep/                   # Bicep templates (recommended IaC path)
├── arm/                     # ARM JSON templates
├── terraform/               # Terraform configurations (AzureRM / AzAPI provider)
├── ansible/                 # Ansible playbooks for post-deployment configuration
└── pipelines/               # Example CI/CD pipelines (GitHub Actions and Azure DevOps)
```

Each top-level tool folder is split into two sub-folders:

| Sub-folder | What it deploys |
|---|---|
| `control-plane/` | Host pool, application group, workspace, and supporting Azure resources |
| `session-hosts/` | AVD session-host VMs on Azure Local, domain-join, and AVD agent registration |

---

## Quick-Start by Tool

| Tool | Location | Guide |
|------|-----------|-------|
| PowerShell | [`powershell/`](./powershell/) | [README](./powershell/README.md) |
| Azure CLI | [`azure-cli/`](./azure-cli/) | [README](./azure-cli/README.md) |
| Bicep | [`bicep/`](./bicep/) | [README](./bicep/README.md) |
| ARM | [`arm/`](./arm/) | [README](./arm/README.md) |
| Terraform | [`terraform/`](./terraform/) | [README](./terraform/README.md) |
| Ansible | [`ansible/`](./ansible/) | [README](./ansible/README.md) |
| Pipelines | [`pipelines/`](./pipelines/) | [README](./pipelines/README.md) |

---

## Deployment Scenarios

See [docs/scenarios.md](./docs/scenarios.md) for detailed walkthroughs of:

1. **Pooled host pool with personal desktops** on Azure Local
2. **Shared host pool with multi-session Windows** on Azure Local
3. **Hybrid deployment** – control plane in Azure, session hosts split between Azure and Azure Local
4. **Greenfield deployment** – new Azure Local cluster + AVD end to end

---

## Documentation

- [Architecture Overview](./docs/architecture.md)
- [Deployment Scenarios](./docs/scenarios.md)
- [Getting Started](./docs/getting-started.md)
- [Contributing](./docs/contributing.md)

---

## Prerequisites

- An existing **Azure Local** cluster (formerly Azure Stack HCI) registered with Azure Arc
- Azure subscription with appropriate RBAC permissions (Contributor or custom AVD roles)
- Azure Active Directory (Entra ID) tenant
- For PowerShell: Az PowerShell module >= 9.0
- For Bicep / ARM: Azure CLI >= 2.50 or Azure PowerShell >= 9.0
- For Terraform: Terraform >= 1.5, AzureRM provider >= 3.75
- For Ansible: Ansible >= 2.14, `azure.azcollection` collection

---

## Contributing

See [CONTRIBUTING.md](./docs/contributing.md) for coding standards, branch strategy, and PR guidelines.

---

## License

See [LICENSE](./LICENSE) for details.
