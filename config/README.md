# Config — Central Variables

Single source of truth for all deployment parameters across every tool in this repository.

## Quick Start

```bash
cp variables.example.yml variables.yml
# Edit variables.yml with your environment values
```

> **Never commit `variables.yml`** — it is `.gitignore`d. Only `variables.example.yml` is tracked.

## Secrets

Passwords and sensitive values use `keyvault://` URIs — resolved at deploy time by the orchestration scripts in `deploy/`. Never store plaintext secrets in `variables.yml`.

```yaml
# Format
vm_admin_password: "keyvault://<vault-name>/<secret-name>"
```

The deploy scripts call `Resolve-KeyVaultRef` which reads from Azure Key Vault via `Az.KeyVault` (with `az keyvault` CLI fallback).

## Variable Reference

### subscription

| Variable | Type | Description |
|----------|------|-------------|
| `avd_subscription_id` | string | AVD subscription — host pool, app group, workspace, session host VMs |
| `azure_local_subscription_id` | string | Azure Local subscription — cluster, custom location, logical networks, images |
| `tenant_id` | string | Entra ID tenant |
| `location` | string | Azure region (default: `eastus`) |

### security

| Variable | Type | Description |
|----------|------|-------------|
| `key_vault_name` | string | Platform Key Vault used for all `keyvault://` URI resolution |
| `key_vault_resource_group` | string | Resource group containing the Key Vault |

### control_plane

| Variable | Type | Description |
|----------|------|-------------|
| `resource_group` | string | Resource group for host pool + app group + workspace |
| `host_pool_name` | string | AVD host pool name |
| `host_pool_type` | string | `Pooled` or `Personal` |
| `load_balancer_type` | string | `BreadthFirst` or `DepthFirst` (Pooled only) |
| `max_session_limit` | int | Max concurrent sessions per host (Pooled only) |
| `preferred_app_group_type` | string | `Desktop`, `RailApplications`, or `None` |
| `personal_assignment_type` | string | `Automatic` or `Direct` (Personal only) |
| `start_vm_on_connect` | bool | Requires Desktop Virtualization Power On Contributor RBAC |
| `validation_environment` | bool | `true` = receives service updates before production |
| `custom_rdp_properties` | string | Semicolon-delimited RDP properties |
| `host_pool_friendly_name` | string | Display name for the host pool |
| `host_pool_description` | string | Description for the host pool |
| `app_group_name` | string | Application group name |
| `app_group_type` | string | `Desktop` or `RemoteApp` |
| `app_group_friendly_name` | string | Display name for the app group |
| `workspace_name` | string | AVD workspace name |
| `workspace_friendly_name` | string | Display name for the workspace |

### session_hosts

| Variable | Type | Description |
|----------|------|-------------|
| `resource_group` | string | Resource group for session host VMs |
| `session_host_count` | int | Number of session host VMs to deploy |
| `vm_naming_prefix` | string | VMs named `{prefix}-001`, `{prefix}-002`, etc. |
| `vm_start_index` | int | Starting index for VM numbering |
| `vm_processors` | int | vCPUs per session host |
| `vm_memory_mb` | int | Memory in MB per session host |
| `vm_admin_username` | string | Local admin account name |
| `vm_admin_password` | string | `keyvault://` URI — resolved at deploy time |
| `session_host_os` | string | OS label (informational) |
| `custom_location_id` | string | Full ARM resource ID — Azure Local custom location |
| `logical_network_id` | string | Full ARM resource ID — Azure Local logical network |
| `gallery_image_id` | string | Full ARM resource ID — Azure Local marketplace gallery image |
| `storage_path_id` | string | Full ARM resource ID — Azure Local storage container |

### domain

| Variable | Type | Description |
|----------|------|-------------|
| `domain_fqdn` | string | Active Directory domain FQDN |
| `domain_join_username` | string | Service account name (qualified at deploy time) |
| `domain_join_password` | string | `keyvault://` URI — resolved at deploy time |
| `domain_join_ou_path` | string | OU distinguished name (empty = default Computers container) |

### entra_id

| Variable | Type | Description |
|----------|------|-------------|
| `enable_entra_id_auth` | bool | Installs AADLoginForWindows extension + `enablerdsaadauth:i:1` RDP property |
| `enroll_in_intune` | bool | Register session hosts in Intune MDM |
| `entra_user_login_group_id` | string | Entra group object ID for Virtual Machine User Login RBAC |
| `entra_admin_login_group_id` | string | Entra group object ID for Virtual Machine Administrator Login RBAC |

### tags

| Variable | Type | Description |
|----------|------|-------------|
| `Environment` | string | Environment tag |
| `Project` | string | Project tag |
| `ManagedBy` | string | Managed by tag |
| `Owner` | string | Owner tag |
| `CostCenter` | string | Cost center tag |

### ansible

| Variable | Type | Description |
|----------|------|-------------|
| `ansible_connection` | string | Ansible connection type |

## Per-Tool Parameter Files

Each tool keeps its own native parameter example file alongside its templates. Use this central file as the reference, then populate the tool-specific files:

| Tool | Parameter file |
|------|---------------|
| Bicep | `infrastructure/bicep/*/main.bicepparam.example` |
| ARM | `infrastructure/arm/*/azuredeploy.parameters.example.json` |
| Terraform | `infrastructure/terraform/*/terraform.tfvars.example` |
| PowerShell | `infrastructure/powershell/*/parameters.example.ps1` |
| Azure CLI | `infrastructure/azure-cli/*/parameters.example.sh` |
| Ansible | `configure/ansible/inventory/hosts.example.yml` |
