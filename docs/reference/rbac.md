# RBAC Reference

This page provides least-privilege role mapping for AVD control-plane deployment and operations.

## 1) Role matrix

| Persona | Scope | Recommended role(s) |
|---|---|---|
| Platform engineer | Subscription/RG | `Contributor` (deployment scope only) |
| Security operations | Subscription/RG | `Reader`, `Security Reader` |
| Monitoring operations | Log Analytics | `Log Analytics Reader` |
| Helpdesk (user session support) | Host pool / app group | `Desktop Virtualization Reader` + operational custom role as needed |
| End users | Application Group | `Desktop Virtualization User` |

## 2) Least-privilege principles
- Assign at the narrowest possible scope.
- Use Entra groups instead of direct user role assignments.
- Separate deployment roles from operations roles.
- Use temporary elevation (PIM) for high-privilege actions.

## 3) Example custom role (deployment manager)

```json
{
	"Name": "AVD.DeploymentManager",
	"Description": "Deploy and update AVD control-plane resources without full subscription owner rights.",
	"Actions": [
		"Microsoft.DesktopVirtualization/*",
		"Microsoft.Insights/diagnosticSettings/*",
		"Microsoft.OperationalInsights/workspaces/read",
		"Microsoft.Authorization/roleAssignments/read",
		"Microsoft.Resources/subscriptions/resourceGroups/read"
	],
	"NotActions": [
		"Microsoft.Authorization/roleAssignments/delete"
	],
	"AssignableScopes": [
		"/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"
	]
}
```

## 4) CLI assignment examples

```bash
az role assignment create \
	--assignee-object-id <entra-group-object-id> \
	--assignee-principal-type Group \
	--role "Desktop Virtualization User" \
	--scope /subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.DesktopVirtualization/applicationGroups/<appGroup>
```

```bash
az role assignment create \
	--assignee-object-id <ops-group-object-id> \
	--assignee-principal-type Group \
	--role "Log Analytics Reader" \
	--scope /subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<law>
```

## 5) PowerShell assignment example

```powershell
New-AzRoleAssignment -ObjectId $GroupObjectId -RoleDefinitionName "Desktop Virtualization User" -Scope $AppGroupScope
```

## 6) Governance checks
- Weekly: detect direct user assignments at subscription scope.
- Monthly: review stale privileged role assignments.
- Quarterly: role recertification with service owners.
