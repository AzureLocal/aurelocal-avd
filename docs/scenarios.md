# Deployment Scenarios

This document describes the primary deployment scenarios supported by this repository.

---

## Scenario 1 – Pooled Host Pool (Multi-Session Windows)

**Use case**: Shared desktop environment where multiple users log in to the same VM simultaneously. Best for task workers with homogeneous workloads.

**Architecture**:
- Control plane: Azure (host pool type = Pooled, load-balancer type = BreadthFirst or DepthFirst)
- Session hosts: Windows 11 Enterprise Multi-Session or Windows Server 2022 on Azure Local
- Profiles: FSLogix on SOFS (companion repo) or Azure Files

**Deployment steps**:
1. Deploy the AVD control plane (host pool, app group, workspace) in Azure.
2. Deploy pooled session-host VMs on Azure Local.
3. Domain-join VMs and register them with the host pool.
4. Configure FSLogix on session hosts pointing to the SOFS share.

**Tool examples**: `src/bicep/control-plane.bicep` + `src/bicep/session-hosts.bicep`

---

## Scenario 2 – Personal Host Pool (Persistent Desktops)

**Use case**: Dedicated desktop per user. Users get the same VM every session. Best for power users or developers who need to install software.

**Architecture**:
- Control plane: Azure (host pool type = Personal, assignment type = Automatic or Direct)
- Session hosts: Windows 11 Enterprise on Azure Local (one VM per assigned user)
- Profiles: Local profile or FSLogix for roaming (optional)

**Deployment steps**:
1. Deploy the AVD control plane with `hostPoolType = Personal`.
2. Deploy personal session-host VMs on Azure Local (sized appropriately per user).
3. Domain-join VMs and register them with the host pool.
4. Optionally assign users to specific VMs via Azure portal or automation.

**Tool examples**: `src/powershell/New-AVDControlPlane.ps1` + `src/powershell/New-AVDSessionHosts.ps1`

---

## Scenario 3 – Hybrid Deployment (Azure + Azure Local Session Hosts)

**Use case**: Burst capacity or migration scenario where some session hosts run in Azure and some run on Azure Local. Useful during datacenter migrations or for DR.

**Architecture**:
- Control plane: Azure (single host pool spanning both Azure and Azure Local hosts)
- Session hosts: Mix of Azure VMs and Azure Local VMs registered to the same host pool
- Profiles: Azure Files (accessible from both locations) or FSLogix cloud cache

**Deployment steps**:
1. Deploy the AVD control plane in Azure.
2. Deploy Azure-based session hosts using standard AVD procedures.
3. Deploy Azure Local session hosts from this repository.
4. Both sets of hosts register to the same host pool using the registration token.
5. Configure FSLogix cloud cache or Azure Files for profile portability.

**Tool examples**: `src/terraform/control-plane.tf` + `src/terraform/session-hosts.tf`

---

## Scenario 4 – Greenfield End-to-End Deployment

**Use case**: Brand new environment – no existing Azure Local cluster or AVD setup. Deploys everything from scratch.

**Deployment order**:
1. **Azure Local cluster** – Deploy and register cluster with Azure Arc (out of scope for this repo; see [Azure Local deployment docs](https://learn.microsoft.com/en-us/azure/azure-local/deploy/deployment-introduction)).
2. **SOFS + FSLogix share** – Deploy using the [companion repository](https://github.com/AzureLocal/azurelocal-sofs-fslogix).
3. **AVD control plane** – Deploy host pool, app group, workspace using any tool in this repo.
4. **AVD session hosts** – Deploy VMs on Azure Local and register with the host pool.
5. **CI/CD pipeline** – Wire up ongoing session-host lifecycle management using `.github/workflows/` and the pipeline examples in `examples/pipelines/`.

---

## Scenario 5 – MSIX App Attach

**Use case**: Application delivery via MSIX packages without installing apps directly on the session-host image. Reduces image maintenance overhead.

**Additional components**:
- Azure Storage account or Azure Files share for MSIX package storage
- MSIX package signing certificate in Key Vault

**Deployment steps**:
1. Complete Scenario 1 or 2 above.
2. Create an Azure Storage account (or Azure Files share) for MSIX packages.
3. Upload signed `.msix` / `.msixbundle` packages.
4. Register MSIX packages in the AVD host pool via Azure portal or automation.
5. Assign MSIX apps to application groups.

---

## Choosing the Right Tool

| Scenario | Recommended Tool | Reason |
|----------|-----------------|--------|
| Small / one-off deployment | PowerShell or Azure CLI | Quick, interactive, easy to adapt |
| Repeatable infrastructure | Bicep | Native ARM language, strong tooling, type-safe |
| Multi-cloud / existing Terraform estate | Terraform | Consistent workflow across cloud providers |
| Configuration management post-deploy | Ansible | Idempotent OS-level configuration |
| Automated CI/CD | GitHub Actions or Azure DevOps | Triggered deployments on PR/push |
