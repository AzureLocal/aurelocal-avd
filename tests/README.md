# Tests

Validation and testing scripts for AVD deployments.

## Structure

```
tests/
├── powershell/               # Pester tests for PowerShell scripts
│   ├── Config-Loader.Tests.ps1
│   └── Schema-Validation.Tests.ps1
├── validate-config-schema.py # Config schema validation script
└── README.md
```

## Running Tests

### PowerShell (Pester)

```powershell
Install-Module -Name Pester -MinimumVersion 5.0 -Force -Scope CurrentUser
Invoke-Pester -Path tests/powershell -Output Detailed
```

### Terraform

```bash
cd src/terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

### Bicep

```bash
for f in src/bicep/*.bicep; do
  az bicep build --file "$f" --stdout > /dev/null
done
```

### Config Schema

```bash
pip install pyyaml jsonschema
python tests/validate-config-schema.py
```
