# Host Pool Options (Pooled and Personal)

This reference defines host pool behavior, parameter mapping, and recommended autoscale patterns.

## 1) Host pool types

### Pooled
- Purpose: shared compute for task workers, call centers, and shift-based operations.
- Load balancing options:
	- `BreadthFirst`: spreads users across hosts.
	- `DepthFirst`: fills hosts before moving to next host.
- Recommended baseline:
	- `BreadthFirst` for user-experience consistency.
	- `DepthFirst` for cost-optimized autoscale scenarios.

### Personal
- Purpose: dedicated VM per user for developers, engineers, privileged workflows.
- Assignment:
	- `Automatic`: first available VM assigned at first sign-in.
	- `Direct`: preassigned VM-to-user mapping by operations.
- Recommended baseline: `Direct` where strict ownership/compliance is needed.

## 2) Core parameter reference

| Parameter | Scope | Applies To | Notes |
|---|---|---|---|
| `hostPoolType` | Host pool | Pooled/Personal | `Pooled` or `Personal` |
| `loadBalancingType` | Host pool | Pooled | `BreadthFirst` or `DepthFirst` |
| `maxSessionLimit` | Host pool | Pooled | Set from load-test data |
| `personalDesktopAssignmentType` | Host pool | Personal | `Automatic` or `Direct` |
| `startVMOnConnect` | Host pool | Both | Requires RBAC + service principal |
| `registrationTokenExpiration` | Host registration | Both | Short-lived token recommended |

## 3) Configuration mapping

| Canonical key (`config/variables.yml`) | Bicep | Terraform | PowerShell |
|---|---|---|---|
| `host_pool.type` | `hostPoolType` | `host_pool_type` | `-HostPoolType` |
| `host_pool.load_balancing` | `loadBalancingType` | `load_balancing_type` | `-LoadBalancingType` |
| `host_pool.max_sessions` | `maxSessionLimit` | `max_session_limit` | `-MaxSessionLimit` |
| `host_pool.personal_assignment` | `personalDesktopAssignmentType` | `personal_desktop_assignment_type` | `-PersonalAssignmentType` |
| `host_pool.start_vm_on_connect` | `startVMOnConnect` | `start_vm_on_connect` | `-StartVMOnConnect` |

## 4) Implementation examples

Bicep (pooled):

```bicep
param hostPoolType string = 'Pooled'
param loadBalancingType string = 'BreadthFirst'
param maxSessionLimit int = 12

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' = {
	name: 'hp-pooled-prod'
	location: resourceGroup().location
	properties: {
		hostPoolType: hostPoolType
		loadBalancerType: loadBalancingType
		maxSessionLimit: maxSessionLimit
		startVMOnConnect: true
		preferredAppGroupType: 'Desktop'
	}
}
```

Terraform (personal):

```hcl
resource "azurerm_virtual_desktop_host_pool" "personal" {
	name                            = "hp-personal-prod"
	location                        = azurerm_resource_group.avd.location
	resource_group_name             = azurerm_resource_group.avd.name
	type                            = "Personal"
	personal_desktop_assignment_type = "Direct"
	start_vm_on_connect             = true
}
```

PowerShell:

```powershell
New-AzWvdHostPool -ResourceGroupName $rg -Name 'hp-pooled-prod' -Location $location `
	-HostPoolType 'Pooled' -LoadBalancerType 'BreadthFirst' -MaxSessionLimit 12 -StartVMOnConnect:$true
```

## 5) Autoscale patterns

### Schedule-first
- Start baseline capacity before business hours.
- Drain and stop non-required hosts after hours.

### Load-first
- Increase hosts on session/cpu thresholds.
- Decrease hosts on sustained low utilization.

### Hybrid
- Schedule baseline + dynamic headroom during peaks.

Recommended controls:
- Reserve at least one spare host per pool.
- Use drain mode before host maintenance.
- Keep scale actions idempotent and logged.

## 6) Start VM on Connect requirements
- App registration/service principal authorized on subscription/RG scope.
- Required roles: VM start permission, AVD host pool access.
- Validate startup latency with login SLA tests.

## 7) Operational checks
- Track session distribution by host and pool.
- Alert on host pools with registration or heartbeat drops.
- Review `maxSessionLimit` quarterly against real concurrency.

## References
- AVD host pool overview: https://learn.microsoft.com/azure/virtual-desktop/host-pool-load-balancing
- Personal desktop assignment: https://learn.microsoft.com/azure/virtual-desktop/configure-host-pool-personal-desktop-assignment-type
- Autoscale for pooled host pools: https://learn.microsoft.com/azure/virtual-desktop/autoscale-scaling-plan
- Start VM on Connect: https://learn.microsoft.com/azure/virtual-desktop/start-virtual-machine-connect
