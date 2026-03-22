# FSLogix Integration

This guide defines how to run FSLogix profile containers for AVD session hosts on Azure Local with operationally safe defaults.

## 1) Profile container model selection

### VHDX on SMB (SOFS)
- Best for: Azure Local with low-latency SMB and AD DS/Kerberos.
- Pros: simple operations, predictable performance, no cloud dependency in steady state.
- Cons: recovery depends on storage replication/backup maturity.

### Cloud Cache (CCD)
- Best for: multi-site resiliency, Entra-only patterns, or mixed storage backends.
- Pros: supports multiple providers and tolerates backend outages.
- Cons: higher write amplification, more tuning/monitoring complexity.

Recommended default: use VHDX on SOFS for primary Azure Local designs and introduce CCD only where explicit DR/availability requirements justify complexity.

## 2) Sizing and capacity planning

Baseline sizing:
- Profile target per user: 25-40 GB (start with 30 GB).
- Free space buffer: 30% on the profile volume.
- Metadata growth allowance: 10% additional capacity.

Planning formula:

$$
Required\ Capacity = (Users \times Profile\ Size) \times 1.4
$$

Example:
- 400 users, 30 GB each: $400 \times 30 \times 1.4 = 16.8$ TB usable.

## 3) SOFS and SMB configuration guidance

Storage layout:
- Use dedicated CSV volumes for profile containers (separate from golden image/app content volumes).
- Use continuous availability SMB shares for profile paths.
- Keep storage traffic on dedicated east-west networks.

SMB recommendations:
- SMB Multichannel enabled.
- SMB encryption only where required by policy (measure impact first).
- Access-based enumeration enabled for profile shares.

Permissions baseline:
- Share permissions: `Authenticated Users` change, `Administrators` full control.
- NTFS: Creator Owner full on subfolders/files, users only to their own folders, admins/system full control.

## 4) FSLogix registry baseline

Primary keys under `HKLM:\SOFTWARE\FSLogix\Profiles`:
- `Enabled` (DWORD) = `1`
- `DeleteLocalProfileWhenVHDShouldApply` (DWORD) = `1`
- `FlipFlopProfileDirectoryName` (DWORD) = `1`
- `IsDynamic` (DWORD) = `1`
- `SizeInMBs` (DWORD) = `30720` (30 GB default)
- `VolumeType` (String) = `vhdx`
- `VHDLocations` (Multi-String) = `\\sofs\fslogixprofiles`

PowerShell example:

```powershell
$base = 'HKLM:\SOFTWARE\FSLogix\Profiles'
New-Item -Path $base -Force | Out-Null
New-ItemProperty -Path $base -Name Enabled -PropertyType DWord -Value 1 -Force | Out-Null
New-ItemProperty -Path $base -Name DeleteLocalProfileWhenVHDShouldApply -PropertyType DWord -Value 1 -Force | Out-Null
New-ItemProperty -Path $base -Name FlipFlopProfileDirectoryName -PropertyType DWord -Value 1 -Force | Out-Null
New-ItemProperty -Path $base -Name IsDynamic -PropertyType DWord -Value 1 -Force | Out-Null
New-ItemProperty -Path $base -Name SizeInMBs -PropertyType DWord -Value 30720 -Force | Out-Null
New-ItemProperty -Path $base -Name VolumeType -PropertyType String -Value 'vhdx' -Force | Out-Null
New-ItemProperty -Path $base -Name VHDLocations -PropertyType MultiString -Value '\\sofs\fslogixprofiles' -Force | Out-Null
```

Ansible example:

```yaml
- name: Configure FSLogix registry baseline
	ansible.windows.win_regedit:
		path: HKLM:\SOFTWARE\FSLogix\Profiles
		name: "{{ item.name }}"
		data: "{{ item.data }}"
		type: "{{ item.type }}"
		state: present
	loop:
		- { name: Enabled, type: dword, data: 1 }
		- { name: DeleteLocalProfileWhenVHDShouldApply, type: dword, data: 1 }
		- { name: FlipFlopProfileDirectoryName, type: dword, data: 1 }
		- { name: IsDynamic, type: dword, data: 1 }
		- { name: SizeInMBs, type: dword, data: 30720 }
		- { name: VolumeType, type: string, data: vhdx }
		- { name: VHDLocations, type: multistring, data: '\\sofs\fslogixprofiles' }
```

## 5) Antivirus and performance exclusions

Validate against security policy before applying exclusions. Common exclusions include:
- FSLogix process paths (`frxsvc.exe`, `frxrobocopy.exe`).
- Profile container share path.
- VHD(X) attach points.

Always verify exclusions with security operations and Defender policy owners.

## 6) DR and backup strategy

Minimum controls:
- Daily backup of FSLogix container volumes.
- Replication across fault domains or secondary site for critical workloads.
- Quarterly restore test using representative profile containers.

Recovery objective guidance:
- Define profile RPO/RTO explicitly in operations runbooks.
- Validate sign-in performance after restore and check profile lock cleanup.

## 7) Validation tests

Post-deployment checks:
- User sign-in creates and mounts profile VHDX.
- Re-sign-in lands on same profile state across hosts.
- Event logs show no recurring `frxsvc` attach errors.
- SMB latency and IO remain within baseline thresholds.

PowerShell validation example:

```powershell
Get-WinEvent -LogName 'Microsoft-FSLogix-Apps/Operational' -MaxEvents 100 |
	Where-Object { $_.LevelDisplayName -in 'Error','Warning' } |
	Select-Object TimeCreated, Id, Message
```

## Related references
- Companion SOFS repo: https://github.com/AzureLocal/azurelocal-sofs-fslogix
- FSLogix docs: https://learn.microsoft.com/fslogix/
- Deep architecture design: ../deep-design.md
