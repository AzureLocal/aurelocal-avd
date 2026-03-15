# Variable Standards

Conventions for the central configuration file and all variable naming across the repository.

---

## Central Config

The single source of truth is `config/variables.yml`. Copy from `config/variables.example.yml`.

### Format

- **YAML** with sectioned structure
- Clean, human-readable keys (no legacy prefixes)
- 2-space indentation

### Sections

```yaml
subscription:     # Azure subscriptions (AVD + Azure Local), tenant, location
security:         # Key Vault name and resource group
control_plane:    # Host pool, app group, workspace settings
session_hosts:    # VM count, prefix, specs, admin creds, Azure Local resource IDs
domain:           # AD domain config, join credentials, OU paths
entra_id:         # Entra ID SSO, Intune enrollment, RBAC group IDs
tags:             # Resource tags
ansible:          # Ansible controller details (optional)
```

### Naming Rules

| Scope | Convention | Example |
|-------|-----------|---------|
| Top-level sections | `snake_case` | `azure_local`, `data_disks` |
| Keys within sections | `snake_case` | `subscription_id`, `volume_size_gb` |
| Per-VM maps | Zero-padded string keys | `"01"`, `"02"`, `"03"` |
| Booleans | Descriptive name | `role_enabled: true` |
| Secrets | `keyvault://` URI | `keyvault://kv-name/secret-name` |
| Example values | IIC fictional identity | `iic.local`, `rg-iic-avd-hp-eus-01`, `kv-iic-platform` |

---

## Key Vault References

Secrets are **never** stored as plain text in config files. Use the `keyvault://` URI format:

```yaml
session_hosts:
  vm_admin_password: "keyvault://kv-iic-platform/avd-vm-admin-password"
domain:
  domain_join_password: "keyvault://kv-iic-platform/domain-join-password"
```

At runtime, scripts resolve these via `Resolve-KeyVaultRef`:

1. Try `Az.KeyVault` PowerShell module (preferred)
2. Fallback to `az keyvault secret show` CLI
3. Hard fail if neither works (no interactive prompts)

---

## Compatibility

The deploy scripts read the central `config/variables.yml` directly. Legacy config file layouts (e.g., `solution-avd.yml`) are **not** supported — migrate to the new section-based structure.

- New `config/variables.yml` → required by all deploy scripts
- See `config/variables.example.yml` for a complete reference

---

## Tool-Specific Parameter Files

| Tool | File | Location |
|------|------|----------|
| PowerShell | `variables.yml` | `config/` |
| Bicep | `main.bicepparam` | `infrastructure/bicep/` |
| Terraform | `terraform.tfvars` | `infrastructure/terraform/` |
| ARM | `azuredeploy.parameters.json` | `infrastructure/arm/` |
| Ansible | `inventory.yml` | `configure/ansible/inventory/` |
| Azure CLI | `.env` | `infrastructure/azure-cli/` |

All tool-specific parameter files should derive their values from the central `config/variables.yml`.
