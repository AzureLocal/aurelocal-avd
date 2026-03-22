# =============================================================================
# Outputs — Control Plane
# =============================================================================

output "resource_group_id" {
  description = "Resource ID of the AVD resource group."
  value       = azurerm_resource_group.avd.id
}

output "host_pool_id" {
  description = "Resource ID of the AVD host pool."
  value       = azurerm_virtual_desktop_host_pool.avd.id
}

output "app_group_id" {
  description = "Resource ID of the AVD application group."
  value       = azurerm_virtual_desktop_application_group.avd.id
}

output "workspace_id" {
  description = "Resource ID of the AVD workspace."
  value       = azurerm_virtual_desktop_workspace.avd.id
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.avd.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = azurerm_key_vault.avd.vault_uri
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.avd.id
}

output "diagnostic_setting_ids" {
  description = "Diagnostic setting IDs for AVD control plane resources."
  value = {
    host_pool = azurerm_monitor_diagnostic_setting.host_pool.id
    app_group = azurerm_monitor_diagnostic_setting.app_group.id
    workspace = azurerm_monitor_diagnostic_setting.workspace.id
  }
}

output "rbac_assignment_ids" {
  description = "Role assignment IDs created for AVD identity automation."
  value = {
    desktop_virtualization_user = try(azurerm_role_assignment.desktop_virtualization_user[0].id, null)
    vm_user_login               = try(azurerm_role_assignment.vm_user_login[0].id, null)
    vm_admin_login              = try(azurerm_role_assignment.vm_admin_login[0].id, null)
    start_vm_on_connect         = try(azurerm_role_assignment.start_vm_on_connect[0].id, null)
  }
}

# =============================================================================
# Outputs — Session Hosts
# =============================================================================

output "session_host_ids" {
  description = "Resource IDs of the deployed session-host machines."
  value       = { for name, m in azapi_resource.machine : name => m.id }
}

output "session_host_names" {
  description = "Names of the deployed session-host VMs."
  value       = local.vm_names
}

# =============================================================================
# Outputs — Scaling
# =============================================================================

output "scaling_plan_id" {
  description = "Resource ID of the scaling plan (if enabled)."
  value       = var.scaling_enabled && var.host_pool_type == "Pooled" ? azurerm_virtual_desktop_scaling_plan.avd[0].id : null
}

# =============================================================================
# Outputs — Networking
# =============================================================================

output "nsg_id" {
  description = "Resource ID of the NSG (if enabled)."
  value       = var.nsg_enabled ? azurerm_network_security_group.avd[0].id : null
}
