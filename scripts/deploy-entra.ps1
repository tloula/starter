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
# - AZURE_CLIENT_ID: The Client ID of the created Entra App.
# - AZURE_CLIENT_SECRET: The Client Secret of the created Entra App.
# - TM_GROUP_OBJECT_ID: The Object ID of the created Team Entra Group.

. "$PSScriptRoot\functions.ps1"

# ########## INITIALIZATION ########## #

# Dependency paths
$envFilePath = ".env.dev"

if (-not (az account show)) {
    Write-Host "Logging in to Azure..."
    az login
    Write-Host "Logging in to Azure... Done"
}

# Dependency checks
if (-not (Test-Path $envFilePath)) {
    Write-Host ".env.dev file not found." -ForegroundColor Red
    exit
}

Set-EnvVarsFromDotEnvFile -filePath ".env.dev"

if (-not ($env:PROJECT_NAME)) {
    Write-Host "PROJECT_NAME environment variable not set. Exiting..." -ForegroundColor Red
    exit
}

# ########## ENTRA APP  ########## #

# Create the Entra application if it does not exist
$app = Create-AppIfNotExists -appName "$env:PROJECT_NAME-dev"

# Create a client secret for the application
$clientSecret = az ad app credential reset --id $app.appId --display-name "dev container" --query "{clientSecret: password}" -o json | ConvertFrom-Json

$env:AZURE_CLIENT_ID = $app.appId
$env:AZURE_CLIENT_SECRET = $clientSecret.clientSecret

# Save the client secret to the key vault if it exists
# Otherwise, the bicep deployment will use the environment variable to save it to the key vault
$kv = az keyvault show --name $env:PROJECT_NAME --query "name" -o tsv
if ($kv) {
    az keyvault secret set --vault-name $env:PROJECT_NAME --name "dev-aad-app-client-secret" --value $env:AZURE_CLIENT_SECRET
}

# ########## ENTRA TEAM GROUP  ########## #

$groupName = "TM-" + $env:PROJECT_NAME.Substring(0,1).ToUpper() + $env:PROJECT_NAME.Substring(1).ToLower()
$groupId = Create-GroupIfNotExists -displayName $groupName

$env:TM_GROUP_OBJECT_ID = $groupId

# ########## ADD ENTRA APP TO ENTRA TEAM GROUP  ########## #

$appServicePrincipalObjectId = (az ad sp show --id $app.appId --query "id" -o tsv)
Add-ObjectToGroupIfNotMember -groupId $groupId -objectId $appServicePrincipalObjectId -objectName "Entra app"

# ########## ADD CURRENT USER TO ENTRA TEAM GROUP  ########## #

$currentUserObjectId = (az ad signed-in-user show --query id -o tsv)
Add-ObjectToGroupIfNotMember -groupId $groupId -objectId $currentUserObjectId -objectName "Current user"
