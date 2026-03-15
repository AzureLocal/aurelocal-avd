# Variable Reference

All deployment parameters consolidated from every tool's parameter file.

See [`config/README.md`](../../config/README.md) for the full reference table including types, defaults, and which phases consume each variable.

!!! warning "Secrets"
    Never store passwords, tokens, or certificates in parameter files. Use Azure Key Vault references instead.

## Subscription & Global

| Variable | Type | Default |
|----------|------|---------|
| `azure_subscription_id` | string | — |
| `azure_tenant_id` | string | — |
| `location` | string | `eastus` |
| `resource_group_name` | string | `rg-avd-prod` |

## Control Plane

| Variable | Type | Default |
|----------|------|---------|
| `host_pool_name` | string | `hp-azurelocal-pool01` |
| `host_pool_type` | string | `Pooled` |
| `load_balancer_type` | string | `BreadthFirst` |
| `max_session_limit` | int | `10` |
| `app_group_name` | string | `ag-avd-desktops` |
| `app_group_type` | string | `Desktop` |
| `workspace_name` | string | `ws-avd-prod` |
| `key_vault_name` | string | `kv-avd-prod-001` |
| `log_analytics_workspace_name` | string | `law-avd-prod` |
| `log_analytics_retention_days` | int | `30` |

## Session Hosts

| Variable | Type | Default |
|----------|------|---------|
| `custom_location_id` | string | — |
| `vm_name_prefix` | string | `avd-sh` |
| `vm_count` | int | `2` |
| `vm_size` | string | `Standard_D4s_v3` |
| `image_id` | string | — |
| `vnet_id` | string | — |
| `subnet_name` | string | `default` |
| `key_vault_id` | string | — |

## Domain Join

| Variable | Type | Default |
|----------|------|---------|
| `domain_fqdn` | string | `contoso.local` |
| `domain_join_user` | string | — |
| `ou_path` | string | — |

## Tags

| Variable | Type | Default |
|----------|------|---------|
| `environment_tag` | string | `production` |
| `owner_tag` | string | `platform-team` |

## Ansible

| Variable | Type | Default |
|----------|------|---------|
| `ansible_connection` | string | `local` |
