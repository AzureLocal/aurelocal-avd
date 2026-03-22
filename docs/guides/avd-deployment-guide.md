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

The canonical contract for all tooling is `config/variables.yml` validated by `config/schema/variables.schema.json`.

---

## Step 1 – Configuration

Copy the example config and fill in your values:

```bash
cp config/variables.example.yml config/variables.yml
```

See [Variable Reference](../reference/variables.md) for details on each parameter.

Also review:

- [Variable Mapping](../reference/variable-mapping.md)
- [Tool Parity Matrix](../reference/tool-parity-matrix.md)
- [Phase Ownership](../reference/phase-ownership.md)
- [Monitoring Queries](../reference/monitoring-queries.md)

---

## Step 2 – Deploy the AVD Control Plane

The control plane creates Azure resources: host pool, application group, workspace, Key Vault, and Log Analytics workspace.

=== "Bicep"

    ```bash
    cd src/bicep
        # preferred path: canonical orchestrator reads config/variables.yml
        pwsh ./Deploy-AVDSessionHosts.ps1 -ControlPlaneOnly
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
    # transitional mode is still supported
    .\New-AVDControlPlane.ps1 -ConfigFile ..\..\config\variables.yml
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
        # subscription-scope wrapper creates/targets resource groups via module
        pwsh ./Deploy-AVDSessionHosts.ps1 -SkipControlPlane
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
    .\New-AVDSessionHosts.ps1 -ConfigFile ..\..\config\variables.yml
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

Ansible role coverage includes control plane, session hosts, diagnostics, RBAC, FSLogix, and validation checks.

---

## Step 5 – Validate

```powershell
Get-AzWvdSessionHost -ResourceGroupName <rg> -HostPoolName <pool>
```

All hosts should show `Status = Available`.

Run monitoring checks in Log Analytics using [Monitoring Queries](../reference/monitoring-queries.md).

---

## Next Steps

- Review [deployment scenarios](../scenarios.md) for different configurations
- Set up CI/CD pipelines using the examples in `examples/pipelines/` for automated deployments
- Deploy [FSLogix profiles](https://github.com/AzureLocal/azurelocal-sofs-fslogix) with the companion repo
