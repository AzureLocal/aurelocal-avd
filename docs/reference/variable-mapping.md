# Variable Mapping Reference

This table defines the canonical contract mapping from config variables to each automation implementation.

| Canonical key | Bicep | Terraform | PowerShell | Ansible | ARM |
|---|---|---|---|---|---|
| subscription.avd_subscription_id | deployment scope subscription | provider subscription | Set-AzContext -SubscriptionId | azure_subscription_id | deployment subscription |
| subscription.azure_local_subscription_id | cross-subscription IDs | azapi resource ID values | custom location/network/image IDs | avd_custom_location_id and IDs | parameter IDs |
| subscription.location | location | var.location | $Location | azure_location | parameters.location |
| security.key_vault_name | param key vault name | var.key_vault_name | $KeyVaultName | avd_key_vault_name | keyVaultName |
| control_plane.resource_group | param resourceGroupName | var.resource_group_name | $ResourceGroupName | azure_resource_group | resourceGroupName |
| control_plane.host_pool_name | hostPoolName | var.host_pool_name | $HostPoolName | avd_host_pool_name | hostPoolName |
| control_plane.host_pool_type | hostPoolType | var.host_pool_type | $HostPoolType | avd_host_pool_type | hostPoolType |
| control_plane.load_balancer_type | loadBalancerType | var.load_balancer_type | $LoadBalancerType | avd_load_balancer_type | loadBalancerType |
| control_plane.max_session_limit | maxSessionLimit | var.max_session_limit | $MaxSessionLimit | avd_max_session_limit | maxSessionLimit |
| control_plane.app_group_name | appGroupName | var.app_group_name | $AppGroupName | avd_app_group_name | appGroupName |
| control_plane.workspace_name | workspaceName | var.workspace_name | $WorkspaceName | avd_workspace_name | workspaceName |
| session_hosts.resource_group | param resourceGroupName (session hosts) | var.resource_group_name or dedicated var | $ResourceGroupName | azure_resource_group | resourceGroupName |
| session_hosts.session_host_count | sessionHostCount | var.vm_count | $VmCount | avd_vm_count | loop count |
| session_hosts.vm_naming_prefix | vmNamingPrefix | var.vm_name_prefix | $VmNamePrefix | avd_vm_name_prefix | vmName pattern |
| session_hosts.vm_processors | vmProcessors | var.vm_processors | VM sizing input | vm processors in resource body | processors |
| session_hosts.vm_memory_mb | vmMemoryMB | var.vm_memory_mb | VM sizing input | vm memory in resource body | memorymb |
| session_hosts.vm_admin_username | adminUsername | var.admin_username | admin username | avd_admin_username | adminUsername |
| session_hosts.vm_admin_password | adminPassword (resolved) | var.admin_password (sensitive) | Key Vault ref resolved | Key Vault secret | adminPassword |
| session_hosts.custom_location_id | customLocationId | var.custom_location_id | $CustomLocationId | avd_custom_location_id | customLocationId |
| session_hosts.logical_network_id | logicalNetworkId | var.vnet_id / logical network id | $VnetId | avd_vnet_id | logicalNetworkId |
| session_hosts.gallery_image_id | galleryImageId | var.image_id | $ImageId | avd_image_id | imageId |
| session_hosts.storage_path_id | storagePathId | var.storage_path_id | storage path parameter | avd_storage_path_id | storagePathId |
| domain.domain_fqdn | domainFqdn | var.domain_fqdn | $DomainFqdn | avd_domain_fqdn | domain parameter |
| domain.domain_join_username | domainJoinUser | var.domain_join_user | $DomainJoinUser | avd_domain_join_user | domain join user |
| domain.domain_join_password | domainJoinPassword (resolved) | var.domain_join_password | Key Vault ref resolved | Key Vault secret | protected setting |
| monitoring.log_analytics_workspace_name | diagnostics destination | var.log_analytics_workspace_name | diagnostics script | avd_log_analytics_workspace_name | diagnostics resource |
| monitoring.*_diagnostic_categories | category arrays | variable lists | Set-AVDDiagnosticSettings | avd diagnostics role vars | diagnostic settings categories |
| rbac.desktop_virtualization_user_group_id | role assignment principal | role assignment principal | Set-AVDRoleAssignments | avd-rbac role vars | role assignment principal |
| rbac.vm_user_login_group_id | role assignment principal | role assignment principal | Set-AVDRoleAssignments | avd-rbac role vars | role assignment principal |
| rbac.vm_admin_login_group_id | role assignment principal | role assignment principal | Set-AVDRoleAssignments | avd-rbac role vars | role assignment principal |
| fslogix.profile_share_path | extension/script input | VM extension setting | Set-AVDFSLogixConfig | avd-fslogix role vars | custom script setting |
| fslogix.vhd_size_gb | extension/script input | VM extension setting | Set-AVDFSLogixConfig | avd-fslogix role vars | custom script setting |
| image.source/publisher/offer/sku/version | image selection fields | image variables | parameters or YAML | image vars | parameter fields |

## Contract Modes

- Strict direct: Bicep deploy orchestrator reads config/variables.yml directly.
- Derived: Terraform and ARM parameter files may be generated from canonical config.
- Transitional: PowerShell parameters.ps1 remains supported while ConfigFile/YAML path is adopted.
