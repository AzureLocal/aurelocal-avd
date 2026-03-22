resource "azapi_resource" "fslogix_extension" {
  for_each = var.fslogix_enabled && var.fslogix_profile_share_path != "" ? toset(local.vm_names) : toset([])

  type      = "Microsoft.HybridCompute/machines/extensions@2023-10-03-preview"
  name      = "FSLogixConfig"
  location  = var.location
  parent_id = azapi_resource.machine[each.key].id

  body = jsonencode({
    properties = {
      publisher               = "Microsoft.Compute"
      type                    = "CustomScriptExtension"
      typeHandlerVersion      = "1.10"
      autoUpgradeMinorVersion = true
      settings                = {}
      protectedSettings = {
        commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"$path='HKLM:\\\\SOFTWARE\\\\FSLogix\\\\Profiles';if(!(Test-Path $path)){New-Item -Path $path -Force | Out-Null};New-ItemProperty -Path $path -Name Enabled -PropertyType DWord -Value 1 -Force | Out-Null;New-ItemProperty -Path $path -Name VHDLocations -PropertyType MultiString -Value '${var.fslogix_profile_share_path}' -Force | Out-Null;New-ItemProperty -Path $path -Name SizeInMBs -PropertyType DWord -Value ${var.fslogix_size_in_mbs} -Force | Out-Null;New-ItemProperty -Path $path -Name VolumeType -PropertyType String -Value 'VHDX' -Force | Out-Null\""
      }
    }
  })

  depends_on = [azapi_resource.avd_agent_ext]
}
