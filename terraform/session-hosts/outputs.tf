output "session_host_ids" {
  description = "Resource IDs of the deployed session-host machines."
  value       = { for name, m in azapi_resource.machine : name => m.id }
}

output "session_host_names" {
  description = "Names of the deployed session-host VMs."
  value       = local.vm_names
}
