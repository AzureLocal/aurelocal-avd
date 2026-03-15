# Bicep – AVD on Azure Local

Bicep templates for deploying Azure Virtual Desktop on Azure Local.

---

## Folder Structure

```
bicep/
├── control-plane/
│   ├── main.bicep                    # Subscription-scope entry point (creates RG)
│   ├── main.bicepparam.example       # Example parameters file
│   └── modules/
│       └── controlPlaneResources.bicep   # Host pool, app group, workspace
└── session-hosts/
    ├── main.bicep                    # Subscription-scope entry point (creates RG)
    ├── main.bicepparam.example       # Example parameters file
    └── modules/
        └── sessionHostResources.bicep    # Arc machines, NICs, VM instances, extensions
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

az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters main.bicepparam
```

> **Recommended:** Use the deploy scripts in `deploy/` instead of manual `az deployment`
> commands. They handle registration token generation, Key Vault credential resolution,
> and session host naming automatically.

---

## Validation (what-if)

```bash
az deployment sub what-if \
  --location eastus \
  --template-file bicep/control-plane/main.bicep \
  --parameters bicep/control-plane/main.bicepparam
```
