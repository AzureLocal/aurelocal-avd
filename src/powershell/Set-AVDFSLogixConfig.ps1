#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileSharePath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('VHD', 'VHDX')]
    [string]$VolumeType = 'VHDX',

    [Parameter(Mandatory = $false)]
    [int]$SizeInMBs = 30720,

    [Parameter(Mandatory = $false)]
    [switch]$EnableCloudCache,

    [Parameter(Mandatory = $false)]
    [string[]]$CloudCacheLocations = @()
)

$fslogixPath = 'HKLM:\SOFTWARE\FSLogix\Profiles'
if (-not (Test-Path $fslogixPath)) {
    New-Item -Path $fslogixPath -Force | Out-Null
}

if ($PSCmdlet.ShouldProcess($fslogixPath, 'Configure FSLogix profile settings')) {
    New-ItemProperty -Path $fslogixPath -Name Enabled -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $fslogixPath -Name VHDLocations -PropertyType MultiString -Value @($ProfileSharePath) -Force | Out-Null
    New-ItemProperty -Path $fslogixPath -Name DeleteLocalProfileWhenVHDShouldApply -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $fslogixPath -Name FlipFlopProfileDirectoryName -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $fslogixPath -Name SizeInMBs -PropertyType DWord -Value $SizeInMBs -Force | Out-Null
    New-ItemProperty -Path $fslogixPath -Name VolumeType -PropertyType String -Value $VolumeType -Force | Out-Null

    if ($EnableCloudCache -and $CloudCacheLocations.Count -gt 0) {
        New-ItemProperty -Path $fslogixPath -Name CCDLocations -PropertyType MultiString -Value $CloudCacheLocations -Force | Out-Null
    }

    Write-Host 'FSLogix settings applied successfully.' -ForegroundColor Green
}
