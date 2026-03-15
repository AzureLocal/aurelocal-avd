#!/usr/bin/env bash
# deploy-session-hosts.sh
# Deploys AVD session-host VMs on an Azure Local cluster using the Azure CLI
# and registers them with an existing AVD host pool.
#
# Usage:
#   bash deploy-session-hosts.sh
#   Source parameters.sh first, or export the variables below.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/parameters.sh" ]]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/parameters.sh"
fi

# ── Defaults ──────────────────────────────────────────────────────────────────
VM_COUNT="${VM_COUNT:-2}"
VM_SIZE="${VM_SIZE:-Standard_D4s_v3}"
SUBNET_NAME="${SUBNET_NAME:-default}"
ENVIRONMENT_TAG="${ENVIRONMENT_TAG:-production}"
OWNER_TAG="${OWNER_TAG:-platform-team}"

# ── Validate required variables ───────────────────────────────────────────────
for var in RESOURCE_GROUP CUSTOM_LOCATION_ID HOST_POOL_NAME KEY_VAULT_NAME \
           VM_NAME_PREFIX IMAGE_ID VNET_ID DOMAIN_FQDN DOMAIN_JOIN_USER; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: Required variable '$var' is not set." >&2
    exit 1
  fi
done

echo "=== AVD Session Host Deployment ==="
echo "  Resource Group  : ${RESOURCE_GROUP}"
echo "  Custom Location : ${CUSTOM_LOCATION_ID}"
echo "  Host Pool       : ${HOST_POOL_NAME}"
echo "  VM Count        : ${VM_COUNT}"

# ── Retrieve secrets from Key Vault ───────────────────────────────────────────
echo ""
echo "Retrieving secrets from Key Vault '${KEY_VAULT_NAME}'..."
REGISTRATION_TOKEN=$(az keyvault secret show \
  --vault-name "${KEY_VAULT_NAME}" \
  --name "avd-registration-token" \
  --query value -o tsv)
DOMAIN_JOIN_PASSWORD=$(az keyvault secret show \
  --vault-name "${KEY_VAULT_NAME}" \
  --name "domain-join-password" \
  --query value -o tsv)
echo "  Secrets retrieved."

# ── Deploy VMs ────────────────────────────────────────────────────────────────
for i in $(seq -w 1 "${VM_COUNT}"); do
  VM_NAME="${VM_NAME_PREFIX}-${i}"
  echo ""
  echo "Deploying VM '${VM_NAME}'..."

  # Check if the VM already exists
  if az vm show --resource-group "${RESOURCE_GROUP}" --name "${VM_NAME}" &>/dev/null; then
    echo "  VM '${VM_NAME}' already exists – skipping."
    continue
  fi

  # Create the Arc-enabled VM on Azure Local
  # The --custom-location parameter targets the Azure Local cluster
  az stack-hci-vm create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${VM_NAME}" \
    --custom-location "${CUSTOM_LOCATION_ID}" \
    --image "${IMAGE_ID}" \
    --size "${VM_SIZE}" \
    --vnet-id "${VNET_ID}" \
    --subnet-id "${VNET_ID}/subnets/${SUBNET_NAME}" \
    --tags "environment=${ENVIRONMENT_TAG}" "owner=${OWNER_TAG}" "deployedBy=azure-cli" \
    --output none
  echo "  VM '${VM_NAME}' created."

  # ── Domain Join Extension ────────────────────────────────────────────────────
  echo "  Configuring domain-join extension..."
  az vm extension set \
    --resource-group "${RESOURCE_GROUP}" \
    --vm-name "${VM_NAME}" \
    --name "JsonADDomainExtension" \
    --publisher "Microsoft.Compute" \
    --version "1.3" \
    --settings "{
      \"domainToJoin\": \"${DOMAIN_FQDN}\",
      \"ouPath\": \"${OU_PATH:-}\",
      \"user\": \"${DOMAIN_JOIN_USER}\",
      \"restart\": \"true\",
      \"options\": \"3\"
    }" \
    --protected-settings "{\"password\": \"${DOMAIN_JOIN_PASSWORD}\"}" \
    --output none
  echo "  Domain join extension configured."

  # ── AVD Agent ───────────────────────────────────────────────────────────────
  echo "  Installing AVD Agent..."
  az vm extension set \
    --resource-group "${RESOURCE_GROUP}" \
    --vm-name "${VM_NAME}" \
    --name "DSC" \
    --publisher "Microsoft.Powershell" \
    --version "2.83" \
    --settings "{
      \"modulesUrl\": \"https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip\",
      \"configurationFunction\": \"Configuration.ps1\\\\AddSessionHost\",
      \"properties\": {
        \"hostPoolName\": \"${HOST_POOL_NAME}\",
        \"registrationInfoToken\": \"${REGISTRATION_TOKEN}\"
      }
    }" \
    --output none
  echo "  AVD Agent extension triggered."
done

echo ""
echo "=== Session Host Deployment Complete ==="
echo "Verify hosts: Azure Portal > AVD > Host Pools > ${HOST_POOL_NAME} > Session Hosts"
