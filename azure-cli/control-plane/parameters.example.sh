# Control-plane parameters – copy to parameters.sh and fill in your values.
# DO NOT commit parameters.sh (it is .gitignore'd).

export RESOURCE_GROUP="rg-avd-prod"
export LOCATION="eastus"
export HOST_POOL_NAME="hp-azurelocal-pool01"
export HOST_POOL_TYPE="Pooled"           # Pooled | Personal
export LOAD_BALANCER_TYPE="BreadthFirst" # BreadthFirst | DepthFirst
export MAX_SESSION_LIMIT="10"
export APP_GROUP_TYPE="Desktop"
export WORKSPACE_NAME="ws-avd-prod"
export APP_GROUP_NAME="ag-avd-desktops"
export KEY_VAULT_NAME="kv-avd-prod-001"  # Must be globally unique
export LOG_ANALYTICS_WORKSPACE_NAME="law-avd-prod"
export ENVIRONMENT_TAG="production"
export OWNER_TAG="platform-team"
