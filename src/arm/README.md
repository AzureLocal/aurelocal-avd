# ARM Template Deployment

ARM JSON templates for deploying AVD on Azure Local.

## Files

| File | Description |
|------|-------------|
| `control-plane.json` | ARM template for AVD control plane resources |
| `control-plane.parameters.example.json` | Example parameters for control plane |
| `session-hosts.json` | ARM template for session host VMs |
| `session-hosts.parameters.example.json` | Example parameters for session hosts |
| `Deploy-AVDSessionHosts-ARM.ps1` | PowerShell orchestrator script for ARM deployments |

## Usage

```bash
# Control Plane
az deployment sub create \
  --location eastus \
  --template-file src/arm/control-plane.json \
  --parameters @src/arm/control-plane.parameters.example.json

# Session Hosts (via orchestrator)
cd src/arm
.\Deploy-AVDSessionHosts-ARM.ps1
```
