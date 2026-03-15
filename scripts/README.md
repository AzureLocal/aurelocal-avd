# Scripts

Azure CLI / Bash utility scripts for deploying AVD on Azure Local.

## Files

| File | Description |
|------|-------------|
| `deploy-avd-control-plane.sh` | Deploy AVD control plane via Azure CLI |
| `deploy-session-hosts.sh` | Deploy session host VMs via Azure CLI |
| `parameters.example.env` | Example environment variables — copy to `parameters.env` and fill in your values |

## Usage

```bash
cd scripts
cp parameters.example.env parameters.env
# Edit parameters.env

# Control Plane
source parameters.env
bash deploy-avd-control-plane.sh

# Session Hosts
source parameters.env
bash deploy-session-hosts.sh
```

## Prerequisites

- Azure CLI 2.50+
- `bash` shell
