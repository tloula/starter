# ################# #
# Azure Entra Setup #
# ################# #

# This script automates the setup of Azure Entra resources required for the project.
# It performs the following tasks:
# 1. Creates an Entra App if it does not exist.
# 2. Creates a Team Entra Group (TM-<ProjectName>) if it does not exist.
# 3. Adds the Entra App to the Team Entra Group.

# Prerequisites:
# - Azure CLI must be installed and configured.
# - The following environment variables must be set:
#   - PROJECT_NAME: The name of the project.

# The script sets the following environment variables:
# - AZURE_TENANT_ID: The Azure Tenant ID.
# - AZURE_CLIENT_ID: The Client ID of the created Entra App.
# - AZURE_CLIENT_SECRET: The Client Secret of the created Entra App.
# - TM_GROUP_OBJECT_ID: The Object ID of the created Team Entra Group.

# ########## INITIALIZATION ########## #

if (-not (az account show)) {
    Write-Host "Logging in to Azure..."
    az login
    Write-Host "Logging in to Azure... Done"
}

if (-not ($env:PROJECT_NAME)) {
    Write-Host "PROJECT_NAME environment variable not set. Exiting..." -ForegroundColor Red
    exit
}

if (-not ($env:AZURE_TENANT_ID)) {
    $env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
}

# ########## ENTRA APP  ########## #

$appName = $env:PROJECT_NAME + "-dev"

# Check if the application already exists
$app = az ad app list --display-name $appName --query "[?displayName=='$appName']" -o json | ConvertFrom-Json

if ($app.Count -gt 0) {
    $app = $app[0]
    Write-Host "Application $appName already exists." -ForegroundColor Yellow
} else {
    # Create the Entra application
    $app = az ad app create --display-name $appName --query "{appId: $app.appId}" -o json | ConvertFrom-Json

    # Create a service principal for the application
    $sp = az ad sp create --id $appId --query "{appId: $app.appId}" -o json | ConvertFrom-Json

    Write-Host "Created application '$appName' with App ID: $app.appId" -ForegroundColor Green
}

# Create a client secret for the application
$clientSecret = az ad app credential reset --id $app.appId --query "{clientSecret: password}" -o json | ConvertFrom-Json

$env:AZURE_CLIENT_ID = $app.appId
$env:AZURE_CLIENT_SECRET = $clientSecret.clientSecret

# ########## ENTRA TEAM GROUP  ########## #

$projectName = $env:PROJECT_NAME.Substring(0,1).ToUpper() + $env:PROJECT_NAME.Substring(1).ToLower()
$groupName = "TM-$projectName"

# Check if the group already exists
$group = az ad group list --display-name $groupName --query "[?displayName=='$groupName']" -o json | ConvertFrom-Json

if ($group.Count -gt 0) {
    $groupId = $group[0].id
    Write-Host "Group $groupName already exists." -ForegroundColor Yellow
} else {
    # Create the group
    $group = az ad group create --display-name $groupName --mail-nickname $groupName --query "{objectId: objectId}" -o json | ConvertFrom-Json
    $groupId = $group.id
    Write-Host "Created group '$groupName' with Object ID: $groupId" -ForegroundColor Green
}

$env:TM_GROUP_OBJECT_ID = $groupId

# ########## ADD ENTRA APP TO ENTRA TEAM GROUP  ########## #

$appServicePrincipalObjectId = (az ad sp show --id $app.appId --query "id" -o tsv)

# Check if the service principal is already a member of the group
$isMember = az ad group member check --group $groupId --member-id $appServicePrincipalObjectId --query "value" -o tsv
if ($isMember) {
    Write-Host "Entra app is already a member of group '$groupName'" -ForegroundColor Yellow
} else {
    az ad group member add --group $groupName --member-id $appServicePrincipalObjectId
    Write-Host "Added Entra app to group '$groupName'" -ForegroundColor Green
}
