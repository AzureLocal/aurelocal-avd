# PowerShell – AVD on Azure Local

PowerShell scripts for deploying Azure Virtual Desktop on Azure Local.

---

## Folder Structure

```
powershell/
├── control-plane/
│   ├── New-AVDControlPlane.ps1       # Deploy host pool, app group, workspace, Key Vault, Log Analytics
│   └── parameters.example.ps1        # Example parameters file
└── session-hosts/
    ├── New-AVDSessionHosts.ps1       # Deploy session-host VMs on Azure Local
    └── parameters.example.ps1        # Example parameters file
```

---

## Prerequisites

- PowerShell 7.2 or later
- Az PowerShell module >= 9.0: `Install-Module Az -Force`
- Logged in to Azure: `Connect-AzAccount`
- Appropriate RBAC: Contributor (or custom AVD roles) on the target subscription

---

## Control Plane Deployment

```powershell
cd powershell/control-plane
cp parameters.example.ps1 parameters.ps1
# Edit parameters.ps1 with your environment values
.\New-AVDControlPlane.ps1 -ParametersFile .\parameters.ps1
```

Or pass parameters directly:

```powershell
.\New-AVDControlPlane.ps1 `
  -ResourceGroupName "rg-avd-prod" `
  -Location "eastus" `
  -HostPoolName "hp-azurelocal-pool01" `
  -HostPoolType "Pooled" `
  -WorkspaceName "ws-avd-prod" `
  -AppGroupName "ag-desktops"
```

---

## Session Host Deployment

```powershell
cd powershell/session-hosts
cp parameters.example.ps1 parameters.ps1
# Edit parameters.ps1 with your Azure Local cluster details
.\New-AVDSessionHosts.ps1 -ParametersFile .\parameters.ps1
```

---

## Parameters Reference

See the `parameters.example.ps1` in each subfolder for a full list of supported parameters.

For automated end-to-end deployments (including Key Vault credential resolution and
AVD registration token generation), use the deploy scripts in `deploy/` instead:

```powershell
.\deploy\Deploy-AVDSessionHosts.ps1           # Bicep-based (full deployment)
.\deploy\Deploy-AVDSessionHosts-ARM.ps1       # ARM-based (session hosts only)
```
