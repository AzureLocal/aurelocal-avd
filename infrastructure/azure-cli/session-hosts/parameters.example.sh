# Session-host parameters – copy to parameters.sh and fill in your values.
# DO NOT commit parameters.sh (it is .gitignore'd).

export RESOURCE_GROUP="rg-avd-prod"

# Azure Local custom location resource ID
export CUSTOM_LOCATION_ID="/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurelocal/providers/Microsoft.ExtendedLocation/customLocations/cl-azurelocal-01"

# Existing AVD host pool
export HOST_POOL_NAME="hp-azurelocal-pool01"

# Key Vault containing 'avd-registration-token' and 'domain-join-password'
export KEY_VAULT_NAME="kv-avd-prod-001"

# VM settings
export VM_NAME_PREFIX="avd-sh"
export VM_COUNT="2"
export VM_SIZE="Standard_D4s_v3"

# Azure Local gallery image resource ID
export IMAGE_ID="/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurelocal/providers/Microsoft.AzureStackHCI/galleryImages/win11-multisession-23h2"

# Virtual network resource ID
export VNET_ID="/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurelocal/providers/Microsoft.AzureStackHCI/virtualNetworks/vnet-azurelocal-01"
export SUBNET_NAME="default"

# Domain join
export DOMAIN_FQDN="contoso.local"
export DOMAIN_JOIN_USER="svc-domainjoin@contoso.local"
export OU_PATH="OU=AVD,OU=Computers,DC=contoso,DC=local"

export ENVIRONMENT_TAG="production"
export OWNER_TAG="platform-team"
