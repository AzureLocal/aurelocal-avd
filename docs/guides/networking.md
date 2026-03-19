# Networking

This guide explains every networking component deployed for AVD on Azure Local — exactly what NSG rules are created and why each one exists, how private endpoints work for AVD control plane isolation, how DNS resolution ties it together, and how each IaC tool implements the resources.

## Why Networking Configuration Matters

AVD session hosts are Arc-enabled VMs sitting in your Azure Local logical network. They need to talk to several Azure services over the internet to function:

- The **AVD broker** (to register themselves, receive connection assignments, send heartbeats)
- **Entra ID** (to validate user tokens for Hybrid Join)
- **Azure Monitor** (to ship diagnostics and performance counters)
- **Windows KMS** (to activate the Windows license)

Without proper NSG rules, session hosts can't communicate with these services and AVD breaks. With private endpoints, you can move the AVD broker and workspace traffic off the public internet entirely, keeping it on the Microsoft backbone network — important for compliance and security-sensitive environments.

![AVD Networking — NSG Rules, Private Endpoints & DNS](../assets/diagrams/avd-networking.png)

> *Open the [draw.io source](../assets/diagrams/avd-networking.drawio) for an editable version.*

---

## What Gets Deployed

| Azure Resource Type | Resource Name | What It Is |
|---|---|---|
| `Microsoft.Network/networkSecurityGroups` | `${nsg_name}` | Network Security Group attached to the session host subnet. Contains 4 outbound allow rules for AVD-required traffic. |
| `Microsoft.Network/networkSecurityGroups/securityRules` | 4 inline rules (priorities 100-130) | Individual NSG rules allowing outbound HTTPS to Azure service tags + KMS activation. |
| `Microsoft.Network/privateEndpoints` | `${host_pool_name}-pe` | Private endpoint for the AVD Host Pool. Creates a NIC in the PE subnet (in the **Azure VNet**, not the Azure Local logical network) with a private IP that routes to the AVD `connection` sub-resource. |
| `Microsoft.Network/privateEndpoints` | `${workspace_name}-pe` | Private endpoint for the AVD Workspace. Creates a NIC in the PE subnet with a private IP that routes to the AVD `feed` sub-resource. |
| `Microsoft.Network/privateEndpoints` | `${global_workspace_name}-global-pe` | Private endpoint for initial feed discovery. Creates a NIC in the PE subnet with a private IP that routes to the AVD `global` sub-resource. Only ONE needed across all AVD deployments. |
| `Microsoft.Network/privateEndpoints/privateDnsZoneGroups` | Auto-created | Links `connection` and `feed` PEs to `privatelink.wvd.microsoft.com`. Links `global` PE to `privatelink-global.wvd.microsoft.com`. Automatically creates A records so domain names resolve to private IPs. |

---

## NSG Rules — Every Rule Explained

The NSG has 4 outbound rules, each targeting a specific Azure service tag. Service tags are Microsoft-managed IP address groups that automatically update as Azure adds or changes IP ranges.

### Rule 1: Allow-AVD-Service (Priority 100)

| Property | Value |
|---|---|
| Direction | Outbound |
| Priority | 100 |
| Protocol | TCP |
| Source | `*` (any address in the subnet) |
| Destination | Service Tag: `WindowsVirtualDesktop` |
| Destination Port | 443 (HTTPS) |
| Action | Allow |

**Why it exists:** Session hosts communicate with the AVD control plane over HTTPS 443. This includes:

- **Agent registration** — When a session host boots, the AVD agent (`RDAgentBootLoader`) contacts `rdbroker.wvd.microsoft.com` to register itself in the host pool
- **Heartbeats** — Every 30 seconds, the agent sends a heartbeat. If 3 consecutive heartbeats are missed, the host shows as "Unavailable" in the portal
- **Reverse connect** — When a user connects, the broker tells the session host to establish a reverse-connect WebSocket tunnel through the AVD gateway. This tunnel carries the RDP traffic; no inbound ports needed on the session host
- **Session orchestration** — Load balancing decisions, drain mode signals, and scaling plan commands all flow through this channel

