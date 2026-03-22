#Requires -Version 7.0

Describe 'AVD Contract Validation' {
    BeforeAll {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $schemaPath = Join-Path $repoRoot 'config/schema/variables.schema.json'
        $configExamplePath = Join-Path $repoRoot 'config/variables.example.yml'
        $invalidSchemaPath1 = Join-Path $repoRoot 'tests/schemas/invalid-host-pool-pooled-missing-load-balancer.yml'
        $invalidSchemaPath2 = Join-Path $repoRoot 'tests/schemas/invalid-keyvault-uri.yml'
    }

    It 'has canonical schema and example config' {
        Test-Path $schemaPath | Should -BeTrue
        Test-Path $configExamplePath | Should -BeTrue
    }

    It 'has negative schema fixtures' {
        Test-Path $invalidSchemaPath1 | Should -BeTrue
        Test-Path $invalidSchemaPath2 | Should -BeTrue
    }

    It 'has contract mapping doc' {
        Test-Path (Join-Path $repoRoot 'docs/reference/variable-mapping.md') | Should -BeTrue
    }

    It 'has parity and phase docs' {
        Test-Path (Join-Path $repoRoot 'docs/reference/tool-parity-matrix.md') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'docs/reference/phase-ownership.md') | Should -BeTrue
    }

    It 'has diagnostics and identity templates for Bicep and ARM' {
        Test-Path (Join-Path $repoRoot 'src/bicep/diagnostics.bicep') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'src/bicep/identity.bicep') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'src/arm/diagnostics.json') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'src/arm/identity.json') | Should -BeTrue
    }

    It 'has expanded PowerShell automation scripts' {
        Test-Path (Join-Path $repoRoot 'src/powershell/Import-AVDConfig.ps1') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'src/powershell/Set-AVDDiagnosticSettings.ps1') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'src/powershell/Set-AVDRoleAssignments.ps1') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'src/powershell/Set-AVDFSLogixConfig.ps1') | Should -BeTrue
    }

    It 'has expanded Ansible roles' {
        Test-Path (Join-Path $repoRoot 'src/ansible/roles/avd-diagnostics/tasks/main.yml') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'src/ansible/roles/avd-rbac/tasks/main.yml') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'src/ansible/roles/avd-fslogix/tasks/main.yml') | Should -BeTrue
        Test-Path (Join-Path $repoRoot 'src/ansible/roles/avd-validation/tasks/main.yml') | Should -BeTrue
    }
}
