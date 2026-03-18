locals {
  tags = {
    environment = var.environment_tag
    owner       = var.owner_tag
    deployed_by = "terraform"
  }
  vm_names = [for i in range(1, var.vm_count + 1) : format("%s-%02d", var.vm_name_prefix, i)]

  # Computed flags
  is_pooled   = var.host_pool_type == "Pooled"
  is_personal = var.host_pool_type == "Personal"
  uses_entra  = var.identity_strategy != "ad_only"
}
