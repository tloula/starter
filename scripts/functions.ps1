# Function to read .env.dev file and return a hashtable of key-value pairs
function Read-DotEnvFile {
    param (
        [string]$filePath
    )

    $projectVariables = @{}
    if (Test-Path $filePath) {
        $lines = Get-Content $filePath
        foreach ($line in $lines) {
            if ($line -match '^\s*#') { continue } # Skip comments
            if ($line -match '^\s*$') { continue } # Skip empty lines
            if ($line -match '^\s*([^=]+)\s*=\s*(.*)\s*$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $projectVariables[$key] = $value
            }
        }
    }
    return $projectVariables
}

# Function to save environment variables to .env.dev file
function Save-DotEnvFile {
    param (
        [string]$filePath,
        [hashtable]$projectVariables
    )

    # Read the existing file content
    $existingLines = @()
    if (Test-Path $filePath) {
        $existingLines = Get-Content $filePath
    }

    # Create a hashtable to store the updated variables
    $updatedVariables = @{}

    # Process each line and update the variables
    for ($i = 0; $i -lt $existingLines.Count; $i++) {
        $line = $existingLines[$i]
        if ($line -match '^\s*#') { continue } # Skip comments
        if ($line -match '^\s*$') { continue } # Skip empty lines
        if ($line -match '^\s*([^=]+)\s*=\s*(.*)\s*$') {
            $key = $matches[1].Trim()
            if ($projectVariables.ContainsKey($key)) {
                $existingLines[$i] = "$key=$($projectVariables[$key])"
                $updatedVariables[$key] = $true
            }
        }
    }

    # Add any new variables that were not already in the file
    foreach ($key in $projectVariables.Keys) {
        if (-not $updatedVariables.ContainsKey($key)) {
            $existingLines += "$key=$($projectVariables[$key])"
        }
    }

    # Write the updated content back to the file
    Set-Content -Path $filePath -Value $existingLines
}

# Function to read a .env file and set environment variables
function Set-EnvVarsFromDotEnvFile {
    param (
        [string]$filePath
    )

    $envVars = Read-DotEnvFile -filePath $filePath
    foreach ($key in $envVars.Keys) {
        $envVarName = $key
        $envVarValue = $envVars[$key]
        [System.Environment]::SetEnvironmentVariable($envVarName, $envVarValue, [System.EnvironmentVariableTarget]::Process)
    }
}

function Save-EnvVarsToDotEnvFile {
    param (
        [string]$filePath
    )

    $projectVariables = @{
        PROJECT_NAME = $env:PROJECT_NAME
        CONTAINER_NAME = $env:CONTAINER_NAME
        LOCATION = $env:LOCATION
        AZURE_CLIENT_ID = $env:AZURE_CLIENT_ID
        AZURE_TENANT_ID = $env:AZURE_TENANT_ID
    }
    Save-DotEnvFile -filePath $envFilePath -projectVariables $projectVariables
}

# Function to prompt for input with a default value
function Prompt-ForInput {
    param (
        [string]$prompt,
        [string]$defaultValue
    )

    $input = Read-Host "$prompt [$defaultValue]"
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $defaultValue
    }
    return $input
}

# Function to create an Azure Entra application if it does not exist
function Create-AppIfNotExists {
    param (
        [string]$appName
    )

    # Check if the application already exists
    $app = az ad app list --display-name $appName --query "[?displayName=='$appName']" -o json | ConvertFrom-Json

    if ($app.Count -gt 0) {
        $app = $app[0]
        Write-Host "Application $appName already exists with app id: $($app.appId)" -ForegroundColor Yellow
    } else {
        # Create the Entra application
        $app = az ad app create --display-name $appName --query "{appId: appId}" -o json | ConvertFrom-Json

        # Create a service principal for the application
        $sp = az ad sp create --id $app.appId --query "{appId: appId}" -o json | ConvertFrom-Json

        Write-Host "Created application $appName with app id: $($app.appId)" -ForegroundColor Green

        # Retrieve the current user's object ID
        $currentUserObjectId = az ad signed-in-user show --query id -o tsv

        # Add the current user as an owner of the application
        az ad app owner add --id $app.appId --owner-object-id $currentUserObjectId
    }

    return $app
}

# Function to create a group if it does not exist
function Create-GroupIfNotExists {
    param (
        [string]$displayName
    )

    # Check if the group already exists
    $group = az ad group list --display-name $displayName --query "[?displayName=='$displayName']" -o json | ConvertFrom-Json

    if ($group.Count -gt 0) {
        $groupId = $group[0].id
        Write-Host "Group $displayName already exists (object id: $groupId)" -ForegroundColor Yellow
    } else {
        # Create the group
        $group = az ad group create --display-name $displayName --mail-nickname $displayName --query "{objectId: id}" -o json | ConvertFrom-Json
        $groupId = $group.objectId
        Write-Host "Created group $displayName (object id: $groupId)" -ForegroundColor Green

        # Retrieve the current user's object ID
        $currentUserObjectId = az ad signed-in-user show --query id -o tsv

        # Add the current user as an owner of the group
        az ad group owner add --group $groupId --owner-object-id $currentUserObjectId
        Write-Host "Added current user as owner of group $groupName" -ForegroundColor Green
    }

    return $groupId
}

# Function to add an object to a group if it is not already a member
function Add-ObjectToGroupIfNotMember {
    param (
        [string]$groupId,
        [string]$objectId,
        [string]$objectName
    )

    # Check if the object is already a member of the group
    $isMember = az ad group member check --group $groupId --member-id $objectId --query "value" -o tsv
    if ($isMember -eq "True") {
        Write-Host "$objectName is already a member of group $groupId" -ForegroundColor Yellow
    } else {
        az ad group member add --group $groupId --member-id $objectId
        Write-Host "Added $objectName to group $groupId" -ForegroundColor Green
    }
}
