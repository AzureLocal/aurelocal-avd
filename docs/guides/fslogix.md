# FSLogix Profile Containers

FSLogix profile containers store user profiles in VHDx files on SMB shares, dramatically improving logon times and profile reliability for AVD session hosts.

## Topology Options

### Single Share

All profile data stored in one VHDx per user on a single SMB share.

```yaml
fslogix:
  enabled: true
  share_topology: single
  single:
    vhd_path: "\\\\fs-01.domain.local\\FSLogix\\Profiles"
```

**Best for:** Small/medium deployments, simplest configuration.

### Split (Profile + Office)

Separates user profile data from Office/OneDrive cache into two VHDx files.

```yaml
fslogix:
  enabled: true
  share_topology: split
  split:
    profile_share: "\\\\fs-01.domain.local\\FSLogix\\Profiles"
    office_share: "\\\\fs-01.domain.local\\FSLogix\\ODFC"
```

**Best for:** Environments with large Office cache sizes, separate backup policies.

### Cloud Cache

Multi-site replication for high availability. Profile data is cached locally and replicated to multiple SMB targets.

```yaml
fslogix:
  enabled: true
  share_topology: cloud_cache
  cloud_cache:
    connections:
      - "type=smb,connectionString=\\\\primary.domain.local\\FSLogix"
      - "type=smb,connectionString=\\\\secondary.domain.local\\FSLogix"
```

**Best for:** Multi-site DR, geo-distributed users.

## NTFS Permissions

The recommended permission model for FSLogix shares:

| Principal | Permission | Applies To |
|-----------|-----------|------------|
| CREATOR OWNER | Full Control | Subfolders and files only |
| AVD Users Group | Modify | This folder only |
| BUILTIN\\Administrators | Full Control | This folder, subfolders, files |

## Deployment

### PowerShell

```powershell
# Provision the share and configure session hosts
.\src\powershell\New-FSLogixShare.ps1 -ConfigPath config/variables.yml
.\src\powershell\Configure-FSLogix.ps1 -ConfigPath config/variables.yml
```

### Terraform

FSLogix is configured via the `fslogix_*` variables. See [terraform.tfvars.example](../../src/terraform/terraform.tfvars.example).

### Bicep / ARM

FSLogix configuration is applied via CustomScriptExtension during session host deployment.

### Ansible

```bash
ansible-playbook src/ansible/playbooks/site.yml -i inventory.yml --tags fslogix
```

## Sizing Guidelines

| Users | VHDx Size | Share Size |
|-------|-----------|------------|
| 1-50 | 30 GB | 2 TB |
| 50-200 | 30 GB | 6 TB |
| 200-500 | 20 GB | 10 TB |
| 500+ | 15 GB | Plan per user |

## Troubleshooting

- **Profile not loading:** Check `HKLM:\SOFTWARE\FSLogix\Profiles\Enabled` = 1
- **Slow logon:** Verify UNC path is reachable from session hosts
- **VHDx locked:** Previous session may not have been cleanly released. Check Event Viewer > FSLogix
