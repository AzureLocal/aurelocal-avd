# Examples & IIC Policy

> **Canonical reference:** [Fictional Company Policy (full)](https://azurelocal.cloud/standards/fictional-company-policy)  
> **Applies to:** All AzureLocal repositories  
> **Last Updated:** 2026-03-17

---

## Policy

All examples, sample configurations, and walkthroughs use **one** fictional company: **Infinite Improbability Corp (IIC)**.

!!! warning "Mandatory"
    Never use `contoso`, `fabrikam`, `adventure-works`, `woodgrove`, `example.com`, or any real customer name.
    **IIC only** — in every repo, every example, every sample config.

---

## IIC Reference Card

| Attribute | Value |
|-----------|-------|
| **Full Name** | Infinite Improbability Corp |
| **Abbreviation** | IIC |
| **Domain (public)** | `improbability.cloud` / `iic.cloud` |
| **Domain (on-prem AD)** | `iic.local` |
| **NetBIOS Name** | `IMPROBABLE` |
| **Entra ID Tenant** | `improbability.onmicrosoft.com` |
| **Email Pattern** | `user@improbability.cloud` |

---

## AVD Naming Patterns

### Azure Resources

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `rg-iic-avd-<##>` | `rg-iic-avd-01` |
| Host Pool | `hp-iic-<type>-<##>` | `hp-iic-pooled-01` |
| Workspace | `ws-iic-avd-<##>` | `ws-iic-avd-01` |
| Application Group | `ag-iic-<type>-<##>` | `ag-iic-desktop-01` |
| Session Host | `vm-iic-avd-<##>` | `vm-iic-avd-01` through `vm-iic-avd-50` |
| Key Vault | `kv-iic-<purpose>` | `kv-iic-platform` |
| Storage Account | `stiic<purpose><##>` | `stiicprofiles01` |
| Log Analytics | `law-iic-<purpose>-<##>` | `law-iic-monitor-01` |

### Active Directory

| Resource | Pattern | Example |
|----------|---------|---------|
| OU path | `OU=AVD,OU=Servers,DC=iic,DC=local` | — |
| Service account | `svc.iic.<purpose>` | `svc.iic.avd-join` |
| Group | `grp-iic-<purpose>` | `grp-iic-avd-users` |

### IP Addresses

| Network | Range | Usage |
|---------|-------|-------|
| Management | `10.0.0.0/24` | Node management |
| Compute | `10.0.2.0/24` | Session host traffic |

---

## Real Identities

| Name | Usage |
|------|-------|
| **Azure Local Cloud** | Community project, GitHub org, `azurelocal.cloud` |
| **Hybrid Cloud Solutions** | Author/maintainer LLC, script headers, copyright |

---

## Usage Examples

### In `config/variables.example.yml`

```yaml
subscription:
  avd_subscription_id: "00000000-0000-0000-0000-000000000000"
  tenant_id: "00000000-0000-0000-0000-000000000000"
  location: "eastus"

security:
  keyvault_name: "kv-iic-platform"

control_plane:
  host_pool_name: "hp-iic-pooled-01"
  workspace_name: "ws-iic-avd-01"
```

### In Documentation

> Infinite Improbability Corp's AVD environment uses a pooled host pool (`hp-iic-pooled-01`)
> with breadth-first load balancing across 50 session hosts on Azure Local.

---

## Enforcement

- **PR review**: Reviewers flag any use of `contoso`, `fabrikam`, or other non-IIC names
- **Config validation**: `variables.example.yml` uses IIC naming in all placeholders
- **CI**: Vale linting rules flag non-IIC fictional company names (when configured)
