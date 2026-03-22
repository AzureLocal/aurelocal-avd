# =============================================================================
# New-AVDImage.ps1
# =============================================================================
# Manages Azure Local gallery images for AVD session hosts.
# Supports marketplace download, gallery image import, and custom images.
# =============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\common\Config-Loader.ps1"
$config = Get-AVDConfig -Path $ConfigPath

$imageConfig = $config.image
$source = $imageConfig.source
$location = $config.azure.location
$rg = $config.azure.resource_group
$subId = (Get-AzContext).Subscription.Id
$customLocationId = $config.azure_local.custom_location_id

Write-Host "Image source: $source" -ForegroundColor Cyan

switch ($source) {
    'marketplace' {
        $mp = $imageConfig.marketplace
        $imageName = "$($mp.offer)-$($mp.sku)"
        Write-Host "Downloading marketplace image: $($mp.publisher)/$($mp.offer)/$($mp.sku)/$($mp.version)"

        if ($PSCmdlet.ShouldProcess($imageName, "Download marketplace gallery image")) {
            $body = @{
                location         = $location
                extendedLocation = @{
                    type = "CustomLocation"
                    name = $customLocationId
                }
                properties = @{
                    osType              = "Windows"
                    hyperVGeneration    = "V2"
                    identifier          = @{
                        publisher = $mp.publisher
                        offer     = $mp.offer
                        sku       = $mp.sku
                    }
                    version = $mp.version
                }
            }

            $uri = "/subscriptions/$subId/resourceGroups/$rg/providers/Microsoft.AzureStackHCI/marketplaceGalleryImages/${imageName}?api-version=2023-09-01-preview"
            $result = Invoke-AzRestMethod -Method PUT -Path $uri -Payload ($body | ConvertTo-Json -Depth 5)
            if ($result.StatusCode -in 200, 201) {
                Write-Host "Marketplace image download initiated: $imageName" -ForegroundColor Green
            } else {
                Write-Error "Failed to download marketplace image: $($result.Content)"
            }
        }
    }

    'gallery' {
        $gallery = $imageConfig.gallery
        Write-Host "Using gallery image: $($gallery.image_id)"
        Write-Host "Gallery images are referenced directly by resource ID during VM deployment." -ForegroundColor Yellow
        Write-Host "No additional provisioning needed." -ForegroundColor Yellow
    }

    'custom' {
        $custom = $imageConfig.customization
        Write-Host "Custom image pipeline not implemented in this script." -ForegroundColor Yellow
        Write-Host "Use Azure Image Builder or Packer with the following config:" -ForegroundColor Yellow
        if ($custom.scripts) {
            Write-Host "  Scripts: $($custom.scripts -join ', ')" -ForegroundColor Cyan
        }
        if ($custom.windows_updates) {
            Write-Host "  Windows Updates: enabled" -ForegroundColor Cyan
        }
        if ($custom.optimize) {
            Write-Host "  OS Optimization: enabled" -ForegroundColor Cyan
        }
    }
}

Write-Host "`nImage management complete." -ForegroundColor Green
