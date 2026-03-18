# Validation Matrix

Complete validation coverage for the AVD automation solution across all IaC tools.

## Quick Reference

| Area | Tool | Command | CI Workflow |
|------|------|---------|-------------|
| Config Schema | Python | `python tests/validate-config-schema.py` | `ci-config-schema.yml` |
| Config Schema | PowerShell | `Invoke-Pester tests/powershell/Schema-Validation.Tests.ps1` | `ci-powershell.yml` |
| Config Loader | PowerShell | `Invoke-Pester tests/powershell/Config-Loader.Tests.ps1` | `ci-powershell.yml` |
| PowerShell Lint | PSScriptAnalyzer | `Invoke-ScriptAnalyzer -Path src/powershell -Recurse` | `ci-powershell.yml` |
| Terraform Format | Terraform | `terraform fmt -check -recursive` | `ci-terraform.yml` |
| Terraform Validate | Terraform | `terraform init -backend=false && terraform validate` | `ci-terraform.yml` |
| Terraform Lint | TFLint | `tflint --format compact` | `ci-terraform.yml` |
| Bicep Build | Azure CLI | `az bicep build --file <file>` | `ci-bicep.yml` |
| Bicep Lint | Azure CLI | `az bicep lint --file <file>` | `ci-bicep.yml` |
| Ansible Lint | ansible-lint | `ansible-lint src/ansible/` | `ci-ansible.yml` |
| Ansible Syntax | ansible-playbook | `ansible-playbook site.yml --syntax-check` | `ci-ansible.yml` |
| YAML Lint | yamllint | `yamllint -d relaxed src/ansible/` | `ci-ansible.yml` |

## Pre-Deployment Checks

Run `Test-AVDDeployment.ps1` to validate a live environment before deployment:

| Check | Description |
|-------|-------------|
| Config Load | YAML parses and schema validates |
| Azure Connectivity | `az account show` succeeds |
| Resource Group | Target RG exists or can be created |
| Network | VNet/subnet exist and have available IPs |
| Permissions | Current identity has required RBAC roles |
| Key Vault | Referenced vault is accessible |

## Post-Deployment Checks

| Check | Tool | Description |
|-------|------|-------------|
| Host Pool Health | PowerShell | Session hosts registered and available |
| AVD Agent Status | PowerShell | Agent reporting healthy on all hosts |
| User Connectivity | PowerShell | Test RDP connection to host pool |
| FSLogix Profiles | PowerShell | Profile containers mounting correctly |
| Monitoring | Azure Portal | Diagnostic data flowing to LAW |
| Scaling Plan | Azure Portal | Plan active and schedules triggering |

## CI/CD Workflow Map

```
Pull Request
├── ci-terraform.yml      → fmt + validate + tflint
├── ci-bicep.yml          → build + lint
├── ci-powershell.yml     → PSScriptAnalyzer + Pester
├── ci-ansible.yml        → yamllint + syntax-check + ansible-lint
├── ci-config-schema.yml  → JSON Schema validation of examples
├── validate-config.yml   → Schema validation of variables.example.yml
└── validate-repo-structure.yml → Repository structure checks
```