The `WindowsVirtualDesktop` service tag resolves to ~200 IP ranges across Azure regions. Microsoft maintains it — you don't need to update it manually.

### Rule 2: Allow-AzureMonitor (Priority 110)

| Property | Value |
|---|---|
| Direction | Outbound |
| Priority | 110 |
| Protocol | TCP |
| Source | `*` |
| Destination | Service Tag: `AzureMonitor` |
| Destination Port | 443 |
| Action | Allow |

**Why it exists:** If monitoring is enabled, session hosts ship telemetry to Azure Monitor / Log Analytics:

- **Performance counters** — CPU, memory, disk, network via the Azure Monitor Agent (AMA) or legacy Log Analytics agent (MMA)
- **Windows Event Logs** — Application, System, and AVD-specific event channels (`Microsoft-Windows-TerminalServices-*`)
- **AVD Insights data** — Connection quality, session duration, round-trip time

Without this rule, monitoring data never reaches Log Analytics and your AVD Insights workbook shows blank.

### Rule 3: Allow-AzureAD (Priority 120)

| Property | Value |
|---|---|
| Direction | Outbound |
| Priority | 120 |
| Protocol | TCP |
| Source | `*` |
| Destination | Service Tag: `AzureActiveDirectory` |
| Destination Port | 443 |
| Action | Allow |

**Why it exists:** Required for Entra ID authentication in all identity strategies:

- **AD-Only** — Even though session hosts don't use Entra ID for login, the AVD agent still needs Entra ID to validate the broker connection token
- **Hybrid Join** — The `AADLoginForWindows` extension communicates with `login.microsoftonline.com` and `device.login.microsoftonline.com` for device registration and PRT-based SSO. Azure AD Connect sync validation is also required.

> **Note:** Entra-only join is NOT supported on Azure Local. Only `ad_only` and `hybrid_join` strategies are available.

The `AzureActiveDirectory` service tag covers `login.microsoftonline.com`, `graph.microsoft.com`, `device.login.microsoftonline.com`, and related endpoints.

### Rule 4: Allow-KMS (Priority 130)

| Property | Value |
|---|---|
| Direction | Outbound |
| Priority | 130 |
| Protocol | TCP |
| Source | `*` |
| Destination | Service Tag: `Internet` |
| Destination Port | 1688 |
| Action | Allow |

**Why it exists:** Windows VMs must activate their license via the Azure KMS server at `azkms.core.windows.net:1688` (or `kms.core.windows.net:1688`). If activation fails:

- Windows shows "Activate Windows" watermark on the desktop
- After 30 days, the VM enters reduced-functionality mode
- Some Windows features (personalization, certain Group Policy settings) stop working

This rule uses the `Internet` service tag with a specific port (1688) rather than a KMS-specific tag because there is no dedicated Azure KMS service tag. Port 1688 is exclusively used by KMS.

### Default Deny

The NSG's built-in default rules deny all other outbound traffic not explicitly allowed. This means session hosts cannot reach arbitrary internet endpoints — only the four service tags above. If you need additional outbound access (e.g., for application downloads, Windows Update), add rules with priorities above 130.

---

## Private Endpoints — Deep Dive

> **Important — Azure Local Hybrid Architecture:** Private endpoints for AVD on Azure Local are an **advanced hybrid networking scenario**. Unlike standard Azure deployments where session hosts and PEs share the same VNet, on Azure Local the session hosts are on-premises while the private endpoints live in an Azure VNet. This requires ExpressRoute or Site-to-Site VPN connectivity between environments. Most Azure Local AVD deployments work well with the default public endpoints (TLS 1.2 encrypted). Only enable private endpoints if your compliance or security requirements demand it.

### What Private Endpoints Do

By default, AVD session hosts communicate with the AVD control plane over public endpoints (`rdbroker.wvd.microsoft.com`, `rdweb.wvd.microsoft.com`). This traffic goes over the public internet, encrypted via TLS 1.2.

