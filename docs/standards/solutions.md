# Solution Standards

Conventions for Infrastructure-as-Code (IaC) templates and deployment solutions in this repository.

---

## General Principles

- **Modular** — break templates into reusable modules/files
- **Parameterized** — no hardcoded values; everything comes from the central config or parameter files
- **Idempotent** — safe to deploy multiple times without side effects
- **Tagged** — all Azure resources get standard tags (project, environment, workload, solution)

---

## Bicep

| Convention | Standard |
|------------|----------|
| Location | `infrastructure/bicep/` |
| Entry point | `main.bicep` |
| Parameters | `main.bicepparam` (example: `main.bicepparam.example`) |
| Modules | `modules/` subdirectory |
| Naming | `camelCase` for parameters, `kebab-case` for resource names |
| API versions | Use the latest stable API version |

### Module Pattern

```bicep
// modules/storageAccount.bicep
param storageAccountName string
param location string
param tags object = {}

resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
}

output id string = sa.id
```

---

## Terraform

| Convention | Standard |
|------------|----------|
| Location | `infrastructure/terraform/` |
| Entry point | `main.tf` |
| Variables | `variables.tf` + `terraform.tfvars.example` |
| Outputs | `outputs.tf` |
| Templates | `templates/` subdirectory |
| State | **Never commit** `*.tfstate`, `*.tfstate.backup`, or `tfplan` |
| Lock file | `.terraform.lock.hcl` is gitignored |

### File Organization

```
infrastructure/terraform/
├── main.tf                     # Provider config + module calls
├── variables.tf                # Input variable declarations
├── outputs.tf                  # Output values
├── locals.tf                   # Computed locals
├── resource-group.tf           # Resource group resources
├── avd.tf                      # AVD-specific resources
├── session-hosts.tf            # Session host resources
├── keyvault.tf                 # Key Vault integration
├── terraform.tfvars.example    # Example variable values
├── README.md
└── templates/
    └── cloud-init.yml.tftpl    # Template files
```

### Naming

- Resources: `snake_case` (e.g., `resource "azurerm_resource_group" "avd"`)
- Variables: `snake_case` (e.g., `var.resource_group_name`)
- Outputs: `snake_case` (e.g., `output "storage_account_id"`)

---

## ARM Templates

| Convention | Standard |
|------------|----------|
| Location | `infrastructure/arm/` |
| Template | `azuredeploy.json` |
| Parameters | `azuredeploy.parameters.example.json` |
| Naming | `camelCase` for parameters |

---

## Ansible

| Convention | Standard |
|------------|----------|
| Location | `configure/ansible/` |
| Playbooks | `playbooks/` subdirectory |
| Inventory | `inventory/` subdirectory |
| Roles | `roles/` subdirectory |
| Variable names | `snake_case` |
| YAML indent | 2 spaces |

---

## Security

- No secrets in IaC files — use Key Vault references or parameter injection
- Use managed identities where possible
- Apply least-privilege RBAC
- Enable resource locks on production resources
