# Bicep – AVD on Azure Local

Bicep templates for deploying Azure Virtual Desktop on Azure Local.

---

## Folder Structure

```
src/bicep/
├── control-plane.bicep               # Subscription-scope entry point (creates RG + control plane)
├── control-plane.bicepparam.example   # Example parameters file
├── control-plane-resources.bicep      # Host pool, app group, workspace resources
├── session-hosts.bicep               # Subscription-scope entry point (creates RG + session hosts)
├── session-hosts.bicepparam.example   # Example parameters file
├── session-host-resources.bicep       # Arc machines, NICs, VM instances, extensions
└── Deploy-AVDSessionHosts.ps1        # End-to-end orchestrator script
```

---

## Prerequisites

- Azure CLI >= 2.50 with Bicep CLI: `az bicep install`
- Or Azure PowerShell >= 9.0

---

## Control Plane Deployment

```bash
cd src/bicep
cp control-plane.bicepparam.example control-plane.bicepparam
# Edit control-plane.bicepparam with your values

az deployment sub create \
  --location eastus \
  --template-file control-plane.bicep \
  --parameters control-plane.bicepparam
```

---

## Session Host Deployment

```bash
cd src/bicep
cp session-hosts.bicepparam.example session-hosts.bicepparam
# Edit session-hosts.bicepparam

az deployment sub create \
  --location eastus \
  --template-file session-hosts.bicep \
  --parameters session-hosts.bicepparam
```

> **Recommended:** Use the deploy script instead of manual `az deployment`
> commands. It handles registration token generation, Key Vault credential
> resolution, and session host naming automatically:
>
> ```powershell
> .\src\bicep\Deploy-AVDSessionHosts.ps1
> ```

---

## Validation (what-if)

```bash
az deployment sub what-if \
  --location eastus \
  --template-file src/bicep/control-plane.bicep \
  --parameters src/bicep/control-plane.bicepparam
```
