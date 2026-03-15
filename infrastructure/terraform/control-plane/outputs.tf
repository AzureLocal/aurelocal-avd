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
