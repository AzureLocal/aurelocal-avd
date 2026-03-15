# Azure CLI – AVD on Azure Local

Bash scripts using the Azure CLI for deploying Azure Virtual Desktop on Azure Local.

---

## Folder Structure

```
azure-cli/
├── control-plane/
│   ├── deploy-avd-control-plane.sh   # Deploy host pool, app group, workspace, Key Vault, Log Analytics
│   └── parameters.example.sh         # Example parameters file
└── session-hosts/
    ├── deploy-session-hosts.sh       # Deploy session-host VMs on Azure Local
    └── parameters.example.sh         # Example parameters file
```

---

## Prerequisites

- Azure CLI >= 2.50: [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- AVD extension: `az extension add --name desktopvirtualization`
- Logged in: `az login`
- Target subscription set: `az account set --subscription <id>`

---

## Control Plane Deployment

```bash
cd azure-cli/control-plane
cp parameters.example.sh parameters.sh
# Edit parameters.sh
bash deploy-avd-control-plane.sh
```

---

## Session Host Deployment

```bash
cd azure-cli/session-hosts
cp parameters.example.sh parameters.sh
# Edit parameters.sh
bash deploy-session-hosts.sh
```
