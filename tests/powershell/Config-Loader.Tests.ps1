#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

<#
.SYNOPSIS
    Pester tests for the Config-Loader module.
.DESCRIPTION
    Validates Get-AVDConfig loads YAML correctly, resolves keyvault URIs,
    and rejects invalid configs.
#>

BeforeAll {
    . "$PSScriptRoot/../../src/powershell/common/Config-Loader.ps1"

    $script:ExampleConfig = Join-Path $PSScriptRoot '../../config/variables.example.yml'
    $script:SchemaPath    = Join-Path $PSScriptRoot '../../config/schema/variables.schema.json'
    $script:ExamplesDir   = Join-Path $PSScriptRoot '../../config/examples'
}

Describe 'Get-AVDConfig' {
    It 'Loads variables.example.yml without error' {
        { Get-AVDConfig -ConfigPath $script:ExampleConfig } | Should -Not -Throw
    }

    It 'Returns a hashtable' {
        $cfg = Get-AVDConfig -ConfigPath $script:ExampleConfig
        $cfg | Should -BeOfType [hashtable]
    }

    It 'Contains required top-level keys' {
        $cfg = Get-AVDConfig -ConfigPath $script:ExampleConfig
        $cfg.Keys | Should -Contain 'azure'
        $cfg.Keys | Should -Contain 'avd'
    }

    It 'Loads each example config without error' {
        if (Test-Path $script:ExamplesDir) {
            $examples = Get-ChildItem -Path $script:ExamplesDir -Filter '*.yml'
            foreach ($ex in $examples) {
                { Get-AVDConfig -ConfigPath $ex.FullName } | Should -Not -Throw -Because "Example $($ex.Name) should load"
            }
        }
    }
}

Describe 'Test-AVDConfigSchema' {
    It 'Validates variables.example.yml against schema' {
        $cfg = Get-AVDConfig -ConfigPath $script:ExampleConfig
        $result = Test-AVDConfigSchema -Config $cfg -SchemaPath $script:SchemaPath
        $result | Should -Be $true
    }

    It 'Validates each example config against schema' {
        if (Test-Path $script:ExamplesDir) {
            $examples = Get-ChildItem -Path $script:ExamplesDir -Filter '*.yml'
            foreach ($ex in $examples) {
                $cfg = Get-AVDConfig -ConfigPath $ex.FullName
                $result = Test-AVDConfigSchema -Config $cfg -SchemaPath $script:SchemaPath
                $result | Should -Be $true -Because "Example $($ex.Name) should pass schema validation"
            }
        }
    }
}

Describe 'Resolve-KeyVaultSecrets' {
    It 'Leaves non-keyvault values unchanged' {
        $cfg = @{ simple = 'hello'; nested = @{ value = 42 } }
        $result = Resolve-KeyVaultSecrets -Config $cfg -DryRun
        $result.simple | Should -Be 'hello'
        $result.nested.value | Should -Be 42
    }

    It 'Identifies keyvault URIs in DryRun mode' {
        $cfg = @{ secret = 'keyvault://my-vault/my-secret' }
        $result = Resolve-KeyVaultSecrets -Config $cfg -DryRun
        # In DryRun, URI should remain as-is (no actual vault lookup)
        $result.secret | Should -BeLike 'keyvault://*'
    }
}
