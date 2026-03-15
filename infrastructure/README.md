# Infrastructure — Phase 1

IaC templates and scripts for provisioning AVD resources. Each tool contains `control-plane/` and `session-hosts/` subdirectories.

## What Gets Deployed

**Control plane** (in Azure):

| Resource | Description |
|----------|-------------|
| Resource Group | Container for all AVD resources |
| Host Pool | Logical grouping of session hosts |
| Application Group | Desktop or RemoteApp collection |
| Workspace | User-facing aggregator |
| Key Vault | Registration tokens, domain-join credentials |
| Log Analytics | AVD diagnostics and monitoring |

**Session hosts** (on Azure Local):

| Resource | Description |
|----------|-------------|
| Arc-enabled VMs | Windows VMs via Arc Resource Bridge |
| Network Interfaces | NICs on Azure Local virtual networks |
| Domain Join Extension | Joins VMs to Active Directory |
| AVD Agent Extension | Registers hosts with the host pool |

## Choose a Tool

| Tool | Directory | Best For |
|------|-----------|----------|
| **Bicep** | [`bicep/`](bicep/) | Recommended — native ARM, type-safe, modular |
| **ARM** | [`arm/`](arm/) | Direct ARM JSON templates |
| **Terraform** | [`terraform/`](terraform/) | Multi-cloud teams, existing TF estate |
| **PowerShell** | [`powershell/`](powershell/) | Interactive / ad-hoc deployments |
| **Azure CLI** | [`azure-cli/`](azure-cli/) | Bash-based scripting |

## Prerequisites

- Azure subscription with Contributor RBAC (or custom AVD role)
- Entra ID tenant
- Azure Local cluster registered with Arc
- See [`config/`](../config/) for variable setup

## Workflow

```
config/  →  infrastructure/ (you are here)  →  deploy/  →  configure/  →  tests/
```
