# PowerShell Deployment Scripts

PowerShell Az module scripts for deploying AVD on Azure Local.

## Files

| File | Description |
|------|-------------|
| `New-AVDControlPlane.ps1` | Deploy AVD control plane (host pool, app group, workspace, Key Vault, LAW) |
| `New-AVDSessionHosts.ps1` | Deploy session host VMs on Azure Local |
| `parameters.example.ps1` | Example parameter file — copy to `parameters.ps1` and fill in your values |

## Usage

```powershell
cd src/powershell

# Control Plane
cp parameters.example.ps1 parameters.ps1
# Edit parameters.ps1
.\New-AVDControlPlane.ps1 -ParametersFile .\parameters.ps1

# Session Hosts
.\New-AVDSessionHosts.ps1 -ParametersFile .\parameters.ps1
```

## Prerequisites

- PowerShell 7.2+
- Az PowerShell module 9.0+ (`Install-Module Az -Force`)
- Az.DesktopVirtualization module
