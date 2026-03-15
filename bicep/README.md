# Bicep – AVD on Azure Local

Bicep templates for deploying Azure Virtual Desktop on Azure Local.

---

## Folder Structure

```
bicep/
├── control-plane/
│   ├── main.bicep                    # Subscription-scope entry point
│   ├── main.bicepparam.example       # Example parameters file
│   └── modules/
│       ├── resourceGroup.bicep
│       ├── logAnalytics.bicep
│       ├── keyVault.bicep
│       ├── hostPool.bicep
│       ├── applicationGroup.bicep
│       └── workspace.bicep
└── session-hosts/
    ├── main.bicep                    # Resource-group-scope entry point
    ├── main.bicepparam.example       # Example parameters file
    └── modules/
        ├── networkInterface.bicep
        └── sessionHost.bicep
```

---

## Prerequisites

- Azure CLI >= 2.50 with Bicep CLI: `az bicep install`
- Or Azure PowerShell >= 9.0

---

## Control Plane Deployment

```bash
cd bicep/control-plane
cp main.bicepparam.example main.bicepparam
# Edit main.bicepparam with your values

az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters main.bicepparam
```

---

## Session Host Deployment

```bash
cd bicep/session-hosts
cp main.bicepparam.example main.bicepparam
# Edit main.bicepparam

az deployment group create \
  --resource-group rg-avd-prod \
  --template-file main.bicep \
  --parameters main.bicepparam
```

---

## Validation (what-if)

```bash
az deployment sub what-if \
  --location eastus \
  --template-file bicep/control-plane/main.bicep \
  --parameters bicep/control-plane/main.bicepparam
```
