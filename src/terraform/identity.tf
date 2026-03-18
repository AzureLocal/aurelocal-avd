# =============================================================================
# Identity & RBAC — Terraform
# =============================================================================
# Role assignments for AVD: Desktop Virtualization User, VM User Login,
# and optional VM Administrator Login for Entra-joined hosts.
# =============================================================================

variable "identity_strategy" {
  description = "Identity strategy: ad_only, entra_join, or hybrid_join."
  type        = string
  default     = "ad_only"
  validation {
    condition     = contains(["ad_only", "entra_join", "hybrid_join"], var.identity_strategy)
    error_message = "identity_strategy must be 'ad_only', 'entra_join', or 'hybrid_join'."
  }
}

variable "avd_user_group_id" {
  description = "Object ID of the Entra ID group to assign Desktop Virtualization User role."
  type        = string
  default     = ""
}

variable "avd_admin_group_id" {
  description = "Object ID of the Entra ID group to assign Virtual Machine Administrator Login."
  type        = string
  default     = ""
}

variable "rbac_assignments" {
  description = "Additional RBAC role assignments."
  type = list(object({
    role_definition_name = string
    principal_id         = string
    scope                = string
  }))
  default = []
}

# ── Desktop Virtualization User ───────────────────────────────────────────────
# Grants users permission to connect to the application group.

resource "azurerm_role_assignment" "avd_user" {
  count = var.avd_user_group_id != "" ? 1 : 0

  scope                = azurerm_virtual_desktop_application_group.avd.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = var.avd_user_group_id
}

# ── Virtual Machine User Login ────────────────────────────────────────────────
# Required for Entra-joined or hybrid-joined hosts so users can sign in via Entra ID.

resource "azurerm_role_assignment" "vm_user_login" {
  count = var.identity_strategy != "ad_only" && var.avd_user_group_id != "" ? 1 : 0

  scope                = azurerm_resource_group.avd.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = var.avd_user_group_id
}

# ── Virtual Machine Administrator Login ───────────────────────────────────────
# Optional admin access for Entra-joined hosts.

resource "azurerm_role_assignment" "vm_admin_login" {
  count = var.identity_strategy != "ad_only" && var.avd_admin_group_id != "" ? 1 : 0

  scope                = azurerm_resource_group.avd.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = var.avd_admin_group_id
}

# ── Additional role assignments from config ───────────────────────────────────

resource "azurerm_role_assignment" "custom" {
  count = length(var.rbac_assignments)

  scope                = var.rbac_assignments[count.index].scope
  role_definition_name = var.rbac_assignments[count.index].role_definition_name
  principal_id         = var.rbac_assignments[count.index].principal_id
}

# ── Entra ID Login Extension ─────────────────────────────────────────────────
# For entra_join or hybrid_join, deploy AADLoginForWindows on each session host.

resource "azapi_resource" "aad_login_ext" {
  for_each = var.identity_strategy != "ad_only" ? toset(local.vm_names) : toset([])

  type      = "Microsoft.HybridCompute/machines/extensions@2023-10-03-preview"
  name      = "AADLoginForWindows"
  location  = var.location
  parent_id = azapi_resource.machine[each.key].id

  body = jsonencode({
    properties = {
      publisher               = "Microsoft.Azure.ActiveDirectory"
      type                    = "AADLoginForWindows"
      typeHandlerVersion      = "2.0"
      autoUpgradeMinorVersion = true
      settings = var.identity_strategy == "hybrid_join" ? {
        mdmId = ""
      } : {}
    }
  })

  depends_on = [azapi_resource.avd_agent_ext]
}
