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

```bash
az deployment group create \
  --resource-group rg-avd-prod \
  --template-file arm/session-hosts/azuredeploy.json \
  --parameters @arm/session-hosts/azuredeploy.parameters.json
```

---

> **Note**: Do not store secrets in parameter files. Use Key Vault references:
> ```json
> "registrationToken": {
>   "reference": {
>     "keyVault": { "id": "/subscriptions/.../vaults/kv-avd-prod-001" },
>     "secretName": "avd-registration-token"
>   }
> }
> ```
