# FSLogix Integration

This page consolidates FSLogix guidance for AVD session-hosts on Azure Local. Sections to fill:

- Profile container types: VHDX vs Cloud Cache (CCD) — tradeoffs and when to choose which
- SOFS storage layouts (single vs triple layout) and recommended sizing
- SOFS SMB and NTFS permission examples
- FSLogix registry settings to apply (HKLM:\SOFTWARE\FSLogix\Profiles)
- Antivirus and performance tuning recommendations
- DR and backup considerations for profile containers
- Validation tests and Ansible/PowerShell snippets for configuration

References:
- Companion SOFS repo: https://github.com/AzureLocal/azurelocal-sofs-fslogix
- Microsoft FSLogix docs: https://learn.microsoft.com/fslogix/

TODOs:
- Add sample CSE/extension JSON for applying registry keys
- Add Ansible role examples for validation and mounting checks
