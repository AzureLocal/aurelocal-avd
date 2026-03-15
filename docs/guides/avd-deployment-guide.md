# AVD Deployment Guide

A comprehensive step-by-step guide for deploying Azure Virtual Desktop on Azure Local.

---

## Overview

This guide walks through a complete AVD deployment using the IaC tools in this repository. It covers:

1. Setting up configuration
2. Deploying the AVD control plane in Azure
3. Deploying session hosts on Azure Local
4. Post-deployment configuration with Ansible
5. Validation and testing

---

## Step 1 – Configuration

Copy the example config and fill in your values:

```bash
cp config/variables.example.yml config/variables.yml
```

See [Variable Reference](../reference/variables.md) for details on each parameter.

---

## Step 2 – Deploy the AVD Control Plane

The control plane creates Azure resources: host pool, application group, workspace, Key Vault, and Log Analytics workspace.

=== "Bicep"

    ```bash
    cd src/bicep
    cp control-plane.bicepparam.example control-plane.bicepparam
    # Edit control-plane.bicepparam
    az deployment sub create \
      --location eastus \
      --template-file control-plane.bicep \
      --parameters control-plane.bicepparam
    ```

=== "Terraform"

    ```bash
    cd src/terraform
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars
    terraform init
    terraform plan -target=azurerm_resource_group.avd -target=azurerm_virtual_desktop_host_pool.avd
    terraform apply
    ```

=== "PowerShell"

    ```powershell
    cd src/powershell
    cp parameters.example.ps1 parameters.ps1
    # Edit parameters.ps1
    .\New-AVDControlPlane.ps1 -ParametersFile .\parameters.ps1
    ```

=== "Azure CLI"

    ```bash
    cd scripts
    cp parameters.example.env parameters.env
    # Edit parameters.env
    source parameters.env
    bash deploy-avd-control-plane.sh
    ```

---

## Step 3 – Deploy Session Hosts

Session hosts are Arc-enabled VMs on your Azure Local cluster.

=== "Bicep"

    ```bash
    cd src/bicep
    cp session-hosts.bicepparam.example session-hosts.bicepparam
    az deployment group create \
      --resource-group <rg> \
      --template-file session-hosts.bicep \
      --parameters session-hosts.bicepparam
    ```

=== "Terraform"

    ```bash
    cd src/terraform
    terraform plan
    terraform apply
    ```

=== "PowerShell"

    ```powershell
    cd src/powershell
    .\New-AVDSessionHosts.ps1 -ParametersFile .\parameters.ps1
    ```

---

## Step 4 – Post-Deployment Configuration (Optional)

Use Ansible to configure session hosts after deployment:

```bash
cd src/ansible
cp inventory/hosts.example.yml inventory/hosts.yml
# Edit inventory/hosts.yml
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

---

## Step 5 – Validate

```powershell
Get-AzWvdSessionHost -ResourceGroupName <rg> -HostPoolName <pool>
```

All hosts should show `Status = Available`.

---

## Next Steps

- Review [deployment scenarios](../scenarios.md) for different configurations
- Set up CI/CD pipelines using the examples in `examples/pipelines/` for automated deployments
- Deploy [FSLogix profiles](https://github.com/AzureLocal/azurelocal-sofs-fslogix) with the companion repo
