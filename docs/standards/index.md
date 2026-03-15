# Standards

Standards and conventions for the Azure Virtual Desktop on Azure Local repository. These ensure consistency across all scripts, documentation, infrastructure-as-code, and configuration files.

---

## Sections

| Standard | Description |
|----------|-------------|
| [Scripts](scripts.md) | PowerShell, Ansible, and Azure CLI script conventions |
| [Documentation](documentation.md) | MkDocs structure, formatting, and style guide |
| [Solutions](solutions.md) | Bicep, Terraform, ARM, and Ansible IaC conventions |
| [Variables](variables.md) | Central config structure, naming rules, Key Vault patterns |
| [Examples](examples.md) | Example scenario structure and formatting |

---

## Sister Repositories

| Repository | Purpose |
|------------|---------|
| [azurelocal-avd](https://github.com/AzureLocal/azurelocal-avd) | Azure Virtual Desktop on Azure Local |

---

## Company & Fictional References

### Real Identities

| Name | Usage |
|------|-------|
| **Hybrid Cloud Solutions** | Author/maintainer LLC. Used in script headers (`Author: Hybrid Cloud Solutions`), copyright notices, contact emails (`support@hybridsolutions.cloud`, `info@`, `sales@`, `contact@`), and website links (`hybridsolutions.cloud`). |
| **Azure Local Cloud** | The community project and GitHub org. Shows up in repo URLs, `azurelocal.cloud` site, and org references. Not a fictional identity — this is the real project name. |

### Fictional Identity

All example configs, resource names, domains, tenants, and walkthroughs use **one** fictional company:

| Name | Abbreviation | Domain | Description |
|------|:------------:|--------|-------------|
| **Infinite Improbability Corp** | **IIC** | `iic.local` / `iic.cloud` | The fictional customer/tenant used across all examples. A nod to *The Hitchhiker's Guide to the Galaxy*. |

**Use IIC everywhere you'd normally reach for `contoso`:**

- AD domains: `iic.local`, `IIC` (NetBIOS)
- Resource names: `rg-iic-avd-hp-eus-01`, `kv-iic-platform`, `rg-iic-avd-sh-eus-01`
- OUs: `OU=Servers,DC=iic,DC=local`
- User accounts: `svc.iic.deploy`, `admin@iic.local`
- Tenant references: "Infinite Improbability Corp's production AVD environment"

!!! warning "Consistency"
    Never use `contoso`, `fabrikam`, `adventure-works`, or other Microsoft example names. **IIC only.**