Private endpoints create **network interfaces in an Azure Virtual Network** with private IP addresses that route to the AVD service. When DNS is configured correctly, the FQDN `rdbroker.wvd.microsoft.com` resolves to a private IP (e.g., `10.1.2.4`) instead of a public IP. All AVD control plane traffic stays on the Microsoft backbone — it never touches the public internet.

> **Azure Local distinction:** On Azure Local, session hosts sit on an on-premises logical network (`AzureStackHCI/logicalNetworks`), NOT in an Azure VNet. The private endpoints are deployed into a **separate Azure VNet** in an Azure region. For on-premises session hosts to reach the private endpoint IPs, you must have **ExpressRoute or Site-to-Site VPN** connectivity between the Azure Local site and the Azure VNet hosting the PEs. See [Azure Local firewall requirements — Private Endpoints](https://learn.microsoft.com/azure/azure-local/concepts/firewall-requirements) for Microsoft's confirmation of this architecture.

### Prerequisites for Private Endpoints on Azure Local

Before enabling private endpoints, you must have the following infrastructure **already deployed**:

| Prerequisite | What It Is | Why It's Needed |
|---|---|---|
| **Azure VNet** | A Virtual Network in an Azure region (e.g., `vnet-hub-eastus`) | Private endpoint NICs are created here — they cannot be created in an Azure Local logical network. |
| **PE Subnet** | A dedicated subnet in the Azure VNet (e.g., `snet-pe`, `/28` minimum) | Houses the 3 private endpoint NICs. Must have enough IPs (minimum 3). |
| **ExpressRoute or Site-to-Site VPN** | Hybrid connectivity between your Azure Local site and the Azure VNet | On-premises session hosts need Layer 3 reachability to the PE private IPs in the Azure VNet. |
| **Azure DNS Private Resolver** | A DNS resolver deployed in the Azure VNet | On-premises DNS servers forward private DNS zone queries to this resolver. `168.63.129.16` is only reachable from within the Azure VNet. |
| **Private DNS Zones (2)** | `privatelink.wvd.microsoft.com` AND `privatelink-global.wvd.microsoft.com` | Each zone hosts A records for different PE sub-resources. Both must be linked to the Azure VNet. |

### Three Private Endpoints, Three Sub-Resources

AVD Private Link requires **three** separate private endpoints with distinct sub-resources:

| Private Endpoint | Sub-Resource | DNS Zone | What It Handles |
|---|---|---|---|
| Host Pool PE | `connection` | `privatelink.wvd.microsoft.com` | Agent registration, heartbeats, reverse-connect tunnels, session orchestration. This is the session host → broker communication. |
| Workspace PE | `feed` | `privatelink.wvd.microsoft.com` | The AVD client feed — when a user opens the AVD client and sees their list of desktops/apps, that request goes to the workspace. This is the client → workspace communication. |
| Global PE | `global` | `privatelink-global.wvd.microsoft.com` | **Initial feed discovery** — when the AVD client first subscribes, it queries `rdweb.wvd.microsoft.com` to discover all workspaces. You only need ONE global PE across your entire AVD deployment. Use a dedicated placeholder workspace for this. |

> **Important:** The `global` PE uses a **separate DNS zone** (`privatelink-global.wvd.microsoft.com`). Since September 2023, sharing the same DNS zone for `global` and other sub-resources is no longer supported. See [Microsoft docs](https://learn.microsoft.com/azure/virtual-desktop/private-link-overview#known-issues-and-limitations).
>
> **Important:** You cannot control access to the workspace used for the `global` sub-resource. Even if you configure it for private-only access, it remains publicly accessible. Create a separate empty workspace (no application groups) solely for the global PE.

### DNS Zone Configuration

For private endpoints to work, DNS resolution must return the private IP instead of the public IP. This requires **two** private DNS zones and a DNS forwarding chain:

1. **Private DNS Zone 1**: `privatelink.wvd.microsoft.com` — for `connection` and `feed` sub-resources
2. **Private DNS Zone 2**: `privatelink-global.wvd.microsoft.com` — for the `global` sub-resource
3. **A Records**: Automatically created by the `privateDnsZoneGroup` when each PE is deployed
4. **VNet Link**: Both DNS zones must be linked to the Azure VNet containing the PE subnet
5. **DNS Forwarding Chain (Azure Local specific)**:

```
On-prem session host → query: rdbroker.wvd.microsoft.com
    → On-prem DNS server (e.g., AD DC at 10.0.1.10)
    → Conditional forwarder: *.wvd.microsoft.com → Azure DNS Private Resolver (e.g., 10.1.0.4)
    → Azure DNS Private Resolver → Azure Private DNS Zone
    → CNAME: rdbroker.wvd.microsoft.com → rdbroker.privatelink.wvd.microsoft.com
    → A record: rdbroker.privatelink.wvd.microsoft.com → 10.1.2.4 (PE NIC in Azure VNet)
    → Traffic routes: on-prem → ExpressRoute/VPN → Azure VNet → PE NIC → AVD service
```

> **Key difference from standard Azure:** In a standard Azure deployment, session hosts use Azure DNS (`168.63.129.16`) directly because they're in the same VNet. On Azure Local, `168.63.129.16` is **not reachable** from on-premises — you must deploy an [Azure DNS Private Resolver](https://learn.microsoft.com/azure/dns/dns-private-resolver-overview) in the Azure VNet and configure your on-prem DNS servers to forward to it.

### Subnet Design

Private endpoints need their own **subnet in the Azure VNet** (not in the Azure Local logical network):

| Property | Recommended Value |
|---|---|
| Subnet Size | `/28` (14 usable IPs) — enough for 3 PEs plus room for future growth |
| Subnet Name | `snet-pe` or `snet-private-endpoints` |
| Subnet Location | In the Azure VNet that has ExpressRoute/VPN connectivity to Azure Local |
| NSG | Optional on PE subnet (PEs don't need outbound rules — they're the target, not the source) |
| Service Endpoints | Not needed — PEs are different from service endpoints |

---

## Configuration — Every Field Explained

```yaml
networking:
  private_endpoints:
    enabled: false                     # Whether to deploy private endpoints for the host pool, workspace, and global feed.
                                       # If false, AVD uses public endpoints (still encrypted via TLS 1.2).
                                       # If true, requires:
                                       #   - An Azure VNet with a dedicated PE subnet (NOT the Azure Local logical network)
                                       #   - ExpressRoute or Site-to-Site VPN from on-premises to the Azure VNet
                                       #   - Azure DNS Private Resolver in the Azure VNet
                                       #   - Two private DNS zones (see dns_zone_id and global_dns_zone_id)
    subnet_id: "/subscriptions/.../subnets/pe-subnet"
                                       # Full resource ID of the subnet IN AN AZURE VNET where private endpoint NICs are created.
                                       # IMPORTANT: This must be an Azure VNet subnet, NOT an Azure Local logical network subnet.
                                       # The subnet must have enough IP addresses (at least 3 for host pool + workspace + global PEs).
    dns_zone_id: ""                    # Full resource ID of the privatelink.wvd.microsoft.com DNS zone.
                                       # Used for host pool (connection) and workspace (feed) PEs.
                                       # If empty, the private endpoint is created without DNS zone group —
                                       # you must create A records manually or via Azure Policy.
    global_dns_zone_id: ""             # Full resource ID of the privatelink-global.wvd.microsoft.com DNS zone.
                                       # Used for the global (initial feed discovery) PE.
                                       # This is a SEPARATE zone from dns_zone_id — required since September 2023.
    global_workspace_id: ""            # Full resource ID of a dedicated placeholder workspace for the global PE.
                                       # This workspace should have NO application groups registered.
                                       # Only ONE global PE is needed across your entire AVD deployment.
  nsg:
    enabled: true                      # Whether to create the NSG with AVD outbound rules.
                                       # If false, no NSG is deployed (assumes you manage NSG externally).
    name: "hp-pool01-nsg"             # Name of the NSG resource. Must be unique within the resource group.
                                       # The NSG is created but NOT automatically associated with a subnet —
                                       # you must attach it to the session host subnet via subnet properties
                                       # or a separate association resource.
```

---

## What Each IaC Tool Deploys — Resource by Resource

### Terraform (`src/terraform/networking.tf`)

| Terraform Resource | Azure Resource Created | Condition | What It Does |
|---|---|---|---|
| `azurerm_network_security_group.avd_nsg[0]` | NSG | `var.nsg_enabled == true` | Creates the NSG with 4 inline `security_rule` blocks (priorities 100-130). Each rule uses a service tag destination. |
| `azurerm_private_endpoint.host_pool[0]` | Host Pool Private Endpoint | `var.private_endpoints_enabled == true` | Creates PE in `var.private_endpoint_subnet_id` (must be an Azure VNet subnet) with `private_service_connection` targeting the host pool resource and sub-resource `connection`. |
| `azurerm_private_endpoint.workspace[0]` | Workspace Private Endpoint | `var.private_endpoints_enabled == true` | Creates PE targeting the workspace resource and sub-resource `feed`. |
| `azurerm_private_endpoint.global[0]` | Global Feed Discovery PE | `var.private_endpoints_enabled == true` | Creates PE targeting a dedicated placeholder workspace and sub-resource `global`. Only one needed across all AVD deployments. |
| (inline) `private_dns_zone_group` block | DNS Zone Group | `var.private_dns_zone_id != ""` | Inside `connection` and `feed` PEs — links to `privatelink.wvd.microsoft.com`. |
| (inline) `private_dns_zone_group` block | Global DNS Zone Group | `var.private_dns_global_zone_id != ""` | Inside `global` PE — links to `privatelink-global.wvd.microsoft.com`. |

**Terraform variables:**

```hcl
nsg_enabled                   = true
nsg_name                      = "hp-pool01-nsg"
private_endpoints_enabled     = true
private_endpoint_subnet_id    = "/subscriptions/.../subnets/snet-pe"      # Must be an Azure VNet subnet
private_dns_zone_id           = "/subscriptions/.../privateDnsZones/privatelink.wvd.microsoft.com"
private_dns_global_zone_id    = "/subscriptions/.../privateDnsZones/privatelink-global.wvd.microsoft.com"
global_workspace_id           = "/subscriptions/.../workspaces/ws-global-pe"
```

### Bicep (`src/bicep/networking.bicep`)

Same resources implemented in Bicep:

| Bicep Resource | ARM Type | Notes |
|---|---|---|
| `nsg` resource | `Microsoft.Network/networkSecurityGroups@2023-05-01` | Contains `securityRules` array with 4 rules. Same service tags and priorities as Terraform. |
| `hostPoolPe` resource | `Microsoft.Network/privateEndpoints@2023-05-01` | `privateLinkServiceConnections` array with `groupIds: ['connection']`. Subnet must be in an Azure VNet. |
| `workspacePe` resource | `Microsoft.Network/privateEndpoints@2023-05-01` | `privateLinkServiceConnections` array with `groupIds: ['feed']`. |
| `globalPe` resource | `Microsoft.Network/privateEndpoints@2023-05-01` | `privateLinkServiceConnections` array with `groupIds: ['global']`. Only one needed across all AVD deployments. |
| `hostPoolPeDnsGroup` child | `Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01` | Links `connection` PE to `privatelink.wvd.microsoft.com`. |
| `workspacePeDnsGroup` child | `Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01` | Links `feed` PE to `privatelink.wvd.microsoft.com`. |
| `globalPeDnsGroup` child | `Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01` | Links `global` PE to `privatelink-global.wvd.microsoft.com`. |

```bash
az deployment group create \
  --resource-group rg-avd-prod \
  --template-file src/bicep/networking.bicep \
  --parameters nsgName='hp-pool01-nsg' \
               nsgEnabled=true \
               privateEndpointsEnabled=true \
               privateEndpointSubnetId='/subscriptions/.../subnets/snet-pe' \
               hostPoolId='<host-pool-resource-id>' \
               workspaceId='<workspace-resource-id>' \
               privateDnsZoneId='/subscriptions/.../privateDnsZones/privatelink.wvd.microsoft.com' \
               globalWorkspaceId='<global-workspace-resource-id>' \
               privateDnsGlobalZoneId='/subscriptions/.../privateDnsZones/privatelink-global.wvd.microsoft.com'
```

### PowerShell (`src/powershell/Configure-AVDNetworking.ps1`)

The PowerShell script runs these steps in order:

1. Loads configuration from YAML
2. If `nsg.enabled`: Creates NSG via `New-AzNetworkSecurityGroup`
3. Adds 4 rules via `Add-AzNetworkSecurityRuleConfig` — same service tags and priorities
4. Calls `Set-AzNetworkSecurityGroup` to apply the rules
5. If `private_endpoints.enabled`: Creates host pool PE via `New-AzPrivateEndpoint` with `-GroupId "connection"`
6. Creates workspace PE with `-GroupId "feed"`
7. Creates global PE with `-GroupId "global"` targeting a dedicated placeholder workspace
8. If DNS zones are specified: creates DNS zone groups via `New-AzPrivateDnsZoneGroup` — one for `privatelink.wvd.microsoft.com` (connection + feed) and one for `privatelink-global.wvd.microsoft.com` (global)

```powershell
.\src\powershell\Configure-AVDNetworking.ps1 -ConfigPath config/variables.yml
```

### Ansible (`src/ansible/roles/avd-networking/tasks/main.yml`)

Uses `azure_rm_securitygroup` for the NSG, `azure_rm_resource` for private endpoints. Tagged as `networking`.

```bash
ansible-playbook src/ansible/playbooks/site.yml -i inventory.yml --tags networking
```

---

## Troubleshooting

| Symptom | Root Cause | Resolution |
|---|---|---|
| Session hosts show "Unavailable" in host pool | NSG blocks outbound 443 to `WindowsVirtualDesktop` service tag | Verify NSG rule with priority 100 exists. Test: `Test-NetConnection rdbroker.wvd.microsoft.com -Port 443` from session host. |
| AVD Insights workbook shows no data | NSG blocks outbound 443 to `AzureMonitor` service tag, or monitoring agent not installed | Verify rule priority 110. Check if AMA/MMA agent is running on session hosts. |
| Hybrid Join fails — "Unable to register device" | NSG blocks outbound 443 to `AzureActiveDirectory` service tag | Verify rule priority 120. Test: `Test-NetConnection login.microsoftonline.com -Port 443` |
| Windows "Activate Windows" watermark | NSG blocks outbound 1688 to KMS server | Verify rule priority 130. Test: `Test-NetConnection azkms.core.windows.net -Port 1688` |
| Private endpoint deployed but FQDN still resolves to public IP | DNS zone group not created, DNS forwarding not configured, or Azure DNS Private Resolver not deployed | Check: `nslookup rdbroker.wvd.microsoft.com` from session host — should return `10.x.x.x` (private IP). If it returns a public IP: (1) verify the `privateDnsZoneGroup` resource exists, (2) verify both DNS zones are linked to the Azure VNet, (3) verify on-prem DNS forwards `*.wvd.microsoft.com` to the Azure DNS Private Resolver IP. |
| Users can't see desktops in AVD client after enabling PE | Global PE missing, workspace PE missing, or `feed`/`global` sub-resources not configured | Verify all 3 PEs exist — host pool (`connection`), workspace (`feed`), AND global (`global`). The global PE is required for initial feed discovery. |
| PE deployed but session hosts cannot reach PE IPs | No ExpressRoute/VPN between Azure Local and Azure VNet | On Azure Local, session hosts are on-premises. They need Layer 3 connectivity (ER or S2S VPN) to the Azure VNet hosting the PEs. Verify with `Test-NetConnection 10.1.2.4 -Port 443` from a session host. |
