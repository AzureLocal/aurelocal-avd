# Networking

Network configuration for AVD on Azure Local includes NSG rules for required outbound traffic and optional private endpoints.

## Required Outbound Rules

AVD session hosts need outbound access to these Azure service tags:

| Rule | Service Tag | Port | Purpose |
|------|------------|------|---------|
| Allow-AVD-Service | WindowsVirtualDesktop | 443 | AVD broker communication |
| Allow-AzureMonitor | AzureMonitor | 443 | Diagnostics and monitoring |
| Allow-AzureAD | AzureActiveDirectory | 443 | Authentication (Entra ID) |
| Allow-KMS | Internet | 1688 | Windows activation |

## Configuration

```yaml
networking:
  private_endpoints:
    enabled: false
    subnet_id: "/subscriptions/.../subnets/pe-subnet"
    dns_zone_id: ""
  nsg:
    enabled: true
    name: "hp-pool01-nsg"
```

## Private Endpoints

Private endpoints keep AVD control plane traffic on the Microsoft backbone:

- **Host Pool** — `connection` sub-resource
- **Workspace** — `feed` sub-resource

### Prerequisites

- A dedicated subnet for private endpoints
- Private DNS zone: `privatelink.wvd.microsoft.com`
- DNS forwarding from on-premises to Azure Private DNS

## Deployment

### PowerShell

```powershell
.\src\powershell\Configure-AVDNetworking.ps1 -ConfigPath config/variables.yml
```

### Terraform

```hcl
nsg_enabled                = true
private_endpoints_enabled  = true
private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.wvd.microsoft.com"
```

### Bicep

Deploy `networking.bicep`:

```bash
az deployment group create \
  --resource-group rg-avd-prod \
  --template-file src/bicep/networking.bicep \
  --parameters nsgName=hp-pool01-nsg ...
```

### Ansible

```bash
ansible-playbook src/ansible/playbooks/site.yml -i inventory.yml --tags networking
```
