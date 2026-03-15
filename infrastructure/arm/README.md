# ARM – AVD on Azure Local

ARM JSON templates for deploying Azure Virtual Desktop on Azure Local.

---

## Folder Structure

```
arm/
├── control-plane/
│   ├── azuredeploy.json                        # Subscription-scope ARM template
│   └── azuredeploy.parameters.example.json     # Example parameters file
└── session-hosts/
    ├── azuredeploy.json                        # Resource-group-scope ARM template
    └── azuredeploy.parameters.example.json     # Example parameters file
```

---

## Prerequisites

- Azure CLI >= 2.50 or Azure PowerShell >= 9.0

---

## Control Plane Deployment

```bash
# Azure CLI
az deployment sub create \
  --location eastus \
  --template-file arm/control-plane/azuredeploy.json \
  --parameters @arm/control-plane/azuredeploy.parameters.json

# PowerShell
New-AzSubscriptionDeployment \
  -Location eastus \
  -TemplateFile arm/control-plane/azuredeploy.json \
  -TemplateParameterFile arm/control-plane/azuredeploy.parameters.json
```

---

## Session Host Deployment

The ARM session-host template deploys a **single VM** per invocation. For multi-VM
deployments, use the deploy script which loops and handles credential resolution:

```powershell
.\deploy\Deploy-AVDSessionHosts-ARM.ps1 -SessionHostCount 3
```

Or deploy manually:

```bash
az deployment group create \
  --resource-group rg-avd-prod \
  --template-file arm/session-hosts/azuredeploy.json \
  --parameters @arm/session-hosts/azuredeploy.parameters.json
```

---

> **Note**: The ARM session-host template requires a `commandToExecute` parameter
> (SecureString) that combines domain join + AVD agent installation into a single
> Custom Script Extension. The deploy script builds this automatically.
>
> Do not store secrets in parameter files — use `keyvault://` URIs in `config/variables.yml`.
