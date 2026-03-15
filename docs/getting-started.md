# Getting Started

This guide walks you through deploying Azure Virtual Desktop on Azure Local using this repository.

---

## Prerequisites

### Azure

- Azure subscription (Contributor or Owner role, or custom AVD role)
- Microsoft Entra ID (Azure AD) tenant
- Azure Virtual Desktop service principal / resource provider registered:
  ```bash
  az provider register --namespace Microsoft.DesktopVirtualization
  ```

### Azure Local

- Azure Local cluster (version 23H2 or later) deployed and registered with Azure Arc
- Arc Resource Bridge installed and running on the cluster
- Custom location created for the Arc Resource Bridge
- Sufficient compute and storage capacity for session-host VMs

### Tooling (choose one or more)

| Tool | Minimum Version | Install |
|------|-----------------|---------|
| PowerShell | 7.2+ | [Install](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |
| Az PowerShell module | 9.0+ | `Install-Module Az -Force` |
| Azure CLI | 2.50+ | [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Bicep CLI | 0.22+ | `az bicep install` |
| Terraform | 1.5+ | [Install](https://developer.hashicorp.com/terraform/downloads) |
| Ansible | 2.14+ | `pip install ansible` + `ansible-galaxy collection install azure.azcollection` |

---

## Step 1 – Clone This Repository

```bash
git clone https://github.com/AzureLocal/aurelocal-avd.git
cd aurelocal-avd
```

---

## Step 2 – Deploy the AVD Control Plane in Azure

The control plane creates the host pool, application group, workspace, and supporting resources (Key Vault, Log Analytics, Storage) in your Azure subscription.

Pick your preferred tool:

### Option A – Bicep

```bash
cd src/bicep
cp control-plane.bicepparam.example control-plane.bicepparam
# Edit control-plane.bicepparam with your values
az deployment sub create \
  --location eastus \
  --template-file control-plane.bicep \
  --parameters control-plane.bicepparam
```

### Option B – PowerShell

```powershell
cd src/powershell
cp parameters.example.ps1 parameters.ps1
# Edit parameters.ps1 with your values
.\New-AVDControlPlane.ps1 -ParametersFile .\parameters.ps1
```

### Option C – Azure CLI

```bash
cd scripts
cp parameters.example.env parameters.env
# Edit parameters.env with your values
source parameters.env
bash deploy-avd-control-plane.sh
```

### Option D – Terraform

```bash
cd src/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

---

## Step 3 – Note the Host Pool Registration Token

After Step 2, retrieve the registration token. The session-host deployment scripts use it to register VMs with the host pool.

```powershell
# PowerShell
$token = Get-AzWvdRegistrationInfo -ResourceGroupName <rg> -HostPoolName <pool>
$token.Token
```

```bash
# Azure CLI
az desktopvirtualization hostpool retrieve-registration-token \
  --resource-group <rg> \
  --name <pool> \
  --query registrationInfo.token -o tsv
```

Store this token in Azure Key Vault:

```bash
az keyvault secret set \
  --vault-name <kv-name> \
  --name avd-registration-token \
  --value "<token>"
```

---

## Step 4 – Deploy Session Hosts on Azure Local

Session hosts are Arc-enabled VMs deployed on your Azure Local cluster.

### Option A – Bicep

```bash
cd src/bicep
cp session-hosts.bicepparam.example session-hosts.bicepparam
# Edit session-hosts.bicepparam (set customLocationId, hostPoolRegistrationToken, etc.)
az deployment group create \
  --resource-group <rg> \
  --template-file session-hosts.bicep \
  --parameters session-hosts.bicepparam
```

### Option B – PowerShell

```powershell
cd src/powershell
# parameters.ps1 should already exist from control-plane step
.\New-AVDSessionHosts.ps1 -ParametersFile .\parameters.ps1
```

### Option C – Terraform

```bash
cd src/terraform
# terraform.tfvars should already exist from control-plane step
terraform plan
terraform apply
```

---

## Step 5 – Validate the Deployment

```powershell
# Check session hosts are registered and available
Get-AzWvdSessionHost -ResourceGroupName <rg> -HostPoolName <pool>
```

All hosts should show `Status = Available` after the VMs boot and the AVD agent completes registration.

---

## Step 6 – Configure FSLogix (Optional but Recommended)

For profile persistence deploy a Scale Out File Server using the companion repository:

```
https://github.com/AzureLocal/azurelocal-sofs-fslogix
```

Then set the FSLogix VHD location on session hosts:

```powershell
# Group Policy or registry
Set-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" `
  -Name VHDLocations -Value "\\<SOFS-Name>\FSLogixProfiles"
Set-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" `
  -Name Enabled -Value 1
```

---

## Next Steps

- Review [deployment scenarios](./scenarios.md) for more configurations.
- Set up CI/CD pipelines using the examples in `examples/pipelines/` for automated deployments.
- Review the [architecture overview](./architecture.md) to understand the full solution.
