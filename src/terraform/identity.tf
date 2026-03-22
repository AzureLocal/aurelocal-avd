locals {
  role_desktop_virtualization_user         = "/providers/Microsoft.Authorization/roleDefinitions/1d336d6b-1444-4a47-9fbb-26e0a0e4f6bb"
  role_vm_user_login                       = "/providers/Microsoft.Authorization/roleDefinitions/fb879df8-f326-4884-b1cf-06f3ad86be52"
  role_vm_admin_login                      = "/providers/Microsoft.Authorization/roleDefinitions/1c0163c0-47e6-4577-8991-ea5c82e286e4"
  role_desktop_virtualization_power_on     = "/providers/Microsoft.Authorization/roleDefinitions/40c5ff49-9181-41f8-ae61-143b0e78555e"
}

resource "azurerm_role_assignment" "desktop_virtualization_user" {
  count              = var.desktop_virtualization_user_group_id == "" ? 0 : 1
  scope              = azurerm_virtual_desktop_application_group.avd.id
  role_definition_id = "${data.azurerm_subscription.current.id}${local.role_desktop_virtualization_user}"
  principal_id       = var.desktop_virtualization_user_group_id
}

resource "azurerm_role_assignment" "vm_user_login" {
  count              = var.vm_user_login_group_id == "" ? 0 : 1
  scope              = azurerm_resource_group.avd.id
  role_definition_id = "${data.azurerm_subscription.current.id}${local.role_vm_user_login}"
  principal_id       = var.vm_user_login_group_id
}

resource "azurerm_role_assignment" "vm_admin_login" {
  count              = var.vm_admin_login_group_id == "" ? 0 : 1
  scope              = azurerm_resource_group.avd.id
  role_definition_id = "${data.azurerm_subscription.current.id}${local.role_vm_admin_login}"
  principal_id       = var.vm_admin_login_group_id
}

resource "azurerm_role_assignment" "start_vm_on_connect" {
  count              = var.start_vm_on_connect_principal_id == "" ? 0 : 1
  scope              = azurerm_resource_group.avd.id
  role_definition_id = "${data.azurerm_subscription.current.id}${local.role_desktop_virtualization_power_on}"
  principal_id       = var.start_vm_on_connect_principal_id
}
