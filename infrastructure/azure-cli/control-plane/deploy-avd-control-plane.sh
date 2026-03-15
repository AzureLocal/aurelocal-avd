#!/usr/bin/env bash
# deploy-avd-control-plane.sh
# Deploys the AVD control plane (host pool, app group, workspace, Key Vault, Log Analytics) in Azure.
#
# Usage:
#   bash deploy-avd-control-plane.sh
#   Source a parameters.sh file first, or export the variables listed below.
#
# Required environment variables (or set in parameters.sh):
#   RESOURCE_GROUP, LOCATION, HOST_POOL_NAME, WORKSPACE_NAME, APP_GROUP_NAME,
#   KEY_VAULT_NAME, LOG_ANALYTICS_WORKSPACE_NAME

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load parameters file if present
if [[ -f "${SCRIPT_DIR}/parameters.sh" ]]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/parameters.sh"
fi

# ── Defaults ──────────────────────────────────────────────────────────────────
HOST_POOL_TYPE="${HOST_POOL_TYPE:-Pooled}"
LOAD_BALANCER_TYPE="${LOAD_BALANCER_TYPE:-BreadthFirst}"
MAX_SESSION_LIMIT="${MAX_SESSION_LIMIT:-10}"
APP_GROUP_TYPE="${APP_GROUP_TYPE:-Desktop}"
ENVIRONMENT_TAG="${ENVIRONMENT_TAG:-production}"
OWNER_TAG="${OWNER_TAG:-platform-team}"

# ── Validate required variables ───────────────────────────────────────────────
for var in RESOURCE_GROUP LOCATION HOST_POOL_NAME WORKSPACE_NAME APP_GROUP_NAME KEY_VAULT_NAME LOG_ANALYTICS_WORKSPACE_NAME; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: Required variable '$var' is not set." >&2
    exit 1
  fi
done

echo "=== AVD Control Plane Deployment ==="
echo "  Resource Group : ${RESOURCE_GROUP}"
echo "  Location       : ${LOCATION}"
echo "  Host Pool      : ${HOST_POOL_NAME} (${HOST_POOL_TYPE})"

# ── Resource Group ─────────────────────────────────────────────────────────────
echo ""
echo "Ensuring resource group '${RESOURCE_GROUP}'..."
if az group show --name "${RESOURCE_GROUP}" &>/dev/null; then
  echo "  Resource group already exists – skipping."
else
  az group create \
    --name "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --tags "environment=${ENVIRONMENT_TAG}" "owner=${OWNER_TAG}" "deployedBy=azure-cli"
  echo "  Resource group created."
fi

# ── Log Analytics Workspace ────────────────────────────────────────────────────
echo ""
echo "Deploying Log Analytics Workspace '${LOG_ANALYTICS_WORKSPACE_NAME}'..."
if az monitor log-analytics workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${LOG_ANALYTICS_WORKSPACE_NAME}" &>/dev/null; then
  echo "  Log Analytics Workspace already exists – skipping."
else
  az monitor log-analytics workspace create \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${LOG_ANALYTICS_WORKSPACE_NAME}" \
    --location "${LOCATION}" \
    --sku PerGB2018 \
    --retention-time 30 \
    --tags "environment=${ENVIRONMENT_TAG}" "owner=${OWNER_TAG}"
  echo "  Log Analytics Workspace created."
fi

LAW_ID=$(az monitor log-analytics workspace show \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${LOG_ANALYTICS_WORKSPACE_NAME}" \
  --query id -o tsv)

# ── Key Vault ──────────────────────────────────────────────────────────────────
echo ""
echo "Deploying Key Vault '${KEY_VAULT_NAME}'..."
if az keyvault show --name "${KEY_VAULT_NAME}" --resource-group "${RESOURCE_GROUP}" &>/dev/null; then
  echo "  Key Vault already exists – skipping."
else
  az keyvault create \
    --name "${KEY_VAULT_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --sku standard \
    --enabled-for-template-deployment true \
    --tags "environment=${ENVIRONMENT_TAG}" "owner=${OWNER_TAG}"
  echo "  Key Vault created."
fi

# ── Host Pool ──────────────────────────────────────────────────────────────────
echo ""
echo "Creating AVD host pool '${HOST_POOL_NAME}'..."
if az desktopvirtualization hostpool show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${HOST_POOL_NAME}" &>/dev/null; then
  echo "  Host pool already exists – skipping."
else
  az desktopvirtualization hostpool create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${HOST_POOL_NAME}" \
    --location "${LOCATION}" \
    --host-pool-type "${HOST_POOL_TYPE}" \
    --load-balancer-type "${LOAD_BALANCER_TYPE}" \
    --max-session-limit "${MAX_SESSION_LIMIT}" \
    --preferred-app-group-type "${APP_GROUP_TYPE}" \
    --tags "environment=${ENVIRONMENT_TAG}" "owner=${OWNER_TAG}"
  echo "  Host pool created."
fi

HOST_POOL_ID=$(az desktopvirtualization hostpool show \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${HOST_POOL_NAME}" \
  --query id -o tsv)

# ── Application Group ──────────────────────────────────────────────────────────
echo ""
echo "Creating application group '${APP_GROUP_NAME}'..."
if az desktopvirtualization applicationgroup show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${APP_GROUP_NAME}" &>/dev/null; then
  echo "  Application group already exists – skipping."
else
  az desktopvirtualization applicationgroup create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${APP_GROUP_NAME}" \
    --location "${LOCATION}" \
    --application-group-type "${APP_GROUP_TYPE}" \
    --host-pool-arm-path "${HOST_POOL_ID}" \
    --tags "environment=${ENVIRONMENT_TAG}" "owner=${OWNER_TAG}"
  echo "  Application group created."
fi

AG_ID=$(az desktopvirtualization applicationgroup show \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${APP_GROUP_NAME}" \
  --query id -o tsv)

# ── Workspace ──────────────────────────────────────────────────────────────────
echo ""
echo "Creating workspace '${WORKSPACE_NAME}'..."
if az desktopvirtualization workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${WORKSPACE_NAME}" &>/dev/null; then
  echo "  Workspace already exists – skipping."
else
  az desktopvirtualization workspace create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${WORKSPACE_NAME}" \
    --location "${LOCATION}" \
    --application-group-references "${AG_ID}" \
    --tags "environment=${ENVIRONMENT_TAG}" "owner=${OWNER_TAG}"
  echo "  Workspace created."
fi

# ── Registration Token ─────────────────────────────────────────────────────────
echo ""
echo "Retrieving host-pool registration token..."
TOKEN_EXPIRY=$(date -u -d '+24 hours' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v+24H '+%Y-%m-%dT%H:%M:%SZ')

REGISTRATION_TOKEN=$(az desktopvirtualization hostpool retrieve-registration-token \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${HOST_POOL_NAME}" \
  --query registrationInfo.token -o tsv)

az keyvault secret set \
  --vault-name "${KEY_VAULT_NAME}" \
  --name "avd-registration-token" \
  --value "${REGISTRATION_TOKEN}" \
  --output none
echo "  Registration token stored in Key Vault secret 'avd-registration-token'."

echo ""
echo "=== AVD Control Plane Deployment Complete ==="
echo "Host Pool  : ${HOST_POOL_NAME}"
echo "Workspace  : ${WORKSPACE_NAME}"
echo "Key Vault  : ${KEY_VAULT_NAME}"
echo ""
echo "Next step: deploy session hosts using deploy-session-hosts.sh"
