# Deploy

End-to-end deployment scripts that orchestrate the full AVD-on-Azure-Local workflow:
control plane provisioning, registration token generation, credential resolution, and
session host creation.

## Scripts

| Script | Template Engine | What It Deploys |
|--------|----------------|-----------------|
| `Deploy-AVDSessionHosts.ps1` | **Bicep** | Control plane + session hosts (batch) |
| `Deploy-AVDSessionHosts-ARM.ps1` | **ARM JSON** | Session hosts only (per-VM loop) |

### Deploy-AVDSessionHosts.ps1 (Bicep)

Full deployment — control plane **and** session hosts.

```powershell
# Deploy everything (control plane + session hosts)
.\deploy\Deploy-AVDSessionHosts.ps1

# Control plane only (host pool, app group, workspace)
.\deploy\Deploy-AVDSessionHosts.ps1 -ControlPlaneOnly

# Session hosts only (skip control plane)
.\deploy\Deploy-AVDSessionHosts.ps1 -SkipControlPlane

# Override count / prefix
.\deploy\Deploy-AVDSessionHosts.ps1 -SessionHostCount 5 -VmNamingPrefix "avd-prod"

# Dry run (WhatIf)
.\deploy\Deploy-AVDSessionHosts.ps1 -WhatIf
```

### Deploy-AVDSessionHosts-ARM.ps1 (ARM)

Session hosts only — deploys one VM per iteration using the ARM JSON template.

```powershell
# Deploy 3 session hosts
.\deploy\Deploy-AVDSessionHosts-ARM.ps1 -SessionHostCount 3

# Dry run
.\deploy\Deploy-AVDSessionHosts-ARM.ps1 -WhatIf
```

> **When to use which?** The Bicep variant deploys all session hosts in a single
> deployment (parallel resource creation). The ARM variant loops per-VM, which is
> useful for incremental additions or debugging a single host.

## Prerequisites

| Requirement | Install |
|-------------|---------|
| PowerShell 7+ | `winget install Microsoft.PowerShell` |
| Az PowerShell | `Install-Module Az -Scope CurrentUser` |
| Az.DesktopVirtualization | `Install-Module Az.DesktopVirtualization` |
| Az.KeyVault | `Install-Module Az.KeyVault` |
| `config/variables.yml` | Copy `config/variables.example.yml` and fill in your values |
| Azure login | `Connect-AzAccount` |

## How It Works

1. **Load config** — reads `config/variables.yml`
2. **Control plane** *(Bicep variant only)* — deploys host pool, app group, workspace
3. **Registration token** — generates a short-lived (4-hour) AVD registration token via `New-AzWvdRegistrationInfo`
4. **Credential resolution** — resolves `keyvault://` URIs from config (admin password, domain join password) using `Az.KeyVault` with `az CLI` fallback
5. **Session host deployment** — deploys VMs on Azure Local with domain join + AVD agent installation
6. **Cleanup** — nulls credential variables and forces garbage collection

## Workflow

```
config/  →  infrastructure/  →  deploy/ (you are here)  →  configure/  →  tests/
```

## Contributing

See the [Contributing Guide](../docs/contributing.md) for standards.
